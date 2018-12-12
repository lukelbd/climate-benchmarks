# Benchmarks for climate data analysis
Use this repo to benchmark data analysis techniques across CDO, NCL, NCO, python, and julia. Matlab and IDL are the past so I'm not bothering with them ;)

## A Note on NetCDF3 vs. NetCDF4
There were two major performance differences observed between the NetCDF3 and NetCDF4 versions of the sample data:

* It turned out that, **in general**, CDO with NetCDF3 (on a Macbook) responded **less favorably** to thread-safe disk IO locking (the `-L` flag) -- it tended to speed things up for smaller datasets (over-optimization?) then slow things down for larger datasets, but **more-so** for NetCDF3.
* We also found that **non-dask** python datasets (i.e. XArray datasets loaded with `chunks=None`) were **somewhat slower** for NetCDF3 than NetCDF4. The effect was **more pronounced** with larger datasets. When chunking was used, the speed improvements for NetCDF4 were marginal, even toward 2GB datasets (around **7s** vs **9s**).

Since most large general circulation models produce NetCDF3 files, only the results for these datasets were shown. But anyway, as explained above, the differences weren't that huge.

## Interpolation tests
Setup is 4 times daily 100-day T42L40 resolution files, from dry dynamical core model.

* Time for NCL interpolation script with **automatic iteration**: ***70s exactly***
* Time for interpolation script with **explicit iteration through variables**: ***71s almost identical***
* Time for interpolation with CDO: ***30s pre-processing*** (probably due to inefficiency of overwriting original ncfile with file that dleetes coordinates), ***94s for setting things up*** (because we have to write surface geopotential to same massive file, instead of declaring as separate variable in NCL), and ***122s actual interpolation*** (with bunch of warnings) so ***216 total***
    
## Eddy flux term tests
### Macbook: 1 level, 1000 timesteps
Data used was generated with the `datagen` script via the line:
```
for reso in 5 2 1 0.5; do ./datagen $reso; done
```

