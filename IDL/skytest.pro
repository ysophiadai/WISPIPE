;purpose: a series of test to run the sky subtraction
;input:
;      file: the flat field removed sky image   *_clean2.fits
;files required:
; grism.conv
;created by Sophia Dai    2015.11.20
;last edit: 2015.11.30
;--------------------------------------------------------------------------
function skycor, sky0, pp
; pp[0]: norm_factor for zodi
; pp[1]: norm_factor for heliem excess
zodi=sky0[*,*,0]
he  =sky0[*,*,1]

az = dblarr(1014,1014)+mean(pp[0])
bh = dblarr(1014,1014)+mean(pp[1])

yval = az*zodi+bh*he

return, yval

end
;------------------------------------------------------------------


pro skytest, output=output
spawn, 'ls -1 *flt_clean.fits', flt

grism='G141'

if not keyword_set(output) then goto,fit
path = '/Volumes/Kudo/DATA/WISPS/aXe/Par382/'
openw,lun,'fltseg.py',/get_lun
printf,lun,'import os,string,time'
printf,lun,'import sys'
printf,lun,'import shutil'
printf,lun,'from pyraf import iraf'
printf,lun,'from iraf import stsdas, dither'

for i = 0, n_elements(flt)-1 do begin
title = strmid(flt[i],0,19)
wht = mrdfits(flt[i],2)
err = 1.66354/sqrt(wht)
h1=headfits(flt[i])
exptime1=strcompress(sxpar(h1,'EXPTIME'),/remove_all)
det='0.5'

spawn,'sex  '+flt[i]+' -c '+path+'SEX/config.sex -catalog_name '+title+'2.cat -mag_zeropoint 26.83 -WEIGHT_TYPE MAP_WEIGHT -weight_image '+flt[i]+' -parameters_name '+path+'SEX/config.param -filter Y -filter_name '+path+'SEX/grism.conv -detect_minarea 6 -detect_thresh '+det+' -ANALYSIS_THRESH 1.0 -DEBLEND_NTHRESH 64 -DEBLEND_MINCONT 0.005 -GAIN '+exptime1+' -STARNNW_NAME '+path+'SEX/default.nnw -CHECKIMAGE_NAME '+title+'2_seg.fits'

printf,lun,'iraf.imarith("'+flt[i]+'[1]","-","'+title+'2_seg.fits[1]","'+title+'2_maskout.fits")'
endfor

free_lun,lun
spawn,'python fltseg.py'
goto,eend

fit:
spawn,'rm *new.fits'
spawn,'rm *new2.fits'
spawn,'rm *f.fits'
spawn,'rm *temp*.fits'
openw,lun,'coeff_out.txt',/get_lun
openw,lun2,'fltnew.py',/get_lun
openw,1,grism+'_cleanf.list'
openw,2,grism+'_clean2.list'
openw,3,grism+'_clean3.list'
openw,4,grism+'_cleannew.list'
openw,5,grism+'_cleannew2.list'

printf,lun2,'import os,string,time'
printf,lun2,'import sys'
printf,lun2,'import shutil'
printf,lun2,'from pyraf import iraf'
printf,lun2,'from iraf import stsdas, dither'
printf,lun2,'from astropy.io import fits'
printf,lun2,'            '
if grism eq 'G102' then begin
printf,lun2,'iraf.imarith("@G102_clean.list//[1]%''","/","/Volumes/Kudo/DATA/WISPS/aXe/CONFIG/g102_master_flat.fits","@G102_cleanf.list")'
printf,lun2,'iraf.imcopy("@G102_cleanf.list","@G102_clean.list//[SCI, overwrite+]%''")'
zodi = mrdfits('/Volumes/Kudo/DATA/WISPS/aXe/CONFIG/g102_master_zodi.fits')
hel = mrdfits('/Volumes/Kudo/DATA/WISPS/aXe/CONFIG/g102_master_he_excess.fits')
endif else begin
printf,lun2,'iraf.imarith("@G141_clean.list//[1]%''","/","/Volumes/Kudo/DATA/WISPS/aXe/CONFIG/g141_master_flat.fits","@G141_cleanf.list")'
printf,lun2,'iraf.imcopy("@G141_cleanf.list","@G141_clean.list//[SCI, overwrite+]%''")'
zodi = mrdfits('/Volumes/Kudo/DATA/WISPS/aXe/CONFIG/g141_master_zodi.fits')
hel = mrdfits('/Volumes/Kudo/DATA/WISPS/aXe/CONFIG/g141_master_he_excess.fits')
scat = mrdfits('/Volumes/Kudo/DATA/WISPS/aXe/CONFIG/g141_master_scattered_light.fits')
endelse


imgall = dblarr(1014,1014,n_elements(flt))
n102 = 0
n141 = 0
a = dblarr(n_elements(flt))
c = dblarr(n_elements(flt))

for i = 0, n_elements(flt)-1 do begin
   imgall[*,*,i] = mrdfits(strmid(flt[i],0,19)+'2_maskout.fits')
   h=headfits(flt[i])
   filter=strcompress(sxpar(h,'FILTER'),/remove_all)
a[i] = median(imgall[*,*,i]/zodi)
c[i] = median(imgall[*,*,i])
endfor

