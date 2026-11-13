import assert from "node:assert/strict";
import { existsSync, readFileSync, readdirSync } from "node:fs";
import { join, relative, resolve } from "node:path";
import test from "node:test";

const root = resolve(process.env.BLOG_SITE_DIR ?? "_site");
const origin = new URL("https://microsoft.github.io/azure-container-apps/");
const read = (file) => readFileSync(join(root, file), "utf8");
const entities = { "&amp;": "&", "&quot;": '"', "&#39;": "'", "&lt;": "<", "&gt;": ">" };
const decodeHtml = (value) => value.replace(/&(?:amp|quot|#39|lt|gt);/g, (entity) => entities[entity]);
const files = readdirSync(root, { recursive: true }).filter((file) => /\.html$/.test(file) && !/^(aca-getting-started|docs)[\\/]/.test(file));
const postCards = (html) => [...html.matchAll(/<article class="post-card">([\s\S]*?)<\/article>/g)].map(([, card]) => ({
  date: card.match(/<time datetime="([^"]+)"/)?.[1],
  url: card.match(/class="post-title" href="([^"]+)"/)?.[1],
  tagged: /class="tag-list"/.test(card),
}));
const homepage = read("index.html");
const posts = postCards(homepage);

test("HTML entities are decoded once, preserving nested escapes in links and IDs", () => {
  assert.equal(decodeHtml("&amp;lt; &amp;quot; &#39; &amp;"), "&lt; &quot; ' &");
});

test("the homepage lists every published post newest first", () => {
  assert.ok(posts.length > 0, "The blog should contain a starter post");
  assert.equal(new Set(posts.map((post) => post.url)).size, posts.length);
  for (const [index, post] of posts.entries()) {
    assert.ok(post.url?.startsWith(origin.pathname), "Post URLs must include the repository base path");
    assert.ok(Number.isFinite(Date.parse(post.date)), "Each post needs a machine-readable date");
    if (index > 0) assert.ok(Date.parse(posts[index - 1].date) >= Date.parse(post.date));
  }
  assert.equal(files.filter((file) => /^\d{4}[\\/]\d{2}[\\/]\d{2}[\\/]/.test(file)).length, posts.length);
});

test("every post appears in its date, tag and author indexes", () => {
  const indexes = ["archive/index.html", "tags/index.html", "authors/index.html"];
  for (const index of indexes) {
    const indexedPosts = new Set(postCards(read(index)).map((post) => post.url));
    for (const post of posts) {
      if (index !== "tags/index.html" || post.tagged) {
        assert.ok(indexedPosts.has(post.url), `${index} is missing ${post.url}`);
      }
    }
  }
});

test("older and newer navigation follows the publication order", () => {
  for (const [index, post] of posts.entries()) {
    const file = decodeURIComponent(new URL(post.url, origin).pathname.slice(origin.pathname.length)) + "index.html";
    const html = read(file);
    const older = html.match(/class="post-navigation-link older-post" href="([^"]+)"/)?.[1];
    const newer = html.match(/class="post-navigation-link newer-post" href="([^"]+)"/)?.[1];
    assert.equal(older, posts[index + 1]?.url, `Wrong older post on ${post.url}`);
    assert.equal(newer, posts[index - 1]?.url, `Wrong newer post on ${post.url}`);
  }
});

test("generated blog pages have valid local links, assets and fragment targets", () => {
  for (const file of files) {
    const html = read(file);
    assert.match(html, /<html lang="en">/);
    assert.match(html, /<meta name="viewport"/);
    assert.match(html, /<main id="main"/);
    assert.doesNotMatch(html, /\{%\s*(include|feed_meta)\b/, `Unrendered template in ${file}`);
    const pageUrl = new URL(file.replaceAll("\\", "/").replace(/index\.html$/, ""), origin);
    for (const [, attribute] of html.matchAll(/(?:href|src)="([^"]+)"/g)) {
      const url = new URL(decodeHtml(attribute), pageUrl);
      if (url.origin !== origin.origin) continue;
      assert.ok(url.pathname.startsWith(origin.pathname), `Missing base path: ${attribute} in ${file}`);
      let target = resolve(root, decodeURIComponent(url.pathname.slice(origin.pathname.length)));
      if (url.pathname.endsWith("/")) target = join(target, "index.html");
      assert.ok(!relative(root, target).startsWith(".."), `Link escapes the site: ${attribute}`);
      assert.ok(existsSync(target), `Missing target: ${attribute} in ${file}`);
      if (url.hash && /\.html$/.test(target)) {
        const ids = [...readFileSync(target, "utf8").matchAll(/\bid="([^"]+)"/g)].map(([, id]) => decodeHtml(id));
        assert.ok(ids.includes(decodeURIComponent(url.hash.slice(1))), `Missing fragment: ${attribute} in ${file}`);
      }
    }
  }
});

test("the resource hub remains available and non-site source stays private to GitHub", () => {
  assert.ok(existsSync(join(root, "aca-getting-started", "index.html")));
  assert.ok(existsSync(join(root, "feed.xml")));
  for (const file of ["AGENTS.md", "Gemfile", "README.md", "scripts/test-blog.mjs", "plugin"]) {
    assert.ok(!existsSync(join(root, file)), `Non-site source unexpectedly published: ${file}`);
  }
});
