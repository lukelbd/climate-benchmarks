## Benchmarks for data anslysis stuff
Use this repo to benchmark data analysis techniques across CDO, NCL, NCO, python, and julia. Matlab and IDL are the past so I'm not bothering with them ;)

### Interpolation timing for 100-day files at synoptic timesteps

* Time for NCL interpolation script with **automatic iteration**: ***70s exactly***
* Time for interpolation script with **explicit iteration through variables**: ***71s almost identical***
* Time for interpolation with CDO: ***30s pre-processing*** (probably due to inefficiency of overwriting original ncfile with file that dleetes coordinates), ***94s for setting things up*** (because we have to write surface geopotential to same massive file, instead of declaring as separate variable in NCL), and ***122s actual interpolation*** (with bunch of warnings) so ***216 total***
 
### Flux terms
* Loading, evaluating then saving to new file with **NCL**: ***20s***, probably because have to save these huge variables into memory
* As above, but **without saving the conformed variables**: ***21s, almost identical***
* Evaluating and saving with **CDO**: ***6s***, so try to use CDO
