#!/usr/bin/env bash
# ==============================================================================
# LostLink - Unix & Shell Scripting Campus Lost & Found System
# Module: analytics.sh (Member 4: Analytics & Statistics Engine)
# Commands Used: awk, wc, sort, uniq, cut, tr
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

get_analytics() {
    local output_mode="${1:---table}"

    # Calculate metrics with awk
    local stats_data
    stats_data=$(awk -F',' '
    BEGIN {
        total_lost = 0
        total_found = 0
        returned = 0
        pending_claims = 0
        matched_items = 0
    }
    # File 1: lost_items.csv
    FILENAME ~ /lost_items\.csv$/ && FNR > 1 {
        total_lost++
        if ($9 == "recovered") returned++
        if ($9 == "matched") matched_items++
        cat_count[$3]++
        loc_count[$5]++
    }
    # File 2: found_items.csv
    FILENAME ~ /found_items\.csv$/ && FNR > 1 {
        total_found++
        if ($9 == "returned") returned++
        cat_count[$3]++
    }
    # File 3: claims.csv
    FILENAME ~ /claims\.csv$/ && FNR > 1 {
        if ($6 == "pending") pending_claims++
        if ($6 == "approved") approved_claims++
    }
    END {
        rec_rate = 0
        if (total_lost > 0) {
            rec_rate = (returned / total_lost) * 100
        }
        printf "%d|%d|%d|%d|%d|%.1f\n", total_lost, total_found, pending_claims, returned, matched_items, rec_rate
    }
    ' "$LOST_CSV" "$FOUND_CSV" "$CLAIMS_CSV")

    local t_lost t_found p_claims t_returned m_items rec_rate
    t_lost=$(echo "$stats_data" | cut -d'|' -f1)
    t_found=$(echo "$stats_data" | cut -d'|' -f2)
    p_claims=$(echo "$stats_data" | cut -d'|' -f3)
    t_returned=$(echo "$stats_data" | cut -d'|' -f4)
    m_items=$(echo "$stats_data" | cut -d'|' -f5)
    rec_rate=$(echo "$stats_data" | cut -d'|' -f6)

    # Category breakdown with awk
    local cat_json
    cat_json=$(awk -F',' '
    FNR > 1 {
        if (FILENAME ~ /lost_items\.csv$/ || FILENAME ~ /found_items\.csv$/) {
            cats[$3]++
        }
    }
    END {
        printf "["
        first = 1
        for (c in cats) {
            if (!first) printf ", "
            printf "{\"category\": \"%s\", \"count\": %d}", c, cats[c]
            first = 0
        }
        printf "]"
    }
    ' "$LOST_CSV" "$FOUND_CSV")

    # Location hotspots with awk and sort
    local loc_json
    loc_json=$(awk -F',' '
    FNR > 1 && FILENAME ~ /lost_items\.csv$/ {
        locs[$5]++
    }
    END {
        for (l in locs) {
            printf "%d|%s\n", locs[l], l
        }
    }
    ' "$LOST_CSV" | sort -t'|' -k1,1nr | head -n 5 | awk -F'|' '
    BEGIN { printf "[" }
    {
        if (NR > 1) printf ", "
        printf "{\"location\": \"%s\", \"count\": %d}", $2, $1
    }
    END { printf "]" }
    ')

    if [[ "$output_mode" == "--json" ]]; then
        cat <<EOF
{
  "total_lost": $t_lost,
  "total_found": $t_found,
  "pending_claims": $p_claims,
  "returned_items": $t_returned,
  "matched_items": $m_items,
  "recovery_rate_percent": $rec_rate,
  "categories": $cat_json,
  "top_loss_locations": $loc_json
}
EOF
    else
        print_header "LOSTLINK CAMPUS ANALYTICS & RECOVERY METRICS"
        echo -e "${COLOR_BOLD}Core Key Performance Indicators:${COLOR_RESET}"
        printf "  %-26s: ${COLOR_CYAN}%s${COLOR_RESET}\n" "Total Lost Items Reported" "$t_lost"
        printf "  %-26s: ${COLOR_BLUE}%s${COLOR_RESET}\n" "Total Found Items Logged" "$t_found"
        printf "  %-26s: ${COLOR_YELLOW}%s${COLOR_RESET}\n" "Pending Claims for Review" "$p_claims"
        printf "  %-26s: ${COLOR_GREEN}%s${COLOR_RESET}\n" "Successfully Returned Items" "$t_returned"
        printf "  %-26s: ${COLOR_MAGENTA}%s${COLOR_RESET}\n" "Candidate Matched Items" "$m_items"
        printf "  %-26s: ${COLOR_BOLD}${COLOR_GREEN}%.1f%%${COLOR_RESET}\n\n" "Campus Item Recovery Rate" "$rec_rate"

        echo -e "${COLOR_BOLD}Top Campus Loss Hotspots (High Incident Zones):${COLOR_RESET}"
        awk -F',' '
        FNR > 1 && FILENAME ~ /lost_items\.csv$/ { locs[$5]++ }
        END {
            for (l in locs) printf "%2d incident(s) - %s\n", locs[l], l
        }
        ' "$LOST_CSV" | sort -nr | head -n 5 | sed 's/^/  • /'
        echo ""
    fi
}

case "${1:-}" in
    stats|summary)
        get_analytics "${2:---table}"
        ;;
    *)
        get_analytics "--table"
        ;;
esac
