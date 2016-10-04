;##############################################################
;# WISPIPE
;# Reduction Pipeline for the WISP program (Atek et al. 2010)
;# Hakim Atek 2009
;###############################################################
;# Purpose: to create the 1D spectra in the Spectra folder and the 2D
;# stamps in the Stamps folder
;# Input: field 
;#        trim
;# 
;# Output: 1D spectra in *.dat in the Plots directory
;#         2D grism stamps in *.fits in the Stamps directory
;# 
;# Sophia Dai 2015.04.30  comment option added to the forprint step
;# Last update
;# Sophia Dai 2015.08.10  g*_1x, g*_1y added to correct for the
;# contamination flag errors
;###############################################################

PRO axe_sing_IB1,field,beam,n,shift,trim,SAVE=SAVE,path0,NOPLOT=NOPLOT

 bin=1.

;  path="~/data2/WISPS/aXe/"+field+"/"
  path = expand_path(path0)+'/aXe/'+field+"/"
  G102_path=path+"/G102_DRIZZLE/"
  G141_path=path+"/G141_DRIZZLE/"

         ;=========================================================================
         ;                  READ EXTRACTED MULTI-SPECTRA FILES                    =
         ;=========================================================================

         match_count=0
         readcol,path+'DATA/DIRECT_GRISM/F160_clean.list',f160_list,format=('A')

         G102_SPEC=G102_path+'aXeWFC3_G102_2_opt.SPC.fits'
;       help, temp, /struct
         G102_STP=G102_path+'aXeWFC3_G102_2_opt.STP.fits'
         G141_SPEC=G141_path+'aXeWFC3_G141_2_opt.SPC.fits'
         G141_STP=G141_path+'aXeWFC3_G141_2_opt.STP.fits'
         
         readcol,path+'DATA/DIRECT_GRISM/cat_F110.cat',magj,format=('x,x,x,x,x,x,x,x,x,x,x,f'),/silent
         if f160_list[0] ne 'none' then begin
            readcol,path+'DATA/DIRECT_GRISM/cat_F160.cat',magh,format=('x,x,x,x,x,x,x,x,x,x,x,f'),/silent
         endif else begin
            readcol,path+'DATA/DIRECT_GRISM/cat_F140.cat',magh,format=('x,x,x,x,x,x,x,x,x,x,x,f'),/silent 
         endelse 
         readcol,path+'DATA/DIRECT_GRISM/G102_0th.txt',g102_zx,g102_zy,g102_z_beam,g102_zmag,format=('f,f,i,f'),/silent 
         readcol,path+'DATA/DIRECT_GRISM/G141_0th.txt',g141_zx,g141_zy,g141_z_beam,g141_zmag,format=('f,f,i,f'),/silent 
         readcol,path+'DATA/DIRECT_GRISM/G102_1st.txt',g102_x,g102_y,g102_1_beam,format=('f,f,i'),/silent 
         readcol,path+'DATA/DIRECT_GRISM/G141_1st.txt',g141_x,g141_y,g141_1_beam,format=('f,f,i'),/silent 
       
!p.font=0
beam_pet,field,beam,pet_a,pet_b,/both,expand_path(path0)
;convert pet_a & pet_b to the larger scale, added by SD 2015.8
pet_a = 1.60318*pet_a
pet_b = 1.60318*pet_b


;################################  GRISM G102   ##################################

    ; READ STAMP FILES
    ;***********************************************************
    STP_ID='BEAM_'+STRING(beam,Format='(I0.3)')+'A' ;beams(k)
    print,"READING G102 ....... STAMP .......",STP_ID
    FITS_READ,G102_STP,G102_STAMP,header,EXTNAME=STP_ID,/NO_ABORT


   ; MATCH SPECTRUM & STAMP BEAMS
   ;**********************************************************
    fits_open,G102_SPEC, fcb    ;read beam names in SPEC          
    NEXTEN_SPEC=fcb.nextend
    SPEC_IDs=fcb.extname
    fits_close,fcb
    SPC_IND=where(SPEC_IDs EQ STP_ID) 


   ; READ SPEC FILES, array size= 255
   ;**********************************************************
    IF (SPC_IND[0] NE -1) THEN BEGIN
       match_count=match_count+1
       ftab_ext,G102_SPEC,'ID,lambda,flux,ferror,weight,contam',$
         SPEC_ID,G102_wave,G102_flux,G102_ferr,weight,G102_contam,EXTEN_NO=SPC_IND[0]
       print,"READING G102 ........ SPEC .......",SPEC_ID

