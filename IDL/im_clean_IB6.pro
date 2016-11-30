;##############################################################
;# WISPIPE
;# Reduction Pipeline for the WISP program (Atek et al. 2010)
;# Hakim Atek 2009
;# Modified by Marc Rafelski 2012  to work independent of path length
;# Last edit by Sophia Dai 2015.02.24
;#
;# Purpose: Cleans the direct images
;# Keywords: 
;#       both: if both grisms available
;#       uvis; if uvis data available
;#       multidrizzle: obsolete keyword, completely shifted to
;# astrodrizzle since end of 2013
;#       F140only: for Cycle 19 data only - used only one IR image. 
;# Calls: 
;#        clean_direct.pro (defined here)
;#        cross_clean.pro
;#        badpix.pro
;#        strpos.pro, strtrim.pro, strmod.pro
;# Input: 
;#       direct_list (of all the '_flt.fits' files)
;#       field
;#       path0: points to the directory with data--raw &
;# aXe--processed data
;#       pathc: points to the WISPIPE directory 
;# Output: cleaned images named *_flt_clean.fits 
;#         (1st array for _sci, 3rd array for _dq)
;#         the astrodrizzle script: driz.py
;#         if uvis data available, the astrodrizzle script: uvis_driz.py
;#        
;# Updated on 2015.02.24 by Sophia Dai to remove north-up options, 
;# to add correlated noise correction in the F*_rms.fits, factor =
;# 1.67757; and to include the UVIStoIR and IRtoUVIS drizzle if uvis
;# data exist.
;# updated on 2016.02.03 by Sophia Dai to account for the num=1
;# situation in UVIStoIR and IRtoUVIS drizzle step
;#
;# Updated by Ivano Baronchelli (2016.09.06).
;# - Images are not copied into the DIRECT_GRISM folder at this point
;# - All astrodrizzle "updatewcs" keywords set to False instead of
;#   True.
;# - A program file for the initial drizzling of the uvis exposures
;#   is written (uvis_initial_driz.py)
;# - V4: a program for the initial updatewcs of the uvis exposures is
;#   adjoined (uvis_updatewcs.py)
;# - V4: in all the "imcalc" tasks, the rms image is computed using
;#   the following form:
;#   iraf.imcalc(input="input_wht.fits", output="output_rms.fits", equals="1.0/sqrt(im1)")
;#   This new solution is suggested by Marc Rafelsky and sobstitutes
;#   the old one:
;#   iraf.imcalc(input="input_wht.fits", output="output_rms.fits", equals="value/sqrt(im1)")
;#  - V4: a program for the initial updatewcs of the IR grism and
;#   direct exposures is written (IR_updatewcs.py) .
;#   (this step doesn' seem to be
;#   necessary for the pipeline to work, but it is recomended)
;#
;#  - V5: the bad pixel mask used is the updated one (bp_mask_v6.pl), that
;#     considers also the wagon wheel feature.
;#  - V5: In place of F600LP and F475X we call the filters
;#    with this new nomenclature:
;#    F475X  --> UVIS1 (idem for F475)
;#    F600LP --> UVIS2 (idem for F600)
;###############################################################
;==============================================================================================
pro clean_direct,direct_list

direct_len=n_elements(direct_list)

for k=0,direct_len-1 do begin    
     name=direct_list(k)                    ;*_flt.fits
     tmp=strsplit(name,'.',/extract)        ;[*_flt, fits]
     name_clean=tmp[0]+'_clean.fits'        ;*_flt_clean.fits
     spawn,'cp '+name+' '+name_clean
     direct=MRDFITS(name,1,hdr,/silent)
     print,"cleaning direct image .....",k+1 

     dq_cross=cross_clean(tmp[0])                    ; cross clean the _flt.fits file, using the *_ima.fits file, output is the dq array

     direct_clean=sigma_filter(direct,3, N_sigma=7, /ALL,/MON)  ; have a 7 sigma cut of the _flt.fits image, within a pixel=3 box; 
                                ; standard deviations to define outliers = 7, % of smoothed pixels shown
     modfits,name_clean,direct_clean, EXTEN_NO = 1              ; update the *_flt_clean.fits file with the cleaned one; 1st header extension, _sci files
     
     tmp=readfits(name_clean,exten_no=3,hdr3)
     modfits,name_clean,dq_cross,hdr3,exten_no=3                ; update the *_flt_clean.fits file with the cleaned one; 3rd header extension, _dq files

