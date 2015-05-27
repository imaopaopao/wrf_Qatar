; Clint Aegerter
; Plots upper air variables (temperature, wind, and height) for the real-time WRF run

;  LOAD FUNCTIONS AND PROCEDURES
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"

begin

; Basic resources
res = True
res@MainTitle = "UNL Real-Time WRF"
res@Footer = False
mpres = True
pltres = True

; Plot type
;type  = "X11"
type = "png"
;type = "ps"
;type = "pdf
;wks   = gsn_open_wks(type, "WRF_UpperAir")
;gsn_define_colormap(wks,"BlAqGrYeOrReVi200")

; WRF output directory
;dir       = "/shared/aerosol/gshared/wrf_forcast/14021500/wrfout/"
;filelist  = "2014_wrfout_d01"
str       = "string"
filename  = asciiread(dir + filelist, -1, str)
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
 fileTime = str_sub_str(time, ":", "_")
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
;  vector               = wrf_vector(a, wks, u_plane, v_plane, opts_wind)
;  delete(opts_wind)

  ; Plotting options for Wind Speed                
  opts_spd                      = res                          
  opts_spd@cnFillOn             = True
  opts_spd@pmLabelBarWidthF     = 0.875
  opts_spd@pmLabelBarHeightF    = 0.2
  opts_spd@cnLevelSelectionMode = "ExplicitLevels"
  opts_spd@cnFillColors         = (/"white", "skyblue1", "steelblue2", "steelblue3", "blue1", "blue3", \
                                   "purple4", "purple3", "purple1", "magenta3", "magenta2", "violet"/)

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
   wks = gsn_open_wks(type, dir + "images/upper_air/" + "WRF_925hPa_" + fileTime)
   gsn_define_colormap(wks,"BlAqGrYeOrReVi200")

   standard_z                     = 810.
   standard_int                   = 30. 
   opts_tc@ContourParameters      = (/-24., 32., 2./)
   contour_tc                     = wrf_contour(a, wks, tc_plane, opts_tc)
   opts_z@ContourParameters       = (/standard_z-(25.*standard_int), standard_z+(25.*standard_int), standard_int/)
   contour_height                 = wrf_contour(a, wks, z_plane, opts_z) 
   opts_spd@cnLevels              = (/25, 30, 35, 40, 45, 50, 55, 60, 70, 80, 90/)
   contour_spd                    = wrf_contour(a, wks, spd, opts_spd)
   vector                         = wrf_vector(a, wks, u_plane, v_plane, opts_wind)
   plot                           = wrf_map_overlays(a, wks, (/contour_tc, \ 
                                    contour_height, vector/), pltres, mpres)
