;##############################################################
;# WISPIPE
;# 
;# Purpose: 
;#       to generate readme files for both the catalog & the 1dspectra files
;# input:  *_flt.fits files
;# keyword: spec, for spectra renaming to satisfy MAST requirements
;#          
;# output: readme files with the Par name
;#         zip file containing the folder
;# Created by Sophia DAI 2015.03.30
;###############################################################


pro mastreadme,spec=spec,output=output

m='external'

;i corresponds to the parid
for i = 3,200 do begin         ;174,200  nospec

   skiplist=[3,4,13,18,25,48,60,63,64,66,67,69,71,73,76,79,80,83,84,86,89,91,95,96,100,102,103,104,111,112,117,134,142,148,149,150,169,174,177,181,184,185,186,187,189,190,192,193,195,196,198]
   m = where (skiplist eq i)
   if m ne -1 then goto,skiptar
   
if keyword_set(spec) then goto,spec1
if keyword_set(output) then goto,spec2

spawn,'mkdir /Volumes/Kudo/DATA/MAST/MAST-DR-2015/par'+strtrim(i,2)
spawn,'mkdir /Volumes/Kudo/DATA/MAST/MAST-DR-2015/par'+strtrim(i,2)+'/1dspectra'

;from harddrive /Kudo
;-------Image files-------
spawn, 'rsync -a /Volumes/Kudo/DATA/WISPS/aXe/Par'+strtrim(i,2)+'/DATA/DIRECT_GRISM/F110W_drz.fits  /Volumes/Kudo/DATA/MAST/MAST-DR-2015/par'+strtrim(i,2)+'/hlsp_wisp_hst_wfc3_par'+strtrim(i,2)+'_f110w_v5.0_drz.fits'
spawn, 'rsync -a /Volumes/Kudo/DATA/WISPS/aXe/Par'+strtrim(i,2)+'/DATA/DIRECT_GRISM/F140W_drz.fits  /Volumes/Kudo/DATA/MAST/MAST-DR-2015/par'+strtrim(i,2)+'/hlsp_wisp_hst_wfc3_par'+strtrim(i,2)+'_f140w_v5.0_drz.fits'
spawn, 'rsync -a /Volumes/Kudo/DATA/WISPS/aXe/Par'+strtrim(i,2)+'/DATA/DIRECT_GRISM/F160W_drz.fits  /Volumes/Kudo/DATA/MAST/MAST-DR-2015/par'+strtrim(i,2)+'/hlsp_wisp_hst_wfc3_par'+strtrim(i,2)+'_f160w_v5.0_drz.fits'
spawn, 'rsync -a /Volumes/Kudo/DATA/WISPS/aXe/Par'+strtrim(i,2)+'/DATA/DIRECT_GRISM/G102_drz.fits   /Volumes/Kudo/DATA/MAST/MAST-DR-2015/par'+strtrim(i,2)+'/hlsp_wisp_hst_wfc3_par'+strtrim(i,2)+'_g102_v5.0_drz.fits'
spawn, 'rsync -a /Volumes/Kudo/DATA/WISPS/aXe/Par'+strtrim(i,2)+'/DATA/DIRECT_GRISM/G141_drz.fits   /Volumes/Kudo/DATA/MAST/MAST-DR-2015/par'+strtrim(i,2)+'/hlsp_wisp_hst_wfc3_par'+strtrim(i,2)+'_g141_v5.0_drz.fits'
;-------catalog files-------
spawn, 'rsync -a  /Volumes/Kudo/DATA/WISPS/aXe/Par'+strtrim(i,2)+'/DATA/DIRECT_GRISM/fin_F110.cat  /Volumes/Kudo/DATA/MAST/MAST-DR-2015/par'+strtrim(i,2)+'/hlsp_wisp_hst_wfc3_par'+strtrim(i,2)+'_f110w_v5.0_cat.txt'
spawn, 'rsync -a  /Volumes/Kudo/DATA/WISPS/aXe/Par'+strtrim(i,2)+'/DATA/DIRECT_GRISM/fin_F140.cat  /Volumes/Kudo/DATA/MAST/MAST-DR-2015/par'+strtrim(i,2)+'/hlsp_wisp_hst_wfc3_par'+strtrim(i,2)+'_f140w_v5.0_cat.txt'
spawn, 'rsync -a  /Volumes/Kudo/DATA/WISPS/aXe/Par'+strtrim(i,2)+'/DATA/DIRECT_GRISM/fin_F160.cat  /Volumes/Kudo/DATA/MAST/MAST-DR-2015/par'+strtrim(i,2)+'/hlsp_wisp_hst_wfc3_par'+strtrim(i,2)+'_f160w_v5.0_cat.txt'
;-------spectra files-------
;spawn, 'rsync -a  /Volumes/Kudo/DATA/WISPS/aXe/Par'+strtrim(i,2)+'/Spectra/Par'+strtrim(i,2)+'_BEAM_*.dat /Volumes/Kudo/DATA/MAST/MAST-DR-2015/par'+strtrim(i,2)+'/1dspectra'

