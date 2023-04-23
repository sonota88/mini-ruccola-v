#!/usr/bin/bash

set -o errexit

infile="$1"

mkdir -p bin

bname="$(basename $infile .v)"
dname="$(dirname $infile)"

v -enable-globals $infile
mv "${dname}/${bname}" bin/$bname
