;##############################################################
;# WISPIPE
;# Reduction Pipeline for the WISP program (Atek et al. 2010)
;#
;# Written by Ivano Baronchelli, Novebre 2016
;# Purpose: plot spectra in ps files and write code to make a single
;# pdf file
;# Note: this program replace a part of the code previously
;#       written in wisp_extract.pro and axe_sing.pro
;#
;# Differences with older  wisp_extract.pro and axe_sing.pro
;# correspondent codes:
;#
;# Output: plots in eps format generated in the /Plots directory, with
;#   /spectra_0_* for obj ID < 10000 (matched in both filters - dualimage mode),
;#   /spectra_1_* for obj ID 10000-20000 (detected F110 but not in dual image mode)
;#   /spectra_2_* for obj ID 20000-30000 (detected F140/160 but not dual image mode)
;#   /spectra_3_* for obj ID >30000 (detected in F110 and F140/160 but not dual image mode )
;#   A pdf file with all the spectra plotted in one
;#
;# - joinpy procedure is allowed to make an unique pdf file.
;#  This should be the default in mac-OS systems (why people should
;#  install something else?).
;# - Plots are removed when correspondent stamps do not exist or if
;#  less than a certain % is visible (not null values).
;##############################################################


pro plot_spectra,field,trim, path0

bin=1.

path = expand_path(path0)+'/aXe/'+field+"/"
path4=path+"DATA/DIRECT/"
path5=path+"DATA/GRISM/"
 
G102_path=path+"/G102_DRIZZLE/"
G141_path=path+"/G141_DRIZZLE/"

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; OBS CHECK 
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
J_OBS='NO'    ; NO or YES observations in the F110 band
H_OBS='NO'    ; NO, F140 or F160
G102_OBS='NO' ; NO or YES observations in the G102 grism
G141_OBS='NO' ; NO or YES observations in the G141 grism
f110_list='none'
f140_list='none'
f160_list='none'
g102_list='none'
g141_list='none'
;------------------------------------------------
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

;     J      +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
IF TEST_J eq 0 and TEST_JB eq 1 then begin
   readcol,path4+'F110_clean.list',f110_list,format=('A')
   if strlowcase(f110_list[0]) ne 'none' and n_elements(f110_list[0]) gt 0 then J_OBS='YES'
ENDIF
;     H      F140 / F160 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
IF TEST_H1 eq 0 and TEST_H1B eq 1 then begin
   readcol,path4+'F140_clean.list',f140_list,format=('A')
   if strlowcase(f140_list[0]) ne 'none' and n_elements(f140_list[0]) gt 0 then H_OBS='F140'
ENDIF
IF TEST_H2 eq 0 and TEST_H2B eq 1 then begin
   readcol,path4+'F160_clean.list',f160_list,format=('A')
   if strlowcase(f160_list[0]) ne 'none' and n_elements(f160_list[0]) gt 0 then H_OBS='F160'
ENDIF
;    G102    +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
IF TEST_G102 eq 0 and TEST_G102B eq 1 then begin
   readcol,path5+'G102_clean.list',g102_list,format=('A')
   if strlowcase(g102_list[0]) ne 'none' and n_elements(g102_list[0]) gt 0 then G102_OBS='YES'
ENDIF
;    G141    +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
IF TEST_G141 eq 0 and TEST_G141B eq 1 then begin
   readcol,path5+'G141_clean.list',g141_list,format=('A')
   if strlowcase(g141_list[0]) ne 'none' and n_elements(g141_list[0]) gt 0 then G141_OBS='YES'
ENDIF
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

print, 'plot_spectra'
print, 'HHHHHHHHHHHHHHHHH'
print, TEST_J,TEST_JB
print, TEST_H1,TEST_H1B
print, TEST_H2,TEST_H2B
print, TEST_G102, TEST_G102B
print, TEST_G141, TEST_G141B
print, 'J_OBS = '+J_OBS
print, 'H_OBS = '+H_OBS
print, 'G102_OBS = '+G102_OBS
print, 'G141_OBS = '+G141_OBS
print, 'HHHHHHHHHHHHHHHHH'

