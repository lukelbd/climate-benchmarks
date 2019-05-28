#!/usr/bin/env bash
#------------------------------------------------------------------------------#
# Utilities used for all benchmarks
# NOTE: Sourcing this with no arguments is just as if you copied and pasted these
# lines in the original script, *unless* you also pass arguments in the source
# command and all the $@ are overwritten, but weirdly $0 still refers to the
# original script invoking source no matter what.
#------------------------------------------------------------------------------#
# Initial stuff
#------------------------------------------------------------------------------#
# Global variables
shopt -s nullglob
cwd="$(pwd)"
name="$0"
name="${name%.sh}"
dir="$1" # directories where data is stored
dir="$cwd/${dir##*/}"
header="| nlat | size | name | real (s) | user (s) | sys (s) |\n| --- | --- | --- | --- | --- | --- |\n"
output="$cwd/logs/"$(echo "$name" | tr A-Z a-z)"_${dir}_${HOSTNAME%%.*}.log" # store here
[ "$#" -ne 1 ] && echo "Error: Usage is ./Benchmark <dir> where <dir> is the location of NetCDFs for globbing/testing." && exit 1

# Input data
! [ -d "$dir" ] && echo "Error: Directory \"$dir\" not found." && exit 1
datas=("$dir"/data*.nc)
[ ${#datas[@]} -eq 0 ] && echo "Error: Data directory \"$dir\" is empty." && exit 1
# Output directory
! [ -d "$name" ] && echo "Error: Directory \"$name\" not found." && exit 1
! [ -d "$name/out" ] && mkdir "$name/out" # in same folder as project
cd "$name" # into directory with all the files

# Remove old stuff
rm "$output" 2>/dev/null
rm "$dir"/*-*.nc 2>/dev/null # remove parallel-produced files

#------------------------------------------------------------------------------#
# Functions
#------------------------------------------------------------------------------#
# The 'disk usage' often very different from the 'apparent size' ls -l.
# Former depends on internals, and on Cheyenne, ends up way bigger. See:
# * https://unix.stackexchange.com/a/106278/112647
# * https://serverfault.com/a/290091/427991
[[ "$OSTYPE" == "darwin"* ]] && _macos=true || _macos=false
if $_macos && ! type gdu &>/dev/null; then
  echo "Warning: gdu unavailable. Recommend installing it with brew install coreutils."
  du='du -h'
elif $_macos; then
  du='gdu --apparent-size -h'
else
  du='du --apparent-size -h'
fi

# Header
# NOTE: Critical that 'size' and 'nlat' are global variables here
header() {
  size=$(command $du $1 | xargs | cut -d' ' -f1)
  nlat=${1#*N}
  nlat=$(printf '%.0f' ${nlat%T*})
  echo && echo "Dataset: $1 ($size)"
  echo "Logfile: $output"
  printf "\n$header" >>$output # add header for each new file
}

# Convert time command output to raw seconds
seconds() {
  t=$1
  m=${t%m*}
  s=${t#*m}
  s=${s%.*}
  d=${t#*.} # decimal
  echo $((m*60 + s)).${d%s} # converts e.g. 1m35.23s to 85.23s
}

# Magic python wrapper that allows modules with same name as files
python() {
  command python -c "
import sys
sys.path.remove('')
$(cat "$1")
" "${@:2}"
}

# Run time command
bench() {
  # NOTE: Discard stderr, beause don't care about warnings; for debugging
  # you may need to play with this!
  # NOTE: Preserve stdout, because have Matlab print stuff after startup
  # is complete so we can get better estimate
  # res=$( (time "${@:2}") 2>&1 )
  local real user sys
  [ -z "$debug" ] && debug=false
  if $debug; then
    # Debug mode
    # res=$("${@:2}" 2>&1)
    echo "Debug mode: ${@:2}"
    echo "Result:"
    "${@:2}"
    echo "Exit: $?"
  else
    # Normal mode, time command
    res=$( (time "${@:2}" 2>/dev/null) 2>&1 )
    info="$(echo "${res%real*}" | xargs | tr -s ' ')"
    time="real ${res##*real}"
    array=($time)
    # Get result, tabulate it, add it to markdown file
    if [ -n "$info" ]; then # try to find the number, in seconds
      info="${info##*mathworks.com.}" # only way to remove startup....
      info="$(echo "$info" | sed 's/[^.0-9]//g')"
      real="$(seconds 0m${info%.1}s)" # weirdly, get extra '1' at end of string that is totally invisible before passing through sed
      printf "| $nlat | $size | $1 | **$real** | | |\n" >>$output
    else
      real=$(seconds ${array[1]})
      user=$(seconds ${array[3]})
      sys=$(seconds ${array[5]})
      printf "| $nlat | $size | $1 | **$real** | $user | $sys |\n" >>$output
    fi
    echo $1
    echo ${real}s
  fi
}