endfor

end




;==========================================================================================================


;===========================================     MAIN  ====================================================

;pro im_clean_IB6,field,both=both,uvis=uvis,multidrizzle=multidrizzle,F140only=F140only, path0, pathc,script=script,single=single
pro im_clean_IB6,field, path0, pathc,script=script


print, "======================="
print, "im_clean (im_clean_IB6)"
print, "======================="



configpath = pathc+'/aXe/CONFIG/'
path = path0+'/aXe/'
path_data = path0+'/data/'+field+"/"

path2=path+field+"/"
path3=path2+'DATA/DIRECT_GRISM/'
; MODIFICATION BY I.B. The program will work on files in "DIRECT" and
;"GRISM" and not DIRECT_GRISM anymore.
path4=path2+'DATA/DIRECT/'
path5=path2+'DATA/GRISM/'
path6=path2+'DATA/UVIS/'

BPM=configpath+'bp_mask_v6.fits'


  spawn, 'ls -1 '+path5+'i*flt.fits',grism_list
  grism_len=n_elements(grism_list)
  print,grism_list

  spawn, 'ls -1 '+path4+'i*flt.fits',direct_list
  direct_len=n_elements(direct_list)
  spawn, 'ls -1 '+path5+'i*flt_clean.fits',clean_list



if keyword_set(script) then goto, script
; clean grism images, first copy to DATA/DIRECT_GRISM, then use
; badpix.func to generate cleaned image
;*******************************************************

     for j=0,grism_len-1 do begin

         print,"Cleaning Grism image",j

         name=clean_list(j)                            ;***_flt_clean.fits
;        get parameters for drizzle
         tmp=mrdfits(name,1,header)
         rot=sxpar(header,'ORIENTAT')
         ra=sxpar(header,'CRVAL1')
         dec=sxpar(header,'CRVAL2')
         print,"rotation parameter ....",rot
         print,"center RA ....",ra
         print,"center DEC ....",dec
   
         name = strtrim(name, 2)
         foob = strpos(name, '/', /reverse_search)   ;find position of '/'
         fooe = strpos(name, '.', /reverse_search)   ;find position of '.'
         fooe2 = strpos(name, '_', /reverse_search)  ;find position of the last'_'
         foo2 = strmid(name, foob+1,fooe2-foob-1)    ;foo2 is the name right after '/' before '_***.fits'
         foo3 = strmid(name, foob+1,fooe-foob-1)     ;foo3 is the name right after '/' before '.fits'
;         s_name=path2+'DATA/GRISM/m_sci_'+foo3+'.fits'  
         dq=path5+foo2+'.fits'         ;dq is the *_flt.fits file to be cleaned
 

          s_grism=badpix(name,1,dq,BPM)                   ;creates a *_flt_clean.fits from _flt.fits input, with 1 
          tmp=readfits(name,hdr1,EXTEN_NO=1) 
         check_fits,s_grism,hdr1,/update
         modfits,name,s_grism,hdr1,EXTEN_NO = 1         ;replace the ***_flt_clean.fits with the bad pixel removed one
     endfor


; clean direct images
;*******************************************************
     print,"Sigma-rejection cleaning of direct images ....."
     clean_direct,direct_list   ;all files in /DATA/DIRECT folder


script:

;goto,eend

   
; create the default astrodrizzle script
;***********************************
;***********************************
openw,10,path3+'driz.py'
openw,11,path2+'DATA/UVIS/uvis_driz.py'
openw,12,path2+'DATA/UVIS/uvis_initial_driz.py'
openw,13,path2+'DATA/UVIS/uvis_updatewcs.py'
openw,14,path2+'IR_updatewcs.py'
;***********************************
;***********************************



printf,10,'import os,string,time'
printf,10,'import sys'
printf,10,'import shutil'
printf,10,'from pyraf import iraf'
printf,10,'from iraf import stsdas, slitless, axe, dither'
printf,10,'import drizzlepac'
printf,10,'from drizzlepac import astrodrizzle'
printf,10,'from pyraf.irafpar import IrafParS'
printf,10,'from stsci.tools import teal'
printf,10, 'teal.unlearn("astrodrizzle")'

    ;printf,10,'unlearn astrodrizzle'

