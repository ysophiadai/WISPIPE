pro smooth_and_combine3,field, path0

; IDL program for wisp pipeline
; Ivano baronchelli July 2016
;
; This IDL program writes a python program with the same name that
; combines the images taken in the J and H bands (sci, rms and
; wht). The combined images can be used after to extract the sources
; in dual image mode, to an higher depth, in both the J and H bands.
;
; NOTE : 
; A) The presence of the F140 image instead of the F160 is
;   automatically recognized and if a F140 image is present, it is the
;   one that is used as H-image. 
; B) along with the sci images, rms and wht images are combined too
; (using different techniques, scale and weigths)

; OPERATIONS (mostly performed by the successive run of the python
;             program). Note that they are not written in the same
;             order inside the code.

; 1) SMOOTHING
; The images in H and J bands have two different FWHM. In order to
; combine them, the image with smaller FWHM (J) needs to be smoothed to
; the FWHM of the one with wider FWHM. An intermediate J sci, rms and
; wht image is created to this pourpose:
; - F110W_sci_smooth.fits (no scale applied)
; - F110W_rms_smooth.fits (no scale applied) and
; - F110W_wht_scaled_smoothed.fits) (scale applied)
; the scale for the wht image is not the same as the one applied to
; the sci and rms images (see below).

;
; 2) WEIGHTING
; The images in H and J bands are not equally deep and a weight is
; needed before combine sci, rms or weight images. This weight can be
; computed in two different ways:
; - method 1: the S/N ratios of the sources in the J and H catalogs
; extracted from the NOT-tweakreged J and H images can be
; compared. The weight used is 1.0 for J and [(S/N)_H/(S/N)_J]^2 for
; H.
; - method2: the S/N ratios are computed directly from the median
;   values of sci/rms images (considering only pixels above 5
;   sigma)
; We average the results of the first method based on sources and
; second method, based on pixels;
;
; 3) SCALING 
; The images in H and J bands are not equally scaled. We scale the
; H image to the J reference before combining the two. To compute the
; scaling factor, we multiply the scale based on the mag-zeropoint
; difference for the flux ratio FJ/FH measured from single image
; extractions in J and H (on not-tweakreged images). The scaling will
; make the H image looking like a J -smoothed image.

; NOTE: 
; - sci images --> combine = average the images, scales the H image
;                  to the J value and weights as a function of the
;                  relative (S/N)^2 computed as described above. 
; - rms images --> quadratic sum of sigma rms images:
;                  sqrt (sum {(wt * sigma)^2}) / sum {wt}
;                  The rms images are previously scaled using the same
;                  scaling factors used for the sci images. The
;                  weights used are the same used for the sci images
; - wht images --> scaled to the final J-equivalent exposure time
;                  (this means a different scaling factor than those
;                  used for the sci and rms images). The weights
;                  used, instead, are the same as for the sci and rms
;                  images   
;    
;
; The final J+H combined (and deeper) image should present technical
; characteristics similar to the J image in input (same mag_zeropoint,
; pixel scale, wcs and pixel position ecc).  The only technical
; difference is the FWHM of the sources that should be that of the H
; image (very close to the J FWHM, anyway). The final image looks like
; a J image taken with a longer exposure time. The final sci, rms and
; wht images are saved in:
; - '/DATA/DIRECT_GRISM/JH_combined_sci.fits'
; - '/DATA/DIRECT_GRISM/JH_combined_rms.fits'
; - '/DATA/DIRECT_GRISM/JH_combined_wht.fits'

; The following files contains the name of the combined images and the
; weigths used to make the final combined images: 
; - '/DATA/DIRECT_GRISM/combine_sci_images.dat
; - '/DATA/DIRECT_GRISM/combine_rms_images.dat
; - '/DATA/DIRECT_GRISM/combine_wht_images.dat
; - '/DATA/DIRECT_GRISMcombine_weights.dat

