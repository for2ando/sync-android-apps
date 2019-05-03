#!/bin/bash
pname=$(basename "$0")
usage="$pname [-h|--help]"
case "$1" in
-*) echo "$usage"; exit 1;;
esac
test $# -ne 0 && { echo "$usage"; exit 1;}

dname=$(dirname "$0")
case "$dname" in /*);; *) dname="$(pwd)/$dname";; esac

source "$dname/parse-adbdev.sh"

test -z "$APPDIR" && { echo "Please set envvar: APPDIR.">&2; exit 2;}
test -d "$APPDIR"/apps ||
  { echo "$APPDIR/apps: no such a directory.">&2; exit 3;}
test -r "$APPDIR"/@list ||
  { echo "$APPDIR/@list: no such a file.">&2; exit 4;}

adev="$(adb devices -l)"
dev=$(echo "$adev" | parse-adbdev model) || exit 11
stamp=$(date +%Y%m%d-%H%M%S)
log="log-put-$dev-$stamp"

(
  echo "APPDIR=$APPDIR"

  get-android-apps list -3 >@orig
  set-complement "$APPDIR"/@list @orig >@toput

  echo "$adev"
  for obj in apk ab; do
    put-android-apps $obj $(sed "s|^|$APPDIR/apps/|;s|$|.$obj|" @toput)
  done
  mv @orig "@orig-$dev-$stamp"
  mv @toput "@toput-$dev-$stamp"
) 2>&1 | tee "$log"
