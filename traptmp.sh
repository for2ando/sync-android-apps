#!/bin/bash
#usage:
# source traptmp.sh
# traptmp ...
debug=false

declare -x TRAPTMP_ACTIVEP  # Boolean
test -z "$TRAPTMP_ACTIVEP" && TRAPTMP_ACTIVEP=false
declare -x -A TRAPTMP_FILES TRAPTMP_SIGNALS TRAMPTMP_BACKUPS
declare -x -A TRAPTMP_SIGNAL_NUMBERS TRAPTMP_SIGNAL_LITERALS

traptmp() {
  local pname=${FUNCNAME[0]}
  local usage_add="  $pname add Filename [...]
    Add a Filename to the list of filenames.
    If already exist in the list, do nothing"
  local usage_rm="  $pname rm Filename [...]
    Remove a Filename from the list of filenames.
    If not exist in the list, do nothing."
  local usage_begin="  $pname begin Signal [...]
    Initialize the traptmp system, by doing followings:
    * Set the list of signals by Signal(s)."
  local usage_end="  $pname end
    Terminate the traptmp system, by doing followings:
    * Clear trap command string for each signals.
    * Clear the list of signals."
  local usage_settraps="  $pname settraps
    Set trap command strings for each signals, consist from the backup command
    string, and a rm command for filenames in the list."
  local usage_files="  $pname files
    Print the current list of filenames to stdout."
  local usage_signals="  $pname {signals|signal-literals}
    Print the current list of signals."
  local usage_backups="  $pname backups
    Print the current list of trap-command backups to stdout."
  local usage_traps="  $pname traps
    Print the current list of traps to be set to stdout."
  local usage_help="  $pname {-h|--help} [SubCommand]
    Print SubCommand's help."
  local usage="Synopsis:
  $pname {add|rm} [Filename ...]
  $pname begin [Signal ...]
  $pname end
  $pname settraps
  $pname {files|signals|signal-literals|backups|traps}
  $pname {-h|--help} [SubCommand]
Main Features:
  * Manages a list of file to remove when some listed signal send,
  * Starts & terminates this removing action.
  * Manages a list of signals to be send.
Sub Commands:
  Please invoke $pname --help SubCommand."
  
  _traptmp_signal_tables_exist() {
    local -i nsig=$(trap -l | tail -1 | sed 's/^.*[^0-9]\([0-9][ 0-9]*\)[^0-9]*$/\1/')
    test ${#TRAPTMP_SIGNAL_NUMBERS[@]} -eq $nsig -a ${#TRAPTMP_SIGNAL_LITERALS[@]} -eq $nsig
  }
  
  _traptmp_make_signal_tables() {
    ## make a table of signal number <--> signal name
    TRAPTMP_SIGNAL_NUMBERS=()
    TRAPTMP_SIGNAL_LITERALS=()
    local -a ary1 ary2=()
    local -i idx
    local queue=$(mktemp -u)
    mkfifo $queue
    trap -l >$queue &
    while IFS='	 )' read -r -a ary1; do
      idx=1
      while [ $idx -lt ${#ary1[@]} ]; do
        TRAPTMP_SIGNAL_LITERALS[${ary1[$((idx-1))]}]=${ary1[$idx]}
        TRAPTMP_SIGNAL_NUMBERS[${ary1[$idx]}]=${ary1[$((idx-1))]}
        idx+=2
      done
    done <$queue
    rm $queue
  }
  
  _traptmp_set_traps() {
    local -A files_quoted
    for file in "${!TRAPTMP_FILES[@]}"; do
      files_quoted["'$file'"]=''
    done
    local backup
    for signal in "${!TRAPTMP_SIGNALS[@]}"; do
      backup=$(eval echo "${TRAPTMP_BACKUPS[$signal]}")
      test "$backup" != "" && backup+=;
      trap ${backup}"rm -f ${!files_quoted[*]}" $signal
    done
  }
  
  _traptmp_get_trap_cmd() {
    local signal=${TRAPTMP_SIGNAL_LITERALS["$1"]}
    test "$signal" == "" &&
      signal="$1"
    trap | awk '$4 == "'"$signal"'" { print $3; }'
  }
  
  _traptmp_sort_args() {
    echo "$@" | sed 's/ /\n/g' | sort
  }
  
  _traptmp_signal_tables_exist || _traptmp_make_signal_tables
  
  while true; do
    case "$1" in
    -h|--help)
      case "$2" in
      add|rm|begin|end|settraps|files|signals|backups|traps|help)
        eval echo \""\$usage_$2"\"; return 0;;
      *)
        echo "$usage_help"; return 0;;
      esac
      ;;
    -*) echo "$usage"; return 1;;
    *) break;;
    esac
  done
  test $# -eq 0 && { echo "$usage"; return 1; }
  
  subcmd="$1"
  case "$subcmd" in
  add)
    test $# -le 1 && { echo "$usage_add"; return 1; }
    shift
    for file in "$@"; do
      TRAPTMP_FILES["$file"]=''
    done
    $TRAPTMP_ACTIVEP && _traptmp_set_traps
    ;;
  rm)
    test $# -le 1 && { echo "$usage_rm"; return 1; }
    shift
    for file in "$@"; do
      unset -v TRAPTMP_FILES["$file"]
    done
    $TRAPTMP_ACTIVEP && _traptmp_set_traps
    ;;
  begin)
    test $# -le 1 && { echo "$usage_begin"; return 1; }
    shift
    local num
    TRAPTMP_SIGNALS=()
    for signal in "$@"; do
      num=${TRAPTMP_SIGNAL_NUMBERS[$signal]}
      if [ "$num" != "" ]; then signal=$num; fi
      test "$TRAPTMP_SIGNAL_LITERALS[$signal]" == "" &&
        { echo "$signal: invalid signal.">&2; return 2; }
      TRAPTMP_SIGNALS[$signal]=''
      test "${TRAPTMP_BACKUPS[$signal]}" == "" && {
        cmd="$(_traptmp_get_trap_cmd $signal)"
        test "$cmd" != "" &&
          TRAPTMP_BACKUPS[$signal]="$cmd"
      }
    done
    _traptmp_set_traps
    TRAPTMP_ACTIVEP=true
    ;;
  end)
    test $# -ne 1 && { echo "$usage_end"; return 1; }
    $TRAPTMP_ACTIVEP || return 0
    TRAPTMP_ACTIVEP=false
    local backup_quoted backup
    for signal in "${!TRAPTMP_SIGNALS[@]}"; do
      backup_quoted="${TRAPTMP_BACKUPS[$signal]}"
      backup=$(eval echo "$backup_quoted")
      if [ "$backup_quoted" == "" ]; then
        trap $signal
      else
        trap "$backup" $signal
      fi
    done
    TRAPTMP_SIGNALS=()
    TRAPTMP_BACKUPS=()
    ;;
  settraps)
    test $# -ne 1 && { echo "$usage_settraps"; return 1; }
    _traptmp_set_traps
    ;;
  files)
    test $# -ne 1 && { echo "$usage_files"; return 1; }
    echo $(_traptmp_sort_args "${!TRAPTMP_FILES[@]}")
    ;;
  signals)
    test $# -ne 1 && { echo "$usage_signals"; return 1; }
    echo $(_traptmp_sort_args "${!TRAPTMP_SIGNALS[@]}")
    ;;
  signal-literals)
    test $# -ne 1 && { echo "$usage_signals"; return 1; }
    firstp=true
    for signal in $(_traptmp_sort_args "${!TRAPTMP_SIGNALS[@]}"); do
      if $firstp; then firstp=false; else echo -n ' '; fi
      echo -n ${TRAPTMP_SIGNAL_LITERALS[$signal]}
    done
    echo
    ;;
  backups)
    test $# -ne 1 && { echo "$usage_backups"; return 1; }
    for signal in $(_traptmp_sort_args "${!TRAPTMP_BACKUPS[@]}"); do
      echo "$signal = ${TRAPTMP_BACKUPS[$signal]}"
    done
    ;;
  traps)
    test $# -ne 1 && { echo "$usage_traps"; return 1; }
    local regex='('
    local firstp=true
    for signal in ${!TRAPTMP_SIGNALS[@]}; do
      if $firstp; then firstp=false; else regex="$regex|"; fi
      regex="$regex${TRAPTMP_SIGNAL_LITERALS[$signal]}"
    done
    regex="$regex)\$"
    trap | egrep "$regex"
    ;;
  help) echo "$usage_help"; return 1;;
  *) echo "$usage"; return 1;;
  esac
}

if $debug; then
  test "$(caller)" = "0 NULL" && {
    pname=$(basename "$0")
    case "$pname" in
    traptmp.sh)
      traptmp "$@"
      exit $?;;
    esac
  }
fi