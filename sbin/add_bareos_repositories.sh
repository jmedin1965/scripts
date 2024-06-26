#!/bin/sh

set -u
set -e

PREFIX_DIR=""
# declare the Bareos repository
DOWNLOADSERVER="download.bareos.org"
URL="http://download.bareos.org/current/Debian_12"

# Juan
[ -e /etc/os-release ] && . /etc/os-release
if [ "$ID" = "debian" ]
then
    URL="$(/usr/bin/dirname "$URL")/Debian_$VERSION_ID" 

elif [ "$ID" = "ubuntu" ]
then
    URL="$(/usr/bin/dirname "$URL")/xUbuntu_$VERSION_ID" 
fi
echo URL is now $URL
# Juan end

# setup credentials for apt auth
# (required for download.bareos.com, subscription)
BAREOS_USERNAME="username_at_example.com"
BAREOS_PASSWORD="MySecretBareosPassword"

if [ "${DOWNLOADSERVER}" = "download.bareos.com" ] && [ -d "${PREFIX_DIR}/etc/apt/auth.conf.d/" ]; then
    cat <<EOT >"${PREFIX_DIR}/etc/apt/auth.conf.d/download_bareos_com.conf"
machine download.bareos.com
login ${BAREOS_USERNAME}
password ${BAREOS_PASSWORD}
EOT
    chmod 0600 "${PREFIX_DIR}/etc/apt/auth.conf.d/download_bareos_com.conf"
fi

# add the Bareos repository
cat <<EOT >"${PREFIX_DIR}/etc/apt/sources.list.d/bareos.sources"
Types: deb deb-src
URIs: ${URL}
Suites: /
Architectures: amd64
Signed-By: ${PREFIX_DIR}/etc/apt/keyrings/bareos-experimental.gpg
EOT

# add package key
mkdir -p "${PREFIX_DIR}/etc/apt/keyrings/"
# download key via
if [ ! -x /usr/bin/gpg ]
then
    wget -O /etc/apt/keyrings/bareos-experimental.gpg ${URL}/bareos-keyring.gpg
else
    # or
cat << EOT | gpg --dearmor -o "${PREFIX_DIR}/etc/apt/keyrings/bareos-experimental.gpg"
-----BEGIN PGP PUBLIC KEY BLOCK-----

mQINBF23EK4BEAC1FADpF6aaC93bxouVT6/BuXJajjtLkHNKfY26BYuvpwgLmVwp
M8vBuQWEPxxP6y2wXffv5bO/0Y1tS7tCW4i7duKz6W6as7/N13P/Mah8KOS0Zles
VM94fKXX8um7okqY9EwqgWVyHetW0PVpMKCsguMezv0IUmGAi/XX/GgJBeDYWvTh
S8DXtMhqWMXWv9yptJJsFQgdS0GVb8fcHG+Vl5GWmb+p8+R5x2JjLrP2OIoY8caD
boueBiUUeYnlPQqBa7flZSlBslSbk8qwnr75r/fX0/ihnFfLZol348AOCjPeWEYM
H3xQvuuyXsOg7dJ3dX4pE/MwUUOSlWyAACvCDYLQ+Xlvnt1j1dmbnGiBYRfn9cMZ
YEDZVSey7LwUwkXi9yXAc5+g6+OUUz1dIoZCyiAezttU8yfoiLXgilOHm7LniW4o
n5LIxTmo3pUSeEdQntFKd8jStIhvhGyKop1wlDU+FGUaxgWdswKE5se7WdaR6Em7
iuOMd9hZpS24Y4jeGjr4v4uwzB/Y8eB+vvM/ISGJltC8zgNpk81Dv1g2m/cy3YLb
POUxNy5+TAdO3UztuYbGQqgDax8RESD/6CbC8Z8X4TXYETjqtBR/9dNWBJCMb3aT
CXqZyc0YwiU0ISDCZhKbrPCkhwniOI4gqNz2pyFn9eUBw4xXx4DV0rQkyQARAQAB
tDRCYXJlb3MgZXhwZXJpbWVudGFsIFNpZ25pbmcgS2V5IDxzaWduaW5nQGJhcmVv
cy5jb20+iQI5BBMBAgAjBQJdtxCuAhsDBwsJCAcDAgEGFQgCCQoLBBYCAwECHgEC
F4AACgkQQtokpt/vkSdp9RAAnYDZdfswrj5K2Kr/vL7rE5JrmbjoobapqqIIOnLg
3RfBMJqfc3CMFwpcPR8i2L1UluMiMYjHBrjeJrpqb6ZKbQQhTWxMj6vqHXaBWJ65
z1UjDHzbvY/1BjXQy2j7LusbCNZjgGkYtafl4/4IUiH6++n6QsPfagphOuY1k3Uv
RqAKf/3DWChV8uU+lnMG3Gf9ZaJ4G3Q3ybxdJ2MMH/F4DIgWMMapRiRUZSEO/xgX
gyS1f1TLUTgLL1p0rUuDb9Jk+ntfntxTlCZl/njdtUgGa+Fbom6itnGJZVI4PmRr
f+7Rt+YOimp/LQ+dvcVoLrvX2uugdSe96yS8MWr6vbB4AipxKHsjp0bOuHj9yMr7
+VS9pQQ9frlk0gGkxjFflpvgjWqLnFBQjX7OFXW3U8w6vFjoWwS2zmdekWd36yF/
JUtG1aBIk7T5wOImVdDkT/QXXK21Lu2HUfymvBLpWiRPi6P7Nye6XSYp3i1lpV20
UmucKiOed93dBJLWcbelJdAJCPeLhvuTIZRZqrJ+z4ZozjgXf/8g7RR/HCKaUt+M
i6P0TKYbyneXK166OqiyGGY0/enbAKSf/+K/FyPRsAHbGd+3wOY26QdL/JfNnJq0
eOkfPAZ+RjfWMd8VMMrx11gV+hPzszQHUKoWhyC0EndKuvU00QQ+EL6yBjMbjIHI
KL8=
=j9IV
-----END PGP PUBLIC KEY BLOCK-----
EOT
fi

echo "Repository ${URL} successfully added."
