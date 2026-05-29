#!/usr/bin/env node
// Validate every `aca <verb1> <verb2>` invocation in plugin/skills/**/*.md
// against the real `aca` binary on PATH. Catches fabricated commands
// (e.g. the hyphenated `aca sandbox-group …` family) before they ship.
//
// Usage:  node plugin/scripts/verify-aca-verbs.mjs [path-to-skill-dir]
// Exits:  0 if all verbs exist, 1 if any are broken, 2 if `aca` is not
//         on PATH (skips with a warning so CI without the toolchain
//         doesn't fail).

import { promises as fs } from 'node:fs';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SCAN_ROOT = path.resolve(process.argv[2] ?? path.join(__dirname, '..', 'skills'));
const SHELL_FENCES = new Set([
  'bash', 'sh', 'shell', 'console', 'azurecli', 'powershell', 'pwsh', 'ps1', 'ps',
]);

async function walk(dir, out = []) {
  let ents;
  try { ents = await fs.readdir(dir, { withFileTypes: true }); }
  catch (e) { if (e.code === 'ENOENT') return out; throw e; }
  for (const ent of ents) {
    const full = path.join(dir, ent.name);
    if (ent.isDirectory()) await walk(full, out);
    else if (ent.isFile() && ent.name.endsWith('.md')) out.push(full);
  }
  return out;
}

// Extract every aca invocation inside a shell code fence.
// Returns [{ file, line, v1, v2 }].
function extractFromMarkdown(file, text) {
  const out = [];
  const lines = text.split(/\r?\n/);
  let fenceLang = null;
  for (let i = 0; i < lines.length; i++) {
    const fenceOpen = lines[i].match(/^```([a-zA-Z0-9_-]*)/);
    if (fenceOpen) {
      fenceLang = fenceLang === null ? (fenceOpen[1] || '').toLowerCase() : null;
      continue;
    }
    if (fenceLang === null || !SHELL_FENCES.has(fenceLang)) continue;
    // Strip leading prompts and trailing line continuations.
    let line = lines[i].replace(/\r/g, '')
      .replace(/^(?:PS[^>]*>|\$|#|>)\s+/, '')
      .replace(/[\\`]\s*$/, '').trim();
    if (!/^aca(\s|$)/.test(line)) continue;
    // Skip subshell contents so flags don't get attributed to aca.
    line = line.replace(/\$\([^()]*\)/g, '_').replace(/`[^`]*`/g, '_');
    const tokens = line.split(/\s+/);
    const v1 = tokens[1] && /^[a-z][-a-z]*$/.test(tokens[1]) ? tokens[1] : null;
    const v2 = tokens[2] && /^[a-z][-a-z]*$/.test(tokens[2]) ? tokens[2] : null;
    if (v1) out.push({ file, line: i + 1, v1, v2 });
  }
  return out;
}

const helpCache = new Map();
function verbExists(args) {
  const key = args.join(' ');
  if (helpCache.has(key)) return helpCache.get(key);
  const r = spawnSync('aca', [...args, '--help'], { encoding: 'utf8', timeout: 15000, windowsHide: true });
  const ok = r.status === 0;
  helpCache.set(key, ok);
  return ok;
}

// Probe for `aca` once; if missing, skip with exit 2.
const probe = spawnSync('aca', ['--help'], { encoding: 'utf8', timeout: 15000, windowsHide: true });
if (probe.error || probe.status !== 0) {
  console.warn(`[verify-aca-verbs] WARNING: 'aca' is not on PATH (skipping). Install from https://aka.ms/aca-cli-install to enable.`);
  process.exit(2);
}

const files = await walk(SCAN_ROOT);
const invocations = [];
for (const f of files) invocations.push(...extractFromMarkdown(f, await fs.readFile(f, 'utf8')));

const seen = new Map(); // key -> [{file, line}]
for (const inv of invocations) {
  const key = inv.v2 ? `${inv.v1} ${inv.v2}` : inv.v1;
  if (!seen.has(key)) seen.set(key, []);
  seen.get(key).push(inv);
}

const broken = [];
for (const [key, sites] of [...seen.entries()].sort()) {
  const args = key.split(' ');
  if (!verbExists(args)) broken.push({ key, sites });
}

const total = seen.size;
console.log(`[verify-aca-verbs] Scanned ${files.length} markdown files, extracted ${total} unique aca verb pairs.`);
if (broken.length === 0) {
  console.log(`[verify-aca-verbs] OK: all ${total} verb pairs exist in the real 'aca' binary.`);
  process.exit(0);
}
console.error(`[verify-aca-verbs] FAIL: ${broken.length} of ${total} verb pairs do not exist:`);
for (const b of broken) {
  console.error(`  X  aca ${b.key}`);
  for (const s of b.sites) console.error(`       at ${path.relative(process.cwd(), s.file)}:${s.line}`);
}
process.exit(1);
