#
#
# $Header:$

sources_file=/etc/apt/sources.list
cache_server=http://

# backup original file
if [ -f "$sources_file.orig" ]
then
	echo "** backup $sources_file to .orig"
	cp "$sources_file" "$sources_file.orig" 
fi

sed
