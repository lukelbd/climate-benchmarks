; This file gets potential temperature, dtheta/dp, static stability, and the 
; potential vorticity on model levels; copies the source code from pot_vort_hybrid
; and places it here directly, so we don't have to create/pass a giant list (which 
; may be slow for big dataset/may create copies, but not sure)
;
; How to find source code for some complex functions?
; * Go to base library directory in <which ncl>/../lib/ncarg/nclscript, and
;   run the comand "grep -r -l "func_name" ." -- this searches files recursively
; * Useful for many situations!
; Some notes on NCL performance:
; * The addfile() command is arbitrarily fast; probably just get header
;   information, no loading into memory yet.
; * Extracting variable names with f->t is slow, because this loads them
;   into memory.
; * Placing items into a list [/ item /] is not fast, as evidently NCL retains
;   pointers to the underlying objects, does not copy.
; * Indexing a list and saving it as a separate variable however IS slow; this
;   action seems to save the contents of that list as a new item. So it is to
;   be avoided when possible.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Isobaric coordinate version
; First interpolate to pressure levels
notime = False
if (.not. notime) then readtime = toint(systemfunc("date +%s")) else readtime = 0 end if
print("Reading initial file and interpolating...")
if (.not. isvar("filename")) then 
    q = integertochar(34) ; a double quote; only way to put inside string! yuck.
    print("fatal:File name must be passed as variable 'filename' as follows: ncl 'filename=" \
      + q + "foobar" + q + "' or " + q + "filename=\" + q + "foobar\" + q + q + ".")
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
slp      = f->slp
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
if (.not. notime) then calctime1 = toint(systemfunc("date +%s")) else calctime1 = 0 end if
print("    - Time for NCL interpolation: " + tostring(calctime1-interptime) + "s.")
print("  * Total time for NCL setup: " + tostring(calctime1-readtime) + "s.")
print("Getting other parameters...")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Get static stability using the source code procedure
; Stability === -T*d[log(theta)]/dp = -(T/theta)*d[theta]/dp
;   * original potential temperature function code is below
;   * npr is the dimension number of p corresponding to temp, 
;     gets passed to differencing procedures; if -1, ranks/sizes are same
; The Calculations
; pt    = t*(p0/conform(t,poutm,dimlev))^0.286 ; pot_temp procedure does this
p0    = 100000. ; default [units = Pa]
pt    = t*(p0/conform(t,p,dimlev))^0.286 ; pot_temp procedure does this
s = -(t/pt)*center_finite_diff_n(pt,p,False,0,dimlev) ; static stability
  ; * option 3 allows treating dimension as cyclic
  ; * option 4 is "not currently implemented"; ignore
  ; * option 5 is the derivative dimension
; Copy coordinates, fix units
s@long_name = "static stability"
s@units     = "K/Pa"       ; or "K-m-s2/kg"
pt@long_name = "potential temperature"
pt@units     = "K"       ; or "K-m-s2/kg"
copy_VarCoords(t,s)
copy_VarCoords(t,pt)
; dthdp@long_name = "vertical derivative of theta with pressure"
; dthdp@units     = s@units
; copy_VarCoords(t,dthdp)
if (.not. notime) then calctime2 = toint(systemfunc("date +%s")) else calctime2 = 0 end if
print("    - Time for NCL static stability: " + tostring(calctime2-calctime1) + "s.")
calctime4 = calctime2 ; cheap fix

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; BELOW: FORGET THIS STUFF, DON'T NEED TO GET PV ON PRESSURE LEVELS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ; Gradients used to convert vorticity to theta-coordinates
; ; Don't understand the math here but was copied from NCL function
; dudp = center_finite_diff_n(u,p,False,0,dimlev)
; dvdp = center_finite_diff_n(v,p,False,0,dimlev)
; dtdx = t
; dtdy = t
; gradsg(pt, dtdx, dtdy) ; args 2-3 are output
; dtdx@long_name = "longitudinal gradient (derivative)"
; dtdy@long_name = "latitudinal gradient (derivative)"
; dtdx@units = "K/m"
; dtdy@units = "K/m"
; ; vor = uv2vrG(u,v)
; calctime3 = toint(systemfunc("date +%s"))
; print("    - Time for NCL derivatives: " + tostring(calctime3-calctime2) + "s.")
;
; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ; Finally calculate the PV (requiring vorticity in theta coordinates)
; G = 9.80665  ; m/s, gravity at 45 deg lat used by the WMO
; W = 7.292e-5 ; 1/s, earth ang rotation
; rad = 4.*atan(1.)/180.
; if (typeof(lat).eq.typeof(vor)) then
;     f0 = 2.*W*sin(lat*rad) ; (1/s) ; coriolis parameter
; else
;     f0 = 2.*W*sin(tofloat(lat)*rad)
; end if
; pv = -G*((vor + conform(vor,f0,dimlat)) + (1/s)*(dvdp*dtdx - dudp*dtdy))*dthdp
; ; pv = -G*((vor+conform(vor,f0,dimlat))*dthdp - (dthdx*dvdp-dthdy*dudp)) ; for comparison, this is model version
; copy_VarCoords(t,pv)
; pv@long_name  = "potential vorticity"
; pv@short_name = "PV"
; pv@units      = "K m2/kg s"      ; common units
; calctime4 = toint(systemfunc("date +%s"))
; print("    - Time for NCL PV calculations: " + tostring(calctime4-calctime3) + "s.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Apply sign conventions: positive == poleward
; pv(time|:,lev_p|:,{lat|-90:0},lon|:) = -1.*pv(time|:,lev_p|:,{lat|-90:0},lon|:)
; vor(time|:,lev_p|:,{lat|-90:0},lon|:) = -1.*vor(time|:,lev_p|:,{lat|-90:0},lon|:)
; v(time|:,lev_p|:,{lat|-90:0},lon|:) = -1.*v(time|:,lev_p|:,{lat|-90:0},lon|:)
; f0(time|:,lev_p|:,{lat|-90:0},lon|:) = -1.*f0(time|:,lev_p|:,{lat|-90:0},lon|:)
; copy_VarCoords(t,f0)
; f0@long_name = "Coriolis force"
; f0@units = "1/s"
if (.not. notime) then writetime = toint(systemfunc("date +%s")) else writetime = 0 end if
print("    - Time for negating stuff in southern hemisphere: " + tostring(writetime-calctime4) + "s.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Write interpolated data and newly calculated data
print("  * Total time for NCL calculations: " + tostring(writetime-calctime1) + "s.")
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
o->s = s ; this one newly calculated
; o->vor = vor
; o->pt = pt ;  actually fuck that, don't save pt
; o->pv = pv ; positive == poleward
; f->dthdp = dthdp ; actually don't need this probably; just do it after-the-fact
delete(o)
if (.not. notime) then endtime = toint(systemfunc("date +%s")) else endtime = 0 end if
print("  * Time for NCL writing: " + tostring(endtime-writetime) + "s.")
print("TOTAL TIME ELAPSED: " + tostring(endtime-readtime) + "s.")
exit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Save in new file
; o = addfile("outNCL.nc","c") ; for placing new data; much faster than
;   ; adding to already massive filename (saving was even longer than computation)
; o->dthdp = dthdp
; o->pt = pt
; o->vor = vor ; positive == poleward
; o->pv = pv ; positive == poleward
; o->v = v ; positive == poleward
; o->s = s
; delete(o) ; will be saved to filesystem now
; Old method
; print("Time for NCL stuff: " + \
;   tostring(endtime-readtime) + "s (" + \
;   tostring(calctime-readtime) + "s for reading, " + \
;   tostring(writetime-calctime) + "s for computing, " + \
;   tostring(endtime-writetime) + "s for writing)")
; Isentropic slope
; f->slope = slope
; time = toint(substring(systemfunc("date +%s%3N"),-7,-1))
; slopes = grad_latlon_cfd(pt,pt&lat,pt&lon,True,False)
; slope = slopes[0] ; first is lat slope, second is lon slope
; print("Processing time for slope (ms): " + \
;   tostring(toint(substring(systemfunc("date +%s%3N"),-7,-1))-time))
; end
; exit
; status_exit(1) ; only reach here if something failed in begin-end loop

