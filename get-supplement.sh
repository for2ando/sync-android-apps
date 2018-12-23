#!/bin/bash
pname=$(basename "$0")
usage="$pname [-l|--listonly|-h|--help]"
listonlyp=false
case "$1" in
-l|--listonly) listonlyp=true; shift;;
-*) echo "$usage"; exit 1;;
esac
test $# -ne 0 && { echo "$usage"; exit 1;}

dname=$(dirname "$0")
case "$dname" in /*);; *) dname="$(pwd)/$dname";; esac

source "$dname/adb-getdev.sh"

adev="$(adb devices -l)"
dev=$(echo "$adev" | adb-getdev model) || exit 11
stamp=$(date +%Y%m%d-%H%M%S)
log="log-get-$dev-$stamp"

(
  test "$(basename $(pwd))" = apps && cd ..
  test -d apps || { echo "apps: no such a directory here.">&2; exit 3;}
  test -r @list || { echo "@list: no such a file here.">&2; exit 4;}

  tmpfile=$(mktemp $pname.XXXXXXXX)
  trap "rm -f $tmpfile" 1 2 3 15 EXIT ERR
  get-android-apps list -3 >@orig ||
    { echo "get-android-apps -list: failed.">&2; rm -f @orig; exit 5;}
  set-complement @orig @list >"$tmpfile" ||
    { echo "set-complement: failed.">&2;  exit 6;}
  if test -r @blacklist; then
    set-complement "$tmpfile" @blacklist >@toget ||
      { echo "set-complement: failed.">&2; rm -f @toget; exit 7;}
    rm -f "$tmpfile"
  else
    mv "$tmpfile" @toget
  fi
  trap - 1 2 3 15 EXIT ERR

  $listonlyp || {
    if test $(cat @toget | wc -l) -eq 0; then
      echo "No apps to get.">&2
    else
      cd apps
      echo "$adev"
      for obj in apk ab; do
        get-android-apps $obj $(cat ../@toget)
      done
      cd ..
      mv @list "@list-$dev-$stamp"
    fi
  }
  mv @orig "@orig-$dev-$stamp"
  mv @toget "@toget-$dev-$stamp"

  "$dname"/make-list.sh ||
    { echo "make-list.sh: failed.">&2; exit 10;}
  #"$dname"/make-withname.sh
) 2>&1 | tee "$log"
