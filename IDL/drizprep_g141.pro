;##############################################################
;# WISPIPE
;#
;# Purpose: Generate several drizzled images
;# Keywords: 
;#       both: if both grisms available
;#       uvis; if uvis data available
;# Calls: 
;# Input: 
;#       direct_list (of all the '_flt.fits' files)
;#       field
;#       path0: points to the directory with data--raw &
;#       pathc: points to the WISPIPE directory 
;# Output:
;#         move the tweak+drizzled direct & grism image to the DIRECT_GRISM folder
;#         if uvis data available, the astrodrizzle script in uvis_driz.py
;#        
;# Created on 2014.11.07 by Sophia Dai to generate driz.py
;# Updated on 2015.03.19 by Sophia Dai
;###############################################################

;===========================================     MAIN  ====================================================

pro drizprep_g141,field,path0
;path = '/Volumes/Kudo/DATA/WISPS/aXe/Par288-full/'
;drizprep,'Par288-full','/Volumes/Kudo/DATA/WISPS','~/WISPS/WISPIPE'

configpath = path0+'/aXe/CONFIG/'
path = path0+'/aXe/'

path2 = path+field+"/"
path3=path2+'DATA/DIRECT_GRISM/'


;move drizzled direct & grism images to the DIRECT_GRISM folder
   readcol,path3+'F140_clean.list',f140_list,format=('A')
   readcol,path3+'F160_clean.list',f160_list,format=('A')
   readcol,path3+'G141_clean.list',g141_list,format=('A')

if f140_list[0] ne 'none' then begin
    spawn,'cp '+path2+'DATA/DIRECT/F140W_twk_drz.fits '+path2+'DATA/DIRECT_GRISM/F140W_drz.fits' 
    spawn,'cp '+path2+'DATA/DIRECT/F140W_twk_sci.fits '+path2+'DATA/DIRECT_GRISM/F140W_sci.fits'
    spawn,'cp '+path2+'DATA/DIRECT/F140W_twk_wht.fits '+path2+'DATA/DIRECT_GRISM/F140W_wht.fits' 
    spawn,'cp '+path2+'DATA/DIRECT/F140W_twk_rms.fits '+path2+'DATA/DIRECT_GRISM/F140W_rms.fits' 
 endif

if f160_list[0] ne 'none' then begin
    spawn,'cp '+path2+'DATA/DIRECT/F160W_twk_drz.fits '+path2+'DATA/DIRECT_GRISM/F160W_drz.fits' 
    spawn,'cp '+path2+'DATA/DIRECT/F160W_twk_sci.fits '+path2+'DATA/DIRECT_GRISM/F160W_sci.fits'
    spawn,'cp '+path2+'DATA/DIRECT/F160W_twk_wht.fits '+path2+'DATA/DIRECT_GRISM/F160W_wht.fits' 
    spawn,'cp '+path2+'DATA/DIRECT/F160W_twk_rms.fits '+path2+'DATA/DIRECT_GRISM/F160W_rms.fits' 
 endif

if g141_list[0] ne 'none' then begin
    spawn,'cp '+path2+'DATA/GRISM/G141_orig_drz.fits '+path2+'DATA/DIRECT_GRISM/G141_drz.fits' 
 endif

end
