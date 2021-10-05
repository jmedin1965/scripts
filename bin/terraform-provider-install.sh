#!/bin/bash

if [ $# == 0 ]
then
    echo usage: $(basename "$0") provider
    exit 1
fi

GOOS="$(go env GOOS)"
GOARCH="$(go env GOARCH )"
VER="$(git tag|tail -n 1)"

echo GOOS = \"$GOOS\"
echo GOARCH = \"$GOARCH\"
echo VER = \"$VER\"

echo installing "/usr/local/bin/${1}_$VER"

cp -a "$1" "/usr/local/bin/${1}_$VER"

# Custom provider repo how to
#
# REF https://www.terraform.io/docs/configuration/provider-requirements.html
#