;        if N_elements(G102_wave) eq 0 then return

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

   ; flagging zeroth order contamination and edge truncation
   ; problem targeted by CS of wrong contamination flag in G102 on 2015.8.7
                                ; updated by SD to correct the
                                ; contamination flag errors: add the
                                ; g102_1x,g102_1y parameters
   ;*********************************************************

   ;G102 ---------
   g102_zo=G102_flux*0.
;   g102_1x = round (g102_x[beam-1])
;   g102_1y = round (g102_y[beam-1])
   for l=0,n_elements(g102_zx)-1 do begin
          ind_a=where(round(pet_a[*,0]) eq round(g102_zx(l)) and round(pet_a[*,1]) eq round(g102_zy(l)) and g102_zmag(l) lt 22.5 ); and g102_zx(l) gt (g102_1x-92) and  g102_zx(l) lt (g102_1x+92) and g102_zy(l) gt (g102_1y -4) and g102_zy(l) lt (g102_1y +4) )
          if ind_a[0] ne -1 then begin             
             g102_lam_zo=reform(pet_a[ind_a,2])
             for p=0,n_elements(ind_a)-1 do begin 
                g102_zo( where( abs(G102_wave-g102_lam_zo[p]) eq min( abs(G102_wave-g102_lam_zo[p]) )))=1
                print,".....G102..BEAM..CONTAMINATED..by..0th..order..of..object...",g102_z_beam(l)
             endfor   
          endif
      endfor        
   g102_trun=G102_flux*0.
   maxla=max(pet_a[*,2])    
   ind_truna=where(G102_wave gt maxla)
   if ind_truna[0] ne -1 then begin 
      g102_trun(ind_truna)=2
      g102_zo=g102_zo+g102_trun
   endif

ENDIF                      ;correspond to     'IF (SPC_IND[0] NE -1)' in line 70
;################################  GRISM G141   ##################################

   ; READ STAMP FILES
   ;***********************************************************
   STP_ID='BEAM_'+STRING(beam,Format='(I0.3)')+'A' ;beams(k)
   print,"READING G141 ....... STAMP .......",STP_ID
   FITS_READ,G141_STP,G141_STAMP,header,EXTNAME=STP_ID,/NO_ABORT

   ; MATCH SPECTRUM & STAMP BEAMS
   ;**********************************************************
   fits_open,G141_SPEC, fcb     ;read beam names in SPEC          
   NEXTEN_SPEC=fcb.nextend
   SPEC_IDs=fcb.extname
   fits_close,fcb
   SPC_IND2=where(SPEC_IDs EQ STP_ID) 

   ; READ SPEC FILES
   ;**********************************************************
   IF (SPC_IND2[0] NE -1) THEN BEGIN
      match_count=match_count+1
      ftab_ext,G141_SPEC,'ID,lambda,flux,ferror,weight,contam',$
         SPEC_ID,G141_wave,G141_flux,G141_ferr,weight,g141_contam,EXTEN_NO=SPC_IND2[0]
      print,"READING G141 ........ SPEC .......",SPEC_ID
   ;ENDIF
;;;; MR edit - if SPEC_IND[0] eq -1 then it doesn't read the
;;;;           spectrum. But it still expects to see the spectrum
;;;;           below. Hence comment out the endif here, and add it
;;;;           below so it doesn't crash. What was logic here before?

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


   ;G141 --zeroth--flag------
   ; updated by SD to correct the contamination flag errors:
   ;add the g141_1x,g141_1y parameters
   g141_zo=G141_flux*0.
;   g141_1x = round (g141_x[beam-1])
;   g141_1y = round (g141_y[beam-1])
       for m=0,n_elements(g141_zx)-1 do begin
          ind_b=where(round(pet_b[*,0]) eq round(g141_zx(m)) and round(pet_b[*,1]) eq round(g141_zy(m)) and g141_zmag(m) lt 22.5 ); and g141_zx(m) gt (g141_1x-92) and  g141_zx(m) lt (g141_1x+92) and g141_zy(m) gt (g141_1y -4) and g141_zy(m) lt (g141_1y +4))
         if ind_b[0] ne -1 then begin
             g141_lam_zo=pet_b[ind_b,2]
             for p=0,n_elements(ind_b)-1 do begin 
                g141_zo( where( abs(G141_wave-g141_lam_zo[p]) eq min( abs(G141_wave-g141_lam_zo[p]) )))=1
                print,".....G141..BEAM..CONTAMINATED..by..0th..order..of..object...",g141_z_beam(m)
             endfor   
          endif
      endfor

   g141_trun=G141_flux*0.
   maxlb=max(pet_b[*,2])    
   ind_trunb=where(G141_wave gt maxlb)
   if ind_trunb[0] ne -1 then begin
      g141_trun(ind_trunb)=2
      g141_zo=g141_zo+g141_trun
   endif
