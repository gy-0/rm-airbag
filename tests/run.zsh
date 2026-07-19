#!/bin/zsh

emulate -L zsh
setopt NO_UNSET PIPE_FAIL

typeset test_dir="${0:A:h}"
typeset project_root="${test_dir:h}"
typeset suite_root
suite_root=$(/usr/bin/mktemp -d /tmp/rm-airbag-tests.XXXXXX) || exit 1

typeset test_bin="$suite_root/rm-airbag"
typeset rm_shim="$suite_root/rm"
typeset fake_trash="$project_root/tests/fake-trash.zsh"
typeset fake_store="$suite_root/fake-trash"
typeset output_file="$suite_root/stdout"
typeset error_file="$suite_root/stderr"
typeset last_status=0 passes=0 failures=0

cleanup() {
  /bin/rm -rf -- "$suite_root"
}
trap cleanup EXIT INT TERM

/usr/bin/sed \
  "s|typeset -gr RM_AIRBAG_TRASH_BIN=\"/usr/bin/trash\"|typeset -gr RM_AIRBAG_TRASH_BIN=\"$fake_trash\"|" \
  "$project_root/bin/rm-airbag" >| "$test_bin"
/bin/chmod 755 "$test_bin" "$fake_trash"
/bin/ln -s "$test_bin" "$rm_shim"

run_command() {
  RM_AIRBAG_TEST_ROOT="$suite_root" \
  RM_AIRBAG_FAKE_TRASH="$fake_store" \
  RM_AIRBAG_FAKE_MODE="${RM_AIRBAG_FAKE_MODE:-success}" \
    "$@" >| "$output_file" 2>| "$error_file"
  last_status=$?
}

pass() {
  print -r -- "ok - $1"
  (( passes++ ))
}

fail() {
  print -u2 -r -- "not ok - $1"
  (( failures++ ))
}

assert_status() {
  local expected="$1" label="$2"
  if (( last_status == expected )); then pass "$label"; else fail "$label (status $last_status, expected $expected)"; fi
}

assert_exists() {
  local path="$1" label="$2"
  if [[ -e "$path" || -L "$path" ]]; then pass "$label"; else fail "$label"; fi
}

assert_missing() {
  local path="$1" label="$2"
  if [[ ! -e "$path" && ! -L "$path" ]]; then pass "$label"; else fail "$label"; fi
}

assert_stdout() {
  local expected="$1" label="$2"
  local actual="$(<"$output_file")"
  if [[ "$actual" == "$expected" ]]; then pass "$label"; else fail "$label (got: $actual)"; fi
}

assert_stderr_contains() {
  local expected="$1" label="$2"
  if /usr/bin/grep -Fq -- "$expected" "$error_file"; then pass "$label"; else fail "$label"; fi
}

print -r -- "TAP version 13"

run_command "$rm_shim" --version
assert_status 0 "rm --version exits successfully"
assert_stdout "rm (rm-airbag) 0.1.0 -- moves files to the macOS Trash" "rm --version identifies rm-airbag"

run_command "$rm_shim"
assert_status 1 "missing operand returns 1"
assert_stderr_contains "rm: missing operand" "missing operand reports an rm-style error"

run_command "$rm_shim" -f "$suite_root/does-not-exist"
assert_status 0 "-f ignores a missing operand"

typeset regular_file="$suite_root/regular file"
: >| "$regular_file"
run_command "$rm_shim" -v "$regular_file"
assert_status 0 "regular file moves successfully"
assert_missing "$regular_file" "regular file leaves its original location"
assert_stdout "$regular_file" "-v matches macOS rm path output"

typeset directory="$suite_root/directory"
/bin/mkdir "$directory"
run_command "$rm_shim" "$directory"
assert_status 1 "directory without -r is rejected"
assert_exists "$directory" "rejected directory remains in place"

