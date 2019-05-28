%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get fluxes with matlab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% First load data
if ~exist('filename')
  error('Filename undefined.')
end
% Coordinates
% dir_ = strsplit(filename, '/');
% dir_ = dir_{1}; % extract from the cell array
time = ncread(filename, 'time');
plev = ncread(filename, 'plev');
lon  = ncread(filename, 'lon');
lat  = ncread(filename, 'lat');
% Data
u = ncread(filename, 'u');
v = ncread(filename, 'v');
t = ncread(filename, 't');
% Attributes
% Must be read manually!
time_name  = ncreadatt(filename, 'time', 'long_name');
plev_name  = ncreadatt(filename, 'plev', 'long_name');
lat_name   = ncreadatt(filename, 'lat',  'long_name');
time_units = ncreadatt(filename, 'time', 'units');
plev_units = ncreadatt(filename, 'plev', 'units');
lat_units  = ncreadatt(filename, 'lat',  'units');

% Next perform calculations
% WARNING: Since MATLAB is column-major, get longitude on first dimension
nlon = length(lon);
nlat = length(lat);
nplev = length(plev);
ubar = mean(u, 1);
vbar = mean(v, 1);
tbar = mean(t, 1);
emf = mean((u - repmat(ubar, nlon, 1, 1, 1)).*(v - repmat(vbar, nlon, 1, 1, 1)), 1);
ehf = mean((t - repmat(tbar, nlon, 1, 1, 1)).*(t - repmat(tbar, nlon, 1, 1, 1)), 1);
emf = squeeze(emf);
ehf = squeeze(ehf);

% Save file
%{ outname = [dir_ 'matlab.nc']; %}
outname = 'out/matlab.nc';
if exist(outname, 'file')==2
  delete(outname);
end
% Create variables
nccreate(outname, 'time', 'Dimensions', {'time', Inf});
nccreate(outname, 'plev', 'Dimensions', {'plev', nplev});
nccreate(outname, 'lat',  'Dimensions', {'lat', nlat});
nccreate(outname, 'emf', 'Dimensions', {'lat', nlat, 'plev', nplev, 'time', Inf});
nccreate(outname, 'ehf', 'Dimensions', {'lat', nlat, 'plev', nplev, 'time', Inf});
% Write variables
ncwrite(outname, 'time', time);
ncwrite(outname, 'plev', plev);
ncwrite(outname, 'lat',  lat);
ncwrite(outname, 'emf',  emf);
ncwrite(outname, 'ehf',  ehf);
% Add attributes
ncwriteatt(outname, 'time', 'long_name', time_name);
ncwriteatt(outname, 'time', 'units',     time_units);
ncwriteatt(outname, 'plev', 'long_name', plev_name);
ncwriteatt(outname, 'plev', 'units',     plev_units);
ncwriteatt(outname, 'lat',  'long_name', lat_name);
ncwriteatt(outname, 'lat',  'units',     lat_units);
ncwriteatt(outname, 'emf',  'long_name', 'eddy momentum flux');
ncwriteatt(outname, 'emf',  'units',     'm**2/s**2');
ncwriteatt(outname, 'ehf',  'long_name', 'eddy heat flux');
ncwriteatt(outname, 'ehf',  'units',     'K*m/s');