TEST_J=file_test(path4+'F110_clean.list',/zero_length)    ; 1 if exists but no content
TEST_JB=file_test(path4+'F110_clean.list')                ; 1 if exists
TEST_H1=file_test(path4+'F140_clean.list',/zero_length)   ; 1 if exists but no content
TEST_H1B=file_test(path4+'F140_clean.list')               ; 1 if exists but
TEST_H2=file_test(path4+'F160_clean.list',/zero_length)   ; 1 if exists but no content
TEST_H2B=file_test(path4+'F160_clean.list')               ; 1 if exists
TEST_G102=file_test(path5+'G102_clean.list',/zero_length) ; 1 if exists but no content
TEST_G102B=file_test(path5+'G102_clean.list')             ; 1 if exists
TEST_G141=file_test(path5+'G141_clean.list',/zero_length) ; 1 if exists but no content
TEST_G141B=file_test(path5+'G141_clean.list')             ; 1 if exists
; UVIS
TEST_UV1=file_test(path6+'UVIS1.list',/zero_length) ; 1 if exists but no content
TEST_UV1B=file_test(path6+'UVIS1.list')             ; 1 if exists
TEST_UV2=file_test(path6+'UVIS2.list',/zero_length) ; 1 if exists but no content
TEST_UV2B=file_test(path6+'UVIS2.list')             ; 1 if exists


f110_list='none'
f140_list='none'
f160_list='none'
g102_list='none'
g141_list='none'
UV1_list ='none'
UV2_list ='none'

; IF FILES EXIST AND ARE NOT VOID ...
;                                 ... READ THEM!
IF TEST_J eq 0 and TEST_JB eq 1 THEN       readcol,path4+'F110_clean.list',f110_list,format=('A')
IF TEST_H1 eq 0 and TEST_H1B eq 1 THEN     readcol,path4+'F140_clean.list',f140_list,format=('A')
IF TEST_H2 eq 0 and TEST_H2B eq 1 THEN     readcol,path4+'F160_clean.list',f160_list,format=('A')
IF TEST_G102 eq 0 and TEST_G102B eq 1 THEN readcol,path5+'G102_clean.list',g102_list,format=('A')
IF TEST_G141 eq 0 and TEST_G141B eq 1 THEN readcol,path5+'G141_clean.list',g141_list,format=('A')
; UVIS
IF TEST_UV1 eq 0 and TEST_UV1B eq 1 THEN readcol,path6+'UVIS1.list',UV1_list,format=('A')
IF TEST_UV2 eq 0 and TEST_UV2B eq 1 THEN readcol,path6+'UVIS2.list',UV2_list,format=('A')

num110 = n_elements(f110_list)
num140 = n_elements(f140_list)
num160 = n_elements(f160_list)
numG102 = n_elements(G102_list)
numG141 = n_elements(G141_list)
; UVIS
numUV1 = n_elements(UV1_list)
numUV2 = n_elements(UV2_list)

; IF n_elements(f110_list) eq 0 or strlowcase(f110_list[0]) eq 'none' then f110_list='none'
; IF n_elements(f140_list) eq 0 or strlowcase(f110_list[0]) eq 'none' then f140_list='none'
; IF n_elements(f160_list) eq 0 or strlowcase(f110_list[0]) eq 'none' then f160_list='none'
; IF n_elements(g102_list) eq 0 or strlowcase(f110_list[0]) eq 'none' then g102_list='none'
; IF n_elements(g141_list) eq 0 or strlowcase(f110_list[0]) eq 'none' then g141_list='none'
;  ; UVIS
; IF n_elements(UV1_list) eq 0 or strlowcase(UV1_list[0]) eq 'none' then UV1_list='none'
; IF n_elements(UV2_list) eq 0 or strlowcase(UV2_list[0]) eq 'none' then UV2_list='none'


