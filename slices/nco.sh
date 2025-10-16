#!/usr/bin/env bash
# Take slice with NCO hyperslab
# NOTE: ncks uses 0-based endpoint-inclusive indexing.
ncks -O -h --no-abc -d "${@:3}" time,0,$(($2 - 1)) "$1" out/slice_nco.nc
