;##############################################################
;# WISPIPE
;# Reduction Pipeline for the WISP program (Atek et al. 2010)
;# Hakim Atek 2009
;# Purpose: 
;#       generate region files for direct images
;# Input:  
;#       cat_F*.cat in DIRECT_GRISM folder
;# Output:
;#       F*.reg
;#       G*.reg
;# Last edit: Sophia DAI 2015.5
;###############################################################
pro find_zo_F140,field, both=both,path0

path =  path0+'/aXe/'+field+"/"
;path="~/data2/WISPS/aXe/"+field+"/"


                    ;=======================================================
                    ;                    G102 GRISM                        =
                    ;=======================================================
k=0                 ;loop on individual frames in case of dithering

if keyword_set(both) then begin

;    read files and make region files for direct images  
;    *********************************************************** 
readcol,path+'G102_axeprep.lis',g102_list,f140cat_list,f140_list,format=('A,A,A'),/silent
g102_list=path+'DATA/DIRECT_GRISM/'+g102_list
f140cat_list=path+'DATA/DIRECT_GRISM/'+f140cat_list
f140_list=path+'DATA/DIRECT_GRISM/'+f140_list
readcol,path+'DATA/DIRECT_GRISM/cat_F140.cat',id,xt,yt,a,b,theta,ra,dec,ad,bd,pa,mag,/silent
;mk_regionfile,ra,dec,5,label=string(fix(id)),file=path+'DATA/DIRECT_GRISM/F140.reg'
mk_regionfile,ra,dec,5,label=string(fix(id)),file=path+'DATA/DIRECT_GRISM/F140-wcs.reg'
mk_regionfile_elip,xt,yt,2.*a,2.*b,theta,label=string(fix(id)),file=path+'DATA/DIRECT_GRISM/F140.reg',/image,color='magenta'


;readcol,f140cat_list[k],id,xt,yt,a,b,theta,ra,dec,ad,bd,pa,mag,format='I,d,d,d,d,d',/silent


;make region file with zero order and mask
;*******************************************
out_zerorder=strsplit(g102_list[k],'.',/extract)
openw,1,path+'DATA/DIRECT_GRISM/G102_0th.reg'
openw,3,path+'DATA/DIRECT_GRISM/G102_0th.txt'
openw,2,path+'DATA/DIRECT_GRISM/G102_1st.reg'
openw,4,path+'DATA/DIRECT_GRISM/G102_1st.txt'

for i=0,n_elements(xt)-1,1 do begin
;same scale in pipeline prior to 2015.2
;printf,1,xt[i]-259.176-(1.7154e-3)*xt[i]+1.5e-2*yt[i]-1.5,yt[i]-4.5,id[i],format='("circle(",(d8.2),",",(d8.2),",5) # font=''helvetica 12 bold'' text={",(i),"}")'
;printf,3,xt[i]-259.176-(1.7154e-3)*xt[i]+1.5e-2*yt[i]-1.5,yt[i]-4.5,id[i],mag(i)
;xc=round(xt[i]-259.176-(1.7154e-3)*xt[i]+1.5e-2*yt[i]-1.5-1.)
;yc=round(yt[i]-4.5-1.)
;new scale after 2015.2 --> expand by 1.6
printf,1,xt[i]-1.60318*(259.176+17)+(1.7154e-3)*xt[i]+(1.5e-2)*yt[i],yt[i]-1.60318*4.5,id[i],format='("circle(",(d8.2),",",(d8.2),",5) # font=''helvetica 12 bold'' text={",(i),"}")'
printf,3,xt[i]-1.60318*(259.176+17)+(1.7154e-3)*xt[i]+(1.5e-2)*yt[i],yt[i]-1.60318*4.5,id[i],mag(i)


; 1st ORDER
;******************************************
;same scale in pipeline prior to 2015.2
;if (mag(i) lt 23.5) then begin 
;printf,2,xt[i]+135,yt[i]+1,format='("box(",(d8.2),",",(d8.2),",184,8,0) # color=red")' 
;printf,2,xt[i]+135,yt[i]+8,id[i],format='("# text(",(d8.2),",",(d8.2),") color=magenta width=4 font=''helvetica 14 bold'' text={",(i),"}" )'
;endif else begin
;printf,2,xt[i]+135,yt[i]+1,format='("box(",(d8.2),",",(d8.2),",184,8,0) # color=cyan")' 
;printf,2,xt[i]+135,yt[i]+8,id[i],format='("# text(",(d8.2),",",(d8.2),") color=cyan width=2 font=''helvetica 14 bold'' text={",(i),"}" )'
;endelse
;printf,4,xt[i]+135,yt[i]+1,id[i]
;new scale --> expand by 1.6
if (mag(i) lt 23.5) then begin
printf,2,xt[i]+1.60318*135,yt[i]+1*1.60318,format='("box(",(d8.2),",",(d8.2),",294,8,0) # color=red")' 
printf,2,xt[i]+1.60318*135,yt[i]+8*1.60318,id[i],format='("# text(",(d8.2),",",(d8.2),") color=magenta width=4 font=''helvetica 14 bold'' text={",(i),"}" )'
endif else begin
printf,2,xt[i]+1.60318*135,yt[i]+1*1.60318,format='("box(",(d8.2),",",(d8.2),",294,8,0) # color=cyan")' 
printf,2,xt[i]+1.60318*135,yt[i]+8*1.60318,id[i],format='("# text(",(d8.2),",",(d8.2),") color=cyan width=2 font=''helvetica 14 bold'' text={",(i),"}" )'
endelse
printf,4,xt[i]+1.60318*135,yt[i]+1*1.60318,id[i]

