#!/bin/bash
set -e

# The user that VS Code server runs as (set by devcontainer CLI via _REMOTE_USER)
USERNAME="${_REMOTE_USER:-vscode}"

# Determine home directory
if [ "${USERNAME}" = "root" ]; then
    USER_HOME="/root"
else
    USER_HOME="/home/${USERNAME}"
fi

# VS Code server data directory (.vscode-server is modern, .vscode-remote is legacy)
VSCODE_DATA_DIR=""
for DIR in "${USER_HOME}/.vscode-server" "${USER_HOME}/.vscode-remote"; do
    if [ -d "${DIR}" ]; then
        VSCODE_DATA_DIR="${DIR}"
        break
    fi
done

# Default to .vscode-server if neither exists yet (server is installed at runtime)
if [ -z "${VSCODE_DATA_DIR}" ]; then
    VSCODE_DATA_DIR="${USER_HOME}/.vscode-server"
fi

# Ensure VS Code user data parent directories exist
mkdir -p "${VSCODE_DATA_DIR}/data/User/globalStorage"
mkdir -p "${VSCODE_DATA_DIR}/data/User/settings"

# Ensure mount point directories exist (replaced by volume mounts at runtime)
mkdir -p "/usr/local/share/oaicopilot-persist/globalStorage"
mkdir -p "/usr/local/share/vscode-persist/settings"

# Function to setup symlink safely
setup_symlink() {
    local SRC="$1"
    local DST="$2"

    if [ -L "${DST}" ]; then
        local CURRENT
        CURRENT=$(readlink "${DST}")
        if [ "${CURRENT}" = "${SRC}" ]; then
            echo "✓ Symlink already correct: ${DST} -> ${SRC}"
            return 0
        fi
        echo "! Updating symlink: ${DST} -> ${SRC}"
        rm -f "${DST}"
    elif [ -e "${DST}" ]; then
        # If it's a directory with existing data, migrate it to the source
        if [ -d "${DST}" ] && [ "$(ls -A "${DST}" 2>/dev/null)" ]; then
            echo "→ Migrating existing data from ${DST} to ${SRC}"
            mkdir -p "${SRC}"
            cp -a "${DST}/." "${SRC}/"
        fi
        rm -rf "${DST}"
    fi

    ln -s "${SRC}" "${DST}"
    echo "✓ Created symlink: ${DST} -> ${SRC}"
}

# Setup OAI Compatible Copilot globalStorage symlink
setup_symlink "/usr/local/share/oaicopilot-persist/globalStorage"     "${VSCODE_DATA_DIR}/data/User/globalStorage/johnny-zhao.oai-compatible-copilot"

# Setup settings symlink (shared volume name with kilocode-persist)
setup_symlink "/usr/local/share/vscode-persist/settings"     "${VSCODE_DATA_DIR}/data/User/settings"

# Fix ownership if running as root
if [ "$(id -u)" -eq 0 ] && [ "${USERNAME}" != "root" ]; then
    chown -R "${USERNAME}:${USERNAME}" "/usr/local/share/oaicopilot-persist" 2>/dev/null || true
    chown -R "${USERNAME}:${USERNAME}" "/usr/local/share/vscode-persist" 2>/dev/null || true
    chown -R "${USERNAME}:${USERNAME}" "${VSCODE_DATA_DIR}/data/User" 2>/dev/null || true
fi

echo ""
echo "OAI Compatible Copilot persistence configured for user: ${USERNAME}"
echo "  Extension state  → /usr/local/share/oaicopilot-persist/globalStorage"
echo "  Settings         → /usr/local/share/vscode-persist/settings"
