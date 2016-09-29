;+
;NAME
; runctecorr
;PURPOSE
; IDL wrapper to run ctereverse for wfc3 either on all files in a
; directory (default), or a specific file, or a list of files
; 
; INPUTS
; None needed
;OPTIONAL KEYWORDS
; file - is the filename to run ctecorr on if you don't want to
;        run it on all raw.fits files in the dirctory.
; list - /list to make file be a list of files instead
; clean  - /clean will tell the code to remove the previous raw files
;          and rename the rac files to raw. Make sure you have your
;          raw files backed up before hand. Currently only works if
;          nothing else is specified (ie. not file or list)     
;          === DO NOT USE!
; mp    - /mp runs it with multiple processors assuming that is
;         installed. 
;
;MODIFICATION HISTORY
;     Written by: Marc Rafelski 2013
;     Added mp support Jan 2014
;-
; Note: Don't use clean


pro runctecorr, file=file, list=list, clean=clean, mp=mp

; if no file keyword, assume you want to do it on all the raw files. 

if not keyword_set(file) then begin
   spawn, 'ls *raw.fits', inlist
   
   for idx=0, n_elements(inlist)-1 do begin
      if keyword_set(mp) then begin
         spawn, 'wfc3uv_ctereverse_parallel.e'  + ' ' + inlist[idx]
      endif else begin
         spawn, 'wfc3uv_ctereverse.e'  + ' ' + inlist[idx]
      endelse
   endfor

   if keyword_set(clean) then begin
      spawn, 'rm *raw.fits'
      ractoraw
   endif

endif else begin
   
   ; if /list then read in list, and run on list. 
   if keyword_set(list) then begin
      readcol, file, inlist, format='A'
      for idx=0, n_elements(inlist)-1 do begin
      if keyword_set(mp) then begin
         spawn, 'wfc3uv_ctereverse_parallel.e'  + ' ' + inlist[idx]
      endif else begin
         spawn, 'wfc3uv_ctereverse.e'  + ' ' + inlist[idx]
      endelse
      endfor
   endif else begin

      ; run on a single file
      if keyword_set(mp) then begin
         spawn, 'wfc3uv_ctereverse_parallel.e'  + ' ' + file
      endif else begin
         spawn, 'wfc3uv_ctereverse.e'  + ' ' + file
      endelse

   endelse
endelse

end
