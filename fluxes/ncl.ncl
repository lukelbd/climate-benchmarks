; Get eddy fluxes
qq = integertochar(34)  ; a double quote -- this is the only way to put inside string!
demo = "ncl 'filename=" + qq + "foobar" + qq + "' or " + qq + "filename=\" + qq + "foobar\" + qq + qq + "."
if (.not. isvar("filename")) then
    print("fatal:File name must be passed as variable 'filename' as follows: " + demo)
    exit
end if
if (.not. isvar("large")) then
    print("fatal:Variable 'large' must be passed as follows: " + demo)
    exit
end if

; Read file and variables
f = addfile(filename, "r")
t = f->t
u = f->u
v = f->v

; Turn on large file mode
if (toint(large) .eq. 1) then
  setfileoption("nc", "Format", "LargeFile") 
end if
out = "out/ncl.nc"
system("rm " + out + " 2>/dev/null")  ; remove existing file
o = addfile(out, "c")

; Calculate fluxes
emf = dim_avg_n( \
  (u - conform(u, dim_avg_n(u, 3), (/0, 1, 2/))) \
  * (v - conform(v, dim_avg_n(v, 3), (/0, 1, 2/))), \
  3 \
)
ehf = dim_avg_n( \
  (t - conform(t, dim_avg_n(t, 3), (/0, 1, 2/))) \
  * (v - conform(v, dim_avg_n(v, 3), (/0, 1, 2/))), \
  3 \
)

; Save fluxes
avevar = v(:,:,:,0) ; possibly needs to be its own var
copy_VarCoords(avevar, emf)
copy_VarCoords(avevar, ehf)
emf@long_name = "eddy momentum flux"
emf@units = "m**2/s**2"
ehf@long_name = "eddy heat flux"
ehf@units = "K*m/s"
o->ehf = ehf
o->emf = emf

; Delete handles, i.e. force writing to disk
delete(f)
delete(o)
