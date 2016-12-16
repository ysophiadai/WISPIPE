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
GRISM ='G102'
print 'GRISM: '+GRISM
#===============================================
#===============================================
# Check direct filter to select the correct config file
if os.path.isfile("DATA/DIRECT_GRISM/F110W_drz.fits"):
    conf_file='G102.F110W.V4.32_WISP_6.1.conf'
else:
    if os.path.isfile("DATA/DIRECT_GRISM/F140W_drz.fits"):
        conf_file='G102.F140W.V4.32_WISP_6.1.conf'
    elif os.path.isfile("DATA/DIRECT_GRISM/F160W_drz.fits"):
        conf_file='G102.F160W.V4.32_WISP_6.1.conf'
    else:
        print "No direct image found"
        conf_file='none'
print '---------------------------------------------------------'
print 'Configuration file used: '+conf_file
print '---------------------------------------------------------'
#===============================================

def set_aXe_environment():
    print ''
    os.environ['AXE_IMAGE_PATH'] = './DATA/DIRECT_GRISM/'
    print '--> variable AXE_IMAGE_PATH   set to "./DATA/DIRECT_GRISM/"'

    # os.environ['AXE_CONFIG_PATH'] = '../CONFIG/'
    # print '--> variable AXE_CONFIG_PATH  set to "../CONFIG/"'
    os.environ['AXE_CONFIG_PATH'] = os.path.expandvars('$WISPIPE')+'aXe/CONFIG/'
    print '--> variable AXE_CONFIG_PATH  set to "'+os.path.expandvars('$WISPIPE')+'aXe/CONFIG/"'

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
    # aXe -- NOBACK -- DRIZZLE :
    #*****************************************************************************************
def aXe_noback_drizzle():

    # Running axeprep:
# =====================================

    print """
-->axeprep(inlist=GRISM+"_axeprep.lis", configs=conf_file,
		  backgr="NO", mfwhm="2.0", norm="NO")
    """
    time.sleep(5)
#   iraf.axeprep(inlist=GRISM+"_axeprep.lis", configs=conf_file,
#  	  backgr="YES",  backims="g102_master_sky_clean.fits", mfwhm="2.0",
#  	  norm="NO")
    # NEW VERSION: BACKGROUND SUBTRACTION REMOVED (IB Aug 2016)
    iraf.axeprep(inlist=GRISM+"_axeprep.lis", configs=conf_file,
		  backgr="NO", mfwhm="2.0", norm="NO")
   
    # Clean GRISM Images:
    # ============================   
    owd = os.getcwd()
    os.chdir('./DATA/DIRECT_GRISM/')
         
    if os.path.isfile("F110W_drz.fits"):
        iraf.fixpix(images="@F110_clean.list//[1]%'",masks=os.path.expandvars('$WISPIPE')+"aXe/CONFIG/bp_mask_v6.pl",linterp=1000,cinterp="INDEF")
        iraf.combine(input="@F110_clean.list//[1]%'",output="F110.fits",combine="median")
        print "F110.fits created"
    else:
        if os.path.isfile("F140W_drz.fits"):
            iraf.fixpix(images="@F140_clean.list//[1]%'",masks=os.path.expandvars('$WISPIPE')+"aXe/CONFIG/bp_mask_v6.pl",linterp=1000,cinterp="INDEF")
            iraf.combine(input="@F140_clean.list//[1]%'",output="F140.fits",combine="median")
            print "F140.fits created"
        else:
            if os.path.isfile("F160W_drz.fits"):
                iraf.fixpix(images="@F160_clean.list//[1]%'",masks=os.path.expandvars('$WISPIPE')+"aXe/CONFIG/bp_mask_v6.pl",linterp=1000,cinterp="INDEF")
                iraf.combine(input="@F160_clean.list//[1]%'",output="F160.fits",combine="median")
                print "F160.fits created"


#    iraf.fixpix(images="@F110_clean.list//[1]%'",masks=os.path.expandvars('$WISPIPE')+"aXe/CONFIG/bp_mask_v6.pl",linterp=1000,cinterp="INDEF")
#    iraf.combine(input="@F110_clean.list//[1]%'",output="F110.fits",combine="median")