spec1:
if keyword_set(spec) then spawn,'rm /Volumes/Kudo/DATA/MAST/MAST-DR-2015/par'+strtrim(i,2)+'/1dspectra/*.dat'
spawn, 'ls -1 /Volumes/Kudo/DATA/WISPS/aXe/Par'+strtrim(i,2)+'/Spectra/Par'+strtrim(i,2)+'_BEAM_*.dat', specid
               ;specid[j] = '/Volumes/Kudo/DATA/WISPS/aXe/Par1/Spectra/Par1_BEAM_72A.dat'
;   readcol,'/Volumes/Kudo/DATA/WISPS/aXe/Par'+strtrim(i,2)+'/DATA/DIRECT_GRISM/G141.list',g141_list,format=('A')
   filter='g102-g141'
   if  i eq 2 or  (i ge 21 and i le 25) or (i ge 28 and i le 32) or i eq 34 or i eq 35 or ( i ge 38 and i le 40) or $
      (i ge 44 and i le 47) or (i ge 50 and i le 54) or (i ge 56 and i le 59) or i eq 61 or i eq 70 or i eq 75 or $
      i eq 77 or i eq 82 or i eq 85 or i eq 88 or i eq 90 or i eq 92 or i eq 93 or (i ge 98 and i le 103) or $
      (i ge 105 and i le 113) or (i ge 116 and i le 200) $
      then filter='g141'
;bewteen Par 116 and 200
   if i eq 120 or i eq 131 or i eq 135 or i eq 136 or i eq 143 or i eq 146 or i eq 147 or i eq 167 or i eq 181 or i eq 183 or i eq 187 or i eq 189 or i eq 190 or i eq 192 or i eq 19 then filter='g102-g141'
   if  i eq 60 then filter='g102'

for j=0, n_elements(specid)-1 do begin
   readcol,specid[j], w,f,e,c,z,f='f,d,d,d,i',/silent
   parid = tostring(i)
   n0=strlen(parid)
   nstart=50+2*n0
   n1 = strlen(specid[j])
   nlen = n1-nstart-4-1   ;-1 added to remove A
   specid2=strmid(specid[j],nstart,nlen)
   if long(specid2) lt '10' then specid2='000'+specid2
   if long(specid2) lt '100' and long(specid2) ge '10' then specid2='00'+specid2
   if long(specid2) lt '1000' and long(specid2) ge '100' then specid2='0'+specid2
   FORPRINT,w,f,e,c,z,/silent,COMMENT='#     wave      flux            error           contam           zeroth' $
            ,TEXTOUT='/Volumes/Kudo/DATA/MAST/MAST-DR-2015/par'+strtrim(i,2)+'/1dspectra/hlsp_wisp_hst_wfc3_par'+strtrim(i,2)+'-'+specid2+'a_'+filter+'_v5.0_spec1d.dat'
endfor

spec0:

spawn, 'ls -1  /Volumes/Kudo/DATA/WISPS/aXe/Par'+strtrim(i,2)+'/DATA/DIRECT/*flt.fits', flt

ra_targ = dindgen(n_elements(flt))
dec_targ = dindgen(n_elements(flt))
dateobs = strarr(n_elements(flt))
timeobs = strarr(n_elements(flt))
expstart = dindgen(n_elements(flt))
expend = dindgen(n_elements(flt))
exptime = dindgen(n_elements(flt))

for idx=0, n_elements(flt)-1 do begin
h=headfits(flt[idx])
;hprint,h
;filter=strcompress(sxpar(h,'FILTER'),/remove_all)
;if filter eq 'F110W' then print, flt[idx]
ra_targ[idx]  = strcompress(sxpar(h,'RA_TARG'),/remove_all)
dec_targ[idx]  = strcompress(sxpar(h,'DEC_TARG'),/remove_all)
dateobs[idx] = strcompress(sxpar(h,'DATE-OBS'),/remove_all)
timeobs[idx] =  strcompress(sxpar(h,'TIME-OBS'),/remove_all)
expstart[idx] = strcompress(sxpar(h,'EXPSTART'),/remove_all)
EXPEND[idx] = strcompress(sxpar(h,'EXPEND'),/remove_all)
EXPTIME[idx] = sxpar(h,'EXPTIME')
endfor

