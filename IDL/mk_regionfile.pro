PRO mk_regionfile, x, y, radius, arcsec=arcsec, color=color, image=image, file=file, label=label,box=box

IF NOT(keyword_set(color)) THEN color='red'
IF NOT(keyword_set(arcsec)) THEN unit='' ELSE unit='"  '
IF NOT(keyword_set(file)) THEN file='out.reg'
IF NOT(keyword_set(image)) THEN coord='j2000' ELSE coord='image'

n = n_elements(x)

;IF NOT(keyword_set(box)) THEN begin
shape_string = strarr(n)+'circle '

radius_string = strarr(n)+strn(radius)+unit
;endif else begin
;shape_string = strarr(n)+'circle '
;'("box(",(d8.2),",",(d8.2),",184,8,0) # color=red")' 
;endelse


color_string = strarr(n)+'# color='+color

coord_string = strarr(n)+'# '+coord

skip_string = strarr(n)+'   '

open_string = strarr(n)+'('
close_string = strarr(n)+')'
IF NOT(keyword_set(image)) then comma_string = strarr(n)+'d ' ELSE comma_string=strarr(n)+' '

IF keyword_set(label) THEN label_string = strarr(n)+' text={'+label+'} ' ELSE label_string = strarr(n)+' ' 

;circle       331.3584594727d        -0.2803835273d 5         # color=red text={       1} 
;0th grism
;circle( -269.16, 1141.79,5) # font='helvetica 12 bold' text={           1}
;1st grism
;box(  376.78, 1149.20,184,8,0) # color=red
;# text(  376.78, 1158.20) color=magenta width=4 font='helvetica 14 bold' text={           1}


writecol, file, shape_string, x, comma_string,y, comma_string, radius_string, skip_string, skip_string, skip_string, color_string+label_string, $
   format='a,f20.10, a, f20.10, a, a, a, a, a, a',no_verify=1

END
