#!/usr/bin/env bash
# Use NCAP2 to get eddy fluxes
# See documentation; the -v flag says to only output user-defined variables
# Great examples from documentation are below
# Example 1:
#   n1=pow(2,3.0f)    // n1 type float
#   n2=atan2(2,3.0)   // n2 type double
#   n3=1/(three_dmn_var_dbl.cos().pow(2))-tan(three_dmn_var_dbl)^2; // n3 type double
# Example 2:
#   *temp[$time,$lat,$lon]=10.0;     // Cast
#   *temp_avg=temp.avg($time);      // Regular assign
#   temp.ram_delete();              // Delete RAM variable
#   temp_avg.ram_write();           // Write Variable to output
#
#   // Create and increment a RAM variable from "one" in Input
#   *one++;
#   // Create RAM variables from the variables three and four in Input.
#   // Multiply three by 10 and add it to four.
#   *four+=*three*=10; // three=30, four=34
[ -z "$1" ] && echo "Error: Must provide filename." && exit 1
ncap2 -O -v -s "${@:2}" '
  emf = ((u - u.avg($lon)) * (v - v.avg($lon))).avg($lon);
  ehf = ((t - t.avg($lon)) * (v - v.avg($lon))).avg($lon);
  ' "$1" out/nco.nc
