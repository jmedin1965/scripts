
# check teleport_f
# teleport_f is where we save the name and port of the teleport server
# that way, we don't need to find it the next time
if [ -e "/etc/teleport_server.txt" ]
then
  export TELEPORT_PROXY="$(cat "/etc/teleport_server.txt")"
fi

alias tsh-ssh='tsh ssh -A'
