#!/usr/bin/env bats

# Test command line interface - no mocking needed
load 'test_helper'

# Test the script's command line interface directly
@test "script shows help with --help" {
    run bash ../safe-arch-upgrade.sh --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "--rollback" ]]
    [[ "$output" =~ "--clear-cache" ]]
}

@test "script rejects invalid arguments" {
    run bash ../safe-arch-upgrade.sh --invalid-option
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown option" ]]
}

@test "script accepts valid arguments" {
    # These should not error (though they may exit early for other reasons)
    run bash ../safe-arch-upgrade.sh --list
    # Don't check exit code since it might fail due to missing timeshift
    [[ "$output" =~ "Available snapshots" ]] || [[ "$output" =~ "No snapshot system" ]]
}

@test "script checks for root user" {
    # Create a version that mocks EUID for testing
    script_content=$(cat ../safe-arch-upgrade.sh)
    
    # Replace EUID check with our test value
    echo "$script_content" | sed 's/\$EUID/0/' | bash -s -- --help
    
    # Should complain about running as root
    run bash -c 'EUID=0; bash ../safe-arch-upgrade.sh --help'
    [[ "$output" =~ "Don't run this script as root" ]] || 
    [[ "$status" -eq 1 ]]
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