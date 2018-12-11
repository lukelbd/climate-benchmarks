/*
  This file is part of CDO. CDO is a collection of Operators to
  manipulate and analyse Climate model Data.

  Copyright (C) 2003-2018 Uwe Schulzweida, <uwe.schulzweida AT mpimet.mpg.de>
  See COPYING file for copying and redistribution conditions.

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; version 2 of the License.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
*/

/*
   This module contains the following operators:

      Vertint    ml2pl           Model to pressure level interpolation
      Vertint    ml2hl           Model to height level interpolation
*/


#include <cdi.h>
#include "cdo.h"
#include "cdo_int.h"
#include "pstream.h"
#include "after_vertint.h"
#include "listarray.h"
#include "stdnametable.h"
#include "constants.h"


static
bool zaxis_is_hybrid(int zaxistype)
{
  return (zaxistype == ZAXIS_HYBRID || zaxistype == ZAXIS_HYBRID_HALF);
}

static
void change_hybrid_zaxis(int vlistID1, int vlistID2, int nvct, double *vct, int zaxisID2)
{
  int nzaxis = vlistNzaxis(vlistID1);
  for ( int iz = 0; iz < nzaxis; ++iz )
    {
      int zaxisID = vlistZaxis(vlistID1, iz);
      int nlevel  = zaxisInqSize(zaxisID);
      int zaxistype = zaxisInqType(zaxisID);

      if ( zaxis_is_hybrid(zaxistype) && nlevel > 1 )
	{
	  int nvct2 = zaxisInqVctSize(zaxisID);
          if ( nvct2 == nvct && memcmp(vct, zaxisInqVctPtr(zaxisID), nvct*sizeof(double)) == 0 )
            vlistChangeZaxisIndex(vlistID2, iz, zaxisID2);
	}
    }
}


