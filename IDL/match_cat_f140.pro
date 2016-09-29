;##############################################################
;# WISPIPE
;# Reduction Pipeline for the WISP program (Atek et al. 2010)
;# Hakim Atek 2009
;# Purpose:
;#        match catalogs generated from SourceExtractor on the
;# drizzled images, use weight image for detection, and rms image for
;# error estimates. Fixed -detect_minarea 6; -ANALYSIS_THRESH 2;
;# -DEBLEND_NTHRESH 64 -DEBLEND_MINCONT 0.005;
;# Detect_thresh is set to:
;#        F110W: 1.9 @ t_exp > 1041s, 2.3 @ t_exp < 1041s
;#        F140W: 2.0
;#        F160W: 2.3
;# 
;# Input:  
;#        F110W_sci.fits, F160W_sci.fits or F140_sci.fits
;#        F110W_wht.fits, F160W_wht.fits or F140_wht.fits
;#        F110W_rms.fits, F160W_rms.fits or F140_rms.fits
;# Output:
;#        cat_F110.cat, cat_F160.cat or cat_F140.cat
;# Calling:
;#        seflag.pro to flag objects falling at the 1. edge 2. bad
;# pixels 3. with elongated shape possibly due to diffraction of stars
;# or persistence
;#
;# Detect_minarea updated to 12 with the new pixlescale
;# Detect_thresh updated in 2015.2 to make it more efficient
;# Last edit
;# Sophia Dai, 2015.02.26
;###############################################################
PRO match_cat_f140,field,path0

path = path0+"/aXe/"+field+'/'


;=============================================================================
;                  Calculate the depth of the IR images                      = 
;=============================================================================

limit_110=measuremaglim_ir(path+'DATA/DIRECT_GRISM/F110W_drz.fits', 26.83, 2., 0.01, 5, 0)   ;plot parameter added to the end, default = 0 so no plot is shown
limit_140=measuremaglim_ir(path+'/DATA/DIRECT_GRISM/F140W_drz.fits', 26.46, 2., 0.01, 5, 0)   ;plot parameter added to the end, default = 0 so no plot is shown

;=============================================================================
;                  MATCH OBJECTS IN THE 2 GRISMS                             = 
;=============================================================================

dmax=1.5d-4 ; maximum distance for matching (degrees)


;Run SExtractor on direct images
;**************************************
spawn,'cp '+path+'DATA/DIRECT_GRISM/F1*W_*fits '+path+'SEX/'


;F110W
h1=headfits(path+'SEX/F110W_drz.fits') 
exptime1=strcompress(sxpar(h1,'EXPTIME'),/remove_all)
if exptime1 gt 1041 then det='1.9'
if exptime1 le 1041 then det='2.3'
spawn,'sex '+path+'SEX/F110W_sci.fits -c '+path+'SEX/config.sex -catalog_name '+path+$
      'SEX/F110W_'+det+'.cat -mag_zeropoint 26.83 -WEIGHT_TYPE MAP_WEIGHT,MAP_RMS -weight_image '$
      +path+'SEX/F110W_wht.fits,'+path+'SEX/F110W_rms.fits -parameters_name '+path+$
      'SEX/config.param -filter Y -filter_name '+path+'SEX/gauss_2.0_5x5.conv -detect_minarea 12 -detect_thresh '+det+$
      ' -ANALYSIS_THRESH 2.0 -DEBLEND_NTHRESH 64 -DEBLEND_MINCONT 0.005 -GAIN '+exptime1+' -STARNNW_NAME '+path+$
      'SEX/default.nnw -CHECKIMAGE_NAME '+path+'SEX/F110W_'+det+'_seg.fits '
seflag,'F110W',det,field,path0

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

;READ CATALOGS
openw,u1,path+'SEX/F110_m.cat',/get_lun
openw,u2,path+'SEX/F140_m.cat',/get_lun
openw,u3,path+'SEX/F110_um.cat',/get_lun
openw,u4,path+'SEX/F140_um.cat',/get_lun

