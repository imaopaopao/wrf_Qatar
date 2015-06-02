; Clint Aegerter
; Plots several variables for the real-time WRF run

;  LOAD FUNCTIONS AND PROCEDURES
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"

begin

; Basic resources
res = True
res@MainTitle = "Real-Time WRF"
res@Footer = False
mpres = True
pltres = True

; Plot type
type  = "X11"
;type = "png"
;type = "ps"
;type = "pdf
wks   = gsn_open_wks(type, "WRF_UpperAir")
gsn_define_colormap(wks,"BlAqGrYeOrReVi200")

; WRF output directory
dir       = "/shared/aerosol/gshared/wrf_forcast/14021500/wrfout/"
filelist  = "2014_wrfout_d01"
str       = "string"
filename  = asciiread("/work/jwang7/caegerter/WRF_Plot/" + filelist, -1, str)
nfile     = dimsizes(filename)

; Pressure levels
pressure_levels = (/925., 850., 700., 500., 300., 250., 200./)
nlevels         = dimsizes(pressure_levels)

; Map settings
;minlat = 38.0
;maxlat = 44.0
;minlon = -105.0
;maxlon = -95.0

; Map resources
mpres@mpGridAndLimbOn              = False
mpres@mpProjection                 = "CylindricalEquidistant"
mpres@mpGeophysicalLineColor       = "Black"
mpres@mpNationalLineColor          = "Black"
mpres@mpUSStateLineColor           = "Black"
mpres@mpGeophysicalLineThicknessF  = 3.0
mpres@mpNationalLineThicknessF     = 3.0
mpres@mpUSStateLineThicknessF      = 3.0
mpres@mpOutlineBoundarySets        = "AllBoundaries"
mpres@mpDataBaseVersion            = "Ncarg4_1"
mpres@mpDataSetName                = "Earth..2"
mpres@gsnMaximize                  = True
mpres@mpFillDrawOrder              = "PreDraw"
mpres@tmXBLabelsOn                 = False
mpres@tmYLLabelsOn                 = False
mpres@tmXBMajorLengthF             = 0.0
mpres@tmYLMajorLengthF             = 0.0

plot   = new(1, graphic)

; Do loop to read and plot each file
do i = 0, nfile-1
 a = addfile(dir + filename(i) + ".nc", "r")
 time = charactertostring(a->Times(0, :))
 res@TimeLabel = time
 lat  = a->XLAT
 lon  = a->XLONG
  
 ; Temperature
 tc   = wrf_user_getvar(a, "tc", 0)
 tc2  = wrf_user_getvar(a, "T2", 0)  ; T2 in Kelvin
 tc2  = tc2-273.16                   ; T2 in C
 tf2  = 1.8*tc2+32.0                 ; convert to Fahrenheit
  tf2@description = "2m Temperature"
  tf2@units = "~F34~0~F~F"
  tf2@lat2d = a->XLAT(0,:,:)
  tf2@lon2d = a->XLONG(0,:,:)

 ; Dewpoint temperature
 td2  = wrf_user_getvar(a, "td2", 0)
 tdf2 = 1.8*td2+32.0
  tdf2@description = "Surface Dewpoint"
  tdf2@units = "~F34~0~F~F"
  tdf2@lat2d = a->XLAT(0,:,:)
  tdf2@lon2d = a->XLONG(0,:,:)

 ; Wind
 u   = wrf_user_getvar(a, "ua", 0)
 v   = wrf_user_getvar(a, "va", 0)
 u10 = wrf_user_getvar(a, "U10", 0)
 v10 = wrf_user_getvar(a, "V10", 0)
 u10 = u10*1.94386 ; convert to knots
 v10 = v10*1.94386
  u10@units = "kts"
  v10@units = "kts"
  u10@lat2d = a->XLAT(0,:,:)
  v10@lon2d = a->XLONG(0,:,:)

 ; Pressure
 p   = wrf_user_getvar(a, "pressure", 0)
 slp = wrf_user_getvar(a, "slp", 0) ; sea-level pressure
 wrf_smooth_2d(slp, 3)
  slp@lat2d = a->XLAT(0,:,:)
  slp@lon2d = a->XLONG(0,:,:)
 
 ; Height
 z = wrf_user_getvar(a, "z", 0)

 ; Relative Humidity
 rh = wrf_user_getvar(a, "rh", 0)

 ; Precip
 rain_exp = wrf_user_getvar(a, "RAINNC", 0)
 rain_con = wrf_user_getvar(a, "RAINC", 0)
 rain_tot = rain_exp + rain_con
 if ( i .ne. 0) then
  rain_tot_3hr             = rain_tot - rain_tot_save
  rain_tot_3hr             = rain_tot * 0.0393701 ; convert to inches
  rain_tot_3hr@description = "3-hr Accumulated Precip"
  rain_tot_3hr@units       = "in" 
 end if
 ; Save precip values for use in next loop
 rain_exp_save = rain_exp
 rain_con_save = rain_con
 rain_tot_save = rain_tot

 ; Simulated Reflectivity
 dbz = wrf_user_getvar(a, "dbz", 0)

 ; mCAPE, mCIN, LCL, LFC, CAPE, CIN
 cape2d = wrf_user_getvar(a, "cape_2d", 0)
 cape3d = wrf_user_getvar(a, "cape_3d", 0)
 mcape  = cape2d(0,:,:)
 mcin   = cape2d(1,:,:)
 lcl    = cape2d(2,:,:)
 lfc    = cape2d(3,:,:)
 cape   = cape3d(0,:,:,:)
 sbcape = cape(0,:,:)
 cin    = cape3d(1,:,:,:)
 sbcin  = cin(0,:,:)
 wrf_smooth_2d(cape(0,:,:), 3)
  mcape@description  = "mCAPE"
  mcin@description   = "mCIN"
  lcl@description    = "LCL"
  lfc@description    = "LFC"
  sbcape@description = "SBCAPE"
  sbcin@description  = "SBCIN"
  mcape@units        = "J kg~S~-1~N~"
  mcin@units         = "J kg~S~-1~N~"
