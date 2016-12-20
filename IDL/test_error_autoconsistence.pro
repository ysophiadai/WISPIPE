pro test_error_autoconsistence, PARN,justplot=justplot

fileout='uncertainty_test.cat'
plotout='uncertainty_test.eps'
BLUE=520000000 ; blue for screen
RED=3000       ; red for screen

lbin=0.05

Par=PARN ; (ex. 302)

;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
IF NOT keyword_set(justplot) THEN BEGIN
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


; Read reference catalog
catname='DATA/DIRECT_GRISM/cat_F110.cat'
readcol,catname,beam,mag,format='i8,x,x,x,x,x,x,x,x,x,x,f',skipline=15,/silent


SAVE_VEC=dblarr(8,n_elements(beam))
; ID, WISP-sigma (G102), GAUSS-sigma (G102), Analytical-sigma (G102), WISP-sigma (G141), GAUSS-sigma (G141), Analytical-sigma (G141)
ID=lonarr(n_elements(SAVE_VEC[0,*])) ;ID
ID[*]=-99
SAVE_VEC[0,*]=-99. ;WISP-sigma (G102)
SAVE_VEC[1,*]=-99. ;WISP-sigma-unc. (G102)
SAVE_VEC[2,*]=-99. ;GAUSS-sigma (G102)
SAVE_VEC[3,*]=-99. ;Analytical-sigma (G102)
SAVE_VEC[4,*]=-99. ;WISP-sigma (G141)
SAVE_VEC[5,*]=-99. ;WISP-sigma-unc. (G141)
SAVE_VEC[6,*]=-99. ;GAUSS-sigma (G141)
SAVE_VEC[7,*]=-99. ;Analytical-sigma (G141)

SAVE=strarr(n_elements(SAVE_VEC[0,*])) ;Save (y/n)

kf_102='n'
kf_141='n'