READCOL,path+'SEX/F110W.cat',F110_number,x1,y1,a1,b1,theta1,x1_w,y1_w,a1_w,b1_w,theta1_w,mag1,magerr1,star1,flag1,/SILENT
READCOL,path+'SEX/F140W.cat',F140_number,x2,y2,a2,b2,theta2,x2_w,y2_w,a2_w,b2_w,theta2_w,mag2,magerr2,star2,flag2,/SILENT
;numbering=FINDGEN(N_ELEMENTS)

ind1=where(mag1 gt 30.)
ind2=where(mag2 gt 30.)
ind3=where(mag1 eq 99)
ind4=where(mag2 eq 99)

if ind1[0] ne -1 then mag1(ind1) = limit_110 
if ind2[0] ne -1 then mag2(ind2) = limit_140 
if ind3[0] ne -1 then mag1(ind3) = limit_110
if ind4[0] ne -1 then mag2(ind4) = limit_140


no_count=0
count=0
; MATCH F110 vs F140
;********************************
FOR i=0,N_ELEMENTS(F110_number)-1 DO BEGIN
match=0
       FOR j=0,N_ELEMENTS(F140_number)-1 DO BEGIN

d=SQRT( ((x1_w(i) - x2_w(j)))^2 + ((y1_w(i)-y2_w(j)))^2) 
 
             IF  SQRT( (x1_w(i) - x2_w(j))^2 + (y1_w(i)-y2_w(j))^2) LT dmax THEN BEGIN           
       ; matched ones goto u1
                printf,u1,F110_number(i),x1(i),y1(i),a1(i),b1(i),theta1(i),x1_w(i),y1_w(i),$
                a1_w(i),b1_w(i),theta1_w(i),mag1(i),magerr1(i),star1(i),flag1(i),FORMAT='(15(F20.10))'
                printf,u2,F140_number(j),x2(j),y2(j),a2(j),b2(j),theta2(j),x2_w(j),y2_w(j),$
                a2_w(j),b2_w(j),theta2_w(j),mag2(j),magerr2(j),star2(j),flag2(j),FORMAT='(15(F20.10))'
       
  ;  print,"match ....", i,"======",j,"======",SQRT( ((x1_w(i) - x2_w(j)))^2 + ((y1_w(i)-y2_w(j)))^2)*3600. 
                match=match+1 
                count=count+1         
             ENDIF
        
      ENDFOR
      ; OTHERWISE, SAVE THE REMAINDER OF F110
      IF (match EQ 0) THEN BEGIN 
        no_count=no_count+1
        printf,u3,F110_number(i),x1(i),y1(i),a1(i),b1(i),theta1(i),x1_w(i),y1_w(i),$
        a1_w(i),b1_w(i),theta1_w(i),mag1(i),magerr1(i),star1(i),flag1(i),FORMAT='(15(F20.10))'  
  ;   print,"NO match ....",d*3600.
      ENDIF 

ENDFOR

print,"******** MATCH = ",count,"*******"
print,"***** NO MATCH = ",no_count,"*******"

; KEEP THE REMAINDER OF F140
;*****************************
FOR j=0,N_ELEMENTS(F140_number)-1 DO BEGIN
match2=0
       FOR i=0,N_ELEMENTS(F110_number)-1 DO BEGIN
           IF  SQRT( (abs(x1_w(i) - x2_w(j)))^2 + (abs(y1_w(i)-y2_w(j)))^2) LT dmax THEN match2=match2+1
       ENDFOR      
       IF (match2 EQ 0) THEN BEGIN       
       printf,u4,F140_number(j),x2(j),y2(j),a2(j),b2(j),theta2(j),x2_w(j),y2_w(j),$
       a2_w(j),b2_w(j),theta2_w(j),mag2(j),magerr2(j),star2(j),flag2(j),FORMAT='(15(F20.10))'
       ENDIF
ENDFOR

