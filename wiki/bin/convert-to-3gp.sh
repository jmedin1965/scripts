
out=${1%.*}.3gp
echo convert $1 to $out

if [ -f "$out" ]
then
	echo "$out: file exists"
else
	avconv -i "$1" -s 4cif -vcodec h263 -r 10 -b 180 -ab 64 -acodec libvo_aacenc -ac 1 -ar 8000 -aspect 16:9 -strict experimental "$out"
fi
