#!/usr/bin/env bash
# Take slice with CDO seltimestep
# NOTE: CDO uses 1-based endpoint-inclusive indexing
cdo -O -s "${@:3}" -seltimestep,1/$2 "$1" out/slice_cdo.nc