run_command "$rm_shim" -d "$directory"
assert_status 0 "-d moves an empty directory"
assert_missing "$directory" "-d removes the empty directory from its original location"

typeset recursive_dir="$suite_root/recursive"
/bin/mkdir -p "$recursive_dir/nested"
: >| "$recursive_dir/nested/file"
run_command "$rm_shim" -rf "$recursive_dir"
assert_status 0 "-rf moves a directory hierarchy"
assert_missing "$recursive_dir" "recursive directory leaves its original location"

typeset interactive_file="$suite_root/interactive"
: >| "$interactive_file"
print -r -- "n" | RM_AIRBAG_TEST_ROOT="$suite_root" RM_AIRBAG_FAKE_TRASH="$fake_store" RM_AIRBAG_FAKE_MODE=success \
  "$rm_shim" -i "$interactive_file" >| "$output_file" 2>| "$error_file"
last_status=$?
assert_status 0 "declining -i exits successfully"
assert_exists "$interactive_file" "declining -i keeps the file"

print -r -- "y" | RM_AIRBAG_TEST_ROOT="$suite_root" RM_AIRBAG_FAKE_TRASH="$fake_store" RM_AIRBAG_FAKE_MODE=success \
  "$rm_shim" -i "$interactive_file" >| "$output_file" 2>| "$error_file"
last_status=$?
assert_status 0 "accepting -i exits successfully"
assert_missing "$interactive_file" "accepting -i moves the file"

typeset -a once_files
once_files=("$suite_root/once-a" "$suite_root/once-b" "$suite_root/once-c" "$suite_root/once-d")
for interactive_file in "${once_files[@]}"; do : >| "$interactive_file"; done
print -r -- "n" | RM_AIRBAG_TEST_ROOT="$suite_root" RM_AIRBAG_FAKE_TRASH="$fake_store" RM_AIRBAG_FAKE_MODE=success \
  "$rm_shim" -I "${once_files[@]}" >| "$output_file" 2>| "$error_file"
last_status=$?
assert_status 1 "declining -I matches native macOS rm exit status"
for interactive_file in "${once_files[@]}"; do
  assert_exists "$interactive_file" "declining -I keeps ${interactive_file:t}"
done

typeset dash_dir="$suite_root/dash-name"
/bin/mkdir "$dash_dir"
: >| "$dash_dir/--"
(cd "$dash_dir" && RM_AIRBAG_TEST_ROOT="$suite_root" RM_AIRBAG_FAKE_TRASH="$fake_store" RM_AIRBAG_FAKE_MODE=success \
  "$rm_shim" -- -- >| "$output_file" 2>| "$error_file")
last_status=$?
assert_status 0 "rm -- -- accepts a file named --"
assert_missing "$dash_dir/--" "file named -- is moved"

typeset unsupported_file="$suite_root/unsupported"
: >| "$unsupported_file"
run_command "$rm_shim" -x "$unsupported_file"
assert_status 1 "safety-sensitive unsupported option fails closed"
assert_exists "$unsupported_file" "unsupported option leaves the file in place"

typeset protected_home="$suite_root/protected-home"
/bin/mkdir "$protected_home"
HOME="$protected_home" RM_AIRBAG_TEST_ROOT="$suite_root" RM_AIRBAG_FAKE_TRASH="$fake_store" RM_AIRBAG_FAKE_MODE=success \
  "$rm_shim" -rf "$protected_home" >| "$output_file" 2>| "$error_file"
last_status=$?
assert_status 1 "the HOME directory is protected"
assert_exists "$protected_home" "protected HOME remains in place"

typeset failure_file="$suite_root/failure"
: >| "$failure_file"
RM_AIRBAG_FAKE_MODE=fail run_command "$rm_shim" "$failure_file"
assert_status 1 "Trash failure returns 1"
assert_exists "$failure_file" "Trash failure leaves the source file in place"
assert_stderr_contains "file left in place" "Trash failure is explicit"

