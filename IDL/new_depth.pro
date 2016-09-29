;##############################################################
;# WISPIPE
;# Reduction Pipeline for the WISP program (Atek et al. 2010)
;
; NAME:
;      depth
; PURPOSE:
;      a few depth measurement called in match_cat*.pro
;      defined function: Gauss & measuremaglim_ir & MEASUREMAGLIM_UVIS & DO_MEASUREMAGLIM
; CALLING SEQUENCE:
;       
;
; INPUTS:
;       
;
; OUTPUTS:
;       
;
;
;
; EXAMPLE:
;          measuremaglim_ir(path+'/DATA/DIRECT_GRISM/F110W_drz.fits',26.83,2.,0.01,5,0)
;#         this function returns the ABSOLUTE VALUE of the limit
;# calculated (to avoid negative flux)
;#
;# created by Hakim Atek 2009
;#
;# updated by Sophia Dai 2014
;#
;# updated by Ivano Baronchelli 2016:
;# - The area upon which the statistics is performed is re-defined and
;#    automatically detected in case an external frame is adjoined.
;# - The image read is not the MEF image but the simple sci image. 
;#    Consequently the extenction of the read files passes from 1 to 0.   
;# - The depth is computed in a loop for 50 times and then
;#    approximated to the first decimal point. This makes the depth
;#    computation (based on random apertures) mre stable in different
;#    run of the pipeline
;
;###############################################################
;========================
pro gauss, x, a, F

Z = (X-A(1))/abs(A(2))
F= A(0)*EXP(-Z^2/2.d) 

if n_params() GE 4 THEN $
pder=[[EXP(-Z^2/2)],[2*F*Z],[F*z^2]]

end

;--------------------------------------------------------------
function measuremaglim_ir,imagename,zeropoint,radius,bin,thr,plot


; IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
; Ivano Modifications  IIIIIIIIIIIII
; IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII

; OLD VERSION - Sophia
; imaget=mrdfits(imagename,1)
; image=imaget[280:900,240:900]

; NEW VERSION
imaget=mrdfits(imagename,0)
IF n_elements(imaget) le 1 then imaget=mrdfits(imagename,1)
NX=n_elements(imaget[*,0]) ; X size
NY=n_elements(imaget[0,*]) ; Y size
REFX=NX/2 ; Approximated central pixel (x)
REFY=NY/2 ; Approximated central pixel (y)

; Get real image size excluding frame
FX_min=0L
FX_max=long(NX-1)
FY_min=0L
FY_max=long(NY-1)
tst=700 ; test strip will be 2*tst
internal_border=100 ; additive border

; DETECT X FRAME LIMITS FX_min,FX_max
MINOK=0
MAXOK=0
NN=0L
while NN lt REFX do begin
TESTSTRIP1=imaget[NN,REFY-tst:REFY+tst]
TESTSTRIP2=imaget[(NX-1)-NN,REFY-tst:REFY+tst]
Check_IDX1=where(TESTSTRIP1 eq 0.)
Check_IDX2=where(TESTSTRIP2 eq 0.)
if n_elements(Check_IDX1) lt 0.2*float(n_elements(TESTSTRIP1)) and MINOK lt 1 then begin
FX_min=NN+internal_border
MINOK=1
endif
if n_elements(Check_IDX2) lt 0.2*float(n_elements(TESTSTRIP2)) and MAXOK lt 1 then begin
FX_max=(NX-1)-NN-internal_border
MAXOK=1
endif
NN=NN+1
endwhile


; DETECT Y FRAME LIMITS FY_min,FY_max
MINOK=0
MAXOK=0
NN=0L
while NN lt REFY do begin
TESTSTRIP1=imaget[REFX-tst:REFX+tst,NN]
TESTSTRIP2=imaget[REFX-tst:REFX+tst,(NY-1)-NN]
Check_IDX1=where(TESTSTRIP1 eq 0.)
Check_IDX2=where(TESTSTRIP2 eq 0.)
if n_elements(Check_IDX1) lt 0.2*float(n_elements(TESTSTRIP1)) and MINOK lt 1  then begin
FY_min=NN+internal_border
MINOK=1
endif
if n_elements(Check_IDX2) lt 0.2*float(n_elements(TESTSTRIP2)) and MAXOK lt 1  then begin
FY_max=(NY-1)-NN-internal_border
MAXOK=1
endif
NN=NN+1
endwhile

