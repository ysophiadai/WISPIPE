pro setest,ps=ps

goto, plots
  
;F140W
;==== pre SE preparation ===
;iraf.imcopy(input="F110W_nosky_drz.fits[1]", output="F110W_nosky_sci.fits")
;iraf.imcopy(input="F110W_nosky_drz.fits[2]", output="F110W_nosky_wht.fits")
;iraf.imcalc(input="F110W_nosky_wht.fits", output="F110W_nosky_rms.fits", equals="1/sqrt(im1)")



;==== SE test F110W ===
;h1=headfits(path+'SEX/F110W_drz.fits') 
;exptime1=strcompress(sxpar(h1,'EXPTIME'),/remove_all)
;spawn,'sex '+path+'SEX/F110W_sci.fits -c '+path+'SEX/config.sex -catalog_name '+path+'SEX/F110.cat -mag_zeropoint 26.83 -WEIGHT_TYPE MAP_WEIGHT -weight_image '+path+'SEX/F110W_wht.fits -parameters_name '+path+'SEX/config.param -filter Y -filter_name '+path+'SEX/gauss_2.0_5x5.conv -detect_minarea 6 -detect_thresh 3.5 -ANALYSIS_THRESH 2 -CHECKIMAGE_NAME '+path+'SEX/F110_seg.fits -DEBLEND_NTHRESH 64 -DEBLEND_MINCONT 0.005 -GAIN '+exptime1+' -STARNNW_NAME '+path+'SEX/default.nnw'
;F110W
h1=headfits(path+'SEX/F110W_drz.fits') 
exptime1=strcompress(sxpar(h1,'EXPTIME'),/remove_all)
spawn,'sex '+path+'SEX/F110W_sci.fits -c '+path+'SEX/config.sex -catalog_name '+path+$
'SEX/F110.cat -mag_zeropoint 26.83 -WEIGHT_TYPE MAP_WEIGHT -weight_image '+path+'SEX/F110W_wht.fits -parameters_name '+path+$
'SEX/config.param -filter Y -filter_name '+path+'SEX/gauss_2.0_5x5.conv -detect_minarea 6 -detect_thresh 3 -ANALYSIS_THRESH 2 -CHECKIMAGE_NAME '$
+path+'SEX/F110_seg.fits -DEBLEND_NTHRESH 64 -DEBLEND_MINCONT 0.005 -GAIN '+exptime1+' -STARNNW_NAME '+path+'SEX/default.nnw'

colors =['red','green','magenta','cyan','brown','yellow']
fid='Par288'
h1=headfits('./'+fid+'/F110W_pixscale0.08_0.7_sci.fits') 
exptime1=strcompress(sxpar(h1,'EXPTIME'),/remove_all)
if exptime1 gt 1041 then det='1.9'
if exptime1 le 1041 then det='2.3'
spawn,'sex ./'+fid+'/F110W_pixscale0.08_0.7_sci.fits -c ./config.sex -catalog_name ./'+fid+'/F110W_pixscale0.08_0.7_'+det+'.cat -mag_zeropoint 26.83 -WEIGHT_TYPE MAP_WEIGHT,MAP_RMS -weight_image ./'+fid+'/F110W_pixscale0.08_0.7_wht.fits,./'+fid+'/F110W_pixscale0.08_0.7_rms.fits -parameters_name ./config.param -filter Y -filter_name ./gauss_2.0_5x5.conv -detect_minarea 6 -detect_thresh '+det+' -ANALYSIS_THRESH 2 -DEBLEND_NTHRESH 64 -DEBLEND_MINCONT 0.005 -GAIN '+exptime1+' -STARNNW_NAME ./default.nnw -CHECKIMAGE_TYPE segmentation -CHECKIMAGE_NAME ./'+fid+'/F110W_pixscale0.08_0.7_'+det+'_seg.fits '