typeset batch_one="$suite_root/batch-one" batch_two="$suite_root/batch-two"
: >| "$batch_one"
: >| "$batch_two"
RM_AIRBAG_FAKE_MODE=batch-fallback run_command "$rm_shim" "$batch_one" "$batch_two"
assert_status 1 "batch and individual failures return 1"
assert_exists "$batch_one" "first batch failure remains in place"
assert_exists "$batch_two" "second batch failure remains in place"
assert_stderr_contains "simulated batch failure" "batch error is retained as a fallback"

typeset fake_home="$suite_root/home"
/bin/mkdir "$fake_home"
print -r -- 'export KEEP_ME=1' >| "$fake_home/.zshenv"
RM_AIRBAG_HOME="$fake_home" run_command "$project_root/bin/rm-airbag" enable
assert_status 0 "enable succeeds in an isolated HOME"
assert_exists "$fake_home/.local/share/rm-airbag/shims/rm" "enable creates the rm shim"
if /usr/bin/grep -Fq 'export KEEP_ME=1' "$fake_home/.zshenv"; then pass "enable preserves existing shell config"; else fail "enable preserves existing shell config"; fi

RM_AIRBAG_HOME="$fake_home" run_command "$project_root/bin/rm-airbag" enable
typeset marker_count=$(/usr/bin/grep -Fc '# >>> rm-airbag >>>' "$fake_home/.zshenv")
if (( marker_count == 1 )); then pass "enable is idempotent"; else fail "enable is idempotent (markers: $marker_count)"; fi

RM_AIRBAG_HOME="$fake_home" run_command "$project_root/bin/rm-airbag" doctor
assert_status 0 "doctor validates the isolated installation"

RM_AIRBAG_HOME="$fake_home" run_command "$project_root/bin/rm-airbag" disable
assert_status 0 "disable succeeds"
assert_missing "$fake_home/.local/share/rm-airbag/shims/rm" "disable removes the rm shim"
if /usr/bin/grep -Fq '# >>> rm-airbag >>>' "$fake_home/.zshenv"; then fail "disable removes managed shell blocks"; else pass "disable removes managed shell blocks"; fi
if /usr/bin/grep -Fq 'export KEEP_ME=1' "$fake_home/.zshenv"; then pass "disable preserves unrelated shell config"; else fail "disable preserves unrelated shell config"; fi

typeset malformed_home="$suite_root/malformed-home"
/bin/mkdir "$malformed_home"
print -r -- '# >>> rm-airbag >>>' >| "$malformed_home/.zshenv"
RM_AIRBAG_HOME="$malformed_home" run_command "$project_root/bin/rm-airbag" enable
assert_status 1 "enable rejects a malformed managed block"
assert_missing "$malformed_home/.local/share/rm-airbag/shims/rm" "malformed config causes no partial shim installation"
assert_stdout "" "malformed config produces no success output"
assert_stderr_contains "nothing was changed" "malformed config reports fail-closed behavior"

typeset install_home="$suite_root/install-home"
/bin/mkdir "$install_home"
RM_AIRBAG_HOME="$install_home" run_command "$project_root/scripts/install.sh"
assert_status 0 "source installer succeeds in an isolated HOME"
assert_exists "$install_home/.local/bin/rm-airbag" "source installer installs the executable"
assert_exists "$install_home/.local/share/rm-airbag/shims/rm" "source installer enables the shim"

RM_AIRBAG_HOME="$install_home" run_command "$project_root/scripts/uninstall.sh"
assert_status 0 "source uninstaller succeeds"
assert_missing "$install_home/.local/bin/rm-airbag" "source uninstaller removes the executable"
assert_missing "$install_home/.local/share/rm-airbag/shims/rm" "source uninstaller removes the shim"

print -r -- "1..$(( passes + failures ))"
print -r -- "# $passes passed, $failures failed"
(( failures == 0 ))
