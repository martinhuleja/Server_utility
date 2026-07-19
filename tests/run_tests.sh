#!/bin/bash

TARGET_SCRIPT="$(pwd)/server_util.sh"
MOCKS_DIR="$(pwd)/tests/mocks"
SANDBOX_DIR="$(pwd)/tests/sandbox"

PASSED=0
FAILED=0

setup_env() {
  mkdir -p "$MOCKS_DIR" "$SANDBOX_DIR"

  # SSH mock: fails if the 'fail_ssh' file exists in the sandbox
  echo -e '#!/bin/bash\nif [ -f fail_ssh ]; then rm fail_ssh; exit 1; fi\nexit 0' >"$MOCKS_DIR/ssh"

  # SCP mock: fails if the 'fail_scp' file exists in the sandbox
  echo -e '#!/bin/bash\nif [ -f fail_scp ]; then rm fail_scp; exit 1; fi\nexit 0' >"$MOCKS_DIR/scp"

  chmod +x "$MOCKS_DIR/ssh" "$MOCKS_DIR/scp"
  export PATH="$MOCKS_DIR:$PATH"
}

teardown_env() {
  rm -rf "$MOCKS_DIR" "$SANDBOX_DIR"
}

run_test() {
  local test_name="$1"
  local expected_code="$2"
  local input_string="$3"
  shift 3

  cd "$SANDBOX_DIR" || exit 1

  # Execute with suppressed standard and error output
  if [ -n "$input_string" ]; then
    echo "$input_string" | "$TARGET_SCRIPT" "$@" >/dev/null 2>&1
  else
    "$TARGET_SCRIPT" "$@" >/dev/null 2>&1
  fi

  local actual_code=$?
  cd - >/dev/null || exit 1

  if [ "$actual_code" -eq "$expected_code" ]; then
    printf "\033[0;32m[PASS]\033[0m %s\n" "$test_name"
    ((PASSED++))
  else
    printf "\033[0;31m[FAIL]\033[0m %s (Expected %d, got %d)\n" "$test_name" "$expected_code" "$actual_code"
    ((FAILED++))
  fi
}

setup_env

# --- ENVIRONMENT SETUP (Mock data) ---
touch "$SANDBOX_DIR/test_file.txt"
touch "$SANDBOX_DIR/test_file2.txt"
mkdir -p "$SANDBOX_DIR/test_dir"
mkdir -p "$SANDBOX_DIR/test_dir2"
touch "$SANDBOX_DIR/existing_local.txt"
touch "$SANDBOX_DIR/fail_dir" # Dummy file to test mkdir failure

# --- 1. ARGUMENT PARSING ---
run_test "Arg: No arguments" 1 ""
run_test "Arg: Help flag (-h)" 0 "" "-h"
run_test "Arg: Help flag (--help)" 0 "" "--help"
run_test "Arg: Unknown argument" 1 "" "--unknown-flag"

run_test "Arg: Missing target for -s (empty)" 1 "" "-s"
run_test "Arg: Missing target for -s (flag follows)" 1 "" "-s" "-f" "test_file.txt"
run_test "Arg: Server alias (eva)" 0 "" "-s" "eva" "-f" "test_file.txt"
run_test "Arg: Server alias (merlin)" 0 "" "-s" "merlin" "-f" "test_file.txt"
run_test "Arg: Custom server" 0 "" "-s" "custom.server.com" "-f" "test_file.txt"

run_test "Arg: Missing file for -f (empty)" 1 "" "-f"
run_test "Arg: Missing file for -f (flag follows)" 1 "" "-f" "-d"
run_test "Arg: Multiple files (-f)" 0 "" "-f" "test_file.txt" "test_file2.txt"

run_test "Arg: Directory flag (-r)" 0 "" "-r"
run_test "Arg: Directory flag (--directory)" 0 "" "--directory"

run_test "Arg: Missing path for -dst (empty)" 1 "" "-dst"
run_test "Arg: Missing path for -dst (flag follows)" 1 "" "-dst" "-s" "eva"

run_test "Arg: Download flag (-dl)" 1 "" "-dl" # Fails correctly (no files specified)
run_test "Arg: Download flag (--download)" 1 "" "--download"

# --- 2. INPUT VALIDATION (UPLOAD) ---
run_test "Upload val: No files" 1 "" "-s" "eva"
run_test "Upload val: File does not exist" 1 "" "-f" "nonexistent.txt"
run_test "Upload val: Target is a directory without -d" 1 "" "-f" "test_dir"
run_test "Upload val: Valid file" 0 "" "-f" "test_file.txt"
run_test "Upload val: Directory default (pwd)" 0 "" "-d"
run_test "Upload val: Multiple valid directories" 0 "" "-d" "test_dir" "test_dir2"
run_test "Upload val: One invalid directory" 1 "" "-d" "test_dir" "nonexistent_dir"
run_test "Upload val: FIT server + \$HOME expansion in -dst" 0 "" "-s" "eva" "-dst" "$HOME/Documents/test" "-f" "test_file.txt"

# --- 3. INPUT VALIDATION (DOWNLOAD) ---
run_test "Download val: No files to download" 1 "" "-get"
run_test "Download val: Overwrite ABORTED (n)" 1 "n" "-get" "-f" "existing_local.txt"
run_test "Download val: Overwrite CONFIRMED (y)" 0 "y" "-get" "-f" "existing_local.txt"
run_test "Download val: Overwrite CONFIRMED (Y)" 0 "Y" "-get" "-f" "existing_local.txt"
run_test "Download val: Valid remote file" 0 "" "-get" "-f" "remote_file.txt"
run_test "Download val: FIT server + \$HOME expansion in -f" 0 "" "-get" "-s" "merlin" "-f" "$HOME/remote_file.txt"

# --- 4. TRANSFER EXECUTION (UPLOAD) ---
touch "$SANDBOX_DIR/fail_ssh"
run_test "Upload exec: SSH failure (mkdir on server)" 1 "" "-f" "test_file.txt"

touch "$SANDBOX_DIR/fail_scp"
run_test "Upload exec: SCP failure (data transfer)" 1 "" "-f" "test_file.txt"

# --- 5. TRANSFER EXECUTION (DOWNLOAD) ---
# Tries to create a directory inside the 'fail_dir' file, triggering a mkdir exit code 1
run_test "Download exec: mkdir failure (local directory)" 1 "" "-get" "-f" "remote.txt" "-dst" "fail_dir/sub"

touch "$SANDBOX_DIR/fail_scp"
run_test "Download exec: SCP failure (data transfer)" 1 "" "-get" "-f" "remote.txt"

# --- TEARDOWN & RESULTS ---
teardown_env

printf "\nPassed: %d, Failed: %d\n" "$PASSED" "$FAILED"
if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
exit 0
