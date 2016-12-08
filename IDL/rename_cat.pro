;##############################################################
;# WISPIPE
;# Reduction Pipeline for the WISP program (Atek et al. 2010)
;# Hakim Atek 2009
;# Input:  
;#        cat_F110.cat, cat_F140.cat, cat_F160.cat, 
;# Output:
;#        fin_F*.cat  in DIRECT_GRISM folder
;# 
;# 
;# updated by Sophia Dai, 2015
;# updated by Ivano Baronchelli 2016
;###############################################################
PRO rename_cat, field,path0

path = expand_path(path0)+'/aXe/'+field+'/' 

path4=path+'DATA/DIRECT/'
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; OBS CHECK 
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
J_OBS='NO'    ; NO or YES observations in the F110 band
H_OBS='NO'    ; NO, F140 or F160
f110_list='none'
f140_list='none'
f160_list='none'
;------------------------------------------------
TEST_J=file_test(path4+'F110_clean.list',/zero_length)    ; 1 if exists but no content
TEST_JB=file_test(path4+'F110_clean.list')                ; 1 if exists
TEST_H1=file_test(path4+'F140_clean.list',/zero_length)   ; 1 if exists but no content
TEST_H1B=file_test(path4+'F140_clean.list')               ; 1 if exists but
TEST_H2=file_test(path4+'F160_clean.list',/zero_length)   ; 1 if exists but no content
TEST_H2B=file_test(path4+'F160_clean.list')               ; 1 if exists
;------------------------------------------------
;     J      +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
IF TEST_J eq 0 and TEST_JB eq 1 then begin
   readcol,path4+'F110_clean.list',f110_list,format=('A')
   if strlowcase(f110_list[0]) ne 'none' and n_elements(f110_list[0]) gt 0 then J_OBS='YES'
ENDIF
;     H      F140 / F160 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
IF TEST_H1 eq 0 and TEST_H1B eq 1 then begin
   readcol,path4+'F140_clean.list',f140_list,format=('A')
   if strlowcase(f140_list[0]) ne 'none' and n_elements(f140_list[0]) gt 0 then H_OBS='F140'
ENDIF
IF TEST_H2 eq 0 and TEST_H2B eq 1 then begin
   readcol,path4+'F160_clean.list',f160_list,format=('A')
   if strlowcase(f160_list[0]) ne 'none' and n_elements(f160_list[0]) gt 0 then H_OBS='F160'
ENDIF
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

print, 'rename_cat'
print, 'HHHHHHHHHHHHHHHHH'
print, TEST_J,TEST_JB
print, TEST_H1,TEST_H1B
print, TEST_H2,TEST_H2B
print, 'J_OBS = '+J_OBS
print, 'H_OBS = '+H_OBS
print, 'HHHHHHHHHHHHHHHHH'

num110 = n_elements(f110_list)
num140 = n_elements(f140_list)
num160 = n_elements(f160_list)

IF strlowcase(f110_list[0]) eq 'none' then num110  =0
IF strlowcase(f140_list[0]) eq 'none' then num140  =0
IF strlowcase(f160_list[0]) eq 'none' then num160  =0

; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



 ; F110
 ;===============
IF J_OBS EQ 'YES' THEN BEGIN 

 OPENR,lun,path+'DATA/DIRECT_GRISM/cat_F110.cat',/get_lun
 header_F110=strarr(15)
 readf,lun,header_F110
 header_F110(11)="#  12 MAG_F1153W        Kron-like elliptical aperture magnitude         [mag]"
 CLOSE,lun
 FREE_LUN,lun

 cat_F110=DDREAD(path+'DATA/DIRECT_GRISM/cat_F110.cat')
 tmp=strsplit(field,'r',/extract)
 name_110=tmp[1]+'_'+string(cat_F110[6,*],format='(F10.6)')+'_'+string(cat_F110[7,*],format='(F10.6)')
 tmp_110=reform(strcompress(name_110,/remove_all))

 fmt='(A22,I7,4(F10.3),F10.1,4(2X,:,F0),F10.1,3(F10.3),I5)' ; '(F10.3,1PE12.2,I7)'
 forprint,tmp_110,cat_F110[0,*],cat_F110[1,*],cat_F110[2,*],cat_F110[3,*],cat_F110[4,*],cat_F110[5,*],cat_F110[6,*],cat_F110[7,*],cat_F110[8,*],$
 cat_F110[9,*],cat_F110[10,*],cat_F110[11,*],cat_F110[12,*],cat_F110[13,*],cat_F110[14,*],format=fmt,$
 textout=path+'DATA/DIRECT_GRISM/fin_F110.cat',comment=[["#   0 RA_DEC_NAME  "],[reform(header_f110,1,15)],["#"]]  ;width=4000,

