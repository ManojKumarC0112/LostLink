#!/usr/bin/env bash
# ==============================================================================
# LostLink - Unix & Shell Scripting Campus Lost & Found System
# Module: matching_engine.sh (Member 2: Smart Weighted Matching Algorithm)
# Concepts Used: awk associative arrays, string tokenization, date math, scoring
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Calculate matching score between one lost item and one found item
# Output format: TOTAL_SCORE|CAT_SCORE|KEY_SCORE|LOC_SCORE|DATE_SCORE|CONFIDENCE
calculate_match_score() {
    local l_cat="$1"
    local l_text="$2"
    local l_loc="$3"
    local l_date="$4"
    local f_cat="$5"
    local f_text="$6"
    local f_loc="$7"
    local f_date="$8"

    awk -v lcat="$l_cat" -v ltext="$l_text" -v lloc="$l_loc" -v ldate="$l_date" \
        -v fcat="$f_cat" -v ftext="$f_text" -v floc="$f_loc" -v fdate="$f_date" '
    BEGIN {
        # 1. CATEGORY MATCH (35%)
        cat_score = 0
        if (tolower(lcat) == tolower(fcat)) {
            cat_score = 35
        }

        # 2. KEYWORD OVERLAP (35%)
        # Tokenize and remove common stop-words
        stop_words = " the a an in on with and of to is for by my at near under from on floor room block desk "
        
        # Prepare lost text words
        clean_ltext = tolower(ltext)
        gsub(/[^a-z0-9 ]/, " ", clean_ltext)
        n_l = split(clean_ltext, words_l, " ")
        for (i=1; i<=n_l; i++) {
            w = words_l[i]
            if (length(w) > 2 && index(stop_words, " " w " ") == 0) {
                l_dict[w] = 1
            }
        }

        # Prepare found text words and count overlaps
        clean_ftext = tolower(ftext)
        gsub(/[^a-z0-9 ]/, " ", clean_ftext)
        n_f = split(clean_ftext, words_f, " ")
        matches = 0
        total_unique = 0

        for (w in l_dict) total_unique++
        for (i=1; i<=n_f; i++) {
            w = words_f[i]
            if (length(w) > 2 && index(stop_words, " " w " ") == 0) {
                if (l_dict[w] == 1) {
                    matches++
                    l_dict[w] = 2 # prevent double count
                } else if (l_dict[w] == 0) {
                    total_unique++
                }
            }
        }

        if (total_unique > 0) {
            key_score = int((matches / total_unique) * 35)
            if (matches > 0 && key_score < 10) key_score = 10 # baseline for explicit keyword hit
        } else {
            key_score = 0
        }
        if (key_score > 35) key_score = 35

        # 3. LOCATION PROXIMITY (20%)
        loc_score = 0
        clean_lloc = tolower(lloc)
        clean_floc = tolower(floc)
        if (clean_lloc == clean_floc) {
            loc_score = 20
        } else {
            # Check partial keyword match in location (e.g. "Library", "Cafeteria", "Science")
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
        date_score = 0
        # Parse YYYY-MM-DD
        split(ldate, ld, "-")
        split(fdate, fd, "-")
        l_day_approx = ld[1]*365 + ld[2]*30 + ld[3]
        f_day_approx = fd[1]*365 + fd[2]*30 + fd[3]
        diff = l_day_approx - f_day_approx
        if (diff < 0) diff = -diff

        if (diff <= 2) {
            date_score = 10
        } else if (diff <= 7) {
            date_score = 5
        } else {
            date_score = 0
        }

        # TOTAL WEIGHTED SCORE
        total = cat_score + key_score + loc_score + date_score

        # CONFIDENCE CLASSIFICATION
        if (total >= 70) {
            conf = "HIGH"
        } else if (total >= 45) {
            conf = "MODERATE"
        } else if (total >= 25) {
            conf = "LOW"
        } else {
            conf = "UNLIKELY"
        }

        printf "%d|%d|%d|%d|%d|%s\n", total, cat_score, key_score, loc_score, date_score, conf
    }
    '
}

# ------------------------------------------------------------------------------
# Run Matching Engine Across All Active Items
# ------------------------------------------------------------------------------
run_matching_all() {
    local output_mode="${1:---table}"
    local min_threshold="${2:-25}"

    local temp_results
    temp_results=$(mktemp)

    # Read each lost item with status in (lost, matched)
    while IFS=',' read -r l_id l_title l_cat l_desc l_loc l_date l_user l_email l_stat l_created; do
        [[ "$l_id" == "item_id" || -z "$l_id" ]] && continue
        [[ "$l_stat" == "recovered" || "$l_stat" == "closed" ]] && continue

        # Compare with each found item
        while IFS=',' read -r f_id f_title f_cat f_desc f_loc f_date f_user f_email f_stat f_created; do
            [[ "$f_id" == "item_id" || -z "$f_id" ]] && continue
            [[ "$f_stat" == "returned" || "$f_stat" == "closed" ]] && continue

            # Score this pair
            local score_str
            score_str=$(calculate_match_score "$l_cat" "$l_title $l_desc" "$l_loc" "$l_date" "$f_cat" "$f_title $f_desc" "$f_loc" "$f_date")
            
            local total_score cat_s key_s loc_s date_s conf
            total_score=$(echo "$score_str" | cut -d'|' -f1)
            cat_s=$(echo "$score_str" | cut -d'|' -f2)
            key_s=$(echo "$score_str" | cut -d'|' -f3)
            loc_s=$(echo "$score_str" | cut -d'|' -f4)
            date_s=$(echo "$score_str" | cut -d'|' -f5)
            conf=$(echo "$score_str" | cut -d'|' -f6)

            if [[ $total_score -ge $min_threshold ]]; then
                echo "$total_score|$conf|$l_id|$l_title|$l_cat|$f_id|$f_title|$f_cat|$cat_s|$key_s|$loc_s|$date_s|$l_date|$f_date|$l_loc|$f_loc" >> "$temp_results"
            fi
        done < "$FOUND_CSV"
    done < "$LOST_CSV"

    # Sort results by score descending
    local temp_sorted
    temp_sorted=$(mktemp)
    if [[ -s "$temp_results" ]]; then
        sort -t'|' -k1,1nr "$temp_results" > "$temp_sorted"
    fi

    if [[ "$output_mode" == "--json" ]]; then
        awk -F'|' '
        BEGIN { print "[" }
        NF > 0 {
            if (NR > 1) print ","
            l_t = $4; gsub(/"/, "\\\"", l_t)
            f_t = $7; gsub(/"/, "\\\"", f_t)
            printf "  {\"score\": %d, \"confidence\": \"%s\", \"lost_id\": \"%s\", \"lost_title\": \"%s\", \"lost_category\": \"%s\", \"found_id\": \"%s\", \"found_title\": \"%s\", \"found_category\": \"%s\", \"breakdown\": {\"category\": %d, \"keywords\": %d, \"location\": %d, \"date\": %d}, \"lost_date\": \"%s\", \"found_date\": \"%s\", \"lost_location\": \"%s\", \"found_location\": \"%s\"}", $1, $2, $3, l_t, $5, $6, f_t, $8, $9, $10, $11, $12, $13, $14, $15, $16
        }
        END { print "\n]" }
        ' "$temp_sorted"
    else
        local match_count
        match_count=$(wc -l < "$temp_sorted")
        print_header "SMART MATCHING ENGINE: Found $match_count Candidate Matches"
        
        if [[ $match_count -eq 0 ]]; then
            echo -e "${COLOR_YELLOW}No candidate matches found above $min_threshold% threshold.${COLOR_RESET}\n"
        else
            awk -F'|' '
            BEGIN {
                printf "%-6s | %-10s | %-8s | %-22s | %-8s | %-22s | %-18s\n", "SCORE", "CONFIDENCE", "LOST ID", "LOST TITLE", "FOUND ID", "FOUND TITLE", "SCORE BREAKDOWN"
                print "------------------------------------------------------------------------------------------------------------------"
            }
            {
                breakdown = sprintf("C:%d K:%d L:%d D:%d", $9, $10, $11, $12)
                printf "%3d%%   | %-10s | %-8s | %-22.22s | %-8s | %-22.22s | %-18s\n", $1, $2, $3, $4, $6, $7, breakdown
            }
            ' "$temp_sorted"
            echo ""
        fi
    fi

    rm -f "$temp_results" "$temp_sorted"
}

# ------------------------------------------------------------------------------
# CLI Router
# ------------------------------------------------------------------------------
case "${1:-}" in
    match-all)
        run_matching_all "${2:---table}" "${3:-25}"
        ;;
    match-score)
        calculate_match_score "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"
        ;;
    *)
        echo "Usage: $0 match-all [--table|--json] [min_threshold]"
        ;;
esac
