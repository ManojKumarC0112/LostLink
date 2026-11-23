#!/usr/bin/env bash
# ==============================================================================
# LostLink - Unix & Shell Scripting Campus Lost & Found System
# Module: search_engine.sh (Member 2: Advanced Search, Filtering & Sorting)
# Commands Used: grep, awk, cut, sort, uniq, tr, mktemp, wc
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# ------------------------------------------------------------------------------
# Multi-Criteria Search & Filter
# Parameters:
#   $1 = type ("lost", "found", or "all")
#   $2 = keyword (title/description search)
#   $3 = category filter ("all" or e.g. "Electronics")
#   $4 = location filter ("all" or e.g. "Library")
#   $5 = status filter ("all" or e.g. "lost", "found", "returned")
#   $6 = sort_by ("date_desc", "date_asc", "title", "id")
#   $7 = output_mode ("--json" or "--table")
# ------------------------------------------------------------------------------
execute_search() {
    local target_type="${1:-all}"
    local keyword="${2:-}"
    local category="${3:-all}"
    local location="${4:-all}"
    local status="${5:-all}"
    local sort_by="${6:-date_desc}"
    local output_mode="${7:-table}"

    # Build combined dataset
    local temp_combined
    temp_combined=$(mktemp)

    if [[ "$target_type" == "lost" ]]; then
        tail -n +2 "$LOST_CSV" | awk -F',' '{print "LOST," $0}' >> "$temp_combined"
    elif [[ "$target_type" == "found" ]]; then
        tail -n +2 "$FOUND_CSV" | awk -F',' '{print "FOUND," $0}' >> "$temp_combined"
    else
        tail -n +2 "$LOST_CSV" | awk -F',' '{print "LOST," $0}' >> "$temp_combined"
        tail -n +2 "$FOUND_CSV" | awk -F',' '{print "FOUND," $0}' >> "$temp_combined"
    fi

    # Filter with awk using regular expressions and case-insensitivity
    local temp_filtered
    temp_filtered=$(mktemp)

    awk -F',' -v kw="$keyword" -v cat="$category" -v loc="$location" -v stat="$status" '
    BEGIN {
        kw = tolower(kw)
        cat = tolower(cat)
        loc = tolower(loc)
        stat = tolower(stat)
    }
    {
        # Fields:
        # $1=TYPE, $2=ID, $3=TITLE, $4=CATEGORY, $5=DESC, $6=LOCATION, $7=DATE, $8=USER, $9=EMAIL, $10=STATUS, $11=CREATED
        row_type = $1
        row_id = $2
        row_title = $3
        row_cat = $4
        row_desc = $5
        row_loc = $6
        row_date = $7
        row_stat = $10

        # Check Keyword match across Title, Description, Location, and Category
        if (kw != "" && kw != "all") {
            full_text = tolower(row_title " " row_desc " " row_loc " " row_cat)
            if (index(full_text, kw) == 0) next
        }

        # Check Category
        if (cat != "" && cat != "all") {
            if (tolower(row_cat) != cat) next
        }

        # Check Location
        if (loc != "" && loc != "all") {
            if (index(tolower(row_loc), loc) == 0) next
        }

        # Check Status
        if (stat != "" && stat != "all") {
            if (tolower(row_stat) != stat) next
        }

        print $0
    }
    ' "$temp_combined" > "$temp_filtered"

    # Sort using Unix sort
    local temp_sorted
    temp_sorted=$(mktemp)

    case "$sort_by" in
        date_asc)
            sort -t',' -k7,7 "$temp_filtered" > "$temp_sorted"
            ;;
        title)
            sort -t',' -k3,3 -f "$temp_filtered" > "$temp_sorted"
            ;;
        id)
            sort -t',' -k2,2 "$temp_filtered" > "$temp_sorted"
            ;;
        date_desc|*)
            sort -t',' -k7,7r "$temp_filtered" > "$temp_sorted"
            ;;
    esac

    # Output formatting
    if [[ "$output_mode" == "--json" ]]; then
        awk -F',' '
        BEGIN {
            print "["
        }
        {
            if (NR > 1) print ","
            # Escape strings
            title = $3; gsub(/"/, "\\\"", title)
            desc = $5; gsub(/"/, "\\\"", desc)
            loc = $6; gsub(/"/, "\\\"", loc)
            printf "  {\"type\": \"%s\", \"id\": \"%s\", \"title\": \"%s\", \"category\": \"%s\", \"description\": \"%s\", \"location\": \"%s\", \"date\": \"%s\", \"reported_by\": \"%s\", \"status\": \"%s\"}", $1, $2, title, $4, desc, loc, $7, $8, $10
        }
        END {
            print "\n]"
        }
        ' "$temp_sorted"
    else
        local count
        count=$(wc -l < "$temp_sorted")
        print_header "SEARCH RESULTS: Found $count matches (Keyword: '\''${keyword:-<none>}'\'', Category: $category, Location: $location)"
        
        if [[ $count -eq 0 ]]; then
            echo -e "${COLOR_YELLOW}No records matched your search criteria.${COLOR_RESET}\n"
        else
            awk -F',' '
            BEGIN {
                printf "%-5s | %-8s | %-25s | %-12s | %-20s | %-10s | %-9s\n", "TYPE", "ID", "TITLE", "CATEGORY", "LOCATION", "DATE", "STATUS"
                print "-------------------------------------------------------------------------------------------------------"
            }
            {
                printf "%-5s | %-8s | %-25.25s | %-12.12s | %-20.20s | %-10s | %-9s\n", $1, $2, $3, $4, $6, $7, $10
            }
            ' "$temp_sorted"
            echo ""
        fi
    fi

    # Clean up temporary files
    rm -f "$temp_combined" "$temp_filtered" "$temp_sorted"
}

# ------------------------------------------------------------------------------
# CLI Router
# ------------------------------------------------------------------------------
case "${1:-}" in
    search)
        execute_search "${2:-all}" "${3:-}" "${4:-all}" "${5:-all}" "${6:-all}" "${7:-date_desc}" "${8:---table}"
        ;;
    quick)
        # Quick single-keyword search
        execute_search "all" "$2" "all" "all" "all" "date_desc" "${3:---table}"
        ;;
    *)
        echo "Usage: $0 search [type:lost|found|all] [keyword] [category] [location] [status] [sort_by] [--json|--table]"
        echo "       $0 quick <keyword> [--json|--table]"
        ;;
esac