print,'a,median(img)',a,c
azodi = a(where (c eq min(c)))
print,'a zodi',azodi
printf,lun2,'            '
if grism eq 'G102' then printf,lun2,'iraf.imarith("'+strtrim(azodi,2)+'","*","/Volumes/Kudo/DATA/WISPS/aXe/CONFIG/g102_master_zodi.fits","zoditemp.fits")'
if grism eq 'G141' then printf,lun2,'iraf.imarith("'+strtrim(azodi,2)+'","*","/Volumes/Kudo/DATA/WISPS/aXe/CONFIG/g141_master_zodi.fits","zoditemp.fits")'

b = dblarr(n_elements(flt))
bb = dblarr(n_elements(flt))
az = dblarr(1014,1014)+mean(azodi)
for i =0, n_elements(flt)-1 do begin
   img = imgall[*,*,i]
   img2 = img-az*zodi
;   wht = mrdfits(flt[i],2)
;   err = 1.66354/sqrt(wht)
   b[i] = median((img-az*zodi)/hel)

   goto,skip
   n = 1000
   bgrid = findgen(n)/5000 + b[i] -0.1
   res = dblarr(1014,1014,n_elements(bgrid))
   residual = dblarr(n_elements(bgrid))
   for j = 0, n_elements(bgrid)-1 do begin
      bh = dblarr(1014,1014)+mean(bgrid[j])
      res[*,*,j] = img-az*zodi-bh*hel
      residual[j] = median( img-az*zodi-bh*hel)
   endfor
   m = where( (residual ge 0 and residual eq min(abs(residual))) or (residual lt 0 and residual eq -1.*min(abs(residual))) )
   bb[i] = bgrid[m]
   print,'bgrid[m]',bgrid[m]
skip:
   
print,'b[i]',b[i]
   
printf,lun,'flt  ',flt[i],'  a-zodi  ',azodi,'  b-helium  ',b[i], format='(2A0, 2(A0, D20.12))' ; b-helium-grid',bgrid[m],

title = strmid(flt[i],0,19)
printf,1,title+'f.fits'
printf,2,title+'2.fits'
printf,3,title+'3.fits'
printf,4,title+'new.fits'
printf,5,title+'new2.fits'
spawn,'cp '+title+'.fits '+title+'2.fits'
spawn,'cp '+title+'.fits '+title+'3.fits'
if grism eq 'G102' then printf,lun2,'iraf.imarith("'+strtrim(b[i],2)+'","*","/Volumes/Kudo/DATA/WISPS/aXe/CONFIG/g102_master_he_excess.fits","heltemp'+strtrim(i,2)+'.fits")'
if grism eq 'G141' then printf,lun2,'iraf.imarith("'+strtrim(b[i],2)+'","*","/Volumes/Kudo/DATA/WISPS/aXe/CONFIG/g141_master_he_excess.fits","heltemp'+strtrim(i,2)+'.fits")'
endfor

printf,lun2,'            '
printf,lun2,'iraf.imarith("@'+grism+'_cleanf.list","-","zoditemp.fits","@'+grism+'_cleannew.list")'
printf,lun2,'iraf.imcopy("@'+grism+'_cleannew.list","@'+grism+'_clean2.list//[SCI, overwrite+]%''")'
printf,lun2,'            '

for i = 0, n_elements(flt)-1 do begin
title = strmid(flt[i],0,19)
printf,lun2,'iraf.imarith("'+title+'new.fits","-","heltemp'+strtrim(i,2)+'.fits","'+title+'new2.fits")'
endfor

printf,lun2,'iraf.imcopy("@'+grism+'_cleannew2.list","@'+grism+'_clean3.list//[SCI, overwrite+]%''")'
printf,lun2,'            '

for i = 0, n_elements(flt)-1 do begin
title = strmid(flt[i],0,19)
printf,lun2,'img_hdu = fits.open('''+title+'.fits'', mode=''update'')'
printf,lun2,'img_hdu[1].header[''EXTVER''] = 1'
printf,lun2,'img_hdu.flush()'
printf,lun2,'img_hdu = fits.open('''+title+'2.fits'', mode=''update'')'
printf,lun2,'img_hdu[1].header[''EXTVER''] = 1'
printf,lun2,'img_hdu.flush()'
printf,lun2,'img_hdu = fits.open('''+title+'3.fits'', mode=''update'')'
printf,lun2,'img_hdu[1].header[''EXTVER''] = 1'
printf,lun2,'img_hdu.flush()'
endfor

free_lun,lun
free_lun,lun2
close,1,2,3,4,5
;spawn,'python fltnew.py'

goto,eend


sky0 = dblarr(1014,1014,2)
sky0[*,*,0]=zodi
sky0[*,*,1]=hel

parinfo = replicate({value:0.D, fixed:0, limited:[1,0],limits:[0.00001D,0]}, 2)
parinfo.value=[0.000, b[i]]
skyfit = mpfitfun('skycor', hel, img, err $
                     , parinfo = parinfo, perror = perror, /quiet, yfit = yfit $    ;functargs = functargs, 
                      , nfev = nfev, niter = niter, status = status, bestnorm = chi2)

pzodi = skyfit[0]
phel = skyfit[1]

print,skyfit
stop


eend:
end
