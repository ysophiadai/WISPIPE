;##############################################################
;# WISPIPE
;# Reduction Pipeline for the WISP program (Atek et al. 2010)
;# Hakim Atek 2009
;# Edited by Sophia Dai 2014
;# Purpose: 
;#        This program locates the raw data, prepares lists and directories in
;#        the .../WISPS/aXe/ folder, and copies python programs to the
;#        designated directory.
;# Output:
;#        directory sturcture under aXe/Par#
;#        clean.list of the grism images to be cleaned
;#
;#    for keyword_set(uvis) add:
;#       cp pathc/aXe/tweakreg_uvis.py path0/aXe/$1/DATA/UVIS
;#       cp pathc/aXe/make_uvis_helpfile.py path0/aXe/$1/DATA/UVIS
;#    The above 2 commands removed from wispipe_uvis.sh
;#
;# 
;# 
;# Last update by Ivano Baronchelli Aug 2016
;# - grism and direct exposures are not copied in the DIRECT_GRISM
;# directory
;# - V1: tweakreg_uvis.py is not copied from the aXe folder anymore. Now
;#    this program is written by align_uvis.pro
;# - V2: In place of F600LP and F475X we call the filters
;#    with this new nomenclature:
;#    F475X  --> UVIS1 (idem for F475)
;#    F600LP --> UVIS2 (idem for F600)
;###############################################################
pro process_IB2,field,uvis=uvis, path0, pathc

;droppath="~/WISPIPE/aXe/" ; for copying files
;path="~/data2/WISPS/aXe/" ; This is where data will end up
;path_data='~/data2/WISPS/data/'+field+"/" ; this is where raw data are

droppath = pathc+'/aXe/'
path = path0+'/aXe/'
path_data = path0+'/data/'+field+"/"

spawn,'mkdir '+path+field
path2=path+field+"/"
path3=path2+'DATA/DIRECT_GRISM/'
print,"working in directory  ",path2

;spawn,'mkdir '+path_data+"UVIS"
;;;;; Removed this line - it shold not do that. MR 10/3/2016
spawn,'mkdir '+path2+"G102_OUTPUT"
spawn,'mkdir '+path2+"G102_DRIZZLE"
spawn,'mkdir '+Path2+"G141_OUTPUT"
spawn,'mkdir '+path2+"G141_DRIZZLE"
spawn,'mkdir '+path2+"Plots"
spawn,'mkdir '+path2+"Spectra"
spawn,'mkdir '+path2+"Stamps"
spawn,'mkdir '+path2+"DATA"
spawn,'mkdir '+path2+"DATA/DIRECT"
spawn,'mkdir '+path2+"DATA/GRISM"
spawn,'mkdir '+path2+"DATA/DIRECT_GRISM"

spawn,'cp -r '+droppath+'SEX '+path2
;spawn,'cp '+path+'G*_axeweb.par '+path2
;spawn,'cp '+droppath+'G*_axe_iol.py '+path2 ; this is only needed if using multidrizzle
spawn,'cp '+droppath+'G*_axe_F140.py '+path2 ; this is only needed for cycle 19 with 1 IR filter
spawn,'cp '+droppath+'G*_axe*.py '+path2
;spawn,'cp '+droppath+'iolprepmanual.py '+path2; this is no longer needed
;spawn,'cp '+path+'skysub/skysub_all*.cl '+path2+'DATA/GRISM/'


;spawn,'cp ~/WISPIPE/login.cl '+path2
;spawn,'cp ~/WISPIPE/login.cl '+path2+'DATA/GRISM/'
;spawn,'cp ~/WISPIPE/login.cl '+path2+'DATA/DIRECT_GRISM/'
;;;;; Removed these lines - it shold not do that. MR 10/3/2016


;for UVIS
spawn,'mkdir '+path2+"DATA/UVIS"
;spawn,'cp ~/WISPIPE/login.cl '+path2+'DATA/UVIS/'
;;;;; Removed these lines - it shold not do that. MR 10/3/2016
spawn,'mkdir '+path2+"DATA/UVIS/IRtoUVIS"
spawn,'mkdir '+path2+"DATA/UVIS/UVIStoIR"

spawn, 'ls -1 '+path_data+'*fits',all

len=n_elements(all)


