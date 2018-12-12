# Benchmarks for climate data analysis
Use this repo to benchmark data analysis techniques across CDO, NCL, NCO, python, and julia. Matlab and IDL are the past so I'm not bothering with them ;)

## Interpolation tests
Setup is 4 times daily 100-day T42L40 resolution files, from dry dynamical core model.

* Time for NCL interpolation script with **automatic iteration**: ***70s exactly***
* Time for interpolation script with **explicit iteration through variables**: ***71s almost identical***
* Time for interpolation with CDO: ***30s pre-processing*** (probably due to inefficiency of overwriting original ncfile with file that dleetes coordinates), ***94s for setting things up*** (because we have to write surface geopotential to same massive file, instead of declaring as separate variable in NCL), and ***122s actual interpolation*** (with bunch of warnings) so ***216 total***

## Eddy flux term tests
Data used was generated with the `datagen` script via the line:
```
for reso in 5 2 1 0.5; do ./datagen $reso; done
```
Results are summarized in the below table. Turns out **NCL is much faster than all other tools**, to my surprise. Dask chunking didn't work well for small files. Note that using the NCL feature `setfileoption("nc", "Format", "LargeFile")` made absolutely **neglibile** difference in final wall-clock time, to my surprise. Also note there are no options to improve large file handling, recommendation is to split up by level or time; see [this NCL talk post](https://www.ncl.ucar.edu/Support/talk_archives/2011/2636.html) and [this stackoverflow post](https://stackoverflow.com/questions/44474507/read-large-netcdf-data-by-ncl).

### Macbook Pro

| size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- |
| 7.4M (3) | XArray + no dask | **1.297** | 1.039 | 0.258 |
| 7.4M (3) | XArray + 100-timestep chunks | **1.116** | 0.913 | 0.179 |
| 7.4M (3) | XArray + 10-timestep chunks | **1.541** | 1.291 | 0.296 |
| 7.4M (3) | XArray + 1-timestep chunks | **6.515** | 5.640 | 1.481 |
| 7.4M (3) | CDO | **6.336** | 1.026 | 6.319 |
| 7.4M (3) | CDO + serial IO | **2.911** | 0.695 | 3.086 |
| 7.4M (3) | NCL | **0.604** | 0.325 | 0.082 |
| 7.4M (3) | NCO | **0.270** | 0.201 | 0.034 |

| size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- |
| 7.6M (4) | XArray + no dask | **1.110** | 1.075 | 0.192 |
| 7.6M (4) | XArray + 100-timestep chunks | **1.072** | 0.891 | 0.163 |
| 7.6M (4) | XArray + 10-timestep chunks | **1.552** | 1.355 | 0.298 |
| 7.6M (4) | XArray + 1-timestep chunks | **6.453** | 5.890 | 1.485 |
| 7.6M (4) | CDO | **6.495** | 2.001 | 6.801 |
| 7.6M (4) | CDO + serial IO | **2.471** | 1.290 | 1.936 |
| 7.6M (4) | NCL | **0.425** | 0.339 | 0.073 |
| 7.6M (4) | NCO | **0.302** | 0.258 | 0.035 |

| size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- |
| 30M (3) | XArray + no dask | **1.683** | 1.597 | 0.328 |
| 30M (3) | XArray + 100-timestep chunks | **1.089** | 0.935 | 0.193 |
| 30M (3) | XArray + 10-timestep chunks | **1.556** | 1.343 | 0.314 |
| 30M (3) | XArray + 1-timestep chunks | **6.336** | 5.609 | 1.462 |
| 30M (3) | CDO | **6.226** | 1.138 | 6.327 |
| 30M (3) | CDO + serial IO | **2.791** | 0.778 | 2.891 |
| 30M (3) | NCL | **0.929** | 0.790 | 0.131 |
| 30M (3) | NCO | **0.859** | 0.764 | 0.083 |

| size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- |
| 30M (4) | XArray + no dask | **1.305** | 1.547 | 0.294 |
| 30M (4) | XArray + 100-timestep chunks | **1.090** | 0.946 | 0.184 |
| 30M (4) | XArray + 10-timestep chunks | **1.575** | 1.405 | 0.317 |
| 30M (4) | XArray + 1-timestep chunks | **6.594** | 6.083 | 1.567 |
| 30M (4) | CDO | **6.519** | 2.045 | 6.873 |
| 30M (4) | CDO + serial IO | **2.389** | 1.359 | 1.785 |
| 30M (4) | NCL | **0.898** | 0.767 | 0.124 |
| 30M (4) | NCO | **0.935** | 0.822 | 0.102 |

