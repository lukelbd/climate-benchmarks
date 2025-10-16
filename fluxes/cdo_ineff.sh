#!/usr/bin/env bash
# Get eddy fluxes using individual CDO commands
[ -z "$1" ] && echo "Error: Must provide filename." && exit 1
flags=(-s -O "${@:2}")

cdo "${flags[@]}" -chname,u,EMF \
  -zonmean \
  -mul -sub -selvar,u "$1" -enlarge,"$1" -zonmean -selvar,u "$1" \
       -sub -selvar,v "$1" -enlarge,"$1" -zonmean -selvar,v "$1" \
  tmp1.nc
cdo "${flags[@]}" -chname,t,EHF \
  -zonmean \
  -mul -sub -selvar,t "$1" -enlarge,"$1" -zonmean -selvar,t "$1" \
       -sub -selvar,v "$1" -enlarge,"$1" -zonmean -selvar,v "$1" \
  tmp2.nc

cdo "${flags[@]}" merge tmp1.nc tmp2.nc out/cdo.nc

rm tmp1.nc tmp2.nc
