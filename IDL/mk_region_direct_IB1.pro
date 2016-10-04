;##############################################################
;# WISPIPE
;# Purpose: 
;#       generate region files for direct images
;# Input:  
;#       cat_F*.cat in DIRECT_GRISM folder
;# Output:
;#       F*.reg
;# Ivano Baronchelli September 2016
;###############################################################
pro mk_region_direct_IB1,field,path0


print, "------------------------"
print, "mk_region_direct"
print, "------------------------"
  
path =  expand_path(path0)+'/aXe/'+field+"/"

; F110
readcol,path+'DATA/DIRECT_GRISM/F110_clean.list',f110_list,format=('A')
if f110_list[0] ne 'none' then begin
readcol,path+'DATA/DIRECT_GRISM/cat_F110.cat',id,xt_0,yt_0,a,b,theta,ra,dec,ad,bd,pa,mag,/silent
mk_regionfile,ra,dec,5,label=string(fix(id)),file=path+'DATA/DIRECT_GRISM/F110W_drz.reg'
mk_regionfile_elip,xt_0,yt_0,2.*a,2.*b,theta,label=string(fix(id)),file=path+'DATA/DIRECT_GRISM/F110.reg',/image,color='cyan'
endif

; F140
readcol,path+'DATA/DIRECT_GRISM/F140_clean.list',f140_list,format=('A')
if f140_list[0] ne 'none' then begin
readcol,path+'DATA/DIRECT_GRISM/cat_F140.cat',id,xt_0,yt_0,a,b,theta,ra,dec,ad,bd,pa,mag,/silent
mk_regionfile,ra,dec,5,label=string(fix(id)),file=path+'DATA/DIRECT_GRISM/F140W_drz.reg'
mk_regionfile_elip,xt_0,yt_0,2.*a,2.*b,theta,label=string(fix(id)),file=path+'DATA/DIRECT_GRISM/F140.reg',/image,color='magenta'
endif

; F160
readcol,path+'DATA/DIRECT_GRISM/F160_clean.list',f160_list,format=('A')
if f160_list[0] ne 'none' then begin
readcol,path+'DATA/DIRECT_GRISM/cat_F160.cat',id,xt_0,yt_0,a,b,theta,ra,dec,ad,bd,pa,mag,/silent
mk_regionfile,ra,dec,5,label=string(fix(id)),file=path+'DATA/DIRECT_GRISM/F160W_drz.reg'
mk_regionfile_elip,xt_0,yt_0,2.*a,2.*b,theta,label=string(fix(id)),file=path+'DATA/DIRECT_GRISM/F160.reg',/image,color='magenta'
endif


end