NN=0L
WHILE NN lt n_elements(beam) DO BEGIN

 L_min_102=0.85
 L_max_102=1.1
 L_min_141=1.15 
 L_max_141=1.6
 print, 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
 PRINT, 'BEAM: '+strcompress(string(beam[NN]),/remove_all)
 print, 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
   
 ; Test files existence
 dat_102_name='Spectra/Par'+strcompress(string(Par),/remove_all)+'_G102_BEAM_'+strcompress(string(beam[NN]),/remove_all)+'A.dat'
 dat_141_name='Spectra/Par'+strcompress(string(Par),/remove_all)+'_G141_BEAM_'+strcompress(string(beam[NN]),/remove_all)+'A.dat'
 TEST_102=file_test(dat_102_name,/zero_length)    ; 1 if exists but no content
 TEST_102B=file_test(dat_102_name)                ; 1 if exists
 TEST_141=file_test(dat_141_name,/zero_length)    ; 1 if exists but no content
 TEST_141B=file_test(dat_141_name)                ; 1 if exists

 G102_OBS='NO'
 G141_OBS='NO'
 IF TEST_102 ne 1 and TEST_102B eq 1 then G102_OBS='YES'
 IF TEST_141 ne 1 and TEST_141B eq 1 then G141_OBS='YES'
 

 ; xxxxxxxxxxxxxxxxx
 ; READ G102
 ; xxxxxxxxxxxxxxxxx
 IF G102_OBS EQ 'YES' then begin
  ; Read file.dat for grism 102
  readcol,dat_102_name,wave102,flux102,flux102err,flux102cont,zeroth,format='f,f,f,f,i8',/silent
  TRIM=where(wave102 gt 8.25e3 and wave102 lt 11.5e3)

  wave102=wave102[TRIM]/1e4
  flux102=flux102[TRIM]*1e18
  flux102err=flux102err[TRIM]*1e18
  flux102cont=flux102cont[TRIM]*1e18
  zeroth=zeroth[TRIM]

  maxy=median(flux102)+5*abs((percentiles(flux102,value=[0.9])-median(flux102)))
  miny=median(flux102)-5*abs((median(flux102)-percentiles(flux102,value=[0.1])))
  
 ENDIF


 ; xxxxxxxxxxxxxxxxx
 ; READ G141
 ; xxxxxxxxxxxxxxxxx
 IF G141_OBS EQ 'YES' then begin
  ; Read file.dat for grism 102
  readcol,dat_141_name,wave141,flux141,flux141err,flux141cont,zeroth,format='f,f,f,f,i8',/silent
  TRIM=where(wave141 gt 10.75e3 and wave141 lt 16.5e3)

  wave141=wave141[TRIM]/1e4
  flux141=flux141[TRIM]*1e18
  flux141err=flux141err[TRIM]*1e18
  flux141cont=flux141cont[TRIM]*1e18
  zeroth=zeroth[TRIM]

  ; Keep 102 not 141 here below !!!!
  IF G102_OBS EQ 'NO' then begin
   if median(flux141) ne max(flux141) then begin
    maxy=2*median(flux141[where(flux141 gt median(flux141))])
   endif else begin
    maxy=median(flux141)+0.2*maxy
   endelse
   if median(flux141) ne min(flux141) then begin
    miny=median(flux141[where(flux141 lt median(flux141))])
    if miny gt 0 then miny=0
    if miny lt 0 then miny=3*median(flux141[where(flux141 lt median(flux141))])
   endif else begin
    miny=median(flux141)
   endelse
  ENDIF
 ENDIF
 

 ; ==================================
 ;  FIT AND UNCERTAINTY COMPUTATION
 ; ==================================

 ASK102='YES'
 GETOUT='NO'
 WHILE GETOUT NE 'YES' DO BEGIN

  GETOUT='YES'

  IF G102_OBS EQ 'YES' then begin
   plot,wave102,flux102,xrange=[0.7,1.7],yrange=[miny,maxy],/xst,/yst,charsize=1.5,charthick=2,xtitle='wavelength [um]',ytitle='Flux 1e18 [erg s-1 cm-2 A-1]',title='Beam '+strcompress(string(beam[NN]),/remove_all)
   oplot,wave102,flux102,thick=2,color=BLUE
   oplot,[L_min_102,L_min_102],[miny,maxy],linestyle=2,thick=2,color=BLUE
   oplot,[L_max_102,L_max_102],[miny,maxy],linestyle=2,thick=2,color=BLUE
  ENDIF

  IF G141_OBS EQ 'YES' then begin
   IF G102_OBS EQ 'NO' then plot,wave141,flux141,xrange=[0.7,1.7],yrange=[miny,maxy],/xst,/yst,charsize=1.5,charthick=2,xtitle='wavelength [um]',title='Beam '+strcompress(string(beam[NN]),/remove_all)
   oplot,wave141,flux141,thick=2,color=RED
   oplot,[L_min_141,L_min_141],[miny,maxy],linestyle=2,thick=2,color=RED
   oplot,[L_max_141,L_max_141],[miny,maxy],linestyle=2,thick=2,color=RED
  ENDIF 


 ;####################### G102 ###########################

  IF G102_OBS EQ 'YES' then begin
   IF ASK102 EQ 'YES' THEN BEGIN
    ; SELECT spectral region for error determination 
    Sel102='y'
    WHILE strlowcase(Sel102) eq 'y' do begin 
     Sel102='n'
     print,'Select new range for G102? (y/n, default=n)'
     read,Sel102
     if strlowcase(Sel102) ne 'y' then Sel102='n'
     if strlowcase(Sel102) eq 'y' then begin
      print, 'New wavelength min [um]: '
      read, L_min_102
      L_min_102=L_min_102
      print, 'New wavelength max [um]: '
      read,L_max_102
      L_max_102=L_max_102
      oplot,[L_min_102,L_min_102],[miny,maxy],linestyle=2,thick=2
      oplot,[L_max_102,L_max_102],[miny,maxy],linestyle=2,thick=2
     endif

     ; Linear fit
     IDX_102=where(wave102 gt L_min_102 and wave102 lt L_max_102)
     if n_elements(IDX_102) gt 2 then begin
      fit_102=linfit(wave102[IDX_102],flux102[IDX_102],SIGMA=sig_102)
      a_fit102=fit_102[0]
      b_fit102=fit_102[1]
      XX_102=[L_min_102 , L_max_102]
      YY_102=[L_min_102*b_fit102+a_fit102 , L_max_102*b_fit102+a_fit102]
      oplot,XX_102,YY_102,thick=2

      kf_102='yes'
      print,'Keep fit for grism 102? (y/n, default=n)'
      read,kf_102
      if strlowcase(kf_102) ne 'y' then kf_102='n'
     endif else begin
      print, 'not enough points to fit!' 
      Sel_102='n'
      kf_102='n'
     endelse
      
     if kf_102 ne 'y' then begin
      Sel102='n'
      GETOUT='NO'
     endif

     if kf_102 eq 'y' then Sel102='n'
     
    ENDWHILE
   ENDIF
  ENDIF ELSE BEGIN
   PRINT, 'file '+dat_102_name+' does not exist!'
