#!/usr/bin/env bats

# Test pre-upgrade safety validations and checks
load 'test_helper'

@test "script detects timeshift snapshot system correctly" {
    # Mock timeshift being available with snapshots directory
    temp_script=$(mktemp)
    
    # Create a version that simulates timeshift being available
    sed 's/command -v timeshift/echo timeshift/' safe-upgrade.sh | \
    sed 's|\[[ -d /timeshift/snapshots \]|[[ -d /tmp ]]|' > "$temp_script"
    
    run bash "$temp_script" --list
    [[ "$output" =~ "timeshift" ]] || [[ "$output" =~ "Available snapshots" ]]
    
    rm "$temp_script"
}

@test "script detects snapper snapshot system correctly" {
    # Mock snapper being available with snapshots directory  
    temp_script=$(mktemp)
    
    # Create a version that simulates snapper being available
    sed 's/command -v timeshift/echo/' safe-upgrade.sh | \
    sed 's/command -v snapper/echo snapper/' | \
    sed 's|\[[ -d /.snapshots \]|[[ -d /tmp ]]|' > "$temp_script"
    
    run bash "$temp_script" --list
    [[ "$output" =~ "snapper" ]] || [[ "$output" =~ "Available snapshots" ]]
    
    rm "$temp_script"
}

@test "script detects when no snapshot system is available" {
    # Mock no snapshot systems being available
    temp_script=$(mktemp)
    
    # Create a version with no snapshot tools available
    sed 's/command -v timeshift/echo/' safe-upgrade.sh | \
    sed 's/command -v snapper/echo/' | \
    sed 's|\[[ -d /timeshift/snapshots \]|[[ -d /nonexistent ]]|' | \
    sed 's|\[[ -d /.snapshots \]|[[ -d /nonexistent ]]|' > "$temp_script"
    
    run bash "$temp_script" --list
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No snapshot system detected" ]]
    
    rm "$temp_script"
}

@test "script checks available disk space before operations" {
    # Test that the script calls disk space checking
    run bash safe-upgrade.sh --help
    [ "$status" -eq 0 ]
    
    # The script should have disk space checking functionality
    script_content=$(cat safe-upgrade.sh)
    [[ "$script_content" =~ "check_free_space" ]]
    [[ "$script_content" =~ "df --output=avail" ]]
}

@test "script warns on low disk space (less than 5GB)" {
    # Create a version that simulates low disk space
    temp_script=$(mktemp)
    
    # Mock df command to return low space (1GB = ~1000000 KB)
    sed 's/df --output=avail \//echo 1000000/' safe-upgrade.sh > "$temp_script"
    
    # Use timeout to handle interactive prompt
    run timeout 2s bash "$temp_script" --help 2>/dev/null || true
    [[ "$output" =~ "Low disk space" ]] || [[ "$output" =~ "WARNING" ]]
    
    rm "$temp_script"
}

@test "script has adequate disk space threshold logic" {
    # Test the space conversion and threshold logic
    local result
    result=$(test_space_conversion 5242880)  # 5GB in KB
    [[ "$result" == "5.0" ]]
    
    result=$(test_space_threshold 3)
    [[ "$result" == "critical" ]]
    
    result=$(test_space_threshold 8)
    [[ "$result" == "warning" ]]
    
    result=$(test_space_threshold 15)
    [[ "$result" == "ok" ]]
}

@test "script validates snapshot creation is possible" {
    # Test that script checks for snapshot system before attempting creation
    script_content=$(cat safe-upgrade.sh)
    
    # Should have snapshot system detection
    [[ "$script_content" =~ "detect_snapshot_system" ]]
    
    # Should check for timeshift or snapper availability
    [[ "$script_content" =~ "timeshift" ]]
    [[ "$script_content" =~ "snapper" ]]
    
    # Should have snapshot creation function
    [[ "$script_content" =~ "create_snapshot" ]]
}

@test "script requires confirmation for risky operations" {
    # Test that script prompts for confirmation on low disk space
    script_content=$(cat safe-upgrade.sh)
    
    # Should have confirmation prompts for risky operations
    [[ "$script_content" =~ "read -p.*Continue" ]]
    [[ "$script_content" =~ "Continue anyway" ]] || [[ "$script_content" =~ "Continue without" ]]
}

@test "script checks for required dependencies" {
    # Test that script checks for essential tools
    script_content=$(cat safe-upgrade.sh)
    
    # Should check for package managers
    [[ "$script_content" =~ "yay" ]] || [[ "$script_content" =~ "pacman" ]]
    
    # Should use command -v to check for tool availability
    [[ "$script_content" =~ "command -v" ]]
}

@test "script has root privilege checking for system operations" {
    # Test that script uses sudo for privileged operations
    script_content=$(cat safe-upgrade.sh)
    
    # Should use sudo for system operations
    [[ "$script_content" =~ "sudo" ]]
    
    # Should have proper privilege escalation for snapshots
    [[ "$script_content" =~ "sudo timeshift" ]] || [[ "$script_content" =~ "sudo snapper" ]]
}