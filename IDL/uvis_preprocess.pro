;##############################################################
;# WISPIPE
;# Reduction Pipeline for the WISP program (originally by Hakim Atek)
;# uvis_preprocess deals with preparing the UVIS data for darks and CTE
;# Marc Rafelski 2013
;#
;# Updated 2014.08 by Sophia Dai
;# the averaged dark names are added to the header, rather than the smoothed darks
;# Updates 2015.02 by Marc Rafelski
;# Updates 2015.06 by Sophia Dai
;#                    added keyword single for the single UV band
;# Updates to use UVIS 2.0 data structure by Marc Rafelski
;# fields
;# Updates 2016.01 by Marc Rafelski added 'or prename eq '0'' to line 92
;###############################################################
; 

; If you specify /darksonly then it just checks which darks you
; need. Do this before running this in the pipeline to make sure you
; have processed the darks for the field beforehand!

; /nopostflash is for older data before postflash. (for running
; calwf3) : around Oct 29, 2012 before postflash was turned on (http://www.stsci.edu/hst/observatory/crds/SIfileInfo/WFC3/WFC3UVISdarks?no_wrap=true)

; You have to tell it if you want it to do a postflash dark in header

;;;; IF RUNNING AFTER OCTOBER 2015 - NEED TO MODIFY the check for post-flash dark

; Modified that now nocte still runs calwf3. Need to specify that
; seperately.

; use /uvis2 when processing data with the new headers from UVIS 2.0 -
; otherwise it will not work on newly downloaded data. 
; New default - use uvis2 and multiprocessor unless specify otherwise

; use /sp to run on a single processor, by default /mp is now called.
; use /olduvis to run it on data with old headers from UVIS 1.0 (pre UVIS 2.0)

;Example running this program:
;uvis_preprocess, 'Par358'

pro uvis_preprocess, field, darksonly=darksonly, tiger=tiger, calwf3only=calwf3only, nocte=nocte, nocalwf3=nocalwf3, mp=mp, nopostflash=nopostflash, uvis2=uvis2, olduvis=olduvis, sp=sp

; New default - use uvis2 and multiprocessor unless specify otherwise
  if not keyword_set(olduvis) then uvis2=1
  if not keyword_set(sp) then mp = 1

  
print, 'REMEMBER: If you are not in astroconda, you are not doing it right.'

path0 = expand_path('$WISPDATA')
pathc = expand_path('$WISPIPE')

path = path0+'/aXe/'
path_data = path0+'/data/'+field+"/"
droppath = pathc+'/aXe/'

if not keyword_set(calwf3only) then begin


if not keyword_set(darksonly) then begin
   spawn,'mkdir '+path_data+"UVIS"
   spawn,'mkdir '+path_data+"UVIS_orig"
   spawn,'cp '+droppath+'runcalwf3.py '+ path_data+'UVIS/'
endif

spawn,'ls -1 '+path_data+'*raw.fits',raw

;cal_ref_uvis, /auto, /smooth, /postflash

len=n_elements(raw)
darkfilearr = strarr(n_elements(raw))
filterlist = strarr(n_elements(raw))
rootarr =  strarr(n_elements(raw))
for i=0,len-1 do begin
  name=raw(i)
  h=headfits(name) 
  filter=strcompress(sxpar(h,'FILTER'),/remove_all)    
  filterlist[i] = filter
  EXPEND = double(strtrim(sxpar(h, 'EXPEND'),2))

  
  if (filter eq 'F475X' or filter eq 'F600LP' or filter eq 'F606W' or filter eq 'F814W' ) then begin 
     
     ; Store the original dark name for screen output
    dark=strmid(strcompress(sxpar(h,'DARKFILE'),/remove_all),5,13)
    ;darkfilearr[i] = dark
    darkfilearr[i] = read_dark_lookup(expend,smooth=smooth,postflash=postflash,avg=avg)

    if not keyword_set(darksonly) then begin

      ; Make a new name for the dark, and
      ; store it in the header so that
      ; calwf3 uses the new generated dark. 
       newdark = dark    
       prename = strmid(newdark, 0,1)
       ;;;;;; NOTE!!!!!! 
       ;;;;;; IF naming convention changes in WFC3 darks - you may
       ;;;;;; will need  to modify the naming convention for knowing
       ;;;;;; it has postflash darks

;       if (prename eq 'x' or prename eq 'y' or prename eq 'z') and newdark ne 'x2819400i_drk' then strput, newdark, 'p', 0 ; this is for the postflash darks
       if (prename eq 'x' or prename eq 'y' or prename eq 'z' or prename eq '0' or prename eq '1') and newdark ne 'x2819400i_drk' then strput, newdark, 'p', 0 ; this is for the postflash darks
       if newdark eq 'w971325mi_drk' or newdark eq 'w9k1521si_drk' or newdark eq 'wb81559si_drk' or newdark eq 'wb81559ri_drk' then strput, newdark, 'p', 0 ; this is for the few pre 2013 that have pf darks
       strput, newdark, 'a', 1                                ; this is for averaged darks (not smoothed darks)
       
       darkn = 'iref$'+newdark
       sxaddpar, h, 'DARKFILE', darkn
       modfits, name, 0, h
    endif

    root= strmid(name, 17, 9, /reverse_offset)
    rootarr[i] = root

    if not keyword_set(darksonly) then begin
       print,'copying '+root+'_raw.fits'+' to UVIS directory'
       
       ; we copy the raw and save the
       ; original  UVIS_orig/ since will delete the
       ; original after cte correction. This
       ; way the original file still exists

       spawn,'cp -a '+path_data+root+'_raw.fits'+' '+path_data+'UVIS/'
       print,'moving '+root+'_raw.fits'+' to UVIS_orig directory'
       spawn,'mv '+path_data+root+'_raw.fits'+' '+path_data+'UVIS_orig/'
       print,'moving '+root+'_trl.fits'+' to UVIS_orig directory'
       spawn,'mv '+path_data+root+'_trl.fits'+' '+path_data+'UVIS_orig/'
       print,'moving '+root+'_spt.fits'+' to UVIS_orig directory'
       spawn,'mv '+path_data+root+'_spt.fits'+' '+path_data+'UVIS_orig/'
       print,'moving '+'*_drz.fits'+' to UVIS_orig directory'
       spawn,'mv '+path_data+'*_drz.fits'+' '+path_data+'UVIS_orig/'
       print,'moving '+root+'_flt_hlet.fits'+' to UVIS_orig directory'
       spawn,'mv '+path_data+root+'_flt_hlet.fits'+' '+path_data+'UVIS_orig/'
       print,'moving '+root+'_flt.fits'+' to UVIS_orig directory'
       spawn,'mv '+path_data+root+'_flt.fits'+' '+path_data+'UVIS_orig/'

       print,'moving '+root+'_flc.fits'+' to UVIS_orig directory'
       spawn,'mv '+path_data+root+'_flc.fits'+' '+path_data+'UVIS_orig/'
       print,'moving '+'*_drc.fits'+' to UVIS_orig directory'
       spawn,'mv '+path_data+'*_drc.fits'+' '+path_data+'UVIS_orig/'



    endif

 endif

endfor

; Lets figure out which darks there are
; need to sort first, then use the uniq function on sorted array. That
; gives you the subscripts. 
darkfiles = darkfilearr[sort(darkfilearr)]
diffdark = uniq(darkfiles)

darksneeded = darkfiles[diffdark]
print, '---------------------------------------------------------'
print, 'Make sure you process the following darks (original names):'
print, darksneeded
print, '---------------------------------------------------------'

if not keyword_set(darksonly) and not keyword_set(nocte) then begin



; Now lets CTE correct the data
   whatuvis = where(filterlist eq 'F475X' or filterlist eq 'F600LP' or filterlist eq 'F606W' or filterlist eq 'F814W', numuvis)

   if numuvis gt 0 then begin
      ;uvisfiles = raw[whatuvis]
      uvisfiles = rootarr[whatuvis]+'_raw.fits'

      spawn, 'pwd', currdir
      cd, path_data+'UVIS/'
      

      for idx=0, n_elements(uvisfiles)-1 do begin
         print, 'Running wfc3uv_ctereverse.e on ', uvisfiles[idx]     

         if keyword_set(mp) then begin
            spawn, 'wfc3uv_ctereverse_parallel.e'  + ' ' + uvisfiles[idx]
         endif else begin
            spawn, 'wfc3uv_ctereverse.e'  + ' ' + uvisfiles[idx]
         endelse
      endfor


      
; Now lets remove old raw data, and rename rac data to raw   
;rac==raw cte corrected
      for idx=0, n_elements(uvisfiles)-1 do begin
         
         locrac =STRPOS(uvisfiles[idx], '_raw.fits')
         name = strmid(uvisfiles[idx],0,locrac)
         spawn, 'rm '+name+'_raw.fits'
         spawn, 'mv '+name+'_rac.fits '+ name+'_raw.fits'
         
      endfor
      
      cd, currdir

   
      print, '---------------------------------------------------------'
      print, 'Did you remember to process the following darks?'
      print, darksneeded
      print, '---------------------------------------------------------'
   endif
endif

endif

; Now lets run calwf3 on the new UVIS data.
; This generates the flt files needed for drizzling
if not keyword_set(darksonly) and not keyword_set(nocte) and not keyword_set(nocalwf3) then begin
   spawn,'cp '+droppath+'runcalwf3.py '+ path_data+'UVIS/'
   spawn,'cp '+pathc+'/IDL/cal_ref_uvis.pro '+ path_data+'UVIS/'
   spawn,'cp '+pathc+'/IDL/read_dark_lookup.pro '+ path_data+'UVIS/'
   cd,  path_data+'UVIS/'
   if not keyword_set(nopostflash) then begin
      cal_ref_uvis, /auto, /avg, /postflash, uvis2=uvis2
   endif else begin
      cal_ref_uvis, /auto, /avg, uvis2=uvis2
   endelse
   spawn, './runcalwf3.py'
endif

end
