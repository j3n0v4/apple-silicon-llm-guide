#!/usr/bin/env bash
#
# install-swap-guard — Install or uninstall swap-guard as a launchd agent
#
# Installs the swap-guard swap watchdog script and launchd plist, configures
# a sudoers NOPASSWD entry for /usr/sbin/purge, and loads the agent.
#
# Usage:
#   ./install-swap-guard.sh              # Install from local repo
#   ./install-swap-guard.sh --uninstall  # Uninstall swap-guard
#   curl -fsSL ... | bash                # Install from URL (not yet supported)
#

set -o nounset
set -o pipefail
set -o errexit

# --- Configuration -----------------------------------------------------------

SCRIPT_SRC="./swap-guard.sh"
PLIST_SRC="./com.vltx.swap-guard.plist"
SCRIPT_DST="/usr/local/bin/swap-guard"
PLIST_DST="${HOME}/Library/LaunchAgents/com.vltx.swap-guard.plist"
SUDOERS_FILE="/etc/sudoers.d/swap-guard"
LOG_FILE="/tmp/swap-guard.log"

# Detect the real user (not root when run via sudo)
REAL_USER="${SUDO_USER:-${USER}}"
REAL_UID="$(id -u "${REAL_USER}" 2>/dev/null || echo "${UID}")"

# --- Mode selection ------------------------------------------------------------

ACTION="install"
if [ "${1:-}" = "--uninstall" ] || [ "${1:-}" = "-u" ]; then
    ACTION="uninstall"
fi

# --- Colors (if available) ---------------------------------------------------

if [ -t 1 ]; then
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    GREEN=''
    YELLOW=''
    RED=''
    BOLD=''
    NC=''
fi

info()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*"; }
header(){ echo -e "\n${BOLD}$*${NC}"; }

# --- Prerequisites -----------------------------------------------------------

header "Checking prerequisites"

# Must be on macOS
if [ "$(uname)" != "Darwin" ]; then
    error "This script is for macOS only (detected: $(uname))"
    exit 1
fi
info "macOS detected"

# Must have sudo access
if ! sudo -n true 2>/dev/null; then
    error "sudo access required. Run this script with a user that has admin privileges."
    exit 1
fi
info "sudo access confirmed"

# --- Uninstall ----------------------------------------------------------------

if [ "${ACTION}" = "uninstall" ]; then
    header "Uninstalling swap-guard"

    # Unload the launchd agent
    if [ -f "${PLIST_DST}" ]; then
        launchctl bootout "gui/${REAL_UID}" "${PLIST_DST}" 2>/dev/null || true
        rm -f "${PLIST_DST}"
        info "Removed launchd plist: ${PLIST_DST}"
    else
        warn "Launchd plist not found (already removed): ${PLIST_DST}"
    fi

    # Remove the script
    if [ -f "${SCRIPT_DST}" ]; then
        sudo rm -f "${SCRIPT_DST}"
        info "Removed script: ${SCRIPT_DST}"
    else
        warn "Script not found (already removed): ${SCRIPT_DST}"
    fi

    # Remove the sudoers entry
    if [ -f "${SUDOERS_FILE}" ]; then
        sudo rm -f "${SUDOERS_FILE}"
        info "Removed sudoers entry: ${SUDOERS_FILE}"
    else
        warn "Sudoers file not found (already removed): ${SUDOERS_FILE}"
    fi

    # Remove log files
    rm -f "${LOG_FILE}" 2>/dev/null
    rm -f /tmp/swap-guard-stdout.log 2>/dev/null
    rm -f /tmp/swap-guard-stderr.log 2>/dev/null
    info "Removed log files"

    # Verify uninstall
    if ! launchctl list | grep -q "com.vltx.swap-guard" 2>/dev/null; then
        info "swap-guard is no longer running"
    else
        warn "swap-guard may still be loaded — try: launchctl remove com.vltx.swap-guard"
    fi

    header "Uninstall complete"
    echo ""
    echo "  swap-guard has been removed from your system."
    echo "  Ollama and other applications are unaffected."
    echo ""
    exit 0
fi

# --- Install ------------------------------------------------------------------

# Source files must exist
if [ ! -f "${SCRIPT_SRC}" ]; then
    error "Source script not found: ${SCRIPT_SRC}"
    error "Run this script from the scripts/ directory of the apple-silicon-llm-guide repo."
    exit 1
