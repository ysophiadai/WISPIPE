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

pro im_clean_IB6,field,both=both,uvis=uvis,multidrizzle=multidrizzle,F140only=F140only, path0, pathc,script=script,single=single

;configpath ='/Users/ydai/WISPIPE/aXe/CONFIG/'  ; This is where the CONFIG folder is
;path="~/data2/WISPS/aXe/" ; This is where data will end up
;path_data='~/data2/WISPS/data/'+field+"/" ; this is where raw data are

;;;;configpath = path0+'/aXe/CONFIG/'
configpath = expand_path(pathc+'/aXe/CONFIG')+'/'
path = expand_path(path0)+'/aXe/'
path_data = expand_path(path0)+'/data/'+field+"/"

;path="/Users/atek/Caltech/aXe/"
;path_data='/Volumes/data/'+field+"/"
path2=path+field+"/"
path3=path2+'DATA/DIRECT_GRISM/'
; MODIFICATION BY I.B. The program will work on files in "DIRECT" and
;"GRISM" and not DIRECT_GRISM anymore.
path4=path2+'DATA/DIRECT/'
path5=path2+'DATA/GRISM/'

  spawn, 'ls -1 '+path2+'DATA/GRISM/i*flt.fits',grism_list
  grism_len=n_elements(grism_list)
  print,grism_list

  spawn, 'ls -1 '+path2+'DATA/DIRECT/i*flt.fits',direct_list
  direct_len=n_elements(direct_list)
  spawn, 'ls -1 '+path2+'DATA/GRISM/i*flt_clean.fits',clean_list



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

         ;tmp=strsplit(name,'.',/extract)
         ;tmp2=strsplit(tmp[0],'/',/extract)
         ;tmp3=strsplit(tmp2[8],'_',/extract)
         ;dq=path2+'DATA/GRISM/'+tmp3[0]+'_'+tmp3[1]+'.fits' 
         ;s_name=path2+'DATA/GRISM/m_sci_'+tmp2[8]+'.fits'   

            name = strtrim(name, 2)
            foob = strpos(name, '/', /reverse_search)   ;find position of '/'
            fooe = strpos(name, '.', /reverse_search)   ;find position of '.'
            fooe2 = strpos(name, '_', /reverse_search)  ;find position of the last'_'
            foo2 = strmid(name, foob+1,fooe2-foob-1)    ;foo2 is the name right after '/' before '_***.fits'
            foo3 = strmid(name, foob+1,fooe-foob-1)     ;foo3 is the name right after '/' before '.fits'
;            s_name=path2+'DATA/GRISM/m_sci_'+foo3+'.fits'  
            dq=path2+'DATA/GRISM/'+foo2+'.fits'         ;dq is the *_flt.fits file to be cleaned
 

;&&&&&&&&&&&&&&&&&&&&&&&  MODIFIED %%%%%%%%%%%%%%%
;;     s_grism=badpix(s_name,0,dq)
            s_grism=badpix(name,1,dq)                   ;creates a *_flt_clean.fits from _flt.fits input, with 1 

          tmp=readfits(name,hdr1,EXTEN_NO=1) 
;;        sxaddpar,hdr1,'BITPIX',-16

;&&&&&&&&&&&&&&&&&&&&&&&  MODIFIED %%%%%%%%%%%%%%%
         check_fits,s_grism,hdr1,/update
         modfits,name,s_grism,hdr1,EXTEN_NO = 1         ;replace the ***_flt_clean.fits with the bad pixel removed one
     endfor


; clean direct images
;*******************************************************
      print,"Sigma-rejection cleaning of direct images ....."
      clean_direct,direct_list                           ;all files in /DATA/DIRECT folder
      
; MODIFIED BY I.B. : direct and grism exposures are not copyied to the
; DIRECT_GRISM folder at this point (to prevent possible bugs) 
;      spawn, 'cp '+path2+'DATA/GRISM/i*clean.fits '+path3    
;       print,"Copying =====================================================",path2+'DATA/GRISM/*clean.fits TO '+path3 
;       spawn, 'cp '+path2+'DATA/DIRECT/*clean.fits '+path3
;       print,"Copying =====================================================",path2+'DATA/DIRECT/*clean.fits TO '+path3 
   
script:

;goto,eend
if not keyword_set(multidrizzle) then begin
; create the default astrodrizzle script
;***********************************
openw,10,path3+'driz.py'
openw,11,path2+'DATA/UVIS/uvis_driz.py'
openw,12,path2+'DATA/UVIS/uvis_initial_driz.py'
openw,13,path2+'DATA/UVIS/uvis_updatewcs.py'
openw,14,path2+'IR_updatewcs.py'



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

   readcol,path3+'F110_clean.list',f110_list,format=('A')
   readcol,path3+'F140_clean.list',f140_list,format=('A')
   readcol,path3+'F160_clean.list',f160_list,format=('A')
   readcol,path3+'G102_clean.list',g102_list,format=('A')
   readcol,path3+'G141_clean.list',g141_list,format=('A')
   numG141 = n_elements(G141_list)


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





       if f160_list[0] ne 'none' then begin