############################################################
# This part is now done in tweakprepgrism.pro.
############################################################
####     iraf.fixpix(images="@G102_clean.list//[1]%'",masks="/Volumes/PROMISE_PEGASUS/DATA/WISPS/aXe/CONFIG/bp_mask_v5.pl",linterp=1000,cinterp="INDEF") # Removed v3 (done in tweakprepgrism.pro(py))
####     iraf.combine(input="@G102_clean.list//[1]%'",output="G102.fits",combine="median")                                                               # Removed v3 (done in tweakprepgrism.pro(py))
####     # # ORIGINAL Sophia Version
####     # astrodrizzle.AstroDrizzle("@G102_clean.list", output="G102",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=True,clean=True,preserve=False,final_scale=0.08,final_pixfrac=0.75)
####     # # Ivano first modification (updatewcs True --> False)
####     astrodrizzle.AstroDrizzle("@G102_clean.list", output="G102",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,final_scale=0.08,final_pixfrac=0.75) # Removed v3 (done in tweakprepgrism.pro(py))
####     astrodrizzle.AstroDrizzle("@G102_clean.list", output="G102_orig_scale",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False)                          # Removed v3 (done in tweakprepgrism.pro(py))
####     # # Ivano Second modification (skysub='False'; we don't want astrodrizzle to subtract the background from the astrodrizzled image. It is already subtracted before from single exposures. A Second astrodrizzle with the original scale is also performed)
####     # # DON'T USE THE NEXT SOLUTION... IT COMPLETELY FAILS for an unknown reason!
####     # astrodrizzle.AstroDrizzle("@G102_clean.list", output="G102",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,final_scale=0.08,final_pixfrac=0.75,skysub=False)
####     # astrodrizzle.AstroDrizzle("@G102_clean.list", output="G102_orig_scale",num_cores=5,final_wcs=True,final_wht_type="IVM",build=True,updatewcs=False,clean=True,preserve=False,skysub=False)
############################################################

    os.chdir(owd)

    # Running axecore:
    # ============================
    if os.path.isfile("F110W_drz.fits"):
        print """
        --> axecore(inlist=GRISM+"_axeprep.lis", configs=conf_file, back="NO",
        extrfwhm=9.0, backfwhm=3.0, drzfwhm=4.0,
	    slitless_geom="YES", orient="NO", exclude="NO", lambda_mark=1020.0,
	    cont_model="gauss", model_scale=1.0, inter_type="linear",
	    lambda_psf=1153.0, np=30, interp=1, smooth_length=0, smooth_fwhm=0.0,
        spectr="YES",  adj_sens="YES", weights="YES", sampling="drizzle")

        """
        time.sleep(5)
        iraf.axecore(inlist=GRISM+"_axeprep.lis", configs=conf_file, back="NO",
            extrfwhm=9.0, backfwhm=3.0, drzfwhm=4.0,
            slitless_geom="YES", orient="NO", exclude="NO", lambda_mark=1020.0,
            cont_model="gauss", model_scale=1.0, inter_type="linear",
            lambda_psf=1153.0, np=30, interp=1, smooth_length=0, smooth_fwhm=0.0,
            spectr="YES",  adj_sens="YES", weights="YES", sampling="drizzle")
    else:
        if os.path.isfile("F140W_drz.fits"):
            print """
            --> axecore(inlist=GRISM+"_axeprep.lis", configs=conf_file, back="NO",
            extrfwhm=9.0, backfwhm=3.0, drzfwhm=4.0,
            slitless_geom="YES", orient="NO", exclude="NO", lambda_mark=1020.0,
            cont_model="gauss", model_scale=1.0, inter_type="linear",
            lambda_psf=1392.0, np=30, interp=1, smooth_length=0, smooth_fwhm=0.0,
            spectr="YES",  adj_sens="YES", weights="YES", sampling="drizzle")

            """
            time.sleep(5)
            iraf.axecore(inlist=GRISM+"_axeprep.lis", configs=conf_file, back="NO",
                extrfwhm=9.0, backfwhm=3.0, drzfwhm=4.0,
                slitless_geom="YES", orient="NO", exclude="NO", lambda_mark=1020.0,
                cont_model="gauss", model_scale=1.0, inter_type="linear",
                lambda_psf=1392.0, np=30, interp=1, smooth_length=0, smooth_fwhm=0.0,
                spectr="YES",  adj_sens="YES", weights="YES", sampling="drizzle")
        else:
            print """
            --> axecore(inlist=GRISM+"_axeprep.lis", configs=conf_file, back="NO",
            extrfwhm=9.0, backfwhm=3.0, drzfwhm=4.0,
            slitless_geom="YES", orient="NO", exclude="NO", lambda_mark=1020.0,
            cont_model="gauss", model_scale=1.0, inter_type="linear",
            lambda_psf=1600.0, np=30, interp=1, smooth_length=0, smooth_fwhm=0.0,
            spectr="YES",  adj_sens="YES", weights="YES", sampling="drizzle")

            """
            time.sleep(5)
            iraf.axecore(inlist=GRISM+"_axeprep.lis", configs=conf_file, back="NO",
                extrfwhm=9.0, backfwhm=3.0, drzfwhm=4.0,
                slitless_geom="YES", orient="NO", exclude="NO", lambda_mark=1020.0,
                cont_model="gauss", model_scale=1.0, inter_type="linear",
                lambda_psf=1536.9, np=30, interp=1, smooth_length=0, smooth_fwhm=0.0,
                spectr="YES",  adj_sens="YES", weights="YES", sampling="drizzle")
            

    # Running drzprep:
    #=============================== 
    print """
--> tdrzprep inlist="GRISM_axeprep.lis" configs=conf_file
            opt_extr="YES" back="NO"
    """
    time.sleep(5)
    iraf.drzprep(inlist=GRISM+"_axeprep.lis", configs=conf_file,
                 opt_extr="YES", back="NO")
    

    # Running axedrizzle:
    # ==============================
    print """
--> axedrizzle(inlist=GRISM+"_axeprep.lis", configs=conf_file, infwhm=9.0,
                    outfwhm=4.0, back="NO", makespc="YES", opt_extr="YES",
                    adj_sens="YES")
    """
    time.sleep(5)
    iraf.axedrizzle(inlist=GRISM+"_axeprep.lis", configs=conf_file, infwhm=9.0,
                    outfwhm=4.0, back="NO", makespc="YES", opt_extr="YES",
                    adj_sens="YES")



    #***************************************************************************************** 
    #            aXe -- MAIN PROGRAMME
    #*****************************************************************************************
