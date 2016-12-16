;##############################################################
;# WISPIPE
;#
;# Purpose: Generate several drizzled images
;# Keywords: 
;# 
;# Calls: 
;# Input: 
;#       direct_list (of all the '_flt.fits' files)
;#       field
;#       path0: points to the directory with data--raw &
;# Output:
;#         move the tweak+drizzled direct & grism image to the DIRECT_GRISM folder
;#        
;#        
;# Created on 2014.11.07 by Sophia Dai to generate driz.py
;# Updated on 2015.02.24 by Sophia Dai
;# Last Updated on November 2016 by Ivano Baronchelli
;###############################################################

;===========================================     MAIN  ====================================================

pro new_drizprep_IB2,field,path0

;path = '/Volumes/Kudo/DATA/WISPS/aXe/Par288-full/'
;drizprep,'Par288-full','/Volumes/Kudo/DATA/WISPS','~/WISPS/WISPIPE'


print, ' '
print, 'XXXXXXXXXXXXXXXXXXX'
print, "     drizprep"
print, 'XXXXXXXXXXXXXXXXXXX'
print, ' '
  

; path = path0+'/aXe/'
; path2 = path+field+"/"

; path3=path2+'DATA/DIRECT_GRISM/'
; path4=path2+'DATA/GRISM/'
; path5=path2+'DATA/DIRECT/'

path = path0+'/aXe/'+field+"/"
path3=path+'DATA/DIRECT_GRISM/'
path4=path+'DATA/GRISM/'
path5=path+'DATA/DIRECT/'



;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; OBS CHECK 
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
print, 'drizprep'
J_OBS='NO'    ; NO or YES observations in the F110 band
H_OBS='NO'    ; NO, F140 or F160
G102_OBS='NO' ; NO or YES observations in the G102 grism
G141_OBS='NO' ; NO or YES observations in the G141 grism
f110_list='none'
f140_list='none'
f160_list='none'
g102_list='none'
g141_list='none'
;------------------------------------------------
; DIRECT ----
TEST_J=file_test(path+'DATA/DIRECT/F110_clean.list',/zero_length) ; 1 if exists but no content
TEST_JB=file_test(path+'DATA/DIRECT/F110_clean.list')              ; 1 if exists
TEST_H1=file_test(path+'DATA/DIRECT/F140_clean.list',/zero_length) ; 1 if exists but no content
TEST_H1B=file_test(path+'DATA/DIRECT/F140_clean.list')             ; 1 if exists
TEST_H2=file_test(path+'DATA/DIRECT/F160_clean.list',/zero_length) ; 1 if exists but no content
TEST_H2B=file_test(path+'DATA/DIRECT/F160_clean.list')             ; 1 if exists
; GRISMS ----
TEST_G102=file_test(path+'DATA/GRISM/G102_clean.list',/zero_length) ; 1 if exists but no content
TEST_G102B=file_test(path+'DATA/GRISM/G102_clean.list')              ; 1 if exists
TEST_G141=file_test(path+'DATA/GRISM/G141_clean.list',/zero_length) ; 1 if exists but no content
TEST_G141B=file_test(path+'DATA/GRISM/G141_clean.list')              ; 1 if exists
;------------------------------------------------
;     J      +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
IF TEST_J eq 0 and TEST_JB eq 1 then begin
   readcol,path+'DATA/DIRECT/F110_clean.list',f110_list,format=('A')
   if strlowcase(f110_list[0]) ne 'none' and n_elements(f110_list[0]) gt 0 then J_OBS='YES'
ENDIF
;     H      F140 / F160 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
IF TEST_H1 eq 0 and TEST_H1B eq 1 then begin
   readcol,path+'DATA/DIRECT/F140_clean.list',f140_list,format=('A')
   if strlowcase(f140_list[0]) ne 'none' and n_elements(f140_list[0]) gt 0 then H_OBS='F140'
ENDIF
IF TEST_H2 eq 0 and TEST_H2B eq 1 then begin
   readcol,path+'DATA/DIRECT/F160_clean.list',f160_list,format=('A')
   if strlowcase(f160_list[0]) ne 'none' and n_elements(f160_list[0]) gt 0 then H_OBS='F160'