ENDELSE


 ;####################### G141 ###########################
  IF Sel102 ne 'y' THEN BEGIN
   IF G141_OBS EQ 'YES' then begin

    ; SELECT spectral region for error determination 

    Sel141='y'
    WHILE strlowcase(Sel141) eq 'y' do begin 
     Sel141='n'
     print,'Select new range for G141? (y/n, default=n)'
     read,Sel141
     if strlowcase(Sel141) ne 'y' then Sel141='n'
     if strlowcase(Sel141) eq 'y' then begin
      print, 'New wavelength min [um]: '
      read, L_min_141
      L_min_141=L_min_141
      print, 'New wavelength max [um]: '
      read,L_max_141
      L_max_141=L_max_141
      oplot,[L_min_141,L_min_141],[miny,maxy],linestyle=2,thick=2
      oplot,[L_max_141,L_max_141],[miny,maxy],linestyle=2,thick=2
     endif

     ; Linear fit
     IDX_141=where(wave141 gt L_min_141 and wave141 lt L_max_141)
     if n_elements(IDX_141) gt 2 then begin
      fit_141=linfit(wave141[IDX_141],flux141[IDX_141],SIGMA=sig_141)
      a_fit141=fit_141[0]
      b_fit141=fit_141[1]
      XX_141=[L_min_141 , L_max_141]
      YY_141=[L_min_141*b_fit141+a_fit141 , L_max_141*b_fit141+a_fit141]
      oplot,XX_141,YY_141,thick=2

      kf_141='y'
      print,'Keep fit for grism 141? (y/n, default=n)'
      read,kf_141
      if strlowcase(kf_141) ne 'y' then kf_141='n'
     endif else begin
      print, 'not enough points to fit!' 
      Sel_141='n'
      kf_141='n'
     endelse

     if kf_141 ne 'y' then begin
      Sel141='n'
      GETOUT='NO'
      ASK102='NO'
     endif

     if kf_141 eq 'y' then Sel141='n'

    ENDWHILE

   ENDIF ELSE BEGIN
    PRINT, 'file '+dat_141_name+' does not exist!'
   ENDELSE

  ENDIF
  
 IF Sel102 ne 'y' and Sel141 ne 'y' then GETOUT='YES'
 ENDWHILE

 
  ; COMPARE UNCERTAINTY COMPUTED HERE WITH UNCERTAINTY IN THE FILE
  
 GFIT_102=-99.
 sig102=-99.
 RU_102=-99.
 RUU_102=-99.
 sig_gauss102=-99.
 
 IF G102_OBS EQ 'YES' then begin
  if kf_102 eq 'y' then begin

   newbin=lbin
   selbin = 'y'
   while selbin eq 'y' do begin
    sc_102=flux102[IDX_102]-interpol(YY_102,XX_102,wave102[IDX_102])
    plothist,sc_102,xh102,yh102,bin=newbin,/noplot
    plothist,sc_102,bin=newbin,xtitle='Flux uncert. 1e18 [erg s-1 cm-2 A-1]',ytitle='N',thick=2,charsize=1.5,charthick=2,xrange=[min(xh102)-0.2*abs(min(xh102)),max(xh102)+0.2*abs(max(xh102))],yrange=[0,max(yh102)+0.1*max(yh102)],color=BLUE,/xst,/yst, title='G102 Uncertainty'
 
    IF n_elements(xh102) gt 4then begin
     ; Sigma from gaussian fit    
     GFIT_102=gaussfit(xh102,yh102,A102,nterms=3)
     oplot,xh102,GFIT_102,color=BLUE,THICK=2
     sig_gauss102=A102[2] ; <--- USE THIS, not 'GFIT_102', for the gaussian fit
    
     ; Analytinc sigma
     sig102=sqrt(total(sc_102^2)/float(n_elements(IDX_102)))  

     ; Reported uncertainty (median)
     RU_102=median(flux102err[IDX_102])
     ; Estimated uncertainty on Reported uncertainty (84% percentile-16%percentile)/2
     RUU_102=(percentiles(flux102err[IDX_102],value=[0.84])-percentiles(flux102err[IDX_102],value=[0.16]))/2.

     string102='Gaussian fit sigma= '+strcompress(string(A102[2]))
     string102bis='Analitic sigma= '+strcompress(string(sig102))
     string102tris='Median wisp output= '+strcompress(string(RU_102))+'+-'+strcompress(string(RUU_102))

     xyouts,min(xh102)+(max(xh102)-min(xh102))*0.1,max(yh102)-(max(yh102)-min(yh102))*0.1,string102,charsize=1.7,charthick=2
     xyouts,min(xh102)+(max(xh102)-min(xh102))*0.1,max(yh102)-(max(yh102)-min(yh102))*0.15,string102bis,charsize=1.7,charthick=2
     xyouts,min(xh102)+(max(xh102)-min(xh102))*0.1,max(yh102)-(max(yh102)-min(yh102))*0.2,string102tris,charsize=1.7,charthick=2

     print, 'Actual bin width: '+strcompress(string(newbin),/remove_all)
     print, 'Select a new bin width? (y/n, default, no)'
     read,selbin
    ENDIF ELSE BEGIN
     ggg='ciao'
     print, 'Too few points for a fit!',n_elements(xh102)
     print, '"d" to discard this fit, any key to select another binning '
     read,ggg
     if ggg ne 'd' then selbin = 'y'
     if ggg eq 'd' then begin
      selbin = 'n'
      GFIT_102=-99.
      sig102=-99.
      RU_102=-99.
      RUU_102=-99.
     endif
    ENDELSE
    if selbin eq 'y' then begin
     print,'New bin width:'
     read, newbin
    endif
 endwhile

  endif
 ENDIF
 
 fff='fff'

 if kf_102 eq 'y' then begin
  print, 'Any key to watch histogram for G141, (q to EXIT)'
  fff='fff'
  read,fff
 endif

 if strlowcase(fff) EQ 'q' THEN NN=n_elements(beam)


 GFIT_141=-99.
 sig141=-99.
 RU_141=-99.
 RUU_141=-99.
 sig_gauss141=-99.

 IF G141_OBS EQ 'YES' then begin
  if kf_141 eq 'y' then begin
   
   newbin=lbin

   selbin = 'y'
   while selbin eq 'y' do begin
    sc_141=flux141[IDX_141]-interpol(YY_141,XX_141,wave141[IDX_141])
    plothist,sc_141,xh141,yh141,bin=newbin,/noplot
    plothist,sc_141,bin=newbin,xtitle='Flux uncert. 1e18 [erg s-1 cm-2 A-1]',ytitle='N',thick=2,charsize=1.5,charthick=2,xrange=[min(xh141)-0.2*abs(min(xh141)),max(xh141)+0.2*abs(max(xh141))],yrange=[0,max(yh141)+0.1*max(yh141)],color=RED,/xst,/yst, title='G141 Uncertainty'
    IF n_elements(xh141) gt 4 then begin
     ; Sigma from gaussian fit    
     GFIT_141=gaussfit(xh141,yh141,A141,nterms=3)
     oplot,xh141,GFIT_141,color=RED,THICK=2
     sig_gauss141=A141[2] ; <--- USE THIS, not 'GFIT_102', for the gaussian fit

     ; Analytinc sigma
     sig141=sqrt(total(sc_141^2)/float(n_elements(IDX_141))) 

     ; Reported uncertainty
     RU_141=median(flux141err[IDX_141])
     ; Estimated uncertainty on Reported uncertainty (84% percentile-16% percentile)/2
     RUU_141=(percentiles(flux141err[IDX_141],value=[0.84])-percentiles(flux141err[IDX_141],value=[0.16]))/2
    
     string141='Gaussian fit sigma= '+strcompress(string(A141[2]))
     string141bis='Analitic sigma= '+strcompress(string(sig141))
     string141tris='Median wisp output= '+strcompress(string(RU_141))+'+-'+strcompress(string(RUU_141))

     xyouts,min(xh141)+(max(xh141)-min(xh141))*0.1,max(yh141)-(max(yh141)-min(yh141))*0.1,string141,charsize=1.7,charthick=2
     xyouts,min(xh141)+(max(xh141)-min(xh141))*0.1,max(yh141)-(max(yh141)-min(yh141))*0.15,string141bis,charsize=1.7,charthick=2
     xyouts,min(xh141)+(max(xh141)-min(xh141))*0.1,max(yh141)-(max(yh141)-min(yh141))*0.2,string141tris,charsize=1.7,charthick=2
   
     print, 'Actual bin width: '+strcompress(string(newbin),/remove_all)
     print, 'Select a new bin width? (y/n, default, no)'
     read,selbin
    ENDIF ELSE BEGIN
     ggg='ciao'
     print, 'Too few points for a fit!'
     print, '"d" to discard this fit, any key to select another binning '
     read,ggg
     if ggg ne 'd' then selbin = 'y'
     if ggg eq 'd' then begin
      selbin = 'n'
      GFIT_141=-99.
      sig141=-99.
      RU_141=-99.
      RUU_141=-99.
     endif
    ENDELSE 
    if selbin eq 'y' then begin
     print,'New bin width:'
     read, newbin
    endif
   endwhile
   
  endif
 ENDIF

 if fff ne 'q' then begin
    print, 'OPTIONS:'
    print, 's  --> save'
    print, 'b  --> redo this beam'
    print, 'bb --> return to previous beam'
    print, 'q  --> EXIT (saving all modifications)'
    print, 'any other key to continue without saving'
  fff='fff'
  read,fff
 endif 

 if fff eq 's' then begin
  IF kf_102 eq 'y' or kf_141 eq 'y' then begin
   ; ID, WISP-sigma (G102), GAUSS-sigma (G102), Analytical-sigma (G102), WISP-sigma (G141), GAUSS-sigma (G141), Analytical-sigma (G141)
   SAVE[NN]='y'    ;Save (y/n)
   IF G102_OBS eq 'YES' and kf_102 eq 'y' then begin
    SAVE_VEC[0,NN]=RU_102      ;WISP-sigma (G102)
    SAVE_VEC[1,NN]=RUU_102      ;WISP-sigma uncertainy (G102)
    SAVE_VEC[2,NN]=sig_gauss102 ;GAUSS-sigma (G102)
    SAVE_VEC[3,NN]=sig102 ;Analytical-sigma (G102)
   ENDIF
   IF G141_OBS eq 'YES' and kf_141 eq 'y' then begin
    SAVE_VEC[4,NN]=RU_141 ;WISP-sigma (G141)
    SAVE_VEC[5,NN]=RUU_141 ;WISP-sigma uncertainy (G141)
    SAVE_VEC[6,NN]=sig_gauss141 ;GAUSS-sigma (G141)
    SAVE_VEC[7,NN]=sig141 ;Analytical-sigma (G141)
   ENDIF
  ENDIF ELSE BEGIN
  print, "Results can't be saved (none of the fits where kept)" 
  ENDELSE
  
 endif
 
 IF strlowcase(fff) EQ 'q' THEN NN=n_elements(beam)
 IF strlowcase(fff) EQ 'b' THEN NN=NN-1
 IF strlowcase(fff) EQ 'bb' THEN NN=NN-2
 IF NN le -2 THEN NN=-1
 
