#!/bin/sh
pname=$(basename "$0")
usage="$pname  [-q|-s] SourceAppDir NewAppDir
$pname  {-h|--help}"
quietp=false
while true; do
  case "$1" in
  -q|--quiet)
  -s|--silent) quietp=true; shift;;
  -*) echo "$usage"; exit 1;;
  *) break;;
  esac
done
test $# -ne 2 && { echo "$usage"; exit 1;}

dname=$(dirname "$0")
case "$dname" in /*);; *) dname="$(pwd)/$dname";; esac

appdir="$1"
newappdir="$2"

test -d "$appdir" ||
  { echo "$appdir: source directory not exist.">&2; exit 2;}
test -d "$newappdir" &&
  { echo "$newappdir: the destination directory exists. Remove it and retry.">&2; exit 2;}
$quietp || echo "make $newappdir.">&2
mkdir -p "$newappdir/apps" ||
  { echo "$newappdir/apps: mkdir failed.">&2; exit 3;}
for obj in apk ab; do
  $quietp || echo "make hardlinks for $obj.">&2
  ln "$appdir"/apps/*.$obj "$newappdir"/apps
done

(
  cd "$newappdir"
  $quietp || echo "make @list.">&2
  "$dname"/make-list.sh
  #"$dname"/make-withname.sh
)
cp "$appdir"/@blacklist "$newappdir"/
