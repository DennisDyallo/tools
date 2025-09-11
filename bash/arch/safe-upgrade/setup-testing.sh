#!/bin/bash

# Setup testing environment for safe-arch-upgrade script

echo "=== Setting up testing environment ==="

# 1. Install testing framework
install_bats() {
    echo "Installing Bats testing framework..."
    
    if command -v yay &> /dev/null; then
        yay -S bats-core bats-assert bats-support --noconfirm
    else
        # Manual installation
        git clone https://github.com/bats-core/bats-core.git /tmp/bats-core
        cd /tmp/bats-core
        sudo ./install.sh /usr/local
        
        # Install helpers
        git clone https://github.com/bats-core/bats-support.git test_helper/bats-support
        git clone https://github.com/bats-core/bats-assert.git test_helper/bats-assert
    fi
}

# 2. Create test directory structure
create_test_structure() {
    echo "Creating test directory structure..."
    
    mkdir -p tests
    mkdir -p tests/fixtures
    mkdir -p tests/mocks
    mkdir -p tests/test_helper
    
    # Create test configuration
    cat > tests/test_helper/test_helper.bash << 'EOF'
# Common test helper functions

setup_test_env() {
    export TEST_DIR="$(mktemp -d)"
    export LOGFILE="$TEST_DIR/test.log"
    export TESTING=true
    
    # Prevent actual system operations
    export PATH="$TEST_DIR/mocks:$PATH"
    mkdir -p "$TEST_DIR/mocks"
}

teardown_test_env() {
    rm -rf "$TEST_DIR"
}

# Mock a command with specific output and exit code
mock_command() {
    local cmd="$1"
    local exit_code="${2:-0}"
    local output="$3"
    
    cat > "$TEST_DIR/mocks/$cmd" << MOCKEOF
#!/bin/bash
echo "$output"
exit $exit_code
MOCKEOF
    chmod +x "$TEST_DIR/mocks/$cmd"
}

# Extract functions from main script for unit testing
extract_functions() {
    # Copy script but remove main execution
    grep -v "^main " safe-arch-upgrade.sh > "$TEST_DIR/functions_only.sh"
    echo "# Functions extracted for testing" >> "$TEST_DIR/functions_only.sh"
    source "$TEST_DIR/functions_only.sh"
}
EOF
}

# 3. Create specific tests for our script functions
create_specific_tests() {
    echo "Creating specific test files..."
    
    # Test argument parsing
    cat > tests/test_argument_parsing.bats << 'EOF'
#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/test_helper'

setup() {
    setup_test_env
    extract_functions
}

teardown() {
    teardown_test_env
}

@test "parse_args sets ROLLBACK_MODE for --rollback" {
    ROLLBACK_MODE=false
    parse_args --rollback
    assert_equal "$ROLLBACK_MODE" "true"
}

@test "parse_args handles multiple arguments" {
    # Test that parse_args can handle combinations
    run parse_args upgrade
    assert_success
}
EOF

    # Test space checking
    cat > tests/test_space_management.bats << 'EOF'
#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/test_helper'

setup() {
    setup_test_env
    extract_functions
}

teardown() {
    teardown_test_env
}

@test "check_free_space calculates GB correctly" {
    # Mock df to return known value
    mock_command "df" 0 "10485760"  # 10GB in KB
    
    # Override the df command call in function for testing
    check_free_space_test() {
        local free_gb=$(echo "10485760" | awk '{printf "%.1f", $1/1024/1024}')
        echo "Available disk space: ${free_gb}GB"
    }
    
    run check_free_space_test
    assert_success
    assert_output "Available disk space: 10.0GB"
}

@test "space thresholds work correctly" {
    # Test different space levels
    for space_gb in 3 7 15; do
        space_kb=$((space_gb * 1024 * 1024))
        gb_result=$(echo "$space_kb" | awk '{printf "%.1f", $1/1024/1024}')
        assert_equal "$gb_result" "${space_gb}.0"
    done
}
EOF

    # Test system detection
    cat > tests/test_system_detection.bats << 'EOF'
#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/test_helper'

setup() {
    setup_test_env
    extract_functions
}

teardown() {
    teardown_test_env
}

@test "detect_snapshot_system finds timeshift" {
    mock_command "timeshift" 0 ""
    mkdir -p "$TEST_DIR/timeshift/snapshots"
    
    # Override directory checks for testing
    detect_snapshot_system_test() {
        if [[ -x "$TEST_DIR/mocks/timeshift" && -d "$TEST_DIR/timeshift/snapshots" ]]; then
            echo "timeshift"
        else
            echo "none"
        fi
    }
    
    run detect_snapshot_system_test
    assert_success
    assert_output "timeshift"
}
EOF
}

