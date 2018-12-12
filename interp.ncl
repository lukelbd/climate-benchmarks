;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This function interpolates model level output to pressure levels
; Will probably be superceded by CDO because can be slow as fuck

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; First interpolate to pressure levels
notime = False
if (.not. notime) then readtime = toint(systemfunc("date +%s")) else readtime = 0 end if
print("Reading initial file and interpolating...")
if (.not. isvar("filename")) then 
    q = integertochar(34) ; a double quote; only way to put inside string! yuck.
    print("fatal:File name must be passed as variable 'filename' as follows: ncl 'filename="       + q + "foobar" + q + "' or " + q + "filename=\" + q + "foobar\" + q + q + ".")
    exit ; almost impossible to put double-quote in string
end if
f = addfile(filename,"r") ; read data from here, write later
; Get the sigma-coordinates and center-coordinates for interpolation
hyai   = f->hyai
hybi   = f->hybi
nedges = dimsizes(hyai) ; is 1D, so this is scalar
hyam = (hyai(0:nedges-2) + hyai(1:nedges-1))/2 ; the middle A coefs
hybm = (hybi(0:nedges-2) + hybi(1:nedges-1))/2 ; the middle B coefs
p0   = 101325. ; reference pressure
p0mb = 1013.25 ; in mb for function input
pouti = (hyai + hybi*p0) / 100 ; back to mb
poutm = (pouti(1:nedges-1) + pouti(0:nedges-2)) / 2
; Read other file data
slp      = f->slp
t_in     = f->t
u_in     = f->u
v_in     = f->v
z_in     = f->z
omega_in = f->omega
rdamp_in = f->rdamp
ndamp_in = f->ndamp
delete(f) ; delete to save memory
; vor_in   = f->vor
if t_in!0.ne."time" .or. t_in!1.ne."mlev" .or. t_in!2.ne."lat" .or. t_in!3.ne."lon"
    print("fatal:Unexpected dimension names or order. Should be time by mlev by lat by lon.")
    exit ; makes life easier to be able to make this assumption
end if
dimlev = 1 ; level dimension
dimlat = 2 ; latitude dimension
dimlon = 3 ; latitude dimension
if (.not. notime) then interptime = toint(systemfunc("date +%s")) else interptime = 0 end if
print("    - Time for NCL reading and setup: " + tostring(interptime-readtime) + "s.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Apply the interpolation to some variables
; Will then get other parameters
hyam_norm = hyam/p0 ; required for vint2hp function
t = vinth2p(t_in, hyam_norm, hybm, poutm, slp, 1, p0mb, 1, True)
  ; number-args is interp-type (1 for linear, 2 for log), 2nd one is not used
u     = vinth2p(u_in, hyam_norm, hybm, poutm, slp, 1, p0mb, 1, True)
v     = vinth2p(v_in, hyam_norm, hybm, poutm, slp, 1, p0mb, 1, True)
z     = vinth2p(z_in, hyam_norm, hybm, poutm, slp, 1, p0mb, 1, True)
omega = vinth2p(omega_in, hyam_norm, hybm, poutm, slp, 1, p0mb, 1, True)
rdamp = vinth2p(rdamp_in, hyam_norm, hybm, poutm, slp, 1, p0mb, 1, True)
ndamp = vinth2p(ndamp_in, hyam_norm, hybm, poutm, slp, 1, p0mb, 1, True)
; vor   = vinth2p(vor_in, hyam_norm, hybm, poutm, slp, 1, p0mb, 1, True)
copy_VarAtts(t_in,t)
copy_VarAtts(u_in,u)
copy_VarAtts(v_in,v)
copy_VarAtts(z_in,z)
copy_VarAtts(omega_in,omega)
copy_VarAtts(rdamp_in,rdamp)
copy_VarAtts(ndamp_in,ndamp)
rdamp@long_name = "dissipative heating from Rayleigh damping"
; copy_VarAtts(vor_in,vor)
; Get the pressure output
p = t&lev_p * 100 ; back to Pa for derivatives
if (.not. notime) then writetime = toint(systemfunc("date +%s")) else writetime = 0 end if
print("    - Time for NCL vint2hp: " + tostring(writetime-interptime) + "s.")
print("  * Total time for NCL interpolation: " + tostring(writetime-readtime) + "s.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Write interpolated data and newly calculated data
print("Writing to new output file...")
setfileoption("nc","Format","LargeFile") ; see: http://www.ncl.ucar.edu/FAQ/#file_io_004
  ; recommended for files >2GB, and my output file may be that big
o = addfile("ncl.nc","c")
o->slp = slp ; holdovers on single presure levels
o->omega = omega ; these variables were interpolated
o->rdamp = rdamp
o->ndamp = ndamp
o->t = t
o->u = u
o->v = v
o->z = z
delete(o)
if (.not. notime) then endtime = toint(systemfunc("date +%s")) else endtime = 0 end if
print("  * Time for NCL writing: " + tostring(endtime-writetime) + "s.")
print("TOTAL TIME ELAPSED: " + tostring(endtime-readtime) + "s.")
exit
