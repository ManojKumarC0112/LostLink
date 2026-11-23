#!/usr/bin/env bash
# ==============================================================================
# LostLink - Unix & Shell Scripting Campus Lost & Found System
# Module: claim_manager.sh (Member 3: Claim Processing & Status Verification)
# Commands Used: awk, sed, grep, cut, date, mktemp, mv
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# ------------------------------------------------------------------------------
# Submit Claim for a Found Item
# ------------------------------------------------------------------------------
submit_claim() {
    local found_item_id="$1"
    local claimed_by="$2"
    local proof_details="$3"
    local output_json="${4:-false}"

    # Verify found item exists
    if ! grep -q "^$found_item_id," "$FOUND_CSV"; then
        if [[ "$output_json" == "--json" ]]; then
            echo '{"success": false, "message": "Found item not found"}'
        else
            print_error "Found item $found_item_id does not exist."
        fi
        return 1
    fi

    # Check if item is already returned or closed
    local current_stat
    current_stat=$(grep "^$found_item_id," "$FOUND_CSV" | cut -d',' -f9)
    if [[ "$current_stat" == "returned" || "$current_stat" == "closed" ]]; then
        if [[ "$output_json" == "--json" ]]; then
            echo '{"success": false, "message": "Item is already returned or closed"}'
        else
            print_error "Cannot claim item $found_item_id because its status is already '$current_stat'."
        fi
        return 1
    fi

    local claim_id
    claim_id=$(get_next_id "$CLAIMS_CSV" "CLM")
    local claim_date
    claim_date=$(date "+%Y-%m-%d %H:%M:%S")
    local status="pending"
    local reviewed_by="none"
    local review_notes="Awaiting admin/security review"
    local updated_at="$claim_date"

    # Sanitize commas
    proof_details="${proof_details//,/;}"

    echo "$claim_id,$found_item_id,$claimed_by,$proof_details,$claim_date,$status,$reviewed_by,$review_notes,$updated_at" >> "$CLAIMS_CSV"
    
    # Update found item status to claimed
    local temp_file
    temp_file=$(mktemp)
    awk -F',' -v id="$found_item_id" 'BEGIN{OFS=","} {if ($1 == id && $9 == "found") $9 = "claimed"; print $0}' "$FOUND_CSV" > "$temp_file" && mv "$temp_file" "$FOUND_CSV"

    log_audit "CLAIMS" "$claimed_by" "Submitted claim $claim_id for found item $found_item_id"

    if [[ "$output_json" == "--json" ]]; then
        echo "{\"success\": true, \"claim_id\": \"$claim_id\", \"found_item_id\": \"$found_item_id\", \"status\": \"$status\"}"
    else
        print_success "Claim $claim_id submitted successfully for found item $found_item_id."
    fi
}

# ------------------------------------------------------------------------------
# List Claims
# ------------------------------------------------------------------------------
list_claims() {
    local status_filter="${1:-all}"
    local output_json="${2:-false}"

    if [[ "$output_json" == "--json" || "$status_filter" == "--json" ]]; then
        if [[ "$status_filter" != "--json" && "$status_filter" != "all" ]]; then
            local tmp_filtered
            tmp_filtered=$(mktemp)
            head -n 1 "$CLAIMS_CSV" > "$tmp_filtered"
            awk -F',' -v st="$status_filter" '$6 == st' "$CLAIMS_CSV" >> "$tmp_filtered"
            csv_to_json "$tmp_filtered"
            rm -f "$tmp_filtered"
        else
            csv_to_json "$CLAIMS_CSV"
        fi
        return 0
    fi

    print_header "CLAIMS LIST (Filter: $status_filter)"
    awk -F',' -v st="$status_filter" '
    BEGIN {
        printf "%-8s | %-9s | %-12s | %-10s | %-10s | %-25s\n", "CLAIM ID", "ITEM ID", "CLAIMED BY", "DATE", "STATUS", "REVIEW NOTES"
        print "-------------------------------------------------------------------------------------------------"
    }
    NR > 1 {
        if (st == "all" || $6 == st) {
            printf "%-8s | %-9s | %-12s | %-10.10s | %-10s | %-25.25s\n", $1, $2, $3, $5, $6, $8
        }
    }
    ' "$CLAIMS_CSV"
}