; h=headfits(path4+strmid(f160_list[0],0,13)+'.fits') ;I.B. modified 2016
          h=headfits(path4+strmid(f160_list[0],0,13)+'.fits') 
          ra=strcompress(sxpar(h,'RA_TARG'),/remove_all)
          dec=strcompress(sxpar(h,'DEC_TARG'),/remove_all)
       endif 

;=========if F160 image exist, use F160 in driz.py; else use F140 images=========
   if f160_list[0] ne 'none' then begin
      num = n_elements(f160_list)
;=========this step fixes the bad pixels by the mask; 1000 times along
;goto,no direct drizzle, cause already done in tweakreg.py
      print, "++++++++++"
      print, keyword_set(single)
      print, "++++++++++"
if not keyword_set(single) then  goto,nodirectdrz160
;the line interpolation
       printf,10,'                '
;       printf,10,'iraf.fixpix(images="@F160_clean.list'+'//[1]%''",masks="'+configpath+$
;              'bp_mask_v5.pl",linterp=1000,cinterp="INDEF")'
       printf,10,'iraf.fixpix(images="@F160_clean.list'+'//[1]%''",masks="'+configpath+$
              'bp_mask_v6.pl",linterp=1000,cinterp="INDEF")'
;=========depending on the number of G141 grism images, generate the G141_drz.fits
       if numG141 gt 1 then begin
         ;printf,10,'astrodrizzle.AstroDrizzle("@G141_clean.list", output="G141",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,final_scale=0.08,final_pixfrac=0.75)' 
          printf,10,'astrodrizzle.AstroDrizzle("@G141_clean.list", output="G141",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,final_scale=0.08,final_pixfrac=0.75)' 
       endif else begin
          ;printf,10,'astrodrizzle.AstroDrizzle("@G141_clean.list", output="G141",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.08,final_pixfrac=0.75)' 
          printf,10,'astrodrizzle.AstroDrizzle("@G141_clean.list", output="G141",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.08,final_pixfrac=0.75)' 
       endelse
;=========depending on the number of F160 direct images, generate F160W_drz.fits
       if num gt 1 then begin
          ;printf,10,'astrodrizzle.AstroDrizzle("@F160_clean.list", output="F160W",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,final_scale=0.08,final_pixfrac=0.75)' ;
          printf,10,'astrodrizzle.AstroDrizzle("@F160_clean.list", output="F160W",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,final_scale=0.08,final_pixfrac=0.75)' ;
       endif else begin
          ;printf,10,'astrodrizzle.AstroDrizzle("@F160_clean.list", output="F160W",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.08,final_pixfrac=0.75)'
          printf,10,'astrodrizzle.AstroDrizzle("@F160_clean.list", output="F160W",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.08,final_pixfrac=0.75)'
       endelse
;=========from the drizzled image, generate *_sci.fits; *_wht.fits;
;and correlated noise corrected *_rms.fits
       printf,10,'iraf.imcopy(input="F160W_drz.fits[1]", output="F160W_sci.fits")'
       printf,10,'iraf.imcopy(input="F160W_drz.fits[2]", output="F160W_wht.fits")'
       ;;; printf,10,'iraf.imcalc(input="F160W_wht.fits", output="F160W_rms.fits", equals="1.66354/sqrt(im1)")'
       printf,10,'iraf.imcalc(input="F160W_wht.fits", output="F160W_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)
       nodirectdrz160:
