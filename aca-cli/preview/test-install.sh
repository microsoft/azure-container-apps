#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

mkdir -p "$TEST_ROOT/mock-bin" "$TEST_ROOT/archive" "$TEST_ROOT/home"
printf '#!/bin/sh\necho aca-test-version\n' > "$TEST_ROOT/archive/aca"
chmod +x "$TEST_ROOT/archive/aca"
tar -czf "$TEST_ROOT/aca.tar.gz" -C "$TEST_ROOT/archive" aca
if command -v sha256sum >/dev/null 2>&1; then
    HASH="$(sha256sum "$TEST_ROOT/aca.tar.gz" | awk '{print $1}')"
else
    HASH="$(shasum -a 256 "$TEST_ROOT/aca.tar.gz" | awk '{print $1}')"
fi
printf 'version=aca-cli-test\nlinux-x64=%s\nosx-arm64=%s\n' "$HASH" "$HASH" > "$TEST_ROOT/pin"

cat > "$TEST_ROOT/mock-bin/curl" <<'MOCK'
#!/bin/sh
case "$2" in
    */latest-version.txt) cat "$TEST_ROOT/pin" ;;
    */aca-cli-test-*.tar.gz)
        test "$3" = "-o"
        cp "$TEST_ROOT/aca.tar.gz" "$4"
        ;;
    *) echo "Unexpected download: $2" >&2; exit 1 ;;
esac
MOCK
cat > "$TEST_ROOT/mock-bin/sudo" <<'MOCK'
#!/bin/sh
echo "Unexpected sudo invocation" >&2
exit 99
MOCK
cat > "$TEST_ROOT/mock-bin/uname" <<'MOCK'
#!/bin/sh
case "$1" in
    -s) echo Linux ;;
    -m) echo x86_64 ;;
    *) exit 1 ;;
esac
MOCK
chmod +x "$TEST_ROOT/mock-bin/curl" "$TEST_ROOT/mock-bin/sudo" "$TEST_ROOT/mock-bin/uname"
export TEST_ROOT
HOME="$TEST_ROOT/home"
PATH="$TEST_ROOT/mock-bin:$PATH"
export HOME PATH
unset INSTALL_DIR

sh "$SCRIPT_DIR/install.sh" > "$TEST_ROOT/default.log"
test "$("$HOME/.local/bin/aca")" = "aca-test-version"
grep -q 'export PATH=' "$TEST_ROOT/default.log"
sh "$SCRIPT_DIR/install.sh" > /dev/null
sh "$SCRIPT_DIR/install.sh" --uninstall > /dev/null
test ! -f "$HOME/.local/bin/aca"

INSTALL_DIR="$TEST_ROOT/custom/bin" sh "$SCRIPT_DIR/install.sh" > /dev/null
test "$("$TEST_ROOT/custom/bin/aca")" = "aca-test-version"
INSTALL_DIR="$TEST_ROOT/custom/bin" sh "$SCRIPT_DIR/install.sh" --uninstall > /dev/null
test ! -f "$TEST_ROOT/custom/bin/aca"

# Simulate an administrator-created destination without elevating the test.
cat > "$TEST_ROOT/mock-bin/mkdir" <<'MOCK'
#!/bin/sh
if [ "$2" = "$TEST_ROOT/system/bin" ]; then
    exit 1
fi
/bin/mkdir "$@"
MOCK
cat > "$TEST_ROOT/mock-bin/sudo" <<'MOCK'
#!/bin/sh
test "$1" = mkdir
test "$2" = -p
test "$3" = "$TEST_ROOT/system/bin"
echo called > "$TEST_ROOT/sudo-called"
/bin/mkdir -p "$3"
MOCK
chmod +x "$TEST_ROOT/mock-bin/mkdir" "$TEST_ROOT/mock-bin/sudo"
INSTALL_DIR="$TEST_ROOT/system/bin" sh "$SCRIPT_DIR/install.sh" > /dev/null
test -f "$TEST_ROOT/sudo-called"
test "$("$TEST_ROOT/system/bin/aca")" = "aca-test-version"
INSTALL_DIR="$TEST_ROOT/system/bin" sh "$SCRIPT_DIR/install.sh" --uninstall > /dev/null
test ! -f "$TEST_ROOT/system/bin/aca"

echo "Installer tests passed (no network or real sudo)."
