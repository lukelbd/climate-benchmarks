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
With an older, verbose CDO algorithm for getting fluxes (see `trash/fluxes_ineff.cdo`), CDO was **much much slower**, and the problem was exacerbated by adding levels.

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
| 9 | 22M (3) | Julia + PackageCompiler | **0.515** | 0.547 | 0.249 |
| 9 | 22M (3) | Interactive Julia | **0.196**
| 9 | 22M (3) | XArray + no dask | **1.016** | 1.446 | 0.212 |
| 9 | 22M (3) | XArray + 200 t chunks | **1.124** | 1.246 | 0.829 |
| 9 | 22M (3) | XArray + 20 t chunks | **1.095** | 0.974 | 0.189 |
| 9 | 22M (3) | XArray + 2 t chunks | **1.680** | 1.395 | 0.337 |
| 9 | 22M (3) | CDO | **0.270** | 0.239 | 0.022 |
| 9 | 22M (3) | NCL | **0.752** | 0.641 | 0.100 |
| 9 | 22M (3) | NCO | **0.640** | 0.573 | 0.052 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 18 | 89M (3) | Julia + PackageCompiler | **1.144** | 1.061 | 0.345 |
| 18 | 89M (3) | Interactive Julia | **1.972**
| 18 | 89M (3) | XArray + no dask | **1.288** | 1.788 | 0.367 |
| 18 | 89M (3) | XArray + 200 t chunks | **1.360** | 1.719 | 1.532 |
| 18 | 89M (3) | XArray + 20 t chunks | **1.444** | 2.549 | 1.633 |
| 18 | 89M (3) | XArray + 2 t chunks | **1.668** | 1.529 | 0.346 |
| 18 | 89M (3) | CDO | **0.428** | 0.375 | 0.041 |
| 18 | 89M (3) | NCL | **2.398** | 2.045 | 0.300 |
| 18 | 89M (3) | NCO | **2.568** | 2.278 | 0.253 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 24 | 158M (3) | Julia + PackageCompiler | **1.822** | 1.667 | 0.422 |
| 24 | 158M (3) | Interactive Julia | **2.819**
| 24 | 158M (3) | XArray + no dask | **1.644** | 2.118 | 0.549 |
| 24 | 158M (3) | XArray + 200 t chunks | **1.671** | 2.705 | 1.823 |
| 24 | 158M (3) | XArray + 20 t chunks | **1.442** | 1.712 | 2.850 |
| 24 | 158M (3) | XArray + 2 t chunks | **1.671** | 1.642 | 0.346 |
| 24 | 158M (3) | CDO | **0.563** | 0.489 | 0.061 |
| 24 | 158M (3) | NCL | **4.019** | 3.505 | 0.449 |
| 24 | 158M (3) | NCO | **4.514** | 4.021 | 0.456 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 36 | 356M (3) | Julia + PackageCompiler | **3.520** | 3.118 | 0.664 |
| 36 | 356M (3) | Interactive Julia | **5.546**
| 36 | 356M (3) | XArray + no dask | **3.220** | 2.669 | 1.064 |
| 36 | 356M (3) | XArray + 200 t chunks | **2.279** | 3.756 | 2.917 |
| 36 | 356M (3) | XArray + 20 t chunks | **1.942** | 2.772 | 5.394 |
| 36 | 356M (3) | XArray + 2 t chunks | **1.894** | 2.145 | 0.398 |
| 36 | 356M (3) | CDO | **0.923** | 0.755 | 0.142 |
| 36 | 356M (3) | NCL | **9.095** | 7.786 | 1.068 |
| 36 | 356M (3) | NCO | **10.066** | 8.973 | 1.019 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 60 | 989M (3) | Julia + PackageCompiler | **12.146** | 8.570 | 1.965 |
| 60 | 989M (3) | Interactive Julia | **13.861**
| 60 | 989M (3) | XArray + no dask | **8.961** | 3.738 | 3.038 |
| 60 | 989M (3) | XArray + 200 t chunks | **4.340** | 7.284 | 4.456 |
| 60 | 989M (3) | XArray + 20 t chunks | **3.649** | 8.183 | 10.169 |
| 60 | 989M (3) | XArray + 2 t chunks | **3.667** | 6.908 | 13.068 |
| 60 | 989M (3) | CDO | **2.196** | 1.808 | 0.309 |
| 60 | 989M (3) | NCL | **26.185** | 21.745 | 3.461 |
| 60 | 989M (3) | NCO | **29.934** | 25.826 | 3.905 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 90 | 2.2G (3) | Julia + PackageCompiler | **25.994** | 18.185 | 5.383 |
| 90 | 2.2G (3) | Interactive Julia | **39.636**
| 90 | 2.2G (3) | XArray + no dask | **25.991** | 7.965 | 13.275 |
| 90 | 2.2G (3) | XArray + 200 t chunks | **18.003** | 12.960 | 15.137 |
| 90 | 2.2G (3) | XArray + 20 t chunks | **9.135** | 18.487 | 17.497 |
| 90 | 2.2G (3) | XArray + 2 t chunks | **7.004** | 15.027 | 27.081 |
| 90 | 2.2G (3) | CDO | **5.400** | 4.058 | 1.131 |
| 90 | 2.2G (3) | NCL | **62.723** | 48.688 | 10.076 |
| 90 | 2.2G (3) | NCO | **75.389** | 59.159 | 11.353 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 120 | 3.9G (3) | Julia + PackageCompiler | **53.397** | 35.249 | 11.727 |
| 129 | 3.9G (3) | Interactive Julia | **63.701**
| 120 | 3.9G (3) | XArray + no dask | **38.976** | 11.378 | 18.792 |
| 120 | 3.9G (3) | XArray + 200 t chunks | **48.395** | 21.554 | 39.484 |
| 120 | 3.9G (3) | XArray + 20 t chunks | **15.120** | 26.239 | 29.483 |
| 120 | 3.9G (3) | XArray + 2 t chunks | **11.042** | 23.187 | 46.731 |
| 120 | 3.9G (3) | CDO | **10.575** | 7.623 | 2.792 |
| 120 | 3.9G (3) | NCL | **216.434** | 90.484 | 42.720 |
| 120 | 3.9G (3) | NCO | **145.183** | 105.943 | 26.878 |

