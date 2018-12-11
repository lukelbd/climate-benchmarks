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

| size (version) | name | real | user | sys |
| --- | --- | --- | --- | --- |
| 7.4M (3) | XArray + no Dask | 0m1.028s | 0m1.027s | 0m0.181s |
| 7.4M (3) | XArray + 1-timestep Dask chunk | 0m6.526s | 0m5.669s | 0m1.530s |
| 7.4M (3) | XArray + 10-timestep Dask chunk | 0m1.624s | 0m1.343s | 0m0.324s |
| 7.4M (3) | NCL | 0m0.397s | 0m0.322s | 0m0.068s |
| 7.4M (3) | CDO | 0m6.293s | 0m1.008s | 0m6.378s |
| 7.4M (3) | NCO | 0m0.237s | 0m0.198s | 0m0.030s |
| 7.6M (4) | XArray + no Dask | 0m1.070s | 0m1.086s | 0m0.183s |
| 7.6M (4) | XArray + 1-timestep Dask chunk | 0m6.675s | 0m6.127s | 0m1.557s |
| 7.6M (4) | XArray + 10-timestep Dask chunk | 0m1.627s | 0m1.400s | 0m0.321s |
| 7.6M (4) | NCL | 0m0.428s | 0m0.345s | 0m0.075s |
| 7.6M (4) | CDO | 0m6.874s | 0m2.164s | 0m7.163s |
| 7.6M (4) | NCO | 0m0.316s | 0m0.259s | 0m0.041s |
| 30M (3) | XArray + no Dask | 0m1.122s | 0m1.481s | 0m0.298s |
| 30M (3) | XArray + 1-timestep Dask chunk | 0m6.575s | 0m5.817s | 0m1.579s |
| 30M (3) | XArray + 10-timestep Dask chunk | 0m1.579s | 0m1.368s | 0m0.322s |
| 30M (3) | NCL | 0m0.932s | 0m0.792s | 0m0.131s |
| 30M (3) | CDO | 0m6.259s | 0m1.142s | 0m6.381s |
| 30M (3) | NCO | 0m0.887s | 0m0.782s | 0m0.095s |
| 30M (4) | XArray + no Dask | 0m1.147s | 0m1.563s | 0m0.247s |

# Installation notes
## CDO for macOS
Was *exceedingly* difficult to get CDO compiled with threadsafe HDF5 like is the default case for Anaconda-downloaded versions on Linux. Used [this thread](https://code.mpimet.mpg.de/boards/2/topics/4630?r=5714#message-5714) for instructions. This required manually compiling HDF5 with custom `./configure` flags and custom prefix, then linking with homebrew using `brew link hdf5`.

Turned out this version worked, but only *without* the `--with-pthread=/usr/local --enable-unsupported` lines -- when trying to compile with both MPI and threadsafe support, got errors. See discussion [here](http://hdf-forum.184993.n3.nabble.com/HDF5-parallel-and-threadsafe-td1701166.html) and Github reference to that discussion [here](https://github.com/conda-forge/hdf5-feedstock/pull/57).

I tried manually compiling the netcdf library but this seemed to make no difference -- can just use *provided* netcdf and NCO libraries.

