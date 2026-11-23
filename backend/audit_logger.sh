#!/usr/bin/env bash
# ==============================================================================
# LostLink - Unix & Shell Scripting Campus Lost & Found System
# Module: audit_logger.sh (Member 3: Activity & Security Audit Trail)
# Commands Used: awk, grep, tail, wc, sort, uniq, date
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# ------------------------------------------------------------------------------
# Append Audit Entry
# ------------------------------------------------------------------------------
record_log() {
    local module="${1:-APP}"
    local user="${2:-system}"
    local message="$3"

    log_audit "$module" "$user" "$message"
    print_success "Logged audit entry for [$module] by $user"
}

# ------------------------------------------------------------------------------
# View Audit Logs with Filtering & Pagination
# ------------------------------------------------------------------------------
view_logs() {
    local limit="${1:-25}"
    local filter_kw="${2:-}"
    local output_mode="${3:---table}"

    if [[ ! -f "$AUDIT_LOG" ]]; then
        if [[ "$output_mode" == "--json" ]]; then
            echo "[]"
        else
            print_warning "No audit log file found."
        fi
        return 0
    fi

    # Filter with grep if keyword provided
    local filtered_stream
    if [[ -n "$filter_kw" && "$filter_kw" != "all" ]]; then
        filtered_stream=$(grep -i "$filter_kw" "$AUDIT_LOG" | tail -n "$limit")
    else
        filtered_stream=$(tail -n "$limit" "$AUDIT_LOG")
    fi

    if [[ "$output_mode" == "--json" ]]; then
        echo "$filtered_stream" | awk '
        BEGIN { print "[" }
        NF > 0 {
            if (NR > 1) print ","
            # Line format: [YYYY-MM-DD HH:MM:SS] [MODULE] [USER] Details...
            match($0, /^\[([0-9\-: ]+)\] \[([A-Z_]+)\] \[([a-zA-Z0-9_\.]+)\] (.*)$/, arr)
            timestamp = arr[1]
            module = arr[2]
            user = arr[3]
            details = arr[4]
            gsub(/"/, "\\\"", details)
            printf "  {\"timestamp\": \"%s\", \"module\": \"%s\", \"user\": \"%s\", \"details\": \"%s\"}", timestamp, module, user, details
        }
        END { print "\n]" }
        '
    else
        print_header "ACTIVITY & AUDIT LOG (Last $limit records, Filter: '\''${filter_kw:-all}'\'')"
        if [[ -z "$filtered_stream" ]]; then
            echo -e "${COLOR_YELLOW}No matching log entries found.${COLOR_RESET}\n"
        else
            echo "$filtered_stream" | awk '
            {
                # Colored terminal presentation
                match($0, /^\[([0-9\-: ]+)\] \[([A-Z_]+)\] \[([a-zA-Z0-9_\.]+)\] (.*)$/, arr)
                printf "\033[36m%-19s\033[0m | \033[33m%-12s\033[0m | \033[32m%-12s\033[0m | %s\n", arr[1], arr[2], arr[3], arr[4]
            }
            '
            echo ""
        fi
    fi
}

# ------------------------------------------------------------------------------
# CLI Router
# ------------------------------------------------------------------------------
case "${1:-}" in
    log)
        record_log "$2" "$3" "$4"
        ;;
    view)
        view_logs "${2:-25}" "${3:-}" "${4:---table}"
        ;;
    *)
        echo "Usage: $0 log <module> <user> <message>"
        echo "       $0 view [limit] [filter_keyword] [--table|--json]"
        ;;
esac
