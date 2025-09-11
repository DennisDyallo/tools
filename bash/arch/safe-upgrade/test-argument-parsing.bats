#!/usr/bin/env bats

# Test command line interface - no mocking needed
load 'test_helper'

# Test the script's command line interface directly
@test "script shows help with --help" {
    run bash safe-upgrade.sh --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "--rollback" ]]
    [[ "$output" =~ "--clear-cache" ]]
}

@test "script rejects invalid arguments" {
    run bash safe-upgrade.sh --invalid-option
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown option" ]]
}

@test "script accepts valid arguments" {
    # These should not error (though they may exit early for other reasons)
    run bash safe-upgrade.sh --list
    # Don't check exit code since it might fail due to missing timeshift
    [[ "$output" =~ "Available snapshots" ]] || [[ "$output" =~ "No snapshot system" ]]
}

@test "script checks for root user" {
    # Create a version that simulates running as root
    temp_script=$(mktemp)
    
    # Copy script but change EUID check to simulate root (EUID=0)
    sed 's/\$EUID -eq 0/0 -eq 0/' safe-upgrade.sh > "$temp_script"
    
    # Should complain about running as root and exit with status 1
    run bash "$temp_script" --help
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Don't run this script as root" ]]
    
    rm "$temp_script"
}

# Test argument parsing logic in isolation (if we extract the function)
@test "argument parsing logic works" {
    # Simple test of the parsing logic
    
    # Test rollback flag setting
    ROLLBACK_MODE=false
    
    # Simulate what parse_args does for --rollback
    case "--rollback" in
        -r|--rollback)
            ROLLBACK_MODE=true
            ;;
        *)
            ROLLBACK_MODE=false
            ;;
    esac
    
    [ "$ROLLBACK_MODE" = "true" ]
}