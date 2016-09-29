pro uvis_initial_twk_IB2,field,path0, pathc

; Version 2
; In place of F600LP and F475X we call the filters
; with this new nomenclature:
; F475X  --> UVIS1
; F600LP --> UVIS2


  
path= path0+'/aXe/'+field+'/'
droppath= pathc+'/aXe/' ; not used anymore

spawn,'cp '+path+'DATA/UVIS/UVIS1*.fits '+path+'SEX/'
spawn,'cp '+path+'DATA/UVIS/UVIS2*.fits '+path+'SEX/'


;LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL
; I.B.
; SELECT TYPE OF DATA (both filters or only fUVIS1?)
FILT='A'
IF FILE_TEST(path+'DATA/UVIS/UVIS1_drz.fits') gt 0 then FILT='B' ;UVIS1

IF FILT ne 'B' then begin
print, '<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>><><><><>'
print, 'WARNING: no UVIS1 image found. This is ok if no observations were taken in this uvis filter'
print, '<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>><><><><>'
ENDIF
;LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL

;UVIS2
h1=headfits(path+'SEX/UVIS2_drz.fits') 
exptime0=strcompress(sxpar(h1,'EXPTIME'),/remove_all)
spawn,'sex '+path+'SEX/UVIS2_sci.fits -c '+path+'SEX/uvis.sex -catalog_name '+path+'SEX/UVIS2_initial.cat -parameters_name '+path+'SEX/config.param -mag_zeropoint 25.87 -WEIGHT_TYPE MAP_WEIGHT -weight_image '+path+'SEX/UVIS2_wht.fits -GAIN '+exptime0+' -STARNNW_NAME '+path+'SEX/default.nnw'


IF FILT eq 'B' then begin
 h2=headfits(path+'SEX/UVIS1_drz.fits') 
 exptime2=strcompress(sxpar(h2,'EXPTIME'),/remove_all)
 spawn,'sex '+path+'SEX/UVIS1_sci.fits -c '+path+'SEX/uvis.sex -catalog_name '+path+'SEX/UVIS1_initial.cat -parameters_name '+path+'SEX/config.param -mag_zeropoint 26.16 -WEIGHT_TYPE MAP_WEIGHT -weight_image '+path+'SEX/UVIS1_wht.fits -GAIN '+exptime2+' -STARNNW_NAME '+path+'SEX/default.nnw'
ENDIF


openw,1,path+'DATA/UVIS/'+'uvis_initial_twk.py' ; Program

printf,1,'import os,string,time'
printf,1,'import sys'
printf,1,'import shutil'
printf,1,'from pyraf import iraf'
printf,1,'from iraf import stsdas, dither'
printf,1,'import drizzlepac'
printf,1,'from drizzlepac import tweakreg'
printf,1,'from drizzlepac import astrodrizzle'
printf,1,'from pyraf.irafpar import IrafParS'
printf,1,'from drizzlepac import tweakback'

; TWEAKREG (note: only the "sci" extension is shifted).
printf,1,"tweakreg.TweakReg('@initial_input.list', catfile='initial_in.cat', refimage='../DIRECT_GRISM/F110W_drz.fits', refcat='../../SEX/F110.cat', updatehdr='Yes',  wcsname='IRwcs' ,xcol=2, ycol=3, fluxcol=12, fluxunits='mag', xyunits='pixels', refxcol=7, refycol=8, refxyunits='degrees', rfluxcol=12, rfluxunits='mag', minobj=15, searchrad=2.0, sigma=2.0, nclip=15,fitgeometry='shift')"

; Tweakbak the ORIGINAL uvis exposures
printf,1,"tweakback.tweakback('UVIS2_drz.fits',newname='IRwcs', input='@uvis_origUVIS2.list',force='True')"
IF FILT eq 'B' then begin
printf,1,"tweakback.tweakback('UVIS1_drz.fits',newname='IRwcs', input='@uvis_origUVIS1.list',force='True')"  
ENDIF

openw,2,path+'DATA/UVIS/'+'initial_input.list'       ; input images list (tweakreg)
openw,3,path+'DATA/UVIS/'+'initial_in.cat'           ; input catalogs list (tweakreg)
openw,4,path+'DATA/UVIS/'+'uvis_origUVIS2.list'           ; input catalogs list (tweakback)
openw,5,path+'DATA/UVIS/'+'uvis_origUVIS1.list'           ; input catalogs list (tweakback)

printf,2,"UVIS2_drz.fits"
printf,3,"UVIS2_drz.fits ../../SEX/UVIS2_initial.cat"

IF FILT eq 'B' then begin
   printf,2,"UVIS1_drz.fits"
   printf,3,"UVIS1_drz.fits ../../SEX/UVIS1_initial.cat"
ENDIF


readcol,path+'DATA/UVIS/UVIS2.list',listUVIS2,format='a'
PP=0L
while PP lt n_elements(listUVIS2) do begin
   printf,4,'UVIS_orig_WCS/'+listUVIS2[PP]
   PP=PP+1
endwhile

IF FILT eq 'B' then begin
 readcol,path+'DATA/UVIS/UVIS1.list',listUVIS1,format='a'
 PP=0L
 while PP lt n_elements(listUVIS1) do begin
    printf,5,'UVIS_orig_WCS/'+listUVIS1[PP]
    PP=PP+1
 endwhile
ENDIF


close,1,2,3,4,5
free_lun,1,2,3,4,5


end
