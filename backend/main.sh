#!/usr/bin/env bash
# ==============================================================================
# LostLink - Unix & Shell Scripting Campus Lost & Found System
# Module: main.sh (Master Interactive Terminal Application)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

show_header() {
    clear 2>/dev/null || echo ""
    echo -e "${COLOR_CYAN}${COLOR_BOLD}================================================================${COLOR_RESET}"
    echo -e "                   ${COLOR_WHITE}${COLOR_BOLD}LOSTLINK CAMPUS SYSTEM${COLOR_RESET}                       "
    echo -e "         ${COLOR_BLUE}Unix & Shell Scripting Application Engine${COLOR_RESET}              "
    echo -e "${COLOR_CYAN}${COLOR_BOLD}================================================================${COLOR_RESET}"
}

pause_prompt() {
    echo ""
    read -rp "Press [Enter] to continue..."
}

# ------------------------------------------------------------------------------
# 1. Record Management
# ------------------------------------------------------------------------------
menu_records() {
    while true; do
        show_header
        echo -e "${COLOR_BOLD}[ RECORD MANAGEMENT ]${COLOR_RESET}"
        echo "  1) Report Lost Item"
        echo "  2) Log Found Item"
        echo "  3) View Lost Items"
        echo "  4) View Found Items"
        echo "  5) Update Item Status"
        echo "  6) Delete Item"
        echo "  0) Back"
        echo ""
        read -rp "Select [0-6]: " ch
        ch="${ch//$'\r'/}"

        case "$ch" in
            1)
                echo ""
                echo -e "${COLOR_BOLD}Report Lost Item:${COLOR_RESET}"
                read -rp "Title (e.g. Dell XPS Laptop): " title
                read -rp "Category (Electronics/Personal/Documents/Accessories/Books): " cat
                read -rp "Description: " desc
                read -rp "Location Lost: " loc
                read -rp "Date (YYYY-MM-DD) [default: today]: " dt
                [[ -z "$dt" ]] && dt=$(date "+%Y-%m-%d")
                read -rp "Your Username: " user
                read -rp "Contact Email: " email
                bash "$SCRIPT_DIR/record_manager.sh" add-lost "$title" "$cat" "$desc" "$loc" "$dt" "$user" "$email"
                pause_prompt
                ;;
            2)
                echo ""
                echo -e "${COLOR_BOLD}Log Found Item:${COLOR_RESET}"
                read -rp "Title (e.g. Blue Titan Wallet): " title
                read -rp "Category (Electronics/Personal/Documents/Accessories/Books): " cat
                read -rp "Description: " desc
                read -rp "Location Found: " loc
                read -rp "Date (YYYY-MM-DD) [default: today]: " dt
                [[ -z "$dt" ]] && dt=$(date "+%Y-%m-%d")
                read -rp "Reported By (Username/Security): " user
                read -rp "Contact Email: " email
                bash "$SCRIPT_DIR/record_manager.sh" add-found "$title" "$cat" "$desc" "$loc" "$dt" "$user" "$email"
                pause_prompt
                ;;
            3)
                echo ""
                bash "$SCRIPT_DIR/record_manager.sh" list lost all
                pause_prompt
                ;;
            4)
                echo ""
                bash "$SCRIPT_DIR/record_manager.sh" list found all
                pause_prompt
                ;;
            5)
                echo ""
                read -rp "Item Type (lost/found): " itype
                read -rp "Item ID (e.g. LST001 / FND001): " iid
                read -rp "New Status (lost/matched/recovered/found/claimed/returned): " nst
                bash "$SCRIPT_DIR/record_manager.sh" update-status "$itype" "$iid" "$nst" "admin"
                pause_prompt
                ;;
            6)
                echo ""
                read -rp "Item Type (lost/found): " itype
                read -rp "Item ID: " iid
                bash "$SCRIPT_DIR/record_manager.sh" delete "$itype" "$iid" "admin"
                pause_prompt
                ;;
            0) break ;;
            *) echo -e "${COLOR_RED}Invalid option.${COLOR_RESET}"; sleep 1 ;;
        esac
    done
}