image=imaget[FX_min:FX_max,FY_min:FY_max]

; IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
; END Ivano Modifications  IIIIIIIII
; IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII


if plot eq 1 then tvscl,image
;image=imaget[1800:4200,1800:4200]
;image=imaget[8000:12000,7000:9000]
ss=size(image)

NLOOPS=50                              ; IVANO LOOP
A2_VECT=fltarr(NLOOPS)                 ; IVANO LOOP
SIG3_cps_VECT=fltarr(NLOOPS)           ; IVANO LOOP
SIG3_ABmag_VECT=fltarr(NLOOPS)         ; IVANO LOOP
A2_VECT=fltarr(NLOOPS)                 ; IVANO LOOP
LL=0                                   ; IVANO LOOP
WHILE LL LT NLOOPS DO BEGIN            ; IVANO LOOP 

xr=randomu(seed,10000)*(ss[1]-20.)+10.
yr=randomu(seed,10000)*(ss[2]-20.)+10.

;aper.pro compute concentric aperture photometry (adapted from
;DAOPHOT), from idl astro library
; radius = 2
; Determine the flux and error for photometry radii of 5 and 10 pixels
;       surrounding the position xr[i],yr[i] on an image array, image.   Compute
;       the partial pixel area exactly.    Assume that the flux units are in
;       Poisson counts, so that PHPADU = 1, and the sky value is already known
;       to be 0.0, and that the range [-1000,20000] for bad low and bad high
;       pixels
; output
;     MAGS   -  NAPER by NSTAR array giving the magnitude for each star in
;               each aperture.  (NAPER is the number of apertures, and NSTAR
;               is the number of stars).   If the /FLUX keyword is not set, then
;               a flux of 1 digital unit is assigned a zero point magnitude of 
;               25.
;     ERRAP  -  NAPER by NSTAR array giving error for each star.  If a 
;               magnitude could not be determined then  ERRAP = 9.99 (if in 
;                magnitudes) or ERRAP = !VALUES.F_NAN (if /FLUX is set).
;     SKY  -    NSTAR element vector giving sky value for each star in 
;               flux units
;     SKYERR -  NSTAR element vector giving error in sky values

; to get the aperture magnitude of the sky map
sky=dblarr(10000)
for i=0l,9999l,1l do begin
APER, image, xr[i], yr[i], mags, errap, skyc, skyerr, 1., radius, [5,10],[-1000,20000], /EXACT, /FLUX,  /SILENT, SETSKYVAL = 0.
   sky[i]=mags
endfor
;sky is the flux array corresponding to the RA DEC, consisting of
;magitude values and (sometimes LOTS of) NAN values

aa=histogram_ez_cla(sky[where(sky NE 0.)], binsize=bin,/silent)     ;<---- to get a 2D array with [0,*] the axis (sky counts) and [1,*] the density

;visual inspection of the sky density and sky mean
; Skip this step so for remote login no check is the default
; added by Sophia Dai 2014.07

if plot eq 1 then begin
plot,aa[0,*],aa[1,*],psym=10,xthick=3,ythick=3,thick=4,xtitle='Sky [counts s!E-1!N]',charsize=1.5,charthick=3,xrange=[-0.5,1.5]
oplot,aa[0,*]*0.+median(sky),aa[1,*]
endif

; REFORM can be used to remove “degenerate” leading dimensions of size one. 
; Such dimensions can appear when a subarray is extracted from an
; array with more dimensions.

number=reform(aa[1,*])            ;<---- density array only
value=reform(aa[0,*])             ;<---- position array only 

; IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
; Ivano Modifications  IIIIIIIIIIIII
; IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
; ORIGINAL
; maximum=max(number,position)      ;<---- to get the position of the peak density value
; NEW:
ID_MAX=where(number gt 0.75*max(number))
position=median(ID_MAX)
; IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
; END Ivano Modifications  IIIIIIIII
; IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII

bb=[0,value[position]]            ; first position value
mm=[0,number[position]]           ; first density

