;##############################################################
;# WISPIPE
;# Reduction Pipeline for the WISP program (Atek et al. 2010)
;# Hakim Atek 2009
;###############################################################
;# Purpose: to create the 1D spectra in a pdf file
;# Input: field 
;#        trim
;#        cat_F110.cat (or 140 or 160)
;# procedure called: axe_sing
;# Output: plots in eps format generated in the /Plots directory, with
;#   /spectra_0_* for obj ID < 10000 (matched in both filters - dualimage mode),
;#   /spectra_1_* for obj ID 10000-20000 (detected F110 but not in dual image mode)
;#   /spectra_2_* for obj ID 20000-30000 (detected F140/160 but not dual image mode)
;#   /spectra_3_* for obj ID >30000 (detected in F110 and F140/160 but not dual image mode )
;#   A pdf file with all the spectra plotted in one
;# 
;# Completely rewritten by Ivano Baronchelli Sept. 2016
;# - Possible 30000 ID+ are saved in /spectra_2_*
;# - joinpy procedure is allowed to make an unique pdf file.
;#  This should be the default in mac-OS systems (why people should
;#  install something else?).
;# - Plots are removed when correspondent stamps do not exist or if
;#  less than a certain % is visible (not null values) 
;###############################################################


pro wisp_extract_IB1,field,trim, path0
      
path = expand_path(path0)+'/aXe/'+field+"/"


IF FILE_TEST(path+'DATA/DIRECT_GRISM/cat_F160.cat') eq 1 then catname=path+'DATA/DIRECT_GRISM/cat_F160.cat'
IF FILE_TEST(path+'DATA/DIRECT_GRISM/cat_F140.cat') eq 1 then catname=path+'DATA/DIRECT_GRISM/cat_F140.cat'
IF FILE_TEST(path+'DATA/DIRECT_GRISM/cat_F110.cat') eq 1 then catname=path+'DATA/DIRECT_GRISM/cat_F110.cat'

readcol,catname,object,format=('I')

max0=0L ; Number of files created (ID 0-10000)
max1=0L ; Number of files created (ID 10000-20000)
max2=0L ; Number of files created (ID 20000-30000)
max3=0L ; Number of files created (ID 30000+)

PAGE='CLOSED'

i=0L ; Page number (three plots per page)
n=0L ; Object number
while n lt n_elements(object) do begin
     shift=0
     RR=0L
     WHILE RR lt 3 do begin
; ################################################################################################################
          if n lt n_elements(object) then begin
             beam=object[n]
             if object[n] ge 0    and object[n] lt 10000 then car='0'
             if object[n] ge 10000 and object[n] lt 20000 then car='1'
             if object[n] ge 20000 and object[n] lt 30000 then car='2'
             if object[n] ge 30000 then car='3'
             IF object[n] eq 10000 then i=0
             IF object[n] eq 20000 then i=0
             IF object[n] eq 30000 then i=0
             Print,"Extraction BEAM ...............",beam
            ;/////////////////////////////////////////////////////////////////////////////////////////
            stpname_102=path+'G102_DRIZZLE/'+'aXeWFC3_G102_mef_ID'+strcompress(string(beam),/remove_all)+'.fits'
            stpname_141=path+'G141_DRIZZLE/'+'aXeWFC3_G141_mef_ID'+strcompress(string(beam),/remove_all)+'.fits'
            FRAC_102=0.
            FRAC_141=0.
            if file_test(stpname_102) eq 1 then begin
               sttp_102=mrdfits(stpname_102,1,HD_102)
               totpix_102=float(n_elements(sttp_102))
               Pok_102=float(n_elements(where(sttp_102 ne 0 and sttp_102 eq sttp_102)))  
               FRAC_102=Pok_102/totpix_102             
            endif

            if file_test(stpname_141) eq 1 then begin
               sttp_141=mrdfits(stpname_141,1,HD_141)
               totpix_141=float(n_elements(sttp_102))
               Pok_141=float(n_elements(where(sttp_141 ne 0 and sttp_141 eq sttp_141)))
               FRAC_141=Pok_141/totpix_141           
            endif

            YN='N'
            IF FRAC_102 gt 0.15 or FRAC_141 gt 0.15 THEN YN='Y'
            ;/////////////////////////////////////////////////////////////////////////////////////////

            if YN eq 'Y' then begin
               IF RR eq 0 or beam eq 10000 or beam eq 20000 or beam eq 30000 THEN BEGIN

                 ; Close previous file 
                  IF PAGE eq 'OPEN' then begin
                     device,/close
                     set_plot,'X'
                     PAGE='CLOSED'
                  ENDIF   
                 RR=0    ; Reset plot counting
                 i=i+1   ; change Page
                 shift=0 ; Return at the beginning of this page
                  ; open new file
                 set_plot, 'PS'
                 DEVICE, /ENCAPSUL,/COLOR, XSIZE=20,YSIZE=28,/cm,FILENAME=path+'Plots/spectra_'+car+'_'+strcompress(i,/remove_all)+'.eps'
                 !P.MULTI = [0,1,3]
                 PAGE='OPEN'
                 ; update maximum value
                 if object[n] ge 0 and object[n] lt 10000 then max0=max0+1
                 if object[n] ge 10000 and object[n] lt 20000 then max1=max1+1
                 if object[n] ge 20000 and object[n] lt 30000 then max2=max2+1
                 if object[n] ge 30000 then max3=max3+1
              ENDIF
               axe_sing_IB1,field,beam,n,shift,trim,/save,expand_path(path0)
               shift=shift+1
            endif

            if YN eq 'N' then begin
               axe_sing_IB1,field,beam,n,shift,trim,/save,expand_path(path0),/noplot
               RR=RR-1   
            endif
            
            RR=RR+1
         endif