NN=NN+1
ENDWHILE



; Save in an output file
; **********************
saveout='m'
while saveout ne 'y' and saveout ne 'n' do begin
 Print,'Save results in: '+fileout+' ? (y/n)'
 read,saveout
 if saveout eq 'y' then begin
  openw,u1,fileout,/get_lun
  save_idx=where(SAVE eq 'y')
  if save_idx[0] ne -1 then begin
   HH=0L
   while HH lt n_elements(save_idx) do begin
    printf, u1,beam[save_idx[HH]],mag[save_idx[HH]],SAVE_VEC[0,save_idx[HH]],SAVE_VEC[1,save_idx[HH]],SAVE_VEC[2,save_idx[HH]],SAVE_VEC[3,save_idx[HH]],SAVE_VEC[4,save_idx[HH]],SAVE_VEC[5,save_idx[HH]],SAVE_VEC[6,save_idx[HH]],SAVE_VEC[7,save_idx[HH]],  format='(I5,1x, 9(F10.5,1x))'
    HH=HH+1
   endwhile
  endif
  CLOSE,u1
  FREE_LUN,u1
  print, 'Results saved in '+fileout
 endif
 
endwhile

;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
ENDIF
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
IF keyword_set(justplot) THEN BEGIN
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
readcol,fileout,beam,mag,RU_102,RUU_102,sig_gauss102,sig102,RU_141,RUU_141,sig_gauss141,sig141, format='i,f,f,f,f,f,f,f,f,f'

