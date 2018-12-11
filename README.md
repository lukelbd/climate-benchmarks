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
Results are summarized in the below table. Turns out **NCL is much faster than all other tools**, to my surprise. Dask chunking didn't work well for small files.

### Macbook Pro

| size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- |
| 7.4M (3) | XArray + no dask | **0.980** | 1.009 | 0.164 |
| 7.4M (3) | XArray + 100-timestep chunks | **1.089** | 0.892 | 0.178 |
| 7.4M (3) | XArray + 10-timestep chunks | **1.557** | 1.310 | 0.301 |
| 7.4M (3) | XArray + 1-timestep chunks | **6.493** | 5.616 | 1.502 |
| 7.4M (3) | CDO | **6.600** | 1.089 | 6.621 |
| 7.4M (3) | CDO + serial IO | **3.349** | 0.780 | 3.411 |
| 7.4M (3) | NCL | **0.384** | 0.313 | 0.062 |
| 7.4M (3) | NCO | **0.239** | 0.200 | 0.029 |

| size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- |
| 7.6M (4) | XArray + no dask | **1.204** | 1.135 | 0.219 |
| 7.6M (4) | XArray + 100-timestep chunks | **1.136** | 0.947 | 0.192 |
| 7.6M (4) | XArray + 10-timestep chunks | **1.634** | 1.431 | 0.340 |
| 7.6M (4) | XArray + 1-timestep chunks | **7.051** | 6.413 | 1.673 |
| 7.6M (4) | CDO | **7.093** | 2.245 | 7.289 |
| 7.6M (4) | CDO + serial IO | **2.526** | 1.383 | 1.924 |
| 7.6M (4) | NCL | **0.521** | 0.374 | 0.102 |
| 7.6M (4) | NCO | **0.318** | 0.265 | 0.040 |

| size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- |
| 30M (3) | XArray + no dask | **1.864** | 1.656 | 0.365 |
| 30M (3) | XArray + 100-timestep chunks | **1.251** | 1.029 | 0.214 |
| 30M (3) | XArray + 10-timestep chunks | **1.601** | 1.402 | 0.332 |
| 30M (3) | XArray + 1-timestep chunks | **7.141** | 6.185 | 1.742 |
| 30M (3) | CDO | **6.472** | 1.176 | 6.567 |
| 30M (3) | CDO + serial IO | **2.844** | 0.790 | 2.949 |
| 30M (3) | NCL | **0.912** | 0.773 | 0.127 |
| 30M (3) | NCO | **0.858** | 0.762 | 0.082 |

| size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- |
| 30M (4) | XArray + no dask | **1.284** | 1.634 | 0.298 |
| 30M (4) | XArray + 100-timestep chunks | **1.115** | 0.960 | 0.191 |
| 30M (4) | XArray + 10-timestep chunks | **1.698** | 1.452 | 0.349 |
| 30M (4) | XArray + 1-timestep chunks | **6.702** | 6.104 | 1.583 |
| 30M (4) | CDO | **6.817** | 2.174 | 7.166 |
| 30M (4) | CDO + serial IO | **failed** | **failed** | **failed** |
| 30M (4) | NCL | **0.905** | 0.772 | 0.123 |
| 30M (4) | NCO | **0.946** | 0.826 | 0.109 |

| size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- |
| 185M (3) | XArray + no dask | **3.740** | 2.291 | 0.874 |
| 185M (3) | XArray + 100-timestep chunks | **1.665** | 3.067 | 2.602 |
| 185M (3) | XArray + 10-timestep chunks | **1.696** | 1.708 | 0.368 |
| 185M (3) | XArray + 1-timestep chunks | **6.787** | 6.183 | 1.790 |
| 185M (3) | CDO | **6.038** | 1.981 | 6.266 |
| 185M (3) | CDO + serial IO | **2.952** | 1.524 | 2.526 |
| 185M (3) | NCL | **4.689** | 4.029 | 0.639 |
| 185M (3) | NCO | **5.255** | 4.689 | 0.544 |

| size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- |
| 186M (4) | XArray + no dask | **1.863** | 2.202 | 0.624 |
| 186M (4) | XArray + 100-timestep chunks | **1.425** | 1.672 | 2.769 |
| 186M (4) | XArray + 10-timestep chunks | **1.694** | 1.648 | 0.373 |
| 186M (4) | XArray + 1-timestep chunks | **6.782** | 6.371 | 1.752 |
| 186M (4) | CDO | **6.205** | 2.465 | 6.716 |
| 186M (4) | CDO + serial IO | **2.587** | 1.678 | 1.926 |
| 186M (4) | NCL | **4.431** | 3.947 | 0.463 |
| 186M (4) | NCO | **5.245** | 4.697 | 0.528 |

