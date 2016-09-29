;##############################################################
;# WISPIPE
;# Reduction Pipeline for the WISP program 
;# Sophia Dai 2015
;#
;#
;# Purpose: to flag out problematic objects from the SE catalog
;#          1. objects close to the edge
;#          2. objects that contains > limitr (%) of weight=0 pixels
;#          3. objects that are possibly due to star diffractions or persistence
;#          4. objects that are blended in one filter but not the other
;# Calls: 
;# Input:
;#       SourceExtractor generated catalog: F*W_[det].cat
;#       astrodrizzled science map: F*W_sci.fits to determine edges
;#       astrodrizzled weight map: F*W_wht.fits to determine bad pixels
;#       (limitr: the bad pixel ratio limit used for purpose 2)
;#
;# Output: cleaned catalog:
;# filter+'_full.cat',filter+'_clean.cat','cat_deblend_flag.cat', cat_[filter].cat
;#
;# Call Sequence:
;#      e.g. seflag,'F160W','2.3','Par167','~/DATA/WISP/' for general
;# flagging (1-3)
;#      e.g. seflag,'F110','2.3','Par167','~/DATA/WISP/' for
;# deblending flagging (4), note here there is no 'W' in the filter name
;#
;#  Last edit 2015.02.04
;###############################################################

pro seflag,filter,det,field,path0,blend=blend

pathse = path0+"/aXe/"+field+'/SEX/'
;pathse = '~/Desktop/SEtest/'+field+'/'
;pathse = '/Volumes/Kudo/DATA/WISPS/aXe/Par314/SEX/'
if keyword_set(blend) then goto,deblendflag

readcol, pathse+filter+'_'+det+'.cat',id,xt,yt,a,b,theta,ra,dec,ad,bd,pa,mag,emag,star,flags,f='i,f,f,f,f,f,f,f,f,f,f,f,f,f,i',/silent
flag2 = fltarr(n_elements(xt))
rate0 = fltarr(n_elements(xt))


;======== flag step 1: reject objects at the edge, flag them as '9'
h1=headfits(pathse+'/'+filter+'_sci.fits')
dim1=strcompress(sxpar(h1,'NAXIS1'),/remove_all) ;1083
dim2=strcompress(sxpar(h1,'NAXIS2'),/remove_all)  ;959
m1 = where(xt le 10 or xt ge dim1-20 or yt le 10 or yt ge dim2-10)
if m1[0] ne -1 then flag2[m1] = 9

;======== flag step 2: reject objects that contains > 50% of weight=0 pixels, flag them as '99'
imwht = mrdfits(pathse+'/'+filter+'_wht.fits')
imseg = mrdfits(pathse+'/'+filter+'_'+det+'_seg.fits')
xgrid = findgen(dim1)+1
ygrid = findgen(dim2)+1
limitr=0.5
for i=0, n_elements(xt)-1 do begin
      ;--- skip the already flagged ones
    if flags[i] ge 4 or flag2[i] ne 0 then goto, next
m2x = where(xgrid ge xt[i]-2*a[i] and xgrid le xt[i]+2*a[i])
m2y = where(ygrid ge yt[i]-2*b[i] and ygrid le yt[i]+2*b[i])
area = float(n_elements(m2x)*n_elements(m2y))
weight = imwht[xgrid(m2x[0]):xgrid(m2x[n_elements(m2x)-1]),ygrid(m2y[0]):ygrid(m2y[n_elements(m2y)-1]) ]
m2 = where(weight eq 0)
mm2 = float(n_elements(m2))
rate0[i] = mm2/area
if rate0[i] gt limitr then flag2[i] = flag2[i] + 99
    next:
endfor

;======== flag step 3: reject elongated spikes with high eccentricity (ecc > 0.98), flag them as '999'
ecc = sqrt(1- b^2/a^2)
mm = where((sqrt(1-b^2/a^2)) gt 0.98)
if mm[0] ne -1 then flag2[mm] = flag2[mm]+999


;======== generate the updated catalog
OPENR,lun,pathse+filter+'_'+det+'.cat',/get_lun
header=strarr(17)
readf,lun,header
header(15)="#  16 BADPIXLE_RATIO         N_badpixel/N_total   "
header(16)="#  17 FLAG2                  WISPs flags: 9 = edge, 99 = badpix, 999 = high eccentricity   "
CLOSE,lun
FREE_LUN,lun

