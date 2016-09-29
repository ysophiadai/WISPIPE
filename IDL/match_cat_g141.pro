;##############################################################
;# WISPIPE
;# Reduction Pipeline for the WISP program (Atek et al. 2010)
;# Hakim Atek 2009
;# Edited by Sophia Dai 2014
;# Purpose: Run SExtractor on direct images, and then generate the
;# catalog in sorted magnitude order; Default is using F160 image, if
;# not available, F140 image would be used.
;
;
;###############################################################
PRO match_cat_g141,field,path0

;path="/Users/atek/Caltech/aXe/"+field+'/' 
path = path0+'/aXe/'+field+'/'


  readcol,path+'DATA/DIRECT_GRISM/F160_clean.list',f160_list,format=('A')
     

                    ;=======================================================
                    ;                   F160 IMAGE                         =
                    ;=======================================================
 
   if f160_list[0] ne 'none' then begin

;Run SExtractor on direct images
;**************************************
spawn,'cp '+path+'DATA/DIRECT_GRISM/F1*W_*fits '+path+'SEX/'

limit_160=measuremaglim_ir(path+'/DATA/DIRECT_GRISM/F160W_drz.fits',25.96,2.,0.01,5,0) ;plot parameter added to the end, default = 0 so no plot is shown

h2=headfits(path+'SEX/F160W_drz.fits') 
exptime2=strcompress(sxpar(h2,'EXPTIME'),/remove_all)
det='2.3'
spawn,'sex '+path+'SEX/F160W_sci.fits -c '+path+'SEX/config.sex -catalog_name '+path+$
      'SEX/F160W_'+det+'.cat -mag_zeropoint 25.96 -WEIGHT_TYPE MAP_WEIGHT,MAP_RMS -weight_image '$
      +path+'SEX/F160W_wht.fits,'+path+'SEX/F160W_rms.fits -parameters_name '+path+$
      'SEX/config.param -filter Y -filter_name '+path+'SEX/gauss_2.0_5x5.conv -detect_minarea 12 -detect_thresh '+det+$
      ' -ANALYSIS_THRESH 2.0 -DEBLEND_NTHRESH 64 -DEBLEND_MINCONT 0.005 -GAIN '+exptime2+' -STARNNW_NAME '+path+$
      'SEX/default.nnw -CHECKIMAGE_NAME '+path+'SEX/F160W_'+det+'_seg.fits '
seflag,'F160W',det,field,path0

READCOL,path+'SEX/F160W.cat',F160_number,x2,y2,a2,b2,theta2,x2_w,y2_w,a2_w,b2_w,theta2_w,mag2,magerr2,star2,flag2,/SILENT

ind1=where(mag2 eq 99)
if ind1[0] ne -1 then mag2(ind1)=limit_160

; MODIFY HEADERS
;*******************************
OPENR,lun,path+'SEX/F160W.cat',/get_lun
header_F160=strarr(15)
readf,lun,header_F160
header_F160(11)="#  12 MAG_F1537W        Kron-like elliptical aperture magnitude-AUTO    [mag]"
CLOSE,lun
FREE_LUN,lun

openw,u2,path+'SEX/cat_F160.cat',/get_lun

;READ ALL FILES AT ONCE
;******************************
cat_F160_m=DDREAD(path+'SEX/F160W.cat')

;SORT CATALOG BY MAGNITUDE
;******************************
ind_F160_m=sort(cat_F160_m[11,*])
cat_F160_m=cat_F160_m[*,ind_F160_m]

;CHANGE NUMBERING
;*****************************
cat_F160_m[0,*]=indgen(N_ELEMENTS(cat_F160_m[0,*]))+1

;CONCAT MATCHED
;***************
cat_F160=cat_F160_m
cat_F160[11,*]=mag2(ind_f160_m)


PRINTF,u2,header_F160
PRINTF,u2,cat_F160,FORMAT='((I0,10(2X,:,F0),(2X,:,F0.2),3(2X,:,F0.2)))' 

