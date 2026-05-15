
out=${1%.*}.avi
echo convert $1 to $out

avconv -i "$1" -s 16cif -vcodec h263 -r 20 -b 360 -ab 128 -acodec libvo_aacenc -ac 1 -ar 16000 -aspect 16:9 -strict experimental "$out"

#avconv -i "$1" -s 4cif -vcodec h263 -r 10 -b 180 -ab 64 -acodec libvo_aacenc -ac 1 -ar 8000 -aspect 16:9 -strict experimental "$out"