Results are summarized in the below table. Turns out **NCL is much faster than all other tools**, to my surprise. Dask chunking didn't work well for small files. Note that using the NCL feature `setfileoption("nc", "Format", "LargeFile")` made absolutely **neglibile** difference in final wall-clock time, to my surprise. Also note there are no options to improve large file handling, recommendation is to split up by level or time; see [this NCL talk post](https://www.ncl.ucar.edu/Support/talk_archives/2011/2636.html) and [this stackoverflow post](https://stackoverflow.com/questions/44474507/read-large-netcdf-data-by-ncl).

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 18 | 7.4M (3) | XArray + no dask | **2.544** | 1.216 | 0.679 |
| 18 | 7.4M (3) | XArray + 1000 t chunks | **1.110** | 1.105 | 1.259 |
| 18 | 7.4M (3) | XArray + 100 t chunks | **1.107** | 0.904 | 0.174 |
| 18 | 7.4M (3) | XArray + 20 t chunks | **1.303** | 1.062 | 0.227 |
| 18 | 7.4M (3) | Julia | **5.777** | 5.732 | 0.283 |
| 18 | 7.4M (3) | CDO | **6.310** | 1.001 | 6.335 |
| 18 | 7.4M (3) | CDO + serial IO | **2.962** | 0.677 | 3.154 |
| 18 | 7.4M (3) | NCL | **0.634** | 0.319 | 0.102 |
| 18 | 7.4M (3) | NCO | **0.264** | 0.194 | 0.036 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 36 | 30M (3) | XArray + no dask | **1.804** | 1.634 | 0.362 |
| 36 | 30M (3) | XArray + 1000 t chunks | **1.089** | 1.184 | 1.037 |
| 36 | 30M (3) | XArray + 100 t chunks | **1.084** | 0.940 | 0.176 |
| 36 | 30M (3) | XArray + 20 t chunks | **1.307** | 1.113 | 0.239 |
| 36 | 30M (3) | Julia | **6.650** | 5.985 | 0.392 |
| 36 | 30M (3) | CDO | **6.239** | 1.108 | 6.365 |
| 36 | 30M (3) | CDO + serial IO | **2.712** | 0.755 | 2.827 |
| 36 | 30M (3) | NCL | **0.931** | 0.779 | 0.130 |
| 36 | 30M (3) | NCO | **0.852** | 0.756 | 0.082 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 60 | 82M (3) | XArray + no dask | **2.033** | 1.909 | 0.488 |
| 60 | 82M (3) | XArray + 1000 t chunks | **1.312** | 1.624 | 1.543 |
| 60 | 82M (3) | XArray + 100 t chunks | **1.413** | 2.384 | 2.176 |
| 60 | 82M (3) | XArray + 20 t chunks | **1.319** | 1.231 | 0.254 |
| 60 | 82M (3) | Julia | **7.830** | 6.556 | 0.544 |
| 60 | 82M (3) | CDO | **6.043** | 1.373 | 6.239 |
| 60 | 82M (3) | CDO + serial IO | **2.619** | 0.994 | 2.568 |
| 60 | 82M (3) | NCL | **2.188** | 1.873 | 0.284 |
| 60 | 82M (3) | NCO | **2.340** | 2.099 | 0.220 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 90 | 185M (3) | XArray + no dask | **4.088** | 2.024 | 0.946 |
| 90 | 185M (3) | XArray + 1000 t chunks | **2.568** | 2.691 | 1.589 |
| 90 | 185M (3) | XArray + 100 t chunks | **1.857** | 2.216 | 3.628 |
| 90 | 185M (3) | XArray + 20 t chunks | **1.559** | 1.637 | 0.308 |
| 90 | 185M (3) | Julia | **10.510** | 7.720 | 0.849 |
| 90 | 185M (3) | CDO | **7.220** | 2.327 | 7.343 |
| 90 | 185M (3) | CDO + serial IO | **4.488** | 2.257 | 3.678 |
| 90 | 185M (3) | NCL | **5.383** | 4.368 | 0.733 |
| 90 | 185M (3) | NCO | **5.376** | 4.675 | 0.526 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 120 | 330M (3) | XArray + no dask | **2.995** | 2.618 | 1.045 |
| 120 | 330M (3) | XArray + 1000 t chunks | **2.157** | 4.810 | 1.903 |
| 120 | 330M (3) | XArray + 100 t chunks | **2.159** | 2.944 | 5.407 |
| 120 | 330M (3) | XArray + 20 t chunks | **2.237** | 2.991 | 5.775 |
| 120 | 330M (3) | Julia | **12.211** | 8.272 | 1.046 |
| 120 | 330M (3) | CDO | **7.907** | 3.790 | 8.209 |
| 120 | 330M (3) | CDO + serial IO | **5.228** | 3.332 | 3.857 |
| 120 | 330M (3) | NCL | **9.583** | 8.049 | 1.297 |
| 120 | 330M (3) | NCO | **9.200** | 8.290 | 0.870 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 180 | 742M (3) | XArray + no dask | **4.914** | 3.328 | 1.809 |
| 180 | 742M (3) | XArray + 1000 t chunks | **3.399** | 6.015 | 3.833 |
| 180 | 742M (3) | XArray + 100 t chunks | **3.109** | 5.884 | 6.267 |
| 180 | 742M (3) | XArray + 20 t chunks | **3.591** | 5.726 | 7.023 |
| 180 | 742M (3) | Julia | **17.755** | 11.294 | 2.012 |
| 180 | 742M (3) | CDO | **7.725** | 6.317 | 6.374 |
| 180 | 742M (3) | CDO + serial IO | **7.321** | 5.714 | 3.501 |
| 180 | 742M (3) | NCL | **18.497** | 15.741 | 2.351 |
| 180 | 742M (3) | NCO | **21.434** | 18.521 | 2.797 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 240 | 1.3G (3) | XArray + no dask | **6.412** | 3.851 | 2.281 |
| 240 | 1.3G (3) | XArray + 1000 t chunks | **5.075** | 7.799 | 5.497 |
| 240 | 1.3G (3) | XArray + 100 t chunks | **4.405** | 8.505 | 11.017 |
| 240 | 1.3G (3) | XArray + 20 t chunks | **4.309** | 8.501 | 13.294 |
| 240 | 1.3G (3) | Julia | **27.056** | 15.799 | 3.570 |
| 240 | 1.3G (3) | CDO | **6.023** | 9.904 | 5.008 |
| 240 | 1.3G (3) | CDO + serial IO | **7.731** | 7.938 | 2.989 |
| 240 | 1.3G (3) | NCL | **34.025** | 27.370 | 4.687 |
| 240 | 1.3G (3) | NCO | **38.321** | 32.955 | 4.922 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 360 | 2.9G (3) | XArray + no dask | **20.444** | 7.523 | 7.504 |
| 360 | 2.9G (3) | XArray + 1000 t chunks | **18.417** | 13.535 | 11.109 |
| 360 | 2.9G (3) | XArray + 100 t chunks | **8.398** | 19.395 | 18.011 |
| 360 | 2.9G (3) | XArray + 20 t chunks | **8.481** | 18.571 | 27.829 |
| 360 | 2.9G (3) | Julia | **47.591** | 28.088 | 8.230 |
| 360 | 2.9G (3) | CDO | **8.505** | 22.760 | 4.508 |
| 360 | 2.9G (3) | CDO + serial IO | **14.390** | 17.319 | 3.711 |
| 360 | 2.9G (3) | NCL | **75.075** | 60.429 | 12.742 |
| 360 | 2.9G (3) | NCO | **89.726** | 73.230 | 11.331 |

