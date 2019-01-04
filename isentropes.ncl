;------------------------------------------------------------------------------;
; Interpolate to isentropic levels
;------------------------------------------------------------------------------;
qq = integertochar(34) ; a double quote; only way to put inside string! yuck.
demo = "ncl 'filename=" + qq + "foobar" + qq + "' or " + qq + "filename=\" + qq + "foobar\" + qq + qq + "."
if (.not. isvar("filename")) then
    print("fatal:File name must be passed as variable 'filename' as follows: " + demo)
    exit ; almost impossible to put double-quote in string
end if
if (.not. isvar("outname")) then
    print("fatal:Output name must be passed as variable 'outname' as follows: " + demo)
    exit ; almost impossible to put double-quote in string
end if

; Read file
f = addfile(filename, "r") ; just read data from here
; Coordinates
time = f->time
plev = f->plev
lat = f->lat
lon = f->lon
time@axis = "T"
lat@axis = "Y"
lon@axis = "X"

; Get potential temp
; p0 = 1013.25
t = f->t
p0 = 1000.0 ; more common to make this the reference pressure
kappa = 0.286
theta = t*conform(t, (p0/plev)^kappa, (/1/)) ; calculate potential temperature
delete(t)

; The theta coordinates
; Should go in *same order* as pressure coordinates (pressure increasing,
; so theta decreasing)
; thlev = ispan(400,240,20)*1.0 ; specify desired isentropic levels
thlev = (/265, 275, 285, 300, 315, 330, 350, 370, 395, 430, 475, 530, 600, 700, 850/)*1.0
thlev = thlev(::-1)
thlev!0 = "thlev"
thlev&thlev = thlev ; this is apparently necessary
thlev@long_name = "potential temperature"
thlev@units = "K"
thlev@axis = "Z"

; Output file
; Add coordinates so they appear first in order
; TODO: Add coordinates and whatnot
; dir = str_split(filename, "/")
; dir := dir(0)
; system("rm " + dir + "/isentropes_ncl.nc 2>/dev/null") ; remove file
system("rm " + outname + " 2>/dev/null") ; remove file
o = addfile(outname, "c") ; create new file; don't want to read old values or anything
filedimdef(o, "time", -1, True) ; unlimited dimension
; print(time)
; print(lat)
; print(thlev)
o->time = time
o->thlev = thlev
o->lat = lat
o->lon = lon

; Interpolate
; Don't need to save temperature of course, but would like pressure
names = (/"p", "u", "v"/)
do i=0,dimsizes(names)-1
  ; Special consideration for p levs
  name = names(i)
  if (name .eq. "p") then
    var_orig = conform(f->t, plev, (/1/)) ; only dimension 1 matches
    var_orig@long_name = "pressure"
    var_orig@units = "hPa"
  else
    var_orig = f->$name$
  end if
  ; Interpolate to isentropes
  var = int2p_n(theta, var_orig, thlev, 0, 1)
  ; Dimensions
  var!0 = "time" ; name dimensions
  var!1 = "thlev"
  var!2 = "lat"
  var!3 = "lon"
  ; Coordinates
  var&time = time
  var&thlev = thlev
  var&lat = lat
  var&lon = lon
  copy_VarAtts(var_orig, var)
  ; Add to file
  o->$name$ = var
  delete(var)
  delete(var_orig)
end do