num110 = n_elements(f110_list)
num140 = n_elements(f140_list)
num160 = n_elements(f160_list)
numG102 = n_elements(G102_list)
numG141 = n_elements(G141_list)

IF strlowcase(f110_list[0]) eq 'none' then num110  =0
IF strlowcase(f140_list[0]) eq 'none' then num140  =0
IF strlowcase(f160_list[0]) eq 'none' then num160  =0
IF strlowcase(g102_list[0]) eq 'none' then numG102 =0
IF strlowcase(g141_list[0]) eq 'none' then numG141 =0
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++






IF FILE_TEST(path+'DATA/DIRECT_GRISM/cat_F160.cat') eq 1 then catname=path+'DATA/DIRECT_GRISM/cat_F160.cat'
IF FILE_TEST(path+'DATA/DIRECT_GRISM/cat_F140.cat') eq 1 then catname=path+'DATA/DIRECT_GRISM/cat_F140.cat'
IF FILE_TEST(path+'DATA/DIRECT_GRISM/cat_F110.cat') eq 1 then catname=path+'DATA/DIRECT_GRISM/cat_F110.cat'

readcol,catname,object,format=('I')

IF J_OBS EQ 'YES' THEN  readcol,path+'DATA/DIRECT_GRISM/cat_F110.cat',magj,format=('x,x,x,x,x,x,x,x,x,x,x,f'),/silent
IF H_OBS EQ 'F140' THEN readcol,path+'DATA/DIRECT_GRISM/cat_F140.cat',magh,format=('x,x,x,x,x,x,x,x,x,x,x,f'),/silent
IF H_OBS EQ 'F160' THEN readcol,path+'DATA/DIRECT_GRISM/cat_F160.cat',magh,format=('x,x,x,x,x,x,x,x,x,x,x,f'),/silent


max0=0L ; Number of files created (ID 0-10000)
max1=0L ; Number of files created (ID 10000-20000)
max2=0L ; Number of files created (ID 20000-30000)
max3=0L ; Number of files created (ID 30000+)

PAGE='CLOSED'
!p.font=0

