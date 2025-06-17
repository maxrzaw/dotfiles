function prompt_aws_token_validity() {
    # Ensure the AWS token daemon is running
    ensure_aws_token_daemon_running
    local my_aws_cache_file="/tmp/aws_token_status_$USER"
    local my_aws_status="checking"

    # Read status from cache file if it exists
    if [[ -f $my_aws_cache_file ]]; then
        my_aws_status=$(<"$my_aws_cache_file")
    fi

    # Display appropriate segment based on status
    if [[ $my_aws_status == "valid" ]]; then
        p10k segment -b green -f black -i '' -t 'Valid'
    elif [[ $my_aws_status == "expired" ]]; then
        p10k segment -b red -f white -i '' -t 'Expired'
    else
        p10k segment -b yellow -f black -i '' -t '...'
    fi
}

function instant_prompt_aws_token_validity() {
    # Instant prompt can't check token validity (no subshells), so show neutral
    p10k segment -b yellow -f black -i ' ' -t '...'
}

function ensure_aws_token_daemon_running() {
    # This line sets the variable `my_aws_daemon_py` to the path of a file named `aws_token_daemon.py`
    # located in the same directory as the current script.
    local my_aws_daemon_py="${${(%):-%x}:h}/aws_token_daemon.py"

    # Check if daemon is running
    if ! pgrep -f "python.*aws_token_daemon.py" >/dev/null; then
        # Start daemon if not running
        (nohup python3 "$my_aws_daemon_py" >/dev/null 2>&1 &)
    fi
}
