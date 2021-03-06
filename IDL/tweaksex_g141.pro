;##############################################################
;# WISPIPE
;# Reduction Pipeline for the WISP program
;# Generated by Sophia Dai 2014
;# Purpose: 
;#       generate catalogs with SEXtractor on the CR cleaned flt images
;# Input:  
;#      F160_crclean.list or F140_crclean.list
;# Output:
;#       cat_F160.cat or cat_F140.cat in SEX/ folder
;#       tweakreg.py in DATA/DIRECT folder
;# 
;###############################################################
pro tweaksex_g141,field,path0,F140only=F140only

  path = path0+'/aXe/'+field+'/'
  configpath = path0+'/aXe/CONFIG/'

;path = '/Volumes/Kudo/DATA/WISPS/aXe/Par288-full/'
;tweaksex,'Par288-full','/Volumes/Kudo/DATA/WISPS'

readcol,path+'DATA/DIRECT_GRISM/F160_clean.list',f160_list0,format=('A')

if  f160_list0[0] ne 'none' then readcol,path+'DATA/DIRECT/F160_crclean.list',f160_list,format=('A')
if  f160_list0[0] eq 'none' then readcol,path+'DATA/DIRECT/F140_crclean.list',f140_list,format=('A')

; Run SExtractor on CR cleaned direct flt images
; **************************************

if f160_list0[0] ne 'none' then begin
for i = 0, n_elements(f160_list)-1 do begin
    h2=headfits(path+'DATA/DIRECT/'+strmid(f160_list[i],0,19)+'_crclean.fits') 
    exptime2=strcompress(sxpar(h2,'EXPTIME'),/remove_all)
    det='2.3'
    spawn,'sex '+path+'DATA/DIRECT/'+strmid(f160_list[i],0,19)+'_crclean.fits -c '+path+'SEX/config.sex -catalog_name '+path+$
          'SEX/'+f160_list[i]+'.coo -mag_zeropoint 25.96 -WEIGHT_TYPE MAP_WEIGHT -weight_image '+path+$
          'DATA/DIRECT/'+strmid(f160_list[i],0,19)+'_crclean.fits'+$
          ' -parameters_name '+path+$
          'SEX/config.param -filter Y -filter_name '+path+'SEX/gauss_2.0_5x5.conv -detect_minarea 6 -detect_thresh '+det+$
          ' -ANALYSIS_THRESH 2 -CHECKIMAGE_NAME '+path+$
          'SEX/'+strmid(f160_list[i],0,19)+'_crclean_seg.fits -DEBLEND_NTHRESH 16 -DEBLEND_MINCONT 0.005 -GAIN '+exptime2+$
          ' -STARNNW_NAME '+path+'SEX/default.nnw'
    spawn,'cp '+path+'SEX/'+f160_list[i]+'.coo '+path+'DATA/DIRECT/'
endfor
endif else begin
   for i = 0, n_elements(f140_list)-1 do begin
    h2=headfits(path+'DATA/DIRECT/'+strmid(f140_list[i],0,19)+'_crclean.fits') 
    exptime2=strcompress(sxpar(h2,'EXPTIME'),/remove_all)
    det='2.0'
    spawn,'sex '+path+'DATA/DIRECT/'+strmid(f140_list[i],0,19)+'_crclean.fits -c '+path+'SEX/config.sex -catalog_name '+path+$
          'SEX/'+f140_list[i]+'.coo -mag_zeropoint 26.46 -WEIGHT_TYPE MAP_WEIGHT -weight_image '+path+$
          'DATA/DIRECT/'+strmid(f140_list[i],0,19)+'_crclean.fits'+$
          ' -parameters_name '+path+$
          'SEX/config.param -filter Y -filter_name '+path+'SEX/gauss_2.0_5x5.conv -detect_minarea 6 -detect_thresh '+det+$
          ' -ANALYSIS_THRESH 2 -CHECKIMAGE_NAME '+path+$
          'SEX/'+strmid(f140_list[i],0,19)+'_crclean_seg.fits -DEBLEND_NTHRESH 64 -DEBLEND_MINCONT 0.005 -GAIN '+exptime2+$
          ' -STARNNW_NAME '+path+'SEX/default.nnw'
    spawn,'cp '+path+'SEX/'+f140_list[i]+'.coo '+path+'DATA/DIRECT/'
   endfor
endelse


;Run SExtractor on direct images
;*************************************

