import sys
import os,string,time
from pyraf import iraf
from iraf import proto, imred, ccdred
from iraf import stsdas, slitless, axe
from pyraf.irafpar import IrafParS

import drizzlepac
from drizzlepac import astrodrizzle
from pyraf.irafpar import IrafParS
from stsci.tools import teal
teal.unlearn("astrodrizzle")

#===============================================
GRISM ='G141'
print GRISM                                           
#===============================================

def set_aXe_environment():
    print ''
    os.environ['AXE_IMAGE_PATH'] = './DATA/DIRECT_GRISM/'
    print '--> variable AXE_IMAGE_PATH   set to "./DATA/DIRECT_GRISM/"'

    os.environ['AXE_CONFIG_PATH'] = '../CONFIG/'
    print '--> variable AXE_CONFIG_PATH  set to "../CONFIG/"'
    
    os.environ['AXE_OUTPUT_PATH'] = GRISM+'_OUTPUT/'
    print '--> variable AXE_OUTPUT_PATH  set to "GRISM_OUTPUT/"'
    
    os.environ['AXE_DRIZZLE_PATH'] = GRISM+'_DRIZZLE/'
    print '--> variable AXE_DRIZZLE_PATH set to "_GRISM_DRIZZLE/"'

def check_data_backup():
    dec = "N"
    print ''
    idec = IrafParS(['Did you save the images in "./DATA/"? [(y)es/(n)o] :(N)','string','h'],'whatever')
    idec.getWithPrompt()
    if len(string.strip(idec.value)) >0:
	dec = string.strip(idec.value)
    if dec.upper() == 'N':
	print """
	The grism image are modified during the aXe reduction
	Please keep a copy of the images in "./DATA" somewhere on
	your disk. Then you are able to repeat the test of aXe-1.7
	using the original input data.
	"""
	estring = 'axe.py: Data error!'
	raise Exception(estring)


   

    #***************************************************************************************** 
    # aXe -- NO BACK -- NO DRIZZLE :
    #*****************************************************************************************
def aXe_noback_nodrizzle():
   
    # Running axeprep:
    #=====================================
    print """
-->axeprep inlist="GRISM_axeprep.lis" configs="WFC3.IR.GRISM.V2.0.conf"
             backgr="NO" mfwhm="0.0 norm="NO" histogram="NO"
    """
    time.sleep(5)
    iraf.axeprep(inlist=GRISM+"_axeprep.lis", configs="WFC3.IR."+GRISM+".V2.0.conf",
		  backgr="YES", backims="F110_back.fits", mfwhm="0.0",
		  norm="NO")


    # Running axecore: 
    # ==================================
    print """
-->axecore inlist="GRISM_axesing.lis" configs="WFC3.IR.GRISM.SMOV.conf" 
           back="YES" extrfwhm=9.0 backfwhm=3.0 drzfwhm=4.0 slitless_geom="YES"
           orient="YES" exclude="NO" lambda_mark=1020.0 cont_model="gauss"
           model_scale=3.0 inter_type="linear" lambda_psf=980.0 np=30 interp=1
           smooth_length=0 smooth_fwhm=0.0 model_scale=5.0 inter_type="linear"
           spectr="YES" weights="NO" sampling="drizzle" adj_sens="YES"
    """
    time.sleep(5)
    iraf.axecore(inlist=GRISM+"_axeprep.lis", configs="WFC3.IR."+GRISM+".V2.0.conf", back="YES",
            extrfwhm=9.0, backfwhm=3.0, drzfwhm=4.0,
	    slitless_geom="YES", orient="NO", exclude="NO", lambda_mark=1410.0,
	    cont_model="gauss", model_scale=2.0, inter_type="linear",
	    lambda_psf=1392.0, np=30, interp=1, smooth_length=0, smooth_fwhm=0.0,
            spectr="YES",  adj_sens="YES", weights="YES", sampling="drizzle")
    
#            extrfwhm=2.0, backfwhm=4.0, drzfwhm=2.0,



    #***************************************************************************************** 
    # aXe -- NOBACK -- DRIZZLE :
    #*****************************************************************************************