ENDIF                           ;correspond to     'IF (SPC_IND2[0] NE -1)' in line 150


;################################  PLOTS ################################  
; modified to show all data
IF (SPC_IND[0] NE -1) and (SPC_IND2[0] NE -1) then ymax=max([G102_flux_trim[5:n_elements(G102_flux_rebin)-15], G141_flux_trim[5:n_elements(G141_flux_rebin)-15]])*1.2
IF (SPC_IND[0] NE -1) and (SPC_IND2[0] eq -1) then ymax=max(G102_flux_trim[5:n_elements(G141_flux_rebin)-15])*1.2
IF (SPC_IND[0] eq -1) and (SPC_IND2[0] NE -1) then ymax=max(G141_flux_trim[5:n_elements(G141_flux_rebin)-15])*1.2
IF (SPC_IND[0] eq -1) and (SPC_IND2[0] eq -1) then begin
IF NOT(keyword_set(NOPLOT)) THEN  plot,[0],[0],xrange=[7200,16500],yrange=[-1e-18,10 ]/1e-18,/xstyle,/ystyle,ytitle=TextoIDL('Flux (10^{-18} ergs s^{-1} cm^{-2} A^{-1})'),xtitle='Wavelength (A)',xmargin=[18,8],ymargin=[10,10],xthick=3,ythick=3,charthick=2,xcharsize=2.1,ycharsize=2.05
   return ; ? I do not remove this only because I do not understand...
Endif
;changed ymax to 10 as a test 2015.03.26


IF NOT(keyword_set(NOPLOT)) THEN BEGIN
   plot,[0],[0],xrange=[7200,16500],yrange=[-1e-18,ymax]/1e-18,/xstyle,/ystyle,ytitle=TeXtoIDL('Flux (10^{-18} ergs s^{-1} cm^{-2} A^{-1})'),xtitle='Wavelength (A)',xmargin=[18,8],ymargin=[10,10],xthick=3,ythick=3,charthick=2,xcharsize=2.1,ycharsize=2.05
   x = (!X.Window[1] - !X.Window[0]) / 2. + !X.Window[0] 
   ypos=0.95-(shift/3.)

   XYOuts, x, ypos,'Object'+strcompress(beam)+TeXtoIDL('   J_{110}=')+STRING(magj[n],FORMAT='(F5.2)')$
           +TeXtoIDL('   H_{140}=')+STRING(magh[n], FORMAT='(F5.2)'),/Normal, Alignment=0.5, Charsize=1.25
       if (n eq 1) then begin
          loadct,0
          xyouts,x,0.98,"WISP Survey -- "+field+" 1D spectra -- HA "+systime(),$
                 /Normal, Alignment=0.5, Charsize=1.1,color=50
       endif
   loadct,12,/silent
ENDIF                           ;

   ; PLOTS G102, changed from G102_*_rebin to G102_*_trim by SD, 2015.04.30
   ;***********************************************************************************************
IF (SPC_IND[0] NE -1) then begin
IF NOT(keyword_set(NOPLOT)) THEN BEGIN
   oplot,G102_wave_trim,G102_flux_trim/1e-18,color=100,thick=3,psym=10
   ;oploterror,G102_wave_rebin,G102_flux_rebin,G102_ferr_rebin,thick=1,psym=3,/nohat
   oplot,G102_wave_trim,G102_contam_trim/1e-18,thick=2,psym=10

ind_con=where(g102_zo eq 1)

   if ind_con[0] ne -1 then begin
       for q=0,n_elements(ind_con)-1  do begin
          oplot,replicate(G102_wave(ind_con[q]),2),[ymax,ymax/2.]/1e-18,thick=4,color=25,linestyle=2
       endfor
    endif
ENDIF
ENDIF 

   ; PLOTS G141, changed from G141_*_rebin to G141_*_trim by SD, 2015.04.30
   ;****************************
IF (SPC_IND2[0] NE -1) then begin
IF NOT(keyword_set(NOPLOT)) THEN BEGIN
  oplot,G141_wave_trim,G141_flux_trim/1e-18,color=200,thick=3,psym=10
  oplot,G141_wave_trim,G141_contam_trim/1e-18,thick=2,psym=10   
   ;oploterror,G141_wave_rebin,G141_flux_rebin,G141_ferr_rebin,thick=1,psym=3,/nohat

   ind_con=where(g141_zo eq 1)
   if ind_con[0] ne -1 then begin
       for q=0,n_elements(ind_con)-1  do begin
          oplot,replicate(G141_wave(ind_con[q]),2),[ymax,ymax/2.]/1e-18,thick=4,color=25,linestyle=2
       endfor   
  endif
