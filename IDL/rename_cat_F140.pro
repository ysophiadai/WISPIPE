;##############################################################
;# WISPIPE
;# Reduction Pipeline for the WISP program (Atek et al. 2010)
;# Hakim Atek 2009
;###############################################################
PRO rename_cat_F140, field,path0

path=path0+"/aXe/"+field+'/' 


;  F140
;===================
OPENR,lun,path+'DATA/DIRECT_GRISM/cat_F140.cat',/get_lun
header_F140=strarr(15)
readf,lun,header_F140
header_F140(11)="#  12 MAG_F1392W        Kron-like elliptical aperture magnitude         [mag]"
CLOSE,lun
FREE_LUN,lun

cat_F140=DDREAD(path+'DATA/DIRECT_GRISM/cat_F140.cat')
tmp=strsplit(field,'r',/extract)
name_140=tmp[1]+'_'+string(cat_F140[6,*],format='(F10.6)')+'_'+string(cat_F140[7,*],format='(F10.6)')
tmp_140=reform(strcompress(name_140,/remove_all))

fmt='(A22,I7,4(F10.3),F10.1,4(2X,:,F0),F10.1,3(F10.3),I5)'
forprint,tmp_140,cat_F140[0,*],cat_F140[1,*],cat_F140[2,*],cat_F140[3,*],cat_F140[4,*],cat_F140[5,*],cat_F140[6,*],cat_F140[7,*],cat_F140[8,*],$
cat_F140[9,*],cat_F140[10,*],cat_F140[11,*],cat_F140[12,*],cat_F140[13,*],cat_F140[14,*],format=fmt,$
textout=path+'DATA/DIRECT_GRISM/fin_F140.cat',comment=[["#   0 RA_DEC_NAME  "],[reform(header_f140,1,15)],["#"]];,width=4000,


END