IF strlowcase(f110_list[0]) eq 'none' then num110  =0
IF strlowcase(f140_list[0]) eq 'none' then num140  =0
IF strlowcase(f160_list[0]) eq 'none' then num160  =0
IF strlowcase(g102_list[0]) eq 'none' then numG102 =0
IF strlowcase(g141_list[0]) eq 'none' then numG141 =0
; UVIS
IF strlowcase(UV1_list[0]) eq 'none' then numUV1 =0
IF strlowcase(UV2_list[0]) eq 'none' then numUV2 =0

; ==================================================================
; KIND OF DATA TO BE MANAGED
; ==================================================================
H_only='NO'
both='NO'
uvis='NO'
;-------------------------------------------------------------------
; ONLY F140(or160) but both grisms
IF num110 eq 0 and numG102 gt 0 and numG141 gt 0 then H_only='YES'
; ONLY g141 grism (NO g102, but maybe both filters F110 and F160)
IF numG102 gt 0 and numG141 gt 0 then both="YES" 
; UVIS DATA
IF numUV1 gt 0 and numUV2 gt 0 then uvis='YES' ; never in previous two cases.

print, '=========================================================='
print, "Set of data:"
print, "H_only "+H_only
print, "both   "+both
print, "uvis   "+uvis
print, '------------------------------'
print, "H_only --> only F140 or F160 but both grisms."
print, "both   --> both G102 and G141 observations are present"
print, "uvis   --> uvis data are present"
print, '=========================================================='


; ==================================================================
; ==================================================================

;ooooooooooooooooooo   14   oooooooooooooooooooooo
printf,14,'import os,string,time'
printf,14,'import sys'
printf,14,'import shutil'
printf,14,'from pyraf import iraf'
printf,14,'from iraf import stsdas, slitless, axe, dither'
printf,14,'import drizzlepac'
printf,14,'from drizzlepac import astrodrizzle'
printf,14,'from pyraf.irafpar import IrafParS'
printf,14,'from stsci.tools import teal'
printf,14,'from stwcs import updatewcs'
printf,14, 'teal.unlearn("astrodrizzle")'
;ooooooooooooooooooo   14   oooooooooooooooooooooo
printf,14, 'import os'
printf,14, 'os.chdir("DATA/DIRECT/")'
if f110_list[0] ne 'none' and f110_list[0] ne '' then printf,14, 'updatewcs.updatewcs("@F110_clean.list")'
if f140_list[0] ne 'none' and f140_list[0] ne '' then printf,14, 'updatewcs.updatewcs("@F140_clean.list")'
if f160_list[0] ne 'none' and f160_list[0] ne '' then printf,14, 'updatewcs.updatewcs("@F160_clean.list")'
printf,14, 'os.chdir("../GRISM")'
if g102_list[0] ne 'none' and g102_list[0] ne '' then printf,14, 'updatewcs.updatewcs("@G102_clean.list")'
if g141_list[0] ne 'none' and g141_list[0] ne '' then printf,14, 'updatewcs.updatewcs("@G141_clean.list")'
;ooooooooooooooooooo   14   oooooooooooooooooooooo





