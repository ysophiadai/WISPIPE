;##############################################################
;# WISPIPE
;# QA check after data reduction
;# input: field
;# Purpose: 
;#       check if the reduced image and spectra looks fine
;# Created by Sophia DAI 2015.03.30
;###############################################################
pro qacheck,field,uvis=uvis,g141=g141
                              ; cd $path/aXe/ParXXX

  cd,'/Volumes/Kudo/DATA/WISPS/aXe/Par'+strtrim(field,2)+'/Plots'
  spawn,'open Par'+strtrim(field,2)+'_spectra.pdf'
  cd,'/Volumes/Kudo/DATA/WISPS/aXe/Par'+strtrim(field,2)+'/DATA/DIRECT_GRISM'
if keyword_set(g141) then  spawn,'ds9 -zscale -zoom 0.25 G141_drz.fits F140W_drz.fits & ' ; F160W_drz.fits 
if not keyword_set(uvis) and not keyword_set (g141) then spawn,'ds9 -zscale -zoom 0.25 F110W_drz.fits F160W_drz.fits G102_drz.fits G141_drz.fits F140W_drz.fits & '

if keyword_set(uvis) then begin
  spawn,'ds9 -zscale -zoom 0.25 F110W_drz.fits F160W_drz.fits G102_drz.fits G141_drz.fits & '
  cd, '/Volumes/Kudo/DATA/WISPS/aXe/Par'+strtrim(field,2)+'/DATA/UVIS'
  spawn,'ds9 -zscale -zoom 0.1  IRtoUVIS/*_drz.fits  & '
  spawn,'ds9 -zscale -zoom 0.25 UVIStoIR/*_drz.fits  & '
endif
  

end
