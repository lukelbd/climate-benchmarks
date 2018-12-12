;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This function interpolates model level output to pressure levels
; Turns out this is *much faster* than CDO interpolation in certain
; situations
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Function declaration
; See this page: https://www.ncl.ucar.edu/Support/talk_archives/2011/1363.html
notime = False
if .not. notime then time = toint(systemfunc("date +%s")) else time = 0 end if
origtime = time
newtime = time
; notime = False
undef("message")
procedure message(message:string)
begin ; procedures don't have to return values like functions
  if .not. notime then newtime = toint(systemfunc("date +%s")) else newtime = 0 end if
  print(message + ": " + tostring(newtime-time) + "s.")
  time = newtime ; overwrite in global scope
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; First read the file
print("Reading initial file and interpolating...")
q = integertochar(34) ; a double quote; only way to put inside string! yuck.
demo =  "ncl 'filename=" + q + "foobar" + q + "' or " + q + "filename=\" + q + "foobar\" + q + q + "."
if .not. isvar("filename") then 
  print("fatal:File name must be passed as variable 'filename' as follows: " + demo)
  exit ; almost impossible to put double-quote in string
end if
if .not. isvar("outfile") then 
  print("fatal:Output file must be passed as variable 'outfile' as follows: " + demo)
  exit ; almost impossible to put double-quote in string
end if
f = addfile(filename, "r") ; read data from here, write later
; Get the sigma-coordinates and center-coordinates for interpolation
hyai   = f->hyai
hybi   = f->hybi
nedges = dimsizes(hyai) ; is 1D, so this is scalar
hyam = (hyai(0:nedges-2) + hyai(1:nedges-1))/2 ; the middle A coefs
hybm = (hybi(0:nedges-2) + hybi(1:nedges-1))/2 ; the middle B coefs
p0   = 101325. ; reference pressure
p0mb = 1013.25 ; in mb for function input
pouti = (hyai + hybi*p0) / 100. ; back to mb
poutm = (pouti(1:nedges-1) + pouti(0:nedges-2)) / 2.
; Parameters needed for interpolation
slp = f->slp ; sea level pressure in mb
; Parameters needed for extrapolation
hyam_norm = hyam/p0 ; required for vint2hp function
tbot = f->t(:,0,:,:) ; temperature at bottom level
zbot = f->t(0,0,:,:) ; geopotential everywhere
zbot(:,:) = 0 ; zero surface geopotential
; if var!0.ne."time" .or. var!1.ne."mlev" .or. var!2.ne."lat" .or. var!3.ne."lon"
;   print("fatal:Unexpected dimension names or order. Should be time by mlev by lat by lon.")
;   exit ; makes life easier to be able to make this assumption
; end if
; Print message
message("  * Time for NCL reading and setup")
; Add bounds to file
; This replicates behavior of genlevelbounds in CDO
pouti_edges = (/pouti(0:nedges-2), pouti(1:nedges-1)/)
pouti_edges!0 = "bnds"
pouti_edges!1 = "plev"
pouti_edges&plev = poutm ; the central levels
pouti_edges := pouti_edges(plev|:,bnds|:)
; ; This screws up CDO interpretation of grid, so don't bother
; ; Next the longitude
; lonb = f->lonb
; nlonb = dimsizes(lonb)
; lonb_edges = (/lonb(0:nlonb-2), lonb(1:nlonb-1)/)
; lonb_edges!0 = "bnds"
; lonb_edges!1 = "lon"
; lonb_edges&lon = f->lon
; lonb_edges := lonb_edges(lon|:,bnds|:)
; copy_VarAtts(lonb_edges&lon, lonb_edges)
; ; And the latitude
; latb = f->latb
; nlatb = dimsizes(f->latb)
; latb_edges = (/f->latb(0:nlatb-2), latb(1:nlatb-1)/)
; latb_edges!0 = "bnds"
; latb_edges!1 = "lat"
; latb_edges&lat = f->lat
; latb_edges := latb_edges(lat|:,bnds|:)
; copy_VarAtts(latb_edges&lat, latb_edges)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Apply the interpolation to variables, and write to new file
; * vinth2p_ecmwf produced smoother/nicer results than vinth2p for temperature
;   and geopotential; much more believable
; * this may be what CDO results are supposed to look like
print("Interpolating variables in " + q + filename + q + "...")
varnames = getfilevarnames(f)
dimnames = getvardims(f) ; will work on file handle passed to it
setfileoption("nc", "Format", "LargeFile") 
  ; see: http://www.ncl.ucar.edu/FAQ/#file_io_004
  ; recommended for files >2GB, and my output file may be that big
o = addfile(outfile, "c")
o->plev_bnds = pouti_edges ; will rename later and add atributes
do i=0,dimsizes(varnames)-1
  varname := varnames(i) ; wrap in array to strip attributes
  if .not. any(varname .eq. dimnames) then
    ;---------------------------------------------------------------------------
    ; Get variable and verify some stuff
    var := f->$varname$ ; load from old file
    if dimsizes(dimsizes(var)) .eq. 1 then
      print("Variable " + q + varname + q + " is a coordinate.")
      continue
    else if .not. any("mlev" .eq. getvardims(var)) then
      print("Variable " + q + varname + q + " does not have pressure levels.")
      o->$varname$ = var
      continue
    end if end if
    if varname .eq. "t" then
      varflag = 1 ; special treatment of temp
    else if varname .eq. "z" then
      varflag = -1 ; special treatment of geopotential
    else
      varflag = 0
    end if end if
    ;---------------------------------------------------------------------------
    ; Interpolate the variable and save it
    var_out = vinth2p_ecmwf(var, hyam_norm, hybm, poutm, slp, 1, p0mb, 1, True, varflag, tbot, zbot)
    var_out!1 = "plev" ; rename dimension; simple as that
    copy_VarAtts(var, var_out)
    o->$varname$ = var_out ; write to new file
    message(" * Time for NCL interpolation of " + q + varname + q)
    delete(var_out)
  end if
end do

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Exit message
delete(f)
delete(o)
print("TOTAL TIME ELAPSED: " + tostring(newtime-origtime) + "s.")
exit