### Macbook: 60 level, 200 timesteps
This time data was generated using
```
for reso in 10 7.5 5 3 2 1.5; do ./datagen $reso; done
```
since individual "timesteps" contain much more data.

These results were surprising: turned out **more pressure levels *significantly* slowed** the CDO operations. And I have no idea why. Maybe has to do with the particular operation used, e.g. the `-enlarge` calculated independently for each pressure level?

**Note**: Suspect the CDO issues had something to do with my compilation. These will be updated.

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 9 | 22M (3) | XArray + no dask | **1.850** | 1.637 | 0.381 |
| 9 | 22M (3) | XArray + 200 t chunks | **1.160** | 1.180 | 0.851 |
| 9 | 22M (3) | XArray + 20 t chunks | **1.094** | 0.969 | 0.184 |
| 9 | 22M (3) | XArray + 2 t chunks | **1.594** | 1.394 | 0.334 |
| 9 | 22M (3) | CDO | **62.858** | 9.241 | 62.275 |
| 9 | 22M (3) | CDO + serial IO | **34.465** | 7.605 | 34.887 |
| 9 | 22M (3) | NCL | **1.348** | 0.975 | 0.184 |
| 9 | 22M (3) | NCO | **0.933** | 0.813 | 0.079 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 18 | 89M (3) | XArray + no dask | **2.675** | 2.359 | 0.656 |
| 18 | 89M (3) | XArray + 200 t chunks | **1.840** | 2.108 | 1.420 |
| 18 | 89M (3) | XArray + 20 t chunks | **1.917** | 2.060 | 2.546 |
| 18 | 89M (3) | XArray + 2 t chunks | **2.604** | 2.483 | 0.564 |
| 18 | 89M (3) | CDO | **93.317** | 15.351 | 90.746 |
| 18 | 89M (3) | CDO + serial IO | **36.421** | 8.844 | 37.682 |
| 18 | 89M (3) | NCL | **4.405** | 3.676 | 0.531 |
| 18 | 89M (3) | NCO | **3.663** | 3.283 | 0.330 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 24 | 158M (3) | XArray + no dask | **3.684** | 2.489 | 0.931 |
| 24 | 158M (3) | XArray + 200 t chunks | **1.941** | 3.718 | 1.388 |
| 24 | 158M (3) | XArray + 20 t chunks | **1.840** | 2.245 | 3.066 |
| 24 | 158M (3) | XArray + 2 t chunks | **2.397** | 2.437 | 0.518 |
| 24 | 158M (3) | CDO | **93.303** | 15.951 | 91.763 |
| 24 | 158M (3) | CDO + serial IO | **36.076** | 9.517 | 37.937 |
| 24 | 158M (3) | NCL | **5.310** | 4.495 | 0.570 |
| 24 | 158M (3) | NCO | **5.533** | 4.980 | 0.511 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 36 | 356M (3) | XArray + no dask | **5.386** | 2.856 | 1.476 |
| 36 | 356M (3) | XArray + 200 t chunks | **2.900** | 4.700 | 2.781 |
| 36 | 356M (3) | XArray + 20 t chunks | **2.607** | 3.707 | 6.256 |
| 36 | 356M (3) | XArray + 2 t chunks | **3.598** | 4.316 | 0.807 |
| 36 | 356M (3) | CDO | **86.120** | 16.536 | 86.411 |
| 36 | 356M (3) | CDO + serial IO | **36.543** | 12.035 | 36.878 |
| 36 | 356M (3) | NCL | **12.972** | 11.161 | 1.460 |
| 36 | 356M (3) | NCO | **13.601** | 12.286 | 1.211 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 60 | 989M (3) | XArray + no dask | **9.519** | 4.327 | 2.819 |
| 60 | 989M (3) | XArray + 200 t chunks | **6.384** | 9.653 | 5.718 |
| 60 | 989M (3) | XArray + 20 t chunks | **6.488** | 12.156 | 12.298 |
| 60 | 989M (3) | XArray + 2 t chunks | **7.349** | 13.976 | 19.194 |
| 60 | 989M (3) | CDO | **79.081** | 20.075 | 80.507 |
| 60 | 989M (3) | CDO + serial IO | **21.694** | 13.159 | 19.198 |
| 60 | 989M (3) | NCL | **31.795** | 27.746 | 3.571 |
| 60 | 989M (3) | NCO | **35.165** | 30.703 | 4.343 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 90 | 2.2G (3) | XArray + no dask | **23.937** | 9.584 | 12.199 |
| 90 | 2.2G (3) | XArray + 200 t chunks | **19.511** | 17.259 | 17.254 |
| 90 | 2.2G (3) | XArray + 20 t chunks | **10.709** | 23.701 | 22.772 |
| 90 | 2.2G (3) | XArray + 2 t chunks | **16.609** | 31.536 | 39.170 |
| 90 | 2.2G (3) | CDO | **75.320** | 28.646 | 78.138 |
| 90 | 2.2G (3) | CDO + serial IO | **28.416** | 23.982 | 18.300 |
| 90 | 2.2G (3) | NCL | **76.985** | 60.432 | 13.390 |
| 90 | 2.2G (3) | NCO | **86.957** | 74.774 | 10.855 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 120 | 3.9G (3) | XArray + no dask | **80.528** | 18.752 | 37.429 |
| 120 | 3.9G (3) | XArray + 200 t chunks | **124.813** | 35.979 | 74.355 |
| 120 | 3.9G (3) | XArray + 20 t chunks | **34.452** | 44.120 | 48.859 |
| 120 | 3.9G (3) | XArray + 2 t chunks | **24.056** | 43.881 | 72.519 |
| 120 | 3.9G (3) | CDO | **102.655** | 66.191 | 92.321 |
| 120 | 3.9G (3) | CDO + serial IO | **70.412** | 49.457 | 28.073 |
| 120 | 3.9G (3) | NCL | **really slow** | **really slow** | **really slow** |
| 120 | 3.9G (3) | NCO | **really slow** | **really slow** | **really slow** |

