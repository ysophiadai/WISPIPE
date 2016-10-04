;##############################################################
;# WISPIPE
;# Reduction Pipeline for the WISP program (Atek et al. 2010)
;# Hakim Atek 2009
;# Purpose: to acquire the pixel positions of selected beam
;#
;# Last Update: 2015.08.10 by Sophia Dai
;# changed the pet table from single flt file to the drizzld g102 file
;# to match the new pixel scale of the V5.0 pipeline
;###############################################################
pro beam_pet,field,beam,pet_a,pet_b,both=both, path0

  ;path="~/data2/WISPS/aXe/"+field+"/"
  path = expand_path(path0)+'/aXe/'+field+"/"
  g102_path=path+'G102_OUTPUT/'
  g141_path=path+'G141_OUTPUT/'
  beam_id=STRING(beam,Format='(I0.3)')+'A'
  pet_a=0

                    ;=======================================================
                    ;                    G102 GRISM                        =
                    ;=======================================================

                    if keyword_set(both) then begin 

    readcol,path+'G102_axeprep.lis',g102_list,format=('A'),/silent
    tmp_102=strsplit(g102_list[0],'.',/extract)
    root_102=tmp_102[0]
    g102_pet=g102_path+root_102+'_2.PET.fits'
 
   ; match beam_id to index
   ;**********************************************************
    fits_open,g102_pet, fcb    ;read beam names in SPEC          
    NEXTEN_pet=fcb.nextend
    pet_IDs=fcb.extname
    fits_close,fcb
    beam_ind1=where(pet_IDs EQ beam_id) 

   ;extract PET fields
   ;***********************************************
   ftab_ext,g102_pet,'N,P_X,P_Y,X,Y,DIST,XS,YS,LAMBDA',npixa,p_xa,p_ya,xa,ya,dista,xsa,ysa,p_lambdaa,EXTEN_NO=beam_ind1[0]
   pet_a=[[p_xa],[p_ya],[p_lambdaa]]
                    endif 
                    ;=======================================================
                    ;                    G141 GRISM                        =
                    ;=======================================================

    readcol,path+'G141_axeprep.lis',g141_list,format=('A'),/silent
    tmp_141=strsplit(g141_list[0],'.',/extract)
    root_141=tmp_141[0]
    g141_pet=g141_path+root_141+'_2.PET.fits'


   ; match beam_id to index
   ;**********************************************************
    fits_open,g141_pet, fcb    ;read beam names in SPEC          
    NEXTEN_pet=fcb.nextend
    pet_IDs=fcb.extname
    fits_close,fcb
    beam_ind2=where(pet_IDs EQ beam_id)


   ;extract PET fields
   ;***********************************************
   ftab_ext,g141_pet,'N,P_X,P_Y,LAMBDA',npixb,p_xb,p_yb,p_lambdab,EXTEN_NO=beam_ind2[0]
   pet_b=[[p_xb],[p_yb],[p_lambdab]]

end

