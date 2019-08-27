
release="$(/usr/bin/lsb_release -cs)"

/usr/bin/apt-get -y install ca-certificates
wget https://apt.puppetlabs.com/puppet5-release-${release}.deb
dpkg -i puppet5-release-${release}.deb
rm puppet5-release-${release}.deb

/usr/bin/apt-get update
/usr/bin/apt-get install puppet-agent

#/usr/bin/curl -O https://apt.puppetlabs.com/puppetlabs-release-pc1-${release}.deb
#/usr/bin/dpkg -i puppetlabs-release-pc1-${release}.deb
#/usr/bin/apt-get update
#rm puppetlabs-release-pc1-${release}.deb

