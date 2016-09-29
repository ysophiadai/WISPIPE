;##############################################################
;# WISPIPE
;# Reduction Pipeline for the WISP program (Atek et al. 2010)
;# Hakim Atek 2009
;###############################################################
;# Purpose: to generate the 1D spectra & 2D grism cutout
;# Input: field
;#        beam
;#        n
;#        shift
;#        trim
;#        the GRISM STP file where stamp images of extracted beams
;# are stored.
;#        the GRISM SPC file where extracted 1D spectra are stored.
;# procedure called: axe_sing
;# Output:
;#         2D STAMP images of extracted beams in the Stamps folder
;#         1D Spectra in the Spectra folder
;# 
;# updated by 
;# Sophia Dai 2015.02.20
;###############################################################

PRO axe_sing_g141,field,beam,n,shift,trim,SAVE=SAVE, path0

 bin=1.

;  path="~/data2/WISPS/aXe/"+field+"/"
  path = path0+'/aXe/'+field+"/"
  G141_path=path+"/G141_DRIZZLE/"

         ;=========================================================================
         ;                  READ EXTRACTED MULTI-SPECTRA FILES                    =
         ;=========================================================================

         match_count=0
         readcol,path+'DATA/DIRECT_GRISM/F160_clean.list',f160_list,format=('A')

         G141_SPEC=G141_path+'aXeWFC3_G141_2_opt.SPC.fits'
         G141_STP=G141_path+'aXeWFC3_G141_2_opt.STP.fits'
  
         if f160_list[0] ne 'none' then begin
            readcol,path+'DATA/DIRECT_GRISM/cat_F160.cat',magh,format=('x,x,x,x,x,x,x,x,x,x,x,f'),/silent
         endif else begin
         readcol,path+'DATA/DIRECT_GRISM/cat_F140.cat',magh,format=('x,x,x,x,x,x,x,x,x,x,x,f'),/silent
         endelse
         readcol,path+'DATA/DIRECT_GRISM/G141_0th.txt',g141_zx,g141_zy,g141_z_beam,g141_zmag,format=('f,f,f,f'),/silent 
       
!p.font=0


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
   SPC_IND=where(SPEC_IDs EQ STP_ID) 

   ; READ SPEC FILES
   ;**********************************************************
   IF (SPC_IND[0] NE -1) THEN BEGIN
      match_count=match_count+1
      ftab_ext,G141_SPEC,'ID,lambda,flux,ferror,weight,contam',$
         SPEC_ID,G141_wave,G141_flux,G141_ferr,weight,g141_contam,EXTEN_NO=SPC_IND[0]
 

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

 ; flagging zeroth order contamination
   ;*************************************
   beam_pet,field,beam,pet_a,pet_b,path0

   ;G141 --zeroth--flag------
   g141_zo=G141_flux*0.

       for m=0,n_elements(g141_zx)-1 do begin
          ind_b=where(round(pet_b[*,0]) eq round(g141_zx(m)) and round(pet_b[*,1]) eq round(g141_zy(m)) and g141_zmag(m) lt 22.5)
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

   ; PLOTS 
   ;***********************************************************************************************

   ymax=max(G141_flux_rebin[10:n_elements(G141_flux_rebin)-15])*1.2


   plot,[0],[0],xrange=[7200,16500],yrange=[-1e-18,ymax]/1e-18,/xstyle,/ystyle,$
      ytitle=TeXtoIDL('Flux (10^{-18} ergs s^{-1} cm^{-2} A^{-1})'),xtitle='Wavelength (A)',$
      xmargin=[18,8],ymargin=[10,10],xthick=3,ythick=3,charthick=2,xcharsize=2.1,ycharsize=2.05
   x = (!X.Window[1] - !X.Window[0]) / 2. + !X.Window[0] 
   ypos=0.95-(shift/3.)

   XYOuts, x, ypos,'Object'+strcompress(beam)$  ;+TeXtoIDL('   J_{110}=   ')
           +TeXtoIDL('   H_{140}=')+STRING(magh[n], FORMAT='(F5.2)'),/Normal, Alignment=0.5, Charsize=1.25

       if (n eq 1) then begin
          loadct,0
          xyouts,x,0.98,"WISP Survey -- "+field+" 1D spectra -- HA "+systime(),$
                 /Normal, Alignment=0.5, Charsize=1.1,color=50
       endif
  
   loadct,12,/silent
   oplot,G141_wave_rebin,G141_flux_rebin/1e-18,color=200,thick=3,psym=10
   oplot,G141_wave_rebin,G141_contam_rebin/1e-18,thick=2,psym=10   
   ;oploterror,G141_wave_rebin,G141_flux_rebin,G141_ferr_rebin,thick=1,psym=3,/nohat


   ind_con=where(g141_zo eq 1)
   if ind_con[0] ne -1 then begin
     for q=0,n_elements(ind_con)-1  do begin
        oplot,replicate(G141_wave(ind_con[q]),2),[ymax,ymax/2.]/1e-18,thick=4,color=25,linestyle=2  
     endfor 
   endif

   ; 2D STAMPS  & 1D SPECTRA
   ;***********************************************************************************************
  

        IF keyword_set(SAVE) THEN BEGIN          
          
              FORPRINT,G141_wave,G141_FLUX,G141_ferr,G141_contam,G141_zo $
                       ,COMMENT='#     wave      flux            error           contam           zeroth' $
                       ,TEXTOUT=path+'Spectra/'+field+'_G141_'+STP_ID+'.dat',/nocomment,/silent
              WRITEFITS,path+'Stamps/'+field+'_G141_'+STP_ID+'.fits',G141_STAMP
       

           cut=0
           dim2=n_elements(G141_wave_trim)

           wave=G141_wave_trim[cut:dim2-1]
           flux=G141_flux_trim[cut:dim2-1]
           ferr=G141_ferr_trim[cut:dim2-1]
           contam=G141_contam_trim[cut:dim2-1]
           zeroth=g141_zo[cut:dim2-1]

              FORPRINT,wave,flux,ferr,contam,zeroth $
                       ,COMMENT='#     wave      flux            error           contam           zeroth' $
                          ,TEXTOUT=path+'Spectra/'+field+'_'+STP_ID+'.dat',/silent  

       ENDIF

     ENDIF


END


