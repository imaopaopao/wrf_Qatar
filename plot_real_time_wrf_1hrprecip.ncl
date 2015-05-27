; Clint Aegerter
; Plots 1 hr precipitation for the real-time WRF run

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

; WRF output directory
;dir       = "/work/jwang7/caegerter/test/14021500/wrfout/"
;filelist  = "14021500_list"
str       = "string"
filename  = asciiread(dir + filelist, -1, str)
nfile     = dimsizes(filename)

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

 ; Plot type
 ;type  = "X11"
 type = "png"
 ;type = "ps"
 ;type = "pdf
 wks   = gsn_open_wks(type, dir + "images/precip/" + "WRF_1hrprecip_" + fileTime)
 gsn_define_colormap(wks,"BlAqGrYeOrReVi200")
  
 ; Precip
 rain_exp = wrf_user_getvar(a, "RAINNC", 0)
 rain_con = wrf_user_getvar(a, "RAINC", 0)
 rain_tot = rain_exp + rain_con
 if ( i .ne. 0) then
  rain_tot_1hr             = rain_tot - rain_tot_save
  rain_tot_1hr             = rain_tot_1hr * 0.0393701 ; convert to inches
  rain_tot_1hr@description = "1-hr Accumulated Precip"
  rain_tot_1hr@units       = "in" 
 end if
 ; Save precip values for use in next loop
 rain_exp_save = rain_exp
 rain_con_save = rain_con
 rain_tot_save = rain_tot

 if (i .ne. 0) then
 ; Plotting options for precip
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
  contour_rain              = wrf_contour(a, wks, rain_tot_1hr, opts)
  delete(opts)

  ; Make plot
  plot = wrf_map_overlays(a, wks, (/contour_rain/), pltres, mpres)
 end if

end do

end