;========= if uvis exist, add the IRtoUVIS & UVIStoIR options ===========
    if keyword_set(uvis) then begin 
       printf,10,'                '
       if num gt 1 then begin
          ;printf,10,'astrodrizzle.AstroDrizzle("@F160_clean.list", output="../UVIS/IRtoUVIS/F160W_UVIS",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,final_scale=0.04,final_outnx=4800,final_outny=4800, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
          printf,10,'astrodrizzle.AstroDrizzle("@F160_clean.list", output="../UVIS/IRtoUVIS/F160W_UVIS",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,final_scale=0.04,final_outnx=4800,final_outny=4800, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
       endif else begin
          ;printf,10,'astrodrizzle.AstroDrizzle("@F160_clean.list", output="../UVIS/IRtoUVIS/F160W_UVIS",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.04,final_outnx=4800,final_outny=4800, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
       printf,10,'astrodrizzle.AstroDrizzle("@F160_clean.list", output="../UVIS/IRtoUVIS/F160W_UVIS",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.04,final_outnx=4800,final_outny=4800, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
       endelse
       
            printf,10,'iraf.imcopy(input="../UVIS/IRtoUVIS/F160W_UVIS_drz.fits[1]", output="../UVIS/IRtoUVIS/F160W_UVIS_sci.fits")'
            printf,10,'iraf.imcopy(input="../UVIS/IRtoUVIS/F160W_UVIS_drz.fits[2]", output="../UVIS/IRtoUVIS/F160W_UVIS_wht.fits")'
            ;;; printf,10,'iraf.imcalc(input="../UVIS/IRtoUVIS/F160W_UVIS_wht.fits", output="../UVIS/IRtoUVIS/F160W_UVIS_rms.fits", equals="2.8236/sqrt(im1)")'
            printf,10,'iraf.imcalc(input="../UVIS/IRtoUVIS/F160W_UVIS_wht.fits", output="../UVIS/IRtoUVIS/F160W_UVIS_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)
       if num gt 1 then begin
            ;printf,10,'astrodrizzle.AstroDrizzle("@F160_clean.list", output="../UVIS/UVIStoIR/F160W_IR",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,final_scale=0.13,final_outnx=1600,final_outny=1600, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
            printf,10,'astrodrizzle.AstroDrizzle("@F160_clean.list", output="../UVIS/UVIStoIR/F160W_IR",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,final_scale=0.13,final_outnx=1600,final_outny=1600, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
         endif else begin
           ; printf,10,'astrodrizzle.AstroDrizzle("@F160_clean.list", output="../UVIS/UVIStoIR/F160W_IR",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.13,final_outnx=1600,final_outny=1600, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
         printf,10,'astrodrizzle.AstroDrizzle("@F160_clean.list", output="../UVIS/UVIStoIR/F160W_IR",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.13,final_outnx=1600,final_outny=1600, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
         endelse
         printf,10,'iraf.imcopy(input="../UVIS/UVIStoIR/F160W_IR_drz.fits[1]", output="../UVIS/UVIStoIR/F160W_IR_sci.fits")'
         printf,10,'iraf.imcopy(input="../UVIS/UVIStoIR/F160W_IR_drz.fits[2]", output="../UVIS/UVIStoIR/F160W_IR_wht.fits")'
         ;;; printf,10,'iraf.imcalc(input="../UVIS/UVIStoIR/F160W_IR_wht.fits", output="../UVIS/UVIStoIR/F160W_IR_rms.fits", equals="1.66354/sqrt(im1)")'
         printf,10,'iraf.imcalc(input="../UVIS/UVIStoIR/F160W_IR_wht.fits", output="../UVIS/UVIStoIR/F160W_IR_rms.fits", equals="1.0/sqrt(im1)")'; NEW solution (Suggeste by Marc)
         endif
;========= removed north-up option =========
; depending on the number of F160 direct images, generate
; F160W_rot_drz.fits; note final_wcs=True,final_rot=0 are removed
;       if num gt 1 then begin
;          printf,10,'astrodrizzle.AstroDrizzle("@F160_clean.list", output="F160W_northup",num_cores=5,final_rot=0,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,final_scale=0.08,final_pixfrac=0.75)'
;       endif else begin
;          printf,10,'astrodrizzle.AstroDrizzle("@F160_clean.list", output="F160W_northup",num_cores=5,final_rot=0,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.08,final_pixfrac=0.75)'
;       endelse
;       printf,10,'iraf.imcopy(input="F160W_northup_drz.fits[1]", output="F160W_northup_sci.fits")'
;       printf,10,'iraf.imcopy(input="F160W_northup_drz.fits[2]", output="F160W_northup_wht.fits")'
;       printf,10,'iraf.imcalc(input="F160W_northup_wht.fits", output="F160W_northup_rms.fits", equals="1.66354/sqrt(im1)")'
    endif else begin 

;=========if F160 image does not exist, use F140 as default in driz.py
       readcol,path4+'F140_clean.list',f140_list,format=('A')
       num = n_elements(f140_list)
       if f140_list[0] ne 'none' then begin
; h=headfits(path3+strmid(f140_list[0],0,13)+'.fits')  ;I.B. modified 2016
          h=headfits(path4+strmid(f140_list[0],0,13)+'.fits') 
          ra=strcompress(sxpar(h,'RA_TARG'),/remove_all)
          dec=strcompress(sxpar(h,'DEC_TARG'),/remove_all)
       endif
if not keyword_set(single) then       goto,nodirectdrz140
       printf,10,'                '
    ;   printf,10,'iraf.fixpix(images="@F140_clean.list'+'//[1]%''",masks="'+configpath+$
    ;          'bp_mask_v5.pl",linterp=1000,cinterp="INDEF")'
       printf,10,'iraf.fixpix(images="@F140_clean.list'+'//[1]%''",masks="'+configpath+$
              'bp_mask_v6.pl",linterp=1000,cinterp="INDEF")'
       if numG141 gt 1 then begin
          ;printf,10,'astrodrizzle.AstroDrizzle("@G141_clean.list", output="G141",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False)' 
          printf,10,'astrodrizzle.AstroDrizzle("@G141_clean.list", output="G141",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False)' 
       endif else begin
          ;printf,10,'astrodrizzle.AstroDrizzle("@G141_clean.list", output="G141",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,median=False,blot=False,driz_cr=False)' 
          printf,10,'astrodrizzle.AstroDrizzle("@G141_clean.list", output="G141",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,median=False,blot=False,driz_cr=False)' 
       endelse
       if num gt 1 then begin
          ;printf,10,'astrodrizzle.AstroDrizzle("@F140_clean.list", output="F140W",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,final_scale=0.08,final_pixfrac=0.75)' 
          printf,10,'astrodrizzle.AstroDrizzle("@F140_clean.list", output="F140W",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,final_scale=0.08,final_pixfrac=0.75)' 
       endif else begin
          ;printf,10,'astrodrizzle.AstroDrizzle("@F140_clean.list", output="F140W",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.08,final_pixfrac=0.75)'
          printf,10,'astrodrizzle.AstroDrizzle("@F140_clean.list", output="F140W",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.08,final_pixfrac=0.75)'
       endelse
       printf,10,'iraf.imcopy(input="F140W_drz.fits[1]", output="F140W_sci.fits")'
       printf,10,'iraf.imcopy(input="F140W_drz.fits[2]", output="F140W_wht.fits")'
       ;;; printf,10,'iraf.imcalc(input="F140W_wht.fits", output="F140W_rms.fits", equals="1.66354/sqrt(im1)")'
       printf,10,'iraf.imcalc(input="F140W_wht.fits", output="F140W_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)
       nodirectdrz140:
;========= if uvis exist, add the IRtoUVIS & UVIStoIR options ===========
    if keyword_set(uvis) then begin 
           printf,10,'                '
           if num gt 1 then begin
              ;printf,10,'astrodrizzle.AstroDrizzle("@F140_clean.list", output="../UVIS/IRtoUVIS/F140W_UVIS",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,final_scale=0.04,final_outnx=4800,final_outny=4800, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
              printf,10,'astrodrizzle.AstroDrizzle("@F140_clean.list", output="../UVIS/IRtoUVIS/F140W_UVIS",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,final_scale=0.04,final_outnx=4800,final_outny=4800, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
       endif else begin
              ;printf,10,'astrodrizzle.AstroDrizzle("@F140_clean.list", output="../UVIS/IRtoUVIS/F140W_UVIS",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.04,final_outnx=4800,final_outny=4800, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
              printf,10,'astrodrizzle.AstroDrizzle("@F140_clean.list", output="../UVIS/IRtoUVIS/F140W_UVIS",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.04,final_outnx=4800,final_outny=4800, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
           endelse
            printf,10,'iraf.imcopy(input="../UVIS/IRtoUVIS/F140W_UVIS_drz.fits[1]", output="../UVIS/IRtoUVIS/F140W_UVIS_sci.fits")'
            printf,10,'iraf.imcopy(input="../UVIS/IRtoUVIS/F140W_UVIS_drz.fits[2]", output="../UVIS/IRtoUVIS/F140W_UVIS_wht.fits")'
            ;;; printf,10,'iraf.imcalc(input="../UVIS/IRtoUVIS/F140W_UVIS_wht.fits", output="../UVIS/IRtoUVIS/F140W_UVIS_rms.fits", equals="2.8236/sqrt(im1)")'
            printf,10,'iraf.imcalc(input="../UVIS/IRtoUVIS/F140W_UVIS_wht.fits", output="../UVIS/IRtoUVIS/F140W_UVIS_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)
            if num gt 1 then begin
              ;printf,10,'astrodrizzle.AstroDrizzle("@F140_clean.list", output="../UVIS/UVIStoIR/F140W_IR",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.13,final_outnx=1600,final_outny=1600, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
              printf,10,'astrodrizzle.AstroDrizzle("@F140_clean.list", output="../UVIS/UVIStoIR/F140W_IR",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.13,final_outnx=1600,final_outny=1600, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
       endif else begin
              ;printf,10,'astrodrizzle.AstroDrizzle("@F140_clean.list", output="../UVIS/UVIStoIR/F140W_IR",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,final_scale=0.13,final_outnx=1600,final_outny=1600, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
              printf,10,'astrodrizzle.AstroDrizzle("@F140_clean.list", output="../UVIS/UVIStoIR/F140W_IR",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,final_scale=0.13,final_outnx=1600,final_outny=1600, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
            endelse
       printf,10,'iraf.imcopy(input="../UVIS/UVIStoIR/F140W_IR_drz.fits[1]", output="../UVIS/UVIStoIR/F140W_IR_sci.fits")'
            printf,10,'iraf.imcopy(input="../UVIS/UVIStoIR/F140W_IR_drz.fits[2]", output="../UVIS/UVIStoIR/F140W_IR_wht.fits")'
            ;;; printf,10,'iraf.imcalc(input="../UVIS/UVIStoIR/F140W_IR_wht.fits", output="../UVIS/UVIStoIR/F140W_IR_rms.fits", equals="1.66354/sqrt(im1)")'
            printf,10,'iraf.imcalc(input="../UVIS/UVIStoIR/F140W_IR_wht.fits", output="../UVIS/UVIStoIR/F140W_IR_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)
         endif
