# zmx session picker (requires fzf)
# Usage: zmx-select  — or bind to a key, e.g. bindkey '^g' _zmx_select_widget
zmx-select() {
  (( $+commands[zmx] && $+commands[fzf] )) || return 1

  local display
  display=$(zmx list 2>/dev/null | while IFS=$'\t' read -r name pid clients created dir; do
    name=${name#session_name=}
    pid=${pid#pid=}
    clients=${clients#clients=}
    dir=${dir#started_in=}
    printf "%-20s  pid:%-8s  clients:%-2s  %s\n" "$name" "$pid" "$clients" "$dir"
  done)

  local output rc query key selected session_name
  output=$({ [[ -n "$display" ]] && print "$display"; } | fzf \
    --print-query \
    --expect=ctrl-n \
    --height=80% \
    --reverse \
    --prompt="zmx> " \
    --header="Enter: select | Ctrl-N: create new" \
    --preview='zmx history {1}' \
    --preview-window=right:60%:follow \
  )
  rc=$?

  local -a lines=("${(f)output}")
  query="${lines[1]}"
  key="${lines[2]}"
  selected="${lines[3]}"

  if [[ "$key" == "ctrl-n" && -n "$query" ]]; then
    session_name="$query"
  elif [[ $rc -eq 0 && -n "$selected" ]]; then
    session_name="${selected[(w)1]}"
  elif [[ -n "$query" ]]; then
    session_name="$query"
  else
    return 130
  fi

  zle -I
  zmx attach "$session_name"
}

if (( $+commands[zmx] && $+commands[fzf] )); then
  zle -N _zmx_select_widget zmx-select
  bindkey '^g' _zmx_select_widget
fi