;=========if F160 image exist, use F160 in driz.py; else use F140 images=========
if f160_list[0] ne 'none' then begin
   
 ; ------------------------------------------------------------
 h=headfits(path4+strmid(f160_list[0],0,13)+'.fits') 
 ra=strcompress(sxpar(h,'RA_TARG'),/remove_all)
 dec=strcompress(sxpar(h,'DEC_TARG'),/remove_all)
 ; ------------------------------------------------------------

 ;========= if uvis exist, add the IRtoUVIS & UVIStoIR options ===========
 if uvis eq 'YES' then begin
         
  printf,10,'                '
  if num160 gt 1 then begin
     printf,10,'astrodrizzle.AstroDrizzle("@F160_clean.list", output="../UVIS/IRtoUVIS/F160W_UVIS",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,final_scale=0.04,final_outnx=4800,final_outny=4800, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
     printf,10,'astrodrizzle.AstroDrizzle("@F160_clean.list", output="../UVIS/UVIStoIR/F160W_IR",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,final_scale=0.13,final_outnx=1600,final_outny=1600, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
  endif else begin
   IF num160 gt 0 THEN BEGIN
    printf,10,'astrodrizzle.AstroDrizzle("@F160_clean.list", output="../UVIS/IRtoUVIS/F160W_UVIS",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.04,final_outnx=4800,final_outny=4800, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
    printf,10,'astrodrizzle.AstroDrizzle("@F160_clean.list", output="../UVIS/UVIStoIR/F160W_IR",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.13,final_outnx=1600,final_outny=1600, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
     ENDIF
  endelse

 printf,10,'iraf.imcopy(input="../UVIS/IRtoUVIS/F160W_UVIS_drz.fits[1]", output="../UVIS/IRtoUVIS/F160W_UVIS_sci.fits")'
 printf,10,'iraf.imcopy(input="../UVIS/IRtoUVIS/F160W_UVIS_drz.fits[2]", output="../UVIS/IRtoUVIS/F160W_UVIS_wht.fits")'
 printf,10,'iraf.imcalc(input="../UVIS/IRtoUVIS/F160W_UVIS_wht.fits", output="../UVIS/IRtoUVIS/F160W_UVIS_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)

 printf,10,'iraf.imcopy(input="../UVIS/UVIStoIR/F160W_IR_drz.fits[1]", output="../UVIS/UVIStoIR/F160W_IR_sci.fits")'
 printf,10,'iraf.imcopy(input="../UVIS/UVIStoIR/F160W_IR_drz.fits[2]", output="../UVIS/UVIStoIR/F160W_IR_wht.fits")'
 printf,10,'iraf.imcalc(input="../UVIS/UVIStoIR/F160W_IR_wht.fits", output="../UVIS/UVIStoIR/F160W_IR_rms.fits", equals="1.0/sqrt(im1)")'; NEW solution (Suggeste by Marc)

 endif


endif 



;=========if F160 image does not exist, use F140 as default in driz.py
;       readcol,path4+'F140_clean.list',f140_list,format=('A')
;       num140 = n_elements(f140_list)
       
if f140_list[0] ne 'none' then begin
 ; ------------------------------------------------------------
 h=headfits(path4+strmid(f140_list[0],0,13)+'.fits') 
 ra=strcompress(sxpar(h,'RA_TARG'),/remove_all)
 dec=strcompress(sxpar(h,'DEC_TARG'),/remove_all)
 ; ------------------------------------------------------------
       
 ;========= if uvis exist, add the IRtoUVIS & UVIStoIR options ===========
 if uvis eq 'YES' then begin 

  printf,10,'                '
  if num140 gt 1 then begin
   printf,10,'astrodrizzle.AstroDrizzle("@F140_clean.list", output="../UVIS/IRtoUVIS/F140W_UVIS",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,final_scale=0.04,final_outnx=4800,final_outny=4800, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
   printf,10,'astrodrizzle.AstroDrizzle("@F140_clean.list", output="../UVIS/UVIStoIR/F140W_IR",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.13,final_outnx=1600,final_outny=1600, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
  endif else begin
   IF num140 gt 0 THEN printf,10,'astrodrizzle.AstroDrizzle("@F140_clean.list", output="../UVIS/IRtoUVIS/F140W_UVIS",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.04,final_outnx=4800,final_outny=4800, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
   IF num140 gt 0 THEN printf,10,'astrodrizzle.AstroDrizzle("@F140_clean.list", output="../UVIS/UVIStoIR/F140W_IR",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,final_scale=0.13,final_outnx=1600,final_outny=1600, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
  endelse

  printf,10,'iraf.imcopy(input="../UVIS/IRtoUVIS/F140W_UVIS_drz.fits[1]", output="../UVIS/IRtoUVIS/F140W_UVIS_sci.fits")'
  printf,10,'iraf.imcopy(input="../UVIS/IRtoUVIS/F140W_UVIS_drz.fits[2]", output="../UVIS/IRtoUVIS/F140W_UVIS_wht.fits")'
  printf,10,'iraf.imcalc(input="../UVIS/IRtoUVIS/F140W_UVIS_wht.fits", output="../UVIS/IRtoUVIS/F140W_UVIS_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)

  printf,10,'iraf.imcopy(input="../UVIS/UVIStoIR/F140W_IR_drz.fits[1]", output="../UVIS/UVIStoIR/F140W_IR_sci.fits")'
  printf,10,'iraf.imcopy(input="../UVIS/UVIStoIR/F140W_IR_drz.fits[2]", output="../UVIS/UVIStoIR/F140W_IR_wht.fits")'
  printf,10,'iraf.imcalc(input="../UVIS/UVIStoIR/F140W_IR_wht.fits", output="../UVIS/UVIStoIR/F140W_IR_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)

 endif

