pro axeprep,field,both=both,path0
;##############################################################
;# WISPIPE
;# Reduction Pipeline for the WISP program (Atek et al. 2010)
;# Hakim Atek 2009
;# Edited by Sophia Dai 2014
;# Purpose: Prepare lists for aXedrizzle.
;
;
;###############################################################

;path="~/data2/WISPS/aXe/"+field+"/"
path = expand_path(path0)+'/aXe/'+field+"/"
path_data=path+'DATA/DIRECT_GRISM/'

spawn, 'ls -1 '+path+'DATA/DIRECT_GRISM/i*flt_clean.fits',all





                    ;=======================================================
                    ;                    G102 GRISM                        =
                    ;=======================================================
        
if keyword_set(both) then begin

   readcol,path_data+'G102_clean.list',g102_list,format=('A')
   readcol,path_data+'F110_clean.list',f110_list,format=('A')         
   
          ;observation time of direct images
          ;****************************************  
          julian_110=dblarr(n_elements(f110_list))

          for j=0,n_elements(f110_list)-1 do begin
               name_110=path_data+f110_list(j)       
               h_110=headfits(name_110)    
               time=sxpar(h_110,'TIME-OBS') 
               date=sxpar(h_110,'DATE-OBS') 
               time=double(strsplit(time,':',/extract))
               date=double(strsplit(date,'-',/extract))
               julian_110(j)=JULDAY(date[1],date[2],date[0],time[0],time[1],time[2])                             
          endfor

          ;match direct to grism images by matching the starting time
          ;****************************************** 
          sort_110=strarr(n_elements(g102_list))
          
          for i=0,n_elements(g102_list)-1 do begin       
              name_102=path_data+g102_list(i)       
              h_102=headfits(name_102)    
              time=sxpar(h_102,'TIME-OBS') 
              date=sxpar(h_102,'DATE-OBS') 
              time=double(strsplit(time,':',/extract))
              date=double(strsplit(date,'-',/extract))
              julian_102=JULDAY(date[1],date[2],date[0],time[0],time[1],time[2])

               ind_110=where(abs(julian_110 - julian_102) eq min(abs(julian_110 - julian_102)))
               sort_110(i)=f110_list(ind_110[0])
            endfor
          
           ;catalog name list
           ;***********************************                 
           f110_cat=strarr(n_elements(sort_110))

            for k=0,n_elements(sort_110)-1 do begin
               name_110=sort_110(k)
               tmp=strsplit(name_110,'.',/extract)
               root=tmp[0]
               f110_cat(k)=" "+root+'_1.cat '       
            endfor

     ;print axeprep file
     ;********************
     forprint,g102_list,f110_cat,sort_110,textout=path+'G102_axeprep.lis',/nocomment

     
  endif



                    ;=======================================================
                    ;                    G141 GRISM                        =
                    ;=======================================================

readcol,path+'DATA/DIRECT_GRISM/F160_clean.list',f160_list,format=('A')
    

    if f160_list[0] ne 'none' then begin
                    ;=======================================================
                    ;            If F160 available using F160              =
                    ;=======================================================

    print,'preparing IOLs for F160 filter  ............................' 

readcol,path_data+'G141_clean.list',g141_list,format=('A')
readcol,path_data+'F160_clean.list',f160_list,format=('A')
 
          ;observation time of direct images
          ;****************************************  
          julian_160=dblarr(n_elements(f160_list))
 
          for j=0,n_elements(f160_list)-1 do begin
               name_160=path_data+f160_list(j)       
               h_160=headfits(name_160)    
               time=sxpar(h_160,'TIME-OBS') 
               date=sxpar(h_160,'DATE-OBS') 
               time=double(strsplit(time,':',/extract))
               date=double(strsplit(date,'-',/extract))
               julian_160(j)=JULDAY(date[1],date[2],date[0],time[0],time[1],time[2])                             
          endfor

          ;match direct to grism images
          ;******************************************       
           sort_160=strarr(n_elements(g141_list))
           
         for i=0,n_elements(g141_list)-1 do begin
              name_141=path_data+g141_list(i)       
              h_141=headfits(name_141)    
              time=sxpar(h_141,'TIME-OBS') 
              date=sxpar(h_141,'DATE-OBS') 
              time=double(strsplit(time,':',/extract))
              date=double(strsplit(date,'-',/extract))
              julian_141=JULDAY(date[1],date[2],date[0],time[0],time[1],time[2])

               ind_160=where(abs(julian_160 - julian_141) eq min(abs(julian_160 - julian_141)))
               sort_160(i)=f160_list(ind_160[0])

           endfor

           ;catalog name list
           ;***********************************                 
           
            f160_cat=strarr(n_elements(sort_160))
              
            for l=0,n_elements(sort_160)-1 do begin
               name_160=sort_160(l)
               tmp=strsplit(name_160,'.',/extract)
               root=tmp[0]
               f160_cat(l)=" "+root+'_1.cat '       
            endfor 
   

  ;print axeprep file
  ;********************
  forprint,g141_list,f160_cat,sort_160,textout=path+'G141_axeprep.lis',/nocomment



     endif else begin
                    ;=======================================================
                    ;            If F160 not available using F140          =
                    ;=======================================================
     print,'preparing IOLs for F140 filter  ............................' 


readcol,path_data+'G141_clean.list',g141_list,format=('A')
readcol,path_data+'F140_clean.list',f140_list,format=('A')
 
          ;observation time of direct images
          ;****************************************  
          julian_140=dblarr(n_elements(f140_list))
 
          for j=0,n_elements(f140_list)-1 do begin
               name_140=path_data+f140_list(j)       
               h_140=headfits(name_140)    
               time=sxpar(h_140,'TIME-OBS') 
               date=sxpar(h_140,'DATE-OBS') 
               time=double(strsplit(time,':',/extract))
               date=double(strsplit(date,'-',/extract))
               julian_140(j)=JULDAY(date[1],date[2],date[0],time[0],time[1],time[2])                             
          endfor

          ;match direct to grism images
          ;******************************************       
           sort_140=strarr(n_elements(g141_list))
           
         for i=0,n_elements(g141_list)-1 do begin
              name_141=path_data+g141_list(i)       
              h_141=headfits(name_141)    
              time=sxpar(h_141,'TIME-OBS') 
              date=sxpar(h_141,'DATE-OBS') 
              time=double(strsplit(time,':',/extract))
              date=double(strsplit(date,'-',/extract))
              julian_141=JULDAY(date[1],date[2],date[0],time[0],time[1],time[2])

               ind_140=where(abs(julian_140 - julian_141) eq min(abs(julian_140 - julian_141)))
               sort_140(i)=f140_list(ind_140[0])

           endfor

           ;catalog name list
           ;***********************************                 
           
            f140_cat=strarr(n_elements(sort_140))
              
            for l=0,n_elements(sort_140)-1 do begin
               name_140=sort_140(l)
               tmp=strsplit(name_140,'.',/extract)
               root=tmp[0]
               f140_cat(l)=" "+root+'_1.cat '       
            endfor 
   

  ;print axeprep file
  ;********************
  forprint,g141_list,f140_cat,sort_140,textout=path+'G141_axeprep.lis',/nocomment

  endelse


end
