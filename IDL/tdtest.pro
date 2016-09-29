pro tdtest,ps=ps,output=output
; to test the bigger 2D cutout flux changes

xsizein = 20
ysizein = 24
parid = '324'
if keyword_set(ps) then begin
set_plot,'ps'
DEVICE, /Times, /BOLD, FONT_INDEX=20
psopen,'/Users/ydai/WISPIPE/pipelinetest/2dcutout/2dtest-dflux-par'+parid+'_v4.4_v5.0.ps',/COLOR,bits_per_pixel=8 $
        ,xsize=xsizein,ysize=ysizein,/por;,/encapsulated    
thick=4                
endif

erase
!p.multi=[0,1,3]

;readcol,'/Volumes/Kudo/DATA/WISPS/aXe/Par194-mfwhm6/DATA/DIRECT_GRISM/cat_F140.cat',id,xt,yt,a,b,theta,ra,dec,ad,bd,pa,mag,emag,class,flags,f='i,f,f,f,f,f,f,f,f,f,f,f,f,f,f'
readcol,'/Volumes/Kudo/DATA/WISPS/aXe/Par'+parid+'/linesmatch-v4.3-v5.0-par'+parid+'.txt',ido,idn,f='i,i'
readcol,'/Volumes/Kudo/DATA/WISPS/aXe/Par'+parid+'/DATA/DIRECT_GRISM/cat_F110.cat',id,xt,yt,a,b,theta,ra,dec,ad,bd,pa,mag,emag,class,flags,f='i,f,f,f,f,f,f,f,f,f,f,f,f,f,f'

if keyword_set(output) then begin
openw,lun,'/Users/ydai/WISPIPE/pipelinetest/2dcutout/2dtest_sanitycheck_par'+parid+'_v4.3_v5.0.txt',/get_lun
printf,lun,'#id  median(dif)  median(S/N of difo) median(S/N of difn)  n_pixel(dif)'
endif

for i=0, n_elements(idn)-1 do begin
;par194   if i eq 26 or i eq 64 or i eq 72 or i eq 80 or i eq 96 or i eq 105 then goto, skip
;par94   if i eq 4 or  i eq 5 or i eq 10 or i eq 11 or i eq 13 or i eq 27 or i eq 57  or i eq 61  or i eq 75  or i eq 90   or i eq 105  or i eq 183  or i eq 228  or i eq 230 or i eq 248 or i eq 278 or i eq 334  or i eq 348 or i eq 350 or i eq 356 or i eq 368  or i eq 375  or i eq 379 then goto,skip
;par167
;   if i eq 18 or i eq 62 or i eq 69 or i eq 106 or i eq 126 or i eq 131 or i eq 145 or i eq 153 or i eq 177 or i eq 181 or i eq 231 or i eq 258 or i eq 265 or i eq 269 or i eq 283 or i eq 296 or i eq 297 or i eq 318 or i eq 319 or i eq 320 or i eq 324 or i eq 325 or i eq 333 or i eq 338 or i eq 347 or i eq 359 or i eq 368 or i ge 372 then goto,skip
;par324
   if i eq 10 or i eq 15 or i eq 43 or i eq 59  or i eq 88 or i eq 125 or i eq 129 or i eq 208 or i eq 216 or i eq 261 or i eq 268 or i eq 386  or i eq 387  or i eq 392 or i eq 407 or i eq 415 or i eq 426 or i eq 458 or i eq 464 or i eq 472 or i eq 474 or i eq 481 or i eq 521 then goto,skip
   print,i
;readcol,'/Volumes/Kudo/DATA/WISPS/aXe/Par194-mfwhm9-good/Spectra/Par194-mfwhm9-good_BEAM_'+strtrim(id[i],2)+'A.dat',wv,flux,eflux
;readcol,'/Volumes/Kudo/DATA/WISPS/aXe/Par194-mfwhm3-good/Spectra/Par194-mfwhm3-good_BEAM_'+strtrim(id[i],2)+'A.dat',wvo,fluxo,efluxo
;   if i ne 18 and i ne 20 then goto,skip
   readcol,'/Volumes/Kudo/DATA/WISPS/aXe/Par'+parid+'/Spectra/Par'+parid+'_BEAM_'+strtrim(idn[i],2)+'A.dat',wv,flux,eflux
;   readcol,'/Volumes/Kudo/DATA/WISPS/aXe/Par94-test/Spectra-193494/Par94_BEAM_'+strtrim(id[i],2)+'A.dat',wv,flux,eflux
;   readcol,'/Volumes/Kudo/DATA/WISPS/aXe/aXe-pre20140421-hakim/ReducedFields/Par167_final/Spectra/Par167_BEAM_'+strtrim(ido[i],2)+'A.dat',wvo,fluxo,efluxo
   readcol,'/Volumes/Kudo/DATA/WISPS/aXe/aXe-pre20140421-marcar/Par'+parid+'/Spectra/Par'+parid+'_BEAM_'+strtrim(ido[i],2)+'A.dat',wvo,fluxo,efluxo

;-mfwhm9-good

dif = flux-fluxo
m = where (dif ne 0)

if m[0] ne -1 and keyword_set(output) then begin
printf,lun,id[i],median(dif[m]),median(dif[m]/efluxo[m]),median(dif[m]/eflux[m]),n_elements(m)
endif

   m='a'
   ymax=max(flux)*1.3
   if ymax gt 100 then goto,skip
   plot,[0],[0],xrange=[7200,16500],yrange=[-1e-18,ymax]/1e-18,/xstyle,/ystyle,$
;   plot,[0],[0],xrange=[7200,16500],yrange=[-1e-18,3e-18]/1e-18,/xstyle,/ystyle,$
      ytitle=TeXtoIDL('Flux Diff (10^{-18} ergs s^{-1} cm^{-2} A^{-1})'),xtitle='Wavelength (A)',$
      xmargin=[18,8],ymargin=[10,10],xthick=3,ythick=3,charthick=2,xcharsize=2.1,ycharsize=2.05
;   oplot,wv,flux/1.e-18,color=fsc_color('red')
   oplot,wv,efluxo/1.e-18,color=fsc_color('darkgrey')
   oplot,wv,eflux/1.e-18,color=fsc_color('grey')
;   oplot,wvo,fluxo/1.e-18,color=fsc_color('blue')
   oplot,wvo,dif/1.e-18,color=fsc_color('green')
   
   legend,/top,/right,box=0,['Object (o,n)'+strcompress(ido[i])+','+strcompress(idn[i])$
           +TeXtoIDL('   H_{140}=')+STRING(mag[i], FORMAT='(F5.2)'),'Dark Grey:flux error(o)','Light Grey:flux error(n)','Green: flux diff'];, 'Red: V5.0','Blue: V4.3','Grey: flux error','Red:flux difference'] ;
;if not keyword_set(ps) then read,m   
skip:
endfor

if keyword_set(output) then begin
close,lun
free_lun,lun
endif

eend:
if keyword_set(ps) then begin
psclose
set_plot,'x'
!p.multi=0
endif
end
