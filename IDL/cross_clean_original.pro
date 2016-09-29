;##############################################################
;# WISPIPE
;# Reduction Pipeline for the WISP program (Atek et al. 2010)
;# Hakim Atek 2009
;# Last edited by Sophia Dai 2014.04.24
;# Purpose: Find the flt files and replace with the cross-cleaned map
;# (by define the sky, and cross values, and replace them with nearby
;# pixle values). But where does the 256, 304, 272 etc. and 8192 come from?)  
;#
;
;
;###############################################################
;===================================================================================================
function cross_clean,rootname

root=strsplit(rootname,'_',/extract)
dq=readfits(root[0]+'_ima.fits',exten_no=3,hdrdq)   ;*_ima.fits 1024*1024, 5 pixles at edge is reference overscan, so [5:1018] corresponds to the central 1014*1014

flt_1=readfits(rootname+'.fits',exten_no=1,hdr1)   ;*.fits 1014*1014, exten_no1 == *_sci
flt_dq=readfits(rootname+'.fits',exten_no=3,hdr3)  ;*.fits 1014*1014, exten_no3 == *_dq

replace=0
print,rootname+'.fits'

for i=6,1017,1 do begin   
   for j=6,1017,1 do begin

      if (((dq[i,j] eq 256)OR(dq[i,j] eq 304)OR(dq[i,j] EQ 272)or(dq[i,j] EQ 292)or(dq[i,j] EQ 260)or(dq[i,j] EQ 300)or(dq[i,j] EQ 48)or(dq[i,j] EQ 16)or(dq[i,j] EQ 32)or(dq[i,j] EQ 312))) then begin
        cross=mean([flt_1[i-5-1,j-5],flt_1[i-5+1,j-5],flt_1[i-5,j-5+1],flt_1[i-5,j-5-1]])
        sky=mean([flt_1[i-5-1,j-5+1],flt_1[i-5+1,j-5+1],flt_1[i-5-1,j-5-1],flt_1[i-5+1,j-5-1]])
      
        
        if (cross gt sky +3.*0.06  and dq[i,j] ge 256) then begin
             if (dq[i,j] eq 0) then flt_dq[i-5,j-5] =dq[i,j]-256
             if (dq[i-1,j] eq 0 or dq[i-1,j] eq 8192 ) then flt_dq[i-6,j-5] =dq[i,j]-256 & replace=replace+1
             if (dq[i+1,j] eq 0 or dq[i+1,j] eq 8192 ) then flt_dq[i-4,j-5] =dq[i,j]-256 & replace=replace+1
             if (dq[i,j-1] eq 0 or dq[i,j-1] eq 8192 ) then flt_dq[i-5,j-6] =dq[i,j]-256 & replace=replace+1
             if (dq[i,j+1] eq 0 or dq[i,j+1] eq 8192 ) then flt_dq[i-5,j-4] =dq[i,j]-256 & replace=replace+1

         
        endif

        if (cross gt sky +3.*0.06  and dq[i,j] lt 256) then begin
             if (dq[i,j] eq 0 ) then flt_dq[i-5,j-5] =dq[i,j]
             if (dq[i-1,j] eq 0 or dq[i-1,j] eq 8192 ) then flt_dq[i-6,j-5] =dq[i,j] & replace=replace+1
             if (dq[i+1,j] eq 0 or dq[i+1,j] eq 8192 ) then flt_dq[i-4,j-5] =dq[i,j] & replace=replace+1
             if (dq[i,j-1] eq 0 or dq[i,j-1] eq 8192 ) then flt_dq[i-5,j-6] =dq[i,j] & replace=replace+1
             if (dq[i,j+1] eq 0 or dq[i,j+1] eq 8192 ) then flt_dq[i-5,j-4] =dq[i,j] & replace=replace+1

        endif

     endif

;print,"Bad pixels =", replace
   endfor
endfor
output=fltarr(2,1014,1014)
output[0,*,*]=flt_1
output[1,*,*]=flt_dq
return,flt_dq

end
