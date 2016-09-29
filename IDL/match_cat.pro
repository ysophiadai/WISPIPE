;##############################################################
;# WISPIPE
;# Reduction Pipeline for the WISP program (Atek et al. 2010)
;# Hakim Atek 2009
;# Purpose: match catalogs generated from SEX on the drizzled images
;# Input:  
;#        F110W_sci.fits, F160W_sci.fits or F140_sci.fits
;# Output:
;#        cat_F110.cat, cat_F160.cat or cat_F140.cat
;# 
;# 
;# updated by Sophia Dai, 2015
;###############################################################
pro match_cat,field,path0

path = path0+'/aXe/'+field+'/DATA/DIRECT_GRISM/'

 readcol,path+'F160_clean.list',f160_list,format=('A')
    
   if f160_list[0] ne 'none' then begin
    print,'matching F110W and F160W catalogs ............................' 
    match_cat_f160,field,path0
   endif else begin
     print,'matching F110W and F140W catalogs ............................'
     match_cat_f140,field,path0
   endelse

end
