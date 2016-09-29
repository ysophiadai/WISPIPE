; program to read dark_lookup tables for UVIS WFC3
; Takes a Julian date, and returns filename for dark for given julian date.
; binned option calls the binned files
; /avg uses the averaged darks after the smooth iteration

pro ivano_darks, postflash=postflash, avg=avg

  dir = ''
  file='dark_lookup_pfonly.txt'
 
  thisformat = '(A19, A3, I2, I4, A8)'

  readcol, dir+file, name, mon, day, yr, time, format=thisformat, /silent


  print, n_elements(name)
  counter = 0 
  for idx=0, n_elements(name)-1 do begin
     if keyword_set(avg) then strput, name, 'a', 1
     if keyword_set(postflash) then strput, name, 'p', 0
;     name[idx] = temp
     if not FILE_TEST(name[idx]) then begin
        print, name[idx]," ", mon[idx]," ", day[idx]," ",yr[idx]," ",time[idx]
        counter = counter + 1
     endif
  endfor

  print, 'Missing ' + string(counter) +' files out of ' + string(n_elements(name))

end
