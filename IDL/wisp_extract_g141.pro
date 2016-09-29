;##############################################################
;# WISPIPE
;# Reduction Pipeline for the WISP program (Atek et al. 2010)
;# Hakim Atek 2009
;###############################################################
;# Purpose: to create the 1D spectra in a pdf file
;# Input: field 
;#        trim
;#        cat_F140.cat
;# procedure called: axe_sing
;# Output: plots in eps format generated in the /Plots directory, with
;#   /spectra_0_* for obj ID < 1000 (matched in both filters),
;#   /spectra_1_* for obj ID 1000-2000 (found in F110 but not F140 or F160)
;#   /spectra_2_* for obj ID > 2000 (found in F140 or F160 but not in F110)
;#         A pdf file with all the spectra plotted in one
;#         The extracted 1D spectra data of ascii format in the Spectra folder
;#         The extracted 2D grism cutout of fits format in the Stamps folder
;# 
;# updated by 
;# Sophia Dai 2015.02.20
;###############################################################


pro wisp_extract_g141,field,trim,path0
      
   path = path0+'/aXe/'+field+"/"


   readcol,path+'DATA/DIRECT_GRISM/F160_clean.list',f160_list,format=('A')
    
   if f160_list[0] ne 'none' then begin
      readcol,path+'DATA/DIRECT_GRISM/cat_F160.cat',object,format=('I')
   endif else begin
      readcol,path+'DATA/DIRECT_GRISM/cat_F140.cat',object,format=('I')
  endelse

   len=n_elements(object)      
   len_beam=len   


   max=fix(len_beam/3) 
   rem=len_beam mod 3 
   if rem gt 0 then max=max+1
 
  

for i=0,max-1 do begin
     init=i*3    

   set_plot, 'PS'
   DEVICE, /ENCAPSUL,/COLOR, XSIZE=20,YSIZE=28,/cm, $
           FILENAME=path+'Plots/spectra_0_'+strcompress(i,/remove_all)+'.eps'
       !P.MULTI = [0, 1,3]
            
;           loop on beams
             shift=0
             for n=init,init+2 < (len_beam-1) do begin
                beam=object[n]
                Print,"Extraction BEAM ...............",beam
                axe_sing_g141,field,beam,n,shift,trim,/save,path0
                shift=shift+1
             endfor
  device,/close
   set_plot,'X'

endfor


spawn,'ls -1 '+path+'Plots/spectra_*.eps | sort -t "_" -n -k2,2 -k3,3 -k4,4 > '+path+'Plots/eps.list'
spawn,'gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile='+path+'Plots/'+field+'_spectra.pdf @'+path+'Plots/eps.list'
;spawn,'rm '+path+'Plots/spectra_*eps'

end