### Cheyenne interactive node: 60 level, 200 timesteps
This time, the benchmarks were run on a Cheyenne HPC compute cluster interactive node, which is a shared resource consisting of approximately 72 cores.

Here we see CDO performs just fine (the issues on the Macbook were likely an error). But again, XArray is the strongest performer.

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 18 | 178M (3) | XArray + no dask | **2.078** | 0.976 | 0.416 |
| 18 | 178M (3) | XArray + 200 t chunks | **1.145** | 0.924 | 0.396 |
| 18 | 178M (3) | XArray + 20 t chunks | **1.004** | 1.124 | 0.768 |
| 18 | 178M (3) | XArray + 2 t chunks | **1.191** | 1.184 | 0.292 |
| 18 | 178M (3) | Julia | **14.440** | 13.288 | 0.664 |
| 18 | 178M (3) | CDO | **3.050** | 5.504 | 8.156 |
| 18 | 178M (3) | CDO + serial IO | **3.104** | 4.968 | 4.572 |
| 18 | 178M (3) | NCL | **3.051** | 2.272 | 0.368 |
| 18 | 178M (3) | NCO | **2.981** | 2.532 | 0.328 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 24 | 317M (3) | XArray + no dask | **1.754** | 1.104 | 0.628 |
| 24 | 317M (3) | XArray + 200 t chunks | **1.220** | 0.980 | 0.656 |
| 24 | 317M (3) | XArray + 20 t chunks | **1.075** | 1.356 | 1.192 |
| 24 | 317M (3) | XArray + 2 t chunks | **1.281** | 1.372 | 0.420 |
| 24 | 317M (3) | Julia | **9.153** | 8.716 | 0.424 |
| 24 | 317M (3) | CDO | **3.118** | 6.436 | 7.196 |
| 24 | 317M (3) | CDO + serial IO | **3.766** | 6.060 | 4.420 |
| 24 | 317M (3) | NCL | **4.735** | 3.956 | 0.528 |
| 24 | 317M (3) | NCO | **5.523** | 4.556 | 0.732 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 36 | 712M (3) | XArray + no dask | **5.309** | 1.576 | 1.256 |
| 36 | 712M (3) | XArray + 200 t chunks | **1.744** | 1.516 | 1.080 |
| 36 | 712M (3) | XArray + 20 t chunks | **1.183** | 1.816 | 2.828 |
| 36 | 712M (3) | XArray + 2 t chunks | **1.341** | 1.916 | 0.788 |
| 36 | 712M (3) | Julia | **13.309** | 9.992 | 0.832 |
| 36 | 712M (3) | CDO | **3.270** | 8.812 | 5.072 |
| 36 | 712M (3) | CDO + serial IO | **5.075** | 8.600 | 4.104 |
| 36 | 712M (3) | NCL | **9.572** | 8.556 | 0.992 |
| 36 | 712M (3) | NCO | **11.711** | 10.064 | 1.576 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 60 | 2.0G (3) | XArray + no dask | **10.750** | 3.060 | 3.132 |
| 60 | 2.0G (3) | XArray + 200 t chunks | **2.902** | 2.728 | 2.616 |
| 60 | 2.0G (3) | XArray + 20 t chunks | **1.544** | 3.316 | 7.812 |
| 60 | 2.0G (3) | XArray + 2 t chunks | **1.577** | 3.808 | 2.836 |
| 60 | 2.0G (3) | Julia | **17.567** | 15.376 | 1.544 |
| 60 | 2.0G (3) | CDO | **5.268** | 17.524 | 4.120 |
| 60 | 2.0G (3) | CDO + serial IO | **10.485** | 17.308 | 4.672 |
| 60 | 2.0G (3) | NCL | **26.114** | 23.368 | 2.712 |
| 60 | 2.0G (3) | NCO | **32.614** | 28.044 | 3.796 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 90 | 4.4G (3) | XArray + no dask | **21.418** | 5.792 | 7.020 |
| 90 | 4.4G (3) | XArray + 200 t chunks | **5.429** | 5.228 | 5.692 |
| 90 | 4.4G (3) | XArray + 20 t chunks | **2.423** | 7.092 | 15.916 |
| 90 | 4.4G (3) | XArray + 2 t chunks | **2.214** | 7.876 | 15.216 |
| 90 | 4.4G (3) | Julia | **28.902** | 25.700 | 3.172 |
| 90 | 4.4G (3) | CDO | **9.459** | 34.380 | 5.228 |
| 90 | 4.4G (3) | CDO + serial IO | **18.924** | 34.948 | 6.076 |
| 90 | 4.4G (3) | NCL | **58.569** | 52.504 | 5.840 |
| 90 | 4.4G (3) | NCO | **81.452** | 63.240 | 8.300 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 120 | 7.8G (3) | XArray + no dask | **33.881** | 10.076 | 12.264 |
| 120 | 7.8G (3) | XArray + 200 t chunks | **9.000** | 8.800 | 9.708 |
| 120 | 7.8G (3) | XArray + 20 t chunks | **3.705** | 13.712 | 30.576 |
| 120 | 7.8G (3) | XArray + 2 t chunks | **3.010** | 14.520 | 31.884 |
| 120 | 7.8G (3) | Julia | **58.495** | 40.452 | 5.916 |
| 120 | 7.8G (3) | CDO | **14.893** | 55.396 | 6.924 |
| 120 | 7.8G (3) | CDO + serial IO | **32.032** | 54.436 | 7.952 |
| 120 | 7.8G (3) | NCL | **113.611** | 93.564 | 10.284 |
| 120 | 7.8G (3) | NCO | **140.847** | 112.292 | 13.788 |

# Installation notes
## CDO for macOS
Was *exceedingly* difficult to get CDO compiled with threadsafe HDF5 like is the default case for Anaconda-downloaded versions on Linux. Used [this thread](https://code.mpimet.mpg.de/boards/2/topics/4630?r=5714#message-5714) for instructions. This required manually compiling HDF5 with custom `./configure` flags and custom prefix, then linking with homebrew using `brew link hdf5`.

Got frequent errors following user instructions, which disappeared by disabling `--with-pthread=/usr/local --enable-unsupported`. See discussion [here](http://hdf-forum.184993.n3.nabble.com/HDF5-parallel-and-threadsafe-td1701166.html) and Github reference to that discussion [here](https://github.com/conda-forge/hdf5-feedstock/pull/57).

I tried manually compiling the netcdf library but this seemed to make no difference -- the *provided* netcdf Homebrew library was the same.

<!-- In the end *could never* get the CDO to do NetCDF4 I/O parallelization without at least sporadic errors. However looks like *performance with thread locking is often faster anyway*. -->

