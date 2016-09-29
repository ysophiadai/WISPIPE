; program to change the Calibration reference files
;pro cal_ref_uvis, list, udf=udf, goodsn=goodsn, unbinned=unbinned
; bindark calls binned in read_dark_lookup! (When called with /auto)

; When using this on full auto, use /bindark, /auto, /smooth
; if binned /auto, /smooth
; 
; cal_ref_uvis, /auto,/avg, /postflash, /uvis2

pro cal_ref_uvis, list=list, bindark=bindark, auto=auto, smooth=smooth, biashotpix=biashotpix, postflash=postflash, avg=avg, bin=bin, uvis2=uvis2

  if not keyword_set(uvis2) then begin
     print, 'You did not specify /uvis2 - are you sure?'
     stop
  endif
  
if keyword_set(list) then begin
   readcol, list, names, format='A' 
   endif else begin
      spawn, 'ls *raw.fits', names
   endelse

nimages = n_elements(names)

if not keyword_set(bindark) then begin
for idx=0, nimages-1 do begin
   
   h = headfits(names[idx])
   filter = strtrim(sxpar(h, 'FILTER'),2)
   date = strtrim(sxpar(h, 'DATE'),2)
   ; modified julian date exposure end time
   EXPEND = double(strtrim(sxpar(h, 'EXPEND'),2))
   origdark = strtrim(sxpar(h, 'DARKFILE'),2)
   
; This automatically chooses the dark to use based on the exposure date
   if keyword_set(auto) then begin
      dark = 'iref$'+read_dark_lookup(expend,smooth=smooth,postflash=postflash,avg=avg)
   endif

 ;  print, 'hi'
;   dark = 'iref$pa11641hi_drk.fits'
;   dark = 'iref$pak1521ti_drk.fits'
   ;dark = 'iref$pap1618gi_drk.fits'
   ;dark = 'iref$psp1618fi_drk.fits'
   ;dark = 'iref$pag19549i_drk.fits'
if keyword_set(uvis2) then sxaddpar, h, 'PCTECORR', 'OMIT'
   sxaddpar, h, 'DARKFILE', dark

   modfits, names[idx], 0, h
endfor

endif else begin

;;;;; below this line is only for binned data. Everything else is
;;;;; above here!!

if not keyword_set(auto) or not keyword_set(bindark) then begin
   print, 'By default, you probably want to use /auto or /auto and /bindark'
   print, 'Not currently doing that. .c to continue without it!'
   stop
endif


bias = 'iref$bias2x2mr_bia.fits'
;dark = 'iref$dark2x2mr_drk.fits'
;;;;;dark = 'iref$dark2x2mt_drk.fits'
;;;;;dark = 'iref$dark2x2t2_drk.fits'

;bias = 'iref$w461345hi_bia.fits'
;dark = 'iref$dark2x2ob_drk.fits'
flt225 = 'iref$f225w_2x2_pfl.fits'
flt275 = 'iref$f275w_2x2_pfl.fits'
flt336 = 'iref$f336w_2x2_pfl.fits'
flt475 = 'iref$f475x_2x2_pfl.fits'
flt600 = 'iref$f600lp_2x2_pfl.fits'
flt410 = 'iref$f410m_2x2_pfl.fits'
flt606 = 'iref$f606w_2x2_pfl.fits'
flt814 = 'iref$f814w_2x2_pfl.fits'


; new dark based on only 900s exposures and aggressive hot pixels
;if keyword_set(bindark) then begin
;dark = 'iref$drk_2x2_mr2.fits'
;endif

;if keyword_set(unbinned) then begin
 ;  bias = 'iref$uvis_2x2_bia.fits'
;   darkudf = 'iref$udf_epoch1_2x2_drk.fits'
;   darkgoodsn = 'iref$goodsn_epoch1_2x2_drk.fits'
;   
;   if keyword_set(udf) then dark = darkudf
;   if keyword_set(goodsn) then dark= darkgoodsn
;   if not keyword_set(udf) and not keyword_set(goodsn) then begin
;      print, 'You need to pick udf or goodsn for the flat'
;      stop
;   endif
;endif



for idx=0, nimages-1 do begin
   
   h = xheadfits(names[idx])
   filter = strtrim(sxpar(h, 'FILTER'),2)
   date = strtrim(sxpar(h, 'DATE'),2)
   ; modified julian date exposure end time
   EXPEND = double(strtrim(sxpar(h, 'EXPEND'),2))
   origdark = strtrim(sxpar(h, 'DARKFILE'),2)

   if not keyword_set(bindark) and not keyword_set(auto) then begin
      dark = origdark
      strput, dark, 'b', 5
   endif

; This automatically chooses the dark to use based on the exposure date
   if keyword_set(auto) then begin
      dark = 'iref$'+read_dark_lookup(expend, binned=bindark, smooth=smooth)
   endif

   if keyword_set(biashotpix) then begin
      strput, dark, 'b', 7
   endif

   ; quick override, DO NOT LEAVE HERE
   ;dark = 'iref$udf_epoch1b2x2_drk.fits'
   ;dark = 'iref$b3mthr004_drk.fits'
   ;dark = 'iref$bsm14447i_drk.fits'
   ;dark = 'iref$b9m1423ki_drk.fits'
   ;dark = 'iref$b7t1343si_drk.fits'

;dark = 'iref$b9m1423hi_drk.fits' ; par 114, 115
;dark = 'iref$b9m1423ki_drk.fits' ; par 120
;dark = 'iref$b9m1423qi_drk.fits' ; par 131
;dark = 'iref$b9m1423ti_drk.fits' ; par 135, 136
;dark = 'iref$b9m14244i_drk.fits' ; par 143
;dark = 'iref$ba32002mi_drk.fits' ; par 146, 147
;dark = 'iref$b2d19190i_drk.fits' ; par 181
;dark = 'iref$b2d19191i_drk.fits' ; par 183



   if filter eq 'F225W' then flt = flt225
   if filter eq 'F275W' then flt = flt275
   if filter eq 'F336W' then flt = flt336
   if filter eq 'F475X' then flt = flt475
   if filter eq 'F600LP' then flt = flt600
   if filter eq 'F606W' then flt = flt606
   if filter eq 'F814W' then flt = flt814
   if filter eq 'F410M' then flt = flt410


   sxaddpar, h, 'BIASFILE', bias
   sxaddpar, h, 'DARKFILE', dark

      
   sxaddpar, h, 'PFLTFILE', flt

   modfits, names[idx], 0, h

endfor

endelse

end
