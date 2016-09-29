;+
;NAME
; ractoraw
;PURPOSE
; program to rename rac.fits files to raw.fits files
; this is a supporting code for runctecorr or ctedarks
;
; INPUTS
; None needed
;
;MODIFICATION HISTORY
;     Written by: Marc Rafelski 2013
;-

pro ractoraw
spawn, 'ls *rac.fits', rac

for idx=0, n_elements(rac)-1 do begin

   locrac =STRPOS(rac[idx], '_rac.fits')
   name = strmid(rac[idx],0,locrac)
   
   command = 'mv '+name+'_rac.fits '+ name+'_raw.fits'
   spawn, command
endfor

end
