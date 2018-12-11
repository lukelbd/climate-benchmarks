;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Get eddy fluxes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; First read file and variables
qq = integertochar(34) ; a double quote; only way to put inside string! yuck.
demo = "ncl 'filename=" + qq + "foobar" + qq + "' or " + qq + "filename=\" + qq + "foobar\" + qq + qq + "."
if (.not. isvar("filename")) then
    print("fatal:File name must be passed as variable 'filename' as follows: " + demo)
    exit ; almost impossible to put double-quote in string
end if
if (.not. isvar("large")) then
    print("fatal:Variable 'large' must be passed as follows: " + demo)
    exit ; almost impossible to put double-quote in string
end if
system("rm fluxes_ncl.nc 2>/dev/null") ; remove file
f = addfile(filename, "r") ; just read data from here
t = f->t
u = f->u
v = f->v

; Optionally turn on large file mode
if (toint(large) .eq. 1) then
  setfileoption("nc", "Format", "LargeFile") 
end if
o = addfile("fluxes_ncl.nc", "c") ; create new file; don't want to read old values or anything

; Calculate fluxes
; tbar := conform(t, dim_avg_n(t, dimlon), (/0, 1, 2/)
emf = dim_avg_n((u - conform(u, dim_avg_n(u, 3), (/0, 1, 2/))) \
              * (v - conform(v, dim_avg_n(v, 3), (/0, 1, 2/))), 3)
ehf = dim_avg_n((t - conform(t, dim_avg_n(t, 3), (/0, 1, 2/))) \
              * (v - conform(v, dim_avg_n(v, 3), (/0, 1, 2/))), 3)
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
