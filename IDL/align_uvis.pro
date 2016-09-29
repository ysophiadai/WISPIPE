;##############################################################
;# WISPIPE
;# Reduction Pipeline for the WISP program (Atek et al. 2010)
;# Hakim Atek 2009
;# Purpose: generate catalog list using SEx for the UVIS bands
;# 
;# Input: 
;#         F600LP_sci.fits; F600LP_rot_sci.fits
;# Output:
;#         F600.cat; 
;# 
;# updated by Sophia Dai, 2014
;###############################################################
pro align_uvis,field,path0, pathc

path= path0+'/aXe/'+field+'/'
droppath= pathc+'/aXe/' ; for copying files

spawn,'cp '+path+'DATA/UVIS/F*.fits '+path+'SEX/'
spawn,'cp '+path+'DATA/DIRECT_GRISM/F*.fits '+path+'SEX/'
spawn,'cp '+droppath+'in.cat '+path+'DATA/UVIS/'
spawn,'cp '+droppath+'in_rot.cat '+path+'DATA/UVIS/'
spawn,'cp '+droppath+'in_single.cat '+path+'DATA/UVIS/'
spawn,'cp '+droppath+'in_rot_single.cat '+path+'DATA/UVIS/'
spawn,'cp '+droppath+'input.list '+path+'DATA/UVIS/'
spawn,'cp '+droppath+'input_rot.list '+path+'DATA/UVIS/'
;spawn,'cp /Users/atek/Caltech/aXe/align_uvis.py '+path+'DATA/UVIS/'


;F600LP
h1=headfits(path+'SEX/F600LP_drz.fits') 
exptime0=strcompress(sxpar(h1,'EXPTIME'),/remove_all)
spawn,'sex '+path+'SEX/F600LP_sci.fits -c '+path+'SEX/uvis.sex -catalog_name '+path+'SEX/F600.cat -parameters_name '+path+'SEX/config.param -mag_zeropoint 25.87 -WEIGHT_TYPE MAP_WEIGHT -weight_image '+path+'SEX/F600LP_wht.fits -GAIN '+exptime0+' -STARNNW_NAME '+path+'SEX/default.nnw'
;spawn,'sex '+path+'SEX/F600LP_sci.fits -c '+path+'SEX/uvis.sex -catalog_name '+path+'SEX/F600.cat -parameters_name '+path+'SEX/config.param -mag_zeropoint 25.87 -WEIGHT_TYPE MAP_WEIGHT,map_RMS -weight_image '+path+'SEX/F600LP_wht.fits,'+path+'SEX/F600LP_rms.fits -GAIN '+exptime0+' -STARNNW_NAME '+path+'SEX/default.nnw'
; The above way of using wht map + rms map generates more
; objects. Since we only care the brightest ones for matching,
; it doesn't matter much.
;spawn,'sex '+path+'SEX/F600LP_rot_sci.fits -c '+path+'SEX/uvis.sex -catalog_name '+path+'SEX/F600_rot.cat -parameters_name '+path+'SEX/config.param -mag_zeropoint 25.87 -WEIGHT_TYPE MAP_WEIGHT -weight_image '+path+'SEX/F600LP_rot_wht.fits -GAIN '+exptime0+' -STARNNW_NAME '+path+'SEX/default.nnw'


;;F110W
;h1=headfits(path+'SEX/F110W_drz.fits') 
;exptime1=strcompress(sxpar(h1,'EXPTIME'),/remove_all)
;spawn,'sex '+path+'SEX/F110W_sci.fits -c '+path+'SEX/config.sex -catalog_name '+path+'SEX/F110.cat -mag_zeropoint 26.83 -WEIGHT_TYPE MAP_WEIGHT -weight_image '+path+'SEX/F110W_wht.fits -parameters_name '+path+'SEX/config.param -filter Y -filter_name '+path+'SEX/gauss_2.0_5x5.conv -detect_minarea 6 -detect_thresh 3.5 -ANALYSIS_THRESH 2 -CHECKIMAGE_NAME '+path+'SEX/F110_seg.fits -DEBLEND_NTHRESH 64 -DEBLEND_MINCONT 0.005 -GAIN '+exptime1+' -STARNNW_NAME '+path+'SEX/default.nnw'

;F160W
;h2=headfits(path+'SEX/F160W_drz.fits') 
;exptime2=strcompress(sxpar(h2,'EXPTIME'),/remove_all)
;spawn,'sex '+path+'SEX/F160W_sci.fits -c '+path+'SEX/config.sex -catalog_name '+path+'SEX/F160.cat -mag_zeropoint 25.96 -WEIGHT_TYPE MAP_WEIGHT -weight_image '+path+'SEX/F160W_wht.fits -parameters_name '+path+'SEX/config.param -filter Y -filter_name '+path+'SEX/gauss_2.0_5x5.conv -detect_minarea 6 -detect_thresh 1.5 -ANALYSIS_THRESH 2 -CHECKIMAGE_NAME '+path+'SEX/F160_seg.fits -DEBLEND_NTHRESH 16 -DEBLEND_MINCONT 0.005 -GAIN '+exptime2+' -STARNNW_NAME '+path+'SEX/default.nnw'
;spawn,'sex '+path+'SEX/F160W_rot_sci.fits -c '+path+'SEX/config.sex -catalog_name '+path+'SEX/F160_rot.cat -mag_zeropoint 25.96 -WEIGHT_TYPE MAP_WEIGHT -weight_image '+path+'SEX/F160W_rot_wht.fits -parameters_name '+path+'SEX/config.param -filter Y -filter_name '+path+'SEX/gauss_2.0_5x5.conv -detect_minarea 6 -detect_thresh 1.5 -ANALYSIS_THRESH 2 -CHECKIMAGE_NAME '+path+'SEX/F160_seg.fits -DEBLEND_NTHRESH 16 -DEBLEND_MINCONT 0.005 -GAIN '+exptime2+' -STARNNW_NAME '+path+'SEX/default.nnw'


 ;;      readcol,path+'SEX/F160.cat',ra1,dec1,format=('x,x,x,x,x,x,d,d'),/silent 
;;       readcol,path+'SEX/F600.cat',id2,x2,y2,ra2,dec2,format=('I,d,d,x,x,x,d,d'),/silent
      
;;      ;mk_regionfile,ra1,dec1,5,file=path+'aegis.reg',color='green'

;;       srcor,ra1*24./360.,dec1,ra2*24./360.,dec2,2,ind1,ind2,option=1,spherical=1

;;      ;mk_regionfile,ra2(ind2),dec2(ind2),5,file=path+field+'.reg'

;;       forprint,x2(ind2),y2(ind2),ra1(ind1),dec1(ind1),textout=path+'DATA/UVIS/im_to_ref.coo',format=('d,d,d,d'),/nocomment



end