;preparing GRISM and DIRECT images
;*********************************************
;move UVIS data to the UVIS directory
;===========================
for i=0,len-1 do begin
  name=all(i)
  h=headfits(name) 
  filter=strcompress(sxpar(h,'FILTER'),/remove_all)    
  if (filter eq 'F475X' or filter eq 'F600LP' or filter eq 'F606W' or filter eq 'F814W' ) then begin 
    print,'moving '+name+' to UVIS directory'
    spawn,'mv '+name+' '+path_data+'UVIS/'   
  endif 
endfor

spawn,'cp -r '+path_data+'UVIS '+path2+'DATA/' 
spawn, 'ls -1 '+path_data+'*flt.fits',all
spawn, 'ls -1 '+path_data+'*ima.fits',ima
spawn, 'ls -1 '+path_data+'*raw.fits',raw_all


len=n_elements(all)

;From the '_flt' files, copy G102/G141 to the DATA/GRISM directory,
;and F110W/F140W/F160W to the DATA/DIRECT directory
;===========================
next = 'next'

for i=0,len-1 do begin
  name=all(i)
  print,name
  h=headfits(name)    

; MODIFIED BY I.B. : exposures are not copyed in the DIRECT_GRISM
; folder at this point.
;   spawn,'cp '+all(i)+' '+path2+"DATA/DIRECT_GRISM/"  
   filter=strcompress(sxpar(h,'FILTER'),/remove_all)

       if (filter eq 'G102' or filter eq 'G141') then begin 
          print,"selecting GRISM images ......"
          spawn,'cp '+all(i)+' '+path2+"DATA/GRISM/"  
      endif

     if (filter eq 'F110W' or filter eq 'F140W' or filter eq 'F160W') then begin 
        print,"selecting DIRECT images ......"
        spawn,'cp '+all(i)+' '+path2+"DATA/DIRECT/"
        spawn,'cp '+ima(i)+' '+path2+"DATA/DIRECT/" 
     endif
 
endfor  

;  bp_mask=MRDFITS('~/Caltech/aXe/CONFIG/BP_mask.fits',0,/silent)
  spawn, 'ls -1 '+path2+'DATA/GRISM/i*flt.fits',grism_list
  grism_len=n_elements(grism_list)
  print,grism_list

  spawn, 'ls -1 '+path2+'DATA/DIRECT/i*flt.fits',direct_list
  direct_len=n_elements(direct_list)


;make filter lists
; path2=path+field+"/"
; path3=path2+'DATA/DIRECT_GRISM/'
;*****************************************************

openw,1,path3+'G102.list'
openw,2,path3+'G141.list'
openw,3,path3+'F110.list'
openw,4,path3+'F140.list'
openw,42,path3+'F160.list'
openw,5,path3+'G102_clean.list'
openw,6,path3+'G141_clean.list'
openw,7,path3+'F110_clean.list'
openw,8,path3+'F140_clean.list'
openw,9,path3+'F160_clean.list'
openw,11,path2+'DATA/UVIS/UVIS1.list'
openw,12,path2+'DATA/UVIS/UVIS2.list'
openw,13,path2+'DATA/UVIS/shift_UVIS1.list'
openw,14,path2+'DATA/UVIS/shift_UVIS2.list'

;*****************************************
xshift=strcompress(0,/remove_all)
yshift=strcompress(-11,/remove_all)
;****************************************
printf,13,'# units: pixels' 	    
printf,13,'# frame: output'  	    
printf,13,'# form: delta'	    
printf,13,'# refimage: UVIS1_drz.fits[1]'  

printf,14,'# units: pixels' 	    
printf,14,'# frame: output'  	    
printf,14,'# form: delta'	    
printf,14,'# refimage: UVIS1_drz.fits[1]' 

     for k=0,grism_len-1 do begin
        name=grism_list(k)
        h=headfits(name)
        filter=strcompress(sxpar(h,'FILTER'),/remove_all)
 
        name = strtrim(name, 2)
        foob = strpos(name, '/', /reverse_search)
        fooe = strpos(name, '.', /reverse_search)
 ;       fooe2 = strpos(name, '_', /reverse_search)
        foo = strmid(name, foob+1,fooe-foob-1)
        foo2 = foo+'.fits'
        foo3 = foo+'_clean.fits'

        if (filter eq 'G102' ) then begin  
           ;tmp=strsplit(name,'/',/extract)
           ;printf,1,tmp[8]
           ;tmp2=strsplit(tmp[8],'.',/extract)
           ;printf,5,tmp2[0]+'_clean.fits'
           ;print, tmp
           printf,1,foo2
           printf,5,foo3
       endif

       if (filter eq 'G141' ) then begin
          ;tmp=strsplit(name,'/',/extract)
          ;printf,2,tmp[8]
          ;tmp2=strsplit(tmp[8],'.',/extract)
          ;printf,6,tmp2[0]+'_clean.fits'
           printf,2,foo2
           printf,6,foo3
      endif

   endfor


   for l=0,direct_len-1 do begin
      name=direct_list(l)
      h=headfits(name)
      filter=strcompress(sxpar(h,'FILTER'),/remove_all)
