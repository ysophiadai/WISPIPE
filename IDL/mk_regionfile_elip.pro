PRO mk_regionfile_elip, x, y, radiusa,radiusb, angle, arcsec=arcsec, color=color, image=image, file=file, label=label
  
IF NOT(keyword_set(color)) THEN color='red'
IF NOT(keyword_set(arcsec)) THEN unit='' ELSE unit='"  '
IF NOT(keyword_set(file)) THEN file='out.reg'
IF NOT(keyword_set(image)) THEN coord='j2000' ELSE coord='image'

n = n_elements(x)


shape_string = strarr(n)+'ellipse '

radius_stringa = strarr(n)
radius_stringb = strarr(n)
angle_string = strarr(n)

for i=0, n-1 do begin
radius_stringa[i] = strn(radiusa[i])+unit
radius_stringb[i] = strn(radiusb[i])+unit
angle_string[i] = strn(angle[i])+unit
endfor

color_string = strarr(n)+'# color='+color

coord_string = strarr(n)+'# '+coord

skip_string = strarr(n)+'   '

open_string = strarr(n)+'('
close_string = strarr(n)+')'
IF NOT(keyword_set(image)) then comma_string = strarr(n)+'d ' ELSE comma_string=strarr(n)+' '

IF keyword_set(label) THEN label_string = strarr(n)+' text={'+label+'} ' ELSE label_string = strarr(n)+' ' 


writecol, file, shape_string, x, comma_string,y, comma_string, radius_stringa, skip_string, radius_stringb, skip_string, angle_string, skip_string,  skip_string, skip_string, color_string+label_string, $
   format='a,f20.10, a, f20.10, a, a,a, a, a, a, a, a,a,a,a',no_verify=1

END