endif




if both eq 'YES' then begin

 if H_only eq 'YES' then begin
          
  if numG102 gt 1 then begin
   printf,10,'                '
   printf,10,'astrodrizzle.AstroDrizzle("@G102_clean.list", output="G102",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False)' 
  endif else begin
   IF numG102 gt 0 then printf,10,'astrodrizzle.AstroDrizzle("@G102_clean.list", output="G102",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,median=False,blot=False,driz_cr=False)' 
  endelse

  if numG141 gt 1 then begin
   printf,10,'                '
   printf,10,'astrodrizzle.AstroDrizzle("@G141_clean.list", output="G141",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False)' 
  endif else begin
   IF numG141 gt 0 then printf,10,'astrodrizzle.AstroDrizzle("@G141_clean.list", output="G141",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,median=False,blot=False,driz_cr=False)' 
  endelse


 endif else begin ; IF NOT ONLY F140 ....

        
  if f110_list[0] ne 'none' then begin
   h=headfits(path4+strmid(f110_list[0],0,13)+'.fits')  ;I.B. modified 2016
   ra10=strcompress(sxpar(h,'RA_TARG'),/remove_all)
   dec10=strcompress(sxpar(h,'DEC_TARG'),/remove_all)
  endif


          
;========= if uvis exist, add the IRtoUVIS & UVIStoIR options ===========
  if uvis eq 'YES' then begin 

   printf,10,'                '
   if num110 gt 1 then begin
    printf,10,'astrodrizzle.AstroDrizzle("@F110_clean.list", output="../UVIS/IRtoUVIS/F110W_UVIS",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,final_scale=0.04,final_outnx=4800,final_outny=4800, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
    printf,10,'astrodrizzle.AstroDrizzle("@F110_clean.list", output="../UVIS/UVIStoIR/F110W_IR",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,final_scale=0.13,final_outnx=1600,final_outny=1600, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
   endif else begin
    printf,10,'astrodrizzle.AstroDrizzle("@F110_clean.list", output="../UVIS/IRtoUVIS/F110W_UVIS",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.04,final_outnx=4800,final_outny=4800, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
    printf,10,'astrodrizzle.AstroDrizzle("@F110_clean.list", output="../UVIS/UVIStoIR/F110W_IR",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.13,final_outnx=1600,final_outny=1600, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
   endelse

   printf,10,'iraf.imcopy(input="../UVIS/IRtoUVIS/F110W_UVIS_drz.fits[1]", output="../UVIS/IRtoUVIS/F110W_UVIS_sci.fits")'
   printf,10,'iraf.imcopy(input="../UVIS/IRtoUVIS/F110W_UVIS_drz.fits[2]", output="../UVIS/IRtoUVIS/F110W_UVIS_wht.fits")'
   printf,10,'iraf.imcalc(input="../UVIS/IRtoUVIS/F110W_UVIS_wht.fits", output="../UVIS/IRtoUVIS/F110W_UVIS_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)

   printf,10,'iraf.imcopy(input="../UVIS/UVIStoIR/F110W_IR_drz.fits[1]", output="../UVIS/UVIStoIR/F110W_IR_sci.fits")'
   printf,10,'iraf.imcopy(input="../UVIS/UVIStoIR/F110W_IR_drz.fits[2]", output="../UVIS/UVIStoIR/F110W_IR_wht.fits")'
   printf,10,'iraf.imcalc(input="../UVIS/UVIStoIR/F110W_IR_wht.fits", output="../UVIS/UVIStoIR/F110W_IR_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)

  endif

 endelse 
       