print,filter
        name = strtrim(name, 2)
        foob = strpos(name, '/', /reverse_search)
        fooe = strpos(name, '.', /reverse_search)
;        fooe2 = strpos(name, '_', /reverse_search)
        foo = strmid(name, foob+1,fooe-foob-1)
        foo2 = foo+'.fits'
        foo3 = foo+'_clean.fits'

      if (filter eq 'F110W' ) then begin
         ;tmp=strsplit(name,'/',/extract)
         ;printf,3,tmp[8]
         ;tmp2=strsplit(tmp[8],'.',/extract)
         ;printf,7,tmp2[0]+'_clean.fits'
         printf,3,foo2
         printf,7,foo3
     endif

     if (filter eq 'F140W' ) then begin
        ;tmp=strsplit(name,'/',/extract)
        ;printf,4,tmp[8]
        ;tmp2=strsplit(tmp[8],'.',/extract)
        ;printf,8,tmp2[0]+'_clean.fits'
        printf,4,foo2
        printf,8,foo3
        printf,42,'none'
        printf,9,'none'
     endif
 
     if (filter eq 'F160W' ) then begin
        ;tmp=strsplit(name,'/',/extract)
        ;printf,42,tmp[8]
        ;tmp2=strsplit(tmp[8],'.',/extract)
        ;printf,9,tmp2[0]+'_clean.fits'
        printf,42,foo2
        printf,9,foo3
        printf,4,'none'
        printf,8,'none'
    endif

  endfor

     ; Prepare for UVIS Reductions  
     ;============================================= 
   if keyword_set(uvis) then begin
; spawn,'cp '+pathc+'/aXe/tweakreg_uvis.py '+path2+'DATA/UVIS' ; Removed by I.B. (now written in align_uvis.pro)
        spawn,'cp '+pathc+'/aXe/make_uvis_helpfile.py '+path2+'DATA/UVIS'
        spawn, 'ls -1 '+path2+'DATA/UVIS/*flt.fits',uvis_list
        for m=0,n_elements(uvis_list)-1 do begin
           name=uvis_list(m)
           h=headfits(name)
           filter=strcompress(sxpar(h,'FILTER'),/remove_all)   
  
           name = strtrim(name, 2)
           foob = strpos(name, '/', /reverse_search)
           fooe = strpos(name, '.', /reverse_search)
;        fooe2 = strpos(name, '_', /reverse_search)
           foo = strmid(name, foob+1,fooe-foob-1)
           foo2 = foo+'.fits'
           foo3 = foo+'_clean.fits'

            if (filter eq 'F475X' or filter eq 'F606W' ) then begin
               ;tmp=strsplit(name,'/',/extract)
               ;printf,11,tmp[8] 
               ;printf,13,tmp[8]+' '+xshift+' '+yshift+' 0'
               printf,11,foo2
               printf,13,foo2+' '+xshift+' '+yshift+' 0'
            endif

            if (filter eq 'F600LP' or filter eq 'F814W') then begin
               ;tmp=strsplit(name,'/',/extract)
               ;printf,12,tmp[8] 
               ;printf,14,tmp[8]+' '+xshift+' '+yshift+' 0'
               printf,12,foo2
               printf,14,foo2+' '+xshift+' '+yshift+' 0'
            endif

        endfor

     endif



close,1,2,3,4,5,6,7,8,9,42,11,12,13,14
free_lun,1,2,3,4,5,6,7,8,9,11,12,13,14
spawn, 'cp '+path3+'*list '+path2+'DATA/GRISM/' 
spawn, 'cp '+path3+'*list '+path2+'DATA/DIRECT/' 

; copy grism images
;****************************************************** 

  for j=0,grism_len-1 do begin
     name=grism_list(j)
     tmp=strsplit(name,'.',/extract)
     name_clean=tmp[0]+'_clean.fits'    
     spawn,'cp '+name+' '+name_clean

  endfor


spawn, 'ls -1 '+path2+'DATA/GRISM/i*flt_clean.fits',clean_list
forprint,clean_list,textout=path2+'DATA/GRISM/clean.list',/nocomment 



end




