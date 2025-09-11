# Simple test helpers - no mocking needed

# Load the script functions for testing (without executing main)
load_script_functions() {
    # Extract functions from main script, skip main execution
    source <(grep -E '^[a-zA-Z_][a-zA-Z0-9_]*\(\)|^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*\(\)' safe-upgrade.sh | head -n -1)
}

# Test specific math operations
test_space_conversion() {
    local kb="$1"
    echo "$kb" | awk '{printf "%.1f", $1/1024/1024}'
}

# Test threshold logic without external dependencies
test_space_threshold() {
    local gb_int="$1"
    
    if [[ $gb_int -lt 5 ]]; then
        echo "critical"
    elif [[ $gb_int -lt 10 ]]; then
        echo "warning"
    else
        echo "ok"
    fi
}