;========= remove north-up option =========
;       if numG141 gt 1 then begin
;       if num gt 1 then begin
;          printf,10,'astrodrizzle.AstroDrizzle("@F140_clean.list", output="F140W_northup",num_cores=5,final_wcs=True,final_rot=0,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False)'
;       endif else begin
;          printf,10,'astrodrizzle.AstroDrizzle("@F140_clean.list", output="F140W_northup",num_cores=5,final_wcs=True,final_rot=0,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,median=False,blot=False,driz_cr=False)'
;       endelse
;       printf,10,'iraf.imcopy(input="F140W_northup_drz.fits[1]", output="F160W_northup_sci.fits")'
;       printf,10,'iraf.imcopy(input="F140W_northup_drz.fits[2]", output="F160W_northup_wht.fits")'
;       printf,10,'iraf.imcalc(input="F140W_northup_wht.fits", output="F160W_northup_rms.fits", equals="1.66354/sqrt(im1)")'
    endelse

;when both grisms are available, work on G102 as well
    if keyword_set(both) then begin

; readcol,path3+'G102_clean.list',G102_list,format=('A') ;I.B. modified 2016
       readcol,path5+'G102_clean.list',G102_list,format=('A') 
       numG102 = n_elements(G102_list)
       
;###############################
;if F140 only, stop here
       if keyword_set(F140only) then begin
          if numG102 gt 1 then begin
             printf,10,'                '
             ;printf,10,'astrodrizzle.AstroDrizzle("@G102_clean.list", output="G102",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False)' 
             printf,10,'astrodrizzle.AstroDrizzle("@G102_clean.list", output="G102",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False)' 
          endif else begin
             ;printf,10,'astrodrizzle.AstroDrizzle("@G102_clean.list", output="G102",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,median=False,blot=False,driz_cr=False)' 
             printf,10,'astrodrizzle.AstroDrizzle("@G102_clean.list", output="G102",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,median=False,blot=False,driz_cr=False)' 
          endelse
       endif else begin
;not only F140, add F110 drizzle
; readcol,path3+'F110_clean.list',f110_list,format=('A') ;I.B. modified 2016
 readcol,path4+'F110_clean.list',f110_list,format=('A') ;I.B. modified 2016
          num = n_elements(f110_list)
         if f110_list[0] ne 'none' then begin
; h=headfits(path3+strmid(f110_list[0],0,13)+'.fits')  ;I.B. modified 2016
          h=headfits(path4+strmid(f110_list[0],0,13)+'.fits')  ;I.B. modified 2016
          ra10=strcompress(sxpar(h,'RA_TARG'),/remove_all)
          dec10=strcompress(sxpar(h,'DEC_TARG'),/remove_all)
         endif
if not keyword_set(single) then    goto,nodirectdrz110
         printf,10,'                '        
;          printf,10,'iraf.fixpix(images="@F110_clean.list'+'//[1]%''",masks="'+configpath+$
;                 'bp_mask_v5.pl",linterp=1000,cinterp="INDEF")'  
          printf,10,'iraf.fixpix(images="@F110_clean.list'+'//[1]%''",masks="'+configpath+$
                 'bp_mask_v6.pl",linterp=1000,cinterp="INDEF")'  
          if numG102 gt 1 then begin
             ;printf,10,'astrodrizzle.AstroDrizzle("@G102_clean.list", output="G102",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False)' 
             printf,10,'astrodrizzle.AstroDrizzle("@G102_clean.list", output="G102",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False)' 
          endif else begin
             ;printf,10,'astrodrizzle.AstroDrizzle("@G102_clean.list", output="G102",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,median=False,blot=False,driz_cr=False)' 
             printf,10,'astrodrizzle.AstroDrizzle("@G102_clean.list", output="G102",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,median=False,blot=False,driz_cr=False)' 
          endelse
          if num gt 1 then begin
             ;printf,10,'astrodrizzle.AstroDrizzle("@F110_clean.list", output="F110W",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,final_scale=0.08,final_pixfrac=0.75)' ;
             printf,10,'astrodrizzle.AstroDrizzle("@F110_clean.list", output="F110W",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,final_scale=0.08,final_pixfrac=0.75)' ;
          endif else begin
             ;printf,10,'astrodrizzle.AstroDrizzle("@F110_clean.list", output="F110W",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.08,final_pixfrac=0.75)';,final_scale=0.08,final_pixfrac=0.75
             printf,10,'astrodrizzle.AstroDrizzle("@F110_clean.list", output="F110W",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.08,final_pixfrac=0.75)';,final_scale=0.08,final_pixfrac=0.75
          endelse
          printf,10,'iraf.imcopy(input="F110W_drz.fits[1]", output="F110W_sci.fits")'
          printf,10,'iraf.imcopy(input="F110W_drz.fits[2]", output="F110W_wht.fits")'
          ;;; printf,10,'iraf.imcalc(input="F110W_wht.fits", output="F110W_rms.fits", equals="1.66354/sqrt(im1)")'
          printf,10,'iraf.imcalc(input="F110W_wht.fits", output="F110W_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)
          nodirectdrz110:
;========= if uvis exist, add the IRtoUVIS & UVIStoIR options ===========
    if keyword_set(uvis) then begin 
            printf,10,'                '
            if num gt 1 then begin
               ;printf,10,'astrodrizzle.AstroDrizzle("@F110_clean.list", output="../UVIS/IRtoUVIS/F110W_UVIS",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,final_scale=0.04,final_outnx=4800,final_outny=4800, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
               printf,10,'astrodrizzle.AstroDrizzle("@F110_clean.list", output="../UVIS/IRtoUVIS/F110W_UVIS",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,final_scale=0.04,final_outnx=4800,final_outny=4800, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
          endif else begin
               ;printf,10,'astrodrizzle.AstroDrizzle("@F110_clean.list", output="../UVIS/IRtoUVIS/F110W_UVIS",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.04,final_outnx=4800,final_outny=4800, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
               printf,10,'astrodrizzle.AstroDrizzle("@F110_clean.list", output="../UVIS/IRtoUVIS/F110W_UVIS",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.04,final_outnx=4800,final_outny=4800, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
            endelse
          printf,10,'iraf.imcopy(input="../UVIS/IRtoUVIS/F110W_UVIS_drz.fits[1]", output="../UVIS/IRtoUVIS/F110W_UVIS_sci.fits")'
            printf,10,'iraf.imcopy(input="../UVIS/IRtoUVIS/F110W_UVIS_drz.fits[2]", output="../UVIS/IRtoUVIS/F110W_UVIS_wht.fits")'
            ;;; printf,10,'iraf.imcalc(input="../UVIS/IRtoUVIS/F110W_UVIS_wht.fits", output="../UVIS/IRtoUVIS/F110W_UVIS_rms.fits", equals="2.8236/sqrt(im1)")'
            printf,10,'iraf.imcalc(input="../UVIS/IRtoUVIS/F110W_UVIS_wht.fits", output="../UVIS/IRtoUVIS/F110W_UVIS_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)
          if num gt 1 then begin
            ;printf,10,'astrodrizzle.AstroDrizzle("@F110_clean.list", output="../UVIS/UVIStoIR/F110W_IR",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,final_scale=0.13,final_outnx=1600,final_outny=1600, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
            printf,10,'astrodrizzle.AstroDrizzle("@F110_clean.list", output="../UVIS/UVIStoIR/F110W_IR",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,final_scale=0.13,final_outnx=1600,final_outny=1600, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
          endif else begin
            ;printf,10,'astrodrizzle.AstroDrizzle("@F110_clean.list", output="../UVIS/UVIStoIR/F110W_IR",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.13,final_outnx=1600,final_outny=1600, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
            printf,10,'astrodrizzle.AstroDrizzle("@F110_clean.list", output="../UVIS/UVIStoIR/F110W_IR",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.13,final_outnx=1600,final_outny=1600, final_pixfrac=0.75,final_ra='+ra+',final_dec='+dec+')'
         endelse
          printf,10,'iraf.imcopy(input="../UVIS/UVIStoIR/F110W_IR_drz.fits[1]", output="../UVIS/UVIStoIR/F110W_IR_sci.fits")'
            printf,10,'iraf.imcopy(input="../UVIS/UVIStoIR/F110W_IR_drz.fits[2]", output="../UVIS/UVIStoIR/F110W_IR_wht.fits")'
            ;;; printf,10,'iraf.imcalc(input="../UVIS/UVIStoIR/F110W_IR_wht.fits", output="../UVIS/UVIStoIR/F110W_IR_rms.fits", equals="1.66354/sqrt(im1)")'
            printf,10,'iraf.imcalc(input="../UVIS/UVIStoIR/F110W_IR_wht.fits", output="../UVIS/UVIStoIR/F110W_IR_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)
         endif
;========= removed north-up option =========
;          if num gt 1 then begin
;             printf,10,'astrodrizzle.AstroDrizzle("@F110_clean.list", output="F110W_northup",num_cores=5,final_rot=0,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,final_scale=0.08,final_pixfrac=0.75)'
;          endif else begin
;             printf,10,'astrodrizzle.AstroDrizzle("@F110_clean.list", output="F110W_northup",num_cores=5,final_rot=0,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.08,final_pixfrac=0.75)'
;          endelse
;       printf,10,'iraf.imcopy(input="F110W_northup_drz.fits[1]", output="F160W_northup_sci.fits")'
;       printf,10,'iraf.imcopy(input="F110W_northup_drz.fits[2]", output="F160W_northup_wht.fits")'
;       printf,10,'iraf.imcalc(input="F110W_northup_wht.fits", output="F160W_northup_rms.fits", equals="1.66354/sqrt(im1)")'
       endelse
       
    endif

