ip=""
if [ -e "/mnt/c/WINDOWS/system32/netstat.exe" ]
then
  pwd="$(/bin/pwd)"
  cd /mnt/c
  ip=$(set -- $(/mnt/c/WINDOWS/system32/netstat.exe -r | /bin/grep "0.0.0.0 \+0.0.0.0"); echo $4)
  cd "$pwd"
fi
if [ -n "$ip" ]
then
	export DISPLAY=$ip:0
else
	export DISPLAY=:0
fi
unset ip pwd