ENDIF
;    G102    +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
IF TEST_G102 eq 0 and TEST_G102B eq 1 then begin
   readcol,path+'DATA/GRISM/G102_clean.list',g102_list,format=('A')
   if strlowcase(g102_list[0]) ne 'none' and n_elements(g102_list[0]) gt 0 then G102_OBS='YES'
ENDIF
;    G141    +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
IF TEST_G141 eq 0 and TEST_G141B eq 1 then begin
   readcol,path+'DATA/GRISM/G141_clean.list',g141_list,format=('A')
   if strlowcase(g141_list[0]) ne 'none' and n_elements(g141_list[0]) gt 0 then G141_OBS='YES'
ENDIF
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

print, 'HHHHHHHHHHHHHHHHH'
print, TEST_J,TEST_JB
print, TEST_H1,TEST_H1B
print, TEST_H2,TEST_H2B
print, 'J_OBS = '+J_OBS
print, 'H_OBS = '+H_OBS
print, 'G102_OBS = '+G102_OBS
print, 'G141_OBS = '+G141_OBS
print, 'HHHHHHHHHHHHHHHHH'





; Move drizzled direct & grism images to the DIRECT_GRISM folder
; ************************

; COMBINED IMAGES

IF J_OBS EQ'YES' THEN BEGIN
 spawn,'cp '+path+'DATA/DIRECT/F110W_twk_drz.fits '+path+'DATA/DIRECT_GRISM/F110W_drz.fits' 
 spawn,'cp '+path+'DATA/DIRECT/F110W_twk_sci.fits '+path+'DATA/DIRECT_GRISM/F110W_sci.fits'
 spawn,'cp '+path+'DATA/DIRECT/F110W_twk_wht.fits '+path+'DATA/DIRECT_GRISM/F110W_wht.fits' 
 spawn,'cp '+path+'DATA/DIRECT/F110W_twk_rms.fits '+path+'DATA/DIRECT_GRISM/F110W_rms.fits' 
ENDIF

IF H_OBS EQ 'F160' THEN BEGIN
 spawn,'cp '+path+'DATA/DIRECT/F160W_twk_drz.fits '+path+'DATA/DIRECT_GRISM/F160W_drz.fits' 
 spawn,'cp '+path+'DATA/DIRECT/F160W_twk_sci.fits '+path+'DATA/DIRECT_GRISM/F160W_sci.fits'
 spawn,'cp '+path+'DATA/DIRECT/F160W_twk_wht.fits '+path+'DATA/DIRECT_GRISM/F160W_wht.fits' 
 spawn,'cp '+path+'DATA/DIRECT/F160W_twk_rms.fits '+path+'DATA/DIRECT_GRISM/F160W_rms.fits' 
ENDIF

IF H_OBS EQ 'F140' THEN BEGIN
 spawn,'cp '+path+'DATA/DIRECT/F140W_twk_drz.fits '+path+'DATA/DIRECT_GRISM/F140W_drz.fits' 
 spawn,'cp '+path+'DATA/DIRECT/F140W_twk_sci.fits '+path+'DATA/DIRECT_GRISM/F140W_sci.fits'
 spawn,'cp '+path+'DATA/DIRECT/F140W_twk_wht.fits '+path+'DATA/DIRECT_GRISM/F140W_wht.fits' 
 spawn,'cp '+path+'DATA/DIRECT/F140W_twk_rms.fits '+path+'DATA/DIRECT_GRISM/F140W_rms.fits' 
ENDIF


; SINGLE GRISM EXPOSURES

