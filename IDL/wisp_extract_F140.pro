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
;# updated by 
;# Sophia Dai 2014.05.06
;###############################################################

pro wisp_extract_F140,field,trim,path0

   path = path0+'/aXe/'+field+"/"

   readcol,path+'DATA/DIRECT_GRISM/cat_F140.cat',object,format=('I')
   len=n_elements(object)
   len_beam=n_elements(where(object lt 1000))   
   len_beam1=n_elements(where (object lt 2000 and object gt 1000))
   len_beam2=n_elements(where (object gt 2000)) 

ind1=where(object lt 2000 and object gt 1000)
ind2=where(object gt 2000)


   max=fix(len_beam/3) 
   rem=len_beam mod 3 
   if rem gt 0 then max=max+1
 
   max1=fix(len_beam1/3) 
   rem1=len_beam1 mod 3 
   if rem1 gt 0 then max1=max1+1 

   max2=fix(len_beam2/3) 
   rem2=len_beam2 mod 3 
   if rem2 gt 0 then max2=max2+1


for i=0, max-1 do begin; 6,9 in Par248 to test missing frames
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
                axe_sing_F140,field,beam,n,shift,trim,/save,path0
                shift=shift+1
             endfor
 device,/close
   set_plot,'X'

endfor


if (ind1[0] ne -1) then begin

for i=0,max1-1 do begin
     init=len_beam+1+(i*3)    

   set_plot, 'PS'
   DEVICE, /ENCAPSUL,/COLOR, XSIZE=20,YSIZE=28,/cm, $
           FILENAME=path+'Plots/spectra_1_'+strcompress(i,/remove_all)+'.eps'
       !P.MULTI = [0, 1,3]
            
;           loop on beams
             shift=0


             for n=init,init+2 < (len+len_beam1-1) do begin
                beam=object[n]
                Print,"Extraction BEAM ...............",beam
                axe_sing_F140,field,beam,n,shift,trim,/save,path0
                shift=shift+1 
             endfor
 device,/close
   set_plot,'X'

endfor
endif


print,len

if (ind2[0] ne -1) then begin

for i=0,max2-1 do begin
     init=len_beam+len_beam1+2+(i*3)    

   set_plot, 'PS'
   DEVICE, /ENCAPSUL,/COLOR, XSIZE=20,YSIZE=28,/cm, $
           FILENAME=path+'Plots/spectra_2_'+strcompress(i,/remove_all)+'.eps'
       !P.MULTI = [0, 1,3]
            
;           loop on beams
             shift=0
;stop
             for n=init,init+2 < (len-1) do begin
                beam=object[n]
                Print,"Extraction BEAM ...............",beam
                axe_sing_F140,field,beam,n,shift,trim,/save,path0
                shift=shift+1 
             endfor
 device,/close
   set_plot,'X'

endfor

endif

start:
spawn,'ls -1 '+path+'Plots/spectra_*.eps | sort -t "_" -n -k2,2 -k3,3 -k4,4 > '+path+'Plots/eps.list'
spawn,'gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile='+path+'Plots/'+field+'_spectra.pdf @'+path+'Plots/eps.list'
;spawn,'rm '+path+'Plots/spectra_*eps'


       
end
