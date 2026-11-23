#!/usr/bin/env bash
# ==============================================================================
# LostLink - Unix & Shell Scripting Campus Lost & Found System
# Module: utils.sh (Shared Utilities, Paths, Colors & JSON Helpers)
# ==============================================================================

# Determine absolute path to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Standard Directory Definitions
DB_DIR="$PROJECT_ROOT/database"
LOG_DIR="$PROJECT_ROOT/logs"
REPORTS_DIR="$PROJECT_ROOT/reports"
BACKUP_DIR="$PROJECT_ROOT/backups"
CRON_DIR="$PROJECT_ROOT/cron"

# Database CSV Files
USERS_CSV="$DB_DIR/users.csv"
LOST_CSV="$DB_DIR/lost_items.csv"
FOUND_CSV="$DB_DIR/found_items.csv"
CLAIMS_CSV="$DB_DIR/claims.csv"
AUDIT_LOG="$LOG_DIR/audit.log"

# Terminal ANSI Color Codes
COLOR_RESET="\033[0m"
COLOR_BOLD="\033[1m"
COLOR_RED="\033[31m"
COLOR_GREEN="\033[32m"
COLOR_YELLOW="\033[33m"
COLOR_BLUE="\033[34m"
COLOR_MAGENTA="\033[35m"
COLOR_CYAN="\033[36m"
COLOR_WHITE="\033[37m"

# Ensure all necessary directories exist
ensure_dirs() {
    mkdir -p "$DB_DIR" "$LOG_DIR" "$REPORTS_DIR" "$BACKUP_DIR" "$CRON_DIR"
}

# Audit Logging Function
# Usage: log_audit "MODULE" "USER" "Action description..."
log_audit() {
    local module="${1:-GENERAL}"
    local user="${2:-system}"
    local details="${3:-No details provided}"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    ensure_dirs
    echo "[$timestamp] [$module] [$user] $details" >> "$AUDIT_LOG"
}

# Colored Notification Messages
print_header() {
    local title="$1"
    echo -e "${COLOR_CYAN}${COLOR_BOLD}================================================================${COLOR_RESET}"
    echo -e "  ${COLOR_WHITE}${COLOR_BOLD}$title${COLOR_RESET}"
    echo -e "${COLOR_CYAN}${COLOR_BOLD}================================================================${COLOR_RESET}"
}

print_success() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $1"
}

print_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $1" >&2
}

print_warning() {
    echo -e "${COLOR_YELLOW}[WARNING]${COLOR_RESET} $1"
}

print_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $1"
}

# Generate next sequential alphanumeric ID (e.g., LST008, FND007, CLM005)
# Usage: get_next_id "$csv_file" "LST"
get_next_id() {
    local file="$1"
    local prefix="$2"

    if [[ ! -f "$file" ]] || [[ $(wc -l < "$file") -le 1 ]]; then
        echo "${prefix}001"
        return
    fi

    local max_num
    max_num=$(tail -n +2 "$file" | cut -d',' -f1 | grep "^$prefix" | sed "s/^$prefix//" | sort -n | tail -n 1)
    
    if [[ -z "$max_num" ]]; then
        echo "${prefix}001"
    else
        printf "%s%03d\n" "$prefix" $((10#$max_num + 1))
    fi
}

# Utility: Validation Helpers using Bash Regex
validate_phone() {
    local phone="$1"
    if [[ "$phone" =~ ^\+?[0-9\ -]{7,15}$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_email() {
    local email="$1"
    if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Utility: JSON Escaping
escape_json_val() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/}"
    s="${s//$'\t'/\\t}"
    echo "$s"
}

# Convert any CSV with headers to clean JSON Array using standard Unix awk
# Usage: csv_to_json "$csv_file"
csv_to_json() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "[]"
        return
    fi

    awk -F',' '
    BEGIN {
        print "["
    }
    NR == 1 {
        for (i=1; i<=NF; i++) {
            # Trim quotes or spaces from header
            gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", $i)
            headers[i] = $i
        }
        num_headers = NF
        next
    }
    NF > 0 {
        if (NR > 2) print ","
        print "  {"
        for (i=1; i<=num_headers; i++) {
            val = $i
            gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", val)
            gsub(/"/, "\\\"", val)
            printf "    \"%s\": \"%s\"%s\n", headers[i], val, (i < num_headers ? "," : "")
        }
        printf "  }"
    }
    END {
        print "\n]"
    }
    ' "$file"
}

# Initialize directories on source
ensure_dirs
