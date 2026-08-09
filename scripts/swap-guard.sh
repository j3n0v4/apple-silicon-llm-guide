#!/usr/bin/env bash
#
# swap-guard — Automated swap watchdog for macOS Apple Silicon LLM inference
#
# Monitors swap usage and automatically runs `sudo purge` when stale swap
# exceeds a threshold. Optionally stops idle Ollama models before purging
# when swap is critically high.
#
# Designed to run as a launchd agent (every 60 seconds). No dependencies
# beyond bash, macOS core utilities, and sudo access to /usr/sbin/purge.
#
# Environment variables (all optional):
#   SWAP_THRESHOLD_KB   — Swap above this triggers purge (default: 1048576 = 1 GB)
#   SWAP_AGGRESSIVE_KB  — Swap above this also stops Ollama models (default: 4194304 = 4 GB)
#   LOG_FILE            — Path to log file (default: /tmp/swap-guard.log)
#
# Exit codes:
#   0  — No action needed (swap below threshold)
#   1  — Purge performed (swap was above threshold)
#   2  — Skipped (model active, would not interrupt)
#   3  — Error (unexpected failure)
#

set -o nounset
set -o pipefail

# --- Configuration -----------------------------------------------------------

SWAP_THRESHOLD_KB="${SWAP_THRESHOLD_KB:-1048576}"   # 1 GB
SWAP_AGGRESSIVE_KB="${SWAP_AGGRESSIVE_KB:-4194304}"  # 4 GB
LOG_FILE="${LOG_FILE:-/tmp/swap-guard.log}"

# --- Helpers -----------------------------------------------------------------

log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] $*" >> "${LOG_FILE}"
}

notify() {
    local title="$1"
    local message="$2"
    osascript -e "display notification \"${message}\" with title \"${title}\"" 2>/dev/null || true
}

# --- Swap reading ------------------------------------------------------------

get_swap_used_kb() {
    # Parse `sysctl vm.swapusage` output like:
    #   vm.swapusage: total = 2048.00M  used = 1024.50M  free = 1023.50M  (encrypted)
    local swap_line
    swap_line="$(sysctl vm.swapusage 2>/dev/null)" || {
        log "WARN" "sysctl vm.swapusage failed — swap not available?"
        echo "0"
        return
    }

    # Extract the "used = X.XX{M,G}" portion
    local used_str
    used_str="$(echo "${swap_line}" | sed -n 's/.*used = \([0-9.]*\)\([MG]\).*/\1 \2/p')" || {
        log "WARN" "Could not parse swap usage from: ${swap_line}"
        echo "0"
        return
    }

    if [ -z "${used_str}" ]; then
        log "WARN" "Swap usage field not found in: ${swap_line}"
        echo "0"
        return
    fi

    local used_val
    local used_unit
    used_val="$(echo "${used_str}" | awk '{print $1}')"
    used_unit="$(echo "${used_str}" | awk '{print $2}')"

    # Convert to KB
    case "${used_unit}" in
        G) awk "BEGIN {printf \"%.0f\", ${used_val} * 1048576}" ;;
        M) awk "BEGIN {printf \"%.0f\", ${used_val} * 1024}" ;;
        *) log "WARN" "Unknown swap unit: ${used_unit}"; echo "0" ;;
    esac
}

# --- Ollama helpers ----------------------------------------------------------

ollama_is_running() {
    # Check if the Ollama service is reachable
    curl -sf http://localhost:11434/api/tags >/dev/null 2>&1
}

ollama_has_active_model() {
    # Check `ollama ps` for any model in "loading" or "running" state.
    # Returns 0 (true) if a model is actively generating, 1 (false) otherwise.
    local ps_output
    ps_output="$(ollama ps 2>/dev/null)" || return 1

    # ollama ps returns a header line + data lines. If only the header, no models loaded.
    local line_count
    line_count="$(echo "${ps_output}" | wc -l | tr -d ' ')"
    if [ "${line_count}" -le 1 ]; then
        return 1
    fi

    # Check for models in loading or running state (not idle/stopped)
    # The second column is the status field
    if echo "${ps_output}" | tail -n +2 | awk '{print $2}' | grep -qiE '^(loading|running)$' >/dev/null 2>&1; then
        return 0
    fi

    return 1
}

ollama_stop_all() {
    # Stop all currently loaded models
    local models
    models="$(ollama ps 2>/dev/null | tail -n +2 | awk '{print $1}')" || return 1

    if [ -z "${models}" ]; then
        return 0
    fi

    local stopped=0
    while IFS= read -r model; do
        if [ -n "${model}" ]; then
            ollama stop "${model}" >> "${LOG_FILE}" 2>&1
            log "INFO" "Stopped Ollama model: ${model}"
            stopped=$((stopped + 1))
        fi
    done <<< "${models}"

    return 0
}

# --- Main --------------------------------------------------------------------

main() {
    local swap_kb
    swap_kb="$(get_swap_used_kb)"

    # If swap reading failed (returned 0), still log but do not act
    if [ "${swap_kb}" -eq 0 ]; then
        log "INFO" "Swap check: unable to read swap usage — skipping"
        return 0
    fi

    # Check if swap is above the aggressive threshold (stop models + purge)
    local do_stop_models=false
    if [ "${swap_kb}" -ge "${SWAP_AGGRESSIVE_KB}" ]; then
        do_stop_models=true
    fi

    # Check if swap is above the standard threshold (purge only)
    if [ "${swap_kb}" -lt "${SWAP_THRESHOLD_KB}" ]; then
        log "INFO" "Swap check: ${swap_kb} KB — below threshold (${SWAP_THRESHOLD_KB} KB), no action needed"
        return 0
    fi

    # Swap is above threshold — check if Ollama is active
    if ollama_is_running; then
        if ollama_has_active_model; then
            log "WARN" "Swap check: ${swap_kb} KB — above threshold but model active, skipping purge"
            # No desktop notification — this is expected behavior, not an alert
            return 2
        fi

        # Ollama is running but no active model — safe to stop idle models
        if [ "${do_stop_models}" = true ]; then
            log "INFO" "Swap check: ${swap_kb} KB — above aggressive threshold, stopping idle Ollama models"
            ollama_stop_all
            # Wait for models to unload
            sleep 2
        fi
    else
        log "INFO" "Swap check: ${swap_kb} KB — Ollama not running, proceeding with purge"
    fi

    # Record swap before purge
    local before_kb="${swap_kb}"

    # Run purge
    log "INFO" "Running sudo purge (swap was ${before_kb} KB)"
    if sudo /usr/sbin/purge 2>/dev/null; then
        # Re-read swap after purge
        local after_kb
        after_kb="$(get_swap_used_kb)"
        log "INFO" "Purge complete: swap ${before_kb} KB → ${after_kb} KB"
        # No desktop notification on success — only alert on failure
        return 1
    else
        log "ERROR" "sudo purge failed — check sudoers NOPASSWD entry for /usr/sbin/purge"
        notify "swap-guard" "Purge FAILED — check sudoers configuration"
        return 3
    fi
}

main "$@"
exit $?