openw,u1,pathse+filter+'_full.cat',/get_lun
openw,u2,pathse+filter+'_clean.cat',/get_lun
printf,u1,header
printf,u2,header[0:14]
for i=0, n_elements(xt)-1 do begin
   printf,u1,id[i],xt[i],yt[i],a[i],b[i],theta[i],ra[i],dec[i],ad[i],bd[i],pa[i],mag[i],emag[i],star[i],flags[i],rate0[i],flag2[i] $
          ,FORMAT='(I5, 4(F10.3), F10.1, 4(F20.10), F10.1, 2F10.4, F10.2, I10, F10.4, I10)'
   if flag2[i] eq 0 then begin
      printf,u2,id[i],xt[i],yt[i],a[i],b[i],theta[i],ra[i],dec[i],ad[i],bd[i],pa[i],mag[i],emag[i],star[i],flags[i],FORMAT='(I5, 4(F10.3), F10.1, 4(F20.10), F10.1, 2F10.4, F10.2, I10)'
   endif
endfor

CLOSE,u1,u2
FREE_LUN,u1,u2

;readcol,pathse+filter+'_clean.cat',id,xt,yt,a,b,theta,ra,dec,ad,bd,pa,mag,emag,class,flags,/silent
;mk_regionfile_elip,xt,yt,2.*a,2.*b,theta,label=string(fix(id)),file=pathse+filter+'_clean.reg',/image,color='magenta'
;readcol,pathse+filter+'_'+det+'.cat',id,xt,yt,a,b,theta,ra,dec,ad,bd,pa,mag,emag,class,flags,/silent
;mk_regionfile_elip,xt,yt,2.*a,2.*b,theta,label=string(fix(id)),file=pathse+filter+'_orig.reg',/image,color='cyan'

spawn,'mv '+pathse+filter+'_clean.cat '+pathse+filter+'.cat'

goto,eend

deblendflag:
;seflag,'F160W','2.3','Par314','/Volumes/Kudo/DATA/WISPS/',/blend
;======== flag step 4: flag out objects deblended in only one of the
;2, flag as 256
OPENR,lun,pathse+'cat_F110.cat',/get_lun
header_F110=strarr(15)
header_F140=strarr(15)
header_F160=strarr(15)
header=strarr(16)
readf,lun,header_F110
header[0:14]=header_F110
header(15)="#  16 FLAG2                  WISPs flags: 9 = edge, 99 = badpix, 999 = high eccentricity   "
header_F140=header_f110
header_F140(11)="#  12 MAG_F1392W             Kron-like elliptical aperture magnitude         [mag]"
header_F160=header_f110
header_F160(11)="#  12 MAG_F1537W             Kron-like elliptical aperture magnitude         [mag]"
CLOSE,lun
FREE_LUN,lun

openw,u3,pathse+'cat_deblend_flag.cat',/get_lun
printf,u3,header

readcol,pathse+'cat_F110.cat',id1,xt1,yt1,a1,b1,theta1,ra1,dec1,ad1,bd1,pa1,mag1,emag1,class1,flags1,/silent
if filter eq 'F160W' then readcol,pathse+'cat_F160.cat',id2,xt2,yt2,a2,b2,theta2,ra2,dec2,ad2,bd2,pa2,mag2,emag2,class2,flags2,/silent
if filter eq 'F140W' then readcol,pathse+'cat_F140.cat',id2,xt2,yt2,a2,b2,theta2,ra2,dec2,ad2,bd2,pa2,mag2,emag2,class2,flags2,/silent
m0= where(id1 lt 1000)
m1= where(id1 ge 1000 and id1 lt 2000)
m2= where(id1 ge 2000)

for i=0, n_elements(m1)-1 do begin
   d1=fltarr(n_elements(m0))
   d2=fltarr(n_elements(m0))
;********************************
;distance of the 1000+ obj and its matched obj within the semi-major axis
       for j=0,N_ELEMENTS(m0)-1 do begin
          d1(m0[j])=SQRT( ((ra1(m1[i]) - ra1(m0[j])))^2 + ((dec1(m1[i])-dec1(m0[j])))^2)
          d2(m0[j])=SQRT( ((ra2(m1[i]) - ra2[m0[j]]))^2 + ((dec1(m1[i])-dec2(m0[j])))^2) 
       endfor
       mo = where (d1 lt 2.*ad1 or d1 lt 2.*ad2 or d2 lt 2.*ad1 or d2 lt 2.*ad2)
       if mo[0] ne -1 then begin
        for ii = 0, n_elements(mo)-1 do begin
          flags1(m1[i]) = flags1(m1[i])+256
          flags2(m1[i]) = flags2(m1[i])+256
          flags1(mo[ii]) = flags1(mo[ii])+256
          flags2(mo[ii]) = flags2(mo[ii])+256
          printf,u3,id1[mo[ii]],xt1[mo[ii]],yt1[mo[ii]],a1[mo[ii]],b1[mo[ii]],theta1[mo[ii]],ra1[mo[ii]],dec1[mo[ii]],ad1[mo[ii]],bd1[mo[ii]],pa1[mo[ii]],mag1[mo[ii]],emag1[mo[ii]],class1[mo[ii]],flags1[mo[ii]],id1[m1[i]],FORMAT='(I5, 4(F10.3), F10.1, 4(F20.10), F10.1, 2F10.4, F10.2, 2I10)'
          printf,u3,id1[m1[i]],xt1[m1[i]],yt1[m1[i]],a1[m1[i]],b1[m1[i]],theta1[m1[i]],ra1[m1[i]],dec1[m1[i]],ad1[m1[i]],bd1[m1[i]],pa1[m1[i]],mag1[m1[i]],emag1[m1[i]],class1[m1[i]],flags1[m1[i]],id1[mo[ii]],FORMAT='(I5, 4(F10.3), F10.1, 4(F20.10), F10.1, 2F10.4, F10.2, 2I10)'
       endfor
          endif