if keyword_set(spec) then goto,spec2

openw, lun, '/Volumes/Kudo/DATA/MAST/MAST-DR-2015/par'+strtrim(i,2)+'/supplement_readme_par'+strtrim(i,2)+'_catalog_header.txt',/get_lun
printf,lun,'#TELESCOP=         HST                / telescope used to acquire data'                 
printf,lun,'#INSTRUME=         WFC3/IR               / instrument used to acquire data'                              
printf,lun,'#RA_TARG =  '+string(min(ra_targ))+' / right ascension of target (deg) (J2000) '       
printf,lun,'#DEC_TARG=  '+string(min(dec_targ))+' / declination of target (deg) (J2000) '              
printf,lun,'#DATE-OBS=         '+min(dateobs)+'    / UT date of start of first exposure'             
printf,lun,'#TIME-OBS=         '+min(timeobs)+'      / UT start time of first exposure  '              


spec2:
spawn, 'ls -1  /Volumes/Kudo/DATA/WISPS/aXe/Par'+strtrim(i,2)+'/DATA/GRISM/*flt.fits', flt

ra_targ = dindgen(n_elements(flt))
dec_targ = dindgen(n_elements(flt))
dateobs = strarr(n_elements(flt))
timeobs = strarr(n_elements(flt))
expstart = dindgen(n_elements(flt))
expend = dindgen(n_elements(flt))
exptime = dindgen(n_elements(flt))
filter = strarr(n_elements(flt))

for idx=0, n_elements(flt)-1 do begin
h=headfits(flt[idx])
;hprint,h
;filter=strcompress(sxpar(h,'FILTER'),/remove_all)
;if filter eq 'F110W' then print, flt[idx]
ra_targ[idx]  = strcompress(sxpar(h,'RA_TARG'),/remove_all)
dec_targ[idx]  = strcompress(sxpar(h,'DEC_TARG'),/remove_all)
dateobs[idx] = strcompress(sxpar(h,'DATE-OBS'),/remove_all)
timeobs[idx] =  strcompress(sxpar(h,'TIME-OBS'),/remove_all)
expstart[idx] = strcompress(sxpar(h,'EXPSTART'),/remove_all)
EXPEND[idx] = strcompress(sxpar(h,'EXPEND'),/remove_all)
EXPTIME[idx] = sxpar(h,'EXPTIME')
filter[idx]=strcompress(sxpar(h,'FILTER'),/remove_all)
endfor
m1=where(filter eq 'G102')
m2=where(filter eq 'G141')

openw, lun2, '/Volumes/Kudo/DATA/MAST/MAST-DR-2015/par'+strtrim(i,2)+'/1dspectra/1dspectra_par'+strtrim(i,2)+'_readme.txt',/get_lun
printf,lun2,'1D Spectra Header:'
printf,lun2,'                                                        '    
printf,lun2,'   // DATA DESCRIPTION KEYWORDS'
printf,lun2,'#TELESCOP =        HST'
printf,lun2,'#INSTRUME =        WFC3/IR'
printf,lun2,'#FILTER   =        MULTI'
if m1[0] ne -1 then begin
   printf,lun2,'#FILTER[0] =       G102'
   printf,lun2,'#FILTER[1] =       G141'
endif
if m1[0] eq -1 then printf,lun2,'#FILTER[0] =       G141'
printf,lun2,'#TARGNAME =        MULTI'
printf,lun2,'#RA_TARG  = '+string(min(ra_targ))+' / right ascension of target (deg) (J2000) '       
printf,lun2,'#DEC_TARG = '+string(min(dec_targ))+' / declination of target (deg) (J2000) '              
printf,lun2,'                                                        '    

printf,lun2,'       // DATE AND TIME KEYWORDS'
printf,lun2,'#DATE-OBS =           '+string(min(dateobs))+'    / UT date of start of first exposure'             
printf,lun2,'#TIME-OBS =           '+string(min(timeobs))+'      / UT start time of first exposure  '              
printf,lun2,'#EXPTIME  =           1'
if m1[0] ne -1 then begin
   printf,lun2,'#EXPNUM1  =           '+strtrim(n_elements(flt[m1]),2)+'             / Total number of exposures for G102 filter'
   printf,lun2,'#EXPNUM2  =           '+strtrim(n_elements(flt[m2]),2)+'             / Total number of exposures for G141 filter'
