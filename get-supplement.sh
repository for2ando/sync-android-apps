#!/bin/bash
pname=$(basename "$0")
usage="$pname [-l|--listonly|-q|--quiet|-s|--silent]
$pname {-h|--help}"
listonlyp=false
quietp=false
while true; do
  case "$1" in
  -l|--listonly) listonlyp=true; shift;;
  -q|--quiet|-s|--silent) quietp=true; shift;;
  -*) echo "$usage"; exit 1;;
  *) break;;
  esac
done
test $# -ne 0 && { echo "$usage"; exit 1;}

dname=$(dirname "$0")
case "$dname" in /*);; *) dname="$(pwd)/$dname";; esac

adev="$(adb devices -l)"
dev=$(echo "$adev" | adb-parsedev model) || exit 11
$quietp || echo "device: $dev">&2
stamp=$(date +%Y%m%d-%H%M%S)
$quietp || echo "timestamp: $stamp">&2
log="log-get-$dev-$stamp"
$listonlyp && log="log-getlist-$dev-$stamp"

(
  pkglist=@list
  blacklist=@blacklist
  pkgondev=@pkgondev
  pkgtoget=@pkgtoget
  filetoget=@filetoget
  
  test "$(basename $(pwd))" = apps && cd ..
  test -r "$pkglist" -o -d apps || {
    echo "No $pkglist file nor apps directory here.
      Please chdir to one of appdir which has '$pkglist' file and 'apps' dir.">&2
    exit 3
  }

  $quietp || echo "**** compute supplements based on packages.">&2
  tPkgtoget_candidate=$(mktemp $pname.XXXXXXXX)
  trap "rm -f '$tPkgtoget_candidate'" 1 2 3 15 EXIT ERR
  $quietp || echo "make $pkgondev: pkg-list on the device.">&2
  get-android-apps list -3 >"$pkgondev" ||
    { echo "get-android-apps -list: failed.">&2; rm -f "$pkgondev"; exit 5;}
  $quietp || echo "make $pkgtoget: list of supplement pkgs.">&2
  set-complement "$pkgondev" "$pkglist" >"$tPkgtoget_candidate" ||
    { echo "set-complement: failed.">&2;  exit 6;}
  if test -r "$blacklist"; then
    $quietp || echo "apply $blacklist to $pkgtoget.">&2
    set-complement "$tPkgtoget_candidate" "$blacklist" >"$pkgtoget" ||
      { echo "set-complement: failed.">&2; rm -f "$pkgtoget"; exit 7;}
    rm -f "$tPkgtoget_candidate"
  else
    mv "$tPkgtoget_candidate" "$pkgtoget"
  fi
  trap - 1 2 3 15 EXIT ERR

  if ! $listonlyp; then
    if test $(cat "$pkgtoget" | wc -l) -eq 0; then
      echo "No packages to get.">&2
    else
      cd apps
      for obj in apk ab; do
        $quietp || echo "get $obj files of $pkgtoget pkgs.">&2
        get-android-apps $obj $(cat ../"$pkgtoget")
      done
      cd ..
      mv "$pkglist" "$pkglist-pre-$dev-$stamp"
    fi
    mv "$pkgtoget" "$pkgtoget-$dev-$stamp"
  else
    echo -------- Packages to get:
    cat "$pkgtoget"
    echo -------- end of Packages to get:
    rm "$pkgtoget"
  fi

  $quietp || echo "**** compute supplements based on files.">&2
  tPkgtochk_candidate=$(mktemp $pname.XXXXXXXX)
  tPkgtochk_last=$(mktemp $pname.XXXXXXXX)
  trap "rm -f '$tPkgtochk_candidate' '$tPkgtochk_last'" 1 2 3 15 EXIT ERR
  $quietp || echo "make list of exist pkgs both on the device and the appdir.">&2
  set-product "$pkgondev" "$pkglist" >"$tPkgtochk_candidate" ||
    { echo "set-product: failed.">&2;  exit 16;}
  if test -r "$blacklist"; then
    $quietp || echo "apply $blacklist to the list.">&2
    set-complement "$tPkgtochk_candidate" "$blacklist" >"$tPkgtochk_last" ||
      { echo "set-complement: failed.">&2; rm -f "$tPkgtochk_last"; exit 17;}
    rm -f "$tPkgtochk_candidate"
  else
    mv "$tPkgtochk_candidate" "$tPkgtochk_last"
  fi
  trap "'$tPkgtochk_last'" 1 2 3 15 EXIT ERR
  
  tFilelist=$(mktemp $pname.XXXXXXXX)
  tFileorig=$(mktemp $pname.XXXXXXXX)
  trap "rm -f '$tPkgtochk_last' '$tFilelist' '$tFileorig'" 1 2 3 15 EXIT ERR
  $quietp || echo "make $tFilelist: file-list on the appdir.">&2
  (cd apps; ls *.apk *.ab >../"$tFilelist")
  $quietp || echo "make $tFileorig: file-list on the device.">&2
  for pkg in $(cat "$tPkgtochk_last"); do
    for obj in apk ab; do
      echo "$pkg.$obj">"$tFileorig"
    done
  done
  $quietp || echo "make $filetoget: list of supplement files.">&2
  set-complement "$tFileorig" "$tFilelist" >"$filetoget" ||
    { echo "set-complement: failed.">&2;  exit 18;}
  
  if ! $listonlyp; then
    if test $(cat "$filetoget" | wc -l) -eq 0; then
      echo "No files to get.">&2
    else
      cd apps
      tFiletoget=$(mktemp $pname.XXXXXXXX)
      trap "rm -f '$tFiletoget' '$tPkgtochk_last' '$tFilelist' '$tFileorig'" 1 2 3 15 EXIT ERR
      for obj in apk ab; do
        $quietp || echo "get $obj files of $filetoget files.">&2
        fgrep ".$obj" ../"$filetoget" >"$tFiletoget"
        mapfile -t files <"$tFiletoget"
        get-android-apps $obj "${files[@]}"
      done
      rm -f "$tFiletoget"
      cd ..
      cp -p "$pkglist" "$pkglist-$dev-$stamp"
    fi
    mv "$filetoget" "$filetoget-$dev-$stamp"
  else
    echo -------- Files to get:
    cat "$filetoget"
    echo -------- end of Files to get:
    rm "$filetoget"
  fi
  rm -f "$tPkgtochk_last" "$tFilelist" "$tFileorig"
  trap - 1 2 3 15 EXIT ERR

  if $listonlyp; then
    rm "$pkgondev"
  else
    mv "$pkgondev" "$pkgondev-$dev-$stamp"
    "$dname"/make-list.sh ||
      { echo "make-list.sh: failed.">&2; exit 32;}
    #"$dname"/make-withname.sh
  fi
) 2>&1 | tee "$log"