ENDIF
ENDIF
                                ;SPAWN,'ds9
                                ;'+path+'Stamps/G102_stamp.fits -zoom
                                ;3 -zscale -geometry 1340x400 '$+path+'Stamps/G141_stamp.fits &'


        IF keyword_set(SAVE) THEN BEGIN
           IF (SPC_IND[0] NE -1) then begin
         ;  IF (beam lt 800 or (beam ge 1000 and beam lt 2000)) THEN BEGIN
              FORPRINT,G102_wave,G102_FLUX,G102_ferr,G102_contam,G102_zo $
                       ,COMMENT='#     wave      flux            error           contam           zeroth' $
                       ,TEXTOUT=path+'Spectra/'+field+'_G102_'+STP_ID+'.dat',/silent    
              WRITEFITS,path+'Stamps/'+field+'_G102_'+STP_ID+'.fits',G102_STAMP
           ENDIF
         ;  IF (beam lt 800 or beam ge 2000) THEN BEGIN
              IF (SPC_IND2[0] NE -1) THEN BEGIN
                 FORPRINT,G141_wave,G141_FLUX,G141_ferr,G141_contam,G141_zo $
                          ,COMMENT='#     wave      flux            error           contam           zeroth' $
                          ,TEXTOUT=path+'Spectra/'+field+'_G141_'+STP_ID+'.dat',/SILENT
                 WRITEFITS,path+'Stamps/'+field+'_G141_'+STP_ID+'.fits',G141_STAMP
              ENDIF
             
                 cut=0
                 dim1=n_elements(G102_wave_trim)
                 dim2=n_elements(G141_wave_trim)

              IF (SPC_IND[0] NE -1)  and (SPC_IND2[0] NE -1) THEN BEGIN
                 wave=[G102_wave_trim[0:dim1-(cut+1)],G141_wave_trim[cut:dim2-1]]
                 flux=[G102_flux_trim[0:dim1-(cut+1)],G141_flux_trim[cut:dim2-1]]
                 ferr=[G102_ferr_trim[0:dim1-(cut+1)],G141_ferr_trim[cut:dim2-1]]
                 contam=[G102_contam_trim[0:dim1-(cut+1)],G141_contam_trim[cut:dim2-1]] 
                 zeroth=[g102_zo[0:dim1-(cut+1)],g141_zo[cut:dim2-1]]
              ENDIF 
              IF (SPC_IND[0] NE -1)  and (SPC_IND2[0] eq -1) THEN BEGIN
                 wave=G102_wave_trim[cut:dim2-1]
                 flux=G102_flux_trim[cut:dim2-1]
                 ferr=G102_ferr_trim[cut:dim2-1]
                 contam=G102_contam_trim[cut:dim2-1]
                 zeroth=g102_zo[cut:dim2-1]
              endif
              IF (SPC_IND[0] eq -1) and (SPC_IND2[0] NE -1) then begin
                 wave=[G141_wave_trim[cut:dim2-1]]
                 flux=[G141_flux_trim[cut:dim2-1]]
                 ferr=[G141_ferr_trim[cut:dim2-1]]
                 contam=[G141_contam_trim[cut:dim2-1]] 
                 zeroth=[g141_zo[cut:dim2-1]]
              endif

              FORPRINT,wave,flux,ferr,contam,zeroth $
                       ,COMMENT='#     wave      flux            error           contam           zeroth' $
                       ,TEXTOUT=path+'Spectra/'+field+'_'+STP_ID+'.dat',/silent  
       ENDIF



END



   ;g102_shift_x=g102_1x(where(g102_1_beam eq beam))
   ;g102_semi_x=(max(pet_a[*,0])-min(pet_a[*,1]))/2.   
   ;pet_a[*,0]=pet_a[*,0]+(g102_shift_x[0]-g102_semi_x-min(pet_a[*,0])) 

   ;g102_shift_y=g102_1y(where(g102_1_beam eq beam))
   ;g102_semi_y=max((pet_a[*,1])-min(pet_a[*,1]))/2.   
   ;pet_a[*,1]=pet_a[*,1]+(g102_shift_y[0]-g102_semi_y-min(pet_a[*,1]))
