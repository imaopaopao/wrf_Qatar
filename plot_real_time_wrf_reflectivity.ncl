; Clint Aegerter
; Plots simulated reflectivity for the real-time WRF run

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
wks   = gsn_open_wks(type, "WRF_reflectivity")
 gsn_define_colormap(wks,"radar_1")

; WRF output directory
;dir       = "/shared/aerosol/gshared/wrf_forcast/14021500/wrfout/"
;filelist  = "2014_wrfout_d01"
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
 wks   = gsn_open_wks(type, dir + "images/reflectivity/" + "WRF_reflectivity_" + fileTime)
 gsn_define_colormap(wks,"radar_1")
  
 ; Simulated Reflectivity
 dbz = wrf_user_getvar(a, "dbz", 0)

 ; Plotting options for reflectivity
 opts                      = res
 opts@cnFillOn             = True
 opts@ContourParameters    = (/5., 75., 5./)
 opts@gsnSpreadColors      = True
 opts@gsnSpreadColorStart  = 9
 contour_dbz               = wrf_contour(a, wks, dbz(0,:,:), opts)
 delete(opts)

 ; Make plot
 plot = wrf_map_overlays(a, wks, (/contour_dbz/), pltres, mpres)

end do

end
