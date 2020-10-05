
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


msg()
{
    echo '***' "$@" > /dev/stderr 
}

error()
{
    msg "$@"
    popd
    exit 1
}


msg "checking program $PROG"

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

        msg "required version is $VERSION"

        # make sure TODIR exists
        /bin/mkdir -p "${TODIR}"

        PROG_NAME_NEW="${TODIR}/${PROG}_${VERSION}_${OS}_${ARCH}"
        PROG_NAME_CUR="${TODIR}/${PROG}_${CURVER}_${OS}_${ARCH}"
        msg "PROG_NAME=$PROG_NAME"

        # get current version we have
        CURVER="unknown"
        if [ -e "${TODIR}/${PROG}" ]
        then
            CURVER="$(set -- $( ${TODIR}/${PROG} version | /usr/bin/head -n 1); echo $2 )"
            CURVER="${CURVER#v}"
            msg "current active version is $CURVER"
        fi

        # fix if PROG is not a symbolic link
        if [ -e "${TODIR}/${PROG}" -a ! -h "${TODIR}/${PROG}" ]
        then
            msg "${TODIR}/${PROG}: not a symbolic link, fixing"
            /bin/mv -f "${TODIR}/${PROG}" "$PROG_NAME_CUR"
        fi

        # check if we have the required version
        URL="https://releases.hashicorp.com/${PROG}/${VERSION}/${PROG}_${VERSION}_${OS}_${ARCH}.zip"
        msg "url=$URL"
        if [ ! -e "$PROG_NAME_NEW" ]
        then
            msg "download and extract $URL"
            /usr/bin/wget --continue -O "${PROG_NAME_NEW}.zip" "$URL"
            /usr/bin/unzip -d "${TODIR}" "${PROG_NAME_NEW}.zip"
            /bin/mv -f "${TODIR}/${PROG}" "${PROG_NAME_NEW}"
            msg "downloaded ${PROG_NAME_NEW}"
            /bin/rm -f "${PROG_NAME_NEW}.zip"
        fi

        if [ -x "${PROG_NAME_NEW}" ]
        then
            /bin/ln -sf "$(/usr/bin/basename "$PROG_NAME_NEW")" "${TODIR}/${PROG}"
            msg "Symbolic linc created"
        fi
        ;;
esac