if f160_list0[0] ne 'none' then begin
;F160W
   h2=headfits(path+'DATA/DIRECT/F160W_orig_drz.fits') 
   exptime2=strcompress(sxpar(h2,'EXPTIME'),/remove_all)
   det='2.3'
   spawn,'sex '+path+'DATA/DIRECT/F160W_orig_sci.fits -c '+path+'SEX/config.sex -catalog_name '+path+'SEX/F160.cat -mag_zeropoint 25.96 -WEIGHT_TYPE MAP_WEIGHT,MAP_RMS -weight_image '+path+'DATA/DIRECT/F160W_orig_wht.fits,'+path+'DATA/DIRECT/F160W_orig_rms.fits -parameters_name '+path+'SEX/config.param -filter Y -filter_name '+path+'SEX/gauss_2.0_5x5.conv -detect_minarea 6 -detect_thresh '+det+' -ANALYSIS_THRESH 2 -CHECKIMAGE_NAME '+path+'SEX/F160_seg.fits -DEBLEND_NTHRESH 64 -DEBLEND_MINCONT 0.005 -GAIN '+exptime2+' -STARNNW_NAME '+path+'SEX/default.nnw'
   spawn,'cp '+path+'SEX/F160.cat '+path+'DATA/DIRECT/'
endif else begin
;F140W
   for i = 0, n_elements(f140_list)-1 do begin
   h2=headfits(path+'DATA/DIRECT/F140W_orig_drz.fits') 
   exptime2=strcompress(sxpar(h2,'EXPTIME'),/remove_all)
   det='2.0'
   spawn,'sex '+path+'DATA/DIRECT/F140W_orig_sci.fits'+' -c '+path+'SEX/config.sex -catalog_name '+path+'SEX/F140.cat -mag_zeropoint 26.46 -WEIGHT_TYPE MAP_WEIGHT,MAP_RMS -weight_image '+path+'DATA/DIRECT/F140W_orig_wht.fits,'+path+'DATA/DIRECT/F140W_orig_rms.fits -parameters_name '+path+'SEX/config.param -filter Y -filter_name '+path+'SEX/gauss_2.0_5x5.conv -detect_minarea 6 -detect_thresh '+det+' -ANALYSIS_THRESH 2 -CHECKIMAGE_NAME '+path+'SEX/F140_seg.fits -DEBLEND_NTHRESH 64 -DEBLEND_MINCONT 0.005 -GAIN '+exptime2+' -STARNNW_NAME '+path+'SEX/default.nnw'
   spawn,'cp '+path+'SEX/F140.cat '+path+'DATA/DIRECT/'
   endfor
endelse


;Now generate the python code to tweakreg each flt file to the
;drizzled F160W or F140W file
;*************************************
openw,6,path+'DATA/DIRECT/tweakreg.py'
   printf,6,'import os,string,time'
   printf,6,'import sys'
   printf,6,'import shutil'
   printf,6,'from pyraf import iraf'
   printf,6,'from iraf import stsdas, dither'
   printf,6,'from pyraf.irafpar import IrafParS'
   printf,6,'from stsci.tools import teal'
   printf,6,'import drizzlepac'
   printf,6,'from drizzlepac import tweakreg'
   printf,6,'from drizzlepac import astrodrizzle'
   printf,6,'from drizzlepac import tweakback'
   printf,6,'import glob'
   printf,6,'from stwcs import wcsutil'
   printf,6,'import stwcs.wcsutil.headerlet'
   printf,6,'                '

;generate the position-shift headerlet for the crclean.fits as
;compared to F160W_orig_drz.fits
;*************************************


if not keyword_set(F140only) and f160_list0[0] ne 'none' then begin 
   printf,6,'tweakreg.TweakReg("@direct_clean.list",catfile="direct_clean_catfile.list", refimage="F160W_orig_drz.fits",refcat="F160.cat",  wcsname="shift1", updatehdr=False, updatewcs=False,xcol=2, ycol=3, fluxcol=12, fluxunits="mag", xyunits="pixels",  refxcol=7, refycol=8, refxyunits="degrees", rfluxcol=12, rfluxunits="mag", minobj=15, searchrad=1.0, sigma=4.0, nclip=3, shiftfile=True,outshifts="shift_pos_drz_clean.txt", headerlet=True,fitgeometry="shift")'

   printf,6,'tweakreg.TweakReg("@direct_crclean.list",catfile="direct_crclean_catfile.list", refimage="F160W_orig_drz.fits",refcat="F160.cat", wcsname="shift1", updatehdr=False, updatewcs=False,xcol=2, ycol=3, fluxcol=12, fluxunits="mag", xyunits="pixels",  refxcol=7, refycol=8, refxyunits="degrees", rfluxcol=12, rfluxunits="mag", minobj=15, searchrad=1.0, sigma=4.0, nclip=3, shiftfile=True,outshifts="shift_pos_drz_crclean.txt", headerlet=True,fitgeometry="shift")'