;only works if peakhelp position >=2, cause if position=1, the input array only
;have 3 parameters
;modified by Sophia Dai
if position eq 1 then temp_gaussian=[number[0:position+1],reverse(number[0:position-1])]
if position ge 2 then temp_gaussian=[number[0:position],reverse(number[0:position-1])]       ;manually force a symmetric gaussian distribution
gaussian=temp_gaussian[0:n_elements(value)-1 < n_elements(temp_gaussian)-1]

if (n_elements(gaussian) LT n_elements(value)) then begin
value1=value
value=value1[0:n_elements(gaussian)-1]
endif

loadct,13
if plot eq 1 then oplot,value,gaussian,color=206      ;only plot the min and peak of the gaussian
weight=1.d + value*0.d              ;same weight for all values

a=[50.,median(sky),stddev(sky[where(sky lt thr)])]

fit=curvefit(value,gaussian,weight,a,function_name='gauss',/noderivative)
;fit=gaussfit(value,gaussian,a,nter=3)

;print,a

if plot eq 1 then oplot,value,fit,color=206,thick=5

;print,'5 SIGMA [cps]=',5.d*1.5*a[2]
;print,'5 SIGMA [ABmag]=',-2.5*alog10(5.*1.5*abs(a[2]))+zeropoint
;print,'3 SIGMA [cps]=',3.d*a[2]
;print,'3 SIGMA [ABmag]=',-2.5*alog10(3.*abs(a[2]))+zeropoint

;print,radius,3.d*a[2]
print, '---'
SIG3_cps_VECT[LL]=3.d*a[2]                               ; IVANO LOOP 
SIG3_ABmag_VECT[LL]=-2.5*alog10(3.*abs(a[2]))+zeropoint  ; IVANO LOOP 
A2_VECT[LL]=abs(a[2])                                ; IVANO LOOP
LL=LL+1                                              ; IVANO LOOP
ENDWHILE                                             ; IVANO LOOP
A2_FINAL=mean(A2_VECT)                               ; IVANO LOOP

;updated by Sophia Dai to avoid G102-axe errors of negative flux
;return,abs(-2.5*alog10(3.*abs(a[2]))+zeropoint)

; Update by IVANO:
print, '-----------------'
print, radius,3.*A2_FINAL
print, '-----------------'
print,'-----------------'
print,'3 SIGMA [cps]=',mean(A2_VECT)
print,'3 SIGMA [ABmag]=',mean(SIG3_ABmag_VECT)
print,'-----------------'
return,round(10*(abs(-2.5*alog10(3.*A2_FINAL)+zeropoint)))/10.  


end


;--------------------------------------------------------------
pro measuremaglim_uvis,imagename,zeropoint,radius,bin,thr,plot




; IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
; Ivano Modifications  IIIIIIIIIIIII
; IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII

; OLD VERSION - Sophia
; imaget=mrdfits(imagename,1)
; image=imaget[1300:3280,1600:3000]


; NEW VERSION
imaget=mrdfits(imagename,0)
IF n_elements(imaget) le 1 then imaget=mrdfits(imagename,1)
NX=n_elements(imaget[*,0]) ; X size
NY=n_elements(imaget[0,*]) ; Y size
REFX=NX/2 ; Approximated central pixel (x)
REFY=NY/2 ; Approximated central pixel (y)

; Get real image size excluding frame
FX_min=0L
FX_max=long(NX-1)
FY_min=0L
FY_max=long(NY-1)
tst=700 ; test strip will be 2*tst
internal_border=100 ; additive border

; DETECT X FRAME LIMITS FX_min,FX_max
MINOK=0
MAXOK=0
NN=0L
while NN lt REFX do begin
TESTSTRIP1=imaget[NN,REFY-tst:REFY+tst]
TESTSTRIP2=imaget[(NX-1)-NN,REFY-tst:REFY+tst]
Check_IDX1=where(TESTSTRIP1 eq 0.)
Check_IDX2=where(TESTSTRIP2 eq 0.)
if n_elements(Check_IDX1) lt 0.2*float(n_elements(TESTSTRIP1)) and MINOK lt 1 then begin
FX_min=NN+internal_border
MINOK=1
endif
if n_elements(Check_IDX2) lt 0.2*float(n_elements(TESTSTRIP2)) and MAXOK lt 1 then begin
FX_max=(NX-1)-NN-internal_border
MAXOK=1
endif
NN=NN+1
endwhile


