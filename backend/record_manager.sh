#!/usr/bin/env bash
# ==============================================================================
# LostLink - Unix & Shell Scripting Campus Lost & Found System
# Module: record_manager.sh (Member 1: CRUD Operations & Authentication)
# Commands Used: awk, sed, grep, cut, date, mktemp, mv, wc
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# ------------------------------------------------------------------------------
# User Authentication & Registration
# ------------------------------------------------------------------------------
authenticate_user() {
    local username="$1"
    local password="$2"
    local output_json="${3:-false}"

    if [[ -z "$username" || -z "$password" ]]; then
        if [[ "$output_json" == "--json" ]]; then
            echo '{"success": false, "message": "Missing username or password"}'
        else
            print_error "Username and password required."
        fi
        return 1
    fi

    local user_row
    user_row=$(grep "^[^,]*,${username},${password}," "$USERS_CSV" | head -n 1)

    if [[ -n "$user_row" ]]; then
        local user_id full_name email role
        user_id=$(echo "$user_row" | cut -d',' -f1)
        full_name=$(echo "$user_row" | cut -d',' -f4)
        email=$(echo "$user_row" | cut -d',' -f5)
        role=$(echo "$user_row" | cut -d',' -f6)

        log_audit "AUTH" "$username" "Successful login as $role"

        if [[ "$output_json" == "--json" ]]; then
            echo "{\"success\": true, \"user_id\": \"$user_id\", \"username\": \"$username\", \"full_name\": \"$full_name\", \"email\": \"$email\", \"role\": \"$role\"}"
        else
            print_success "Login successful! Welcome, $full_name ($role)."
        fi
        return 0
    else
        log_audit "AUTH" "$username" "Failed login attempt"
        if [[ "$output_json" == "--json" ]]; then
            echo '{"success": false, "message": "Invalid credentials"}'
        else
            print_error "Invalid username or password."
        fi
        return 1
    fi
}

register_user() {
    local username="$1"
    local password="$2"
    local full_name="$3"
    local email="$4"
    local role="${5:-student}"
    local output_json="${6:-false}"

    if [[ -z "$username" || -z "$password" || -z "$full_name" || -z "$email" ]]; then
        if [[ "$output_json" == "--json" ]]; then
            echo '{"success": false, "message": "All fields are required"}'
        else
            print_error "All fields (username, password, full_name, email) are required."
        fi
        return 1
    fi

    # Check if username exists using grep
    if grep -q "^[^,]*,${username}," "$USERS_CSV"; then
        if [[ "$output_json" == "--json" ]]; then
            echo '{"success": false, "message": "Username already exists"}'
        else
            print_error "Username '$username' is already registered."
        fi
        return 1
    fi

    local user_id
    user_id=$(get_next_id "$USERS_CSV" "USR")
    local created_at
    created_at=$(date "+%Y-%m-%d %H:%M:%S")

    echo "$user_id,$username,$password,$full_name,$email,$role,$created_at" >> "$USERS_CSV"
    log_audit "AUTH" "$username" "Registered new user account ($role)"

    if [[ "$output_json" == "--json" ]]; then
        echo "{\"success\": true, \"user_id\": \"$user_id\", \"username\": \"$username\", \"role\": \"$role\"}"
    else
        print_success "User '$username' registered successfully with ID $user_id."
    fi
    return 0
}