i=0L ; Page number (three plots per page)
n=0L ; Object number
while n lt n_elements(object) do begin
 shift=0
 RR=0L
 WHILE RR lt 3 do begin
  if n lt n_elements(object) then begin
   beam=object[n]

   if object[n] ge 0    and object[n] lt 10000 then car='0'
   if object[n] ge 10000 and object[n] lt 20000 then car='1'
   if object[n] ge 20000 and object[n] lt 30000 then car='2'
   if object[n] ge 30000 then car='3'
   IF object[n] eq 10000 then i=0
   IF object[n] eq 20000 then i=0
   IF object[n] eq 30000 then i=0

   Print,"Plotting beam ...............",beam
   stpname_102=path+'G102_DRIZZLE/'+'aXeWFC3_G102_mef_ID'+strcompress(string(beam),/remove_all)+'.fits'
   stpname_141=path+'G141_DRIZZLE/'+'aXeWFC3_G141_mef_ID'+strcompress(string(beam),/remove_all)+'.fits'
   FRAC_102=0.
   FRAC_141=0.

   if file_test(stpname_102) eq 1 then begin
    sttp_102=mrdfits(stpname_102,1,HD_102)
    totpix_102=float(n_elements(sttp_102))
    Pok_102=float(n_elements(where(sttp_102 ne 0 and sttp_102 eq sttp_102)))  
    FRAC_102=Pok_102/totpix_102             
   endif

   if file_test(stpname_141) eq 1 then begin
    sttp_141=mrdfits(stpname_141,1,HD_141)
    totpix_141=float(n_elements(sttp_102))
    Pok_141=float(n_elements(where(sttp_141 ne 0 and sttp_141 eq sttp_141)))
    FRAC_141=Pok_141/totpix_141           
   endif
            
   ;/////////////////////////////////////////////////////////////////////////////////////////
   YN='N'
   IF FRAC_102 gt 0.15 or FRAC_141 gt 0.15 THEN YN='Y'
   ;/////////////////////////////////////////////////////////////////////////////////////////

   if YN eq 'Y' then begin
    IF RR eq 0 or beam eq 10000 or beam eq 20000 or beam eq 30000 THEN BEGIN
     ; Close previous file 
     if PAGE eq 'OPEN' then begin
      device,/close
      set_plot,'X'
      PAGE='CLOSED'
     endif   
     RR=0    ; Reset plot counting
     i=i+1   ; change Page
     shift=0 ; Return at the beginning of this page
     ; open new file
     set_plot, 'PS'
     DEVICE, /ENCAPSUL,/COLOR, XSIZE=20,YSIZE=28,/cm,FILENAME=path+'Plots/spectra_'+car+'_'+strcompress(i,/remove_all)+'.eps'
     !P.MULTI = [0,1,3]
     PAGE='OPEN'
     ; update maximum value
     if object[n] ge 0 and object[n] lt 10000 then max0=max0+1
     if object[n] ge 10000 and object[n] lt 20000 then max1=max1+1
     if object[n] ge 20000 and object[n] lt 30000 then max2=max2+1
     if object[n] ge 30000 then max3=max3+1
    ENDIF

    
    ; ######################################################
    ;  READ files.dat containing spectra
    ; ######################################################

    OBS_102n='NO'
    IF G102_OBS EQ 'YES' THEN BEGIN
     STP_ID='BEAM_'+STRING(beam,Format='(I0.3)')+'A' ;beams(k)
     G102_specname=path+'Spectra/'+field+'_G102_'+STP_ID+'.dat'
     TEST_G102fA=file_test(G102_specname,/zero_length)    ; 1 if exists but no content
     TEST_G102fB=file_test(G102_specname)                 ; 1 if exists
     IF TEST_G102fA eq 0 and TEST_G102fB eq 1 then begin
      OBS_102n='YES'
      readcol,G102_specname,G102_wave,G102_flux,G102_ferr,G102_contam,G102_zo,format='f,f,f,f,f',/silent
      ;ENDIF
      ; TRIM EDGES  array size 255-->134
      ;****************
      IF (MIN(G102_wave) LE 8250 and MAX(G102_wave) GE 11500) THEN BEGIN
       min=where(G102_wave GE 8250) & max=where(G102_wave GE 11500)
       min=min[0]+trim+3 & max=max[0]-trim
       G102_wave_trim=G102_wave[min:max]
       G102_flux_trim=G102_FLUX[min:max]
       G102_ferr_trim=G102_ferr[min:max]
       G102_contam_trim=G102_contam[min:max]
      ENDIF ELSE BEGIN
       max=n_elements(g102_wave)-1    ;added by SD for plot correction
       min=0
       G102_wave_trim=G102_wave
       G102_flux_trim=G102_FLUX
       G102_ferr_trim=G102_ferr
       G102_contam_trim=G102_contam
      ENDELSE
      ;REBIN  SPECTRA  array size 134-->133
      ;*******************
      dim_in=max-min+1
      dim_out=dim_in/bin
      rebin=indgen(dim_in-1/bin)*bin 
      G102_flux_rebin=congrid(G102_flux_trim,dim_out)
      G102_ferr_rebin=congrid(G102_ferr_trim,dim_out)
      G102_contam_rebin=congrid(G102_contam_trim,dim_out)
      G102_wave_rebin=G102_wave_trim[rebin]
     ENDIF
    ENDIF

    OBS_141n='NO'
    IF G141_OBS EQ 'YES' THEN BEGIN
     STP_ID='BEAM_'+STRING(beam,Format='(I0.3)')+'A' ;beams(k)
     G141_specname=path+'Spectra/'+field+'_G141_'+STP_ID+'.dat'
     TEST_G141fA=file_test(G141_specname,/zero_length)    ; 1 if exists but no content
     TEST_G141fB=file_test(G141_specname)                 ; 1 if exists
     IF TEST_G141fA eq 0 and TEST_G141fB eq 1 then begin
      OBS_141n='YES'
      readcol,G141_specname,G141_wave,G141_flux,G141_ferr,G141_contam,G141_zo,format='f,f,f,f,f',/silent
      ;ENDIF
      ; TRIM EDGES
      ;****************
      IF (MIN(G141_wave) LT 10800 and MAX(G141_wave) GT 16900) THEN BEGIN
       min=where(G141_wave GE 10800) & max=where(G141_wave GE 16900)
       min=min[0]+trim+11 & max=max[0]-trim
       G141_wave_trim=G141_wave[min:max]
       G141_flux_trim=G141_FLUX[min:max]
       G141_ferr_trim=G141_ferr[min:max]
       G141_contam_trim=G141_contam[min:max]
      ENDIF ELSE BEGIN
       max=n_elements(g141_wave)-1    ;added by SD for plot correction
       min=0
       G141_wave_trim=G141_wave
       G141_flux_trim=G141_FLUX
       G141_ferr_trim=G141_ferr
       G141_contam_trim=G141_contam
      ENDELSE
      ;REBIN  SPECTRA
      ;*******************
      dim_in=max-min+1
      dim_out=dim_in/bin
      rebin=indgen(dim_in-1/bin)*bin 
      G141_flux_rebin=congrid(G141_flux_trim,dim_out)
      G141_ferr_rebin=congrid(G141_ferr_trim,dim_out)
      G141_wave_rebin=G141_wave_trim[rebin]
      G141_contam_rebin=G141_contam_trim[rebin]
     ENDIF
    ENDIF
    ; ######################################################
    ;  PLOTS
    ; ######################################################

    IF OBS_102n eq 'YES' and OBS_141n eq 'YES' then ymax=max([G102_flux_trim[5:n_elements(G102_flux_rebin)-15], G141_flux_trim[5:n_elements(G141_flux_rebin)-15]])*1.2
    IF OBS_102n eq 'YES' and OBS_141n ne 'YES' then ymax=max(G102_flux_trim[5:n_elements(G141_flux_rebin)-15])*1.2 ; 
    IF OBS_102n ne 'YES' and OBS_141n eq 'YES' then ymax=max(G141_flux_trim[5:n_elements(G141_flux_rebin)-15])*1.2
    IF OBS_102n ne 'YES' and OBS_141n ne 'YES' then begin
     plot,[0],[0],xrange=[7200,16500],yrange=[-1e-18,10 ]/1e-18,/xstyle,/ystyle,ytitle=TextoIDL('Flux (10^{-18} ergs s^{-1} cm^{-2} A^{-1})'),xtitle='Wavelength (A)',xmargin=[18,8],ymargin=[10,10],xthick=3,ythick=3,charthick=2,xcharsize=2.1,ycharsize=2.05 ;changed ymax to 10 as a test 2015.03.26
    ENDIF

    string1='Object '+strcompress(beam)
    print, string1
    IF J_OBS EQ 'YES' THEN string1=string1+TeXtoIDL('   J_{110}=')+STRING(magj[n],FORMAT='(F5.2)')
    IF H_OBS EQ 'F160' THEN string1=string1+TeXtoIDL('   H_{160}=')+STRING(magh[n], FORMAT='(F5.2)')
    IF H_OBS EQ 'F140' THEN string1=string1+TeXtoIDL('   H_{140}=')+STRING(magh[n], FORMAT='(F5.2)')

    plot,[0],[0],xrange=[7200,16500],yrange=[-1e-18,ymax]/1e-18,/xstyle,/ystyle,$
     ytitle=TeXtoIDL('Flux [10^{-18} ergs s^{-1} cm^{-2} A^{-1}]'),xtitle='Wavelength [A]',$
     xmargin=[18,8],ymargin=[10,10],xthick=3,ythick=3,charthick=2,xcharsize=2.1,ycharsize=2.05
    x = (!X.Window[1] - !X.Window[0]) / 2. + !X.Window[0] 
    ypos=0.95-(shift/3.)
    XYOuts, x, ypos,string1,/Normal, Alignment=0.5, Charsize=1.25
    if (n eq 1) then begin
     loadct,0
     xyouts,x,0.98,"WISP Survey -- "+field+" 1D spectra -- HA "+systime(),$
     /Normal, Alignment=0.5, Charsize=1.1,color=50
    endif
    loadct,12,/silent

    ; PLOTS G102, changed from G102_*_rebin to G102_*_trim by SD, 2015.04.30
    ;***********************************************************************************************

    PLOT_ZERO='YES'
    IF PLOT_ZERO EQ 'YES' THEN BEGIN

    zerotoplot=1 ; this option will plot possible contamination from zeroth orders inside the stamps, but outside the non-zero region of the spectrum  
    zerotoplot=2 ; this option will plot possible contamination from zeroth orders inside the stamps, and inside the non-zero region of the spectrum   
    zerotoplot=3 ; this option will plot possible contamination from zeroth orders inside the stamps, and inside the non-zero region of the spectrum only if they have a magnitude lower (=brighter) than 22.5 
       
    IF OBS_102n eq 'YES' then begin
     ; ind_con=where(g102_zo ge zerotoplot) 
     ind_con=where(g102_zo ge zerotoplot and G102_wave gt 8.251e3 and G102_wave lt 1.15e4) 
     if ind_con[0] ne -1 then begin
      for q=0,n_elements(ind_con)-1  do begin
       ; oplot,replicate(G102_wave(ind_con[q]),2),[ymax,ymax/2.]/1e-18,thick=4,color=25,linestyle=2
       loadct,13,/silent
       ;oplot,[G102_wave(ind_con[q]),G102_wave(ind_con[q])],[-100,ymax*2.]/1e-18,thick=10,color=215;,linestyle=2
       oplot,[G102_wave(ind_con[q]),G102_wave(ind_con[q])],[-100,ymax*2.]/1e-18,thick=10,color=212;,linestyle=2
       loadct,12,/silent
      endfor
     endif
    ENDIF

    IF OBS_141n eq 'YES' then begin
     ind_con=where(g141_zo ge zerotoplot)
     ind_con=where(g141_zo ge zerotoplot and G141_wave ge 1.15e4 and  G141_wave lt 1.7e4)
     if ind_con[0] ne -1 then begin
      for q=0,n_elements(ind_con)-1  do begin
       ; oplot,replicate(G141_wave(ind_con[q]),2),[ymax,ymax/2.]/1e-18,thick=4,color=25,linestyle=2
       loadct,13,/silent
       oplot,[G141_wave[ind_con[q]],G141_wave[ind_con[q]]],[-100,ymax*2.]/1e-18,thick=10,color=218;,linestyle=2
       loadct,12,/silent
      endfor
     endif 
    ENDIF

    ENDIF

       
    IF OBS_102n eq 'YES' then begin
     oplot,G102_wave_trim,G102_flux_trim/1e-18,color=100,thick=3,psym=10
     oplot,G102_wave_trim,G102_contam_trim/1e-18,thick=2,psym=10 
     ;oploterror,G102_wave_rebin,G102_flux_rebin,G102_ferr_rebin,thick=1,psym=3,/nohat
    ENDIF 

    ; PLOTS G141, changed from G141_*_rebin to G141_*_trim by SD, 2015.04.30
    ;****************************
    IF OBS_141n eq 'YES' then begin
     oplot,G141_wave_trim,G141_flux_trim/1e-18,color=200,thick=3,psym=10
     oplot,G141_wave_trim,G141_contam_trim/1e-18,thick=2,psym=10   
     ;oploterror,G141_wave_rebin,G141_flux_rebin,G141_ferr_rebin,thick=1,psym=3,/nohat
    ENDIF
    
    ; ######################################################
    ;  PLOTS - END -
    ; ######################################################

    
    ;;;; axe_sing_IB1,field,beam,n,shift,trim,/save,expand_path(path0)
    shift=shift+1
   endif

   if YN eq 'N' then begin
    print, "Object "+strcompress(string(beam))+"Not plotted in output file (less than 15% coverage in both Grism stamps)"
    RR=RR-1   
   endif
            
   RR=RR+1
  endif
  if n ge n_elements(object) then RR=9999    ; big number to exit
  n=n+1
 ENDWHILE

 IF PAGE eq 'OPEN' then begin
  device,/close
  set_plot,'X'
  PAGE='CLOSED'
 ENDIF


