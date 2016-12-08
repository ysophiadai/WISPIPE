pro makeorder_A_IB2,field, path0

; Version 2
; In place of F600LP and F475X we call the filters
; with this new nomenclature:
; F475X  --> UVIS1
; F600LP --> UVIS2



  
path= path0+'/aXe/'+field+'/DATA/UVIS/'
spawn,'mkdir '+path+'UVIS_orig_WCS'


;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; OBS CHECK 
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
UV1_OBS='NO'
UV2_OBS='NO'
uvis='NO'
UV1_list ='none'
UV2_list ='none'

TEST_UV1=file_test(path+'UVIS1.list',/zero_length) ; 1 if exists but no content
TEST_UV1B=file_test(path+'UVIS1.list')             ; 1 if exists
TEST_UV2=file_test(path+'UVIS2.list',/zero_length) ; 1 if exists but no content
TEST_UV2B=file_test(path+'UVIS2.list')             ; 1 if exists
;------------------------------------------------

;   UVIS1    +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
IF TEST_UV1 eq 0 and TEST_UV1B eq 1 then begin
   readcol,path+'UVIS1.list',UV1_list,format=('A')
   if strlowcase(UV1_list[0]) ne 'none' and n_elements(UV1_list[0]) gt 0 then UV1_OBS='YES'
ENDIF
;   UVIS2    +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
IF TEST_UV2 eq 0 and TEST_UV2B eq 1 then begin
   readcol,path+'UVIS2.list',UV2_list,format=('A')
   if strlowcase(UV2_list[0]) ne 'none' and n_elements(UV2_list[0]) gt 0 then UV2_OBS='YES'
ENDIF
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

print, 'mk_order_A'
print, 'HHHHHHHHHHHHHHHHH'
print, 'UV1_OBS = '+UV1_OBS
print, 'UV2_OBS = '+UV2_OBS
print, 'HHHHHHHHHHHHHHHHH'

;-------------------------------------------------------------------
; UVIS DATA
IF UV1_OBS eq 'YES' or UV2_OBS eq 'YES' then uvis='YES'
print, '=========================================================='
print, "Set of data:"
print, "uvis=   "+uvis
print, '------------------------------'
print, "uvis   --> uvis data are/aren't present"
print, '=========================================================='

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

IF uvis eq 'YES' then begin
 control=0L
   
 IF UV2_OBS eq 'YES' then begin
  EE=0L
  WHILE EE lt n_elements(UV2_list) do begin
   IF UV2_list[EE] ne '' and UV2_list[EE] ne ' ' and strlowcase(UV2_list[EE]) ne 'none' THEN BEGIN
    spawn,'cp '+path+strcompress(UV2_list[EE],/remove_all)+' '+path+'UVIS_orig_WCS/'
    control=control+1
   ENDIF
   EE=EE+1
  ENDWHILE
 ENDIF

 IF UV1_OBS eq 'YES' then begin
  EE=0L
  WHILE EE lt n_elements(UV1_list) do begin
   IF UV1_list[EE] ne '' and UV1_list[EE] ne ' ' and strlowcase(UV1_list[EE]) ne 'none' THEN BEGIN
    spawn,'cp '+path+strcompress(UV1_list[EE],/remove_all)+' '+path+'UVIS_orig_WCS/'
    control=control+1
   ENDIF
   EE=EE+1
  ENDWHILE 
 ENDIF

 IF control eq 0 THEN BEGIN
  print, 'ERROR: uvis data seems to be present but makeorder_A did not work properly!'
 ENDIF

ENDIF


IF uvis eq 'NO' then begin
print, '============================================================='
print, 'No operations were made by makeorder_A (no uvis data present)'
print, '============================================================='
ENDIF


end