# ------------------------------------------------------------------------------
# Add Items (Lost or Found)
# ------------------------------------------------------------------------------
add_lost_item() {
    local title="$1"
    local category="$2"
    local description="$3"
    local location="$4"
    local date_lost="$5"
    local reported_by="$6"
    local contact_email="$7"
    local contact_phone="${8:-+91-9876543210}"
    local output_json="${9:-false}"

    local item_id
    item_id=$(get_next_id "$LOST_CSV" "LST")
    local status="lost"
    local created_at
    created_at=$(date "+%Y-%m-%d %H:%M:%S")

    # Sanitize commas, carriage returns, and newlines in text fields
    title="${title//$'\r'/}"; title="${title//$'\n'/ }"; title="${title//,/;}"
    description="${description//$'\r'/}"; description="${description//$'\n'/ }"; description="${description//,/;}"
    location="${location//$'\r'/}"; location="${location//$'\n'/ }"; location="${location//,/;}"
    contact_phone="${contact_phone//$'\r'/}"; contact_phone="${contact_phone//,/;}"

    echo "$item_id,$title,$category,$description,$location,$date_lost,$reported_by,$contact_email,$status,$created_at,$contact_phone" >> "$LOST_CSV"
    log_audit "RECORD_MGR" "$reported_by" "Reported lost item: $title (ID: $item_id, Phone: $contact_phone)"

    if [[ "$output_json" == "--json" ]]; then
        echo "{\"success\": true, \"item_id\": \"$item_id\", \"title\": \"$title\", \"status\": \"$status\", \"phone\": \"$contact_phone\"}"
    else
        print_success "Lost item registered successfully! Item ID: $item_id (Phone: $contact_phone)"
    fi
}

add_found_item() {
    local title="$1"
    local category="$2"
    local description="$3"
    local location="$4"
    local date_found="$5"
    local reported_by="$6"
    local contact_email="$7"
    local contact_phone="${8:-+91-9876543211}"
    local output_json="${9:-false}"

    local item_id
    item_id=$(get_next_id "$FOUND_CSV" "FND")
    local status="found"
    local created_at
    created_at=$(date "+%Y-%m-%d %H:%M:%S")

    # Sanitize commas, carriage returns, and newlines in text fields
    title="${title//$'\r'/}"; title="${title//$'\n'/ }"; title="${title//,/;}"
    description="${description//$'\r'/}"; description="${description//$'\n'/ }"; description="${description//,/;}"
    location="${location//$'\r'/}"; location="${location//$'\n'/ }"; location="${location//,/;}"
    contact_phone="${contact_phone//$'\r'/}"; contact_phone="${contact_phone//,/;}"

    echo "$item_id,$title,$category,$description,$location,$date_found,$reported_by,$contact_email,$status,$created_at,$contact_phone" >> "$FOUND_CSV"
    log_audit "RECORD_MGR" "$reported_by" "Logged found item: $title (ID: $item_id, Phone: $contact_phone)"

    if [[ "$output_json" == "--json" ]]; then
        echo "{\"success\": true, \"item_id\": \"$item_id\", \"title\": \"$title\", \"status\": \"$status\", \"phone\": \"$contact_phone\"}"
    else
        print_success "Found item logged successfully! Item ID: $item_id (Phone: $contact_phone)"
    fi
}

# ------------------------------------------------------------------------------
# List Items (Formatted Table or JSON)
# ------------------------------------------------------------------------------
list_items() {
    local item_type="$1" # lost or found
    local status_filter="${2:-all}"
    local output_json="${3:-false}"

    local target_csv="$LOST_CSV"
    [[ "$item_type" == "found" ]] && target_csv="$FOUND_CSV"

    if [[ "$output_json" == "--json" || "$status_filter" == "--json" ]]; then
        if [[ "$status_filter" != "--json" && "$status_filter" != "all" ]]; then
            # Filter rows by status column ($9)
            local tmp_filtered
            tmp_filtered=$(mktemp)
            head -n 1 "$target_csv" > "$tmp_filtered"
            awk -F',' -v st="$status_filter" '$9 == st' "$target_csv" >> "$tmp_filtered"
            csv_to_json "$tmp_filtered"
            rm -f "$tmp_filtered"
        else
            csv_to_json "$target_csv"
        fi
        return 0
    fi

    print_header "LIST OF $(echo "$item_type" | tr '[:lower:]' '[:upper:]') ITEMS (Filter: $status_filter)"
    awk -F',' -v st="$status_filter" '
    BEGIN {
        printf "%-8s | %-25s | %-12s | %-20s | %-10s | %-9s\n", "ID", "TITLE", "CATEGORY", "LOCATION", "DATE", "STATUS"
        print "-------------------------------------------------------------------------------------------------"
    }
    NR > 1 {
        if (st == "all" || $9 == st) {
            printf "%-8s | %-25.25s | %-12.12s | %-20.20s | %-10s | %-9s\n", $1, $2, $3, $5, $6, $9
        }
    }
    ' "$target_csv"
}

