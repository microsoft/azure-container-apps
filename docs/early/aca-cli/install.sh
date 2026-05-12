#!/bin/sh
set -e

REPO="microsoft/azure-container-apps"
BRANCH="main"
BINARY_NAME="aca"
INSTALL_DIR="/usr/local/bin"

# Allow overriding version; default to latest
VERSION="${ACA_VERSION:-latest}"

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
        aarch64|arm64) ARCH_TAG="arm64" ;;
        *)             echo "Error: Unsupported architecture: $ARCH"; exit 1 ;;
    esac

    PLATFORM="${OS_TAG}-${ARCH_TAG}"
}

get_download_url() {
    if [ "$VERSION" = "latest" ]; then
        # Fetch latest version from version file (no API, no rate limits)
        VERSION="$(curl -fsSL "https://raw.githubusercontent.com/${REPO}/${BRANCH}/docs/early/aca-cli/latest-version.txt" | tr -d '[:space:]')"
        if [ -z "$VERSION" ]; then
            echo "Error: Could not determine latest version."
            echo "Specify a version manually: ACA_VERSION=aca-cli-v0.1.0-early-access $0"
            exit 1
        fi
        echo "Latest version: ${VERSION}"
    fi
    URL="https://github.com/${REPO}/releases/download/${VERSION}/${VERSION}-${PLATFORM}.tar.gz"
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
