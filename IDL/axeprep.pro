pro axeprep,field,path0
;##############################################################
;# WISPIPE
;# Reduction Pipeline for the WISP program (Atek et al. 2010)
;# Hakim Atek 2009
;# Edited by Sophia Dai 2014
;# Rewritten By Ivano Baronchelli 2016
;# Purpose: Prepare lists for aXedrizzle.
;#
;###############################################################

path = expand_path(path0)+'/aXe/'+field+"/"
path_data=path+'DATA/DIRECT_GRISM/'

spawn, 'ls -1 '+path+'DATA/DIRECT_GRISM/i*flt_clean.fits',all


;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; OBS CHECK 
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
J_OBS='NO'    ; NO or YES observations in the F110 band
H_OBS='NO'    ; NO, F140 or F160
G102_OBS='NO' ; NO or YES observations in the G102 grism
G141_OBS='NO' ; NO or YES observations in the G141 grism
f110_list='none'
f140_list='none'
f160_list='none'
g102_list='none'
g141_list='none'
;------------------------------------------------

TEST_J=file_test(path+'DATA/DIRECT/F110_clean.list',/zero_length)    ; 1 if exists but no content
TEST_JB=file_test(path+'DATA/DIRECT/F110_clean.list')                ; 1 if exists
TEST_H1=file_test(path+'DATA/DIRECT/F140_clean.list',/zero_length)   ; 1 if exists but no content
TEST_H1B=file_test(path+'DATA/DIRECT/F140_clean.list')               ; 1 if exists but
TEST_H2=file_test(path+'DATA/DIRECT/F160_clean.list',/zero_length)   ; 1 if exists but no content
TEST_H2B=file_test(path+'DATA/DIRECT/F160_clean.list')               ; 1 if exists
TEST_G102=file_test(path+'DATA/GRISM/G102_clean.list',/zero_length) ; 1 if exists but no content
TEST_G102B=file_test(path+'DATA/GRISM/G102_clean.list')             ; 1 if exists
TEST_G141=file_test(path+'DATA/GRISM/G141_clean.list',/zero_length) ; 1 if exists but no content
TEST_G141B=file_test(path+'DATA/GRISM/G141_clean.list')             ; 1 if exists



;     J      +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
IF TEST_J eq 0 and TEST_JB eq 1 then begin
   readcol,path+'DATA/DIRECT/F110_clean.list',f110_list,format=('A')
   if strlowcase(f110_list[0]) ne 'none' and n_elements(f110_list[0]) gt 0 then J_OBS='YES'
ENDIF
;     H      F140 / F160 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
IF TEST_H1 eq 0 and TEST_H1B eq 1 then begin
   readcol,path+'DATA/DIRECT/F140_clean.list',f140_list,format=('A')
   if strlowcase(f140_list[0]) ne 'none' and n_elements(f140_list[0]) gt 0 then H_OBS='F140'
ENDIF
IF TEST_H2 eq 0 and TEST_H2B eq 1 then begin
   readcol,path+'DATA/DIRECT/F160_clean.list',f160_list,format=('A')
   if strlowcase(f160_list[0]) ne 'none' and n_elements(f160_list[0]) gt 0 then H_OBS='F160'
ENDIF
;    G102    +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
IF TEST_G102 eq 0 and TEST_G102B eq 1 then begin
   readcol,path+'DATA/GRISM/G102_clean.list',g102_list,format=('A')
   if strlowcase(g102_list[0]) ne 'none' and n_elements(g102_list[0]) gt 0 then G102_OBS='YES'
ENDIF
;    G141    +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
IF TEST_G141 eq 0 and TEST_G141B eq 1 then begin
   readcol,path+'DATA/GRISM/G141_clean.list',g141_list,format=('A')
   if strlowcase(g141_list[0]) ne 'none' and n_elements(g141_list[0]) gt 0 then G141_OBS='YES'
ENDIF

print, 'axeprep'
print, 'HHHHHHHHHHHHHHHHH'
print, TEST_J,TEST_JB
print, TEST_H1,TEST_H1B
print, TEST_H2,TEST_H2B
print, TEST_G102, TEST_G102B
print, TEST_G141, TEST_G141B
print, 'J_OBS = '+J_OBS
print, 'H_OBS = '+H_OBS
print, 'G102_OBS = '+G102_OBS
print, 'G141_OBS = '+G141_OBS
print, 'HHHHHHHHHHHHHHHHH'

; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++