; test for drz_bck
fid='Par288'
h1=headfits('./'+fid+'/F110W_nosky_drz.fits') 
exptime1=strcompress(sxpar(h1,'EXPTIME'),/remove_all)
det='1.5'
spawn,'sex ./'+fid+'/F110W_pixscale0.08_sci.fits -c ./config.sex -catalog_name ./'+fid+'/F110W_pixscale0.08_'+det+'.cat -mag_zeropoint 26.83 -WEIGHT_TYPE NONE -parameters_name ./config.param -filter Y -filter_name ./gauss_2.0_5x5.conv -detect_minarea 6 -detect_thresh '+det+' -ANALYSIS_THRESH 2 -DEBLEND_NTHRESH 64 -DEBLEND_MINCONT 0.005 -GAIN '+exptime1+' -STARNNW_NAME ./default.nnw -CHECKIMAGE_TYPE segmentation -CHECKIMAGE_NAME ./'+fid+'/F110W_pixscale0.08_'+det+'_seg.fits '

readcol,'./'+fid+'/F110W_'+det+'.cat',id,xt,yt,a,b,theta,ra,dec,ad,bd,pa,mag,emag,class,flags
mk_regionfile,ra,dec,5,label=string(fix(id)),file='./'+fid+'/F110W_'+det+'.reg',color=colors[0]
m = where (flags ge 4)
help,m
mk_regionfile_elip,xt,yt,2.*a,2.*b,theta,label=string(fix(id)),file='./'+fid+'/F110W_elip.reg',/image,color='cyan'

;==== SE test F140W ===
h2=headfits('./Par56/Par56_F140W_drz.fits') 
exptime2=strcompress(sxpar(h2,'EXPTIME'),/remove_all)
spawn,'sex ./Par56/F140W_sci.fits -c ./config.sex -catalog_name ./Par56/F140.cat -mag_zeropoint 26.46 -WEIGHT_TYPE MAP_WEIGHT -weight_image Par56/F140W_wht.fits -parameters_name ./config.param -filter Y -filter_name ./gauss_2.0_5x5.conv -detect_minarea 6 -detect_thresh 1.5 -ANALYSIS_THRESH 2 -DEBLEND_NTHRESH 64 -DEBLEND_MINCONT 0.05 -GAIN '+exptime2+' -STARNNW_NAME ./default.nnw -CHECKIMAGE_TYPE -objects -CHECKIMAGE_NAME ./Par56/F140_-obj.fits'

;h2=headfits('./Par194/Par194_F140W_drz.fits') 
;exptime2=strcompress(sxpar(h2,'EXPTIME'),/remove_all)
;spawn,'sex ./Par194/F140W_sci.fits -c ./config.sex -catalog_name ./Par194/deblending-test/F140_1.5.64.0.005.cat -mag_zeropoint 26.46 -WEIGHT_TYPE MAP_WEIGHT -weight_image Par194/F140W_wht.fits -parameters_name ./config.param -filter Y -filter_name ./gauss_2.0_5x5.conv -detect_minarea 6 -detect_thresh 1.5 -ANALYSIS_THRESH 2 -DEBLEND_NTHRESH 64 -DEBLEND_MINCONT 0.005 -GAIN '+exptime2+' -STARNNW_NAME ./default.nnw -CHECKIMAGE_TYPE -objects -CHECKIMAGE_NAME ./Par194/deblending-test/F140_1.5.64.0.005-obj.fits'
;readcol,'./Par56/F140_negtest-2.0-1.5.cat',id,xt,yt,a,b,theta,ra,dec,ad,bd,pa,mag,emag,class,flags
;mk_regionfile,ra,dec,5,label=string(fix(id)),file='./Par56/F140_neg-2.0-1.5.reg',color='yellow'
;mk_regionfile_elip,xt,yt,a,b,theta,label=string(fix(id)),file='./Par194/blendtest_elip.reg',/image,color='yellow'

colors =['red','green','magenta','cyan','brown','yellow']
fid='Par194'
h1=headfits('./'+fid+'/F140W_drz.fits') 
exptime1=strcompress(sxpar(h1,'EXPTIME'),/remove_all)

