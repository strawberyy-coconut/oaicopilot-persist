#!/bin/bash
set -e

USERNAME="${_REMOTE_USER:-vscode}"

if [ "${USERNAME}" = "root" ]; then
    USER_HOME="/root"
else
    USER_HOME="/home/${USERNAME}"
fi

VSCODE_DATA_DIR=""
for DIR in "${USER_HOME}/.vscode-server" "${USER_HOME}/.vscode-remote"; do
    if [ -d "${DIR}" ]; then
        VSCODE_DATA_DIR="${DIR}"
        break
    fi
done

if [ -z "${VSCODE_DATA_DIR}" ]; then
    VSCODE_DATA_DIR="${USER_HOME}/.vscode-server"
fi

mkdir -p "${VSCODE_DATA_DIR}/data/User/globalStorage"
mkdir -p "${VSCODE_DATA_DIR}/data/User/settings"
mkdir -p "/usr/local/share/vscode-persist/globalStorage"
mkdir -p "/usr/local/share/vscode-persist/settings"

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

setup_symlink "/usr/local/share/vscode-persist/globalStorage" \
    "${VSCODE_DATA_DIR}/data/User/globalStorage"

setup_symlink "/usr/local/share/vscode-persist/settings" \
    "${VSCODE_DATA_DIR}/data/User/settings"

if [ "$(id -u)" -eq 0 ] && [ "${USERNAME}" != "root" ]; then
    chown -R "${USERNAME}:${USERNAME}" "/usr/local/share/vscode-persist" 2>/dev/null || true
    chown -R "${USERNAME}:${USERNAME}" "${VSCODE_DATA_DIR}/data/User" 2>/dev/null || true
fi

echo ""
echo "VS Code persistence configured for user: ${USERNAME}"
echo "  globalStorage (all extensions + SecretStorage/API keys) → /usr/local/share/vscode-persist/globalStorage"
echo "  Settings                                              → /usr/local/share/vscode-persist/settings"