| size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- |
| 82M (3) | XArray + no dask | **2.410** | 2.051 | 0.530 |
| 82M (3) | XArray + 100-timestep chunks | **1.217** | 1.277 | 1.661 |
| 82M (3) | XArray + 10-timestep chunks | **1.573** | 1.476 | 0.332 |
| 82M (3) | XArray + 1-timestep chunks | **6.432** | 5.781 | 1.606 |
| 82M (3) | CDO | **6.107** | 1.412 | 6.269 |
| 82M (3) | CDO + serial IO | **2.619** | 0.999 | 2.548 |
| 82M (3) | NCL | **2.194** | 1.894 | 0.286 |
| 82M (3) | NCO | **2.345** | 2.107 | 0.228 |

| size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- |
| 83M (4) | XArray + no dask | **1.485** | 1.925 | 0.405 |
| 83M (4) | XArray + 100-timestep chunks | **1.270** | 1.271 | 1.550 |
| 83M (4) | XArray + 10-timestep chunks | **1.549** | 1.446 | 0.323 |
| 83M (4) | XArray + 1-timestep chunks | **6.749** | 6.141 | 1.680 |
| 83M (4) | CDO | **6.372** | 2.189 | 6.736 |
| 83M (4) | CDO + serial IO | **2.472** | 1.512 | 1.806 |
| 83M (4) | NCL | **2.121** | 1.855 | 0.251 |
| 83M (4) | NCO | **2.391** | 2.158 | 0.223 |

| size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- |
| 185M (3) | XArray + no dask | **3.611** | 2.310 | 0.820 |
| 185M (3) | XArray + 100-timestep chunks | **1.624** | 2.984 | 2.802 |
| 185M (3) | XArray + 10-timestep chunks | **1.688** | 1.695 | 0.355 |
| 185M (3) | XArray + 1-timestep chunks | **6.736** | 6.137 | 1.764 |
| 185M (3) | CDO | **5.931** | 1.943 | 6.162 |
| 185M (3) | CDO + serial IO | **2.930** | 1.509 | 2.507 |
| 185M (3) | NCL | **4.687** | 4.054 | 0.615 |
| 185M (3) | NCO | **5.324** | 4.764 | 0.540 |

| size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- |
| 186M (4) | XArray + no dask | **1.868** | 2.135 | 0.637 |
| 186M (4) | XArray + 100-timestep chunks | **1.432** | 1.659 | 2.774 |
| 186M (4) | XArray + 10-timestep chunks | **1.692** | 1.669 | 0.370 |
| 186M (4) | XArray + 1-timestep chunks | **6.884** | 6.386 | 1.771 |
| 186M (4) | CDO | **6.251** | 2.501 | 6.511 |
| 186M (4) | CDO + serial IO | **2.604** | 1.697 | 1.894 |
| 186M (4) | NCL | **4.465** | 3.978 | 0.472 |
| 186M (4) | NCO | **5.269** | 4.740 | 0.509 |

| size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- |
| 330M (3) | XArray + no dask | **6.169** | 2.577 | 1.301 |
| 330M (3) | XArray + 100-timestep chunks | **1.923** | 2.453 | 4.830 |
| 330M (3) | XArray + 10-timestep chunks | **1.757** | 1.965 | 0.371 |
| 330M (3) | XArray + 1-timestep chunks | **6.774** | 6.396 | 1.763 |
| 330M (3) | CDO | **5.617** | 2.729 | 5.835 |
| 330M (3) | CDO + serial IO | **3.797** | 2.507 | 2.692 |
| 330M (3) | NCL | **8.363** | 7.185 | 1.148 |
| 330M (3) | NCO | **9.281** | 8.313 | 0.911 |

| size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- |
| 330M (4) | XArray + no dask | **2.931** | 2.399 | 0.997 |
| 330M (4) | XArray + 100-timestep chunks | **1.753** | 2.260 | 3.571 |
| 330M (4) | XArray + 10-timestep chunks | **1.783** | 1.910 | 0.412 |
| 330M (4) | XArray + 1-timestep chunks | **7.076** | 6.709 | 1.852 |
| 330M (4) | CDO | **6.355** | 3.090 | 6.704 |
| 330M (4) | CDO + serial IO | **3.283** | 2.304 | 2.350 |
| 330M (4) | NCL | **8.106** | 6.967 | 0.932 |
| 330M (4) | NCO | **9.216** | 8.305 | 0.869 |

| size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- |
| 742M (3) | XArray + no dask | **9.669** | 3.711 | 2.377 |
| 742M (3) | XArray + 100-timestep chunks | **3.238** | 5.851 | 7.868 |
| 742M (3) | XArray + 10-timestep chunks | **3.163** | 5.596 | 9.481 |
| 742M (3) | XArray + 1-timestep chunks | **6.901** | 7.175 | 1.808 |
| 742M (3) | CDO | **5.408** | 5.129 | 5.357 |
| 742M (3) | CDO + serial IO | **5.175** | 4.562 | 2.721 |
| 742M (3) | NCL | **18.155** | 15.812 | 2.284 |
| 742M (3) | NCO | **21.926** | 19.039 | 2.830 |