;prepare uvis_driz.py
    if keyword_set(uvis) then begin   
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
       ;printf,12,'astrodrizzle.AstroDrizzle("@UVIS2.list", output="UVIS2",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False)' 
       printf,12,'astrodrizzle.AstroDrizzle("@UVIS2.list", output="UVIS2",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False)' 
       printf,12,'iraf.imcopy(input="UVIS2_drz.fits[1]", output="UVIS2_sci.fits")'
       printf,12,'iraf.imcopy(input="UVIS2_drz.fits[2]", output="UVIS2_wht.fits")'
       ;;; printf,12,'iraf.imcalc(input="UVIS2_wht.fits", output="UVIS2_rms.fits", equals="1.5/sqrt(im1)")'
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


       
      ;printf,11,'astrodrizzle.AstroDrizzle("@UVIS1.list", output="UVIS1",final_wcs=True,final_rot=0,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False)'
      ;printf,11,'astrodrizzle.AstroDrizzle("@UVIS2.list",shiftfile="shift_600.list", output="UVIS2",final_wcs=True,final_rot=0,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False)' 
      printf,11,'                '
      ;printf,11,'astrodrizzle.AstroDrizzle("@UVIS2.list", output="UVIS2",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False)' 
      printf,11,'astrodrizzle.AstroDrizzle("@UVIS2.list", output="UVIS2",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False)' 
      printf,11,'iraf.imcopy(input="UVIS2_drz.fits[1]", output="UVIS2_sci.fits")'
      printf,11,'iraf.imcopy(input="UVIS2_drz.fits[2]", output="UVIS2_wht.fits")'
      ;;; printf,11,'iraf.imcalc(input="UVIS2_wht.fits", output="UVIS2_rms.fits", equals="1.5/sqrt(im1)")'
      printf,11,'iraf.imcalc(input="UVIS2_wht.fits", output="UVIS2_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)
      ; IR to UVIS
      printf,11,'                '
            ;printf,11,'astrodrizzle.AstroDrizzle("@UVIS2.list", output="IRtoUVIS/UVIS2_UVIS",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,final_scale=0.04,final_outnx=4800,final_outny=4800,final_ra='+ra+',final_dec='+dec+')'
            printf,11,'astrodrizzle.AstroDrizzle("@UVIS2.list", output="IRtoUVIS/UVIS2_UVIS",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,final_scale=0.04,final_outnx=4800,final_outny=4800,final_ra='+ra+',final_dec='+dec+')'
            printf,11,'iraf.imcopy(input="IRtoUVIS/UVIS2_UVIS_drz.fits[1]", output="IRtoUVIS/UVIS2_UVIS_sci.fits")'
            printf,11,'iraf.imcopy(input="IRtoUVIS/UVIS2_UVIS_drz.fits[2]", output="IRtoUVIS/UVIS2_UVIS_wht.fits")'
            ;;; printf,11,'iraf.imcalc(input="IRtoUVIS/UVIS2_UVIS_wht.fits", output="IRtoUVIS/UVIS2_UVIS_rms.fits", equals="1.5/sqrt(im1)")'
            printf,11,'iraf.imcalc(input="IRtoUVIS/UVIS2_UVIS_wht.fits", output="IRtoUVIS/UVIS2_UVIS_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)

      ; UVIS to IR
            ;printf,11,'astrodrizzle.AstroDrizzle("@UVIS2.list", output="UVIStoIR/UVIS2_IR",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,final_scale=0.13,final_outnx=1600,final_outny=1600,final_ra='+ra+',final_dec='+dec+')'
            printf,11,'astrodrizzle.AstroDrizzle("@UVIS2.list", output="UVIStoIR/UVIS2_IR",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,final_scale=0.13,final_outnx=1600,final_outny=1600,final_ra='+ra+',final_dec='+dec+')'
            printf,11,'iraf.imcopy(input="UVIStoIR/UVIS2_IR_drz.fits[1]", output="UVIStoIR/UVIS2_IR_sci.fits")'
            printf,11,'iraf.imcopy(input="UVIStoIR/UVIS2_IR_drz.fits[2]", output="UVIStoIR/UVIS2_IR_wht.fits")'
            ;;; printf,11,'iraf.imcalc(input="UVIStoIR/UVIS2_IR_wht.fits", output="UVIStoIR/UVIS2_IR_rms.fits", equals="1.11/sqrt(im1)")'
            printf,11,'iraf.imcalc(input="UVIStoIR/UVIS2_IR_wht.fits", output="UVIStoIR/UVIS2_IR_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)
      if file_test(path2+'DATA/UVIS/'+'UVIS1.list') then begin
         if file_lines(path2+'DATA/UVIS/'+'UVIS1.list') gt 0 then begin
            ;printf,11,'astrodrizzle.AstroDrizzle("@UVIS1.list",shiftfile="shift_475.list", output="UVIS1",final_wcs=True,final_rot=0,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False)' 
            printf,11,'                '
            printf,11,'astrodrizzle.AstroDrizzle("@UVIS1.list", output="UVIS1",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False)' 
            printf,11,'iraf.imcopy(input="UVIS1_drz.fits[1]", output="UVIS1_sci.fits")'
            printf,11,'iraf.imcopy(input="UVIS1_drz.fits[2]", output="UVIS1_wht.fits")'
            ;;; printf,11,'iraf.imcalc(input="UVIS1_wht.fits", output="UVIS1_rms.fits", equals="1.5/sqrt(im1)")'
            printf,11,'iraf.imcalc(input="UVIS1_wht.fits", output="UVIS1_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)
