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
    
Alternative explanation is that, language tools like python and NCl more appropriate for parallel computation because **data is loaded into memory once**, then calculations can proceed quickly. Maybe issue was just the multiple (5) disk reads compared to 1 NCL disk read?

## Eddy flux term tests
### Puzzles
With an older, verbose CDO algorithm for getting fluxes (see `fluxes.cdo`), CDO was **much much slower**, and the problem was exacerbated by adding levels.

I also found CDO is much slower running in parallel on the compute cluster -- even just when getting simple zonal means. Maybe CDO is bad at parallel computations, the threads conflict or something? But they are separate background processes. Meanwhile NCL was blazingly fast.

### Macbook: 60 level, 200 timesteps
The sample data was generated using
```
for reso in 20 10 7.5 5 3 2 1.5; do ./datagen $reso; done
```
where the numbers refer to the latitude/longitude grid spacing

Turns out for small datasets **NCL is faster than other tools**, and for large datasets, **CDO is faster**. Dask chunking didn't work well for small files. Note that using the NCL feature `setfileoption("nc", "Format", "LargeFile")` made **neglibile** difference in final wall-clock time. Also note there are no options to improve large file processing, recommendation is to split up by level or time; see [this NCL talk post](https://www.ncl.ucar.edu/Support/talk_archives/2011/2636.html) and [this stackoverflow post](https://stackoverflow.com/questions/44474507/read-large-netcdf-data-by-ncl).

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 9 | 22M (3) | XArray + no dask | **0.986** | 1.418 | 0.207 |
| 9 | 22M (3) | XArray + 200 t chunks | **1.174** | 1.913 | 0.663 |
| 9 | 22M (3) | XArray + 20 t chunks | **1.097** | 0.953 | 0.179 |
| 9 | 22M (3) | XArray + 2 t chunks | **1.510** | 1.308 | 0.318 |
| 9 | 22M (3) | CDO | **0.260** | 0.235 | 0.019 |
| 9 | 22M (3) | NCL | **0.715** | 0.617 | 0.091 |
| 9 | 22M (3) | NCO | **0.602** | 0.543 | 0.051 |
| 9 | 22M (3) | Julia | **5.827** | 5.825 | 0.280 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 18 | 89M (3) | XArray + no dask | **2.101** | 2.024 | 0.452 |
| 18 | 89M (3) | XArray + 200 t chunks | **1.282** | 1.656 | 1.561 |
| 18 | 89M (3) | XArray + 20 t chunks | **1.301** | 1.386 | 2.492 |
| 18 | 89M (3) | XArray + 2 t chunks | **1.557** | 1.496 | 0.315 |
| 18 | 89M (3) | CDO | **0.406** | 0.356 | 0.041 |
| 18 | 89M (3) | NCL | **2.276** | 1.987 | 0.273 |
| 18 | 89M (3) | NCO | **2.489** | 2.239 | 0.229 |
| 18 | 89M (3) | Julia | **6.577** | 6.478 | 0.369 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 24 | 158M (3) | XArray + no dask | **1.438** | 2.068 | 0.448 |
| 24 | 158M (3) | XArray + 200 t chunks | **1.880** | 2.258 | 1.884 |
| 24 | 158M (3) | XArray + 20 t chunks | **1.558** | 1.788 | 2.624 |
| 24 | 158M (3) | XArray + 2 t chunks | **1.976** | 1.834 | 0.405 |
| 24 | 158M (3) | CDO | **0.529** | 0.457 | 0.059 |
| 24 | 158M (3) | NCL | **4.027** | 3.507 | 0.475 |
| 24 | 158M (3) | NCO | **4.562** | 4.110 | 0.422 |
| 24 | 158M (3) | Julia | **8.564** | 7.647 | 0.504 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 36 | 356M (3) | XArray + no dask | **4.435** | 2.709 | 1.242 |
| 36 | 356M (3) | XArray + 200 t chunks | **2.408** | 3.908 | 2.911 |
| 36 | 356M (3) | XArray + 20 t chunks | **2.170** | 2.878 | 4.786 |
| 36 | 356M (3) | XArray + 2 t chunks | **1.955** | 2.226 | 0.406 |
| 36 | 356M (3) | CDO | **1.019** | 0.789 | 0.161 |
| 36 | 356M (3) | NCL | **9.103** | 7.781 | 1.078 |
| 36 | 356M (3) | NCO | **10.372** | 9.096 | 1.052 |
| 36 | 356M (3) | Julia | **10.280** | 8.765 | 0.893 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 60 | 989M (3) | XArray + no dask | **9.299** | 3.767 | 2.590 |
| 60 | 989M (3) | XArray + 200 t chunks | **4.777** | 7.153 | 4.787 |
| 60 | 989M (3) | XArray + 20 t chunks | **3.516** | 7.570 | 10.019 |
| 60 | 989M (3) | XArray + 2 t chunks | **3.869** | 7.056 | 11.654 |
| 60 | 989M (3) | CDO | **2.280** | 1.818 | 0.340 |
| 60 | 989M (3) | NCL | **25.601** | 21.664 | 3.007 |
| 60 | 989M (3) | NCO | **29.946** | 25.710 | 3.980 |
| 60 | 989M (3) | Julia | **16.671** | 13.786 | 1.937 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 90 | 2.2G (3) | XArray + no dask | **22.434** | 7.589 | 12.127 |
| 90 | 2.2G (3) | XArray + 200 t chunks | **19.566** | 14.278 | 16.805 |
| 90 | 2.2G (3) | XArray + 20 t chunks | **8.238** | 16.869 | 18.644 |
| 90 | 2.2G (3) | XArray + 2 t chunks | **7.738** | 15.272 | 23.208 |
| 90 | 2.2G (3) | CDO | **5.424** | 4.133 | 1.160 |
| 90 | 2.2G (3) | NCL | **63.710** | 48.852 | 10.949 |
| 90 | 2.2G (3) | NCO | **67.613** | 57.737 | 8.929 |
| 90 | 2.2G (3) | Julia | **28.123** | 23.273 | 3.728 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 120 | 3.9G (3) | XArray + no dask | **37.891** | 11.317 | 19.480 |
| 120 | 3.9G (3) | XArray + 200 t chunks | **41.033** | 21.114 | 35.903 |
| 120 | 3.9G (3) | XArray + 20 t chunks | **15.271** | 26.079 | 30.995 |
| 120 | 3.9G (3) | XArray + 2 t chunks | **12.193** | 25.716 | 43.533 |
| 120 | 3.9G (3) | CDO | **11.147** | 7.868 | 2.948 |
| 120 | 3.9G (3) | NCL | **167.925** | 89.902 | 45.375 |
| 120 | 3.9G (3) | NCO | **132.901** | 104.445 | 20.934 |
| 120 | 3.9G (3) | Julia | **56.365** | 38.161 | 11.888 |

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