| size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- |
| 742M (4) | XArray + no dask | **3.906** | 3.081 | 1.500 |
| 742M (4) | XArray + 100-timestep chunks | **2.525** | 5.058 | 6.678 |
| 742M (4) | XArray + 10-timestep chunks | **2.701** | 4.965 | 8.274 |
| 742M (4) | XArray + 1-timestep chunks | **6.919** | 7.064 | 1.824 |
| 742M (4) | CDO | **5.316** | 3.897 | 5.787 |
| 742M (4) | CDO + serial IO | **3.548** | 3.140 | 2.561 |
| 742M (4) | NCL | **17.428** | 15.209 | 2.033 |
| 742M (4) | NCO | **21.820** | 19.057 | 2.715 |

| size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- |
| 1.3G (3) | XArray + no dask | **15.818** | 4.604 | 3.875 |
| 1.3G (3) | XArray + 100-timestep chunks | **4.342** | 9.189 | 11.659 |
| 1.3G (3) | XArray + 10-timestep chunks | **4.335** | 8.750 | 16.860 |
| 1.3G (3) | XArray + 1-timestep chunks | **7.248** | 8.445 | 1.860 |
| 1.3G (3) | CDO | **5.561** | 9.696 | 4.972 |
| 1.3G (3) | CDO + serial IO | **7.344** | 7.483 | 2.967 |
| 1.3G (3) | NCL | **31.795** | 27.663 | 3.807 |
| 1.3G (3) | NCO | **39.458** | 34.031 | 5.232 |

| size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- |
| 1.3G (4) | XArray + no dask | **7.732** | 3.709 | 3.510 |
| 1.3G (4) | XArray + 100-timestep chunks | **4.222** | 8.178 | 11.442 |
| 1.3G (4) | XArray + 10-timestep chunks | **4.159** | 9.086 | 14.940 |
| 1.3G (4) | XArray + 1-timestep chunks | **7.161** | 8.148 | 2.017 |
| 1.3G (4) | CDO | **6.070** | 6.765 | 6.089 |
| 1.3G (4) | CDO + serial IO | **4.537** | 5.301 | 2.957 |
| 1.3G (4) | NCL | **31.076** | 27.203 | 3.643 |
| 1.3G (4) | NCO | **38.764** | 33.702 | 4.999 |

| size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- |
| 2.9G (3) | XArray + no dask | **33.205** | 9.416 | 12.419 |
| 2.9G (3) | XArray + 100-timestep chunks | **11.477** | 23.268 | 20.029 |
| 2.9G (3) | XArray + 10-timestep chunks | **8.876** | 18.641 | 40.981 |
| 2.9G (3) | XArray + 1-timestep chunks | **8.703** | 12.396 | 2.311 |
| 2.9G (3) | CDO | **8.332** | 22.239 | 4.523 |
| 2.9G (3) | CDO + serial IO | **14.467** | 17.852 | 3.762 |
| 2.9G (3) | NCL | **83.779** | 63.280 | 16.465 |
| 2.9G (3) | NCO | **88.465** | 73.347 | 11.464 |

| size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- |
| 2.9G (4) | XArray + no dask | **16.529** | 6.211 | 8.986 |
| 2.9G (4) | XArray + 100-timestep chunks | **7.939** | 17.366 | 19.754 |
| 2.9G (4) | XArray + 10-timestep chunks | **6.618** | 14.956 | 28.725 |
| 2.9G (4) | XArray + 1-timestep chunks | **7.556** | 10.298 | 2.278 |
| 2.9G (4) | CDO | **6.169** | 12.271 | 4.140 |
| 2.9G (4) | CDO + serial IO | **6.150** | 11.162 | 3.127 |
| 2.9G (4) | NCL | **72.196** | 58.627 | 11.331 |
| 2.9G (4) | NCO | **85.414** | 74.449 | 10.379 |

### Linux server
To be added.

# Installation notes
## CDO for macOS
Was *exceedingly* difficult to get CDO compiled with threadsafe HDF5 like is the default case for Anaconda-downloaded versions on Linux. Used [this thread](https://code.mpimet.mpg.de/boards/2/topics/4630?r=5714#message-5714) for instructions. This required manually compiling HDF5 with custom `./configure` flags and custom prefix, then linking with homebrew using `brew link hdf5`.

Got frequent errors following user instructions, which disappeared by disabling `--with-pthread=/usr/local --enable-unsupported`. See discussion [here](http://hdf-forum.184993.n3.nabble.com/HDF5-parallel-and-threadsafe-td1701166.html) and Github reference to that discussion [here](https://github.com/conda-forge/hdf5-feedstock/pull/57).

I tried manually compiling the netcdf library but this seemed to make no difference -- the *provided* netcdf Homebrew library was the same.

<!-- In the end *could never* get the CDO to do NetCDF4 I/O parallelization without at least sporadic errors. However looks like *performance with thread locking is often faster anyway*. -->