endif

 
;prepare uvis_driz.py
if uvis eq 'YES' then begin   

 ;%%%%%%%%%%%%%%%%%%%   11   %%%%%%%%%%%%%%%%%%%%%%
 printf,11,'import os,string,time'
 printf,11,'import sys'
 printf,11,'import shutil'
 printf,11,'from pyraf import iraf'
 printf,11,'from iraf import stsdas, slitless, axe, dither'
 printf,11,'import drizzlepac'
 printf,11,'from drizzlepac import astrodrizzle'
 printf,11,'from pyraf.irafpar import IrafParS'
 printf,11,'from stsci.tools import teal'
 printf,11, 'teal.unlearn("astrodrizzle")'
 ;%%%%%%%%%%%%%%%%%%%   12   %%%%%%%%%%%%%%%%%%%%%%
 ;prepare uvis_initial_driz.py
 printf,12,'import os,string,time'
 printf,12,'import sys'
 printf,12,'import shutil'
 printf,12,'from pyraf import iraf'
 printf,12,'from iraf import stsdas, slitless, axe, dither'
 printf,12,'import drizzlepac'
 printf,12,'from drizzlepac import astrodrizzle'
 printf,12,'from pyraf.irafpar import IrafParS'
 printf,12,'from stsci.tools import teal'
 printf,12, 'teal.unlearn("astrodrizzle")'
 ;%%%%%%%%%%%%%%%%%%%   12   %%%%%%%%%%%%%%%%%%%%%%
 printf,12,'                '
 printf,12,'astrodrizzle.AstroDrizzle("@UVIS2.list", output="UVIS2",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False)' 
 printf,12,'iraf.imcopy(input="UVIS2_drz.fits[1]", output="UVIS2_sci.fits")'
 printf,12,'iraf.imcopy(input="UVIS2_drz.fits[2]", output="UVIS2_wht.fits")'
 printf,12,'iraf.imcalc(input="UVIS2_wht.fits", output="UVIS2_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)
 ;%%%%%%%%%%%%%%%%%%%   12   %%%%%%%%%%%%%%%%%%%%%%

 ;xxxxxxxxxxxxxxxxxxx   13   xxxxxxxxxxxxxxxxxxxxxx
 ;prepare uvis_updatewcs.py
 printf,13,'import os,string,time'
 printf,13,'import sys'
 printf,13,'import shutil'
 printf,13,'from pyraf import iraf'
 printf,13,'from iraf import stsdas, slitless, axe, dither'
 printf,13,'import drizzlepac'
 printf,13,'from drizzlepac import astrodrizzle'
 printf,13,'from pyraf.irafpar import IrafParS'
 printf,13,'from stsci.tools import teal'
 printf,13,'from stwcs import updatewcs'
 printf,13, 'teal.unlearn("astrodrizzle")'
 ;xxxxxxxxxxxxxxxxxxx   13   xxxxxxxxxxxxxxxxxxxxxx
 printf,13, 'updatewcs.updatewcs("@UVIS2.list")'
 ;xxxxxxxxxxxxxxxxxxx   13   xxxxxxxxxxxxxxxxxxxxxx



 printf,11,'                '
 printf,11,'astrodrizzle.AstroDrizzle("@UVIS2.list", output="UVIS2",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False)' 
 printf,11,'iraf.imcopy(input="UVIS2_drz.fits[1]", output="UVIS2_sci.fits")'
 printf,11,'iraf.imcopy(input="UVIS2_drz.fits[2]", output="UVIS2_wht.fits")'
 printf,11,'iraf.imcalc(input="UVIS2_wht.fits", output="UVIS2_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)

 ; IR to UVIS
 printf,11,'                '
 printf,11,'astrodrizzle.AstroDrizzle("@UVIS2.list", output="IRtoUVIS/UVIS2_UVIS",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,final_scale=0.04,final_outnx=4800,final_outny=4800,final_ra='+ra+',final_dec='+dec+')'
 printf,11,'iraf.imcopy(input="IRtoUVIS/UVIS2_UVIS_drz.fits[1]", output="IRtoUVIS/UVIS2_UVIS_sci.fits")'
 printf,11,'iraf.imcopy(input="IRtoUVIS/UVIS2_UVIS_drz.fits[2]", output="IRtoUVIS/UVIS2_UVIS_wht.fits")'
 printf,11,'iraf.imcalc(input="IRtoUVIS/UVIS2_UVIS_wht.fits", output="IRtoUVIS/UVIS2_UVIS_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)

 ; UVIS to IR
 printf,11,'astrodrizzle.AstroDrizzle("@UVIS2.list", output="UVIStoIR/UVIS2_IR",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,final_scale=0.13,final_outnx=1600,final_outny=1600,final_ra='+ra+',final_dec='+dec+')'
 printf,11,'iraf.imcopy(input="UVIStoIR/UVIS2_IR_drz.fits[1]", output="UVIStoIR/UVIS2_IR_sci.fits")'
 printf,11,'iraf.imcopy(input="UVIStoIR/UVIS2_IR_drz.fits[2]", output="UVIStoIR/UVIS2_IR_wht.fits")'
 printf,11,'iraf.imcalc(input="UVIStoIR/UVIS2_IR_wht.fits", output="UVIStoIR/UVIS2_IR_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)

 
 if file_test(path2+'DATA/UVIS/'+'UVIS1.list') then begin
  if file_lines(path2+'DATA/UVIS/'+'UVIS1.list') gt 0 then begin

   printf,11,'                '
   printf,11,'astrodrizzle.AstroDrizzle("@UVIS1.list", output="UVIS1",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False)' 
   printf,11,'iraf.imcopy(input="UVIS1_drz.fits[1]", output="UVIS1_sci.fits")'
   printf,11,'iraf.imcopy(input="UVIS1_drz.fits[2]", output="UVIS1_wht.fits")'
   printf,11,'iraf.imcalc(input="UVIS1_wht.fits", output="UVIS1_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)
