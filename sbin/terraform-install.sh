#!/bin/bash

#
# Hashicorp now have a repo
#
# REF: https://developer.hashicorp.com/terraform/install

# Required version, can be latest
VERSION="0.13.4"
VERSION="latest"

# os and arch
OS="linux"
ARCH="amd64"

# go URL
URL="https://dl.google.com/go"

# where to install downloaded file
TODIR="/usr/local"

# extract the program we want upgraded from this programs name as a/b/c/prog-anything
PROG="${0##*/}"
PROG="${PROG%-*}"

DEBUG="0"

msg()
{
    echo '***' "$@" > /dev/stderr 
}

debug()
{
    [ "$DEBUG" -gt 0 ] && msg "$@"
}

error()
{
    msg "$@"
    exit 1
}

if [ -n "$1" ]
then
    PROG="$1"
fi
debug "checking program $PROG"

if [ ! -e /usr/share/keyrings/hashicorp-archive-keyring.gpg ]
then
    wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
fi

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
apt update
[ -n "$PROG" ] && apt install $PROG

exit 0




case "$PROG" in
    'go')
        # find/check required version
        if [ -z "$VERSION" -o "$VERSION" == latest ]
        then
            TGZ_FILE="${OS}-${ARCH}.tar.gz"
            STR="<a class=\"download downloadBox\" href=\"/dl/.*.${TGZ_FILE}\">"
            VERSION="$(/usr/bin/curl --silent https://golang.org/dl/ | /bin/grep '<a class="download downloadBox" href="/dl/.*.linux-amd64.tar.gz">' | /bin/sed "s,.*/dl/\(.*\)\.${TGZ_FILE}.*,\1,g")"
        fi
        GO_DIR="$VERSION.$OS-$ARCH"
        if [ -x "${TODIR}/${GO_DIR}/bin/go" ]
        then
            msg "${GO_DIR}: this version is already installed"
        else
            msg "getting go version ${GO_DIR}"
            /bin/mkdir -p "${TODIR}/${GO_DIR}"
            /usr/bin/wget --continue -O "${TODIR}/${GO_DIR}.tar.gz" "${URL}/${GO_DIR}.tar.gz"
            /bin/tar "--one-top-level=${TODIR}/${GO_DIR}" -zxf "${TODIR}/${GO_DIR}.tar.gz"
            /bin/mv "${TODIR}/$GO_DIR/go/"* "${TODIR}/$GO_DIR"
            /bin/rmdir "${TODIR}/$GO_DIR/go"
        fi

        echo "
export GOROOT=${TODIR}/${GO_DIR}
export GOPATH=\"\$HOME/go\"
export PATH=\$GOROOT/bin:\$PATH
" > /etc/profile.d/golang.sh
        /bin/chmod 755 /etc/profile.d/golang.sh
        . /etc/profile.d/golang.sh
        ;;
    *)
        # Put hashicorp progs in bin directory
        TODIR="${TODIR}/bin"

        # find/check required version
        if [ -z "$VERSION" -o "$VERSION" == latest ]
        then
            # find latest version
            VERSION="$(curl -s https://checkpoint-api.hashicorp.com/v1/check/$PROG | jq .current_version | tr -d '"')"
        fi

        debug "required version is $VERSION"

        if [ "$(whoami)" != root ]
        then
            msg "not root user, not checking for updates"
        else
            # make sure TODIR exists
            /bin/mkdir -p "${TODIR}"

            # get current version we have
            CURVER="unknown"
            if [ -e "${TODIR}/${PROG}" ]
            then
                CURVER="$(set -- $( ${TODIR}/${PROG} version | /usr/bin/head -n 1); echo $2 )"
                CURVER="${CURVER#v}"
                debug "current active version is $CURVER"
            fi

            PROG_NAME_NEW="${TODIR}/${PROG}_${VERSION}_${OS}_${ARCH}"
            PROG_NAME_CUR="${TODIR}/${PROG}_${CURVER}_${OS}_${ARCH}"
            debug "PROG_NAME=$PROG_NAME"
            debug "PROG_NAME_NEW=$PROG_NAME_NEW"
            debug "PROG_NAME_CUR=$PROG_NAME_CUR"

            # fix if PROG is not a symbolic link
            debug "${TODIR}/${PROG}: check if not a sym link."
            if [ -e "${TODIR}/${PROG}" -a ! -h "${TODIR}/${PROG}" ]
            then
                msg "${TODIR}/${PROG}: not a symbolic link, fixing"
                /bin/mv -f "${TODIR}/${PROG}" "$PROG_NAME_CUR"
            fi

            # check if we have the required version
            URL="https://releases.hashicorp.com/${PROG}/${VERSION}/${PROG}_${VERSION}_${OS}_${ARCH}.zip"
            debug "url=$URL"
            if [ ! -e "$PROG_NAME_NEW" ]
            then
                msg "download and extract $URL"
                /usr/bin/wget --continue -O "${PROG_NAME_NEW}.zip" "$URL"
                /usr/bin/unzip -d "/tmp" "${PROG_NAME_NEW}.zip" "$PROG"
                /bin/mv -f "/tmp/${PROG}" "${PROG_NAME_NEW}"
                msg "downloaded ${PROG_NAME_NEW}"
                /bin/rm -f "${PROG_NAME_NEW}.zip"

                /bin/ln -sf "$(/usr/bin/basename "$PROG_NAME_NEW")" "${TODIR}/${PROG}"
                msg /bin/ln -sf "$(/usr/bin/basename "$PROG_NAME_NEW")" "${TODIR}/${PROG}"
                msg "Symbolic link created, pwd=$(pwd)"
            fi
        fi

        exec "${TODIR}/${PROG}" "$@"
        ;;
esac