det='1.8'
spawn,'sex ./'+fid+'/F140W_sci.fits -c ./config.sex -catalog_name ./'+fid+'/whtrms/F140_'+det+'_cb.cat -mag_zeropoint 26.46 -WEIGHT_TYPE MAP_WEIGHT,MAP_RMS -weight_image ./'+fid+'/F140W_wht.fits,./'+fid+'/F140W_rms.fits -parameters_name ./config.param -filter Y -filter_name ./gauss_2.0_5x5.conv -detect_minarea 6 -detect_thresh '+det+' -ANALYSIS_THRESH 2 -DEBLEND_NTHRESH 64 -DEBLEND_MINCONT 0.005 -GAIN '+exptime1+' -STARNNW_NAME ./default.nnw -CHECKIMAGE_TYPE -objects -CHECKIMAGE_NAME ./'+fid+'/whtrms/F140_'+det+'_cb-obj.fits '

readcol,'./'+fid+'/whtrms/F140_'+det+'_cb.cat',id,xt,yt,a,b,theta,ra,dec,ad,bd,pa,mag,emag,class,flags
mk_regionfile,ra,dec,5,label=string(fix(id)),file='./'+fid+'/whtrms/F140_'+det+'_cb.reg',color=colors[0]
m = where (flags ge 4)
help,m



;test for fits output
;-CATALOG_TYPE Fits_1.0
spawn,'sex ./'+fid+'/F140W_sci.fits -c ./config.sex -catalog_name ./'+fid+'/F140_'+det+'_test.cat  -mag_zeropoint 26.46 -WEIGHT_TYPE MAP_RMS -weight_image ./'+fid+'/F140W_rms.fits -parameters_name ./configfull.param -filter Y -filter_name ./gauss_2.0_5x5.conv -detect_minarea 6 -detect_thresh '+det+' -ANALYSIS_THRESH 2 -DEBLEND_NTHRESH 64 -DEBLEND_MINCONT 0.005 -GAIN '+exptime1+' -STARNNW_NAME ./default.nnw -CHECKIMAGE_TYPE -objects -CHECKIMAGE_NAME ./'+fid+'/F140_'+det+'-obj.fits '



;==== SE test F160W ===
;spawn,'sex '+path+'SEX/F160W_sci.fits -c '+path+'SEX/config.sex -catalog_name '+path+'SEX/F160.cat -mag_zeropoint 25.96 -WEIGHT_TYPE MAP_WEIGHT -weight_image '+path+'SEX/F160W_wht.fits -parameters_name '+path+'SEX/config.param -filter Y -filter_name '+path+'SEX/gauss_2.0_5x5.conv -detect_minarea 6 -detect_thresh 1.5 -ANALYSIS_THRESH 2 -CHECKIMAGE_NAME '+path+'SEX/F160_seg.fits -DEBLEND_NTHRESH 16 -DEBLEND_MINCONT 0.005 -GAIN '+exptime2+' -STARNNW_NAME '+path+'SEX/default.nnw'

colors =['red','green','magenta','cyan','brown','yellow']
fid='Par167'
h2=headfits('./'+fid+'/F160W_drz.fits') 
exptime2=strcompress(sxpar(h2,'EXPTIME'),/remove_all)

if exptime2 gt 1014 then det='2.3'
if exptime2 le 1014 then det='2.3'
spawn,'sex ./'+fid+'/F160W_sci.fits -c ./config.sex -catalog_name ./'+fid+'/F160_'+det+'.cat -mag_zeropoint 25.96  -WEIGHT_TYPE MAP_WEIGHT,MAP_RMS -weight_image ./'+fid+'/F160W_wht.fits,./'+fid+'/F160W_rms.fits -parameters_name ./config.param -filter Y -filter_name ./gauss_2.0_5x5.conv -detect_minarea 6 -detect_thresh '+det+' -ANALYSIS_THRESH 2 -DEBLEND_NTHRESH 64 -DEBLEND_MINCONT 0.005 -GAIN '+exptime2+' -STARNNW_NAME ./default.nnw -CHECKIMAGE_TYPE SEGMENTATION -CHECKIMAGE_NAME ./'+fid+'/F160_'+det+'_seg.fits '
readcol,'./'+fid+'/F160_'+det+'.cat',id,xt,yt,a,b,theta,ra,dec,ad,bd,pa,mag,emag,class,flags
mk_regionfile,ra,dec,5,label=string(fix(id)),file='./'+fid+'/F160_'+det+'.reg',color=colors[3]
m = where (flags ge 4)
help,m