;  lcl@units   	     = "m"
  lfc@units          = "m"
  sbcape@units       = "J kg~S~-1~N~"
  sbcin@units        = "J kg~S~-1~N~"
;  mcape@lat2d        = a->XLAT(0,:,:)
;  mcape@lon2d        = a->XLONG(0,:,:)
;  mcin@lat2d         = a->XLAT(0,:,:)
;  mcin@lon2d         = a->XLONG(0,:,:)
;  lcl@lat2d          = a->XLAT(0,:,:)
;  lcl@lon2d          = a->XLONG(0,:,:)
;  lfc@lat2d          = a->XLAT(0,:,:)
;  lfc@lon2d          = a->XLONG(0,:,:)
;  sbcape@lat2d       = a->XLAT(0,:,:)
;  sbcape@lon2d       = a->XLONG(0,:,:)
;  sbcin@lat2d        = a->XLAT(0,:,:)
;  sbcin@lon2d        = a->XLONG(0,:,:)

  
 ; SURFACE VARIABLE PLOTTING OPTIONS ==========================================
 ; Plotting options for surface temperature
 opts                   = res
 opts@cnFillOn          = True
 opts@ContourParameters = (/-30., 110., 5./)
 opts@pmLabelBarWidthF  = 0.875
 opts@pmLabelBarHeightF = 0.2
; opts@cnLineLabelsOn = True
; opts@cnLineLabelBackgroundColor = "Grey"
 contour_tf2            = wrf_contour(a, wks, tf2, opts)
 delete(opts)

 ; Plotting options for wind
 opts            = res
 opts@FieldTitle = "Wind"
 opts@NumVectors = 30
 vector          = wrf_vector(a, wks, u10, v10, opts)
 delete(opts)

 ; Plotting options for sea-level pressure
 opts                                = res
 opts@cnLineColor                    = "Black"
 opts@cnHighLabelsOn                 = True
 opts@cnLowLabelsOn                  = True
 opts@ContourParameters              = (/900., 1100., 4./)
 opts@cnLineLabelBackgroundColor     = "White"
 opts@cnLabelDrawOrder               = "PostDraw"
 opts@cnLineThicknessF               = 2.0
 opts@cnInfoLabelOn                  = False
 contour_slp                         = wrf_contour(a, wks, slp, opts)
 delete(opts)

 ; Plotting options for surface dewpoint
