#!/usr/bin/env bash
# ==============================================================================
# LostLink - Unix & Shell Scripting Campus Lost & Found System
# Module: matching_engine.sh (Member 2: High-Performance Smart Weighted Matching)
# Concepts Used: Single-pass awk in-memory array comparison, token dictionary,
#                stop-word elimination, Jaccard overlap, calendar arithmetic
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

run_matching_all() {
    local output_mode="${1:---table}"
    local min_threshold="${2:-25}"

    # Execute entire cross-comparison in a single awk process for maximum speed
    local raw_matches
    raw_matches=$(awk -F',' -v thresh="$min_threshold" '
    BEGIN {
        stop_words = " the a an in on with and of to is for by my at near under from on floor room block desk hall front gate table bench case "
        l_count = 0
    }
    # Pass 1: Load active lost items into memory
    FILENAME ~ /lost_items\.csv$/ && FNR > 1 {
        if ($9 == "recovered" || $9 == "closed") next
        l_count++
        l_id[l_count] = $1
        l_title[l_count] = $2
        l_cat[l_count] = $3
        l_desc[l_count] = $4
        l_loc[l_count] = $5
        l_date[l_count] = $6
        next
    }
    # Pass 2: Compare each active found item against all lost items
    FILENAME ~ /found_items\.csv$/ && FNR > 1 {
        if ($9 == "returned" || $9 == "closed") next
        f_id = $1
        f_title = $2
        f_cat = $3
        f_desc = $4
        f_loc = $5
        f_date = $6

        for (i = 1; i <= l_count; i++) {
            # 1. CATEGORY MATCH (35%)
            cat_score = 0
            if (tolower(l_cat[i]) == tolower(f_cat)) {
                cat_score = 35
            }

            # 2. KEYWORD OVERLAP (35%)
            delete l_dict
            clean_l = tolower(l_title[i] " " l_desc[i])
            gsub(/[^a-z0-9 ]/, " ", clean_l)
            n_l = split(clean_l, words_l, " ")
            for (w_idx = 1; w_idx <= n_l; w_idx++) {
                w = words_l[w_idx]
                if (length(w) > 2 && index(stop_words, " " w " ") == 0) {
                    l_dict[w] = 1
                }
            }

            clean_f = tolower(f_title " " f_desc)
            gsub(/[^a-z0-9 ]/, " ", clean_f)
            n_f = split(clean_f, words_f, " ")
            matches = 0
            total_unique = 0
            for (w in l_dict) total_unique++

            for (w_idx = 1; w_idx <= n_f; w_idx++) {
                w = words_f[w_idx]
                if (length(w) > 2 && index(stop_words, " " w " ") == 0) {
                    if (l_dict[w] == 1) {
                        matches++
                        l_dict[w] = 2
                    } else if (l_dict[w] == 0) {
                        total_unique++
                    }
                }
            }

            key_score = 0
            if (total_unique > 0) {
                key_score = int((matches / total_unique) * 35)
                if (matches > 0 && key_score < 10) key_score = 10
            }
            if (key_score > 35) key_score = 35

            # 3. LOCATION PROXIMITY (20%)
            loc_score = 0
            clean_lloc = tolower(l_loc[i])
            clean_floc = tolower(f_loc)
            if (clean_lloc == clean_floc) {
                loc_score = 20
            } else {
                split(clean_lloc, loc_tokens, " ")
                for (k in loc_tokens) {
                    token = loc_tokens[k]
                    if (length(token) > 3 && index(clean_floc, token) > 0) {
                        loc_score = 15
                        break
                    }
                }
            }

            # 4. DATE PROXIMITY (10%)
            split(l_date[i], ld, "-")
            split(f_date, fd, "-")
            diff = (ld[1]*365 + ld[2]*30 + ld[3]) - (fd[1]*365 + fd[2]*30 + fd[3])
            if (diff < 0) diff = -diff

            if (diff <= 2) date_score = 10
            else if (diff <= 7) date_score = 5
            else date_score = 0

            # TOTAL WEIGHTED SCORE
            total = cat_score + key_score + loc_score + date_score

            if (total >= thresh) {
                conf = (total >= 70) ? "HIGH" : (total >= 45 ? "MODERATE" : "LOW")
                printf "%d|%s|%s|%s|%s|%s|%s|%s|%d|%d|%d|%d|%s|%s|%s|%s\n", \
                    total, conf, l_id[i], l_title[i], l_cat[i], f_id, f_title, f_cat, \
                    cat_score, key_score, loc_score, date_score, l_date[i], f_date, l_loc[i], f_loc
            }
        }
    }
    ' "$LOST_CSV" "$FOUND_CSV")

    # Sort results by score descending
    local sorted_matches
    if [[ -n "$raw_matches" ]]; then
        sorted_matches=$(echo "$raw_matches" | sort -t'|' -k1,1nr)
    else
        sorted_matches=""
    fi

    if [[ "$output_mode" == "--json" ]]; then
        if [[ -z "$sorted_matches" ]]; then
            echo "[]"
            return
        fi
        echo "$sorted_matches" | awk -F'|' '
        BEGIN { print "[" }
        NF > 0 {
            if (NR > 1) print ","
            l_t = $4; gsub(/"/, "\\\"", l_t)
            f_t = $7; gsub(/"/, "\\\"", f_t)
            printf "  {\"score\": %d, \"confidence\": \"%s\", \"lost_id\": \"%s\", \"lost_title\": \"%s\", \"lost_category\": \"%s\", \"found_id\": \"%s\", \"found_title\": \"%s\", \"found_category\": \"%s\", \"breakdown\": {\"category\": %d, \"keywords\": %d, \"location\": %d, \"date\": %d}, \"lost_date\": \"%s\", \"found_date\": \"%s\", \"lost_location\": \"%s\", \"found_location\": \"%s\"}", $1, $2, $3, l_t, $5, $6, f_t, $8, $9, $10, $11, $12, $13, $14, $15, $16
        }
        END { print "\n]" }
        '
    else
        local match_count
        match_count=$(echo "$sorted_matches" | grep -c "^[0-9]" || echo 0)
        print_header "SMART MATCHING ENGINE: Found $match_count Candidate Matches"
        
        if [[ $match_count -eq 0 ]]; then
            echo -e "${COLOR_YELLOW}No candidate matches found above $min_threshold% threshold.${COLOR_RESET}\n"
        else
            echo "$sorted_matches" | awk -F'|' '
            BEGIN {
                printf "%-6s | %-10s | %-8s | %-22s | %-8s | %-22s | %-18s\n", "SCORE", "CONFIDENCE", "LOST ID", "LOST TITLE", "FOUND ID", "FOUND TITLE", "SCORE BREAKDOWN"
                print "------------------------------------------------------------------------------------------------------------------"
            }
            {
                breakdown = sprintf("C:%d K:%d L:%d D:%d", $9, $10, $11, $12)
                printf "%3d%%   | %-10s | %-8s | %-22.22s | %-8s | %-22.22s | %-18s\n", $1, $2, $3, $4, $6, $7, breakdown
            }
            '
            echo ""
        fi
    fi
}

case "${1:-}" in
    match-all)
        run_matching_all "${2:---table}" "${3:-25}"
        ;;
    *)
        echo "Usage: $0 match-all [--table|--json] [min_threshold]"
        ;;
esac
