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
f = addfile(filename, "r") ; just read data from here
o = addfile("fluxes_ncl.nc", "c") ; create new file
t = f->t
u = f->u
v = f->v

; Calculate fluxes
; tbar := conform(t, dim_avg_n(t, dimlon), (/0, 1, 2/)
emf = dim_avg_n((u - conform(u, dim_avg_n(u, 3), (/0, 1, 2/))) \
              * (v - conform(v, dim_avg_n(v, 3), (/0, 1, 2/))), 3)
ehf = dim_avg_n((t - conform(t, dim_avg_n(t, 3), (/0, 1, 2/))) \
              * (v - conform(v, dim_avg_n(v, 3), (/0, 1, 2/))), 3)
o->ehf = ehf
o->emf = emf

; Delete handles, i.e. force writing to disk
delete(f)
delete(o)