SIGMA_TEST_102=sig102
SIGMA_TEST_141=sig141

; SIGMA_TEST_102=sig_gauss102
; SIGMA_TEST_141=sig_gauss141

; SIGMA_TEST_102=(sig_gauss102+sig102)/2.
; SIGMA_TEST_141=(sig_gauss141+sig141)/2.

thresholdmag=21.5
SEL102=where(mag gt thresholdmag and RU_102 gt 0)
SEL141=where(mag gt thresholdmag and RU_141 gt 0)
;SEL102=where(RU_102 gt 0)
;SEL141=where(RU_141 gt 0)

MEDVAL102=median((RU_102[SEL102]-SIGMA_TEST_102[SEL102])/abs(SIGMA_TEST_102[SEL102]))
MEVAL102=mean((RU_102[SEL102]-SIGMA_TEST_102[SEL102])/abs(SIGMA_TEST_102[SEL102]))
MEDVAL141=median((RU_141[SEL141]-SIGMA_TEST_141[SEL141])/abs(SIGMA_TEST_141[SEL141]))
MEVAL141=mean((RU_141[SEL141]-SIGMA_TEST_141[SEL141])/abs(SIGMA_TEST_141[SEL141]))


xx1=(indgen(21)-10.)/10.
xx2=-1*xx1[sort(xx1)]
yy1=sqrt(1-(xx1*xx1))
yy2=-sqrt(1-(xx1*xx1))
xx=[xx1,xx2]
yy=[yy1,yy2]
usersym,xx,yy,/fill

