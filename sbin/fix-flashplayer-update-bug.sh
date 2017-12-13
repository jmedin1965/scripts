#
# REF: https://bugs.launchpad.net/ubuntu/+source/update-notifier/+bug/1570141
#

chown -R _apt:root /var/lib/update-notifier/package-data-downloads/partial

rm /var/lib/update-notifier/package-data-downloads/partial/*.FAILED
rm /var/lib/update-notifier/package-data-downloads/partial/*.*

apt install --reinstall update-notifier-common

