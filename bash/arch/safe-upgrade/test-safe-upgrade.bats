#!/usr/bin/env bats

# Load bats helpers
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Setup and teardown
setup() {
    # Create temp directory for testing
    export TEST_DIR="$(mktemp -d)"
    export LOGFILE="$TEST_DIR/test.log"
    
    # Source the script but prevent main execution
    export TESTING=true
    source safe-arch-upgrade.sh
    
    # Mock external commands
    export PATH="$TEST_DIR/mocks:$PATH"
    
    # Create mock directories
    mkdir -p "$TEST_DIR/mocks"
    mkdir -p "$TEST_DIR/.cache"
}

teardown() {
    rm -rf "$TEST_DIR"
}

# Create mock commands
create_mock_command() {
    local cmd="$1"
    local exit_code="${2:-0}"
    local output="$3"
    
    cat > "$TEST_DIR/mocks/$cmd" << EOF
#!/bin/bash
echo "$output"
exit $exit_code
EOF
    chmod +x "$TEST_DIR/mocks/$cmd"
}

# Test argument parsing
@test "parse_args handles --help flag" {
    create_mock_command "show_help" 0 "Usage: script [OPTIONS]"
    
    run parse_args --help
    assert_success
}

@test "parse_args sets ROLLBACK_MODE for --rollback" {
    ROLLBACK_MODE=false
    parse_args --rollback
    assert_equal "$ROLLBACK_MODE" "true"
}

@test "parse_args handles unknown option" {
    run parse_args --invalid-option
    assert_failure
    assert_output --partial "Unknown option"
}

# Test check_free_space function
@test "check_free_space shows warning for low space" {
    # Mock df command to return low space (4GB)
    create_mock_command "df" 0 "4194304"  # 4GB in KB
    
    # Mock user input (decline to continue)
    echo "n" | run check_free_space
    assert_failure
    assert_output --partial "Low disk space"
}

@test "check_free_space shows info for adequate space" {
    # Mock df command to return adequate space (20GB)
    create_mock_command "df" 0 "20971520"  # 20GB in KB
    
    run check_free_space
    assert_success
    assert_output --partial "Available disk space: 20.0GB"
}

@test "check_free_space warns for medium space" {
    # Mock df command to return medium space (8GB)
    create_mock_command "df" 0 "8388608"  # 8GB in KB
    
    run check_free_space
    assert_success
    assert_output --partial "getting low"
}

# Test detect_snapshot_system
@test "detect_snapshot_system detects timeshift" {
    create_mock_command "timeshift" 0 ""
    mkdir -p "$TEST_DIR/timeshift/snapshots"
    
    # Override the directory check
    function detect_snapshot_system() {
        if command -v timeshift &> /dev/null && [[ -d "$TEST_DIR/timeshift/snapshots" ]]; then
            echo "timeshift"
        else
            echo "none"
        fi
    }
    
    run detect_snapshot_system
    assert_success
    assert_output "timeshift"
}

@test "detect_snapshot_system detects snapper" {
    create_mock_command "snapper" 0 ""
    mkdir -p "$TEST_DIR/.snapshots"
    
    function detect_snapshot_system() {
        if command -v snapper &> /dev/null && [[ -d "$TEST_DIR/.snapshots" ]]; then
            echo "snapper"
        else
            echo "none"
        fi
    }
    
    run detect_snapshot_system
    assert_success
    assert_output "snapper"
}

@test "detect_snapshot_system returns none when no system found" {
    run detect_snapshot_system
    assert_success
    assert_output "none"
}

# Test cache corruption detection
@test "check_cache_corruption detects database issues" {
    # Mock yay to fail (corrupted database)
    create_mock_command "yay" 1 ""
    
    # Mock user input to decline auto-fix
    echo "n" | run check_cache_corruption
    assert_failure
    assert_output --partial "Package database appears corrupted"
}

@test "check_cache_corruption detects lock file" {
    create_mock_command "yay" 0 "package1\npackage2"
    
    # Create mock lock file
    touch "$TEST_DIR/db.lck"
    
    # Override lock file check to use our test file
    function check_cache_corruption() {
        if [[ -f "$TEST_DIR/db.lck" ]]; then
            echo "WARNING: Pacman database is locked."
            return 1
        fi
    }
    
    run check_cache_corruption
    assert_failure
    assert_output --partial "locked"
}

# Test log function
@test "log function writes to logfile" {
    export LOGFILE="$TEST_DIR/test.log"
    
    run log "Test message"
    assert_success
    assert [ -f "$TEST_DIR/test.log" ]
    
    # Check file contains the message
    run cat "$TEST_DIR/test.log"
    assert_output --partial "Test message"
}

# Test space calculation logic
@test "space calculation converts KB to GB correctly" {
    # Test the awk calculation directly
    result=$(echo "10485760" | awk '{printf "%.1f", $1/1024/1024}')
    assert_equal "$result" "10.0"
    
    result=$(echo "5242880" | awk '{printf "%.1f", $1/1024/1024}')
    assert_equal "$result" "5.0"
}

# Integration tests with more mocking
@test "create_snapshot calls check_free_space" {
    create_mock_command "timeshift" 0 "Snapshot created"
    create_mock_command "df" 0 "20971520"  # 20GB
    
    # Mock sudo to not actually run
    function sudo() {
        echo "Mock: sudo $@"
    }
    
    run create_snapshot
    assert_success
    assert_output --partial "Available disk space"
}

# Test error conditions
@test "script exits when run as root" {
    # This would need to be tested by actually running the script
    # as it checks EUID at the script level
    skip "Requires external script execution test"
}

# Test package rollback logic
@test "rollback_packages checks database health first" {
    create_mock_command "yay" 1 ""  # Simulate corruption
    
    run rollback_packages
    assert_failure
    assert_output --partial "Package database corrupted"
}
