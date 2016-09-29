;dir=/Users/ydai/WISPIPE/IDL
;Purpose: quickly plot the spectra of selected object
;generated : 2015.06.15
;update: 2016.03.28

pro plotspec,ps=ps
!p.multi= [0,1,3]
if keyword_set(ps) then begin
   set_plot,'ps'
   DEVICE, /Times, /BOLD, FONT_INDEX=20
   psopen,'/Users/ydai/Dropbox/WISPS/pairs/test_spectra.ps',/COLOR,bits_per_pixel=8,/lan;,/encap                      
endif
wha = 6562.80                    ;Halpha -- res-frame  
whb = 4861.33                    ;Hbeta -- res-frame  
woiii1 = 5008.24D                   ;OIII  -- res-frame
woiii2 = 4960.30D
woii = 3727.                      ;OII -- res-frame, center of two lines



a=mrdfits('/Users/ydai/Dropbox/WISPS/pairs/full-linelist-cg-20160322.fits',1)
m = where(a.H_alpha_linesn gt 3 and a.H_beta_linesn gt 3 and a.H_alpha_lineflux/a.h_beta_lineflux gt 0) & help,m
zarray = a[m].redshift
paridarray = a[m].parID
objidarray = a[m].objID
ratio = a[m].h_alpha_lineflux/a[m].h_beta_lineflux
;ratio = a[m].oiii_lineflux/a[m].h_alpha_lineflux

for i = 0,n_elements(paridarray)-1 do begin
   for jj=0,n_elements(paridarray) do begin
      if i eq jj*3 then begin
         !p.multi= [0,1,3]
         erase
         lab=1
      endif
      if i eq jj*3+2 then xt=1
   endfor

   j = sort(ratio)
   ind = j[i]
   r = string(ratio[ind],F='(F6.3)')
   z = zarray[ind]
   parid = strtrim(paridarray[ind],2)
   obj  = strtrim(objidarray[ind],2)
   xt = 0 ;xtitle keyword
   lab = 0 ;label keyword

;if parid ne 326 then goto,eend

   if paridarray[ind] ge 326 or paridarray[ind] eq 183 then   path = '/Volumes/Kudo/DATA/WISPS/aXe/Par'+parid
   if paridarray[ind] lt 326 and paridarray[ind] ne 183 then  begin
      if paridarray[ind] gt 185 then path = '/Volumes/Kudo/DATA/WISPS/aXe/aXe-pre20140421-marcar/Par'+parid
      if paridarray[ind] le 185 then path = '/Volumes/Kudo/DATA/WISPS/aXe/aXe-pre20140421-hakim/ReducedFields/Par'+parid+'_final/'
   endif
   
   readcol,path+'/Spectra/Par'+parid+'_BEAM_'+obj+'A.dat', wn,fn,en,f ='f,d,d'
   ;if obj lt 2000 then
   readcol,path+'/Spectra/Par'+parid+'_G102_BEAM_'+obj+'A.dat', wn1,fn1 ,en1,f ='f,d,d'
   ;if obj lt 1000 or obj gt 2000 then
   readcol,path+'/Spectra/Par'+parid+'_G141_BEAM_'+obj+'A.dat', wn2,fn2 ,en2,f ='f,d,d'

xmin = 8500
xmax = 16500
flux0 = (findgen(6)-2)*(1.e-16)
m = where(wn gt 7500 and wn lt 18500)  ;trim edge  ;8500-16500
multiplot &  plot,wn(m),fn(m),xrange=[xmin,xmax],yrange=[0.9*min(fn[m]), 1.1*max(fn[m])],psym=10, pos=poss1 $
                  , xtickn=[' ',' ',' ',' ',' ',' ']

if lab eq 1 then begin
xyouts,woii*(1.+z)+200, 0.5*max(fn[m]),'[OII]'
xyouts,woiii1*(1.+z)+200,0.5*max(fn[m]),'[OIII]'
xyouts,wha*(1.+z)+200, 0.5*max(fn[m]),'H_alpha'
;xyouts,whb*(1.+z)+200, 0.5*max(fn[m]),'H_beta'
endif 
if xt eq 1 then axis, xaxis=0,xtitle=textoidl('\lambda [\AA]')
if wn1[0] ne 0 then begin
   m = where(wn1 gt 8500 and wn1 lt 11500)  
   oplot, wn1[m],fn1[m], color=fsc_color('blue'),psym=10
endif
if wn2[0] ne 0 then begin
    m = where(wn2 gt 10600 and wn2 lt 16500)  
 oplot, wn2[m],fn2[m], color=fsc_color('red'),psym=10
endif
 

oplot,[woii,woii]*(1.+z), [-0.1,0.1],linestyle=2,color=fsc_color('pink')  ;[max(fn[m]),0.5*max(fn[m])
oplot,[woiii1,woiii1]*(1.+z), [-0.1,0.1],linestyle=2,color=fsc_color('green')
oplot,[woiii2,woiii2]*(1.+z), [-0.1,0.1],linestyle=2,color=fsc_color('green')
oplot,[wha,wha]*(1.+z), [-0.1,0.1],linestyle=2,color=fsc_color('blue')
oplot,[whb,whb]*(1.+z), [-0.1,0.1],linestyle=2,color=fsc_color('green')

zz=string(z,'(D0.3)')
legend,/top,/right,['Par'+parid+'_'+obj,'z ='+strtrim(zz,2), 'Ha/Hb = '+strtrim(r,2)],box=0
;stop
eend:
endfor


if keyword_set(ps) then begin
psclose
set_plot,'x'
!p.multi=0
endif

end
