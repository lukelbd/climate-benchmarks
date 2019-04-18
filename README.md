<!--
Installation
------------

It was *exceedingly* difficult to get CDO compiled with threadsafe HDF5 like is the default case for Anaconda-downloaded versions on Linux. I used [this thread](https://code.mpimet.mpg.de/boards/2/topics/4630?r=5714#message-5714) for instructions. This required manually compiling HDF5 with custom `./configure` flags and custom prefix, then linking with homebrew using `brew link hdf5`.

I got frequent errors following user instructions, which disappeared by disabling `--with-pthread=/usr/local --enable-unsupported`. See discussion [here](http://hdf-forum.184993.n3.nabble.com/HDF5-parallel-and-threadsafe-td1701166.html) and Github reference to that discussion [here](https://github.com/conda-forge/hdf5-feedstock/pull/57). I tried manually compiling the netcdf library but this seemed to make no difference -- the *provided* netcdf Homebrew library was the same.

In the end *could never* get the CDO to do NetCDF4 I/O parallelization without at least sporadic errors. However looks like *performance with thread locking is often faster anyway*.
-->

# Atmospheric science data analysis benchmarks
This repo provides benchmarks for common 
data analysis tasks in atmospheric science
accomplished with several different tools:

* Fortran
* Climate Data Operators (CDO)
* NCAR Command Language (NCL)
* NetCDF Operators (NCO)
* Julia
* Python
* MATLAB

This repo is a work-in-progress. Below are some notes,
an overview of the languages and tools tested, and some (possibly
contentious) opinions on how the languages compare.
<!-- languages. -->
<!-- some general notes. -->

## NetCDF versions
All benchmarks described here
involve reading and writing to the NetCDF file format, used for storage of multi-dimensional
scientific datasets. There are two major versions of this file
format: version 3 and version 4.
I observed two notable performance differences when
sample data was saved to version 3 of the NetCDF format instead of version 4:
<!-- the NetCDF3 and NetCDF4 versions of the sample data: -->

* With NetCDF3 files, CDO responds **less favorably** to thread-safe disk IO locking (the `-L` flag). It tended to speed things up for smaller datasets (over-optimization?) then slow things down for larger datasets, but **more-so** for NetCDF3 files.
* For NetCDF3 files, non-dask XArray datasets (i.e. datasets loaded with `chunks=None`) performed somewhat **worse** compared to datasets loaded from NetCDF4 files, and the effect was more pronounced for large datasets. However with Dask chunking, the NetCDF4 speed improvements were marginal -- even approaching 2GB file sizes (**7s** vs **9s** for the fluxes benchmark).

Since most large general circulation models still produce the older-format NetCDF3
files, only results for these datasets are shown.
But anyway, the differences weren't that huge.

## Fortran
Fortran is the only low-level, high-performance language tested in these benchmarks. It may
seem like an anachronism to outsiders, but there are [perfectly valid](http://moreisdifferent.com/2015/07/16/why-physicsts-still-use-fortran/) reasons scientists still prefer it. The most important of these is that a very powerful parallelization tool, MPI, can be used only with C++ and Fortran. And of these two, although it is certainly not the right tool
for software engineers and object-oriented programming,
Fortran is the more array-friendly and easier-to-learn language (its name, after all, is an acronym for Formula Translator). Also, it is generally just as fast as C++. Fortran 
is used for high-performance numerical algorithms and geophysical models.
<!-- -- for example, -->
<!-- models used to predict the weather -->
<!-- on a day-to-day basis and help us understand future climate change hazards. -->
<!-- the Coupled Model Intercomparison Project. -->
<!-- communicated by the Intergovernmental Panel on Climate Change (IPCC). -->

## NetCDF Operators (NCO)
The NetCDF operators are a group of command-line tools developed by Unidata for
working with NetCDF files, released alongside the original file format.
Since it was released by the creators,
one might think it would be the efficient tool for manipulating
NetCDF data. But it turns out most other, secondary tools are generally
more efficient.
<!-- , since it was released by the creators. -->

For the NCO benchmarks, the most-used tool was `ncap2`. Though a variety of other tools
are available for various analysis tasks,
like `ncks` (NetCDF kitchen sink), `ncbo` (NetCDF binary operator),
`ncwa` (NetCDF weighted averager),
`ncrcat` (NetCDF record concatenator), `ncecat` (NetCDF ensemble concatenator), `ncra` (NetCDF record averager), `nces` (NetCDF ensemble statistics), `ncremap` (NetCDF remaper), `ncflint` (NetCDF file interpolator), and `ncclimo` (NetCDF climatology generator). 
The documentation can be found [here](http://nco.sourceforge.net/).

## Climate Data Operators (CDO)
CDO has generally similar functionality to the NetCDF operators
and places strict requirements on the dataset format (e.g. all variables must have 2 horizontal "spatial" dimensions, an optional height dimension, and an optional time dimension). Although I'm sure these restrictions are necessary, they can sometimes be frustrating -- and anyway, CDO may, at first glance, seem redundant. 
But it offers **enormous** speed
improvements over NCO, is more flexible, and is generally easier and more intuitive to use. "Operator chaining" is the most notable improvement over NCO. The documentation can be found [here](https://code.mpimet.mpg.de/projects/cdo/wiki/Cdo#Documentation).

The newest versions of `cdo` have zonal-statistics functions available
to the `expr` subcommand. These functions
are used in `fluxes.cdo`, but
the equivalent calculation in older versions of `cdo`
requires an ugly workaround with lots of operator chaining (see
`misc/fluxes_ineff.cdo`). It turned out this
workaround was **much** slower than calculating fluxes with
`expr`. This matches my experience in general: CDO is great for
**simple** tasks, but for **complex**, highly chained commands, it can quickly grow
less efficient than much older, but more powerful and expressive, tools.
<!-- With an older, verbose CDO algorithm for getting fluxes (see `trash/fluxes_ineff.cdo`), CDO was **much much slower**, and the problem was exacerbated by adding levels. -->

## NCAR Command Language (NCL)
NCAR command language is a favorite among many atmospheric scientists, myself included.
It is certainly not the fastest language -- in fact, it is usually the slowest after the
native NetCDF operators -- but it is relatively easy-to-use, concise, and provides specialized tools for atmospheric scientists. Just like everything in MATLAB is
an array, and everything in Python is an "object", everything in NCL is a
dataset with named dimensions. But with the recent [end-of-life announcement](https://www.ncl.ucar.edu/Document/Pivot_to_Python/NCL_Pivot_to_Python_Report_and_Roadmap.pdf), it
may be advisable to move away from NCL over the coming years. The NCL documentation can
be found [here](https://www.ncl.ucar.edu/Document/).

Note that using the NCL feature `setfileoption("nc", "Format", "LargeFile")` made **neglibile** difference in final wall-clock time. Also note there are no options to improve large file processing, and the official recommendation is to split files up by level or time. See [this NCL talk post](https://www.ncl.ucar.edu/Support/talk_archives/2011/2636.html) and [this stackoverflow post](https://stackoverflow.com/questions/44474507/read-large-netcdf-data-by-ncl).

## MATLAB
MATLAB (MATrix LABoratory) is a tried-and-tested, proprietary, high-level data
science language -- the language of choice for engineers and scientists over
the last few decades. But with the emergence of the free, open-source
programming language "Python" as a scientific computing
workhorse, scientists have been slowly making the switch.
And with the **massive** amount of collaborative work
put into scientific computing Python
packages, Python has become (for the most part) a superset
of MATLAB, and seems to have
overtaken MATLAB in terms of
performance and speed.
<!-- resource, and the massive amount of  -->

I have access to MATLAB 2014a through a license from my university.
Note that even without the Java Virtual Manager (`-nojvm`)
and without the display (`-nodisplay`), MATLAB scripts run from the command line
are delayed by up to several seconds!
On my machine, it takes about 9 seconds to start MATLAB
every time a MATLAB script is run from the command line.
Thus running a series of MATLAB commands
on small files for small tasks becomes quickly impractical.
To give MATLAB the best chance, the times shown in the benchmarks below omit
the startup time.

## Python
Python is the high-level, expressive, programming language that is
quickly becoming the favorite of academics and data scientists everywhere.
Almost all scientific computing Python tools are based around the 
array manipulation package ["numpy"](http://www.numpy.org/).
There are two of these tools (at least two well-known ones) for reading NetCDF files:
[netCDF4](http://unidata.github.io/netcdf4-python/netCDF4/index.html) (which confusingly,
also works with version 3 of the file format), and [XArray](http://xarray.pydata.org/en/stable/). The former is rather low-level and fast, the latter is high-level, powerful,
and very flexible. XArray is also closely integrated with [Dask](https://dask.org/),
which supports extremely high-performance array computations with
hidden parallelization and super fancy algorithms designed by some super smart people.
Dask is truly a game-changer, and with the proper "[chunking](http://xarray.pydata.org/en/stable/dask.html)" it can result in code as fast as compiled, serially executed
Fortran code.
<!-- parallel multi-dimensional array computations. -->

## Julia
Julia is the new kid on the block, and tries to combine the best-of-both worlds from MATLAB (e.g. the everything-is-an-array syntax) and Python.
The Julia workflow is quite different -- you **cannot** simply make repeated calls to some script on the command line, because this means the JIT compilation kicks in every time, and becomes a huge bottleneck. Instead you have two options:

1. Run things from a persistent notebook or REPL, making **repeated calls** to some function so that the JIT compilation can speed things up. For example, a simple julia script that iterates over 1000 NetCDF files and performs the same operation on them.
2. Compile to machine executable with [`PackageCompiler`](https://github.com/JuliaLang/PackageCompiler.jl) and a "snoop" script, which lets you call a binary executable. This is perhaps how numerical models written in Julia can be used. Since it is faster, unless stated otherwise, this is the approach used for benchmarks.
<!-- To give Julia the best shot -->
<!-- , each benchmark provides two times: -->
<!-- 1. Time from running a Julia script in an **interactive shell**, after running it with a test file so the JIT compilation has already kicked in. Obviously this was tedious to do systematically, with multiple files and multiple benchmarks, but I thought it was necessary. -->
<!-- 2. Time from running "pre-compiled" Julia code with the [`PackageCompiler`](https://github.com/JuliaLang/PackageCompiler.jl) utility. This has two drawbacks, being that pre-compiling Julia code is quite slow even for very simple programs, and the resulting machine code takes up massive amounts of space relative to the complexity of the program (since all dependencies must be compiled to machine code too). But, it does result in slightly faster code. -->

Julia is advertised for its raw speed in numerical computations.
But for simple data analysis tasks, and especially when working with large arrays,
Julia seems to perform no better than MATLAB or python. With the `NetCDF.jl` package (which mimics MATLAB's NetCDF utilities), Julia is somewhat slower than MATLAB. With the `NCDatasets.jl` package (which mimics the python xarray package), Julia is somewhat slower than python.
For me, there doesn't seem to be a compelling reason to switch from either of these tools to Julia yet. Perhaps as these packages are updated and I/O performance is improved,
there will be one day.
<!-- Perhaps it will fully replace MATLAB one day, but -->
<!-- evidently there is a lot of work to do. -->

# Eddy flux benchmark
For this benchmark, we use an assortment of languages to
calculate and save eddy fluxes of heat and momentum to new NetCDF files.

## Macbook: 60 level, 200 timesteps
The sampe data was generated using
```
for reso in 20 10 7.5 5 3 2 1.5; do ./datagen $reso; done
```
where the numbers refer to the latitude, longitude grid spacing.
Climate Data Operators (CDO) are the clear winner here, followed closely by MATLAB, Fortran, and python in the same pack, depending on the file size.
For files smaller than 100MB though, the differences are never that large, and
the NCAR Command Language (NCL) and NetCDF Operators (NCO) appear to be acceptable choices.


<img src="fluxes.png" width="800">


| nlat | size | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 6 | 20M | Fortran | **0.412** | 0.032 | 0.093 |
| 6 | 20M | Julia NCDatasets (compiled) | **2.222** | 0.957 | 0.388 |
| 6 | 20M | Julia NetCDF (compiled) | **1.709** | 0.857 | 0.342 |
| 6 | 20M | MATLAB (no startup) | **0.874589** | | |
| 6 | 20M | Python netCDF4 | **0.684** | 0.514 | 0.174 |
| 6 | 20M | XArray without dask | **1.581** | 1.440 | 0.364 |
| 6 | 20M | XArray 20 step chunks | **1.043** | 0.895 | 0.212 |
| 6 | 20M | XArray 2 step chunks | **1.681** | 1.380 | 0.386 |
| 6 | 20M | CDO | **0.359** | 0.223 | 0.077 |
| 6 | 20M | NCL | **1.027** | 0.536 | 0.182 |
| 6 | 20M | NCO | **0.414** | 0.291 | 0.096 |

| nlat | size | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 9 | 44M | Fortran | **0.648** | 0.067 | 0.131 |
| 9 | 44M | Julia NCDatasets (compiled) | **3.996** | 1.410 | 0.536 |
| 9 | 44M | Julia NetCDF (compiled) | **2.146** | 1.117 | 0.482 |
| 9 | 44M | MATLAB (no startup) | **0.844445** | | |
| 9 | 44M | Python netCDF4 | **0.519** | 0.462 | 0.148 |
| 9 | 44M | XArray without dask | **1.462** | 1.619 | 0.380 |
| 9 | 44M | XArray 20 step chunks | **1.011** | 0.908 | 0.211 |
| 9 | 44M | XArray 2 step chunks | **1.686** | 1.459 | 0.394 |
| 9 | 44M | CDO | **0.348** | 0.255 | 0.042 |
| 9 | 44M | NCL | **0.984** | 0.668 | 0.156 |
| 9 | 44M | NCO | **0.708** | 0.584 | 0.103 |

| nlat | size | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 12 | 79M | Fortran | **0.900** | 0.095 | 0.147 |
| 12 | 79M | Julia NCDatasets (compiled) | **1.240** | 1.229 | 0.294 |
| 12 | 79M | Julia NetCDF (compiled) | **1.124** | 1.014 | 0.301 |
| 12 | 79M | MATLAB (no startup) | **0.832950** | | |
| 12 | 79M | Python netCDF4 | **0.487** | 0.593 | 0.163 |
| 12 | 79M | XArray without dask | **1.237** | 1.836 | 0.371 |
| 12 | 79M | XArray 20 step chunks | **1.394** | 2.951 | 1.476 |
| 12 | 79M | XArray 2 step chunks | **1.891** | 1.723 | 0.460 |
| 12 | 79M | CDO | **0.463** | 0.380 | 0.060 |
| 12 | 79M | NCL | **1.584** | 1.318 | 0.237 |
| 12 | 79M | NCO | **1.457** | 1.235 | 0.205 |

| nlat | size | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 18 | 178M | Fortran | **1.680** | 0.210 | 0.292 |
| 18 | 178M | Julia NCDatasets (compiled) | **1.906** | 1.754 | 0.430 |
| 18 | 178M | Julia NetCDF (compiled) | **1.275** | 1.160 | 0.412 |
| 18 | 178M | MATLAB (no startup) | **1.035359** | | |
| 18 | 178M | Python netCDF4 | **0.897** | 1.075 | 0.311 |
| 18 | 178M | XArray without dask | **1.773** | 3.441 | 0.749 |
| 18 | 178M | XArray 20 step chunks | **1.856** | 3.238 | 1.997 |
| 18 | 178M | XArray 2 step chunks | **2.162** | 2.216 | 0.539 |
| 18 | 178M | CDO | **0.546** | 0.455 | 0.081 |
| 18 | 178M | NCL | **2.885** | 2.520 | 0.340 |
| 18 | 178M | NCO | **3.135** | 2.648 | 0.436 |

| nlat | size | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 24 | 316M | Fortran | **2.308** | 0.392 | 0.478 |
| 24 | 316M | Julia NCDatasets (compiled) | **3.704** | 2.974 | 0.860 |
| 24 | 316M | Julia NetCDF (compiled) | **2.278** | 1.723 | 0.767 |
| 24 | 316M | MATLAB (no startup) | **1.481880** | | |
| 24 | 316M | Python netCDF4 | **1.453** | 1.662 | 0.546 |
| 24 | 316M | XArray without dask | **2.795** | 3.996 | 1.078 |
| 24 | 316M | XArray 20 step chunks | **2.145** | 3.698 | 4.149 |
| 24 | 316M | XArray 2 step chunks | **2.251** | 2.567 | 0.556 |
| 24 | 316M | CDO | **0.747** | 0.611 | 0.123 |
| 24 | 316M | NCL | **4.817** | 4.270 | 0.508 |
| 24 | 316M | NCO | **9.181** | 7.648 | 1.102 |

| nlat | size | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 36 | 712M | Fortran | **4.450** | 0.938 | 1.083 |
| 36 | 712M | Julia NCDatasets (compiled) | **6.172** | 4.936 | 1.492 |
| 36 | 712M | Julia NetCDF (compiled) | **2.794** | 1.967 | 1.100 |
| 36 | 712M | MATLAB (no startup) | **2.326823** | | |
| 36 | 712M | Python netCDF4 | **3.113** | 3.147 | 1.219 |
| 36 | 712M | XArray without dask | **5.456** | 6.207 | 2.593 |
| 36 | 712M | XArray 20 step chunks | **3.666** | 8.665 | 8.227 |
| 36 | 712M | XArray 2 step chunks | **4.483** | 10.800 | 12.163 |
| 36 | 712M | CDO | **1.664** | 1.314 | 0.328 |
| 36 | 712M | NCL | **10.999** | 9.785 | 1.158 |
| 36 | 712M | NCO | **18.269** | 14.321 | 3.833 |

| nlat | size | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 55 | 1.6G | Fortran | **8.071** | 2.425 | 2.314 |
| 55 | 1.6G | Julia NCDatasets (compiled) | **20.073** | 14.212 | 4.716 |
| 55 | 1.6G | Julia NetCDF (compiled) | **8.240** | 4.287 | 3.375 |
| 55 | 1.6G | MATLAB (no startup) | **7.455892** | | |
| 55 | 1.6G | Python netCDF4 | **10.642** | 7.812 | 4.192 |
| 55 | 1.6G | XArray without dask | **17.062** | 17.028 | 9.560 |
| 55 | 1.6G | XArray 20 step chunks | **9.965** | 26.998 | 14.036 |
| 55 | 1.6G | XArray 2 step chunks | **10.427** | 26.158 | 22.686 |
| 55 | 1.6G | CDO | **4.665** | 3.608 | 0.966 |
| 55 | 1.6G | NCL | **32.438** | 28.809 | 3.240 |
| 55 | 1.6G | NCO | **54.133** | 42.519 | 11.281 |

| nlat | size | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 72 | 2.8G | Fortran | **14.963** | 6.026 | 5.135 |
| 72 | 2.8G | Julia NCDatasets (compiled) | **37.576** | 25.329 | 10.248 |
| 72 | 2.8G | Julia NetCDF (compiled) | **12.322** | 6.231 | 5.258 |
| 72 | 2.8G | MATLAB (no startup) | **13.746387** | | |
| 72 | 2.8G | Python netCDF4 | **17.333** | 11.324 | 6.656 |
| 72 | 2.8G | XArray without dask | **30.254** | 22.150 | 15.532 |
| 72 | 2.8G | XArray 20 step chunks | **14.922** | 37.465 | 18.101 |
| 72 | 2.8G | XArray 2 step chunks | **16.600** | 39.978 | 35.207 |
| 72 | 2.8G | CDO | **10.453** | 8.520 | 1.730 |
| 72 | 2.8G | NCL | **57.910** | 51.708 | 5.616 |
| 72 | 2.8G | NCO | **92.308** | 72.226 | 19.400 |

| nlat | size | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 90 | 4.3G | Fortran | **20.076** | 9.240 | 7.763 |
| 90 | 4.3G | Julia NCDatasets (compiled) | **64.605** | 39.012 | 20.661 |
| 90 | 4.3G | Julia NetCDF (compiled) | **20.591** | 9.386 | 8.761 |
| 90 | 4.3G | MATLAB (no startup) | **28.569324** | | |
| 90 | 4.3G | Python netCDF4 | **52.359** | 24.858 | 26.405 |
| 90 | 4.3G | XArray without dask | **82.653** | 46.488 | 70.870 |
| 90 | 4.3G | XArray 20 step chunks | **28.300** | 58.946 | 43.493 |
| 90 | 4.3G | XArray 2 step chunks | **23.411** | 63.666 | 60.116 |
| 90 | 4.3G | CDO | **13.967** | 11.346 | 2.411 |
| 90 | 4.3G | NCL | **90.036** | 71.161 | 14.306 |
| 90 | 4.3G | NCO | **121.905** | 94.340 | 25.913 |

<!-- | 9 | 22M (3) | Interactive Julia | **0.196** -->
<!-- | 18 | 89M (3) | Interactive Julia | **1.972** -->
<!-- | 24 | 158M (3) | Interactive Julia | **2.819** -->
<!-- | 36 | 356M (3) | Interactive Julia | **5.546** -->
<!-- | 60 | 989M (3) | Interactive Julia | **13.861** -->
<!-- | 90 | 2.2G (3) | Interactive Julia | **39.636** -->
<!-- | 129 | 3.9G (3) | Interactive Julia | **63.701** -->

## Cheyenne interactive node: 60 level, 200 timesteps
This time, the benchmark was run on a Cheyenne HPC compute cluster interactive node, which is a shared resource consisting of approximately 72 cores.

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

<!-- # Hybrid-to-pressure interpolation benchmarks -->
<!-- I have yet to formalize this benchmark, but performed some tests for my research. -->
<!-- I used 400-timestep T42L40 resolution files from a dry dynamical core model. -->
<!--  -->
<!-- * NCL interpolation: **70s total** -->
<!-- * CDO interpolation: **216s total** -->
<!--   - **30s pre-processing** (probably due to inefficiency of overwriting original ncfile with file that deletes coordinates) -->
<!--   - **94s for setting things up** (because we have to write surface geopotential to same massive file, instead of declaring as separate variable in NCL) -->
<!--   - **122s actual interpolation** (with lots of warnings) -->
<!--  -->
<!-- This was a surprising result! And it supports my hypothesis that CDO is great -->
<!-- for simple data analysis tasks, but unsuited for complex tasks. -->
<!-- [> Alternative explanation is that, <] -->
<!-- Perhaps formal, language-based tools like python and NCl -->
<!-- are more appropriate for parallel computation because the data is loaded into memory once, -->
<!-- then the calculations can proceed quickly. Another issue could have been the necessary -->
<!-- disk reads (5) for the CDO script, compared to just 1 NCL disk read. -->

# Isobars-to-isentropes interpolation benchmark
There are only two obvious tools for interpolating between isobars and isentropes: NCL, and python using the MetPy package. This benchmark compares them.

## Macbook: 60 level, 200 timesteps
The sample data was generated using
```
for reso in 20 10 7.5 5 3 2 1.5; do ./datagen $reso; done
```
where the numbers refer to the latitude/longitude grid spacing.
This time, NCL was the clear winner! The MetPy script was also raising
a bunch of strange errors when it ran. Evidently, the kinks in the MetPy
algorithm haven't been ironed out yet.

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 6 | 20M (3) | NCL | **0.745** | 0.417 | 0.132 |
| 6 | 20M (3) | NCL Parallel | **0.811** | 3.243 | 0.920 |
| 6 | 20M (3) | MetPy | **2.825** | 2.819 | 0.636 |
| 6 | 20M (3) | MetPy + Dask | **1.731** | 2.756 | 0.387 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 9 | 45M (3) | NCL | **0.990** | 0.765 | 0.170 |
| 9 | 45M (3) | NCL Parallel | **0.861** | 3.913 | 1.035 |
| 9 | 45M (3) | MetPy | **2.364** | 4.140 | 0.683 |
| 9 | 45M (3) | MetPy + Dask | **2.223** | 4.022 | 0.618 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 12 | 80M (3) | NCL | **1.618** | 1.199 | 0.277 |
| 12 | 80M (3) | NCL Parallel | **1.084** | 4.966 | 1.207 |
| 12 | 80M (3) | MetPy | **3.080** | 5.032 | 0.920 |
| 12 | 80M (3) | MetPy + Dask | **2.849** | 3.612 | 2.792 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 18 | 178M (3) | NCL | **3.400** | 2.435 | 0.438 |
| 18 | 178M (3) | NCL Parallel | **1.554** | 7.015 | 1.523 |
| 18 | 178M (3) | MetPy | **5.057** | 8.213 | 1.868 |
| 18 | 178M (3) | MetPy + Dask | **5.211** | 6.587 | 4.888 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 24 | 317M (3) | NCL | **5.652** | 4.409 | 0.646 |
| 24 | 317M (3) | NCL Parallel | **2.271** | 10.226 | 2.011 |
| 24 | 317M (3) | MetPy | **8.629** | 10.519 | 3.121 |
| 24 | 317M (3) | MetPy + Dask | **8.983** | 8.930 | 7.203 |

| nlat | size (version) | name | real (s) | user (s) | sys (s) |
| --- | --- | --- | --- | --- | --- |
| 36 | 712M (3) | NCL | **12.459** | 9.842 | 1.321 |
| 36 | 712M (3) | NCL Parallel | **5.028** | 19.334 | 3.810 |
| 36 | 712M (3) | MetPy | **19.194** | 19.144 | 7.176 |
| 36 | 712M (3) | MetPy + Dask | **18.281** | 15.292 | 11.703 |

