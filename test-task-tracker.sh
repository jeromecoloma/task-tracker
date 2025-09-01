#!/usr/bin/env bash
# Test script for task-tracker functionality
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

test_count=0
pass_count=0

run_test() {
  local test_name="$1"
  local command="$2"
  local expected_exit_code="${3:-0}"
  
  test_count=$((test_count + 1))
  printf "${BLUE}Test ${test_count}: ${test_name}${RESET}\n"
  
  if eval "$command" >/dev/null 2>&1; then
    local exit_code=0
  else
    local exit_code=$?
  fi
  
  if [[ $exit_code -eq $expected_exit_code ]]; then
    printf "${GREEN}✅ PASS${RESET}\n"
    pass_count=$((pass_count + 1))
  else
    printf "${RED}❌ FAIL (expected exit code $expected_exit_code, got $exit_code)${RESET}\n"
  fi
  echo
}

printf "${YELLOW}Task Tracker Test Suite${RESET}\n"
printf "========================\n\n"

# Basic functionality tests
run_test "Help command works" "./task-tracker --help"
run_test "Version command works" "./task-tracker --version"
run_test "Invalid command fails" "./task-tracker invalid-command" 1

# Configuration tests
rm -f ./.tasktrackerrc
run_test "Init command works" "printf 'y\nTEST-\n_SUFFIX\nWorking on ticket\nTest User\nhttps://test.zendesk.com\nAsia/Manila\ny\n' | ./task-tracker init"
run_test "Config file exists" "test -f ./.tasktrackerrc"

# New syntax validation tests
run_test "Start without ticket ID fails" "./task-tracker start" 1
run_test "Start with non-numeric ticket ID fails" "./task-tracker start abc" 1

# Dependency checking tests (with limited PATH to simulate missing deps)
run_test "Dependency checking works" "PATH='/usr/bin:/bin' ./task-tracker start 12345 --no-validate" 1

# Help for specific commands
run_test "Start command help works" "./task-tracker start --help"

# Passthrough commands (these will fail due to missing deps but should reach the right error)
run_test "Stop command reaches toggl-track" "PATH='/usr/bin:/bin' ./task-tracker stop" 1
run_test "Status command reaches toggl-track" "PATH='/usr/bin:/bin' ./task-tracker status" 1

# Summary
echo "========================"
printf "${YELLOW}Test Summary${RESET}\n"
printf "Tests run: $test_count\n"
printf "Tests passed: ${GREEN}$pass_count${RESET}\n"
printf "Tests failed: ${RED}$((test_count - pass_count))${RESET}\n"

if [[ $pass_count -eq $test_count ]]; then
  printf "\n${GREEN}All tests passed!${RESET}\n"
  exit 0
else
  printf "\n${RED}Some tests failed.${RESET}\n"
  exit 1
fi