endfor

for i=0, n_elements(m2)-1 do begin
   d1=fltarr(n_elements(m0))
   d2=fltarr(n_elements(m0))
;********************************
;distance of the 1000+ obj and its matched obj within the semi-major axis
       for j=0,N_ELEMENTS(m0)-1 do begin
          d1(m0[j])=SQRT( ((ra1(m2[i]) - ra1(m0[j])))^2 + ((dec1(m2[i])-dec1(m0[j])))^2)
          d2(m0[j])=SQRT( ((ra2(m2[i]) - ra2[m0[j]]))^2 + ((dec1(m2[i])-dec2(m0[j])))^2) 
       endfor
       mo = where (d1 lt 2.*ad1 or d1 lt 2.*ad2 or d2 lt 2.*ad1 or d2 lt 2.*ad2)
       if mo[0] ne -1 then begin
        for ii = 0, n_elements(mo)-1 do begin
          flags1(m2[i]) = flags1(m2[i])+256
          flags2(m2[i]) = flags2(m2[i])+256
          flags1(mo[ii]) = flags1(mo[ii])+256
          flags2(mo[ii]) = flags2(mo[ii])+256
          printf,u3,id1[mo[ii]],xt1[mo[ii]],yt1[mo[ii]],a1[mo[ii]],b1[mo[ii]],theta1[mo[ii]],ra1[mo[ii]],dec1[mo[ii]],ad1[mo[ii]],bd1[mo[ii]],pa1[mo[ii]],mag1[mo[ii]],emag1[mo[ii]],class1[mo[ii]],flags1[mo[ii]],id1[m2[i]],FORMAT='(I5, 4(F10.3), F10.1, 4(F20.10), F10.1, 2F10.4, F10.2, 2I10)'
          printf,u3,id1[m2[i]],xt1[m2[i]],yt1[m2[i]],a1[m2[i]],b1[m2[i]],theta1[m2[i]],ra1[m2[i]],dec1[m2[i]],ad1[m2[i]],bd1[m2[i]],pa1[m2[i]],mag1[m2[i]],emag1[m2[i]],class1[m2[i]],flags1[m2[i]],id1[mo[ii]],FORMAT='(I5, 4(F10.3), F10.1, 4(F20.10), F10.1, 2F10.4, F10.2, 2I10)'
       endfor
     endif
    endfor

;replace the catlogs with the updated flags
openw,u1,pathse+'cat_F110.cat',/get_lun
if filter eq 'F160W' then openw,u2,pathse+'cat_F160.cat',/get_lun
if filter eq 'F140W' then openw,u2,pathse+'cat_F140.cat',/get_lun
PRINTF,u1,header_F110
PRINTF,u2,header_F160
for i=0, n_elements(id1)-1 do begin
PRINTF,u1,id1[i],xt1[i],yt1[i],a1[i],b1[i],theta1[i],ra1[i],dec1[i],ad1[i],bd1[i],pa1[i],mag1[i],emag1[i],class1[i],flags1[i],FORMAT='((I5, 4(F10.3), F10.1, 4(F20.10), F10.1, 2F10.4, F10.2, I10))'
PRINTF,u2,id2[i],xt2[i],yt2[i],a2[i],b2[i],theta2[i],ra2[i],dec2[i],ad2[i],bd2[i],pa2[i],mag2[i],emag2[i],class2[i],flags2[i],FORMAT='((I5, 4(F10.3), F10.1, 4(F20.10), F10.1, 2F10.4, F10.2, I10))'
endfor

CLOSE,u1,u2,u3
FREE_LUN,u1,u2,u3

eend:
end
