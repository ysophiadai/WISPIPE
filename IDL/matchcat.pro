;dir=/Users/ydai/WISPIPE/IDL
;Purpose: quickly match 2 catalogs from different data reduction versions
;input:
;     parid: the Par id of the field
;generated : 2015.06.15
;update: 

pro matchcat,parid
  
;readcol,'/Volumes/Kudo/DATA/WISPS/aXe/Par94/DATA/DIRECT_GRISM/cat_F110.cat'$
  ;,id,xt,yt,a,b,theta,ra,dec,ad,bd,pa,mag,emag,class,flags,f='i,f,f,f,f,f,f,f,f,f,f,f,f,f,f'

;define the path for the old and new catalogs
  pathnew = '/Volumes/Kudo/DATA/WISPS/aXe/Par'+parid+'/DATA/DIRECT_GRISM/'
;  pathold = '/Volumes/Kudo/DATA/WISPS/aXe/aXe-pre20140421-hakim/ReducedFields/Par167_final/DATA/DIRECT_GRISM/'
  pathold = '/Volumes/Kudo/DATA/WISPS/aXe/aXe-pre20140421-marcar/Par'+parid+'/DATA/DIRECT_GRISM/'
  
  
  openw,1,'/Volumes/Kudo/DATA/WISPS/aXe/Par'+parid+'/linesmatch-v4.3-v5.0-par'+parid+'.txt',width=1000
  printf,1,'#  objID_old objID_new RA_old DEC_old RA_new DEC_new Mag_new'
;-------------- to generate a linesmatch.txt ---------------------
     readcol,pathold+'/fin_F110.cat',f='x,i,x,x,x,x,x,f,f',objidold,rao,deco
     readcol,pathnew+'/fin_F110.cat',f='x,i,x,x,x,x,x,f,f,x,x,x,f',objidnew,ran,decn,magn
     srcor,rao,deco,ran,decn,0.01,indo,indn
        for jj = 0, n_elements(indo)-1 do begin
           printf,1, objidold[indo[jj]], objidnew[indn[jj]],rao[indo[jj]],deco[indo[jj]],ran[indn[jj]],decn[indn[jj]],magn[indn[jj]]
       endfor
;-------------- done generating a linesmatch.txt ---------------------

end