endif
if m1[0] eq -1 then printf, lun2, '#EXPNUM  =            '+strtrim(n_elements(flt[m2]),2)+'             / Total number of exposures for G141 filter'
printf,lun2,'#EXPSTART =    '+string(min(expstart))+'     / start time of observation, or first exposure if composite [MJD]'
printf,lun2,'#EXPEND   =    '+string(max(expend))+'     / end time of observation, or last exposure if composite [MJD]'
printf,lun2,'#EXPDEFN  =           SUM'
if m1[0] ne -1 then begin
   printf,lun2,'#EXPSUM1  =    '+string(total(exptime[m1]))  +'     / total exposure time in seconds for G102 filter'
   printf,lun2,'#EXPSUM2  =    '+string(total(exptime[m2]))  +'     / total exposure time in seconds for G141 filter'
endif
if m1[0] eq -1 then printf,lun2,'#EXPSUM   =    '+string(total(exptime[m2]))  +'     / total exposure time in seconds for G141 filter'
printf,lun2,'                                                        '    
printf,lun2,'                                                        '    

printf,lun2,'       // For Tabular Spectra: FITS BINARY/ ASCII TABLE EXTENSION KEYWORDS'
printf,lun2,'#XTENSION=   ASCIITABLE               '
printf,lun2,'#BITPIX  =   8                             '    
printf,lun2,'#NAXIS   =   2                /Binary table                  '                  
printf,lun2,'#NAXIS1  =   1152000          /Number of bytes per row      '                   
printf,lun2,'#NAXIS2  =   1                /Number of rows              '                    
printf,lun2,'#PCOUNT  =   0                /Random parameter count     '                     
printf,lun2,'#GCOUNT  =   1                /Group count               '                      
printf,lun2,'#TFIELDS =   5                /Number of columns        '                       
printf,lun2,'#EXTNAME =   txt              /Extension name                           '
printf,lun2,'#EXTNO   =   1                /Extension number           '                     
printf,lun2,'#TFORM1  = 64000E             /Real*4 (floating point)           '            
printf,lun2,'#TTYPE1  = WAVE               /Column 1: Wavelength             '               
printf,lun2,'#TUNIT1  = Angstroms          /Units of column 1               '                
printf,lun2,'#TFORM2  = 64000D             /Real*8 (double precision)      '                   
printf,lun2,'#TTYPE2  = FLUX               /Column 2: Flux Density        '                  
printf,lun2,'#TUNIT2  = erg/s/cm^2/A       /Units of column 2            '                   
printf,lun2,'#TFORM3  = 64000D             /Real*8 (double precision)   '                      
printf,lun2,'#TTYPE3  = ERROR              /Column 3: Photometric Error'                     
printf,lun2,'#TUNIT3  = erg/s/cm^2/A       /Units of column 3         '                      
printf,lun2,'#TFORM4  = 64000D             /Real*8 (double precision)'                       
printf,lun2,'#TTYPE4  = CONTAM             /Column 4: Contamination '                         
printf,lun2,'#TUNIT4  = erg/s/cm^2/A       /Units of column 4  '
printf,lun2,'#TFORM5  = 64000E             /Real*4 (floating point)'                       
printf,lun2,'#TTYPE5  = ZEROTH             /Column 5: Zeroth order, 0:no contamination, 1: contamination from zeroth order, 2: edge truncation'                         
printf,lun2,'#UNIT5   = unitless           /Units of column 5 '
printf,lun2,'#'
printf,lun2,'#COMMENT = Delivered to MAST from the WISP survey'
printf,lun2,'#END    '

if not keyword_set(spec) and not keyword_set(output) then free_lun,lun
free_lun,lun2
;spawn,'cp /Volumes/Kudo/DATA/MAST/MAST-DR-2015/par'+strtrim(i,2)+'/1dspectra/1dspectra_par'+strtrim(i,2)+'_readme.txt /Volumes/Kudo/DATA/MAST/MAST-DR-2015/'
;goto,skiptar
spawn,'tar -cvf /Volumes/Kudo/DATA/MAST/MAST-DR-2015/wisp-par'+strtrim(i,2)+'.tar /Volumes/Kudo/DATA/MAST/MAST-DR-2015/par'+strtrim(i,2)
skiptar:
endfor
end