; ################################################################################################################
    if n ge n_elements(object) then RR=9999    ; big number to exit
    n=n+1
    ENDWHILE


IF PAGE eq 'OPEN' then begin
device,/close
set_plot,'X'
PAGE='CLOSED'
ENDIF

  ; Convert eps --> pdf
  ; spawn,'pstopdf '+path+'Plots/spectra_'+car+'_'+strcompress(i,/remove_all)+'.eps'

endwhile



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;; MAKE SINGLE pdf file ;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



spawn,'ls -1 '+path+'Plots/spectra_*.eps | sort -t "_" -n -k2,2 -k3,3 -k4,4 > '+path+'Plots/eps.list'



;create pdf from all eps files

;PSTOPDF='gs'     ; USE GOSTSCRIPT
PSTOPDF='joinpy'  ; USE joinpy (default on mac OS)

if PSTOPDF eq 'gs' then begin
   spawn,'gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile='+path+'Plots/'+field+'_spectra.pdf @'+path+'Plots/eps.list'
endif


openw,1,path+'Plots/make_pdf.sh'
printf,1,'#!/bin/csh'
if PSTOPDF eq 'joinpy' then begin
;  spawn,'"/System/Library/Automator/Combine PDF Pages.action/Contents/Resources/join.py" -o '+path+'Plots/'+field+'_spectra.pdf *.pdf' ; DOESN'T work!
;   printf,1,'"/System/Library/Automator/Combine PDF Pages.action/Contents/Resources/join.py" -o '+path+'Plots/'+field+'_spectra.pdf *.pdf'
stringa='"/System/Library/Automator/Combine PDF Pages.action/Contents/Resources/join.py" -o '+path+'Plots/'+field+'_spectra.pdf'


EE=1L
WHILE EE le max0 DO BEGIN
; Convert eps --> pdf
spawn,'pstopdf '+path+'Plots/spectra_0_'+strcompress(EE,/remove_all)+'.eps'
stringa=stringa+' '+'spectra_0_'+strcompress(EE,/remove_all)+'.pdf'
EE=EE+1
ENDWHILE

EE=1L
WHILE EE le max1 DO BEGIN
; Convert eps --> pdf
spawn,'pstopdf '+path+'Plots/spectra_1_'+strcompress(EE,/remove_all)+'.eps'
stringa=stringa+' '+'spectra_1_'+strcompress(EE,/remove_all)+'.pdf'
EE=EE+1
ENDWHILE

EE=1L
WHILE EE le max2 DO BEGIN
; Convert eps --> pdf
spawn,'pstopdf '+path+'Plots/spectra_2_'+strcompress(EE,/remove_all)+'.eps'
stringa=stringa+' '+'spectra_2_'+strcompress(EE,/remove_all)+'.pdf'
EE=EE+1
ENDWHILE

EE=1L
WHILE EE le max3 DO BEGIN
; Convert eps --> pdf
spawn,'pstopdf '+path+'Plots/spectra_3_'+strcompress(EE,/remove_all)+'.eps'
stringa=stringa+' '+'spectra_3_'+strcompress(EE,/remove_all)+'.pdf'
EE=EE+1
ENDWHILE

printf,1,stringa

; PDF files will be removed ... but not now 
endif
close,1
free_lun,1


;remove eps files, to save space?  Don't do it to be safe
;spawn,'rm '+path+'Plots/spectra_*eps'

end
