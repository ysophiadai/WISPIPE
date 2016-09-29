;##############################################################
;# WISPIPE
;#
;# Purpose: Generate several drizzled images
;# Keywords: 
;#       both: if both grisms available
;#       uvis; if uvis data available
;# Calls: 
;# Input: 
;#       direct_list (of all the '_flt.fits' files)
;#       field
;#       path0: points to the directory with data--raw &
;#       pathc: points to the WISPIPE directory 
;# Output:
;#         move the tweak+drizzled direct & grism image to the DIRECT_GRISM folder
;#        
;#        
;# Created on 2014.11.07 by Sophia Dai to generate driz.py
;# Updated on 2015.02.24 by Sophia Dai
;# Last Updated on 2015.05.06 by Sophia Dai
;###############################################################

;===========================================     MAIN  ====================================================

pro new_drizprep_IB2,field,path0,f140only=f140only

  print, ' '
  print, 'XXXXXXXXXXXXXXXXXXX'
  print, "     drizprep"
  print, 'XXXXXXXXXXXXXXXXXXX'
  print, ' '
  
;path = '/Volumes/Kudo/DATA/WISPS/aXe/Par288-full/'
;drizprep,'Par288-full','/Volumes/Kudo/DATA/WISPS','~/WISPS/WISPIPE'


path = path0+'/aXe/'

path2 = path+field+"/"
path3=path2+'DATA/DIRECT_GRISM/'
path4=path2+'DATA/GRISM/'
path5=path2+'DATA/DIRECT/'

;    spawn,'cp '+path2+'DATA/DIRECT/*_flt_clean.fits '+path2+'DATA/DIRECT_GRISM/'   ;tweakreg corrected flt images
;    spawn,'cp '+path2+'DATA/GRISM/*_flt_clean.fits '+path2+'DATA/DIRECT_GRISM/'    ;tweakreg corrected flt images

;move drizzled direct & grism images to the DIRECT_GRISM folder
if not keyword_set(f140only) then   readcol,path3+'F110_clean.list',f110_list,format=('A')
   readcol,path3+'F140_clean.list',f140_list,format=('A')
if not keyword_set(f140only) then   readcol,path3+'F160_clean.list',f160_list,format=('A')
   readcol,path3+'G102_clean.list',g102_list,format=('A')
   readcol,path3+'G141_clean.list',g141_list,format=('A')

if not keyword_set(f140only) then begin
if f110_list[0] ne 'none' then begin
    spawn,'cp '+path2+'DATA/DIRECT/F110W_twk_drz.fits '+path2+'DATA/DIRECT_GRISM/F110W_drz.fits' 
    spawn,'cp '+path2+'DATA/DIRECT/F110W_twk_sci.fits '+path2+'DATA/DIRECT_GRISM/F110W_sci.fits'
    spawn,'cp '+path2+'DATA/DIRECT/F110W_twk_wht.fits '+path2+'DATA/DIRECT_GRISM/F110W_wht.fits' 
    spawn,'cp '+path2+'DATA/DIRECT/F110W_twk_rms.fits '+path2+'DATA/DIRECT_GRISM/F110W_rms.fits' 
 endif
if f160_list[0] ne 'none' then begin
    spawn,'cp '+path2+'DATA/DIRECT/F160W_twk_drz.fits '+path2+'DATA/DIRECT_GRISM/F160W_drz.fits' 
    spawn,'cp '+path2+'DATA/DIRECT/F160W_twk_sci.fits '+path2+'DATA/DIRECT_GRISM/F160W_sci.fits'
    spawn,'cp '+path2+'DATA/DIRECT/F160W_twk_wht.fits '+path2+'DATA/DIRECT_GRISM/F160W_wht.fits' 
    spawn,'cp '+path2+'DATA/DIRECT/F160W_twk_rms.fits '+path2+'DATA/DIRECT_GRISM/F160W_rms.fits' 
 endif
endif

if f140_list[0] ne 'none' then begin
    spawn,'cp '+path2+'DATA/DIRECT/F140W_twk_drz.fits '+path2+'DATA/DIRECT_GRISM/F140W_drz.fits' 
    spawn,'cp '+path2+'DATA/DIRECT/F140W_twk_sci.fits '+path2+'DATA/DIRECT_GRISM/F140W_sci.fits'
    spawn,'cp '+path2+'DATA/DIRECT/F140W_twk_wht.fits '+path2+'DATA/DIRECT_GRISM/F140W_wht.fits' 
    spawn,'cp '+path2+'DATA/DIRECT/F140W_twk_rms.fits '+path2+'DATA/DIRECT_GRISM/F140W_rms.fits' 
 endif


; xxxxxxxxxxxx REMOVED BY IVANO. xxxxxxxxxxxx
; There is no need and it is dangerous to copy these files (that do
; not exist anymore, anyway, after the modifications I made), into the DIRECT_GRISM
; folder. They would be overwritten by the solutions computed
; in G102_axe_20##.py and G141_axe_20##.py (now they are made by
; tweakprepgrism.py, so this wouldn't be an error anymore). If these two py programs
; do not work properly you would find the output files you
; expect.... but the wrong ones. 
;;;;;
;;;;;     if g102_list[0] ne 'none' then begin
;;;;;     spawn,'cp '+path2+'DATA/GRISM/G102_orig_drz.fits '+path2+'DATA/DIRECT_GRISM/G102_drz.fits' 
;;;;;     endif
;;;;;     if g141_list[0] ne 'none' then begin
;;;;;     spawn,'cp '+path2+'DATA/GRISM/G141_orig_drz.fits '+path2+'DATA/DIRECT_GRISM/G141_drz.fits' 
;;;;;     endif
;;;;;
; xxxxxxxxxxxx REMOVED BY IVANO. END xxxxxxxxxxxx


;CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
;  Added by Ivano 
;CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

; ERROR CORRECTED:
; the grism exposures were not copied inthe DIRECT_GRISM directory,
; In that directory, a different set of grism exposures were copied
; before this step. BUT THEY WERE NOT TWEAKREGED.
; The pipeline was working on images and grisms that were not
; tweakreged. 
; Now different copies of the same files but not tweakreged are
; NOT copied into DIRECT_GRISM before this step.
; AND we copy instead,  all the "clean" Files to DIRECT_GRISM after
; they are tweakreged. They will be used when creating the final
; stamps.

;G102
if g102_list[0] ne 'none' then begin
PP=0L
WHILE PP lt n_elements(g102_list) do begin
   print, '-------------------------------'
   print, 'GRISM 102 exposure copying'
   IF  FILE_TEST(path3+g102_list[PP]) gt 0 then print, 'WARNING: The old copy in the destination will be sobstituted'
   spawn,'cp '+path4+g102_list[PP]+' '+path3+g102_list[PP]
   print, 'Copying '+path4+g102_list[PP] +' to '+path3+g102_list[PP]

   spawn,'cp '+path4+'G102.fits'+' '+path3+'G102.fits'
   print, 'Copying '+path4+'G102.fits'+' to '+path3+'G102.fits'
   
   spawn,'cp '+path4+'G102_twk_twkpg_drz.fits'+' '+path3+'G102_drz.fits'
   print, 'Copying '+path4+'G102_twk_twkpg_drz.fits'+' to '+path3+'G102_drz.fits'
   spawn,'cp '+path4+'G102_twkpg_orig_scale_drz.fits'+' '+path3+'G102_orig_scale_drz.fits'
   print, 'Copying '+path4+'G102_twkpg_orig_scale_drz.fits'+' to '+path3+'G102_orig_scale_drz.fits'
PP=PP+1
ENDWHILE
endif

;G141
PP=0L
if g141_list[0] ne 'none' then begin
WHILE PP lt n_elements(g141_list) do begin
   print, '-------------------------------'
   print, 'GRISM 141 exposure copying '
   IF  FILE_TEST(path3+g141_list[PP]) gt 0 then print, 'WARNING: The old copy in the destination will be sobstituted'
   spawn,'cp '+path4+g141_list[PP]+' '+path3+g141_list[PP]
   print, 'Copying '+path4+g141_list[PP] +' to '+path3+g141_list[PP]
   spawn,'cp '+path4+'G141.fits'+' '+path3+'G141.fits'
   print, 'Copying '+path4+'G141.fits'+' to '+path3+'G141.fits'
   spawn,'cp '+path4+'G141_twk_twkpg_drz.fits'+' '+path3+'G141_drz.fits'
   print, 'Copying '+path4+'G141_twk_twkpg_drz.fits'+' to '+path3+'G141_drz.fits'
   spawn,'cp '+path4+'G141_twkpg_orig_scale_drz.fits'+' '+path3+'G141_orig_scale_drz.fits'
   print, 'Copying '+path4+'G141_twkpg_orig_scale_drz.fits'+' to '+path3+'G141_orig_scale_drz.fits'
PP=PP+1
ENDWHILE
endif

; DIRECT EXPOSURES

; F110
if f110_list[0] ne 'none' then begin
PP=0L
WHILE PP lt n_elements(f110_list) do begin
   print, '-------------------------------'
   print, 'DIRECT F110 exposure copying '
   IF  FILE_TEST(path3+f110_list[PP]) gt 0 then print, 'WARNING: The old copy in the destination will be sobstituted'
   spawn,'cp '+path5+f110_list[PP]+' '+path3+f110_list[PP]
   print, 'Copying '+path5+f110_list[PP] +' to '+path3+f110_list[PP]
PP=PP+1
ENDWHILE
endif

; F160
if f160_list[0] ne 'none' then begin
PP=0L
WHILE PP lt n_elements(f160_list) do begin
   print, '-------------------------------'
   print, 'DIRECT F160 exposure copying '
   IF  FILE_TEST(path3+f160_list[PP]) gt 0 then print, 'WARNING: The old copy in the destination will be sobstituted'
   spawn,'cp '+path5+f160_list[PP]+' '+path3+f160_list[PP]
   print, 'Copying '+path5+f160_list[PP] +' to '+path3+f160_list[PP]
PP=PP+1
ENDWHILE
endif

; F140
if f140_list[0] ne 'none' then begin
PP=0L
WHILE PP lt n_elements(f140_list) do begin
   print, '-------------------------------'
   print, 'DIRECT F140 exposure copying '
   IF  FILE_TEST(path3+f140_list[PP]) gt 0 then print, 'WARNING: The old copy in the destination will be sobstituted'
   spawn,'cp '+path5+f140_list[PP]+' '+path3+f140_list[PP]
   print, 'Copying '+path5+f140_list[PP] +' to '+path3+f140_list[PP]
PP=PP+1
ENDWHILE
endif

;CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC




end