plots:
xsizein = 20
ysizein = 18

if keyword_set(ps) then begin
set_plot,'ps'
DEVICE, /Times, /BOLD, FONT_INDEX=20
psopen,'/Users/ydai/Desktop/drztest/drz-test-updated.ps',/COLOR,bits_per_pixel=8 $
        ,xsize=xsizein,ysize=ysizein,/por,/encapsulated    
thick=4                
endif

goto,sntest
a = mrdfits('/Users/ydai/Desktop/SEtest/Par288/F110_med.fits')
b = mrdfits('/Users/ydai/Desktop/SEtest/Par288/F110W_sci.fits')

histoplot,a,/freq,binsize=0.02,xrange=[-1,2],yrange=[0,0.2],xtitle='pixle value'
histoplot,b,/freq,binsize=0.02,xrange=[-1,2],yrange=[0,.2],/oplot

xyouts, -.5, .15, 'drizzled'
xyouts, 1.0,.10, 'combined'

goto,eend

;goto,nosntest
sntest:
erase
!p.multi=[0,1,2]
readcol,'/Users/ydai/Desktop/SEtest/Par288/F110W_1.5.cat',id,xt,yt,a,b,theta,ra,dec,ad,bd,pa,mag,emag,flux,eflux,class,flags
multiplot & plot,mag,flux/eflux/1.5,psym=2,xrange=[29,22],yrange=[0,30],ytitle='S/N',ytickname=[' ','10','20','30'],xstyle=1

readcol,'/Users/ydai/Desktop/SEtest/Par288/F110_1.5.cat',id,xt,yt,a,b,theta,ra,dec,ad,bd,pa,mag2,emag2,flux2,eflux2,class,flags
oplot,mag2,flux2/eflux2,psym=4,color=fsc_color('red')

sn = flux/eflux/1.5
m=where(sn ge 4.9 and sn lt 5.1)
print,median(mag[m]),stdev(mag[m])
sn2 = flux2/eflux2
m=where(sn2 ge 4.9 and sn2 lt 5.1)
print,median(mag2[m]),stdev(mag2[m])

legend,textoidl(['Par288 (1015s)','5 \sigma median \pm stdev:','25.86 \pm 0.40 (drz)','25.74 \pm 0.53 (combined)']),/top,/left,box=0

readcol,'/Users/ydai/Desktop/SEtest/Par339a/whtrms/F110W_1.5_cb.cat',id,xt,yt,a,b,theta,ra,dec,ad,bd,pa,mag,emag,flux,eflux,class,flags
multiplot & plot,mag,flux/eflux/1.5,psym=2,xrange=[29,22],yrange=[0,30],xtitle='mag',ytitle='S/N',ytickname=[' ','10','20','30'],xstyle=1

readcol,'/Users/ydai/Desktop/SEtest/Par339a/F110_1.5.cat',id,xt,yt,a,b,theta,ra,dec,ad,bd,pa,mag2,emag2,flux2,eflux2,class,flags
oplot,mag2,flux2/eflux2,psym=4,color=fsc_color('red')

sn = flux/eflux/1.5
m=where(sn ge 4.9 and sn lt 5.1)
print,median(mag[m]),stdev(mag[m])
sn2 = flux2/eflux2
m=where(sn2 ge 4.9 and sn2 lt 5.1)
print,median(mag2[m]),stdev(mag2[m])

legend,textoidl(['Par339a (8894s)', '5 \sigma median \pm stdev:','27.58 \pm 0.39 (drz)','27.30 \pm 0.36 (combined)']),/top,/left,box=0
;legend,textoidl(['Par339a (8894s)', '10 \sigma median \pm stdev:','26.93 \pm 0.36 (drz)','26.25 \pm 0.41 (combined)']),/top,/left,box=0

