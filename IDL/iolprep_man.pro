; program that with iolprepmanual.py replaces the iolprep program from
; axe. This reads in the result from iolprepmanual, and creates the
; necessary _1.cat files

pro iolprep_man, field, path0, pathc

;droppath="~/WISPIPE/aXe/" ; for copying files
;path="~/data2/WISPS/aXe/" ; This is where data will end up
;path3=path2+'DATA/DIRECT_GRISM/test/'

droppath = pathc+'/aXe/'
path = path0+'/aXe/'
path2=path+field+"/"
path3=path2+'DATA/DIRECT_GRISM/'

print,"working in directory  ",path3

; iolprep created a bunch of _xy_1.cat files. Need to create a list of
; these files. These files are listed in the G141_axeprep.lis and
; G102_axeprep.lis files, just without the _xy part.


; Lets check if files exist
;File exists even if empty, so need this double check for zero length

F160 = file_test(path3+'F160_clean.list') and not file_test(path3+'F160_clean.list', /zero_length) 
F140 = file_test(path3+'F140_clean.list') and not file_test(path3+'F140_clean.list', /zero_length) 
F110 = file_test(path3+'F110_clean.list') and not file_test(path3+'F110_clean.list', /zero_length) 


if F160 then begin
   
   readcol, path3+'F160_clean.list', F160_list, format=('A'), /silent

   if f160_list[0] ne 'none' then begin

   template = 'cat_F160.cat'
   
   for idx=0, n_elements(F160_list)-1 do begin
      filename = F160_list[idx]
      floc = strpos(filename, '.fits', /reverse_search)
      rootn = strmid(filename, 0, floc)
      infile = rootn+'_xy_1.cat'
      outfile = rootn+'_1.cat'
      
                                ; read in the specific cat file
      readcol, path3+infile, xin, yin, format=('D,D'), skipline=1, /silent 
                                ; read in the general catalog file
                                ; we want a seperate header and columns
      
      OPENR,lun,path3+template,/get_lun
      header=strarr(15)
      readf,lun,header
      CLOSE,lun
      FREE_LUN,lun
      myformat=('A,L,D,D,D,D,D,D,D,D,D,D,D,D,D,D')
      readcol, path3+template, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, skipline=15, /silent, format=myformat
      
      num = n_elements(x1)
      openw,u1,path3+outfile,/get_lun
      printf, u1, header
                                ; note the switch for columns 2 and 3 to xin and yin
      for idy=0, num-1 do begin
         printf, u1, x1[idy], xin[idy], yin[idy], x4[idy], x5[idy], x6[idy], x7[idy], x8[idy], x9[idy], x10[idy], x11[idy], x12[idy], x13[idy], x14[idy], x15[idy],FORMAT='((I0,10(2X,:,F0),(2X,:,F0.2),3(2X,:,F0.2)))' 
      endfor
      
      close, u1
      free_lun, u1
      
   endfor
endif

endif

if F140 then begin
   
   readcol, path3+'F140_clean.list', F140_list, format=('A'), /silent

   if f140_list[0] ne 'none' then begin

   template = 'cat_F140.cat'
   
   for idx=0, n_elements(F140_list)-1 do begin
      filename = F140_list[idx]
      floc = strpos(filename, '.fits', /reverse_search)
      rootn = strmid(filename, 0, floc)
      infile = rootn+'_xy_1.cat'
      outfile = rootn+'_1.cat'
      
                                ; read in the specific cat file
      readcol, path3+infile, xin, yin, format=('D,D'), skipline=1, /silent 
                                ; read in the general catalog file
                                ; we want a seperate header and columns
      
      OPENR,lun,path3+template,/get_lun
      header=strarr(15)
      readf,lun,header
      CLOSE,lun
      FREE_LUN,lun
      myformat=('L,D,D,D,D,D,D,D,D,D,D,D,D,D,D')
      readcol, path3+template, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, skipline=15, /silent, format=myformat
      
      num = n_elements(x1)
      openw,u1,path3+outfile,/get_lun
      printf, u1, header
                                ; note the switch for columns 2 and 3 to xin and yin
      for idy=0, num-1 do begin
         printf, u1, x1[idy], xin[idy], yin[idy], x4[idy], x5[idy], x6[idy], x7[idy], x8[idy], x9[idy], x10[idy], x11[idy], x12[idy], x13[idy], x14[idy], x15[idy],FORMAT='((I0,10(2X,:,F0),(2X,:,F0.2),3(2X,:,F0.2)))' 
      endfor
      
      close, u1
      free_lun, u1
      
   endfor
   
endif

endif



if F110 then begin
   
   readcol, path3+'F110_clean.list', F110_list, format=('A'), /silent

   if f110_list[0] ne 'none' then begin

   template = 'cat_F110.cat'
   
   for idx=0, n_elements(F110_list)-1 do begin
      filename = F110_list[idx]
      floc = strpos(filename, '.fits', /reverse_search)
      rootn = strmid(filename, 0, floc)
      infile = rootn+'_xy_1.cat'
      outfile = rootn+'_1.cat'
      
                                ; read in the specific cat file
      readcol, path3+infile, xin, yin, format=('D,D'), skipline=1, /silent 
                                ; read in the general catalog file
                                ; we want a seperate header and columns
      
      OPENR,lun,path3+template,/get_lun
      header=strarr(15)
      readf,lun,header
      CLOSE,lun
      FREE_LUN,lun
      myformat=('L,D,D,D,D,D,D,D,D,D,D,D,D,D,D')
      readcol, path3+template, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15, skipline=15, /silent, format=myformat
      
      num = n_elements(x1)
      openw,u1,path3+outfile,/get_lun
      printf, u1, header
                                ; note the switch for columns 2 and 3 to xin and yin
      for idy=0, num-1 do begin
         printf, u1, x1[idy], xin[idy], yin[idy], x4[idy], x5[idy], x6[idy], x7[idy], x8[idy], x9[idy], x10[idy], x11[idy], x12[idy], x13[idy], x14[idy], x15[idy],FORMAT='((I0,10(2X,:,F0),(2X,:,F0.2),3(2X,:,F0.2)))' 
      endfor
      
      close, u1
      free_lun, u1
      
   endfor

endif
   
endif


end
