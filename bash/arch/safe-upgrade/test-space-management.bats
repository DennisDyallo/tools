#!/usr/bin/env bats

# Test pure logic - no external dependencies needed
load 'test_helper'

# Test the math directly (most important part)
@test "KB to GB conversion is accurate" {
    # Test known conversions
    result=$(test_space_conversion "10485760")  # 10GB in KB
    [ "$result" = "10.0" ]
    
    result=$(test_space_conversion "5242880")   # 5GB in KB  
    [ "$result" = "5.0" ]
    
    result=$(test_space_conversion "1048576")   # 1GB in KB
    [ "$result" = "1.0" ]
    
    # Test your specific case (23GB)
    result=$(test_space_conversion "24117248")  # ~23GB in KB
    [ "$result" = "23.0" ]
}

# Test threshold logic (pure bash)
@test "space threshold logic works correctly" {
    # Critical threshold (< 5GB)
    [ "$(test_space_threshold 1)" = "critical" ]
    [ "$(test_space_threshold 4)" = "critical" ]
    
    # Warning threshold (5-9GB)
    [ "$(test_space_threshold 5)" = "warning" ]
    [ "$(test_space_threshold 9)" = "warning" ]
    
    # OK threshold (10+ GB)
    [ "$(test_space_threshold 10)" = "ok" ]
    [ "$(test_space_threshold 23)" = "ok" ]  # Your system
    [ "$(test_space_threshold 50)" = "ok" ]
}

# Test edge cases
@test "space conversion handles edge cases" {
    # Very small values
    result=$(test_space_conversion "1024")      # 1MB
    [ "$result" = "0.0" ]
    
    # Very large values  
    result=$(test_space_conversion "104857600") # 100GB
    [ "$result" = "100.0" ]
}

# Test the actual awk command used in script
@test "awk conversion matches our test function" {
    kb_values=("1048576" "5242880" "10485760" "24117248")
    
    for kb in "${kb_values[@]}"; do
        # Our test helper
        helper_result=$(test_space_conversion "$kb")
        
        # Actual command from script
        script_result=$(echo "$kb" | awk '{printf "%.1f", $1/1024/1024}')
        
        [ "$helper_result" = "$script_result" ]
    done
}