# ------------------------------------------------------------------------------
# 2. Search & Filtering
# ------------------------------------------------------------------------------
menu_search() {
    show_header
    echo -e "${COLOR_BOLD}[ SEARCH & FILTER RECORDS ]${COLOR_RESET}"
    echo ""
    read -rp "Keyword (leave blank for all): " kw
    read -rp "Scope [lost / found / all] (default: all): " stype
    [[ -z "$stype" ]] && stype="all"
    read -rp "Category filter (or 'all'): " scat
    [[ -z "$scat" ]] && scat="all"
    read -rp "Location filter (or 'all'): " sloc
    [[ -z "$sloc" ]] && sloc="all"

    echo ""
    bash "$SCRIPT_DIR/search_engine.sh" search "$stype" "$kw" "$scat" "$sloc" "all" "date_desc" --table
    pause_prompt
}

# ------------------------------------------------------------------------------
# 3. Smart Matching Engine
# ------------------------------------------------------------------------------
menu_matching() {
    show_header
    echo -e "${COLOR_BOLD}[ SMART MATCHING ENGINE ]${COLOR_RESET}"
    echo "Compares active lost items against found items using weighted scoring."
    echo ""
    read -rp "Minimum confidence score % [default: 25]: " thresh
    [[ -z "$thresh" ]] && thresh=25

    echo ""
    bash "$SCRIPT_DIR/matching_engine.sh" match-all --table "$thresh"
    pause_prompt
}

# ------------------------------------------------------------------------------
# 4. Claim Management
# ------------------------------------------------------------------------------
menu_claims() {
    while true; do
        show_header
        echo -e "${COLOR_BOLD}[ CLAIM MANAGEMENT ]${COLOR_RESET}"
        echo "  1) Submit Claim for Found Item"
        echo "  2) View All Claims"
        echo "  3) View Pending Claims"
        echo "  4) Review Claim (Approve / Reject)"
        echo "  0) Back"
        echo ""
        read -rp "Select [0-4]: " ch
        ch="${ch//$'\r'/}"

        case "$ch" in
            1)
                echo ""
                read -rp "Found Item ID (e.g. FND003): " fid
                read -rp "Your Username: " cuser
                read -rp "Proof of Ownership Details: " proof
                bash "$SCRIPT_DIR/claim_manager.sh" submit "$fid" "$cuser" "$proof"
                pause_prompt
                ;;
            2)
                echo ""
                bash "$SCRIPT_DIR/claim_manager.sh" list all
                pause_prompt
                ;;
            3)
                echo ""
                bash "$SCRIPT_DIR/claim_manager.sh" list pending
                pause_prompt
                ;;
            4)
                echo ""
                read -rp "Claim ID (e.g. CLM003): " cid
                read -rp "Decision (approve / reject): " dec
                read -rp "Review Notes: " notes
                bash "$SCRIPT_DIR/claim_manager.sh" review "$cid" "$dec" "admin" "$notes"
                pause_prompt
                ;;
            0) break ;;
            *) echo -e "${COLOR_RED}Invalid option.${COLOR_RESET}"; sleep 1 ;;
        esac
    done
}

# ------------------------------------------------------------------------------
# 5. Analytics & Reports
# ------------------------------------------------------------------------------
menu_analytics_reports() {
    while true; do
        show_header
        echo -e "${COLOR_BOLD}[ ANALYTICS & REPORTS ]${COLOR_RESET}"
        echo "  1) View Campus Recovery Statistics & Hotspots"
        echo "  2) Generate Daily Report"
        echo "  3) Generate Weekly Report"
        echo "  4) Generate Monthly Report"
        echo "  5) List Previously Generated Reports"
        echo "  0) Back"
        echo ""
        read -rp "Select [0-5]: " ch
        ch="${ch//$'\r'/}"

        case "$ch" in
            1)
                echo ""
                bash "$SCRIPT_DIR/analytics.sh" summary --table
                pause_prompt
                ;;
            2)
                echo ""
                bash "$SCRIPT_DIR/report_generator.sh" generate daily all "admin"
                pause_prompt
                ;;
            3)
                echo ""
                bash "$SCRIPT_DIR/report_generator.sh" generate weekly all "admin"
                pause_prompt
                ;;
            4)
                echo ""
                bash "$SCRIPT_DIR/report_generator.sh" generate monthly all "admin"
                pause_prompt
                ;;
            5)
                echo ""
                bash "$SCRIPT_DIR/report_generator.sh" list
                pause_prompt
                ;;
            0) break ;;
            *) echo -e "${COLOR_RED}Invalid option.${COLOR_RESET}"; sleep 1 ;;
        esac
    done
}