CLOSE,u1,u2,u3,u4
FREE_LUN,u1,u2,u3,u4


; MODIFY HEADERS
;*******************************
OPENR,lun,path+'SEX/F110W.cat',/get_lun
header_F110=strarr(15)
header_F140=strarr(15)
readf,lun,header_F110
header_F140=header_F110
header_F110(11)="#  12 MAG_F1153W             Kron-like elliptical aperture magnitude-AUTO         [mag]"
header_F140(11)="#  12 MAG_F1392W             Kron-like elliptical aperture magnitude-AUTO         [mag]"
CLOSE,lun
FREE_LUN,lun

openw,u1,path+'SEX/cat_F110.cat',/get_lun
openw,u2,path+'SEX/cat_F140.cat',/get_lun

;READ ALL FILES AT ONCE
;******************************
cat_F110_m=DDREAD(path+'SEX/F110_m.cat')
cat_F110_um=DDREAD(path+'SEX/F110_um.cat')
cat_F140_m=DDREAD(path+'SEX/F140_m.cat')
cat_F140_um=DDREAD(path+'SEX/F140_um.cat')

;SORT CATALOGS BY MAGNITUDE
;******************************
ind_F110_m=sort(cat_F110_m[11,*])
cat_F110_m=cat_F110_m[*,ind_F110_m]
ind_F110_um=sort(cat_F110_um[11,*])
cat_F110_um=cat_F110_um[*,ind_F110_um]
;ind_F140_m=sort(cat_F140_m[11,*])
cat_F140_m=cat_F140_m[*,ind_F110_m]
ind_F140_um=sort(cat_F140_um[11,*])
cat_F140_um=cat_F140_um[*,ind_F140_um]

cat_F110_m[0,*]=fix(cat_F110_m[0,*])
cat_F110_um[0,*]=fix(cat_F110_um[0,*])
cat_F140_m[0,*]=fix(cat_F140_m[0,*])
cat_F140_um[0,*]=fix(cat_F140_um[0,*])

;CHANGE NUMBERING
;*****************************
cat_F110_m[0,*]=indgen(N_ELEMENTS(cat_F110_m[0,*]))+1
cat_F140_m[0,*]=indgen(N_ELEMENTS(cat_F140_m[0,*]))+1
cat_F110_um[0,*]=1000+indgen(N_ELEMENTS(cat_F110_um[0,*]))+1;cat_F110_um[0,*]
cat_F140_um[0,*]=2000+indgen(N_ELEMENTS(cat_F140_um[0,*]))+1;cat_F140_um[0,*]

;CONCAT MATHCED & UNMATCHED
;*****************************
cat_F110=[[cat_F110_m],[cat_F110_um],[cat_F140_um]]
cat_F140=[[cat_F140_m],[cat_F110_um],[cat_F140_um]]

cat_F110[11,where(cat_F110[0,*] ge 2000)]=limit_110
cat_F140[11,where(cat_F140[0,*] ge 1000 and cat_F140[0,*] lt 2000)]=limit_140


PRINTF,u1,header_F110
PRINTF,u2,header_F140
;PRINTF,u1,cat_F110,FORMAT='((I0,10(2X,:,F0),(2X,:,F0.2),3(2X,:,F0.2)))' 
;PRINTF,u2,cat_F140,FORMAT='((I0,10(2X,:,F0),(2X,:,F0.2),3(2X,:,F0.2)))' 
PRINTF,u1,cat_F110,FORMAT='((I5, 4(F10.3), F10.1, 4(F20.10), F10.1, 2F10.4, F10.2, I10))'
PRINTF,u2,cat_F140,FORMAT='((I5, 4(F10.3), F10.1, 4(F20.10), F10.1, 2F10.4, F10.2, I10))'
CLOSE,u1,u2
FREE_LUN,u1,u2

seflag,'F140W',det,field,path0,/blend

spawn,'cp '+path+'SEX/cat*.cat '+path+'DATA/DIRECT_GRISM/'



END
