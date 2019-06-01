#!/bin/bash

adb-parsedev() {
  pname=${FUNCNAME[0]}
  usage="$pname [Keyword]
  $pname {-h|--help}
    keyword:
      1
      2
      serial
      state
      product
      model
      device
      transport_id
      ... etc."
  case "$1" in
  -*) echo "$usage"; exit 1;;
  esac
  keyword="$1"
  case "$keyword" in
  '') keyword="model";;
  serial) keyword="1";;
  state) keyword="2";;
  esac
  
  if tty -s; then
    adb devices -l
  else
    cat -
  fi | awk '
    $2=="device" || $2=="unauthorized" || $2=="offline" || $2=="bootloader"{
      n = n+1; if (n>=2) {
        print "Two or more remote adb devices connected.">"/dev/stderr"
        exit 3
      }
      if ('"$keyword"' ~ /^[0-9]+$/) { print $'"$keyword"'; exit }
      for (i=1; i<=NF; i++) {
        if (match($i, /^'"$keyword"':(.*)$/, arr) > 0) {
          print arr[1]; exit
        }
      }
    }
    END { if (n==0) {
      print "No remote adb device connected.">"/dev/stderr"
      exit 4
    }}
  '
}

test "$(caller)" = "0 NULL" && {
  pname=$(basename "$0")
  case "$pname" in
  adb-getdev.sh)
    adb-parsedev "$@"
    exit $?;;
  esac
}