CLOSE,u2
FREE_LUN,u2

seflag,'F160W',det,field,path0

spawn,'cp '+path+'SEX/cat*.cat '+path+'DATA/DIRECT_GRISM/'   
     
   endif else begin



                    ;=======================================================
                    ;                   F140 IMAGE                         =
                    ;=======================================================
 
;Run SExtractor on direct images
;**************************************
spawn,'cp '+path+'DATA/DIRECT_GRISM/F1*W_*fits '+path+'SEX/'

;compare with marc's result
;limit_140=measuremaglim_ir('/Users/ydai/WISPIPE/Par248/DATA/DIRECT_GRISM/F140W_drz.fits',26.46,2.,0.01D,10,0) ;plot parameter added to the end, default = 0 so no plot is shown
limit_140=measuremaglim_ir(path+'/DATA/DIRECT_GRISM/F140W_drz.fits',26.46,2.,0.01D,10,0) ;plot parameter added to the end, default = 0 so no plot is shown

;F140W
h2=headfits(path+'SEX/F140W_drz.fits')
det='2.0'
exptime2=strcompress(sxpar(h2,'EXPTIME'),/remove_all)
spawn,'sex '+path+'SEX/F140W_sci.fits -c '+path+'SEX/config.sex -catalog_name '+path+$
      'SEX/F140W_'+det+'.cat -mag_zeropoint 26.46 -WEIGHT_TYPE MAP_WEIGHT,MAP_RMS -weight_image '$
      +path+'SEX/F140W_wht.fits,'+path+'SEX/F140W_rms.fits -parameters_name '+path+$
      'SEX/config.param -filter Y -filter_name '+path+'SEX/gauss_2.0_5x5.conv -detect_minarea 12 -detect_thresh '+det+$
      ' -ANALYSIS_THRESH 2.0 -DEBLEND_NTHRESH 64 -DEBLEND_MINCONT 0.005 -GAIN '+exptime2+' -STARNNW_NAME '+path+$
      'SEX/default.nnw -CHECKIMAGE_NAME '+path+'SEX/F140W_'+det+'_seg.fits '
seflag,'F140W',det,field,path0

READCOL,path+'SEX/F140W.cat',F140_number,x2,y2,a2,b2,theta2,x2_w,y2_w,a2_w,b2_w,theta2_w,mag2,magerr2,star2,flag2,/SILENT

ind1=where(mag2 eq 99)
if ind1[0] ne -1 then mag2(ind1)=limit_140

; MODIFY HEADERS
;*******************************
OPENR,lun,path+'SEX/F140W.cat',/get_lun
header_F140=strarr(15)
readf,lun,header_F140
header_F140(11)="#  12 MAG_F1392W             Kron-like elliptical aperture magnitude         [mag]"
CLOSE,lun
FREE_LUN,lun

openw,u2,path+'SEX/cat_F140.cat',/get_lun

;READ ALL FILES AT ONCE
;******************************
cat_F140_m=DDREAD(path+'SEX/F140W.cat')

;SORT CATALOG BY MAGNITUDE
;******************************
ind_F140_m=sort(cat_F140_m[11,*])
cat_F140_m=cat_F140_m[*,ind_F140_m]

;CHANGE NUMBERING
;*****************************
cat_F140_m[0,*]=indgen(N_ELEMENTS(cat_F140_m[0,*]))+1

;CONCAT MATCHED
;***************
cat_F140=cat_F140_m
cat_F140[11,*]=mag2(ind_f140_m)


PRINTF,u2,header_F140
;PRINTF,u2,cat_F140,FORMAT='((I0,10(2X,:,F0),(2X,:,F0.2),3(2X,:,F0.2)))' 
PRINTF,u2,cat_F140,FORMAT='((I5, 4(F10.3), F10.1, 4(F20.10), F10.1, 2F10.4, F10.2, I10))'

CLOSE,u2
FREE_LUN,u2

spawn,'cp '+path+'SEX/cat*.cat '+path+'DATA/DIRECT_GRISM/'


   endelse



END