!p.font=0
set_plot, 'PS'
DEVICE, /ENCAPSUL,/COLOR, XSIZE=25,YSIZE=15,/cm,FILENAME=plotout
loadct,13,/silent

SS=0L
WHILE SS lt 2 do begin

  IF SS EQ 0 THEN BEGIN
  plothist,   (RU_102[SEL102]-SIGMA_TEST_102[SEL102])/abs(SIGMA_TEST_102[SEL102]),xh102,yh102,bin=0.1,/noplot
  plothist,   (RU_141[SEL141]-SIGMA_TEST_141[SEL141])/abs(SIGMA_TEST_141[SEL141]),xh141,yh141,bin=0.1,/noplot
  yrangeh=max([max(yh102),max(yh141)])
  plothist,(RU_102[SEL102]-SIGMA_TEST_102[SEL102])/abs(SIGMA_TEST_102[SEL102]),bin=0.1,position=[0.7,0.1,0.97,0.47],yrange=[-1,0.75],xrange=[0,yrangeh+0.1*yrangeh],rotate=90,color=110,thick=3,xthick=3,ythick=3,charthick=2,charsize=1.2,/fill,/fline,forientation=75,fcolor=110
  plothist,(RU_141[SEL141]-SIGMA_TEST_141[SEL141])/abs(SIGMA_TEST_141[SEL141]),bin=0.1,/overplot,color=298,thick=3,rotate=90,/fill,/fline,forientation=115,fcolor=298
  plot,[0,100],[0,0],xrange=[20,25],yrange=[-1,0.75],/xst,/yst,ytitle='(sig_wisp-sig_analytic)/|sig_analytic|',xtitle='Magnitude (J)',xthick=3,ythick=3,charthick=2,charsize=1.2,position=[0.1,0.1,0.65,0.47],/noerase
  ystring1=0.1
  ystring2=0.3
  ystring1B=-0.2
  ystring2B=-0.4
 ENDIF
 IF SS EQ 1 THEN BEGIN
  plothist,(RU_102[SEL102]-SIGMA_TEST_102[SEL102])/abs(SIGMA_TEST_102[SEL102]),bin=0.025,position=[0.7,0.55,0.97,0.92],yrange=[-0.15,0.15],xrange=[0,yrangeh/2],rotate=90,color=110,thick=3,xthick=3,ythick=3,charthick=2,charsize=1.2,/noerase,/fill,/fline,forientation=75,fcolor=110
  plothist,(RU_141[SEL141]-SIGMA_TEST_141[SEL141])/abs(SIGMA_TEST_141[SEL141]),bin=0.025,/overplot,color=298,thick=3,rotate=90,/fill,/fline,forientation=115,fcolor=298
  plot,[0,100],[0,0],xrange=[20,25],yrange=[-0.15,0.15],/xst,/yst,xthick=3,ythick=3,charthick=2,charsize=1.2,position=[0.1,0.55,0.65,0.92],/noerase
  ystring1=0.02
  ystring2=0.05
  ystring1B=-0.03
  ystring2B=-0.055