### Cheyenne submission: 40 cores
Next I used `qsub`, and again, the results were quite similar. Not sure why we are seeing the issues with CDO during model runs.

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 18 | 178M (3) | XArray + no dask | **1.173** | 2.356 | 0.400 |
| 18 | 178M (3) | XArray + 200 t chunks | **0.951** | 3.400 | 0.452 |
| 18 | 178M (3) | XArray + 20 t chunks | **1.055** | 10.080 | 12.028 |
| 18 | 178M (3) | XArray + 2 t chunks | **1.091** | 1.112 | 0.256 |
| 18 | 178M (3) | Julia | **8.667** | 8.020 | 0.632 |
| 18 | 178M (3) | CDO | **2.942** | 5.916 | 6.928 |
| 18 | 178M (3) | CDO + serial IO | **3.024** | 5.088 | 4.484 |
| 18 | 178M (3) | NCL | **2.573** | 2.192 | 0.364 |
| 18 | 178M (3) | NCO | **2.890** | 2.516 | 0.308 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 24 | 317M (3) | XArray + no dask | **1.492** | 3.348 | 0.712 |
| 24 | 317M (3) | XArray + 200 t chunks | **1.148** | 4.452 | 0.784 |
| 24 | 317M (3) | XArray + 20 t chunks | **1.059** | 8.796 | 12.480 |
| 24 | 317M (3) | XArray + 2 t chunks | **1.219** | 1.332 | 0.364 |
| 24 | 317M (3) | Julia | **9.006** | 8.600 | 0.740 |
| 24 | 317M (3) | CDO | **3.030** | 6.304 | 7.180 |
| 24 | 317M (3) | CDO + serial IO | **3.551** | 6.040 | 4.380 |
| 24 | 317M (3) | NCL | **4.436** | 3.868 | 0.520 |
| 24 | 317M (3) | NCO | **5.265** | 4.444 | 0.792 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 36 | 712M (3) | XArray + no dask | **4.679** | 5.348 | 1.416 |
| 36 | 712M (3) | XArray + 200 t chunks | **1.463** | 5.676 | 1.244 |
| 36 | 712M (3) | XArray + 20 t chunks | **1.344** | 10.848 | 25.072 |
| 36 | 712M (3) | XArray + 2 t chunks | **1.639** | 21.664 | 31.216 |
| 36 | 712M (3) | Julia | **10.784** | 10.152 | 0.960 |
| 36 | 712M (3) | CDO | **3.216** | 8.772 | 5.284 |
| 36 | 712M (3) | CDO + serial IO | **5.153** | 8.844 | 4.220 |
| 36 | 712M (3) | NCL | **9.574** | 8.620 | 0.928 |
| 36 | 712M (3) | NCO | **11.751** | 10.088 | 1.580 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 60 | 2.0G (3) | XArray + no dask | **9.826** | 7.972 | 3.472 |
| 60 | 2.0G (3) | XArray + 200 t chunks | **2.574** | 9.648 | 3.192 |
| 60 | 2.0G (3) | XArray + 20 t chunks | **1.899** | 28.012 | 31.980 |
| 60 | 2.0G (3) | XArray + 2 t chunks | **3.022** | 47.212 | 100.940 |
| 60 | 2.0G (3) | Julia | **17.202** | 15.716 | 1.816 |
| 60 | 2.0G (3) | CDO | **5.246** | 17.416 | 4.232 |
| 60 | 2.0G (3) | CDO + serial IO | **10.366** | 17.528 | 4.756 |
| 60 | 2.0G (3) | NCL | **26.122** | 23.488 | 2.600 |
| 60 | 2.0G (3) | NCO | **31.881** | 27.896 | 3.932 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 90 | 4.4G (3) | XArray + no dask | **18.705** | 11.156 | 7.708 |
| 90 | 4.4G (3) | XArray + 200 t chunks | **4.813** | 12.172 | 7.492 |
| 90 | 4.4G (3) | XArray + 20 t chunks | **2.762** | 29.908 | 59.560 |
| 90 | 4.4G (3) | XArray + 2 t chunks | **3.737** | 68.036 | 121.884 |
| 90 | 4.4G (3) | Julia | **31.706** | 26.472 | 3.488 |
| 90 | 4.4G (3) | CDO | **9.824** | 34.300 | 5.444 |
| 90 | 4.4G (3) | CDO + serial IO | **19.190** | 35.036 | 6.372 |
| 90 | 4.4G (3) | NCL | **59.335** | 52.484 | 5.860 |
| 90 | 4.4G (3) | NCO | **74.060** | 63.236 | 8.096 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 120 | 7.8G (3) | XArray + no dask | **30.443** | 15.376 | 13.232 |
| 120 | 7.8G (3) | XArray + 200 t chunks | **7.703** | 16.108 | 12.044 |
| 120 | 7.8G (3) | XArray + 20 t chunks | **4.069** | 41.852 | 81.632 |
| 120 | 7.8G (3) | XArray + 2 t chunks | **4.771** | 92.560 | 152.648 |
| 120 | 7.8G (3) | Julia | **56.144** | 41.032 | 5.976 |
| 120 | 7.8G (3) | CDO | **15.368** | 57.296 | 6.508 |
| 120 | 7.8G (3) | CDO + serial IO | **31.701** | 57.076 | 7.296 |
| 120 | 7.8G (3) | NCL | **111.396** | 93.536 | 10.064 |

# Installation notes
## CDO for macOS
Was *exceedingly* difficult to get CDO compiled with threadsafe HDF5 like is the default case for Anaconda-downloaded versions on Linux. Used [this thread](https://code.mpimet.mpg.de/boards/2/topics/4630?r=5714#message-5714) for instructions. This required manually compiling HDF5 with custom `./configure` flags and custom prefix, then linking with homebrew using `brew link hdf5`.

Got frequent errors following user instructions, which disappeared by disabling `--with-pthread=/usr/local --enable-unsupported`. See discussion [here](http://hdf-forum.184993.n3.nabble.com/HDF5-parallel-and-threadsafe-td1701166.html) and Github reference to that discussion [here](https://github.com/conda-forge/hdf5-feedstock/pull/57).

I tried manually compiling the netcdf library but this seemed to make no difference -- the *provided* netcdf Homebrew library was the same.

<!-- In the end *could never* get the CDO to do NetCDF4 I/O parallelization without at least sporadic errors. However looks like *performance with thread locking is often faster anyway*. -->

