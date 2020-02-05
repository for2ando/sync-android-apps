logfilename=log
pkglist=@list
blacklist=@blacklist
desclist=@description
pkgondev_stem=@pkgondev
pkgtoget_stem=@pkgtoget
filetoget_stem=@filetoget
pkgtoput_stem=@pkgtoput
filetoput_stem=@filetoput
appsdir=apps

copyworktolog() {
  test -d "$logdir" || mkdir -p "$logdir" || echo "$logdir: cannot make log directory">&2
  cp -p "$workdir"/* "$logdir"/
}
