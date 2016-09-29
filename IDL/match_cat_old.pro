;##############################################################
;# WISPIPE
;# Reduction Pipeline for the WISP program (Atek et al. 2010)
;# Hakim Atek 2009
;###############################################################
pro match_cat_old,field

;path="~/Caltech/aXe/"+field+'/DATA/DIRECT_GRISM/'
path = '/Volumes/Kudo/DATA/WISPS/aXe/'+field+'/DATA/DIRECT_GRISM/'

 readcol,path+'F160_clean.list',f160_list,format=('A')
    
   if f160_list[0] ne 'none' then begin
    print,'matching F110W and F160W catalogs ............................' 
    match_cat_f160_old,field
   endif ;else begin
;     print,'matching F110W and F140W catalogs ............................'
;     match_cat_f140,field
;   endelse

end