; Summary of what this program does:
; write a python code that calls the iraf tasks:
; - gauss --> to smooth the J sci, rms and wht image to the same PSF of the H image
; - imcombine --> to sum the two images getting a deeper image (rms
;   and wht are combined in the appropriate way
;
; Versions history
; 
; Version 3
; The case in which a J image is not present is considered. In this
; case, images are neither smoothed, nor combined. Catalogs will be
; extracted from the H image alone. This situation is automatically identified
;
;
; Version 2
; In this version we compute some operations on the J and H images
; using IDL instead of iraf. Iraf doesn't properly scale the
; images even specifying the values needed. Iraf normalize to the
; scale value of the first image these values and then scales the
; images for those normalized values. The scale of the first image is
; taken equal to one.
; Another bad thing that iraf does is:
; - weights considering the weight values that we compute and
;   specified in the weight file (and this is ok)
; - considers also the parameter 'ncombine' in the header of the
;   images. This parameter says how many exposure were combined to
;   make that image. But if the images are taken in different filters,
;   as in our case, this wheight shouldn't be considered as it is.
; to correct for the second point, the keyword ncombine in the header
; is set to 'none', so that ncombine doesn't have any influence
; in the weighting process.

; Last edit:
; Ivano Baronchelli July 2016
;ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ

print, " "
print, "----------------------------"
print, "   smooth_and_combine.pro   "
print, "----------------------------"
print, " "

TS='0' ; normal run
;TS='1' ; Test phase


MAG_ZEROPOINT_110=26.83
MAG_ZEROPOINT_140=26.46
MAG_ZEROPOINT_160=25.96


; NORMAL RUN
if TS eq '0' then begin
path=expand_path(path0+'/aXe/'+field+'/DATA/DIRECT_GRISM/')+'/'
; catalogs
cat_110n=expand_path(path0+'/aXe/'+field+'/DATA/DIRECT/'+'F110.cat')
cat_140n=expand_path(path0+'/aXe/'+field+'/DATA/DIRECT/'+'F140.cat')
cat_160n=expand_path(path0+'/aXe/'+field+'/DATA/DIRECT/'+'F160.cat')
endif

; TEST
if TS eq '1' then begin
;path0='../images/'
path='../images/'
; catalogs
cat_110n='../catalogs/'+'F110.cat'
cat_140n='../catalogs/'+'F140.cat'
cat_160n='../catalogs/'+'F160.cat'
endif


;images to be combined (140-or-160)
img_110n=path+'F110W_sci.fits'
img_140n=path+'F140W_sci.fits'
img_160n=path+'F160W_sci.fits'
; rms images to be combined:
img_110n_rms=path+'F110W_rms.fits'
img_140n_rms=path+'F140W_rms.fits'
img_160n_rms=path+'F160W_rms.fits'
; Weight images to be combined:
img_110n_wht=path+'F110W_wht.fits'
img_140n_wht=path+'F140W_wht.fits'
img_160n_wht=path+'F160W_wht.fits'


; output H sci images scaled to J 
img_140n_sci_scaled=path+'F140W_sci_scaled.fits'
img_160n_sci_scaled=path+'F160W_sci_scaled.fits'
; output H rms images scaled to J 
img_140n_rms_scaled=path+'F140W_rms_scaled.fits'
img_160n_rms_scaled=path+'F160W_rms_scaled.fits'
; output J & H wht images scaled 
img_110n_wht_scaled=path+'F110W_wht_scaled.fits'
img_140n_wht_scaled=path+'F140W_wht_scaled.fits'
img_160n_wht_scaled=path+'F160W_wht_scaled.fits'

Python_out_code1=path+'smooth_and_combine.py'
; Files for imcombine task
File_sci_images= path+'combine_sci_images.dat' ; J and H sci images combined
File_wht_images= path+'combine_wht_images.dat' ; J and H wht images combined
File_rms_images= path+'combine_rms_images.dat' ; J and H rms images combined
File_sci_scales= path+'combine_sci_scales.dat' ; J and H scales used for sci
;File_rms_scales= path+'combine_rms_scales.dat' ; J and H scales used for rms
File_wht_scales= path+'combine_wht_scales.dat' ; J and H scales used for wht
File_weights=   path+'combine_weights.dat'   ; J and H weights used for sci, rms, wht

; Name of output combined images
combined_image_sci_name=    path+'JH_combined_sci.fits'
combined_image_rms_name=path+'JH_combined_rms.fits'
combined_image_wht_name=path+'JH_combined_wht.fits'
image_rms_out=          path+'JH_rms_out_imcombine.fits' ; Output of imcombine



;LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL
; J IMAGE NAMES AND zeropoint mag.
image_sci_Jn=img_110n
image_wht_Jn=img_110n_wht
cat_Jn=cat_110n
image_rms_Jn=img_110n_rms
image_wht_scaled_Jn=img_110n_wht_scaled
ZPM_J=MAG_ZEROPOINT_110

;LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL
; H IMAGE NAMES AND zeropoint mag.
switch_160_140=FILE_TEST(img_140n)
IF switch_160_140 eq 0 then begin
 image_sci_Hn=img_160n
 image_wht_Hn=img_160n_wht
 cat_Hn=cat_160n
 image_rms_Hn=img_160n_rms
 image_sci_scaled_Hn=img_160n_sci_scaled
 image_rms_scaled_Hn=img_160n_rms_scaled
 image_wht_scaled_Hn=img_160n_wht_scaled
 ZPM_H=MAG_ZEROPOINT_160
ENDIF
IF switch_160_140 eq 1 then begin
 image_sci_Hn=img_140n
 image_wht_Hn=img_140n_wht
 cat_Hn=cat_140n
 image_rms_Hn=img_140n_rms
 image_sci_scaled_Hn=img_140n_sci_scaled
 image_rms_scaled_Hn=img_140n_rms_scaled
 image_wht_scaled_Hn=img_140n_wht_scaled
 ZPM_H=MAG_ZEROPOINT_140
ENDIF
;LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL


; ***************************************************
; CHECK J IMAGE EXISTENCE. 
; ***************************************************
; IF J IS NOT COVERED, IMAGES WILL NOT BE SMOOTHED AND THE PIPELINE
; PROCEEDS USING THE H FILTER ALONE
ISTHEREJ=FILE_TEST(img_110n)
; ***************************************************


IF ISTHEREJ gt 0 THEN BEGIN
print, " "
print, "J and H images will be smoothed, scaled and combined"
print, " "

; READ IMAGES:
; WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW
; reading sci images
 sci_J=mrdfits(image_sci_Jn,0,hd_sci_J)
 sci_H=mrdfits(image_sci_Hn,0,hd_sci_H)
; reading rms images
 rms_J=mrdfits(image_rms_Jn,0,hd_rms_J)
 rms_H=mrdfits(image_rms_Hn,0,hd_rms_H)
; reading wht images
 wht_J=mrdfits(image_wht_Jn,0,hd_wht_J)
 wht_H=mrdfits(image_wht_Hn,0,hd_wht_H)
; WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW


; HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
;  MATCHING J and H catalogs (not tweakreged images) 
; HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
; this task is needed for computing scales and weights. The fluxes in
; the two catalogs are compared to et the scales, while the S/N ratios
; are compared to get the weights

; catalog SExtracted from J image (not tweakreged)
readcol,cat_Jn,ID_J,X_IM_J,Y_IM_J,A_IM_J,B_IM_J,THETA_IM_J,X_WO_J,Y_WO_J,A_WO_J,B_WO_J,THETA_WO_J,MAG_J, MAGERR_J ,CLASS_STAR_J ,FLAGS_J ,skipline=15,format='a,a,a,a,a,a,a,a,a,a,a,a,a,a,a'

; catalog SExtracted from H image (not tweakreged)
readcol,cat_Hn,ID_H,X_IM_H,Y_IM_H,A_IM_H,B_IM_H,THETA_IM_H,X_WO_H,Y_WO_H,A_WO_H,B_WO_H,THETA_WO_H,MAG_H, MAGERR_H ,CLASS_STAR_H ,FLAGS_H ,skipline=15,format='a,a,a,a,a,a,a,a,a,a,a,a,a,a,a'

X_WO_J=double(X_WO_J)
Y_WO_J=double(Y_WO_J)
MAG_J=double(MAG_J)
X_WO_H=double(X_WO_H)
Y_WO_H=double(Y_WO_H)
MAG_H=double(MAG_H)

 ; Flux and Fluxerr uJy
FLUX_J=10^(29-(MAG_J+48.6)/2.5)
FLUXERR_J=abs( 10^(29-(MAG_J+MAGERR_J+48.6)/2.5) - 10^(29-((MAG_J-MAGERR_J)+48.6)/2.5)  )/2.
FLUX_H=10^(29-(MAG_H+48.6)/2.5)
FLUXERR_H=abs( 10^(29-(MAG_H+MAGERR_H+48.6)/2.5) - 10^(29-((MAG_H-MAGERR_H)+48.6)/2.5)  )/2.

; FIRST MATCH (catalogs aren't alligned each other)
cccpro,X_WO_J, Y_WO_J, X_WO_H, Y_WO_H, J_H_IDX_o, H_J_IDX_o ,dt=0.5
mean_delta_RA=median(X_WO_J[J_H_IDX_o]-X_WO_H[H_J_IDX_o])
mean_delta_dec=median(Y_WO_J[J_H_IDX_o]-Y_WO_H[H_J_IDX_o])
; SECOND MATCH (after allignement correction)
cccpro,X_WO_J, Y_WO_J, X_WO_H+mean_delta_RA, Y_WO_H+mean_delta_dec, J_H_IDX, H_J_IDX ,dt=0.1

DRA_corr=3600.*(X_WO_J[J_H_IDX]-(X_WO_H[H_J_IDX]+mean_delta_RA))*cos(!pi*median(Y_WO_H[H_J_IDX])/180.)
ddec_corr=3600.*(Y_WO_J[J_H_IDX]-(Y_WO_H[H_J_IDX]+mean_delta_dec))
plot,DRA_corr,ddec_corr,position=[0.12,0.2,0.5,0.95],xtitle='Delta RA (corr)',ytitle='Delta dec (corr)',psym=3,/iso,charsize=1.2,title='J and H catalogs matching'
oplot,[-10,10],[0,0],linestyle=2 ;color='goldenrod'
oplot,[0,0],[-10,10],linestyle=2 ;,color='goldenrod'
plot,MAG_J[J_H_IDX],MAG_H[H_J_IDX],psym=3,xrange=[18,30],yrange=[18,30],/xst,/yst,/noerase,xtitle='J mag',ytitle='H mag',position=[0.60,0.2,0.98,0.95],/iso,charsize=1.2
oplot,[0,100],[0,100],linestyle=2 ;,color='goldenrod'

if TS eq '1' then fff='fff'
if TS eq '1' then read, fff



; HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
;  SCALE sci IMAGES 
; HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
; NOTE:
; J image is used as reference. The scaling factor is computed from
; the zeropoint magnitude of the images

;Scaling_F=10^((ZPM_J-ZPM_H)/2.5) ; NO NO NO WRONG!!!

Scale_zeropoint=10^((ZPM_J-ZPM_H)/2.5)
Scale_fluxes=median(FLUX_J[J_H_IDX]/FLUX_H[H_J_IDX])

Scaling_F=Scale_zeropoint*Scale_fluxes

Scale_sci_J=1.
;Scale_sci_H=Scaling_F
Scale_sci_H=float(Scaling_F)

Scale_sci_J_string=strcompress(string(Scale_sci_J),/remove_all)
Scale_sci_H_string=strcompress(string(Scale_sci_H),/remove_all)


Print, 'WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW'
Print, ' The H sci and rms images will be multiplied by'
print,  Scale_sci_H_string
print, ' before combining them with the corresponding '
print, ' smoothed J image'
Print, 'WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW'

; IMAGES SCALED HERE!
; J sci image doesn't need to be scaled (scale=1)
; H sci image scaled to J values 
sci_H_scaled=sci_H*Scale_sci_H
writefits,image_sci_scaled_Hn,sci_H_scaled,hd_sci_H


; HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
; SCALE rms IMAGES
; HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
; NOTE: the "quadratic" option of imcobine (iraf) doesn't allow
; to properly scale the images before combining them. This scaling is
; then performed here.

scale_rms_J=scale_sci_J  ; scale for rms = scale for sci image
scale_rms_H=scale_sci_H  ; scale for rms = scale for sci image

; IMAGES SCALED HERE!
; J rms image doesn't need to be scaled (scale=1)
; H rms image scaled to the same H sci image scale
scaled_img_rms_H=rms_H*scale_rms_H
writefits,image_rms_scaled_Hn,scaled_img_rms_H,hd_rms_H





; HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
; COMPUTE WEIGHTS FOR J Vs H IMAGE
; HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

; Chose which method use
; METHOD_W='1'
; METHOD_W='2'
METHOD_W='COMB' ; Average of methon 2 and 3

; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; xxxxxxxxxxxxxxxxxxxxxxx METHOD 1 xxxxxxxxxxxxxxxxxxxxxxxxx
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
IF METHOD_W eq '1' or METHOD_W eq 'COMB' then begin

; METHOD 1: comparing S/N ratios between SExtracted fluxes;
; read and match catalogs to compare magnitudes and magerrors

;*** Weight for H image ***

;Noise = N = 1/sqrt(exptime) 
; Image_1 & Image_2 = (Im1*t1 + Im2*t2)/(t1+t2) =
; = (Im1*(S1/N1)^2 + Im2*(S2/N2)^2)/ ((S1/N1)^2 +(S2/N2)^2) =
; = Im1*W1 + Im2*W2 -->
; --> W2 = [ (S2/N2)^2 /(S1/N1)^2 ]*W1
; IF W1=1 --> W2=(S2/N2)^2 /(S1/N1)^2 

; (S/N)_J / (S/N)_H
SN_RATIO_J_H_M1=median((FLUX_J[J_H_IDX]/FLUXERR_J[J_H_IDX])/(FLUX_H[H_J_IDX]/FLUXERR_H[H_J_IDX]))
; W_H= 1/[ (S/N)_J / (S/N)_H ]^2.
IMG_WEIGHT_M1=1./(SN_RATIO_J_H_M1^2)


ENDIF
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; xxxxxxxxxxxxxxxxxxxxx METHOD 1 END xxxxxxxxxxxxxxxxxxxxxxx
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; xxxxxxxxxxxxxxxxxxxxxxx METHOD 2 xxxxxxxxxxxxxxxxxxxxxxxxx
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
IF METHOD_W eq '2'  or METHOD_W eq 'COMB' then begin

; S/N ratio obtained from rms/sci. Only pixels containing sources
; (above 5 sigmas are considered). There is no difference in using the
; original or the scaled sci and rms images (since both sci and rms
; are scaled using the same factor) 

; IMPORTANT: THIS METHOD WORKS ONLY IF IMAGES ARE CORRECTLY TWEAKREGED
; TO THE SAME WCS AND PIXEL_SYSTEMS !

;threshold= 3sigma
TH=5.
obin=0.001

; J IMAGE
SEL1J=where(sci_J ne 0.) ; eliminates image borders
PERC_J=percentiles(sci_J[SEL1J],VALUE=[0.1,0.9])
plothist,sci_J[SEL1J],XHIST_J,YHIST_J,bin=obin,xrange=[5*PERC_J[0],5*PERC_J[1]],/xst,/noplot

N_binsJ=float(n_elements(where(XHIST_J gt PERC_J[0] and XHIST_J lt PERC_J[1])))
NEWBIN_J=obin*N_binsJ/50. ; To keep the same binning among different fields
plothist,sci_J[SEL1J],XHIST_J,YHIST_J,bin=NEWBIN_J,xrange=[5*PERC_J[0],5*PERC_J[1]],/xst,title='S/N for J will be computed for pixels above '+strcompress(string(TH))+' sigma',charsize=1.2,xtitle='pixel value'

GFJ=gaussfit(XHIST_J,YHIST_J,AA_J)
GFIT_J=AA_J[0]*exp(-((XHIST_J-AA_J[1])^2)/(2*AA_J[2]^2))
oplot,XHIST_J,GFIT_J;,linestyle=1; ,color='goldenrod'
THJ=AA_J[1]+TH*AA_J[2]
oplot,[THJ,THJ],[0,10*AA_J[0]],linestyle=2

if TS eq '1' then fff='fff'
if TS eq '1' then read, fff

; H IMAGE
;SEL1H=where(sci_H lt -1e-7 or sci_H gt 1e-7) ;  eliminates image borders
SEL1H=where(sci_H ne 0.) ;  eliminates image borders

PERC_H=percentiles(sci_H[SEL1H],VALUE=[0.1,0.9])
plothist,sci_H[SEL1H],XHIST_H,YHIST_H,bin=obin,xrange=[5*PERC_H[0],5*PERC_H[1]],/xst,/noplot

N_binsH=float(n_elements(where(XHIST_H gt PERC_H[0] and XHIST_H lt PERC_H[1])))
NEWBIN_H=obin*N_binsH/50. ; To keep the same binning among different fields
plothist,sci_H[SEL1H],XHIST_H,YHIST_H,bin=NEWBIN_H,xrange=[5*PERC_H[0],5*PERC_H[1]],/xst,title='S/N for H will be computed for pixels above '+strcompress(string(TH))+' sigma',charsize=1.2,xtitle='pixel value'

GFH=gaussfit(XHIST_H,YHIST_H,AA_H)
GFIT_H=AA_H[0]*exp(-((XHIST_H-AA_H[1])^2)/(2*AA_H[2]^2))
oplot,XHIST_H,GFIT_H;color='goldenrod'
THH=AA_H[1]+TH*AA_H[2]
oplot,[THH,THH],[0,10*AA_H[0]],linestyle=2

;select=where(sci_J gt 0.1 and sci_H gt 0.1 and rms_J gt 0 and rms_H gt 0)
;select=where(sci_J gt THJ and sci_H gt THH and rms_J gt 0 and rms_H gt 0)
; exclude probable bad pixels (S/N<1)
select=where(sci_J gt THJ and sci_H gt THH and rms_J gt 0 and rms_H gt 0 and sci_J/rms_J gt 1 and sci_H/rms_H gt 1)

; method 2A ************************
; (S/N)_J / (S/N)_H
SN_RATIO_J_H_M2A=median((sci_J[select]/rms_J[select])/(sci_H[select]/rms_H[select]))
; W_H= 1/[ (S/N)_J / (S/N)_H ]^2.
IMG_WEIGHT_M2A=1./(SN_RATIO_J_H_M2A^2)

if TS eq '1' then fff='fff'
if TS eq '1' then read, fff

; more precise - method 2B ****************
; Logarithmic distribution (gaussian)
plothist, alog10((sci_J[select]/rms_J[select])/(sci_H[select]/rms_H[select])),xhistSNR,yhistSNR,bin=0.01,xrange=[-1.5,2.],xtitle='log[(S/N)_J / (S/N)_H ]', charsize=1.2
GFSNR=gaussfit(xhistSNR,yhistSNR,AA_SNR)
GFIT_SNR=AA_SNR[0]*exp(-((xhistSNR-AA_SNR[1])^2)/(2*AA_SNR[2]^2))
oplot,xhistSNR,GFIT_SNR;,color='goldenrod'
oplot,[AA_SNR[1],AA_SNR[1]],[0,10*AA_SNR[0]],linestyle=2


; (S/N)_J / (S/N)_H
SN_RATIO_J_H_M2B=10^AA_SNR[1]
; W_H= 1/[ (S/N)_J / (S/N)_H ]^2.
IMG_WEIGHT_M2B=1./(SN_RATIO_J_H_M2B^2)

; USE EASY METHOD (2A)
; SN_RATIO_J_H_M2=SN_RATIO_J_H_M2A
; IMG_WEIGHT_M2=IMG_WEIGHT_M2A

; USE MORE PRECISE METHOD (2B)
SN_RATIO_J_H_M2=SN_RATIO_J_H_M2B
IMG_WEIGHT_M2=IMG_WEIGHT_M2B

ENDIF
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
; xxxxxxxxxxxxxxxxxxxxx METHOD 2 END xxxxxxxxxxxxxxxxxxxxxxx
; >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


; J image WHEIGTH
W_J=1.
; H image WEIGHT 
IF METHOD_W eq '1' then W_H=IMG_WEIGHT_M1
IF METHOD_W eq '2' then W_H=IMG_WEIGHT_M2
IF METHOD_W eq 'COMB' then W_H=(IMG_WEIGHT_M1+IMG_WEIGHT_M2)/2.

W_H_string=strcompress(string(W_H),/remove_all)


print, ''
print, ''
Print, 'WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW'
Print, ' In the final combined image, the scaled '
print, ' H image accounts for '+W_H_string+' times'
print, ' the J smoothed image '
Print, 'WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW'
print, ''
print, ''


if TS eq '1' then fff='fff'
if TS eq '1' then read, fff

; HHHHHHHHHHHHHHHHHHHHHHHHHHH
; SMOOTHING SCALE FOR J IMAGE
; HHHHHHHHHHHHHHHHHHHHHHHHHHH
; NOTES:
; The instrument is the same, only the filter changes (J and H)
; The PSF is determined by:
; Sigma=1.22*(lambda/Diameter), and only lambda is changing.
; INFO from:
; http://www.stsci.edu/hst/wfc3/ins_performance/ground/components/filters
; http://www.stsci.edu/hst/wfc3/documents/handbooks/currentIHB/c07_ir07.html
; For F110W (J) --> lambda (peak) = 1.150 um
; For F140W (H) --> lambda (peak) = 1.40 um
; For F160W (H) --> lambda (peak) = 1.545 um

; filter peak wavelengths
RWL_110=1150 ; nm
RWL_140=1400 ; nm
RWL_160=1545 ; nm

; FWHM - Wawelength relation
WL=  [800,  900,  1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700]
; FWHM [arcsec]
FWHM=[0.124,0.126,0.128,0.130,0.133,0.137,0.141,0.145,0.151,0.156]

FWHM_110=interpol(FWHM,WL,RWL_110) ; [arcsec]
FWHM_140=interpol(FWHM,WL,RWL_140) ; [arcsec]
FWHM_160=interpol(FWHM,WL,RWL_160) ; [arcsec]

SIGMA_110=FWHM_110/2.355 ; [arcsec]
SIGMA_140=FWHM_140/2.355 ; [arcsec]
SIGMA_160=FWHM_160/2.355 ; [arcsec]

; Test phase
if TS eq '1' then begin
plot,WL,FWHM,yrange=[0.11,0.17],/Yst,xtitle='wavelength [nm]',ytitle='FWHM';,psym=1
oplot,[RWL_110,RWL_110],[FWHM_110,FWHM_110],psym=1,symsize=1.5
oplot,[RWL_140,RWL_140],[FWHM_140,FWHM_140],psym=1,symsize=1.5
oplot,[RWL_160,RWL_160],[FWHM_160,FWHM_160],psym=1,symsize=1.5
fff='fff'
read, fff
endif

; SIGMA OF THE CONVOLVING FILTER MUST BE:
; (sigma_final)^2 + (sigma_initial)^2 + (sigma_filter)^2 -->
; --> sigma_filter = sqrt[ (sigma_final)^2 - (sigma_initial)^2 ]

IF switch_160_140 eq 0 then FINAL_SIGMA=SIGMA_160
IF switch_160_140 eq 1 then FINAL_SIGMA=SIGMA_140

NEW_SIGMA_110=sqrt( (FINAL_SIGMA^2)-(SIGMA_110^2) ) ; [arcsec]

; --------------------------------------------------------
; --------------------------------------------------------
; GET PIXELSCALE FROM J IMAGE. 
;  H images are assumed identical in size
;  & pixelscale.
; READ image header
HDJ=headfits(img_110n,EXTEN=0)
; Extract astrometry values
EXTAST,HDJ,ASTROREF
; Get x y image size:
NXpixels=strcompress(sxpar(HDJ,'NAXIS1'),/remove_all)
NYpixels=strcompress(sxpar(HDJ,'NAXIS2'),/remove_all)
; identify central pixel:
central_pix_x=round(float(NXpixels)/2.)
central_pix_y=round(float(NYpixels)/2.)
; identify RA dec position of central pixel:
XY2AD,central_pix_x,central_pix_y,ASTROREF , RA_centralpix, dec_centralpix
RA_ref=strcompress(RA_centralpix,/remove_all)
dec_ref=strcompress(dec_centralpix,/remove_all)
; Compute original pixel scale [arcsec/pix]
ra1=RA_centralpix
dec1=dec_centralpix-0.01d
ra2=ra1
dec2=dec_centralpix+0.01d
DELTADEC=dec2-dec1 ;(=0.02°)
AD2XY, ra1 ,dec1,ASTROREF, xpix1, ypix1
AD2XY, ra2 ,dec2,ASTROREF, xpix2, ypix2 
DELTA_PIX_X=xpix2-xpix1
DELTA_PIX_Y=ypix2-ypix1
DELTAPIX=sqrt((DELTA_PIX_X^2.)+(DELTA_PIX_Y^2.))
PIXSCALE=(DELTADEC/DELTAPIX)*3600.d ;[arcsec/pix]
; --------------------------------------------------------
; --------------------------------------------------------

NEW_SIGMA_110_PIX=NEW_SIGMA_110/PIXSCALE ; [Pixels]
NEW_SIGMA_110_string=string(strcompress(NEW_SIGMA_110_PIX))





; HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
; SCALE wht images
; HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
; NOTE:
; The final combined image will look as a J image with longer exposure
; time (and a small smoothing correction). 
;
; IMPORTANT: In this case also the J wht image is scaled (to the final
; equivalent exposure time, as for H)
;
; Given the exposure time "texp" of the original science images, the
; weight image has a value, in each pixel, that represent the
; exposure time spent observing in each pixel. Here we scale the final
; image to a value representing the total exposure time.

; Exposure time J (F110)
h_J=headfits(image_sci_Jn)
exptime_J=double(strcompress(sxpar(h_J,'EXPTIME'),/remove_all))
exptime_J=double(exptime_J)

; Exposure time H (F140 or F160)
h_H=headfits(image_sci_Hn) 
exptime_H=double(strcompress(sxpar(h_H,'EXPTIME'),/remove_all))
exptime_H=double(exptime_H)

plothist,wht_J[where(wht_J gt 0 and wht_H gt 0)]/exptime_J,bin=0.01,xrange=[0,2],xtitle='(wht values) /exptime',linestyle=1,charsize=1.2,title='. . . . J,   _ _ _ H'
plothist,wht_H[where(wht_H gt 0 and wht_J gt 0)]/exptime_H,bin=0.01,/overplot,linestyle=2 ;color='red'

if TS eq '1' then fff='fff'
if TS eq '1' then read,fff

; combined exposure times and weights
;expt_comb=(exptime_J*W_J + exptime_H*W_H)
; IMPORTANT: The H image is normalized to the J standard.
;            the exposure time of the H image has no meaning here.
;            The exptime of the J image has to be considered instead,
;            with a weight that keeps into account the different S/N
;    THE COMBINED IMAGE IS LIKE A J IMAGE WITH A LONGER EXPOSURE TIME.

;expt_comb=(exptime_J*W_J + exptime_H*W_H)/W_J ; NOTE: WRONG !!!!
expt_comb=(exptime_J*W_J + exptime_J*W_H)/W_J ; NOTE: W_J=1

scale_wht_J=expt_comb/exptime_J
scale_wht_H=expt_comb/exptime_H
scale_wht_J_string=strcompress(string(scale_wht_J),/remove_all)
scale_wht_H_string=strcompress(string(scale_wht_H),/remove_all)

plothist,wht_J[where(wht_J gt 0 and wht_H gt 0)]*scale_wht_J,bin=10,xtitle='scaled WHT VALUE',title='. . . . J,   _ _ _ H,  _____ combined (expected)',linestyle=1
plothist,wht_H[where(wht_H gt 0 and wht_J gt 0)]*scale_wht_H,bin=10,/overplot,linestyle=2 ;,color='red'

IDXT=where(wht_J gt 0 and wht_H gt 0)
plothist,( wht_J[IDXT]*scale_wht_J*W_J + wht_H[IDXT]*scale_wht_H*W_H)/(W_J+W_H),bin=10,/overplot ;,color='goldenrod'



; SCALE J wht
scaled_img_wht_J=wht_J*scale_wht_J
;-----------------------------------------------------------------
; NOTE: keep float instead of doube to prevent from overflow and
; underflow errors)
;----------------------------------------------------------------
;writefits,image_wht_scaled_Jn,scaled_img_wht_J,hd_wht_J      ; Double
writefits,image_wht_scaled_Jn,float(scaled_img_wht_J),hd_wht_J; float 

; SCALE H wht
scaled_img_wht_H=wht_H*scale_wht_H
;writefits,image_wht_scaled_Hn,scaled_img_wht_H,hd_wht_H      ; Double
writefits,image_wht_scaled_Hn,float(scaled_img_wht_H),hd_wht_H; float 

print, "--------------------------"
print, "Temporary images written: "
print, image_wht_scaled_Jn
print, image_wht_scaled_Hn
print, "--------------------------"

if TS eq '1' then fff='fff'
if TS eq '1' then read,fff


; HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
; WRITE FILES for image names and weights
; HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH


; Lists of images to be combined
openw,1, File_sci_images
printf,1,path+'F110W_sci_smooth.fits' ; smoothed J sci image (no scaling)
printf,1,image_sci_scaled_Hn          ; scaled H sci image
close,1
free_lun,1

; Lists of rms images to be combined
openw,1, File_rms_images
printf,1,path+'F110W_rms_smooth.fits' ; smoothed J rms image (no scaling)
printf,1,image_rms_scaled_Hn          ; scaled H rms image
close,1
free_lun,1

; Lists of wht images to be combined
openw,1, File_wht_images
printf,1,path+'F110W_wht_scaled_smoothed.fits' ; scaled and smoothed J wht image
printf,1,image_wht_scaled_Hn                   ; scaled H wht image
close,1
free_lun,1

; List of weights to be used for sci, rms and wht images
; NOTE: 
; This file is used also in the new version of match_cat.pro !
; J image accounts for 1 (it is the reference
openw,3,File_weights
printf,3,'1'
printf,3,W_H_string
close,3
free_lun,3


; HHHHHHHHHHHHHHHHHHHHHHH
; WRITE FINAL PYTHON CODE
; HHHHHHHHHHHHHHHHHHHHHHH

; Write python code
openw,4, Python_out_code1
printf, 4, 'from pyraf import iraf'
printf, 4, 'from iraf import gauss'
printf, 4, 'from iraf import imcombine'
printf, 4, 'def main():'


; VERY VERY IMPORTANT: 
; do not use the "scale" option of the iraf.imcombine task !!!!!!
; That function normalizes the scale factors to the scale of the first
; image (as if they were weights, actually...)

; SMOOTH ORIGINAL J "sci" IMAGE
printf, 4, '    iraf.gauss(input="'+path+'F110W_sci.fits", output="'+path+'F110W_sci_smooth.fits",sigma='+NEW_SIGMA_110_string+')'
; SMOOTH ORIGINAL J "rms" IMAGE
printf, 4, '    iraf.gauss(input="'+path+'F110W_rms.fits", output="'+path+'F110W_rms_smooth.fits",sigma='+NEW_SIGMA_110_string+')'
; SMOOTH ORIGINAL J "wht" IMAGE
printf, 4, '    iraf.gauss(input="'+image_wht_scaled_Jn+'", output="'+path+'F110W_wht_scaled_smoothed.fits",sigma='+NEW_SIGMA_110_string+')'


; update sci image header otherwise problems when combining them (weighting)
printf, 4, '    iraf.hedit(images="'+path+'F110W_sci_smooth.fits[0]", field="NCOMBINE", value="none", verify="no", update="yes")'
printf, 4, '    iraf.hedit(images="'+image_sci_scaled_Hn+'[0]", field="NCOMBINE", value="none", verify="no", update="yes")'

; update rms image header otherwise problems when combining them (weighting)
printf, 4, '    iraf.hedit(images="'+path+'F110W_rms_smooth.fits[0]", field="NCOMBINE", value="none", verify="no", update="yes")'
printf, 4, '    iraf.hedit(images="'+image_rms_scaled_Hn+'[0]", field="NCOMBINE", value="none", verify="no", update="yes")'

; update wht image header otherwise problems when combining them (weighting)
printf, 4, '    iraf.hedit(images="'+path+'F110W_wht_scaled_smoothed.fits[0]", field="NCOMBINE", value="none", verify="no", update="yes")'
printf, 4, '    iraf.hedit(images="'+image_wht_scaled_Hn+'[0]", field="NCOMBINE", value="none", verify="no", update="yes")'


; COMBINE J-smoothed AND H-scaled "sci" IMAGES
printf, 4, '    iraf.imcombine(input="@'+File_sci_images+'", output="'+combined_image_sci_name+'",sigmas="'+image_rms_out+'",combine="average",reject="none",project="no",outtype="real",offsets="none",scale="none",zero="none",weight="@'+File_weights+'")'

; COMBINE J-smoothed AND H-scaled "rms" IMAGES
; NOTE: the "QUADRATURE" option doesn't allow to scale the
; images (why?). I tested this and it doesn't work
printf, 4, '    iraf.imcombine(input="@'+File_rms_images+'", output="'+combined_image_rms_name+'",combine="quadrature",reject="none",project="no",outtype="real",offsets="none",scale="none",zero="none",weight="@'+File_weights+'")'

; COMBINE J-scaled-smoothed AND H-scaled "wht" IMAGES
printf, 4, '    iraf.imcombine(input="@'+File_wht_images+'", output="'+combined_image_wht_name+'",combine="average",reject="none",project="no",outtype="real",offsets="none",scale="none",zero="none",weight="@'+File_weights+'")'

printf, 4, "print '------------------------'"
printf, 4, "print 'smooth_and_combine.py'  "
printf, 4, "print '------------------------'"
printf, 4, "print ' ' "
printf, 4, "print 'J and H will be smoothed, scaled and combined'"
printf, 4, "print ' '"

printf, 4, 'main()'

close,4
free_lun,4


ENDIF ;IF ISTHEREJ gt 0 THEN BEGIN

IF ISTHEREJ eq 0 THEN BEGIN
print, "---------------------------"
print, " J image (F110) NOT FOUND  "
print, " no smoothing OR combining"
print, " procedures will be applied"
print, "---------------------------"
; OUT PYTHON CODE:
openw,4, Python_out_code1
printf, 4, "print ' '"
printf, 4, "print '------------------------'"
printf, 4, "print 'smooth_and_combine.py'  "
printf, 4, "print '------------------------'"
printf, 4, "print 'IMAGES ARE NOT COMBINED'"
printf, 4, "print 'This is possible if the '"
printf, 4, "print 'field is covered only in'"
printf, 4, "print 'an H filter (140 or 160)'" 
printf, 4, "print '------------------------'"
printf, 4, "print ' '"
close,4
free_lun,4
ENDIF

print, '-----------------------------------------------------------------------------------'
print, 'NOTE:'
print, 'The next following floating overflow and underflow messages do not have to be considered as errors. If you read this sentece, the program completed its computations.'
print, '-----------------------------------------------------------------------------------'

if TS eq '1' then stop
end
