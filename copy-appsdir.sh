#!/bin/sh
pname=$(basename "$0")
usage="$pname  [-h|--help] SourceAppDir NewAppDir"
case "$1" in -*) echo "$usage"; exit 1;; esac
test $# -ne 2 && { echo "$usage"; exit 1;}

dname=$(dirname "$0")
case "$dname" in /*);; *) dname="$(pwd)/$dname";; esac

appdir="$1"
newappdir="$2"

test -d "$appdir" ||
  { echo "$appdir: directory not exist.">&2; exit 2;}
mkdir -p "$newappdir/apps" ||
  { echo "$newappdir/apps: mkdir failed.">&2; exit 3;}
for obj in apk ab; do
  ln "$appdir"/apps/*.$obj "$newappdir"/apps
done

(
  cd "$newappdir"
  "$dname"/make-list.sh
  #"$dname"/make-withname.sh
)
cp "$appdir"/@blacklist "$newappdir"/
