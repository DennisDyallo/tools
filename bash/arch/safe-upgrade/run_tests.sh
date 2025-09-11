#!/bin/bash
echo "Running all test suites..."
echo ""
echo "Test files found:"
ls -1 *.bats | sed 's/^/  /'
echo ""
bats *.bats
