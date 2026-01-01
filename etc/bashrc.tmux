#
# Auto start tmux on login, just add to ~/.bashrc
#


#
# if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
#
if ! command -v tmux &> /dev/null; then
    echo "tmux-start: no tmux found, run apt install tmux"

elif [ -z "$PS1" ]; then
    echo "tmux-start: PS1 = $PS1"

elif [[ "$TERM" =~ screen ]] || [[ "$TERM" =~ tmux ]] || [ -n "$TMUX" ]; then
    echo "tmux-start: TERM = $TERM"

else
  # find out who you sudo'd from
  tmux_session="$(logname 2>/dev/null)"
  tmux_session="${tmux_session:=$USERNAME}"
  # display some info
  echo "+-----------------------------------+"
  echo "| tmux = $(which tmux)         "
  echo "| TERM = $TERM                 "
  echo "| TMUX = $TMUX                 "
  echo "| tmux_session = $tmux_session "


  i="5"
#  echo -n "Press CTRL-C to exit, starting tmux in: $i seconds...  "
  if [ "$(tmux list-session 2>/dev/null)" != "" ]
  then
    echo "|"
    echo "| tmux session list:"
    tmux list-session
  fi
  echo "+-----------------------------------+"
  echo

  while [ $i -gt 0 ]
  do
  	echo -en "\rPress CTRL-C to exit, starting tmux session $tmux_session in: $i seconds...  "
	sleep 1
	(( i-- ))
  done
  echo
  # then attach if this sessio alteady exists, if not, create a new one with that name
  if tmux has-session -t "$tmux_session"; then
    exec tmux at -t "$tmux_session"
  else
    exec tmux new-session -s "$tmux_session"
  fi
fi
#    verbosity: 4