;%%%%%%%%%%%%%%%%%%%   12   %%%%%%%%%%%%%%%%%%%%%%
            ;printf,12,'astrodrizzle.AstroDrizzle("@UVIS1.list", output="UVIS1",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False)' 
            printf,12,'astrodrizzle.AstroDrizzle("@UVIS1.list", output="UVIS1",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False)' 
            printf,12,'iraf.imcopy(input="UVIS1_drz.fits[1]", output="UVIS1_sci.fits")'
            printf,12,'iraf.imcopy(input="UVIS1_drz.fits[2]", output="UVIS1_wht.fits")'
            ;;; printf,12,'iraf.imcalc(input="UVIS1_wht.fits", output="UVIS1_rms.fits", equals="1.5/sqrt(im1)")'
            printf,12,'iraf.imcalc(input="UVIS1_wht.fits", output="UVIS1_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)
;%%%%%%%%%%%%%%%%%%%   12   %%%%%%%%%%%%%%%%%%%%%%
;xxxxxxxxxxxxxxxxxxx   13   xxxxxxxxxxxxxxxxxxxxxx
       printf,13, 'updatewcs.updatewcs("@UVIS1.list")'
;xxxxxxxxxxxxxxxxxxx   13   xxxxxxxxxxxxxxxxxxxxxx
      ; IR to UVIS
            printf,11,'                '
            ;printf,11,'astrodrizzle.AstroDrizzle("@UVIS1.list", output="IRtoUVIS/UVIS1_UVIS",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,final_scale=0.04,final_outnx=4800,final_outny=4800,final_ra='+ra10+',final_dec='+dec10+')'
            printf,11,'astrodrizzle.AstroDrizzle("@UVIS1.list", output="IRtoUVIS/UVIS1_UVIS",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,final_scale=0.04,final_outnx=4800,final_outny=4800,final_ra='+ra10+',final_dec='+dec10+')'
            printf,11,'iraf.imcopy(input="IRtoUVIS/UVIS1_UVIS_drz.fits[1]", output="IRtoUVIS/UVIS1_UVIS_sci.fits")'
            printf,11,'iraf.imcopy(input="IRtoUVIS/UVIS1_UVIS_drz.fits[2]", output="IRtoUVIS/UVIS1_UVIS_wht.fits")'
            ;;; printf,11,'iraf.imcalc(input="IRtoUVIS/UVIS1_UVIS_wht.fits", output="IRtoUVIS/UVIS1_UVIS_rms.fits", equals="1.5/sqrt(im1)")'
            printf,11,'iraf.imcalc(input="IRtoUVIS/UVIS1_UVIS_wht.fits", output="IRtoUVIS/UVIS1_UVIS_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)
      ; UVIS to IR
            ;printf,11,'astrodrizzle.AstroDrizzle("@UVIS1.list", output="UVIStoIR/UVIS1_IR",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,final_scale=0.13,final_outnx=1600,final_outny=1600,final_ra='+ra10+',final_dec='+dec10+')'
            printf,11,'astrodrizzle.AstroDrizzle("@UVIS1.list", output="UVIStoIR/UVIS1_IR",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,final_scale=0.13,final_outnx=1600,final_outny=1600,final_ra='+ra10+',final_dec='+dec10+')'
            printf,11,'iraf.imcopy(input="UVIStoIR/UVIS1_IR_drz.fits[1]", output="UVIStoIR/UVIS1_IR_sci.fits")'
            printf,11,'iraf.imcopy(input="UVIStoIR/UVIS1_IR_drz.fits[2]", output="UVIStoIR/UVIS1_IR_wht.fits")'
            ;;; printf,11,'iraf.imcalc(input="UVIStoIR/UVIS1_IR_wht.fits", output="UVIStoIR/UVIS1_IR_rms.fits", equals="1.11/sqrt(im1)")'
            printf,11,'iraf.imcalc(input="UVIStoIR/UVIS1_IR_wht.fits", output="UVIStoIR/UVIS1_IR_rms.fits", equals="1.0/sqrt(im1)")' ; NEW solution (Suggeste by Marc)
         endif
      endif
     
      ;********************
; skip the north-up version
;      printf,11, 'teal.unlearn("astrodrizzle")'
;      printf,11,'astrodrizzle.AstroDrizzle("@UVIS2.list", output="UVIS2_northup",final_wcs=True,final_rot=0,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False)' 
;      if file_test(path2+'DATA/UVIS/'+'UVIS1.list') then begin
;         if file_lines(path2+'DATA/UVIS/'+'UVIS1.list') gt 0 then begin
;            printf,11,'astrodrizzle.AstroDrizzle("@UVIS1.list", output="UVIS1_northup",final_wcs=True,final_rot=0,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False)' 
;         endif
;      endif

   endif


 endif

close,10,11,12,13,14
free_lun,10,11,12,13,14

spawn,'chmod 755 '+path3+'/*py'
spawn,'chmod 755 '+path2+'/DATA/UVIS/*py'
eend:

end