# ------------------------------------------------------------------------------
# 6. Backup & Restore
# ------------------------------------------------------------------------------
menu_backup_restore() {
    while true; do
        show_header
        echo -e "${COLOR_BOLD}[ BACKUP & RESTORE ]${COLOR_RESET}"
        echo "  1) Create Backup Snapshot (.tar.gz + SHA-256)"
        echo "  2) List Backups & Check Integrity"
        echo "  3) Restore Database from Archive"
        echo "  0) Back"
        echo ""
        read -rp "Select [0-3]: " ch
        ch="${ch//$'\r'/}"

        case "$ch" in
            1)
                echo ""
                read -rp "Retention policy (days to keep) [default: 7]: " rdays
                [[ -z "$rdays" ]] && rdays=7
                bash "$SCRIPT_DIR/backup_restore.sh" create "$rdays" false "admin"
                pause_prompt
                ;;
            2)
                echo ""
                bash "$SCRIPT_DIR/backup_restore.sh" list --table
                pause_prompt
                ;;
            3)
                echo ""
                read -rp "Backup filename to restore: " bfile
                bash "$SCRIPT_DIR/backup_restore.sh" restore "$bfile" false "admin"
                pause_prompt
                ;;
            0) break ;;
            *) echo -e "${COLOR_RED}Invalid option.${COLOR_RESET}"; sleep 1 ;;
        esac
    done
}

# ------------------------------------------------------------------------------
# 7. System Monitor & Audit Logs
# ------------------------------------------------------------------------------
menu_system_logs() {
    while true; do
        show_header
        echo -e "${COLOR_BOLD}[ SYSTEM MONITOR & LOGS ]${COLOR_RESET}"
        echo "  1) System Health & Resource Monitor"
        echo "  2) View Activity & Audit Logs"
        echo "  0) Back"
        echo ""
        read -rp "Select [0-2]: " ch
        ch="${ch//$'\r'/}"

        case "$ch" in
            1)
                echo ""
                bash "$SCRIPT_DIR/system_monitor.sh" status --table
                pause_prompt
                ;;
            2)
                echo ""
                read -rp "Number of lines to view [default: 20]: " nlines
                [[ -z "$nlines" ]] && nlines=20
                read -rp "Filter keyword (or leave empty): " kw
                echo ""
                bash "$SCRIPT_DIR/audit_logger.sh" view "$nlines" "$kw" --table
                pause_prompt
                ;;
            0) break ;;
            *) echo -e "${COLOR_RED}Invalid option.${COLOR_RESET}"; sleep 1 ;;
        esac
    done
}

# ------------------------------------------------------------------------------
# Main Application Menu
# ------------------------------------------------------------------------------
main() {
    while true; do
        show_header
        echo -e "${COLOR_BOLD}MAIN APPLICATION MENU:${COLOR_RESET}"
        echo "  [1] Lost & Found Records       (Add, View, Update, Delete)"
        echo "  [2] Search & Filter Records    (Multi-criteria Unix Filter)"
        echo "  [3] Smart Matching Engine      (AI Weighted Scoring)"
        echo "  [4] Claim Management           (Submit & Review Claims)"
        echo "  [5] Analytics & Reports        (Statistics, Hotspots, Reports)"
        echo "  [6] Backup & Restore           (Snapshots, SHA-256, Recovery)"
        echo "  [7] System Monitor & Logs      (CPU, RAM, Disk, Audit Trail)"
        echo "  [0] Exit"
        echo ""
        read -rp "Enter choice [0-7]: " choice
        choice="${choice//$'\r'/}"

        case "$choice" in
            1) menu_records ;;
            2) menu_search ;;
            3) menu_matching ;;
            4) menu_claims ;;
            5) menu_analytics_reports ;;
            6) menu_backup_restore ;;
            7) menu_system_logs ;;
            0)
                echo -e "\n${COLOR_GREEN}Exiting LostLink. Goodbye!${COLOR_RESET}\n"
                exit 0
                ;;
            *)
                echo -e "${COLOR_RED}Invalid selection. Choose 0 to 7.${COLOR_RESET}"
                sleep 1
                ;;
        esac
    done
}

main "$@"
