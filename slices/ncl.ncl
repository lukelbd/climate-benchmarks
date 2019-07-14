;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Get slice
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; First read file and variables
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
f = addfile(filename, "r") ; just read data from here

; Optionally turn on large file mode
; dir = str_split(filename, "/")
; dir := dir(0)
; out = dir + "/slice_ncl.nc"
out = "out/slice_ncl.nc"
system("rm " + out + " 2>/dev/null") ; remove file
o = addfile(out, "c") ; create new file; don't want to read old values or anything
o->t = f->t(0:nmax-1,:,:,:)
o->u = f->u(0:nmax-1,:,:,:)
o->v = f->v(0:nmax-1,:,:,:)

; Delete handles, i.e. force writing to disk
delete(f)
delete(o)
