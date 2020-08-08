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
cwd=$(pwd)
name=$0
name=$(echo "${name%.sh}" | tr '[:upper:]' '[:lower:]')
dir=$1 # directories where data is stored
dir=$cwd/${dir##*/}
initline="| nlat | size | name | real (s) | user (s) | sys (s) |\n| --- | --- | --- | --- | --- | --- |\n"
output=$cwd/results/${name}_${dir##*/}_${HOSTNAME%%.*}.log  # store here
if [ "$#" -ne 1 ] || [[ " $* " =~ " -h " ]] || [[ " $* " =~ " --help " ]]; then
  echo "Usage: ./${0##*/} DIR where DIR is the location of NetCDFs for globbing/testing. Scripts for each language must be located in the \"$name\" folder."
  exit 1
fi

# Input data
! [ -d "$dir" ] && echo "Error: Data directory \"$dir\" not found." && exit 1
datas=("$dir"/data*.nc)
[ ${#datas[@]} -eq 0 ] && echo "Error: Data directory \"$dir\" is empty." && exit 1

# Output directory
! [ -d "$name" ] && echo "Error: Benchmarks script directory \"$name\" not found." && exit 1
! [ -d "$name/out" ] && mkdir "$name/out" # in same folder as project
cd "$name" || { echo "Failed to cd to ${name}."; exit 1; } # into directory with all the files

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
init() {
  size=$(command $du $1 | xargs | cut -d' ' -f1)
  nlat=${1#*N}
  nlat=$(printf '%.0f' ${nlat%T*})
  echo && echo "Dataset: $1 ($size)"
  echo "Logfile: $output"
  printf "\n%s" "$initline" >> $output
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
  local real user sys
  [ -z "$debug" ] && debug=false # global debug command
  if $debug; then
    # Debug mode
    # res=$("${@:2}" 2>&1)
    echo "Debug mode: ${*:2}"
    echo "Result:"
    "${@:2}"
    echo "Exit: $?"

  else
    # Normal mode, time command
    res=$( (time "${@:2}" 2>/dev/null) 2>&1 )
    info=$(echo "${res%real*}" | xargs | tr -s ' ')
    time="real ${res##*real}"
    array=($time)

    # Get result, tabulate it, add it to markdown file
    if [ -n "$info" ]; then # try to find the number, in seconds
      info=${info##*mathworks.com.}  # only way to remove startup....
      info=${info//[^.0-9]/}  # extract time info
      real="$(seconds 0m${info%.1}s)" # get extra '1' at end of string that is totally invisible before passing through sed
      printf \
        "| %s | %s | %s | **%s** | | |\n" \
        "$nlat" "$size" "$1" "$real" \
        >> "$output"
    else
      real=$(seconds ${array[1]})
      user=$(seconds ${array[3]})
      sys=$(seconds ${array[5]})
      printf \
        "| %s | %s | %s | **%s** | %s | %s |\n" \
        "$nlat" "$size" "$1" "$real" "$user" "$sys" \
        >> "$output"
    fi
    echo $1
    echo ${real}s
  fi
}