;G102
IF G102_OBS EQ 'YES' THEN BEGIN
 PP=0L
 while PP lt n_elements(g102_list) do begin
  print, '-------------------------------'
  print, 'GRISM 102 exposure copying'
  IF FILE_TEST(path3+g102_list[PP]) gt 0 then print, 'WARNING: The old copy in the destination will be sobstituted'
  spawn,'cp '+path4+g102_list[PP]+' '+path3+g102_list[PP]
  print, 'Copying '+path4+g102_list[PP] +' to '+path3+g102_list[PP]
  spawn,'cp '+path4+'G102.fits'+' '+path3+'G102.fits'
  print, 'Copying '+path4+'G102.fits'+' to '+path3+'G102.fits'
  spawn,'cp '+path4+'G102_twk_twkpg_drz.fits'+' '+path3+'G102_drz.fits'
  print, 'Copying '+path4+'G102_twk_twkpg_drz.fits'+' to '+path3+'G102_drz.fits'
  spawn,'cp '+path4+'G102_twkpg_orig_scale_drz.fits'+' '+path3+'G102_orig_scale_drz.fits'
  print, 'Copying '+path4+'G102_twkpg_orig_scale_drz.fits'+' to '+path3+'G102_orig_scale_drz.fits'
  PP=PP+1
 ENDWHILE
ENDIF

;G141
PP=0L
IF G141_OBS EQ 'YES' THEN BEGIN
 WHILE PP lt n_elements(g141_list) do begin
  print, '-------------------------------'
  print, 'GRISM 141 exposure copying '
  IF  FILE_TEST(path3+g141_list[PP]) gt 0 then print, 'WARNING: The old copy in the destination will be sobstituted'
  spawn,'cp '+path4+g141_list[PP]+' '+path3+g141_list[PP]
  print, 'Copying '+path4+g141_list[PP] +' to '+path3+g141_list[PP]
  spawn,'cp '+path4+'G141.fits'+' '+path3+'G141.fits'
  print, 'Copying '+path4+'G141.fits'+' to '+path3+'G141.fits'
  spawn,'cp '+path4+'G141_twk_twkpg_drz.fits'+' '+path3+'G141_drz.fits'
  print, 'Copying '+path4+'G141_twk_twkpg_drz.fits'+' to '+path3+'G141_drz.fits'
  spawn,'cp '+path4+'G141_twkpg_orig_scale_drz.fits'+' '+path3+'G141_orig_scale_drz.fits'
  print, 'Copying '+path4+'G141_twkpg_orig_scale_drz.fits'+' to '+path3+'G141_orig_scale_drz.fits'
  PP=PP+1
 ENDWHILE
ENDIF

;  SINGLE DIRECT EXPOSURES

; F110
IF J_OBS EQ 'YES' THEN BEGIN
 PP=0L
 WHILE PP lt n_elements(f110_list) do begin
  print, '-------------------------------'
  print, 'DIRECT F110 exposure copying '
  IF  FILE_TEST(path3+f110_list[PP]) gt 0 then print, 'WARNING: The old copy in the destination will be sobstituted'
  spawn,'cp '+path5+f110_list[PP]+' '+path3+f110_list[PP]
  print, 'Copying '+path5+f110_list[PP] +' to '+path3+f110_list[PP]
  PP=PP+1
 ENDWHILE
ENDIF

; F160
IF H_OBS EQ 'F160' THEN BEGIN
 PP=0L
 WHILE PP lt n_elements(f160_list) do begin
  print, '-------------------------------'
  print, 'DIRECT F160 exposure copying '
  IF  FILE_TEST(path3+f160_list[PP]) gt 0 then print, 'WARNING: The old copy in the destination will be sobstituted'
  spawn,'cp '+path5+f160_list[PP]+' '+path3+f160_list[PP]
  print, 'Copying '+path5+f160_list[PP] +' to '+path3+f160_list[PP]
  PP=PP+1
 ENDWHILE
ENDIF

; F140
IF H_OBS EQ 'F140' THEN BEGIN
 PP=0L
 WHILE PP lt n_elements(f140_list) do begin
  print, '-------------------------------'
  print, 'DIRECT F140 exposure copying '
  IF  FILE_TEST(path3+f140_list[PP]) gt 0 then print, 'WARNING: The old copy in the destination will be sobstituted'
  spawn,'cp '+path5+f140_list[PP]+' '+path3+f140_list[PP]
  print, 'Copying '+path5+f140_list[PP] +' to '+path3+f140_list[PP]
  PP=PP+1
 ENDWHILE
ENDIF





end