void *Vertintml(void *argument)
{
  ModelMode mode(ModelMode::UNDEF);
  enum {func_pl, func_hl};
  enum {type_lin, type_log};
  int nrecs;
  int varID, levelID;
  bool sgeopot_needed = false;
  bool extrapolate = false;
  int sgeopotID = -1, geopotID = -1, tempID = -1, psID = -1, lnpsID = -1, gheightID = -1;
  // bool sortlevels = true;
  char paramstr[32];
  char varname[CDI_MAX_NAME], stdname[CDI_MAX_NAME];
  double minval, maxval;
  gribcode_t gribcodes;
  memset(&gribcodes, 0, sizeof(gribcode_t));
  lista_t *flista = lista_new(FLT_LISTA);

  cdoInitialize(argument);

  // clang-format off
  int ML2PL     = cdoOperatorAdd("ml2pl",     func_pl, type_lin, "pressure levels in pascal");
  int ML2PLX    = cdoOperatorAdd("ml2plx",    func_pl, type_lin, "pressure levels in pascal");
  int ML2HL     = cdoOperatorAdd("ml2hl",     func_hl, type_lin, "height levels in meter");
  int ML2HLX    = cdoOperatorAdd("ml2hlx",    func_hl, type_lin, "height levels in meter");
  int ML2PL_LP  = cdoOperatorAdd("ml2pl_lp",  func_pl, type_log, "pressure levels in pascal");
  int ML2PLX_LP = cdoOperatorAdd("ml2plx_lp", func_pl, type_log, "pressure levels in pascal");
  int ML2HL_LP  = cdoOperatorAdd("ml2hl_lp",  func_hl, type_log, "height levels in meter");
  int ML2HLX_LP = cdoOperatorAdd("ml2hlx_lp", func_hl, type_log, "height levels in meter");
  // clang-format on

  int operatorID = cdoOperatorID();
  bool useHightLevel = cdoOperatorF1(operatorID) == func_hl;
  bool useLogType = cdoOperatorF2(operatorID) == type_log;

  if ( operatorID == ML2PL || operatorID == ML2HL || operatorID == ML2PL_LP || operatorID == ML2HL_LP )
    {
      char *envstr = getenv("EXTRAPOLATE");
      if ( envstr && isdigit((int) envstr[0]) )
	{
          if ( atoi(envstr) == 1 ) extrapolate = true;
          if ( extrapolate )
            cdoPrint("Extrapolation of missing values enabled!");
	}
    }
  else if ( operatorID == ML2PLX || operatorID == ML2HLX || operatorID == ML2PLX_LP || operatorID == ML2HLX_LP )
    {
      extrapolate = true;
    }

  operatorInputArg(cdoOperatorEnter(operatorID));

  int nplev = 0;
  double *plev = NULL;
  if ( operatorArgc() == 1 && strcmp(operatorArgv()[0], "default") == 0 )
    {
      if ( useHightLevel )
        {
          double stdlev[] = { 10, 50, 100, 500, 1000, 5000, 10000, 15000, 20000, 25000, 30000 };
          nplev = sizeof(stdlev)/sizeof(*stdlev);
          plev  = (double *) Malloc(nplev*sizeof(double));
          for ( int i = 0; i < nplev; ++i ) plev[i] = stdlev[i];
        }
      else
        {
          double stdlev[] = {100000, 92500, 85000, 70000, 60000, 50000, 40000, 30000, 25000, 20000, 15000,
                             10000,  7000,  5000,  3000,  2000, 1000 };
          nplev = sizeof(stdlev)/sizeof(*stdlev);
          plev  = (double *) Malloc(nplev*sizeof(double));
          for ( int i = 0; i < nplev; ++i ) plev[i] = stdlev[i];
        }
    }
  else
    {
      nplev = args2flt_lista(operatorArgc(), operatorArgv(), flista);
      plev  = (double *) lista_dataptr(flista);
    }
  
  int streamID1 = pstreamOpenRead(cdoStreamName(0));

  int vlistID1 = pstreamInqVlist(streamID1);
  int vlistID2 = vlistDuplicate(vlistID1);

  int taxisID1 = vlistInqTaxis(vlistID1);
  int taxisID2 = taxisDuplicate(taxisID1);
  vlistDefTaxis(vlistID2, taxisID2);

  size_t gridsize = vlist_check_gridsize(vlistID1);

  int zaxistype = useHightLevel ? ZAXIS_HEIGHT : ZAXIS_PRESSURE;
  int zaxisIDp = zaxisCreate(zaxistype, nplev);
  zaxisDefLevels(zaxisIDp, plev);

  int nvct = 0;
  int zaxisIDh = -1;
  int nhlev = 0, nhlevf = 0, nhlevh = 0;
  double *vct = vlist_read_vct(vlistID1, &zaxisIDh, &nvct, &nhlev, &nhlevf, &nhlevh);

  change_hybrid_zaxis(vlistID1, vlistID2, nvct, vct, zaxisIDp);

  int psvarID = -1;
  bool linvertvct = false;
  if ( vct && nvct && nvct%2 == 0 )
    {
      psvarID = vlist_get_psvarid(vlistID1, zaxisIDh);

      int i;
      for ( i = nvct/2+1; i < nvct; i++ )
        if ( vct[i] > vct[i-1] ) break;
      if ( i == nvct ) linvertvct = true;
    }

  if ( cdoVerbose ) cdoPrint("linvertvct = %d", (int) linvertvct);

  if ( linvertvct )
    {
      std::vector<double> vctbuf(nvct);
      for ( int i = 0; i < nvct; ++i ) vctbuf[i] = vct[i];
      for ( int i = 0; i < nvct/2; i++ )
        {
          vct[nvct/2-1-i] = vctbuf[i];
          vct[nvct-1-i] = vctbuf[i+nvct/2];
        }
    }

  int nvars = vlistNvars(vlistID1);

  std::vector<bool> vars(nvars);
  std::vector<bool> varinterp(nvars);
  std::vector<size_t *> varnmiss(nvars);
  std::vector<double *> vardata1(nvars);
  std::vector<double *> vardata2(nvars);

  int maxlev = nhlevh > nplev ? nhlevh : nplev;

  std::vector<size_t> pnmiss;
  if ( !extrapolate ) pnmiss.resize(nplev);

  // check levels
  if ( zaxisIDh != -1 )
    {
      int nlev = zaxisInqSize(zaxisIDh);
      if ( nlev != nhlev ) cdoAbort("Internal error, wrong number of hybrid level!");
      std::vector<double> levels(nlev);
      cdoZaxisInqLevels(zaxisIDh, &levels[0]);

      for ( int ilev = 0; ilev < nlev; ++ilev )
	{
	  if ( (ilev+1) != (int)levels[ilev] )
	    {
	      //sortlevels = false;
	      break;
	    }
	}
    }

  std::vector<int> vert_index;
  std::vector<double> ps_prog, full_press, half_press;
  if ( zaxisIDh != -1 && gridsize > 0 )
    {
      vert_index.resize(gridsize*nplev);
      ps_prog.resize(gridsize);
      full_press.resize(gridsize*nhlevf);
      half_press.resize(gridsize*nhlevh);
    }
  else
    cdoWarning("No 3D variable with hybrid sigma pressure coordinate found!");

  if ( useHightLevel )
    {
      std::vector<double> phlev(nplev);
      height2pressure(&phlev[0], plev, nplev);

      if ( cdoVerbose )
	for ( int i = 0; i < nplev; ++i )
	  cdoPrint("level = %d   height = %g   pressure = %g", i+1, plev[i], phlev[i]);

      memcpy(plev, &phlev[0], nplev*sizeof(double));
    }

  if ( useLogType )
    for ( int k = 0; k < nplev; k++ ) plev[k] = log(plev[k]);

  bool useTable = false;
  for ( varID = 0; varID < nvars; varID++ )
    {
      int tableNum = tableInqNum(vlistInqVarTable(vlistID1, varID));
      if ( tableNum > 0 && tableNum != 255 )
	{
	  useTable = true;
	  break;
	}
    }

  if ( cdoVerbose && useTable ) cdoPrint("Using code tables!");

  for ( varID = 0; varID < nvars; varID++ )
    {
      int gridID   = vlistInqVarGrid(vlistID1, varID);
      int zaxisID  = vlistInqVarZaxis(vlistID1, varID);
      int zaxistype = zaxisInqType(zaxisID);
      // gridsize = gridInqSize(gridID);
      int nlevel   = zaxisInqSize(zaxisID);
      int instNum  = institutInqCenter(vlistInqVarInstitut(vlistID1, varID));
      int tableNum = tableInqNum(vlistInqVarTable(vlistID1, varID));

      int code     = vlistInqVarCode(vlistID1, varID);
      
      int param = vlistInqVarParam(vlistID1, varID);
      cdiParamToString(param, paramstr, sizeof(paramstr));
      int pnum, pcat, pdis;
      cdiDecodeParam(param, &pnum, &pcat, &pdis);
      if ( pdis >= 0 && pdis < 255 ) code = -1;

      if ( useTable )
	{
	  if ( tableNum == 2 )
	    {
	      mode = ModelMode::WMO;
	      wmo_gribcodes(&gribcodes);
	    }
	  else if ( tableNum == 128 || tableNum == 0 )
	    {
	      mode = ModelMode::ECHAM;
	      echam_gribcodes(&gribcodes);
	    }
      //  KNMI: HIRLAM model version 7.2 uses tableNum=1    (LAMH_D11*)
      //  KNMI: HARMONIE model version 36 uses tableNum=1   (grib*)   (opreational NWP version)
      //  KNMI: HARMONIE model version 38 uses tableNum=253 (grib,grib_md) and tableNum=1 (grib_sfx) (research version)
	  else if ( tableNum == 1 || tableNum == 253 )
	    {
	      mode = ModelMode::HIRLAM;
	      hirlam_harmonie_gribcodes(&gribcodes);
	    }
	}
      else
	{
	  mode = ModelMode::ECHAM;
	  echam_gribcodes(&gribcodes);
	}

      if ( cdoVerbose )
        {
          vlistInqVarName(vlistID1, varID, varname);
	  cdoPrint("Mode = %d  Center = %d TableNum =%d Code = %d Param = %s Varname = %s varID = %d",
                   mode, instNum, tableNum,  code, paramstr, varname, varID);
        }

      if ( code <= 0 || code == 255 )
	{
	  vlistInqVarName(vlistID1, varID, varname);
	  strtolower(varname);

	  vlistInqVarStdname(vlistID1, varID, stdname);
	  strtolower(stdname);

	  code = echamcode_from_stdname(stdname);

	  if ( code == -1 )
	    {
	      /*                                  ECHAM                            ECMWF       */
	      if      ( sgeopotID == -1 && (strcmp(varname, "geosp") == 0 || strcmp(varname, "z")    == 0) ) code = gribcodes.geopot;
	      else if ( tempID    == -1 && (strcmp(varname, "st")    == 0 || strcmp(varname, "t")    == 0) ) code = gribcodes.temp;
	      else if ( psID      == -1 && (strcmp(varname, "aps")   == 0 || strcmp(varname, "sp"  ) == 0) ) code = gribcodes.ps;
	      else if ( lnpsID    == -1 && (strcmp(varname, "lsp")   == 0 || strcmp(varname, "lnsp") == 0) ) code = gribcodes.lsp;
	      else if ( geopotID  == -1 && strcmp(stdname, "geopotential_full") == 0 ) code = gribcodes.geopot;
	      /* else if ( strcmp(varname, "geopoth") == 0 ) code = 156; */
	    }
	}

      if ( mode == ModelMode::ECHAM )
	{
	  if      ( code == gribcodes.geopot  && nlevel == 1      ) sgeopotID = varID;
	  else if ( code == gribcodes.geopot  && nlevel == nhlevf ) geopotID  = varID;
	  else if ( code == gribcodes.temp    && nlevel == nhlevf ) tempID    = varID;
	  else if ( code == gribcodes.ps      && nlevel == 1      ) psID      = varID;
	  else if ( code == gribcodes.lsp     && nlevel == 1      ) lnpsID    = varID;
	  else if ( code == gribcodes.gheight && nlevel == nhlevf ) gheightID = varID;
	}
      else if ( mode == ModelMode::WMO || mode == ModelMode::HIRLAM )
	{
	  if      ( code == gribcodes.geopot  && nlevel == 1      ) sgeopotID = varID;
	  else if ( code == gribcodes.geopot  && nlevel == nhlevf ) geopotID  = varID;
	  else if ( code == gribcodes.temp    && nlevel == nhlevf ) tempID    = varID;
	  else if ( code == gribcodes.ps      && nlevel == 1      ) psID      = varID;
	}

      if ( gridInqType(gridID) == GRID_SPECTRAL && zaxis_is_hybrid(zaxistype) )
	cdoAbort("Spectral data on model level unsupported!");

      if ( gridInqType(gridID) == GRID_SPECTRAL )
	cdoAbort("Spectral data unsupported!");

      if ( varID == gheightID )
	vardata1[varID] = (double*) Malloc(gridsize*(nlevel+1)*sizeof(double));
      else
	vardata1[varID] = (double*) Malloc(gridsize*nlevel*sizeof(double));

      /* if ( zaxis_is_hybrid(zaxistype) && zaxisIDh != -1 && nlevel == nhlev ) */
      if ( zaxisID == zaxisIDh ||
	   (zaxis_is_hybrid(zaxistype) && zaxisIDh != -1 && (nlevel == nhlevh || nlevel == nhlevf)) )
	{
	  varinterp[varID] = true;
	  vardata2[varID]  = (double*) Malloc(gridsize*nplev*sizeof(double));
	  varnmiss[varID]  = (size_t*) Malloc(maxlev*sizeof(size_t));
	  memset(varnmiss[varID], 0, maxlev*sizeof(size_t));
	}
      else
	{
	  if ( zaxis_is_hybrid(zaxistype) && zaxisIDh != -1 && nlevel > 1 )
            {
              vlistInqVarName(vlistID1, varID, varname);
              cdoWarning("Parameter %d has wrong number of levels, skipped! (param=%s nlevel=%d)",
                         varID+1, varname, nlevel);
            }

	  varinterp[varID] = false;
	  vardata2[varID]  = vardata1[varID];
	  varnmiss[varID]  = (size_t*) Malloc(nlevel*sizeof(size_t));
	}
    }

  if ( cdoVerbose )
    {
      cdoPrint("Found:");
      if ( tempID    != -1 ) cdoPrint("  %s -> %s", var_stdname(air_temperature), cdoVlistInqVarName(vlistID1, tempID, varname));
      if ( psID      != -1 ) cdoPrint("  %s -> %s", var_stdname(surface_air_pressure), cdoVlistInqVarName(vlistID1, psID, varname));
      if ( lnpsID    != -1 ) cdoPrint("  LOG(%s) -> %s", var_stdname(surface_air_pressure), cdoVlistInqVarName(vlistID1, lnpsID, varname));
      if ( sgeopotID != -1 ) cdoPrint("  %s -> %s", var_stdname(surface_geopotential), cdoVlistInqVarName(vlistID1, sgeopotID, varname));
      if ( geopotID  != -1 ) cdoPrint("  %s -> %s", var_stdname(geopotential), cdoVlistInqVarName(vlistID1, geopotID, varname));
      if ( gheightID != -1 ) cdoPrint("  %s -> %s", var_stdname(geopotential_height), cdoVlistInqVarName(vlistID1, gheightID, varname));
    }

  if ( tempID != -1 || gheightID != -1 ) sgeopot_needed = true;

  std::vector<double> sgeopot;
  if ( zaxisIDh != -1 && sgeopot_needed )
    {
      sgeopot.resize(gridsize);
      if ( sgeopotID == -1 )
	{
          if ( extrapolate )
            {
              if ( geopotID == -1 )
                cdoWarning("%s not found - set to zero!", var_stdname(surface_geopotential));
              else
                cdoPrint("%s not found - using bottom layer of %s!", var_stdname(surface_geopotential), var_stdname(geopotential));
            }
	  memset(&sgeopot[0], 0, gridsize*sizeof(double));
	}
    }

  if ( zaxisIDh != -1 && gheightID != -1 && tempID == -1 )
    cdoAbort("Temperature not found, needed for vertical interpolation of geopotheight!");

  int presID = lnpsID;
  if ( psvarID != -1 ) presID = psvarID;

  if ( zaxisIDh != -1 && presID == -1 )
    {
      if ( psID == -1 )
	cdoAbort("%s not found!", var_stdname(surface_air_pressure));
      else
	presID = psID;
    }

  if ( cdoVerbose )
    {
      vlistInqVarName(vlistID1, presID, varname);
      if ( presID == lnpsID )
        cdoPrint("using LOG(%s) from %s", var_stdname(surface_air_pressure), varname);
      else
        cdoPrint("using %s from %s", var_stdname(surface_air_pressure), varname);
    }

  // check VCT
  if ( zaxisIDh != -1 )
    {
      double suma = 0, sumb = 0;
      for ( int i = 0; i < nhlevh; i++ )
        {
          suma += vct[i];
          sumb += vct[i+nhlevh];
        }
      if ( !(suma>0&&sumb>0) ) cdoWarning("VCT is empty!");
    }

  int streamID2 = pstreamOpenWrite(cdoStreamName(1), cdoFiletype());
  pstreamDefVlist(streamID2, vlistID2);

  int tsID = 0;
  while ( (nrecs = pstreamInqTimestep(streamID1, tsID)) )
    {
      for ( varID = 0; varID < nvars; ++varID ) vars[varID] = false;

      taxisCopyTimestep(taxisID2, taxisID1);
      pstreamDefTimestep(streamID2, tsID);

      for ( int recID = 0; recID < nrecs; recID++ )
	{
	  pstreamInqRecord(streamID1, &varID, &levelID);
	  //gridsize = gridInqSize(vlistInqVarGrid(vlistID1, varID));
	  int zaxisID  = vlistInqVarZaxis(vlistID1, varID);
	  int nlevel   = zaxisInqSize(zaxisID);
	  /*
	  if ( sortlevels && zaxisIDh != -1 && zaxisID == zaxisIDh && nlevel == nhlev )
	    {
	      levelID = (int) (zaxisInqLevel(zaxisIDh, levelID)-1);
	      printf("levelID %d\n", levelID);
	    }
	  */
          if ( linvertvct && zaxisIDh != -1 && zaxisID == zaxisIDh )
            levelID = nlevel-1-levelID;

	  size_t offset  = gridsize*levelID;
	  double *single = vardata1[varID] + offset;

	  pstreamReadRecord(streamID1, single, &varnmiss[varID][levelID]);
	  vars[varID] = true;
	}

      if ( zaxisIDh != -1 )
	{
	  if ( sgeopot_needed )
	    {
	      if ( sgeopotID != -1 )
		memcpy(&sgeopot[0], vardata1[sgeopotID], gridsize*sizeof(double));
	      else if ( geopotID != -1 )
		memcpy(&sgeopot[0], vardata1[geopotID]+gridsize*(nhlevf-1), gridsize*sizeof(double));

	      /* check range of surface geopot */
	      if ( extrapolate && (sgeopotID != -1 || geopotID != -1) )
		{
		  minmaxval(gridsize, &sgeopot[0], NULL, &minval, &maxval);
		  if ( minval < MIN_FIS || maxval > MAX_FIS )
		    cdoWarning("Surface geopotential out of range (min=%g max=%g) [timestep:%d]!", minval, maxval, tsID+1);
		  if ( gridsize > 1 && minval >= 0 && maxval <= 9000 )
		    cdoWarning("Surface geopotential has an unexpected range (min=%g max=%g) [timestep:%d]!", minval, maxval, tsID+1);
		}
	    }

	  if ( presID == lnpsID )
	    for ( size_t i = 0; i < gridsize; i++ ) ps_prog[i] = exp(vardata1[lnpsID][i]);
	  else if ( presID != -1 )
	    memcpy(&ps_prog[0], vardata1[presID], gridsize*sizeof(double));

	  /* check range of ps_prog */
	  minmaxval(gridsize, &ps_prog[0], NULL, &minval, &maxval);
	  if ( minval < MIN_PS || maxval > MAX_PS )
	    cdoWarning("Surface pressure out of range (min=%g max=%g) [timestep:%d]!", minval, maxval, tsID+1);


	  presh(&full_press[0], &half_press[0], vct, &ps_prog[0], nhlevf, gridsize);

	  if ( useLogType )
	    {
	      for ( size_t i = 0; i < gridsize; i++ ) ps_prog[i] = log(ps_prog[i]);
	      for ( size_t ki = 0; ki < nhlevh*gridsize; ki++ ) half_press[ki] = log(half_press[ki]);
	      for ( size_t ki = 0; ki < nhlevf*gridsize; ki++ ) full_press[ki] = log(full_press[ki]);
	    }

	  genind(&vert_index[0], plev, &full_press[0], gridsize, nplev, nhlevf);

	  if ( !extrapolate ) genindmiss(&vert_index[0], plev, gridsize, nplev, &ps_prog[0], &pnmiss[0]);
	}

      for ( varID = 0; varID < nvars; varID++ )
	{
	  if ( vars[varID] )
	    {
	      int zaxisID  = vlistInqVarZaxis(vlistID1, varID);
	      int nlevel   = zaxisInqSize(zaxisID);
	      double missval = vlistInqVarMissval(vlistID1, varID);
	      if ( varinterp[varID] )
		{
		  /*
		  if ( nlevel == nhlevh )
		    {
		      int i, k;
		      double *vl1, *vl2;

		      for ( int k = 1; k < nlevel; k++ )
			{
			  vl1  = vardata1[varID] + gridsize*(k-1);
			  vl2  = vardata1[varID] + gridsize*(k);
			  for ( int i = 0; i < gridsize; i++ )
			    vl1[i] = 0.5*(vl1[i] + vl2[i]);
			}
		      
		      nlevel = nhlevf;
		    }
		  */
                  double *hyb_press = NULL;
		  if      ( nlevel == nhlevf ) hyb_press = &full_press[0];
		  else if ( nlevel == nhlevh ) hyb_press = &half_press[0];
		  else
		    {
                      vlistInqVarName(vlistID1, varID, varname);
		      cdoAbort("Number of hybrid level differ from full/half level (param=%s)!", varname);
		    }

		  for ( levelID = 0; levelID < nlevel; levelID++ )
		    {
		      if ( varnmiss[varID][levelID] )
			cdoAbort("Missing values unsupported for this operator!");
		    }

		  if ( varID == tempID )
		    {
		      if ( nlevel == nhlevh )
			cdoAbort("Temperature on half level unsupported!");

		      if ( useLogType && extrapolate )
			cdoAbort("Log. extrapolation of temperature unsupported!");

		      interp_T(&sgeopot[0], vardata1[varID], vardata2[varID],
			       &full_press[0], &half_press[0], &vert_index[0],
			       plev, nplev, gridsize, nlevel, missval);
		    }
		  else if ( varID == gheightID )
		    {
		      for ( size_t i = 0; i < gridsize; ++i )
			vardata1[varID][gridsize*nlevel+i] = sgeopot[i]/PlanetGrav;

		      interp_Z(&sgeopot[0], vardata1[varID], vardata2[varID],
			       &full_press[0], &half_press[0], &vert_index[0], vardata1[tempID],
			       plev, nplev, gridsize, nlevel, missval);
		    }
		  else
		    {
		      interp_X(vardata1[varID], vardata2[varID], hyb_press,
			       &vert_index[0], plev, nplev, gridsize, nlevel, missval);
		    }
		  
		  if ( !extrapolate ) memcpy(varnmiss[varID], &pnmiss[0], nplev*sizeof(size_t));
		}
	    }
	}

      for ( varID = 0; varID < nvars; varID++ )
	{
	  if ( vars[varID] )
	    {
	      int nlevel = zaxisInqSize(vlistInqVarZaxis(vlistID2, varID));
	      for ( levelID = 0; levelID < nlevel; levelID++ )
		{
		  //gridsize = gridInqSize(vlistInqVarGrid(vlistID2, varID));
		  size_t offset  = gridsize*levelID;
		  double *single = vardata2[varID] + offset;
		  pstreamDefRecord(streamID2, varID, levelID);
		  pstreamWriteRecord(streamID2, single, varnmiss[varID][levelID]);
		}
	    }
	}

      tsID++;
    }

  pstreamClose(streamID2);
  pstreamClose(streamID1);

  for ( varID = 0; varID < nvars; varID++ )
    {
      Free(varnmiss[varID]);
      Free(vardata1[varID]);
      if ( varinterp[varID] ) Free(vardata2[varID]);
    }

  if ( vct ) Free(vct);

  lista_destroy(flista);

  cdoFinish();

  return 0;
}