; DETECT Y FRAME LIMITS FY_min,FY_max
MINOK=0
MAXOK=0
NN=0L
while NN lt REFY do begin
TESTSTRIP1=imaget[REFX-tst:REFX+tst,NN]
TESTSTRIP2=imaget[REFX-tst:REFX+tst,(NY-1)-NN]
Check_IDX1=where(TESTSTRIP1 eq 0.)
Check_IDX2=where(TESTSTRIP2 eq 0.)
if n_elements(Check_IDX1) lt 0.2*float(n_elements(TESTSTRIP1)) and MINOK lt 1  then begin
FY_min=NN+internal_border
MINOK=1
endif
if n_elements(Check_IDX2) lt 0.2*float(n_elements(TESTSTRIP2)) and MAXOK lt 1  then begin
FY_max=(NY-1)-NN-internal_border
MAXOK=1
endif
NN=NN+1
endwhile


image=imaget[FX_min:FX_max,FY_min:FY_max]

; IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
; END Ivano Modifications  IIIIIIIII
; IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII



if plot eq 1 then tvscl,image
;image=imaget[1800:4200,1800:4200]
;image=imaget[8000:12000,7000:9000]
ss=size(image)

NLOOPS=50                              ; IVANO LOOP
A2_VECT=fltarr(NLOOPS)                 ; IVANO LOOP
SIG3_cps_VECT=fltarr(NLOOPS)           ; IVANO LOOP
SIG3_ABmag_VECT=fltarr(NLOOPS)         ; IVANO LOOP
LL=0                                   ; IVANO LOOP
WHILE LL LT NLOOPS DO BEGIN            ; IVANO LOOP 


xr=randomu(seed,10000)*(ss[1]-20.)+10.
yr=randomu(seed,10000)*(ss[2]-20.)+10.

sky=dblarr(10000)
for i=0l,9999l,1l do begin
APER, image, xr[i], yr[i], flux, errap, skyc, skyerr, 1., radius, [5,10],[-1000,20000], /EXACT, /FLUX,  /SILENT, SETSKYVAL = 0.
   sky[i]=flux
endfor

aa=histogram_ez_cla(sky[where(sky NE 0.)], binsize=bin)
if plot eq 1 then begin
plot,aa[0,*],aa[1,*],psym=10,xthick=3,ythick=3,thick=4,xtitle='Sky [counts s!E-1!N]',charsize=1.5,charthick=3,xrange=[-0.5,1.5]
oplot,aa[0,*]*0.+median(sky),aa[1,*]
endif

number=reform(aa[1,*])
value=reform(aa[0,*])

; IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
; Ivano Modifications  IIIIIIIIIIIII
; IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
; ORIGINAL
;maximum=max(number,position)      ;<---- to get the position of the peak density value
; NEW:
ID_MAX=where(number gt 0.75*max(number))
position=median(ID_MAX)
; IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII
; END Ivano Modifications  IIIIIIIII
; IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII

bb=[0,value[position]]
mm=[0,number[position]]

temp_gaussian=[number[0:position],reverse(number[0:position-1])]
gaussian=temp_gaussian[0:n_elements(value)-1 < n_elements(temp_gaussian)-1]

if (n_elements(gaussian) LT n_elements(value)) then begin
value1=value
value=value1[0:n_elements(gaussian)-1]
endif

loadct,13
if plot eq 1 then oplot,value,gaussian,color=206
weight=1.d + value*0.d

a=[50.,median(sky),stddev(sky[where(sky lt thr)])]

fit=curvefit(value,gaussian,weight,a,function_name='gauss',/noderivative)

;print,a

if plot eq 1 then oplot,value,fit,color=206,thick=5

;print,'5 SIGMA [cps]=',5.d*1.5*a[2]
;print,'5 SIGMA [ABmag]=',-2.5*alog10(5.*1.5*abs(a[2]))+zeropoint
;print,'3 SIGMA [cps]=',3.d*a[2]
;print,'3 SIGMA [ABmag]=',-2.5*alog10(3.*abs(a[2]))+zeropoint