def aXe_noback_drizzle_f140():

    # Running axeprep:
    # ============================
    print """
-->axeprep inlist="GRISM_axeprep.lis" configs="WFC3.IR.GRISM.SMOV.conf"
             backgr="NO" mfwhm="3.0" norm="NO" histogram="NO"
    """
    time.sleep(5)
    iraf.axeprep(inlist=GRISM+"_axeprep.lis", configs="WFC3.IR."+GRISM+".V2.0.conf",
		  backgr="YES",  backims="g141_master_sky_clean.fits", mfwhm="2.0",
		  norm="NO")


    # Clean GRISM Images:
    # ============================   
    owd = os.getcwd()
    os.chdir('./DATA/DIRECT_GRISM/') 
    iraf.fixpix(images="@G141_clean.list//[1]%'",masks="/Users/ydai/WISPIPE/aXe/CONFIG/bp_mask_v5.pl",linterp=1000,cinterp="INDEF")
    iraf.combine(input="@G141_clean.list//[1]%'",output="G141.fits",combine="median")
    iraf.fixpix(images="@F140_clean.list//[1]%'",masks="/Users/ydai/WISPIPE/aXe/CONFIG/bp_mask_v5.pl",linterp=1000,cinterp="INDEF")
    iraf.combine(input="@F140_clean.list//[1]%'",output="F140.fits",combine="median")
    astrodrizzle.AstroDrizzle("@G141_clean.list",output="G141",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.08,final_pixfrac=0.75)
    os.chdir(owd)
     
    # Running axecore:
    # ============================
    print """
-->axecore inlist="GRISM_axesing.lis" configs="WFC3.IR.G141.V2.0.conf" 
           back="YES" extrfwhm=9.0 backfwhm=3.0 drzfwhm=4.0 slitless_geom="YES"
           orient="YES" exclude="NO" lambda_mark=1410.0 cont_model="gauss"
           model_scale=3.0 inter_type="linear" lambda_psf=1392.0 np=30 interp=1
           smooth_length=0 smooth_fwhm=0.0 model_scale=5.0 inter_type="linear"
           spectr="YES" weights="YES" sampling="drizzle" adj_sens="YES"
    """
    time.sleep(5)
    iraf.axecore(inlist=GRISM+"_axeprep.lis", configs="WFC3.IR."+GRISM+".V2.0.conf", back="NO",
            extrfwhm=9.0, backfwhm=3.0, drzfwhm=4.0,
	    slitless_geom="YES", orient="NO", exclude="NO", lambda_mark=1410.0,
	    cont_model="gauss", model_scale=1.0, inter_type="linear",
	    lambda_psf=1392.0, np=30, interp=1, smooth_length=0, smooth_fwhm=0.0,
            spectr="YES",  adj_sens="YES", weights="YES", sampling="drizzle")
#            extrfwhm=3.0, backfwhm=3.0, drzfwhm=2.0,



    # Running drzprep:
    #=============================== 
    print """
-->tdrzprep inlist="GRISM_axeprep.lis" configs="WFC3.IR.G141.V2.0.conf"
            opt_extr="YES" back="NO"
    """
    time.sleep(5)
    iraf.drzprep(inlist=GRISM+"_axeprep.lis", configs="WFC3.IR."+GRISM+".V2.0.conf",
                 opt_extr="YES", back="NO")
    

    # Running axedrizzle:
    # ==============================
    print """
-->axedrizzle inlist="GRISM_axeprep.lis" configs="WFC3.IR.GRISM.V2.0.conf" opt_extr="YES"
               infwhm=9.0 outfwhm=4.0 back="NO" makespc="YES" opt_extr="YES"
    """
    time.sleep(5)
    iraf.axedrizzle(inlist=GRISM+"_axeprep.lis", configs="WFC3.IR."+GRISM+".V2.0.conf",
                    infwhm=9.0, outfwhm=4.0,
                    back="NO", makespc="YES", opt_extr="YES",adj_sens="YES")

 
  #***************************************************************************************** 
    # aXe -- NOBACK -- DRIZZLE :
    #*****************************************************************************************
