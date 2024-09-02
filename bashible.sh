#!/usr/bin/env bash

dot="●" 
wid=$(tput cols)
total=$((wid - 23))
SUCCESS=$(tput setaf 2; tput bold; printf "SUCCESS")
FAIL=$(tput setaf 1; tput bold; printf "FAIL")
WARNING=$(tput setaf 3; tput bold; printf "WARNING")

function print_title() {
    value=$(echo $1 | sed 's("((g')
    tput bold; tput smul; echo -e \\n\\t"$value"\\n; tput sgr0
}

function print_message () {
    local message="$1"
    local return_code="$2"

    # Calculate the necessary lengths and padding
    local len=$(echo -n "$message" | wc -c)
    local padding=$((total - len - 7))

    # Determine the status symbol and label based on the return code
    if [ "$return_code" -eq 0 ]; then
        status_symbol="$dot"
        status_label="$SUCCESS"
    elif [ "$return_code" -eq 1 ]; then
        status_symbol="$dot"
        status_label="$FAIL"
    else
        status_symbol="$dot"
        status_label="$WARNING"
    fi

    # Generate the padding and print the message using printf
    v=$(printf "%-${padding}s" "")
    printf "\t%s %s %s %s\n" "$status_symbol" "$message" "${v// /.}" "$status_label"
    tput sgr0  # Reset terminal colors
}

function write_log() {

    name="$1"
    command="$2"
    stderr="$3"
    rc="$4"

    echo -e "\tTASK: $name: ($type)" >> $fail_log
    echo -e "\tCOMMAND: $command" >> $fail_log
    echo -e "\tRESULT: Return Code was $rc" >> $fail_log
    echo -e "\tSTDERR: $stderr"\\n >> $fail_log
    
}

function run_return_code() {
    
    test=$1
    name=$(echo "$test" | jq -r '.name')
    command=$(echo "$test" | jq -r '.command')
    type=$(echo "$test" | jq -r '.type')
    success_code=$(echo "$test" | jq -r '.success_code')
    fail_code=$(echo "$test" | jq -r '.fail_code')
    warn_code=$(echo "$test" | jq -r '.warn_code')

    stderr=$(eval "$command" 2>&1 >/dev/null)

    rc=$?

    if [ $rc -eq $success_code ]; then
        print_message "$name" 0
    elif [ $rc -eq $fail_code ]; then
        print_message "$name" 1
        write_log  "$name" "$command" "$stderr" "$rc" "$type"
    else
        print_message "$name" 1
        write_log  "$name" "$command" "$stderr" "$rc" "$type"
    fi

}

function run_grep_check() {
    
    local test=$1
    local name=$(echo "$test" | jq -r '.name')
    local file_path=$(echo "$test" | jq -r '.path')
    local value=$(echo "$test" | jq -r '.value')
    local ignore_case=$(echo "$test" | jq -r '.ignore_case' | tr '[:upper:]' '[:lower:]')

    # Test if file exists
    if [ ! -f "$file_path" ]; then
        print_message "$name" 1
        return 1
    fi

    # Build and execute grep command
    if [[ "$ignore_case" == "true" ]]; then
        grep_count=$(grep -i -v '^#' "$file_path" | grep -ic "$value" 2> /dev/null)
    else
        grep_count=$(grep -v '^#' "$file_path" | grep -c "$value" 2> /dev/null)
    fi

    # Check the result and print the message
    if [[ "$grep_count" -ge 1 ]]; then
        print_message "$name" 0
    else
        print_message "$name" 1
    fi

}

# Check test file argument
tasks_file=""

# Parse command-line arguments
for arg in "$@"; do
    case $arg in
        --tasks-file=*)
        tasks_file="${arg#*=}"
        shift # Remove the processed argument
        ;;
        *)
        # Handle other options or arguments here
        echo "Unknown argument: $arg"
        ;;
    esac
done

if [[ ! -f $tasks_file ]]; then
    echo "ERROR! Please provide tasks file"
    exit 1
fi

# Truncate log file
fail_log="/tmp/fails.txt"

if [[ ! -f $fail_log ]]; then
    touch "$fail_log"
else
    truncate -s 0 "$fail_log"
fi

# Check any tasks specify sudo and prompt for credentials
is_sudo=$(grep -c 'command: sudo' "$tasks_file")
if [[ is_sudo -ge 1 ]]; then
    # Prompt for sudo
    echo "Please enter sudo password"
    sudo echo '' &> /dev/null
fi

# Print title found in yaml
title=$(yq e '.title' -o=json "$tasks_file")

print_title "$title"

yq e '.tests[]' -o=json "$tasks_file" | jq -c '.' | while IFS= read -r test; do
    
    type=$(echo "$test" | jq -r '.type')

    case "$type" in
        "return_code")
            run_return_code "$test"
            ;;
        "grep_check")
            run_grep_check "$test"
            ;;
        *)
            echo "Can't process this task"
            exit 1
            ;;
    esac
done


#check if logfile has any content
is_log=$(wc -l $fail_log | awk '{print $1}')

if [[ $is_log -ge 1 ]]; then
    tput bold; tput setaf 1; tput smul
    echo -e \\n\\n\\t"Failed Checks (output from $fail_log)"; tput sgr0
    echo -e "$(cat $fail_log)"\\n\\n
    exit 1
else
    exit 0
fi