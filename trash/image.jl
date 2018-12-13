#!/usr/bin/env julia
# For pre-compiling into system image
# Folows suggestion here: https://stackoverflow.com/a/50996444/4970632
# This is ***bad idea*** for several reasons:
# * Adding to sysimage means we have to load some stupid
#   dinky little module every time julia runs.
# * Adding to sysimage ***will not*** result in speedup from
#   repeated function calls -- maybe have to also add all
#   dependencies too?
# * This ***also*** currently does not work on macOS; see github
#   issue: https://github.com/JuliaLang/julia/issues/28557
# * This is ***also*** no longer recomended in favor of just using
#   PackageCompiler; see gihub issue: https://github.com/JuliaLang/julia/pull/27629
using Libdl
Base.require(:ZonalStats)
