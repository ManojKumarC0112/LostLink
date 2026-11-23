#!/usr/bin/env bash
# ==============================================================================
# LostLink - Unix & Shell Scripting Campus Lost & Found System
# Module: backup_restore.sh (Member 4: Backup, Integrity Check & Rotation)
# Commands Used: tar, gzip, sha256sum, find, date, mktemp, rm, ls
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Helper for SHA256 calculation across Linux / Mac / Git Bash
calc_sha256() {
    local target="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$target" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$target" | awk '{print $1}'
    else
        echo "UNVERIFIED"
    fi
}

# ------------------------------------------------------------------------------
# Create Backup Archive with SHA256 & Auto-Rotation
# ------------------------------------------------------------------------------
create_backup() {
    local retention_days="${1:-7}"
    local output_json="${2:-false}"
    local user="${3:-system}"

    ensure_dirs
    local timestamp
    timestamp=$(date "+%Y%m%d_%H%M%S")
    local archive_name="lostlink_backup_${timestamp}.tar.gz"
    local archive_path="$BACKUP_DIR/$archive_name"
    local checksum_path="$archive_path.sha256"

    # Create compressed tarball from database, logs, and reports
    (cd "$PROJECT_ROOT" && tar -czf "$archive_path" database/ logs/ reports/)

    if [[ ! -f "$archive_path" ]]; then
        if [[ "$output_json" == "--json" ]]; then
            echo '{"success": false, "message": "Failed to create tar archive"}'
        else
            print_error "Failed to create backup archive."
        fi
        return 1
    fi

    # Calculate SHA256 Checksum
    local checksum
    checksum=$(calc_sha256 "$archive_path")
    echo "$checksum  $archive_name" > "$checksum_path"

    # Backup Retention Policy: Remove backups older than N days
    local purged_count=0
    if command -v find >/dev/null 2>&1; then
        purged_count=$(find "$BACKUP_DIR" -name "lostlink_backup_*.tar.gz" -mtime +"$retention_days" -print 2>/dev/null | wc -l)
        find "$BACKUP_DIR" -name "lostlink_backup_*.tar.gz" -mtime +"$retention_days" -delete 2>/dev/null
        find "$BACKUP_DIR" -name "lostlink_backup_*.sha256" -mtime +"$retention_days" -delete 2>/dev/null
    fi

    local size_human
    size_human=$(ls -lh "$archive_path" | awk '{print $5}')

    log_audit "BACKUP" "$user" "Created backup $archive_name (Size: $size_human, Purged older: $purged_count)"

    if [[ "$output_json" == "--json" ]]; then
        cat <<EOF
{
  "success": true,
  "archive_name": "$archive_name",
  "archive_path": "$archive_path",
  "size": "$size_human",
  "sha256": "$checksum",
  "timestamp": "$timestamp",
  "purged_old_backups": $purged_count
}
EOF
    else
        print_success "Backup archive created successfully!"
        echo -e "  • File:     ${COLOR_CYAN}$archive_path${COLOR_RESET}"
        echo -e "  • Size:     ${COLOR_WHITE}$size_human${COLOR_RESET}"
        echo -e "  • SHA256:   ${COLOR_YELLOW}$checksum${COLOR_RESET}"
        echo -e "  • Rotation: Cleaned backups older than $retention_days days ($purged_count removed)"
    fi
}