### Cheyenne interactive node: 60 level, 200 timesteps
This time, the benchmarks were run on a Cheyenne HPC compute cluster interactive node, which is a shared resource consisting of approximately 72 cores.

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 9 | 22M (3) | Julia + PackageCompiler | **0.442** | 0.316 | 0.112 |
| 9 | 22M (3) | XArray + no dask | **0.975** | 0.744 | 0.188 |
| 9 | 22M (3) | XArray + 200 t chunks | **0.912** | 0.712 | 0.248 |
| 9 | 22M (3) | XArray + 20 t chunks | **0.885** | 0.872 | 0.476 |
| 9 | 22M (3) | XArray + 2 t chunks | **1.131** | 0.960 | 0.244 |
| 9 | 22M (3) | CDO | **0.406** | 0.300 | 0.028 |
| 9 | 22M (3) | NCL | **0.785** | 0.668 | 0.100 |
| 9 | 22M (3) | NCO | **0.752** | 0.620 | 0.112 |
| 9 | 22M (3) | Julia | **1.294** | 1.180 | 0.108 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 18 | 89M (3) | Julia + PackageCompiler | **1.466** | 0.948 | 0.264 |
| 18 | 89M (3) | XArray + no dask | **1.267** | 0.976 | 0.272 |
| 18 | 89M (3) | XArray + 200 t chunks | **1.224** | 0.976 | 0.428 |
| 18 | 89M (3) | XArray + 20 t chunks | **0.956** | 1.164 | 0.672 |
| 18 | 89M (3) | XArray + 2 t chunks | **1.376** | 1.292 | 0.296 |
| 18 | 89M (3) | CDO | **0.763** | 0.604 | 0.048 |
| 18 | 89M (3) | NCL | **2.938** | 2.256 | 0.408 |
| 18 | 89M (3) | NCO | **2.906** | 2.540 | 0.348 |
| 18 | 89M (3) | Julia | **1.332** | 1.220 | 0.104 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 24 | 158M (3) | Julia + PackageCompiler | **2.221** | 1.684 | 0.412 |
| 24 | 158M (3) | XArray + no dask | **1.936** | 1.140 | 0.704 |
| 24 | 158M (3) | XArray + 200 t chunks | **1.194** | 0.952 | 0.656 |
| 24 | 158M (3) | XArray + 20 t chunks | **1.139** | 1.468 | 1.680 |
| 24 | 158M (3) | XArray + 2 t chunks | **1.276** | 1.456 | 0.496 |
| 24 | 158M (3) | CDO | **1.071** | 0.908 | 0.088 |
| 24 | 158M (3) | NCL | **4.639** | 3.912 | 0.588 |
| 24 | 158M (3) | NCO | **5.331** | 4.496 | 0.812 |
| 24 | 158M (3) | Julia | **1.306** | 1.180 | 0.120 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 36 | 356M (3) | Julia + PackageCompiler | **6.133** | 3.332 | 0.796 |
| 36 | 356M (3) | XArray + no dask | **3.795** | 1.616 | 1.448 |
| 36 | 356M (3) | XArray + 200 t chunks | **1.690** | 1.552 | 1.060 |
| 36 | 356M (3) | XArray + 20 t chunks | **1.240** | 2.064 | 2.964 |
| 36 | 356M (3) | XArray + 2 t chunks | **1.470** | 2.088 | 1.192 |
| 36 | 356M (3) | CDO | **2.033** | 1.804 | 0.092 |
| 36 | 356M (3) | NCL | **10.113** | 8.448 | 1.172 |
| 36 | 356M (3) | NCO | **11.879** | 10.056 | 1.748 |
| 36 | 356M (3) | Julia | **1.280** | 1.168 | 0.108 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 60 | 989M (3) | Julia + PackageCompiler | **13.806** | 8.704 | 1.664 |
| 60 | 989M (3) | XArray + no dask | **7.499** | 3.108 | 3.328 |
| 60 | 989M (3) | XArray + 200 t chunks | **3.102** | 2.800 | 2.796 |
| 60 | 989M (3) | XArray + 20 t chunks | **1.720** | 3.768 | 9.004 |
| 60 | 989M (3) | XArray + 2 t chunks | **1.880** | 4.872 | 9.024 |
| 60 | 989M (3) | CDO | **6.431** | 4.820 | 1.400 |
| 60 | 989M (3) | NCL | **27.460** | 23.348 | 2.728 |
| 60 | 989M (3) | NCO | **32.960** | 27.948 | 3.936 |
| 60 | 989M (3) | Julia | **1.220** | 1.124 | 0.092 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 90 | 2.2G (3) | Julia + PackageCompiler | **27.768** | 18.880 | 3.212 |
| 90 | 2.2G (3) | XArray + no dask | **15.779** | 5.880 | 7.200 |
| 90 | 2.2G (3) | XArray + 200 t chunks | **5.547** | 5.220 | 5.776 |
| 90 | 2.2G (3) | XArray + 20 t chunks | **2.333** | 7.808 | 14.920 |
| 90 | 2.2G (3) | XArray + 2 t chunks | **2.157** | 7.496 | 11.176 |
| 90 | 2.2G (3) | CDO | **13.838** | 10.540 | 3.112 |
| 90 | 2.2G (3) | NCL | **58.623** | 52.544 | 5.876 |
| 90 | 2.2G (3) | NCO | **71.893** | 63.256 | 8.060 |
| 90 | 2.2G (3) | Julia | **1.493** | 1.076 | 0.212 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 120 | 3.9G (3) | Julia + PackageCompiler | **50.636** | 33.424 | 5.320 |
| 120 | 3.9G (3) | XArray + no dask | **25.097** | 9.652 | 12.400 |
| 120 | 3.9G (3) | XArray + 200 t chunks | **9.021** | 8.552 | 10.416 |
| 120 | 3.9G (3) | XArray + 20 t chunks | **3.718** | 11.968 | 31.708 |
| 120 | 3.9G (3) | XArray + 2 t chunks | **2.800** | 13.244 | 23.320 |
| 120 | 3.9G (3) | CDO | **25.413** | 19.008 | 6.244 |
| 120 | 3.9G (3) | NCL | **109.181** | 93.100 | 10.664 |
| 120 | 3.9G (3) | NCO | **139.396** | 112.788 | 13.928 |
| 120 | 3.9G (3) | Julia | **1.342** | 1.124 | 0.156 |

# Installation notes
## CDO for macOS
Was *exceedingly* difficult to get CDO compiled with threadsafe HDF5 like is the default case for Anaconda-downloaded versions on Linux. Used [this thread](https://code.mpimet.mpg.de/boards/2/topics/4630?r=5714#message-5714) for instructions. This required manually compiling HDF5 with custom `./configure` flags and custom prefix, then linking with homebrew using `brew link hdf5`.

Got frequent errors following user instructions, which disappeared by disabling `--with-pthread=/usr/local --enable-unsupported`. See discussion [here](http://hdf-forum.184993.n3.nabble.com/HDF5-parallel-and-threadsafe-td1701166.html) and Github reference to that discussion [here](https://github.com/conda-forge/hdf5-feedstock/pull/57).

I tried manually compiling the netcdf library but this seemed to make no difference -- the *provided* netcdf Homebrew library was the same.

<!-- In the end *could never* get the CDO to do NetCDF4 I/O parallelization without at least sporadic errors. However looks like *performance with thread locking is often faster anyway*. -->