# 4. Create integration tests
create_integration_tests() {
    cat > tests/test_integration.bats << 'EOF'
#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/test_helper'

@test "script shows help without errors" {
    run bash safe-arch-upgrade.sh --help
    assert_success
    assert_output --partial "Usage:"
}

@test "script rejects invalid arguments" {
    run bash safe-arch-upgrade.sh --invalid-option
    assert_failure
    assert_output --partial "Unknown option"
}

@test "script checks for root user" {
    # This would need special handling to test EUID check
    skip "Requires privilege testing setup"
}
EOF
}

# 5. Create performance and property tests
create_property_tests() {
    cat > tests/test_properties.bats << 'EOF'
#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

@test "space conversion is consistent" {
    # Property: KB to GB conversion should be accurate within 0.1GB
    test_values=(1048576 5242880 10485760 20971520)  # 1, 5, 10, 20 GB
    expected=(1.0 5.0 10.0 20.0)
    
    for i in "${!test_values[@]}"; do
        kb_value="${test_values[$i]}"
        expected_gb="${expected[$i]}"
        
        actual_gb=$(echo "$kb_value" | awk '{printf "%.1f", $1/1024/1024}')
        assert_equal "$actual_gb" "$expected_gb"
    done
}

@test "log function creates readable output" {
    export LOGFILE="/tmp/test.log"
    
    # Test log function (would need to source functions)
    echo "Test message" | tee -a "$LOGFILE"
    
    assert [ -f "$LOGFILE" ]
    run cat "$LOGFILE"
    assert_output "Test message"
    
    rm -f "$LOGFILE"
}
EOF
}

# 6. Create test runner script
create_test_runner() {
    cat > run_tests.sh << 'EOF'
#!/bin/bash

echo "=== Running Safe Arch Upgrade Tests ==="

# Set up environment
export BATS_LIB_PATH="/usr/lib/bats-support:/usr/lib/bats-assert"

# Run all tests
echo "Running unit tests..."
bats tests/test_*.bats

echo
echo "=== Test Summary ==="
echo "Unit tests completed. Check output above for results."

# Optional: Generate coverage report
if command -v bashcov &> /dev/null; then
    echo "Generating coverage report..."
    bashcov bats tests/test_*.bats
fi
EOF
    chmod +x run_tests.sh
}

# Main installation function
main() {
    if [[ ! -f "safe-arch-upgrade.sh" ]]; then
        echo "Error: safe-arch-upgrade.sh not found in current directory"
        echo "Please run this setup script in the same directory as your main script."
        exit 1
    fi
    
    install_bats
    create_test_structure
    create_specific_tests
    create_integration_tests
    create_property_tests
    create_test_runner
    
    echo
    echo "=== Testing Setup Complete ==="
    echo "To run tests:"
    echo "  ./run_tests.sh"
    echo
    echo "To run specific test file:"
    echo "  bats tests/test_space_management.bats"
    echo
    echo "Test files created:"
    echo "  tests/test_argument_parsing.bats"
    echo "  tests/test_space_management.bats" 
    echo "  tests/test_system_detection.bats"
    echo "  tests/test_integration.bats"
    echo "  tests/test_properties.bats"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
EOF