| size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- |
| 742M (3) | XArray + no dask | **8.672** | 3.605 | 2.114 |
| 742M (3) | XArray + 100-timestep chunks | **2.989** | 4.895 | 8.799 |
| 742M (3) | XArray + 10-timestep chunks | **2.825** | 5.216 | 8.680 |
| 742M (3) | XArray + 1-timestep chunks | **6.884** | 7.258 | 1.830 |
| 742M (3) | CDO | **5.474** | 5.369 | 5.519 |
| 742M (3) | CDO + serial IO | **5.324** | 4.538 | 2.908 |
| 742M (3) | NCL | **18.336** | 15.825 | 2.369 |
| 742M (3) | NCO | **27.239** | 19.955 | 3.949 |

| size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- |
| 742M (4) | XArray + no dask | **5.116** | 3.147 | 1.959 |
| 742M (4) | XArray + 100-timestep chunks | **2.595** | 4.461 | 6.652 |
| 742M (4) | XArray + 10-timestep chunks | **2.827** | 4.571 | 7.981 |
| 742M (4) | XArray + 1-timestep chunks | **7.118** | 7.303 | 1.904 |
| 742M (4) | CDO | **5.753** | 4.078 | 6.213 |
| 742M (4) | CDO + serial IO | **3.679** | 3.267 | 2.638 |
| 742M (4) | NCL | **17.802** | 15.440 | 2.117 |
| 742M (4) | NCO | **21.913** | 18.955 | 2.813 |

| size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- |
| 2.9G (3) | XArray + no dask | **30.634** | 8.646 | 11.681 |
| 2.9G (3) | XArray + 100-timestep chunks | **11.532** | 21.696 | 19.811 |
| 2.9G (3) | XArray + 10-timestep chunks | **8.726** | 19.082 | 34.452 |
| 2.9G (3) | XArray + 1-timestep chunks | **8.751** | 12.496 | 2.395 |
| 2.9G (3) | CDO | **15.637** | 18.439 | 5.015 |
| 2.9G (3) | CDO + serial IO | **14.300** | 17.374 | 3.708 |
| 2.9G (3) | NCL | **85.473** | 64.158 | 16.353 |
| 2.9G (3) | NCO | **90.682** | 78.015 | 12.078 |

| size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- |
| 2.9G (4) | XArray + no dask | **16.961** | 6.424 | 8.868 |
| 2.9G (4) | XArray + 100-timestep chunks | **8.280** | 18.203 | 21.770 |
| 2.9G (4) | XArray + 10-timestep chunks | **7.468** | 16.122 | 27.476 |
| 2.9G (4) | XArray + 1-timestep chunks | **8.694** | 11.835 | 2.718 |
| 2.9G (4) | CDO | **9.099** | 12.188 | 5.711 |
| 2.9G (4) | CDO + serial IO | **6.503** | 11.323 | 3.273 |
| 2.9G (4) | NCL | **84.788** | 62.625 | 16.650 |
| 2.9G (4) | NCO | **89.145** | 76.988 | 11.485 |

### Linux server
To be added.

# Installation notes
## CDO for macOS
Was *exceedingly* difficult to get CDO compiled with threadsafe HDF5 like is the default case for Anaconda-downloaded versions on Linux. Used [this thread](https://code.mpimet.mpg.de/boards/2/topics/4630?r=5714#message-5714) for instructions. This required manually compiling HDF5 with custom `./configure` flags and custom prefix, then linking with homebrew using `brew link hdf5`.

Got frequent errors following user instructions, which disappeared by disabling `--with-pthread=/usr/local --enable-unsupported`. See discussion [here](http://hdf-forum.184993.n3.nabble.com/HDF5-parallel-and-threadsafe-td1701166.html) and Github reference to that discussion [here](https://github.com/conda-forge/hdf5-feedstock/pull/57).

I tried manually compiling the netcdf library but this seemed to make no difference -- the *provided* netcdf Homebrew library was the same.

<!-- In the end *could never* get the CDO to do NetCDF4 I/O parallelization without at least sporadic errors. However looks like *performance with thread locking is often faster anyway*. -->