# ------------------------------------------------------------------------------
# Review Claim (Approve / Reject)
# ------------------------------------------------------------------------------
review_claim() {
    local claim_id="$1"
    local decision="$2" # approve | reject
    local reviewer="${3:-admin}"
    local notes="${4:-Review completed}"
    local output_json="${5:-false}"

    if ! grep -q "^$claim_id," "$CLAIMS_CSV"; then
        if [[ "$output_json" == "--json" ]]; then
            echo '{"success": false, "message": "Claim ID not found"}'
        else
            print_error "Claim ID $claim_id not found."
        fi
        return 1
    fi

    local new_status
    if [[ "$decision" == "approve" || "$decision" == "approved" ]]; then
        new_status="approved"
    elif [[ "$decision" == "reject" || "$decision" == "rejected" ]]; then
        new_status="rejected"
    else
        print_error "Decision must be 'approve' or 'reject'."
        return 1
    fi

    local updated_at
    updated_at=$(date "+%Y-%m-%d %H:%M:%S")
    notes="${notes//,/;}"

    # Extract target found item ID
    local target_found_id
    target_found_id=$(grep "^$claim_id," "$CLAIMS_CSV" | cut -d',' -f2)

    # Update claims.csv
    local temp_file
    temp_file=$(mktemp)
    awk -F',' -v cid="$claim_id" -v nst="$new_status" -v rev="$reviewer" -v nts="$notes" -v ut="$updated_at" '
    BEGIN { OFS="," }
    {
        if ($1 == cid) {
            $6 = nst
            $7 = rev
            $8 = nts
            $9 = ut
        }
        print $0
    }
    ' "$CLAIMS_CSV" > "$temp_file" && mv "$temp_file" "$CLAIMS_CSV"

    # If approved, update found item status to "returned"
    if [[ "$new_status" == "approved" && -n "$target_found_id" ]]; then
        local temp_found
        temp_found=$(mktemp)
        awk -F',' -v fid="$target_found_id" 'BEGIN{OFS=","} {if ($1 == fid) $9 = "returned"; print $0}' "$FOUND_CSV" > "$temp_found" && mv "$temp_found" "$FOUND_CSV"

        # Also search if any lost item owned by the claimer was matched, update to recovered
        local claimer
        claimer=$(grep "^$claim_id," "$CLAIMS_CSV" | cut -d',' -f3)
        local temp_lost
        temp_lost=$(mktemp)
        awk -F',' -v user="$claimer" 'BEGIN{OFS=","} {if ($7 == user && $9 == "matched") $9 = "recovered"; print $0}' "$LOST_CSV" > "$temp_lost" && mv "$temp_lost" "$LOST_CSV"
    fi

    log_audit "CLAIMS" "$reviewer" "Reviewed claim $claim_id: $new_status (Notes: $notes)"

    if [[ "$output_json" == "--json" ]]; then
        echo "{\"success\": true, \"claim_id\": \"$claim_id\", \"decision\": \"$new_status\", \"found_item_id\": \"$target_found_id\"}"
    else
        print_success "Claim $claim_id has been $new_status by $reviewer."
    fi
}

# ------------------------------------------------------------------------------
# CLI Router
# ------------------------------------------------------------------------------
case "${1:-}" in
    submit)
        submit_claim "$2" "$3" "$4" "${5:-}"
        ;;
    list)
        list_claims "${2:-all}" "${3:-}"
        ;;
    review)
        review_claim "$2" "$3" "${4:-admin}" "${5:-Verified}" "${6:-}"
        ;;
    *)
        echo "Usage: $0 submit <found_item_id> <claimed_by> <proof_details> [--json]"
        echo "       $0 list [all|pending|approved|rejected] [--json]"
        echo "       $0 review <claim_id> <approve|reject> [reviewer] [notes] [--json]"
        ;;
esac
