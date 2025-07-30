# safer rm: send to trash if available, else enforce interactive mode
if command -v trash >/dev/null 2>&1; then
  rm() {
    # collect only non-flag arguments to pass to trash
    local non_flag_args=()
    local arg
    for arg in "$@"; do
      [[ $arg == -* ]] || non_flag_args+=("$arg")
    done

    if (( ${#non_flag_args[@]} )); then
      trash "${non_flag_args[@]}"
    else
      # if no files given, just call the real rm to show usage
      command rm "$@"
    fi
  }
else
  rm() {
    local has_i=0
    local args=()
    local arg
    for arg in "$@"; do
      if [[ $arg == -* && $arg == *i* ]]; then
        has_i=1
      fi
      args+=("$arg")
    done

    # if no interactive flag, inject -i
    (( has_i == 0 )) && args=(-i "${args[@]}")

    command rm "${args[@]}"
  }
fi

