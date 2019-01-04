include("../fluxes.jl")
let M = Module() # Prevent this from putting anything into the Main namespace
    for m in Base.loaded_modules_array()
        Core.isdefined(M, nameof(m)) || Core.eval(M, Expr(:const, Expr(:(=), nameof(m), m)))
    end
    for n in names(Main)
        if Core.isdefined(Main, n) && isconst(Main, n)
            m = getfield(Main, n)
            m isa Module && (Core.isdefined(M, nameof(m)) || Core.eval(M, Expr(:const, Expr(:(=), nameof(m), m))))
        end
    end

Base.include(M, "precompiled.jl")
end # let