def aXe_noback_drizzle_f160():

    # Running axeprep:
    # ============================
    print """
-->axeprep inlist="GRISM_axeprep.lis" configs="WFC3.IR.GRISM.V2.0.conf"
             backgr="NO" mfwhm="3.0 norm="NO" histogram="NO"
    """
    time.sleep(5)
    iraf.axeprep(inlist=GRISM+"_axeprep.lis", configs="WFC3.IR."+GRISM+".V2.0.conf",
		  backgr="YES",  backims="g141_master_sky_clean.fits", mfwhm="2.0",
		  norm="NO")

    # Clean GRISM Images:
    # ============================   
    owd = os.getcwd()
    os.chdir('./DATA/DIRECT_GRISM/') 
    iraf.fixpix(images="@G141_clean.list//[1]%'",masks="/Users/ydai/WISPIPE/aXe/CONFIG/bp_mask_v5.pl",linterp=1000,cinterp="INDEF")
    iraf.combine(input="@G141_clean.list//[1]%'", output="G141.fits",combine="median")
    iraf.fixpix(images="@F160_clean.list//[1]%'",masks="/Users/ydai/WISPIPE/aXe/CONFIG/bp_mask_v5.pl",linterp=1000,cinterp="INDEF")
    iraf.combine(input="@F160_clean.list//[1]%'",output="F160.fits",combine="median")
    astrodrizzle.AstroDrizzle("@G141_clean.list",output="G141",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,median=False,blot=False,driz_cr=False,final_scale=0.08,final_pixfrac=0.75)
    os.chdir(owd)
  
     # Running axecore:
    # ============================
    print """
-->axecore inlist="GRISM_axesing.lis" configs="WFC3.IR.GRISM.V2.0.conf" 
           back="YES" extrfwhm=9.0 backfwhm=3.0 drzfwhm=4.0 slitless_geom="YES"
           orient="YES" exclude="NO" lambda_mark=1410.0 cont_model="gauss"
           model_scale=3.0 inter_type="linear" lambda_psf=1536.9 np=30 interp=1
           smooth_length=0 smooth_fwhm=0.0 model_scale=5.0 inter_type="linear"
           spectr="YES" weights="YES" sampling="drizzle" adj_sens="YES"
    """
    time.sleep(5)
    iraf.axecore(inlist=GRISM+"_axeprep.lis", configs="WFC3.IR."+GRISM+".V2.0.conf", back="NO",
            extrfwhm=9.0, backfwhm=3.0, drzfwhm=4.0,
	    slitless_geom="YES", orient="NO", exclude="NO", lambda_mark=1410.0,
	    cont_model="gauss", model_scale=1.0, inter_type="linear",
	    lambda_psf=1536.9, np=30, interp=1, smooth_length=0, smooth_fwhm=0.0,
            spectr="YES",  adj_sens="YES", weights="YES", sampling="drizzle")




    # Running drzprep:
    #=============================== 
    print """
-->tdrzprep inlist="GRISM_axeprep.lis" configs="WFC3.IR.GRISM.V2.0.conf"
            opt_extr="YES" back="NO"
    """
    time.sleep(5)
    iraf.drzprep(inlist=GRISM+"_axeprep.lis", configs="WFC3.IR."+GRISM+".V2.0.conf",
                 opt_extr="YES", back="NO")
    


    # Running axedrizzle:
    # ==============================
    print """
-->axedrizzle inlist="GRISM_axeprep.lis" configs="WFC3.IR.GRISM.V2.0.conf" opt_extr="YES"
               infwhm=9.0 outfwhm=4.0 back="NO" makespc="YES" opt_extr="YES"
    """
    time.sleep(5)
    iraf.axedrizzle(inlist=GRISM+"_axeprep.lis", configs="WFC3.IR."+GRISM+".V2.0.conf", infwhm=9.0,
                    outfwhm=4.0, back="NO", makespc="YES", opt_extr="YES",
                    adj_sens="YES")

 
  #***************************************************************************************** 
    #            aXe -- MAIN PROGRAMME
    #*****************************************************************************************
def main():

    # set the environmental variable
    set_aXe_environment()

    # Running iolprep:
    owd = os.getcwd()
    #change dir to data path
    os.chdir('./DATA/DIRECT_GRISM/')

    f = open('F160.list', "r")
    text = f.read()
    print text[0:4]

    if text[0:4] == 'none': 
        print 'Extracting with F140W filter ............................' 
        #run task from data directory
        iraf.iolprep(mdrizzle_image="F140W_drz.fits",input_cat="cat_F140.cat")
        #change dir back to original working directory (owd)
        os.chdir(owd) 
        aXe_noback_drizzle_f140()
    else:
        print 'Extracting with F160W filter ............................'
        #run task from data directory
        iraf.iolprep(mdrizzle_image="F160W_drz.fits",input_cat="cat_F160.cat")
        #change dir back to original working directory (owd)
        os.chdir(owd) 
        aXe_noback_drizzle_f160()

main()