;   wks                            = gsn_open_wks(type, "WRF_925wind")
;   gsn_define_colormap(wks,"BlAqGrYeOrReVi200")
   plot                           = wrf_map_overlays(a, wks, (/contour_spd, \
                                    contour_height, vector/), pltres, mpres)
  end if

  ; 850 hPa (1500m standard) =======================================================
  if (pressure .eq. 850) then 
   wks = gsn_open_wks(type, dir + "images/upper_air/" + "WRF_850hPa_" + fileTime)
   gsn_define_colormap(wks,"BlAqGrYeOrReVi200")

   standard_z                     = 1500.
   standard_int                   = 30.
   opts_tc@ContourParameters      = (/-30., 26., 2./)
   contour_tc                     = wrf_contour(a, wks, tc_plane, opts_tc)
   opts_z@ContourParameters       = (/standard_z-(25.*standard_int), standard_z+(25.*standard_int), standard_int/)
   contour_height                 = wrf_contour(a, wks, z_plane, opts_z) 
   opts_spd@cnLevels              = (/25, 30, 35, 40, 45, 50, 55, 60, 70, 80, 90/)
   contour_spd                    = wrf_contour(a, wks, spd, opts_spd)
   vector                         = wrf_vector(a, wks, u_plane, v_plane, opts_wind)
   plot                           = wrf_map_overlays(a, wks, (/contour_tc, \ 
                                    contour_height, vector/), pltres, mpres)
   plot                           = wrf_map_overlays(a, wks, (/contour_spd, \
                                    contour_height, vector/), pltres, mpres)
  end if

  ; 700 hPa (3000m standard) =======================================================
  if (pressure .eq. 700) then
   wks = gsn_open_wks(type, dir + "images/upper_air/" + "WRF_700hPa_" + fileTime)
   gsn_define_colormap(wks,"BlAqGrYeOrReVi200")

   standard_z                     = 3000.
   standard_int                   = 30. 
   opts_tc@ContourParameters      = (/-30., 26., 2./)
   contour_tc                     = wrf_contour(a, wks, tc_plane, opts_tc)
   opts_z@ContourParameters       = (/standard_z-(25.*standard_int), standard_z+(25.*standard_int), standard_int/)
   contour_height                 = wrf_contour(a, wks, z_plane, opts_z)
   opts_spd@cnLevels              = (/25, 30, 35, 40, 45, 50, 55, 60, 70, 80, 90/)
   contour_spd                    = wrf_contour(a, wks, spd, opts_spd)
   vector                         = wrf_vector(a, wks, u_plane, v_plane, opts_wind)
   plot                           = wrf_map_overlays(a, wks, (/contour_tc, \
                                    contour_height, vector/), pltres, mpres)
   plot                           = wrf_map_overlays(a, wks, (/contour_spd, \
                                    contour_height, vector/), pltres, mpres)
  end if

  ; 500 hPa (5700m standard) =======================================================
  if (pressure .eq. 500) then
   wks = gsn_open_wks(type, dir + "images/upper_air/" + "WRF_500hPa_" + fileTime)
   gsn_define_colormap(wks,"BlAqGrYeOrReVi200")

   standard_z                     = 5700.
   standard_int                   = 60.
   opts_tc@ContourParameters      = (/-40., 0., 2./)
   contour_tc                     = wrf_contour(a, wks, tc_plane, opts_tc)
   opts_z@ContourParameters       = (/standard_z-(25.*standard_int), standard_z+(25.*standard_int), standard_int/)
   contour_height                 = wrf_contour(a, wks, z_plane, opts_z)
   opts_spd@cnLevels              = (/25, 30, 35, 40, 50, 60, 70, 80, 90, 100, 110/)
   contour_spd                    = wrf_contour(a, wks, spd, opts_spd)
   vector                         = wrf_vector(a, wks, u_plane, v_plane, opts_wind)
   plot                           = wrf_map_overlays(a, wks, (/contour_tc, \
                                    contour_height, vector/), pltres, mpres)
   plot                           = wrf_map_overlays(a, wks, (/contour_spd, \
                                    contour_height, vector/), pltres, mpres)
  end if

  ; 300 hPa (9000m standard) =======================================================
  if (pressure .eq. 300) then
   wks = gsn_open_wks(type, dir + "images/upper_air/" + "WRF_300hPa_" + fileTime)
   gsn_define_colormap(wks,"BlAqGrYeOrReVi200")

   standard_z                     = 9000.
   standard_int                   = 120.
   opts_z@ContourParameters       = (/standard_z-(25.*standard_int), standard_z+(25.*standard_int), standard_int/)
   contour_height                 = wrf_contour(a, wks, z_plane, opts_z)
   opts_spd@cnLevels              = (/40, 50, 60, 70, 80, 90, 100, 120, 140, 160, 180/)
   contour_spd                    = wrf_contour(a, wks, spd, opts_spd)
   vector                         = wrf_vector(a, wks, u_plane, v_plane, opts_wind)
   plot                           = wrf_map_overlays(a, wks, (/contour_spd, \
                                    contour_height, vector/), pltres, mpres)
  end if

  ; 250 hPa (10500m standard) ======================================================
  if (pressure .eq. 250) then
   wks = gsn_open_wks(type, dir + "images/upper_air/" + "WRF_250hPa_" + fileTime)
   gsn_define_colormap(wks,"BlAqGrYeOrReVi200")

   standard_z                     = 10500.
   standard_int                   = 120.
   opts_z@ContourParameters       = (/standard_z-(25.*standard_int), standard_z+(25.*standard_int), standard_int/)
   contour_height                 = wrf_contour(a, wks, z_plane, opts_z)
   opts_spd@cnLevels              = (/40, 50, 60, 70, 80, 90, 100, 120, 140, 160, 180/)
   contour_spd                    = wrf_contour(a, wks, spd, opts_spd)
   vector                         = wrf_vector(a, wks, u_plane, v_plane, opts_wind)
   plot                           = wrf_map_overlays(a, wks, (/contour_spd, \
                                    contour_height, vector/), pltres, mpres)
  end if

  ; 200 hPa (12000m standard) ======================================================
  if (pressure .eq. 200) then
   wks = gsn_open_wks(type, dir + "images/upper_air/" + "WRF_200hPa_" + fileTime)
   gsn_define_colormap(wks,"BlAqGrYeOrReVi200")

   standard_z                     = 12000.
   standard_int                   = 120.
   opts_z@ContourParameters       = (/standard_z-(25.*standard_int), standard_z+(25.*standard_int), standard_int/)
   contour_height                 = wrf_contour(a, wks, z_plane, opts_z)
   opts_spd@cnLevels              = (/40, 50, 60, 70, 80, 90, 100, 120, 140, 160, 180/)
   contour_spd                    = wrf_contour(a, wks, spd, opts_spd)
   vector                         = wrf_vector(a, wks, u_plane, v_plane, opts_wind)
   plot                           = wrf_map_overlays(a, wks, (/contour_spd, \
                                    contour_height, vector/), pltres, mpres)
  end if
  delete(opts_tc)
  delete(opts_z)
  delete(opts_spd)
 end do
end do

end