endfor

printf,1,'line(751,0,767,1014) # line=0 0 color=white dash=1'
close,1,2,3,4

endif


;;;; There shouldn't be any issues with overwritting some of
;;;; these variables. However, if there is a bug, you could check to
;;;; make sure that these are overwritten properly. 

                    ;=======================================================
                    ;                    G141 GRISM                        =
                    ;=======================================================
                    j=0  ;loop on individual frames in case of dithering

;    read files and make region files for direct images  
;    *********************************************************** 
readcol,path+'G141_axeprep.lis',g141_list,f140cat_list,f140_list,format=('A,A,A'),/silent
g141_list=path+'DATA/DIRECT_GRISM/'+g141_list
f140cat_list=path+'DATA/DIRECT_GRISM/'+f140cat_list
f140_list=path+'DATA/DIRECT_GRISM/'+f140_list
readcol,path+'DATA/DIRECT_GRISM/cat_F140.cat',id,xt,yt,a,b,theta,ra,dec,ad,bd,pa,mag,/silent
;mk_regionfile,ra,dec,5,label=string(fix(id)),file=path+'DATA/DIRECT_GRISM/F140.reg'
; This is commented out because if you need G141 ONLY with F140, you
; should be running the G141 code, not the F140 code. 

                                ;  f140w=mrdfits(f140_list[j],1,hdr_f140)
                                ;  extast,hdr_f140,astr_f140

;readcol,f140cat_list[j],id,xt,yt,a,b,theta,ra,dec,ad,bd,pa,mag,format='d,d,d,d,d,d',/silent
                                ;  mask_141=mrdfits(g141_list[j],1,hdr_spectra_g141)*0. +1.d
                                ;  image=mrdfits(g141_list[j],1)




;make region file with zero order and mask
out_zerorder=strsplit(g141_list[j],'.',/extract)
openw,1,path+'DATA/DIRECT_GRISM/G141_0th.reg'
openw,3,path+'DATA/DIRECT_GRISM/G141_0th.txt'
openw,2,path+'DATA/DIRECT_GRISM/G141_1st.reg'
openw,4,path+'DATA/DIRECT_GRISM/G141_1st.txt'

;0st order
for i=0,n_elements(xt)-1,1 do begin
;same scale in pipeline prior to 2015.2
;printf,1,xt[i]-192.24-(0.0023144)*xt[i]+0.0111089*yt[i],yt[i],id[i],format='("circle(",(d8.2),",",(d8.2),",5)  # font=''helvetica 12 bold'' text={",(i),"}")'
;printf,3,xt[i]-192.24-(0.0023144)*xt[i]+0.0111089*yt[i],yt[i],id[i],mag(i)
;new scale --> expand by 1.6*
;new scale after 2015.8 --> expand by *1.60318
printf,1,xt[i]-1.60318*(192.24+10.5)-(0.0023144)*xt[i]+0.0111089*yt[i],yt[i],id[i],format='("circle(",(d8.2),",",(d8.2),",5)  # font=''helvetica 12 bold'' text={",(i),"}")'
printf,3,xt[i]-1.60318*(192.24+10.5)-(0.0023144)*xt[i]+0.0111089*yt[i],yt[i]-1,id[i],mag(i)

;1st order
;same scale in pipeline prior to 2015.2
;if (mag(i) lt 23) then begin
;printf,2,xt[i]+105,yt[i]+1,format='("box(",(d8.2),",",(d8.2),",184,8,0) # color=magenta")' 
;printf,2,xt[i]+105,yt[i]+8,id[i],format='("# text(",(d8.2),",",(d8.2),") color=magenta width=4 font=''helvetica 14 bold'' text={",(i),"}" )'
;endif else begin
;printf,2,xt[i]+105,yt[i]+1,format='("box(",(d8.2),",",(d8.2),",184,8,0) # color=cyan")' 
;printf,2,xt[i]+105,yt[i]+8,id[i],format='("# text(",(d8.2),",",(d8.2),") color=cyan width=2 font=''helvetica 14 bold'' text={",(i),"}" )'
;endelse
;printf,4,xt[i]+105,yt[i]+1,id[i]
;new scale --> expand by 1.6*
;new scale after 2015.8 --> expand by *1.60318
if (mag(i) lt 23) then begin
printf,2,xt[i]+1.60318*(105),yt[i]+1*1.60318,format='("box(",(d8.2),",",(d8.2),",294,8,0) # color=magenta")' 
printf,2,xt[i]+1.60318*(105),yt[i]+8*1.60318,id[i],format='("# text(",(d8.2),",",(d8.2),") color=magenta width=4 font=''helvetica 14 bold'' text={",(i),"}" )'
endif else begin
printf,2,xt[i]+1.60318*(105),yt[i]+1*1.60318,format='("box(",(d8.2),",",(d8.2),",294,8,0) # color=cyan")' 
printf,2,xt[i]+1.60318*(105),yt[i]+8*1.60318,id[i],format='("# text(",(d8.2),",",(d8.2),") color=cyan width=2 font=''helvetica 14 bold'' text={",(i),"}" )'
endelse
printf,4,xt[i]+1.60318*105,yt[i]+1*1.60318,id[i]

endfor
;printf,1,'line(819,0,831,1014) # line=0 0 color=white dash=1'
close,1,2,3,4



end