fi
info "Found ${SCRIPT_SRC}"

if [ ! -f "${PLIST_SRC}" ]; then
    error "Source plist not found: ${PLIST_SRC}"
    exit 1
fi
info "Found ${PLIST_SRC}"

# --- Install Script ----------------------------------------------------------

header "Installing swap-guard script"

sudo cp "${SCRIPT_SRC}" "${SCRIPT_DST}"
sudo chown root:wheel "${SCRIPT_DST}"
sudo chmod 755 "${SCRIPT_DST}"
info "Installed to ${SCRIPT_DST}"

# --- Configure sudoers -------------------------------------------------------

header "Configuring sudoers NOPASSWD for /usr/sbin/purge"

# Create a dedicated sudoers file (safer than editing the main file)
# Only allows /usr/sbin/purge — nothing else
SUDOERS_LINE="%admin ALL=(ALL) NOPASSWD: /usr/sbin/purge"

# Check if the entry already exists
if [ -f "${SUDOERS_FILE}" ] && grep -q "^%admin.*NOPASSWD:.*/usr/sbin/purge" "${SUDOERS_FILE}" 2>/dev/null; then
    info "sudoers entry already exists: ${SUDOERS_FILE}"
else
    # Write the sudoers file and validate with visudo -c
    echo "${SUDOERS_LINE}" | sudo tee "${SUDOERS_FILE}" >/dev/null

    # Validate syntax
    if sudo visudo -c -f "${SUDOERS_FILE}" 2>/dev/null; then
        info "sudoers entry created and validated: ${SUDOERS_FILE}"
    else
        error "sudoers validation FAILED — removing invalid file"
        sudo rm -f "${SUDOERS_FILE}"
        exit 1
    fi
fi

# Verify the entry works
if sudo -n /usr/sbin/purge 2>/dev/null; then
    info "sudo purge works without password — NOPASSWD entry is active"
else
    warn "sudo purge test failed — the NOPASSWD entry may not be active yet"
    warn "This can happen if the system caches sudoers. Try opening a new terminal."
fi

# --- Install LaunchAgent -----------------------------------------------------

header "Installing launchd agent"

# Create LaunchAgents directory if needed
mkdir -p "${HOME}/Library/LaunchAgents"

# Copy plist
cp "${PLIST_SRC}" "${PLIST_DST}"
chmod 644 "${PLIST_DST}"
info "Installed plist to ${PLIST_DST}"

# Unload if already loaded (to apply changes)
launchctl bootout "gui/${REAL_UID}" "${PLIST_DST}" 2>/dev/null || true

# Load the agent into the real user's domain (not root's)
launchctl bootstrap "gui/${REAL_UID}" "${PLIST_DST}"
info "LaunchAgent loaded"

# --- Verify ------------------------------------------------------------------

header "Verifying installation"

# Check if the agent is running
if launchctl list | grep -q "com.vltx.swap-guard"; then
    info "swap-guard is running as a launchd agent"
else
    warn "swap-guard not found in launchctl list — check logs at ${LOG_FILE}"
fi

# Check the log file
if [ -f "${LOG_FILE}" ]; then
    echo ""
    echo "Recent log entries:"
    tail -5 "${LOG_FILE}" 2>/dev/null || echo "  (log file is empty)"
fi

# --- Summary -----------------------------------------------------------------

header "Installation complete"

echo ""
echo "  ${BOLD}swap-guard${NC} is now monitoring swap every 60 seconds."
echo ""
echo "  Threshold:     ${SWAP_THRESHOLD_KB:-1048576} KB (1 GB)"
echo "  Aggressive:    ${SWAP_AGGRESSIVE_KB:-4194304} KB (4 GB)"
echo "  Log file:      ${LOG_FILE}"
echo ""
echo "  ${BOLD}Check status:${NC}"
echo "    launchctl list | grep swap-guard"
echo "    tail -f ${LOG_FILE}"
echo ""
echo "  ${BOLD}Uninstall:${NC}"
echo "    ./install-swap-guard.sh --uninstall"
echo ""
echo "  ${BOLD}Note:${NC} swap-guard only purges when no Ollama model is actively"
echo "  generating. Active inference is never interrupted."
