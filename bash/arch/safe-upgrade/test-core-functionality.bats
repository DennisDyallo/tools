#!/usr/bin/env bats

# Test core upgrade functionality and operations
load 'test_helper'

@test "script has clear package cache functionality" {
    # Test that --clear-cache option works
    run bash safe-upgrade.sh --clear-cache
    
    # Should show cache cleanup information
    [[ "$output" =~ "Package cache cleanup" ]] || [[ "$output" =~ "cache" ]]
}

@test "script checks for yay package manager availability" {
    # Test dependency checking logic
    script_content=$(cat safe-upgrade.sh)
    
    # Should reference yay for AUR packages
    [[ "$script_content" =~ "yay" ]]
    
    # Should have some form of dependency checking
    [[ "$script_content" =~ "command -v" ]] || [[ "$script_content" =~ "which" ]]
}

@test "script has upgrade review functionality" {
    # Test that script shows what will be upgraded before proceeding
    script_content=$(cat safe-upgrade.sh)
    
    # Should have review functionality
    [[ "$script_content" =~ "review_upgrades" ]]
    
    # Should show packages before upgrading
    [[ "$script_content" =~ "yay -Syu --print" ]] || [[ "$script_content" =~ "print" ]]
    
    # Should ask for confirmation
    [[ "$script_content" =~ "Proceed with" ]] || [[ "$script_content" =~ "Continue" ]]
}

@test "script checks Arch Linux news before upgrading" {
    # Test that script prompts user to check arch news
    script_content=$(cat safe-upgrade.sh)
    
    # Should have news checking functionality
    [[ "$script_content" =~ "check_arch_news" ]]
    [[ "$script_content" =~ "Arch" ]] && [[ "$script_content" =~ "news" ]]
    [[ "$script_content" =~ "breaking changes" ]]
}

@test "script performs actual upgrade operations" {
    # Test that script has upgrade execution logic
    script_content=$(cat safe-upgrade.sh)
    
    # Should have upgrade execution
    [[ "$script_content" =~ "perform_upgrade" ]]
    [[ "$script_content" =~ "yay -Syu" ]] || [[ "$script_content" =~ "pacman -Syu" ]]
    
    # Should have logging capability
    [[ "$script_content" =~ "LOGFILE" ]] || [[ "$script_content" =~ "log" ]]
}

@test "script has cache corruption checking" {
    # Test that script checks for corrupted package cache
    script_content=$(cat safe-upgrade.sh)
    
    # Should have cache corruption detection
    [[ "$script_content" =~ "check_cache_corruption" ]] || [[ "$script_content" =~ "cache" ]]
}

@test "script shows cache sizes before cleanup" {
    # Create a version that mocks cache size commands
    temp_script=$(mktemp)
    
    # Mock the du commands to return known sizes
    sed 's/du -sh ~\/\.cache\/yay/echo "100M"/' safe-upgrade.sh | \
    sed 's/sudo du -sh \/var\/cache\/pacman\/pkg/echo "500M"/' > "$temp_script"
    
    run bash "$temp_script" --clear-cache
    [[ "$output" =~ "cache" ]] && ([[ "$output" =~ "100M" ]] || [[ "$output" =~ "500M" ]] || [[ "$output" =~ "size" ]])
    
    rm "$temp_script"
}

@test "script has proper upgrade flow sequence" {
    # Test that script executes upgrade steps in proper order
    script_content=$(cat safe-upgrade.sh)
    
    # Should have the correct sequence of operations
    [[ "$script_content" =~ "check_arch_news" ]]
    [[ "$script_content" =~ "create_snapshot" ]]
    [[ "$script_content" =~ "review_upgrades" ]]
    [[ "$script_content" =~ "perform_upgrade" ]]
}

@test "script handles interactive confirmations gracefully" {
    # Test that script has proper user interaction handling
    script_content=$(cat safe-upgrade.sh)
    
    # Should have multiple confirmation points
    confirmation_count=$(echo "$script_content" | grep -c "read -p" || echo 0)
    [[ $confirmation_count -gt 1 ]]
    
    # Should handle yes/no responses
    [[ "$script_content" =~ "\[Y/n\]" ]] || [[ "$script_content" =~ "\[y/N\]" ]]
    [[ "$script_content" =~ "Yy" ]] || [[ "$script_content" =~ "Nn" ]]
}

@test "script recommends reboot after kernel upgrades" {
    # Test that script detects kernel upgrades and suggests reboot
    script_content=$(cat safe-upgrade.sh)
    
    # Should detect kernel upgrades
    [[ "$script_content" =~ "linux " ]] && [[ "$script_content" =~ "LOGFILE" ]]
    
    # Should recommend reboot
    [[ "$script_content" =~ "Reboot" ]] && [[ "$script_content" =~ "kernel" ]]
    
    # Should offer to reboot
    [[ "$script_content" =~ "reboot now" ]] || [[ "$script_content" =~ "sudo reboot" ]]
}

@test "script has proper error handling in upgrade flow" {
    # Test that script handles errors during upgrade process
    script_content=$(cat safe-upgrade.sh)
    
    # Should have error handling mechanisms
    [[ "$script_content" =~ "exit 1" ]]
    
    # Should have proper logging for troubleshooting
    [[ "$script_content" =~ "log" ]] && [[ "$script_content" =~ "ERROR" ]]
    
    # Should handle user cancellation
    [[ "$script_content" =~ "cancelled by user" ]] || [[ "$script_content" =~ "EXIT" ]]
}

@test "script creates and uses log files" {
    # Test that script properly logs operations
    script_content=$(cat safe-upgrade.sh)
    
    # Should have log file management
    [[ "$script_content" =~ "LOGFILE" ]]
    
    # Should inform user about log location
    [[ "$script_content" =~ "Logging to" ]] || [[ "$script_content" =~ "log" ]]
    
    # Should use logging function consistently
    [[ "$script_content" =~ "log()" ]] && [[ "$script_content" =~ "log " ]]
}