# ------------------------------------------------------------------------------
# List Backups with Integrity Status
# ------------------------------------------------------------------------------
list_backups() {
    local output_mode="${1:---table}"

    local count
    count=$(find "$BACKUP_DIR" -maxdepth 1 -name "*.tar.gz" 2>/dev/null | wc -l)

    if [[ "$output_mode" == "--json" ]]; then
        echo "["
        local first=1
        for f in "$BACKUP_DIR"/*.tar.gz; do
            [[ ! -f "$f" ]] && continue
            local bname
            bname=$(basename "$f")
            local sz
            sz=$(ls -lh "$f" | awk '{print $5}')
            local dt
            dt=$(date -r "$f" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || date "+%Y-%m-%d %H:%M:%S")
            local status="VALID"
            if [[ -f "$f.sha256" ]]; then
                local expected current
                expected=$(awk '{print $1}' "$f.sha256")
                current=$(calc_sha256 "$f")
                [[ "$expected" != "$current" ]] && status="CORRUPTED"
            else
                status="NO_CHECKSUM"
            fi

            if [[ $first -eq 0 ]]; then echo ","; fi
            printf '  {"filename": "%s", "size": "%s", "date": "%s", "status": "%s"}' "$bname" "$sz" "$dt" "$status"
            first=0
        done
        echo -e "\n]"
    else
        print_header "AVAILABLE DATABASE BACKUPS (Count: $count)"
        if [[ $count -eq 0 ]]; then
            echo -e "${COLOR_YELLOW}No backup archives found in $BACKUP_DIR${COLOR_RESET}\n"
            return
        fi

        printf "%-38s | %-8s | %-19s | %-12s\n" "ARCHIVE FILENAME" "SIZE" "CREATED DATE" "INTEGRITY"
        echo "-------------------------------------------------------------------------------------"
        for f in "$BACKUP_DIR"/*.tar.gz; do
            [[ ! -f "$f" ]] && continue
            local bname sz dt status
            bname=$(basename "$f")
            sz=$(ls -lh "$f" | awk '{print $5}')
            dt=$(date -r "$f" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || date "+%Y-%m-%d %H:%M:%S")
            status="${COLOR_GREEN}VALID${COLOR_RESET}"
            if [[ -f "$f.sha256" ]]; then
                local expected current
                expected=$(awk '{print $1}' "$f.sha256")
                current=$(calc_sha256 "$f")
                if [[ "$expected" != "$current" ]]; then
                    status="${COLOR_RED}CORRUPTED${COLOR_RESET}"
                fi
            else
                status="${COLOR_YELLOW}NO_CHECKSUM${COLOR_RESET}"
            fi
            printf "%-38s | %-8s | %-19s | %b\n" "$bname" "$sz" "$dt" "$status"
        done
        echo ""
    fi
}

# ------------------------------------------------------------------------------
# Restore Database from Backup
# ------------------------------------------------------------------------------
restore_backup() {
    local target_filename="$1"
    local output_json="${2:-false}"
    local user="${3:-admin}"

    local full_path="$BACKUP_DIR/$target_filename"
    if [[ ! -f "$full_path" ]]; then
        full_path="$target_filename"
    fi

    if [[ ! -f "$full_path" ]]; then
        if [[ "$output_json" == "--json" ]]; then
            echo '{"success": false, "message": "Backup file not found"}'
        else
            print_error "Backup file '$target_filename' does not exist."
        fi
        return 1
    fi

    # Verify SHA256 checksum if present
    if [[ -f "$full_path.sha256" ]]; then
        local expected current
        expected=$(awk '{print $1}' "$full_path.sha256")
        current=$(calc_sha256 "$full_path")
        if [[ "$expected" != "$current" ]]; then
            if [[ "$output_json" == "--json" ]]; then
                echo '{"success": false, "message": "SHA256 checksum mismatch! Archive corrupted."}'
            else
                print_error "Checksum verification failed! File is corrupted."
            fi
            return 1
        fi
    fi

    # Extract archive into project root
    (cd "$PROJECT_ROOT" && tar -xzf "$full_path")

    log_audit "RESTORE" "$user" "Restored database from $(basename "$full_path")"

    if [[ "$output_json" == "--json" ]]; then
        echo "{\"success\": true, \"restored_file\": \"$(basename "$full_path")\"}"
    else
        print_success "Database, logs, and reports restored successfully from $(basename "$full_path")!"
    fi
}

# ------------------------------------------------------------------------------
# CLI Router
# ------------------------------------------------------------------------------
case "${1:-}" in
    create)
        create_backup "${2:-7}" "${3:-false}" "${4:-admin}"
        ;;
    list)
        list_backups "${2:---table}"
        ;;
    restore)
        restore_backup "$2" "${3:-false}" "${4:-admin}"
        ;;
    *)
        echo "Usage: $0 create [retention_days] [--json] [user]"
        echo "       $0 list [--table|--json]"
        echo "       $0 restore <backup_file> [--json] [user]"
        ;;
esac