;=======================================================
;                    G102 GRISM                        =
;=======================================================
IF G102_OBS EQ 'YES' THEN BEGIN

 ; --------- direct image selection ---------------
 IF J_OBS EQ 'YES' THEN fimg_list=f110_list ; Priority G102 - F110 
 IF J_OBS EQ 'NO' AND H_OBS eq 'F140' THEN fimg_list=f140_list
 IF J_OBS EQ 'NO' AND H_OBS eq 'F160' THEN fimg_list=f160_list
 IF J_OBS EQ 'NO' AND H_OBS ne 'F140' AND H_OBS ne 'F160' THEN BEGIN
  PRINT, 'MAIN ERROR: No observations were found in any filter (axeprep) '
  stop
 ENDIF

 
 ;observation time of direct images
 ;****************************************  
 julian_img=dblarr(n_elements(fimg_list))

 for j=0,n_elements(fimg_list)-1 do begin
  name_img=path_data+fimg_list(j)       
  h_img=headfits(name_img)    
  time=sxpar(h_img,'TIME-OBS') 
  date=sxpar(h_img,'DATE-OBS') 
  time=double(strsplit(time,':',/extract))
  date=double(strsplit(date,'-',/extract))
  julian_img(j)=JULDAY(date[1],date[2],date[0],time[0],time[1],time[2])                             
 endfor

 ;match direct to grism images by matching the starting time
 ;****************************************** 
 sort_img=strarr(n_elements(g102_list))
 
 for i=0,n_elements(g102_list)-1 do begin       
  name_102=path_data+g102_list(i)       
  h_102=headfits(name_102)    
  time=sxpar(h_102,'TIME-OBS') 
  date=sxpar(h_102,'DATE-OBS') 
  time=double(strsplit(time,':',/extract))
  date=double(strsplit(date,'-',/extract))
  julian_102=JULDAY(date[1],date[2],date[0],time[0],time[1],time[2])

  ind_img=where(abs(julian_img - julian_102) eq min(abs(julian_img - julian_102)))
  sort_img(i)=fimg_list(ind_img[0])
 endfor
 
 ;catalog name list
 ;***********************************                 
 fimg_cat=strarr(n_elements(sort_img))

 for k=0,n_elements(sort_img)-1 do begin
  name_img=sort_img(k)
  tmp=strsplit(name_img,'.',/extract)
  root=tmp[0]
  fimg_cat(k)=" "+root+'_1.cat '       
 endfor

 ;print axeprep file
 ;********************
 forprint,g102_list,fimg_cat,sort_img,textout=path+'G102_axeprep.lis',/nocomment

ENDIF 




;=======================================================
;                    G141 GRISM                        =
;=======================================================
IF G141_OBS EQ 'YES' THEN BEGIN

 ; --------- direct image selection ---------------
 IF H_OBS eq 'F140' THEN fimg_list=f140_list ; Priority G141 - F140 or 160 
 IF H_OBS eq 'F160' THEN fimg_list=f160_list ; Priority G141 - F140 or 160
 IF H_OBS ne 'F140' AND H_OBS ne 'F160' AND J_OBS EQ 'YES' THEN fimg_list=f110_list
 IF J_OBS EQ 'NO' AND H_OBS ne 'F140' AND H_OBS ne 'F160' THEN BEGIN
  PRINT, 'MAIN ERROR: No observations were found in any filter (axeprep) '
  stop
 ENDIF

 ;observation time of direct images
 ;****************************************  
 julian_img=dblarr(n_elements(fimg_list))

 for j=0,n_elements(fimg_list)-1 do begin
  name_img=path_data+fimg_list(j)       
  h_img=headfits(name_img)    
  time=sxpar(h_img,'TIME-OBS') 
  date=sxpar(h_img,'DATE-OBS') 
  time=double(strsplit(time,':',/extract))
  date=double(strsplit(date,'-',/extract))
  julian_img(j)=JULDAY(date[1],date[2],date[0],time[0],time[1],time[2])                             
 endfor

 ;match direct to grism images
 ;******************************************       
 sort_img=strarr(n_elements(g141_list))
  
 for i=0,n_elements(g141_list)-1 do begin
  name_141=path_data+g141_list(i)       
  h_141=headfits(name_141)    
  time=sxpar(h_141,'TIME-OBS') 
  date=sxpar(h_141,'DATE-OBS') 
  time=double(strsplit(time,':',/extract))
  date=double(strsplit(date,'-',/extract))
  julian_141=JULDAY(date[1],date[2],date[0],time[0],time[1],time[2])

  ind_img=where(abs(julian_img - julian_141) eq min(abs(julian_img - julian_141)))
  sort_img(i)=fimg_list(ind_img[0])

 endfor

 ;catalog name list
 ;***********************************                 

 fimg_cat=strarr(n_elements(sort_img))
   
 for l=0,n_elements(sort_img)-1 do begin
  name_img=sort_img(l)
  tmp=strsplit(name_img,'.',/extract)
  root=tmp[0]
  fimg_cat(l)=" "+root+'_1.cat '       
 endfor 
   

 ;print axeprep file
 ;********************
 forprint,g141_list,fimg_cat,sort_img,textout=path+'G141_axeprep.lis',/nocomment

ENDIF


end
