pro makeorder_B_IB2,field,path0

; Version 2
; In place of F600LP and F475X we call the filters
; with this new nomenclature:
; F475X  --> UVIS1
; F600LP --> UVIS2




path= path0+'/aXe/'+field+'/DATA/UVIS/'

;LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL
; I.B.
; SELECT TYPE OF DATA (both filters or only UVIS2?)
FILT='A'
IF FILE_TEST(path+'UVIS1_drz.fits') gt 0 then FILT='B' ;UVIS1
;LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL

readcol,path+'UVIS2.list',listUVIS2,format='a'
EE=0L
WHILE EE lt n_elements(listUVIS2) do begin
 IF listUVIS2[EE] ne '' and listUVIS2[EE] ne ' ' and strupcase(listUVIS2[EE]) ne 'NONE' THEN BEGIN
  spawn,'rm '+path+strcompress(listUVIS2[EE],/remove_all)
;  spawn,'rm '+path+strmid(strcompress(listUVIS2[EE],/remove_all),0,9)+'*'
 ENDIF
EE=EE+1
ENDWHILE


IF FILT eq 'B' then begin
readcol,path+'UVIS1.list',listUVIS1,format='a'
  EE=0L
  WHILE EE lt n_elements(listUVIS1) do begin
   IF listUVIS1[EE] ne '' and listUVIS1[EE] ne ' ' and strupcase(listUVIS1[EE]) ne 'NONE' THEN BEGIN
    spawn,'rm '+path+strcompress(listUVIS1[EE],/remove_all)
;    spawn,'rm '+path+strmid(strcompress(listUVIS1[EE],/remove_all),0,9)+'*'
   ENDIF
  EE=EE+1
  ENDWHILE 
ENDIF

spawn,'mv '+path+'UVIS_orig_WCS/* '+path
spawn,'rm -r '+path+'UVIS_orig_WCS/'

spawn,'rm -r '+path+'UVIS2_drz*'
spawn,'rm -r '+path+'UVIS2_sci.fits'
spawn,'rm -r '+path+'UVIS2_rms.fits'
spawn,'rm -r '+path+'UVIS2_wht.fits'

IF FILT eq 'B' then begin
spawn,'rm -r '+path+'UVIS1_drz*'
spawn,'rm -r '+path+'UVIS1_sci.fits'
spawn,'rm -r '+path+'UVIS1_rms.fits'
spawn,'rm -r '+path+'UVIS1_wht.fits'
ENDIF


end
