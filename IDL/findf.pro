;##############################################################
;# WISPIPE
;# Reduction Pipeline for the WISP program
;# Created by Sophia Dai 2014.06.11
;# Purpose: Q/A check on all the *flt.fits files
;# MR modified this to make it show both CCDs of the UVIS chip. 
;# MR modified this to have /uvis flag to chek in UVIS directory
;# NOTE: /uvis only checks uvis directory! So if you ran
;# uvis_preprocess first then you want to run this twice, e.g.:
; # findf, 'Par336', '$WISPDATA'
; # findf, 'Par336', '$WISPDATA', /UVIS
;# Input: 
;# Output:
;#         Display in ds9 of the *flt.fits files ordered by filters
;# Software called: ds9 command line
;# Example: 
;# cd  $PATH/WISPS/DATA/data2/WISPS/data/Par339a
;# idl   
;# > .r findf
;# > findf,"Par326"
;###############################################################

pro findf,field, path,clean=clean, ir=ir, uvis=uvis
;path_data = path0+'/data/'+field+"/"
if keyword_set(field) then cd,expand_path(path)+'/data/'+strtrim(field,2)
if keyword_set(field) and keyword_set(uvis) then cd,expand_path(path)+'/data/'+strtrim(field,2)+'/UVIS/'
spawn, 'ls -1 *flt*.fits', flt
print, flt
if keyword_set(clean) then spawn, 'ls -1 *flt_clean.fits', flt

next = 'n'

filterlist =['G102','G141','F110W','F140W','F160W','F475X','F600LP', 'F606W','F814W']
if keyword_set(clean) then filterlist =['G102','G141']

for j = 0, n_elements(filterlist)-1 do begin
if keyword_set(ir) then begin
   if filterlist[j] ne 'F110W' and filterlist[j] ne 'F140W' and filterlist[j] ne 'F160W' then goto,next
endif
          

   all = strarr(n_elements(flt))
   for idx=0, n_elements(flt)-1 do begin
      h=headfits(flt[idx])
      filter=strcompress(sxpar(h,'FILTER'),/remove_all)

if filter eq filterlist[j] then begin
print, filterlist[j], '   ', flt[idx]  
all[idx] = flt[idx]
endif
endfor



print,'Now displaying the *flt.fits files for filter: '+ filterlist[j]
goto,qacheck
         ;============= temporary check on stdev, median, and mean in a box ================
          m = where (all gt '0.fits')
          mean_g102 = fltarr(n_elements(m))
          median_g102 = fltarr(n_elements(m))
          stdev_g102 = fltarr(n_elements(m))
          for n = 0, n_elements(m)-1 do begin
             image = mrdfits(all[m[n]],1)
          mean_g102[n] = mean(image[676:719, 803:822])
          median_g102[n] = median(image[676:719, 803:822]) 
          stdev_g102[n] = stdev(image[676:719, 803:822])
       endfor
          print,'mean',mean_g102
          print,'median',median_g102
          print,'stdev',stdev_g102
qacheck:

             ;============= Q/A check of the flt files ================
              m = where (all gt '0.fits')
               allinone = all[m[0]]
              for mm = 1, n_elements(m)-1 do begin
                 allinone = allinone+' '+all[m[mm]]
              endfor
              if m[0] ne -1 then begin
                 spawn,'ds9 -zscale -zoom 0.25 '+allinone+' &'
                 ;print, 'ds9 -zscale -zoom 0.25 '+allinone+' &'
                 if filterlist[j] eq 'F475X' or filterlist[j] eq 'F600LP' or filterlist[j] eq 'F606W' or filterlist[j] eq 'F814W' then begin
                    splitallinone = strsplit(allinone, /extract)
                    for idx=0, n_elements(splitallinone)-1 do begin
                       splitallinone[idx]= splitallinone[idx]+'[4] '
                    endfor
                    allinone = strjoin(splitallinone)
                    spawn,'ds9 -zscale -zoom 0.25 '+allinone+'&'
                    ;print, 'ds9 -zscale -zoom 0.25 '+allinone+'&'
                 endif
              endif
              ;=============== end of Q/A check  =======================
;print, 'Click enter to continue: '
;read,next
next:
endfor
end
