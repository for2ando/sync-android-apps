#!/bin/bash
pname=$(basename "$0")
usage="$pname [-h|--help]"
case "$1" in -*) echo "$usage"; exit 1;; esac
test $# -ne 0 && { echo "$usage"; exit 1;}

(
  test "$(basename $(pwd))" = apps && cd ..
  test -r @list || { echo "@list: no such a file here.">&2; exit 2;}
  
  cat @list | get-android-app-name -p - >@list.withName
)
