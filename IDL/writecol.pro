; to create a region file into, using input:
; filename
; v1: shape_string, v2:x, v3:comma_string, v4:y, v5:comma_string, v6:
; radius_string, v7: skip_string, v8: skip_string, v9: skip_string,
; v10: color_string+label_string

PRO writecol, filename, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, $
              v12, v13, v14, v15, v16, v17, v18, v19, v20, v21, v22, $
              v23, v24, v25, $
              format=format, base_id=base_id, no_verify=no_verify

IF n_params() LT 2 THEN BEGIN
   print, 'calling sequence : '
   print, 'writecol, filename, v1, v2, v3,.... v25, format=format,' + $
    'base_id=base_id'
   return
ENDIF 

IF NOT(keyword_set(base_id)) THEN base_id=0
IF NOT(keyword_set(format)) THEN BEGIN 
   format='A'
   FOR i=1,n_params()-2 DO BEGIN 
      format=format+',A'
   ENDFOR
   format=format+',$/'
ENDIF  

fmt=', format= "(' +format + ')"'

IF NOT(keyword_set(no_verify)) THEN begin 
; check = nic_writecheck(filename) $
 c = findfile(filename)
 IF c(0) NE '' THEN BEGIN
   print, 'overwrite (y/n)?
   myans = get_kbrd(1)
   if myans eq 'y' then begin 
       check = 1
       spawn, '\rm '+filename
   ENDIF $
   ELSE check=0
 ENDIF $
 else check = 1
endif $
ELSE check = 1

help, check

IF NOT(check) THEN return

ncol = n_params()-1

openw, lun, filename, /get_lun
ws = ''
vv = 'v'+strtrim(indgen(ncol)+1, 2)

FOR i = float(0), ncol-1 DO BEGIN 
   ws = ws + ','+vv(i)+'(i)'
ENDFOR  
st = 'printf, lun' + ws + fmt
FOR i = float(0), n_elements(v1)-1 DO BEGIN 
   tst = execute(st)
ENDFOR  
free_lun, lun

END

   