endwhile









;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;; MAKE SINGLE pdf file ;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



spawn,'ls -1 '+path+'Plots/spectra_*.eps | sort -t "_" -n -k2,2 -k3,3 -k4,4 > '+path+'Plots/eps.list'



;create pdf from all eps files

;PSTOPDF='gs'     ; USE GOSTSCRIPT
;PSTOPDF='joinpy'  ; USE joinpy (default on mac OS)

; check to see whether to use join.py (Mac OSX) or gs (good for Linux)
result = FILE_TEST('/System/Library/Automator/Combine PDF Pages.action/Contents/Resources/join.py')
if result eq 1 then PSTOPDF='joinpy' else PSTOPDF='gs'

if PSTOPDF eq 'gs' then begin
   spawn,'gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile='+path+'Plots/'+field+'_spectra.pdf @'+path+'Plots/eps.list'
endif


openw,1,path+'Plots/make_pdf.sh'
printf,1,'#!/bin/csh'
if PSTOPDF eq 'joinpy' then begin
;  spawn,'"/System/Library/Automator/Combine PDF Pages.action/Contents/Resources/join.py" -o '+path+'Plots/'+field+'_spectra.pdf *.pdf' ; DOESN'T work!
;   printf,1,'"/System/Library/Automator/Combine PDF Pages.action/Contents/Resources/join.py" -o '+path+'Plots/'+field+'_spectra.pdf *.pdf'
stringa='"/System/Library/Automator/Combine PDF Pages.action/Contents/Resources/join.py" -o '+path+'Plots/'+field+'_spectra.pdf'