ENDIF



 ;  F140
 ;===================
IF H_OBS EQ 'F140' THEN BEGIN

 OPENR,lun,path+'DATA/DIRECT_GRISM/cat_F140.cat',/get_lun
 header_F140=strarr(15)
 readf,lun,header_F140
 header_F140(11)="#  12 MAG_F1392W        Kron-like elliptical aperture magnitude-AUTO         [mag]"
 CLOSE,lun
 FREE_LUN,lun

 cat_F140=DDREAD(path+'DATA/DIRECT_GRISM/cat_F140.cat')
 tmp=strsplit(field,'r',/extract)
 name_140=tmp[1]+'_'+string(cat_F140[6,*],format='(F10.6)')+'_'+string(cat_F140[7,*],format='(F10.6)')
 tmp_140=reform(strcompress(name_140,/remove_all))

 fmt='(A22,I7,4(F10.3),F10.1,4(2X,:,F0),F10.1,3(F10.3),I5)'
 forprint,tmp_140,cat_F140[0,*],cat_F140[1,*],cat_F140[2,*],cat_F140[3,*],cat_F140[4,*],cat_F140[5,*],cat_F140[6,*],cat_F140[7,*],cat_F140[8,*],$
 cat_F140[9,*],cat_F140[10,*],cat_F140[11,*],cat_F140[12,*],cat_F140[13,*],cat_F140[14,*],format=fmt,$
 textout=path+'DATA/DIRECT_GRISM/fin_F140.cat',comment=[["#   0 RA_DEC_NAME  "],[reform(header_f140,1,15)],["#"]];,width=4000

ENDIF



 ;  F160
 ;===================
IF H_OBS EQ 'F160' THEN BEGIN
 OPENR,lun,path+'DATA/DIRECT_GRISM/cat_F160.cat',/get_lun
 header_F160=strarr(15)
 readf,lun,header_F160
 header_F160(11)="#  12 MAG_F1573W        Kron-like elliptical aperture magnitude-AUTO         [mag]"
 CLOSE,lun
 FREE_LUN,lun

 cat_F160=DDREAD(path+'DATA/DIRECT_GRISM/cat_F160.cat')
 tmp=strsplit(field,'r',/extract)
 name_160=tmp[1]+'_'+string(cat_F160[6,*],format='(F10.6)')+'_'+string(cat_F160[7,*],format='(F10.6)')
 tmp_160=reform(strcompress(name_160,/remove_all))

 fmt='(A22,I7,4(F10.3),F10.1,4(2X,:,F0),F10.1,3(F10.3),I5)'
 forprint,tmp_160,cat_F160[0,*],cat_F160[1,*],cat_F160[2,*],cat_F160[3,*],cat_F160[4,*],cat_F160[5,*],cat_F160[6,*],cat_F160[7,*],cat_F160[8,*],$
 cat_F160[9,*],cat_F160[10,*],cat_F160[11,*],cat_F160[12,*],cat_F160[13,*],cat_F160[14,*],format=fmt,$
 textout=path+'DATA/DIRECT_GRISM/fin_F160.cat',comment=[["#   0 RA_DEC_NAME  "],[reform(header_f160,1,15)],["#"]];,width=4000

ENDIF



IF J_OBS EQ 'NO' AND H_OBS NE 'F140' AND H_OBS NE 'F160' THEN BEGIN
 
 print, '========================================================'
 print, 'MAIN ERROR: reanme_cat.pro did not find any observation' 
 print, 'in any of the filters (F110W, F140W, F160W) or'
 print, 'reanme_cat.pro did not work properly.'
 print, '========================================================'
 stop
 
ENDIF


END