goto,eend
nosntest:


erase
colors =['red','red','green','green','blue','blue']
readcol,'results.txt',F='a,a,i,f,i',parid,filter,texp,sn,ntotal

rate = ntotal

y = indgen(10)*200
x = fltarr(10)
x110 = x + 2.3
x140 = x + 2.0
x160 = x + 2.4

pos1=[0.1,0.10,0.95,0.40]
pos2=[0.1,0.40,0.95,0.70]
pos3=[0.1,0.70,0.95,0.99]
!p.multi=[1,3,0]

plotsym,0,1.0,/fill

multiplot & plot,x160,y,linestyle=2,xrange=[0.9,4.1],yrange=[0,800],xstyle=1,ystyle=1,yticks=4, ytickname=[' ', '200','400','600',' '],xtitle=textoidl('detect-thresh( \sigma)'), pos=pos1
m = where (parid eq 'Par167' and filter eq 'F160W')
oplot,sn(m),rate(m),psym=8,color=fsc_color(colors[4])
oplot,sn(m),rate(m),color=fsc_color(colors[4]),linestyle=1

m = where (parid eq 'Par314' and filter eq 'F160W')
oplot,sn(m),rate(m),psym=8,color=fsc_color(colors[5])
oplot,sn(m),rate(m),color=fsc_color(colors[5])
legend,['Par167-F160W, median (356s)','Par314-F160W, deep (1543s)'],/top,/left,box=0
oplot,[2.2, 2.4], [232, 456], psym=6,symsize=2, color=fsc_color(colors[5])


multiplot & plot,x140,y,linestyle=2,xrange=[0.9,4.1],yrange=[0,900],xstyle=1,ystyle=1,xticks=1, xtickname=[' ',' '],yticks=3, ytickname=[' ', '300', '600', ' '],pos=pos2,ytitle='# of total obj'
m = where (parid eq 'Par194' and filter eq 'F140W')
oplot,sn(m),rate(m),psym=8,color=fsc_color(colors[0])
oplot,sn(m),rate(m),color=fsc_color(colors[0]),linestyle=1

m = where (parid eq 'Par107' and filter eq 'F140W')
oplot,sn(m),rate(m),psym=8,color=fsc_color(colors[1])
oplot,sn(m),rate(m),color=fsc_color(colors[1]), linestyle=2

m = where (parid eq 'Par56' and filter eq 'F140W')
oplot,sn(m),rate(m),psym=8,color=fsc_color(colors[1])
oplot,sn(m),rate(m),color=fsc_color(colors[1])
legend,['Par194-F140W, shallow (128s)','Par56-F140W,  median (684s)', 'Par107-F140W, median (734s)'],/top,/left,box=0
oplot,[1.9,2,2], [224, 486, 385], psym=6,symsize=2, color=fsc_color(colors[1])

multiplot & plot,x110,y,linestyle=2,xrange=[0.9,4.1],yrange=[0,1500],xstyle=1,ystyle=1,xticks=1, xtickname=[' ',' '] , ytickname=[' ','500','1000','1500'], yticks=3, pos=pos3
oplot,x110-0.4,y,linestyle=2
m = where (parid eq 'Par167' and filter eq 'F110W')
oplot,sn(m),rate(m),psym=8,color=fsc_color(colors[2])
oplot,sn(m),rate(m),color=fsc_color(colors[2]),linestyle=1


m = where (parid eq 'Par314' and filter eq 'F110W')
oplot,sn(m),rate(m),psym=8,color=fsc_color(colors[3])
oplot,sn(m),rate(m),color=fsc_color(colors[3])
legend,['Par167-F110W, median (659s)','Par314-F110W, deep (2902s)'],/top,/left,box=0
oplot,[1.9,2.3], [702,396], psym=6,symsize=2, color=fsc_color(colors[3])

eend:
if keyword_set(ps) then begin
psclose
set_plot,'x'
!p.multi=0
endif
end
