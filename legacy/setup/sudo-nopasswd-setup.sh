#!/bin/bash
set -euo pipefail

USERNAME="${1:-${SUDO_USER:?\"Usage: sudo $0 <username> (or run via sudo so SUDO_USER is set)\"}}"

echo "Configuring sudo NOPASSWD for user: ${USERNAME}"

# Verify the user exists
if ! id "${USERNAME}" &>/dev/null; then
    echo "Error: user '${USERNAME}' does not exist." >&2
    exit 1
fi

# Create sudoers drop-in file
SUDOERS_FILE="/etc/sudoers.d/${USERNAME}"
echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "${SUDOERS_FILE}"

# Set correct permissions (required by sudoers)
chmod 0440 "${SUDOERS_FILE}"

# Validate sudoers syntax
if visudo -c -f "${SUDOERS_FILE}"; then
    echo "sudo NOPASSWD configured successfully for ${USERNAME}."
else
    echo "Error: sudoers validation failed. Removing invalid file." >&2
    rm -f "${SUDOERS_FILE}"
    exit 1
fi
