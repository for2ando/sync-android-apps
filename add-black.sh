#!/bin/bash
pname=$(basename "$0")
usage="$pname [-h|--help] AppId [...]"
case "$1" in -*) echo "$usage"; exit 1;; esac
test $# -le 0 && { echo "$usage"; exit 1;}

dname=$(dirname "$0")
case "$dname" in /*);; *) dname="$(pwd)/$dname";; esac

(
  test "$(basename $(pwd))" = apps && cd ..
  test -d apps || { echo "apps: no such a directory here.">&2; exit 3;}
  test -r @blacklist || { echo "@blacklist: no such a file here.">&2; exit 4;}
  
  cd apps
  for app in "$@"; do
    {
      rc=0
      test -f $app.apk || { echo "$appa.apk: no such a file.">&2; rc=5;}
      test -f $app.ab || { echo "$appa.ab: no such a file.">&2; rc=6;}
      test $rc -eq 0 && rm -f $app.apk $app.ab && echo $app>>@blacklist &&
        echo "$app: added to @blacklist.">&2
    } | tee ../log-addblack-$stamp
  done
  
  "$dname"/make-list.sh
  #"$dname"/make-withname.sh
)