def main():

    #======================================================
    # Check direct filter to decide if proceed or not
    #======================================================
    if os.path.isfile("DATA/DIRECT_GRISM/G102_drz.fits"):
        
        # set the environmental variable
        set_aXe_environment()
        # check whether the user has saved the data
        #check_data_backup()
    
        # Running iolprep:
        owd = os.getcwd()
        #change dir to data path
        os.chdir('./DATA/DIRECT_GRISM/')
        
        if os.path.isfile("F110W_drz.fits"):
            print 'Extracting with F110W filter ............................' 
            iraf.iolprep(mdrizzle_image="F110W_drz.fits",input_cat="cat_F110.cat",useMdriz=False)
        else:
            if os.path.isfile("F140W_drz.fits"):
                print 'Extracting with F140W filter ............................' 
                iraf.iolprep(mdrizzle_image="F140W_drz.fits",input_cat="cat_F140.cat",useMdriz=False)
            else:
                if os.path.isfile("F160W_drz.fits"):
                    print 'Extracting with F160W filter ............................' 
                    iraf.iolprep(mdrizzle_image="F160W_drz.fits",input_cat="cat_F160.cat",useMdriz=False)
                    print "WARNING: The G102-F160 combination has never been tested."
                    
    
        #change dir back to original working directory (owd)
        os.chdir(owd) 
        aXe_noback_drizzle()
        
    else:
        print "==========================================="
        print "Field not covered by observations in grism "
        print " G102 or G102 astrodrizzled image not found"
        print "--- No operations executed by G102_axe! ---"
        print "==========================================="

    
main()


 
