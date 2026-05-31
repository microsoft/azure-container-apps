#!/bin/sh
set -e

REPO="microsoft/azure-container-apps"
BRANCH="main"
BINARY_NAME="aca"
INSTALL_DIR="/usr/local/bin"

detect_platform() {
    OS="$(uname -s)"
    ARCH="$(uname -m)"

    case "$OS" in
        Linux)  OS_TAG="linux" ;;
        Darwin) OS_TAG="osx" ;;
        *)      echo "Error: Unsupported OS: $OS"; exit 1 ;;
    esac

    case "$ARCH" in
        x86_64|amd64)
            if [ "$OS_TAG" = "osx" ]; then
                echo "Error: macOS x64 (Intel) is not supported. Only macOS ARM64 (Apple Silicon) is available."; exit 1
            fi
            ARCH_TAG="x64" ;;
        aarch64|arm64)
            if [ "$OS_TAG" = "linux" ]; then
                echo "Error: Linux ARM64 is not currently supported. Only Linux x64 is available."; exit 1
            fi
            ARCH_TAG="arm64" ;;
        *)             echo "Error: Unsupported architecture: $ARCH"; exit 1 ;;
    esac

    PLATFORM="${OS_TAG}-${ARCH_TAG}"
}

# Extract value for "key=..." from latest-version.txt content on stdin.
# Ignores comment lines (# ...) and trims surrounding whitespace from the value.
extract_value() {
    awk -F= -v k="$1" '
        /^[[:space:]]*#/ { next }
        /^[[:space:]]*$/ { next }
        {
            sub(/^[[:space:]]+/, "", $1)
            sub(/[[:space:]]+$/, "", $1)
            if ($1 == k) {
                sub(/^[^=]*=/, "")
                sub(/^[[:space:]]+/, "")
                sub(/[[:space:]]+$/, "")
                print
                exit
            }
        }'
}

# True if $1 is a 64-character lowercase hex string.
is_sha256() {
    case "$1" in
        ""|*[!0-9a-f]*) return 1 ;;
    esac
    [ "${#1}" -eq 64 ]
}

# Fetch and parse the pinned latest-version.txt. Sets:
#   VERSION         - the version= line value
#   EXPECTED_HASH   - the <platform>= line value, validated as 64-char hex
load_version_pin() {
    VERSION_FILE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/aca-cli/preview/latest-version.txt"
    VERSION_FILE_CONTENT="$(curl -fsSL "$VERSION_FILE_URL")" || VERSION_FILE_CONTENT=""
    if [ -z "$VERSION_FILE_CONTENT" ]; then
        echo "Error: Could not download ${VERSION_FILE_URL}."
        echo "Check your network connection and try again."
        exit 1
    fi

    VERSION="$(printf '%s\n' "$VERSION_FILE_CONTENT" | extract_value version)"
    if [ -z "$VERSION" ]; then
        echo "Error: latest-version.txt is missing a 'version=' entry."
        exit 1
    fi

    EXPECTED_HASH="$(printf '%s\n' "$VERSION_FILE_CONTENT" | extract_value "$PLATFORM")"
    if [ -z "$EXPECTED_HASH" ]; then
        echo "Error: latest-version.txt has no SHA-256 entry for platform '${PLATFORM}'."
        echo "This release does not advertise a verified archive for your platform."
        exit 1
    fi
    if ! is_sha256 "$EXPECTED_HASH"; then
        echo "Error: SHA-256 for '${PLATFORM}' in latest-version.txt is not 64 lowercase hex characters."
        exit 1
    fi
    echo "Pinned version: ${VERSION}"
}

get_download_url() {
    load_version_pin
    URL="https://github.com/${REPO}/releases/download/${VERSION}/${VERSION}-${PLATFORM}.tar.gz"
}

# Compute the SHA-256 of $1 using whichever tool is available; print to stdout.
compute_sha256() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    else
        echo ""
        return 1
    fi
}

# tolower without depending on bash; works in dash/ash.
to_lower() {
    printf '%s' "$1" | tr 'A-Z' 'a-z'
}

verify_archive() {
    archive="$1"
    actual="$(compute_sha256 "$archive")"
    rc=$?
    if [ $rc -ne 0 ] || [ -z "$actual" ]; then
        echo "Error: SHA-256 verification is required but neither 'sha256sum' nor 'shasum -a 256' is available."
        echo "On Alpine/busybox, install coreutils:  apk add --no-cache coreutils"
        exit 1
    fi
    actual="$(to_lower "$actual")"
    expected="$(to_lower "$EXPECTED_HASH")"
    if [ "$actual" != "$expected" ]; then
        echo "Error: SHA-256 mismatch for ${VERSION}-${PLATFORM}.tar.gz."
        echo "  expected: ${expected}"
        echo "  actual:   ${actual}"
        echo "Aborting install. The download was not what this release advertises."
        rm -f "$archive"
        exit 1
    fi
    echo "Verified SHA-256: ${actual}"
}

uninstall() {
    TARGET="${INSTALL_DIR}/${BINARY_NAME}"
    ACA_HOME="${HOME}/.aca"

    if [ ! -f "$TARGET" ] && [ ! -d "$ACA_HOME" ]; then
        echo "${BINARY_NAME} is not installed."
        exit 0
    fi

    # Remove binary
    if [ -f "$TARGET" ]; then
        if [ -w "$INSTALL_DIR" ]; then
            rm -f "$TARGET"
        else
            echo "Removing ${TARGET} (requires sudo)..."
            sudo rm -f "$TARGET"
        fi
        echo "Removed ${TARGET}"
    fi

    # Remove config directory
    if [ -d "$ACA_HOME" ]; then
        rm -rf "$ACA_HOME"
        echo "Removed ${ACA_HOME} (configuration)."
    fi

    echo "${BINARY_NAME} uninstalled successfully from ${TARGET}"
}

install() {
    detect_platform
    echo "Detected platform: ${PLATFORM}"

    get_download_url
    echo "Downloading ${BINARY_NAME} from ${URL}..."

    TMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TMP_DIR"' EXIT

    curl -fsSL "$URL" -o "${TMP_DIR}/${BINARY_NAME}.tar.gz"
    verify_archive "${TMP_DIR}/${BINARY_NAME}.tar.gz"
    tar -xzf "${TMP_DIR}/${BINARY_NAME}.tar.gz" -C "$TMP_DIR"

    # Install to INSTALL_DIR (try sudo if needed)
    if [ ! -d "$INSTALL_DIR" ]; then
        echo "Creating ${INSTALL_DIR} (requires sudo)..."
        sudo mkdir -p "$INSTALL_DIR"
    fi

    if [ -w "$INSTALL_DIR" ]; then
        cp "${TMP_DIR}/${BINARY_NAME}" "${INSTALL_DIR}/${BINARY_NAME}"
        chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
    else
        echo "Installing to ${INSTALL_DIR} (requires sudo)..."
        sudo cp "${TMP_DIR}/${BINARY_NAME}" "${INSTALL_DIR}/${BINARY_NAME}"
        sudo chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
    fi

    echo ""
    echo "${BINARY_NAME} installed successfully to ${INSTALL_DIR}/${BINARY_NAME}"
    echo ""
    echo "Prerequisites:"
    echo "  Azure CLI (az) must be installed and logged in."
    echo "  Run 'az login' if you haven't already."
    echo ""
    echo "Run '${BINARY_NAME} --help' to get started."
}

case "${1:-}" in
    --uninstall) uninstall ;;
    *)           install ;;
esac
