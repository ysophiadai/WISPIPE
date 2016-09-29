pro specmatch,parid=parid

path = '/Volumes/Kudo/DATA/WISPS/aXe/'

pars = ['Par9']

for j = 0, n_elements(pars)-1 do begin
   par= pars[j]
   openw,1,'/Volumes/Kudo/DATA/WISPS/aXe/versionmatch/ObjIDmatch-'+strtrim(par,2)+'.txt'
   printf,1,';par    objid_V4   objid_V5'

   if strmid(par,4,2) gt 200 then begin
      version = 4.4
      path2 = '/Volumes/Kudo/DATA/WISPS/aXe/aXe-pre20140421-marcar/'
   endif else begin
      version = 4.2
      path2 = '/Volumes/Kudo/DATA/WISPS/aXe/aXe-pre20140421-hakim/ReducedFields/'
   endelse
   

;-------------- to generate a linesmatch.txt ---------------------
     readcol,path+par+'/DATA/DIRECT_GRISM/cat_F110.cat',f='i,x,x,x,x,x,f,f',objidnew,ran,decn
     if version eq 4.4 then readcol,path2+par+'/DATA/DIRECT_GRISM/cat_F110.cat', f='i,x,x,x,x,x,f,f',objido,rao,deco
     if version eq 4.2 then readcol,path2+par+'_final/DATA/DIRECT_GRISM/fin_F110.cat', f='x,i,x,x,x,x,x,f,f',objido,rao,deco
srcor,rao,deco,ran,decn,0.01,indo,indn
     for j = 0, n_elements(indo)-1 do begin
           printf,1, par, objido[indo[j]], objidnew[indn[j]]
       endfor
;-------------- done generating a linesmatch.txt ---------------------
     endfor

close,1
end