EE=1L
WHILE EE le max0 DO BEGIN
; Convert eps --> pdf
spawn,'pstopdf '+path+'Plots/spectra_0_'+strcompress(EE,/remove_all)+'.eps'
stringa=stringa+' '+'spectra_0_'+strcompress(EE,/remove_all)+'.pdf'
EE=EE+1
ENDWHILE

EE=1L
WHILE EE le max1 DO BEGIN
; Convert eps --> pdf
spawn,'pstopdf '+path+'Plots/spectra_1_'+strcompress(EE,/remove_all)+'.eps'
stringa=stringa+' '+'spectra_1_'+strcompress(EE,/remove_all)+'.pdf'
EE=EE+1
ENDWHILE

EE=1L
WHILE EE le max2 DO BEGIN
; Convert eps --> pdf
spawn,'pstopdf '+path+'Plots/spectra_2_'+strcompress(EE,/remove_all)+'.eps'
stringa=stringa+' '+'spectra_2_'+strcompress(EE,/remove_all)+'.pdf'
EE=EE+1
ENDWHILE

EE=1L
WHILE EE le max3 DO BEGIN
; Convert eps --> pdf
spawn,'pstopdf '+path+'Plots/spectra_3_'+strcompress(EE,/remove_all)+'.eps'
stringa=stringa+' '+'spectra_3_'+strcompress(EE,/remove_all)+'.pdf'
EE=EE+1
ENDWHILE

printf,1,stringa

; PDF files will be removed ... but not now 
endif
close,1
free_lun,1


;remove eps files, to save space?  Don't do it to be safe
;spawn,'rm '+path+'Plots/spectra_*eps'





end