; opts                   = res
; opts@cnFillOn          = True
; opts@ContourParameters = (/-30., 80., 5./)
; opts@pmLabelBarWidthF  = 0.875
; opts@pmLabelBarHeightF = 0.2
; contour_tdf2           = wrf_contour(a, wks, tdf2, opts)
; delete(opts)

 ; Plotting options for SBCAPE
; opts                   = res
; opts@cnFillOn          = True
; opts@ContourParameters = (/200., 5000., 200./)
; opts@pmLabelBarWidthF  = 0.875
; opts@pmLabelBarHeightF = 0.2
; contour_sbcape         = wrf_contour(a, wks, sbcape, opts)
; delete(opts)

 ; Plotting options for SBCIN
; opts                   = res
; opts@cnFillOn          = True
; opts@ContourParameters = (/25., 200., 25./)
; opts@pmLabelBarWidthF  = 0.875
; opts@pmLabelBarHeightF = 0.2
; contour_sbcin          = wrf_contour(a, wks, sbcin, opts)
; delete(opts)

 ; Plotting options for MCAPE
; opts                   = res
; opts@cnFillOn          = True
; opts@ContourParameters = (/200., 5000., 200./)
; opts@pmLabelBarWidthF  = 0.875
; opts@pmLabelBarHeightF = 0.2
; contour_mcape          = wrf_contour(a, wks, mcape, opts)
; delete(opts)

 ; Plotting options for MCIN
; opts                   = res
; opts@cnFillOn          = True
; opts@ContourParameters = (/25., 200., 25./)
; opts@pmLabelBarWidthF  = 0.875
; opts@pmLabelBarHeightF = 0.2
; contour_mcin           = wrf_contour(a, wks, mcin, opts)
; delete(opts)

 ; Plotting options for LCL
; opts = res
; opts@cnFillOn = True
; opts@ContourParameters = (/200., 3800., 200./)
; opts@pmLabelBarWidthF  = 0.875
; opts@pmLabelBarHeightF = 0.2
; contour_lcl            = wrf_contour(a, wks, lcl, opts)
; delete(opts)

 ; Plotting options for precip
 if (i .ne. 0) then
  opts                      = res
  opts@cnFillOn             = True
  opts@cnLevelSelectionMode = "ExplicitLevels"
  opts@cnLevels             = (/.01, .05, .10, .15, .20, .25, .50, \
                             .75, 1.00, 1.50, 2.00, 3.00, 4.00/)
  opts@lbLabelStrings       = (/".01", ".05", ".10", ".15", ".20", ".25", ".50", \
                             ".75", "1.00", "1.50", "2.00", "3.00", "4.00"/)
  opts@pmLabelBarWidthF     = 0.875
  opts@pmLabelBarHeightF    = 0.2
  opts@gsnSpreadColors      = True
  opts@gsnSpreadColorStart  = 0
  contour_rain              = wrf_contour(a, wks, rain_tot_3hr, opts)
  delete(opts)
 end if

 ; Plotting options for reflectivity
 gsn_define_colormap(wks,"radar_1")
 opts                      = res
 opts@cnFillOn             = True
 opts@ContourParameters    = (/5., 75., 5./)
 opts@gsnSpreadColors      = True
 opts@gsnSpreadColorStart  = 9
 contour_dbz               = wrf_contour(a, wks, dbz(0,:,:), opts)
 delete(opts)

 ; Make plots
 gsn_define_colormap(wks,"BlAqGrYeOrReVi200")
 plot = wrf_map_overlays(a, wks, (/contour_tf2, vector, contour_slp/), pltres, mpres)
