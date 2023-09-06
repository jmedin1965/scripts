ip=""
[ -e "/mnt/c/WINDOWS/system32/netstat.exe" ] && \
  ip=$(set -- $(/mnt/c/WINDOWS/system32/netstat.exe -r | /usr/bin/grep "0.0.0.0 \+0.0.0.0"); echo $4)
if [ -n "$ip" ]
then
	export DISPLAY=$ip:0
else
	export DISPLAY=:0
fi
unset ip
