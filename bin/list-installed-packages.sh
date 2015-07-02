echo "HowTo: Create a list of installed packages"
echo "I found out how to do this recently and thought it might be helpful to some people. To output this information to a file in your home directory you would use,"

echo

dpkg --get-selections # > installed-software

echo "And if you wanted to use the list to reinstall this software on a fresh ubuntu setup,"

echo

echo "dpkg --set-selections < installed-software"

echo
echo "followed by;"
echo
echo "dselect"


