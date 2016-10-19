; Run uvis_preprocess on a list of fields
; Takes as an input a list of field names, e.g.: 
; multiple_uvis_preprocess, ['Par302', 'Par303', 'Par304']
; Note: Run in $WISPIPE/IDL/

pro multiple_uvis_preprocess, fields, nocalwf3=nocalwf3, mp=mp, nopostflash=nopostflash, uvis2=uvis2, olduvis=olduvis, sp=sp

  for idx=0, n_elements(fields)-1 do begin
     print, 'Processing field: ', fields[idx]
     uvis_preprocess, fields[idx], uvis2=uvis2, olduvis=olduvis, sp=sp
     cd, '$WISPIPE/IDL/'
  endfor
  
end