# ------------------------------------------------------------------------------
# Update Item Status
# ------------------------------------------------------------------------------
update_status() {
    local item_type="$1"
    local item_id="$2"
    local new_status="$3"
    local user="${4:-admin}"
    local output_json="${5:-false}"

    local target_csv="$LOST_CSV"
    [[ "$item_type" == "found" ]] && target_csv="$FOUND_CSV"

    if ! grep -q "^$item_id," "$target_csv"; then
        if [[ "$output_json" == "--json" ]]; then
            echo '{"success": false, "message": "Item not found"}'
        else
            print_error "Item $item_id not found in $item_type items."
        fi
        return 1
    fi

    local temp_file
    temp_file=$(mktemp)
    awk -F',' -v id="$item_id" -v nst="$new_status" '
    BEGIN { OFS="," }
    {
        if ($1 == id) {
            $9 = nst
        }
        print $0
    }
    ' "$target_csv" > "$temp_file" && mv "$temp_file" "$target_csv"

    log_audit "RECORD_MGR" "$user" "Updated $item_type item $item_id status to '$new_status'"

    if [[ "$output_json" == "--json" ]]; then
        echo "{\"success\": true, \"item_id\": \"$item_id\", \"new_status\": \"$new_status\"}"
    else
        print_success "Status of item $item_id updated to '$new_status'."
    fi
}

# ------------------------------------------------------------------------------
# Delete Item
# ------------------------------------------------------------------------------
delete_item() {
    local item_type="$1"
    local item_id="$2"
    local user="${3:-admin}"
    local output_json="${4:-false}"

    local target_csv="$LOST_CSV"
    [[ "$item_type" == "found" ]] && target_csv="$FOUND_CSV"

    if ! grep -q "^$item_id," "$target_csv"; then
        if [[ "$output_json" == "--json" ]]; then
            echo '{"success": false, "message": "Item not found"}'
        else
            print_error "Item $item_id not found."
        fi
        return 1
    fi

    local temp_file
    temp_file=$(mktemp)
    grep -v "^$item_id," "$target_csv" > "$temp_file" && mv "$temp_file" "$target_csv"

    log_audit "RECORD_MGR" "$user" "Deleted $item_type item $item_id"

    if [[ "$output_json" == "--json" ]]; then
        echo "{\"success\": true, \"deleted_id\": \"$item_id\"}"
    else
        print_success "$item_type item $item_id deleted successfully."
    fi
}

# ------------------------------------------------------------------------------
# CLI Router
# ------------------------------------------------------------------------------
case "${1:-}" in
    auth)
        authenticate_user "$2" "$3" "${4:-}"
        ;;
    register)
        register_user "$2" "$3" "$4" "$5" "${6:-student}" "${7:-}"
        ;;
    add-lost)
        add_lost_item "$2" "$3" "$4" "$5" "$6" "$7" "$8" "${9:-+91-9876543210}" "${10:-}"
        ;;
    add-found)
        add_found_item "$2" "$3" "$4" "$5" "$6" "$7" "$8" "${9:-+91-9876543211}" "${10:-}"
        ;;
    list)
        list_items "$2" "${3:-all}" "${4:-}"
        ;;
    update-status)
        update_status "$2" "$3" "$4" "${5:-admin}" "${6:-}"
        ;;
    delete)
        delete_item "$2" "$3" "${4:-admin}" "${5:-}"
        ;;
    *)
        echo "Usage: $0 {auth|register|add-lost|add-found|list|update-status|delete} [args...]"
        ;;
esac