ENDIF
 
 oplot,[0,100],[0,0],thick=3;,color=180
 oplot,[thresholdmag,thresholdmag],[-10,10],thick=3,linestyle=2
 
 oplot,mag[SEL102],(RU_102[SEL102]-SIGMA_TEST_102[SEL102])/abs(SIGMA_TEST_102[SEL102]),psym=8,symsize=0.75
 oplot,mag[SEL102],(RU_102[SEL102]-SIGMA_TEST_102[SEL102])/abs(SIGMA_TEST_102[SEL102]),psym=8,symsize=0.55,color=110
 oplot,mag[SEL141],(RU_141[SEL141]-SIGMA_TEST_141[SEL141])/abs(SIGMA_TEST_141[SEL141]),psym=8,symsize=0.75
 oplot,mag[SEL141],(RU_141[SEL141]-SIGMA_TEST_141[SEL141])/abs(SIGMA_TEST_141[SEL141]),psym=8,symsize=0.55,color=298
 oplot,[0,100],[MEDVAL102,MEDVAL102],thick=3,linestyle=2,color=110
 oplot,[0,100],[MEVAL102,MEVAL102],thick=3,linestyle=1,color=110
 oplot,[0,100],[MEDVAL141,MEDVAL141],thick=3,linestyle=2,color=298
 oplot,[0,100],[MEVAL141,MEVAL141],thick=3,linestyle=1,color=298

 xyouts,20.25,ystring1,'G102',charthick=2,charsize=1.3,color=110
 xyouts,20.25,ystring2,'G141',charthick=2,charsize=1.3,color=298
 
 xyouts,20.25,ystring1B,'_ _ _ Median',charthick=2,charsize=1.3
 xyouts,20.25,ystring2B,'. . . . Mean',charthick=2,charsize=1.3



 
SS=SS+1
ENDWHILE

loadct,12,/silent
device,/close
set_plot,'X'
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
ENDIF
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


stop
end