;%%%%%%%%%%%%%%%%%%%   12   %%%%%%%%%%%%%%%%%%%%%%
   printf,12,'astrodrizzle.AstroDrizzle("@UVIS1.list", output="UVIS1",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False)' 
   printf,12,'iraf.imcopy(input="UVIS1_drz.fits[1]", output="UVIS1_sci.fits")'
   printf,12,'iraf.imcopy(input="UVIS1_drz.fits[2]", output="UVIS1_wht.fits")'
   printf,12,'iraf.imcalc(input="UVIS1_wht.fits", output="UVIS1_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)
;%%%%%%%%%%%%%%%%%%%   12   %%%%%%%%%%%%%%%%%%%%%%
;xxxxxxxxxxxxxxxxxxx   13   xxxxxxxxxxxxxxxxxxxxxx
   printf,13, 'updatewcs.updatewcs("@UVIS1.list")'
;xxxxxxxxxxxxxxxxxxx   13   xxxxxxxxxxxxxxxxxxxxxx

   ; IR to UVIS
   printf,11,'                '
   printf,11,'astrodrizzle.AstroDrizzle("@UVIS1.list", output="IRtoUVIS/UVIS1_UVIS",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,final_scale=0.04,final_outnx=4800,final_outny=4800,final_ra='+ra10+',final_dec='+dec10+')'
   printf,11,'iraf.imcopy(input="IRtoUVIS/UVIS1_UVIS_drz.fits[1]", output="IRtoUVIS/UVIS1_UVIS_sci.fits")'
   printf,11,'iraf.imcopy(input="IRtoUVIS/UVIS1_UVIS_drz.fits[2]", output="IRtoUVIS/UVIS1_UVIS_wht.fits")'
   printf,11,'iraf.imcalc(input="IRtoUVIS/UVIS1_UVIS_wht.fits", output="IRtoUVIS/UVIS1_UVIS_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)

   ; UVIS to IR
   printf,11,'astrodrizzle.AstroDrizzle("@UVIS1.list", output="UVIStoIR/UVIS1_IR",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,final_scale=0.13,final_outnx=1600,final_outny=1600,final_ra='+ra10+',final_dec='+dec10+')'
   printf,11,'iraf.imcopy(input="UVIStoIR/UVIS1_IR_drz.fits[1]", output="UVIStoIR/UVIS1_IR_sci.fits")'
   printf,11,'iraf.imcopy(input="UVIStoIR/UVIS1_IR_drz.fits[2]", output="UVIStoIR/UVIS1_IR_wht.fits")'
   printf,11,'iraf.imcalc(input="UVIStoIR/UVIS1_IR_wht.fits", output="UVIStoIR/UVIS1_IR_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)

  endif
 endif

endif



close,10,11,12,13,14
free_lun,10,11,12,13,14

spawn,'chmod 755 '+path3+'/*py'
spawn,'chmod 755 '+path2+'/DATA/UVIS/*py'
eend:

end