; print,radius,3.d*a[2]
print, '---'
A2_VECT[LL]=abs(a[2])                                ; IVANO LOOP
SIG3_cps_VECT[LL]=3.d*a[2]                               ; IVANO LOOP 
SIG3_ABmag_VECT[LL]=-2.5*alog10(3.*abs(a[2]))+zeropoint  ; IVANO LOOP 
LL=LL+1                                              ; IVANO LOOP
ENDWHILE                                             ; IVANO LOOP
A2_FINAL=mean(A2_VECT)                               ; IVANO LOOP

;updated by Sophia Dai to avoid G102-axe errors of negative flux
;return,abs(-2.5*alog10(3.*abs(a[2]))+zeropoint)

; Update by IVANO:
print, '-----------------'
print, radius,3.*A2_FINAL
print, '-----------------'
print,'-----------------'
print,'3 SIGMA [cps]=',mean(A2_VECT)
print,'3 SIGMA [ABmag]=',mean(SIG3_ABmag_VECT)
print,'-----------------'
print,round(10*(abs(-2.5*alog10(3.*A2_FINAL)+zeropoint)))/10.


end

pro do_measuremaglim
measuremaglim_uvis,'Par66/DATA/UVIS/F475X_drz.fits',26.15,6.,0.01,50.
measuremaglim_uvis,'Par68/DATA/UVIS/F475X_drz.fits',26.15,6.,0.005,50.
measuremaglim_uvis,'Par69/DATA/UVIS/F475X_drz.fits',26.15,6.,0.01,50.
;measuremaglim_uvis,'Par71/DATA/UVIS/F475X_drz.fits',26.15,6.,0.005,50.
measuremaglim_uvis,'Par73/DATA/UVIS/F475X_drz.fits',26.15,6.,0.02,50.
measuremaglim_uvis,'Par74/DATA/UVIS/F475X_drz.fits',26.15,6.,0.04,50.
measuremaglim_uvis,'Par81/DATA/UVIS/F475X_drz.fits',26.15,6.,0.01,50.
measuremaglim_uvis,'Par83/DATA/UVIS/F475X_drz.fits',26.15,6.,0.01,50.
measuremaglim_uvis,'Par84/DATA/UVIS/F475X_drz.fits',26.15,6.,0.01,50.
measuremaglim_uvis,'Par87/DATA/UVIS/F475X_drz.fits',26.15,6.,0.01,50.
measuremaglim_uvis,'Par89/DATA/UVIS/F475X_drz.fits',26.15,6.,0.01,50.
measuremaglim_uvis,'Par96/DATA/UVIS/F475X_drz.fits',26.08,6.,0.005,50.


measuremaglim_uvis,'Par66/DATA/UVIS/F600LP_drz.fits',25.85,6.,0.04,50.
measuremaglim_uvis,'Par68/DATA/UVIS/F600LP_drz.fits',25.85,6.,0.04,50.
measuremaglim_uvis,'Par69/DATA/UVIS/F600LP_drz.fits',25.85,6.,0.04,50.
;measuremaglim_uvis,'Par71/DATA/UVIS/F600LP_drz.fits',25.85,6.,0.04,50.
measuremaglim_uvis,'Par73/DATA/UVIS/F600LP_drz.fits',25.85,6.,0.04,50.
measuremaglim_uvis,'Par74/DATA/UVIS/F600LP_drz.fits',25.85,6.,0.04,50.
measuremaglim_uvis,'Par81/DATA/UVIS/F600LP_drz.fits',25.85,6.,0.04,50.
measuremaglim_uvis,'Par83/DATA/UVIS/F600LP_drz.fits',25.85,6.,0.04,50.
measuremaglim_uvis,'Par84/DATA/UVIS/F600LP_drz.fits',25.85,6.,0.04,50.
measuremaglim_uvis,'Par87/DATA/UVIS/F600LP_drz.fits',25.85,6.,0.04,50.
measuremaglim_uvis,'Par89/DATA/UVIS/F600LP_drz.fits',25.85,6.,0.04,50.
measuremaglim_uvis,'Par96/DATA/UVIS/F600LP_drz.fits',25.09,6.,0.005,50.
end