endif else begin
   printf,6,'tweakreg.TweakReg("@direct_clean.list",catfile="direct_clean_catfile.list", refimage="F140W_orig_drz.fits",refcat="F140.cat",  wcsname="shift1", updatehdr=False, updatewcs=False,xcol=2, ycol=3, fluxcol=12, fluxunits="mag", xyunits="pixels",  refxcol=7, refycol=8, refxyunits="degrees", rfluxcol=12, rfluxunits="mag", minobj=15, searchrad=1.0, sigma=4.0, nclip=3, shiftfile=True,outshifts="shift_pos_drz_clean.txt", headerlet=True,fitgeometry="shift")'

   printf,6,'tweakreg.TweakReg("@direct_crclean.list",catfile="direct_crclean_catfile.list", refimage="F140W_orig_drz.fits",refcat="F140.cat", wcsname="shift1", updatehdr=False, updatewcs=False,xcol=2, ycol=3, fluxcol=12, fluxunits="mag", xyunits="pixels",  refxcol=7, refycol=8, refxyunits="degrees", rfluxcol=12, rfluxunits="mag", minobj=15, searchrad=1.0, sigma=4.0, nclip=3, shiftfile=True,outshifts="shift_pos_drz_crclean.txt", headerlet=True,fitgeometry="shift")'

endelse


;apply the headerlet to each exposure's direct image
;*************************************
   printf,6,'                '
   printf,6,'from stsci.tools import teal'
   printf,6,'import stwcs'
   printf,6,'cobj = teal.teal("apply_headerlet", loadOnly=True)'
   printf,6,'                '

if f160_list0[0] ne 'none' then begin
   for i = 0, n_elements(f160_list)-1 do begin
   printf,6,'cobj["filename"] = "'+strmid(f160_list[i],0,19)+'.fits"'
   printf,6,'cobj["hdrlet"] = "'+strmid(f160_list[i],0,19)+'_crclean_hlet.fits"'
   printf,6,'stwcs.gui.apply_headerlet.run(cobj)'
   endfor
endif else begin
   for i = 0, n_elements(f140_list)-1 do begin
   printf,6,'cobj["filename"] = "'+strmid(f140_list[i],0,19)+'.fits"'
   printf,6,'cobj["hdrlet"] = "'+strmid(f140_list[i],0,19)+'_crclean_hlet.fits"'
   printf,6,'stwcs.gui.apply_headerlet.run(cobj)'
   endfor
endelse

;now drizzled to get the twked images
;**********************
   printf,6,'                '

if f160_list0[0] ne 'none' then begin
   printf,6,'iraf.fixpix(images="@F160_clean.list'+'//[1]%''",masks="'+configpath+$
          'bp_mask_v5.pl",linterp=1000,cinterp="INDEF")'
   num = n_elements(f160_list)
   if num gt 1 then begin
      printf,6,'astrodrizzle.AstroDrizzle("@F160_clean.list", output="F160W_twk",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False, driz_cr_corr=True, driz_combine=True,final_scale=0.08,final_pixfrac=0.75)'
   endif else begin
      printf,6,'astrodrizzle.AstroDrizzle("@F160_clean.list", output="F160W_twk",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.08,final_pixfrac=0.75)'
   endelse      
   printf,6,'iraf.imcopy(input="F160W_twk_drz.fits[1]", output="F160W_twk_sci.fits")'
   printf,6,'iraf.imcopy(input="F160W_twk_drz.fits[2]", output="F160W_twk_wht.fits")'
   printf,6,'iraf.imcalc(input="F160W_twk_wht.fits", output="F160W_twk_rms.fits", equals="1.66354/sqrt(im1)")'
endif else begin
   printf,6,'iraf.fixpix(images="@F140_clean.list'+'//[1]%''",masks="'+configpath+$
              'bp_mask_v5.pl",linterp=1000,cinterp="INDEF")'
   num = n_elements(f140_list)
   if num gt 1 then begin
      printf,6,'astrodrizzle.AstroDrizzle("@F140_clean.list", output="F140W_twk",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False, driz_cr_corr=True, driz_combine=True,final_scale=0.08,final_pixfrac=0.75)'
   endif else begin
      printf,6,'astrodrizzle.AstroDrizzle("@F140_clean.list", output="F140W_twk",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.08,final_pixfrac=0.75)'
   endelse   
   printf,6,'iraf.imcopy(input="F140W_twk_drz.fits[1]", output="F140W_twk_sci.fits")'
   printf,6,'iraf.imcopy(input="F140W_twk_drz.fits[2]", output="F140W_twk_wht.fits")'
   printf,6,'iraf.imcalc(input="F140W_twk_wht.fits", output="F140W_twk_rms.fits", equals="1.66354/sqrt(im1)")'
endelse   


close,6
free_lun,6

; now update the *filter*_clean.list in DIRECT_GRISM/ folder to
; prepare for driz.py
    spawn,'cp '+path+'DATA/DIRECT/F160_crclean.list '+path+'DATA/DIRECT_GRISM/'
    spawn,'cp '+path+'DATA/DIRECT/F140_crclean.list '+path+'DATA/DIRECT_GRISM/'
   
end