; plot = wrf_map_overlays(a, wks, (/contour_tdf2, vector, contour_slp/), pltres, mpres)
; plot = wrf_map_overlays(a, wks, (/contour_sbcape/), pltres, mpres)
; plot = wrf_map_overlays(a, wks, (/contour_sbcin/), pltres, mpres)
; plot = wrf_map_overlays(a, wks, (/contour_mcape/), pltres, mpres)
; plot = wrf_map_overlays(a, wks, (/contour_mcin/), pltres, mpres)
; plot = wrf_map_overlays(a, wks, (/contour_lcl/), pltres, mpres)
; plot = wrf_map_overlays(a, wks, (/contour_lfc/), pltres, mpres)
 if (i .ne. 0) then
  plot = wrf_map_overlays(a, wks, (/contour_rain/), pltres, mpres)
 end if
 gsn_define_colormap(wks,"radar_1")
 plot = wrf_map_overlays(a, wks, (/contour_dbz/), pltres, mpres)
 gsn_define_colormap(wks,"BlAqGrYeOrReVi200")

 ; Upper air variables
 do level = 0, nlevels-1
   
 pressure = pressure_levels(level)
 
  ; Get variables
  tc_plane = wrf_user_intrp3d(tc,p,"h",pressure,0.,False)
  z_plane  = wrf_user_intrp3d(z,p,"h",pressure,0.,False)
  ;rh_plane = wrf_user_intrp3d(rh,p,"h",pressure,0.,False)
  u_plane  = wrf_user_intrp3d(u,p,"h",pressure,0.,False)
  v_plane  = wrf_user_intrp3d(v,p,"h",pressure,0.,False)
  tc_plane@units = "~F34~0~F~C" 
  
  ; Wind
  u_plane         = u_plane*1.94386 ; kts
  v_plane         = v_plane*1.94386 ; kts
  spd             = (u_plane*u_plane + v_plane*v_plane)^(0.5) ; kts
  u_plane@units   = "kts"
  v_plane@units   = "kts"
  spd@description = "Wind Speed"
  spd@unit        = "kts"
   
  ; UPPER AIR VARIABLE PLOTTING OPTIONS ============================================
  ; Plotting options for T
  opts_tc                   = res
  opts_tc@cnFillOn          = True
  opts_tc@pmLabelBarWidthF  = 0.875
  opts_tc@pmLabelBarHeightF = 0.2

  ; Plotting options for Wind Vectors
  opts_wind            = res
  opts_wind@FieldTitle = "Wind"
  opts_wind@NumVectors = 30
  vector               = wrf_vector(a, wks, u_plane, v_plane, opts_wind)
  delete(opts_wind)

  ; Plotting options for Wind Speed                
  opts_spd                   = res                          
  opts_spd@cnFillOn          = True
  opts_spd@pmLabelBarWidthF  = 0.875
  opts_spd@pmLabelBarHeightF = 0.2

  ; Plotting options for Geopotential Height
  opts_z = res                          
  opts_z@cnLineColor                    = "Black"
  opts_z@cnHighLabelsOn                 = True
  opts_z@cnLowLabelsOn                  = True
  opts_z@cnLineLabelBackgroundColor     = "White"
  opts_z@cnLabelDrawOrder               = "PostDraw"
  opts_z@cnLineThicknessF               = 2.0
  opts_z@cnInfoLabelOn                  = False

  ; Make plots
  ; 925 hPa (810m standard) ========================================================
  if (pressure .eq. 925) then
   standard_z                     = 810.
   standard_int                   = 30. 
   opts_tc@ContourParameters      = (/-24., 32., 2./)
   contour_tc                     = wrf_contour(a, wks, tc_plane, opts_tc)
   opts_z@ContourParameters       = (/standard_z-(25.*standard_int), standard_z+(25.*standard_int), standard_int/)
   contour_height                 = wrf_contour(a, wks, z_plane, opts_z) 
   opts_spd@ContourParameters     = (/ 10. /)
   contour_spd                    = wrf_contour(a, wks, spd, opts_spd)
   plot                           = wrf_map_overlays(a, wks, (/contour_tc, \ 
                                    contour_height, vector/), pltres, mpres)
   plot                           = wrf_map_overlays(a, wks, (/contour_spd, \
                                    contour_height, vector/), pltres, mpres)
  end if

  ; 850 hPa (1500m standard) =======================================================
  if (pressure .eq. 850) then 
   standard_z                     = 1500.
   standard_int                   = 30.
   opts_tc@ContourParameters      = (/-30., 26., 2./)
   contour_tc                     = wrf_contour(a, wks, tc_plane, opts_tc)
   opts_z@ContourParameters       = (/standard_z-(25.*standard_int), standard_z+(25.*standard_int), standard_int/)
   contour_height                 = wrf_contour(a, wks, z_plane, opts_z) 
   opts_spd@ContourParameters     = (/ 10. /)
   contour_spd                    = wrf_contour(a, wks, spd, opts_spd)
   plot                           = wrf_map_overlays(a, wks, (/contour_tc, \ 
                                    contour_height, vector/), pltres, mpres)
   plot                           = wrf_map_overlays(a, wks, (/contour_spd, \
                                    contour_height, vector/), pltres, mpres)
  end if

  ; 700 hPa (3000m standard) =======================================================
  if (pressure .eq. 700) then
   standard_z                     = 3000.
   standard_int                   = 30. 
   opts_tc@ContourParameters      = (/-30., 26., 2./)
   contour_tc                     = wrf_contour(a, wks, tc_plane, opts_tc)
   opts_z@ContourParameters       = (/standard_z-(25.*standard_int), standard_z+(25.*standard_int), standard_int/)
   contour_height                 = wrf_contour(a, wks, z_plane, opts_z)
   opts_spd@ContourParameters     = (/ 10. /)
   contour_spd                    = wrf_contour(a, wks, spd, opts_spd)
   plot                           = wrf_map_overlays(a, wks, (/contour_tc, \
                                    contour_height, vector/), pltres, mpres)
   plot                           = wrf_map_overlays(a, wks, (/contour_spd, \
                                    contour_height, vector/), pltres, mpres)
  end if

  ; 500 hPa (5700m standard) =======================================================
  if (pressure .eq. 500) then
   standard_z                     = 5700.
   standard_int                   = 60.
   opts_tc@ContourParameters      = (/-40., 0., 2./)
   contour_tc                     = wrf_contour(a, wks, tc_plane, opts_tc)
   opts_z@ContourParameters       = (/standard_z-(25.*standard_int), standard_z+(25.*standard_int), standard_int/)
   contour_height                 = wrf_contour(a, wks, z_plane, opts_z)
   opts_spd@ContourParameters     = (/ 10. /)
   contour_spd                    = wrf_contour(a, wks, spd, opts_spd)
   plot                           = wrf_map_overlays(a, wks, (/contour_tc, \
                                    contour_height, vector/), pltres, mpres)
   plot                           = wrf_map_overlays(a, wks, (/contour_spd, \
                                    contour_height, vector/), pltres, mpres)
  end if

  ; 300 hPa (9000m standard) =======================================================
  if (pressure .eq. 300) then
   standard_z                     = 9000.
   standard_int                   = 120.
   opts_z@ContourParameters       = (/standard_z-(25.*standard_int), standard_z+(25.*standard_int), standard_int/)
   contour_height                 = wrf_contour(a, wks, z_plane, opts_z)
   opts_spd@ContourParameters     = (/ 10. /)
   contour_spd                    = wrf_contour(a, wks, spd, opts_spd)
   plot                           = wrf_map_overlays(a, wks, (/contour_spd, \
                                    contour_height, vector/), pltres, mpres)
  end if

  ; 250 hPa (10500m standard) ======================================================
  if (pressure .eq. 250) then
   standard_z                     = 10500.
   standard_int                   = 120.
   opts_z@ContourParameters       = (/standard_z-(25.*standard_int), standard_z+(25.*standard_int), standard_int/)
   contour_height                 = wrf_contour(a, wks, z_plane, opts_z)
   opts_spd@ContourParameters     = (/ 10. /)
   contour_spd                    = wrf_contour(a, wks, spd, opts_spd)
   plot                           = wrf_map_overlays(a, wks, (/contour_spd, \
                                    contour_height, vector/), pltres, mpres)
  end if

  ; 200 hPa (12000m standard) ======================================================
  if (pressure .eq. 200) then
   standard_z                     = 12000.
   standard_int                   = 120.
   opts_z@ContourParameters       = (/standard_z-(25.*standard_int), standard_z+(25.*standard_int), standard_int/)
   contour_height                 = wrf_contour(a, wks, z_plane, opts_z)
   opts_spd@ContourParameters     = (/ 10. /)
   contour_spd                    = wrf_contour(a, wks, spd, opts_spd)
   plot                           = wrf_map_overlays(a, wks, (/contour_spd, \
                                    contour_height, vector/), pltres, mpres)
  end if
  delete(opts_tc)
  delete(opts_z)
  delete(opts_spd)
 end do
end do

end
