#!/usr/bin/env bats

# Simple integration tests - test the script as a black box

@test "script has valid bash syntax" {
    # Most important test - script should parse correctly
    run bash -n ../safe-arch-upgrade.sh
    [ "$status" -eq 0 ]
}

@test "script shows help and exits cleanly" {
    run bash ../safe-arch-upgrade.sh --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Examples:" ]]
}

@test "script handles invalid arguments gracefully" {
    run bash ../safe-arch-upgrade.sh --not-a-real-option
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown option" ]]
}

@test "script requires non-root user" {
    # Test the EUID check without actually running as root
    # We can test this by modifying the script temporarily
    temp_script=$(mktemp)
    
    # Copy script but change EUID check to simulate root
    sed 's/\[[ ] *$EUID -eq 0/[[ 0 -eq 0/' ../safe-arch-upgrade.sh > "$temp_script"
    
    run bash "$temp_script" --help
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Don't run this script as root" ]]
    
    rm "$temp_script"
}

@test "script handles missing dependencies gracefully" {
    # Test what happens when dependencies are missing
    # Create a version with PATH that doesn't include yay
    
    run env PATH="/bin:/usr/bin" bash ../safe-arch-upgrade.sh --help
    # Should still show help even if yay is missing
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "all command line options are documented in help" {
    run bash ../safe-arch-upgrade.sh --help
    [ "$status" -eq 0 ]
    
    # Check that all the options we support are documented
    [[ "$output" =~ "--rollback" ]]
    [[ "$output" =~ "--list" ]]
    [[ "$output" =~ "--delete" ]]
    [[ "$output" =~ "--clear-cache" ]]
    [[ "$output" =~ "--help" ]]
}

@test "script can display version or basic info" {
    # Test that the script can tell us something about itself
    run bash ../safe-arch-upgrade.sh --help
    [ "$status" -eq 0 ]
    
    # Should contain basic identifying information
    [[ "$output" =~ "safe" ]] || [[ "$output" =~ "upgrade" ]] || [[ "$output" =~ "arch" ]]
}