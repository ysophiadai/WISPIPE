pro makeorder_A_IB2,field, path0

; Version 2
; In place of F600LP and F475X we call the filters
; with this new nomenclature:
; F475X  --> UVIS1
; F600LP --> UVIS2



  
path= path0+'/aXe/'+field+'/DATA/UVIS/'
spawn,'mkdir '+path+'UVIS_orig_WCS'

;LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL
; I.B.
; SELECT TYPE OF DATA (both filters or only UVIS2?)
FILT='A'
print, "======================================================="
readcol,path+'UVIS1.list',listUVIS1_0,format='a'
IF n_elements(LISTUVIS1_0) eq 0 then begin
   print, ' The previous error can be ignored if no exposures' 
   print, ' are taken in one of the two uvis filters'
   print, "======================================================="
   listUVIS1_0='NONE'
ENDIF
IF listUVIS1_0[0] ne '' and  listUVIS1_0[0] ne ' ' and strupcase(listUVIS1_0[0]) ne 'NONE' then FILT='B' ;UVIS1
;IF FILE_TEST(path+'DATA/UVIS/UVIS1_drz.fits') gt 0 then FILT='B' ;UVIS1
;LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL

readcol,path+'UVIS2.list',listUVIS2,format='a'
EE=0L
WHILE EE lt n_elements(listUVIS2) do begin
 IF listUVIS2[EE] ne '' and listUVIS2[EE] ne ' ' and strupcase(listUVIS2[EE]) ne 'NONE' THEN BEGIN
  spawn,'cp '+path+strcompress(listUVIS2[EE],/remove_all)+' '+path+'UVIS_orig_WCS/'
 ENDIF
EE=EE+1
ENDWHILE


IF FILT eq 'B' then begin
readcol,path+'UVIS1.list',listUVIS1,format='a'
  EE=0L
  WHILE EE lt n_elements(listUVIS1) do begin
   IF listUVIS1[EE] ne '' and listUVIS1[EE] ne ' ' and strupcase(listUVIS1[EE]) ne 'NONE' THEN BEGIN
    spawn,'cp '+path+strcompress(listUVIS1[EE],/remove_all)+' '+path+'UVIS_orig_WCS/'
   ENDIF
  EE=EE+1
  ENDWHILE 
ENDIF





end
