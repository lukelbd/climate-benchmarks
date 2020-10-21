; Take slice with NCL indexing
qq = integertochar(34) ; a double quote; only way to put inside string! yuck.
demo = "ncl 'filename=" + qq + "foobar" + qq + "' or " + qq + "filename=\" + qq + "foobar\" + qq + qq + "."
if (.not. isvar("filename")) then
    print("fatal:File name must be passed as variable 'filename' as follows: " + demo)
    exit ; almost impossible to put double-quote in string
end if
if (.not. isvar("nmax")) then
    print("fatal:Variable 'nmax' must be passed as follows: " + demo)
    exit ; almost impossible to put double-quote in string
end if

; Read file
f = addfile(filename, "r")
out = "out/slice_ncl.nc"
system("rm " + out + " 2>/dev/null")
o = addfile(out, "c")
o->t = f->t(0:nmax-1, :, :, :)
o->u = f->u(0:nmax-1, :, :, :)
o->v = f->v(0:nmax-1, :, :, :)

; Delete handles to force writing to disk
delete(f)
delete(o)
