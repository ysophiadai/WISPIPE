#!/bin/bash
##############################################################
# WISPIPE
# Reduction Pipeline for the WISP program
# Hakim Atek 2009
# Modified by Marc Rafelski 2012
# Modified by Sophia Dai 2014,2015
# Modified by Ivano Baronchelli, 2016
# use findf.pro to check Q/A of flt before the pipeline
# use qacheck.pro to check Q/A of drz.fits after the pipeline
# use mastreadme.pro to prepare the tar file for mast delivery
# --> Call in bash using: > source ./wispipe_6.2.sh Par# >& log#.log
# --> DO NOT USE THIS OPTION (tcsh, csh): > source ./wispipe_6.2.sh Par# > & log#.log
###############################################################    



ur_setup
cd $WISPIPE/IDL/

idl<< EOF
.run process_IB2.pro
process_IB2, "$1","$WISPDATA","$WISPIPE"
.run cross_clean.pro
.run im_clean_IB6.pro
im_clean_IB6,"$1","$WISPDATA","$WISPIPE"
EOF



##########################################################################
# Before everything, wcs are updated on grism and direct
# exposures.
##########################################################################
cd $WISPDATA/aXe/$1/
python IR_updatewcs.py
##########################################################################


cd $WISPIPE/IDL/
idl<< EOF
.r tweakprep_IB1.pro
tweakprep_IB1,"$1","$WISPDATA"
EOF

##########################################################################
# Python code inserted for sky subtracion.
# The reason for which it is located between tweakprep.pro and
# tweakprep.py is that here the SExtractor catalog are already
# created but the wcs of grism and direct exposures are still
# the original ones  
##########################################################################
cd $WISPDATA/aXe/$1/
# cp $WISPIPE/aXe/fit_multi_sky.py .
cp $WISPIPE/PYTHON/fit_multi_sky.py .
python fit_multi_sky.py "$WISPIPE/aXe/CONFIG/grism_master_sky_v0.5/"
##########################################################################
# sky subtraction - END
##########################################################################


cd $WISPDATA/aXe/$1/DATA/DIRECT/
python tweakprep.py

cd $WISPIPE/IDL/
idl<< EOF
.r tweaksex_IB7.pro
tweaksex_IB7,"$1","$WISPDATA","$WISPIPE"
EOF
cd $WISPDATA/aXe/$1/DATA/DIRECT/
python tweakreg.py
##########            
cd $WISPIPE/IDL/
idl<< EOF
.r tweakprepgrism_IB6.pro
tweakprepgrism_IB6,"$1","$WISPDATA","$WISPIPE"
EOF

cd $WISPDATA/aXe/$1/DATA/GRISM/
python tweakprepgrism.py

cd $WISPIPE/IDL/
idl<< EOF
.r new_drizprep_IB2.pro
new_drizprep_IB2,"$1","$WISPDATA"
EOF


##########################################################################
## UVIS SPECIFIC CODES:
##########################################################################
## If no uvis data are present, the programs in this section will do
## nothing but rising some warnings like: "no uvis data found"
##########################################################################
cd $WISPDATA/aXe/$1/DATA/DIRECT_GRISM/
python driz.py      
cd $WISPDATA/aXe/$1/DATA/UVIS/
python uvis_updatewcs.py
# ////////////////////////////////////
cd $WISPIPE/IDL/
idl<< EOF
.run makeorder_A_IB2.pro
makeorder_A_IB2,"$1","$WISPDATA"
EOF
cd $WISPDATA/aXe/$1/DATA/UVIS/
python uvis_initial_driz.py # makes a temporary drz image (one per filter)
cd $WISPIPE/IDL/
idl<< EOF
.run uvis_initial_twk_IB2.pro
uvis_initial_twk_IB2,"$1","$WISPDATA","$WISPIPE"
EOF
cd $WISPDATA/aXe/$1/DATA/UVIS/
python uvis_initial_twk.py
cd $WISPIPE/IDL/
idl<< EOF
.run makeorder_B_IB2.pro
makeorder_B_IB2,"$1","$WISPDATA"
EOF
# ////////////////////////////////////
cd $WISPDATA/aXe/$1/DATA/UVIS/
python uvis_driz.py
##########################################################################
## UVIS SPECIFIC CODES END
##########################################################################




## FROM HERE FORTH, WORK ON DIRET_GRISM FOLDER (for both grism and direct
## exposures). BEFORE THIS LINE, INSTEAD, EVERY ELABORATION SHOULD BE
## PERFORMED ON DIRECT/ and GRISM/ folders !!ONLY!!
#--------------------------------------------------------------------------




cd $WISPIPE/IDL/
idl<< EOF
.run smooth_and_combine3.pro
smooth_and_combine3,"$1","$WISPDATA"
EOF
cd $WISPDATA/aXe/$1/DATA/DIRECT_GRISM/
python smooth_and_combine.py
cd $WISPIPE/IDL/
idl<< EOF
.run new_depth.pro
.run new_match_cat3.pro
.run new_seflag.pro
new_match_cat3,"$1","$WISPDATA"
EOF

idl<< EOF
.run ddread.pro
.run axeprep.pro
axeprep,"$1","$WISPDATA"
EOF


##########################################################################
# aXe codes for stamps extraction
##########################################################################
cd $WISPDATA/aXe/$1
python G102_axe_V6_2.py
python G141_axe_V6_2.py
##########################################################################


cd $WISPIPE/IDL/
idl<< EOF
.r rename_cat
rename_cat,"$1","$WISPDATA"
EOF


##########################################################################
# Zero order and first order identification. Region files for grism final
# images are created here.
# WISP_grism_region_files.py is written by Vihang Mehta
# usage:
# WISP_grism_region_files.py [-h] [-f FILTER] [-c CONFIG] [-p PAR_DIR] grism
##########################################################################
cd $WISPDATA/aXe/$1/
cp $WISPIPE/PYTHON/WISP_grism_region_files.py .
# ---------------------------------------------
filetest_G102="G102_drz.fits"
filetest_G141="G141_drz.fits"
# ---------------------------------------------
cd $WISPDATA/aXe/$1/DATA/DIRECT_GRISM/
if [ -f $filetest_G102 ]
then
    echo "======================================="
    echo "Extracting Zero-order regions for G102"
    echo "======================================="
    cd $WISPDATA/aXe/$1/
    python WISP_grism_region_files.py G102 -c "$WISPIPE/aXe/CONFIG/"
else
    echo "======================================="
    echo "WARNING: No observations found for G102"
    echo "======================================="  
fi
cd $WISPDATA/aXe/$1/DATA/DIRECT_GRISM/
if [ -f $filetest_G141 ]
then
    echo "======================================="
    echo "Extracting Zero-order regions for G141"
    echo "======================================="
    cd $WISPDATA/aXe/$1/
    python WISP_grism_region_files.py G141 -c "$WISPIPE/aXe/CONFIG/"
else
    echo "======================================="
    echo "WARNING: No observations found for G141"
    echo "======================================="  
fi    
##########################################################################

 
##########################################################################
# Fake program to prevent interruptions in case of errors. If the shell
# script finds make_pdf.sh, the error will not interrupt the reduction
# of other Par fields when they run in "make_pdf.sh"
# #########################################################################
cd $WISPDATA/aXe/$1/Plots
cp $WISPIPE/make_pdf.sh # Pdf plots are not made here!
##########################################################################


cd $WISPIPE/IDL/
idl<< EOF
.r new_wisp_extract_IB1.pro
new_wisp_extract_IB1,"$1",0,"$WISPDATA"
EOF

##########################################################################
# Using the Zero order region files written by WISP_grism_region_files.py
# It modifies the files.dat to update the Zeroth order column.
# written by Hugh Dickinson
##########################################################################
cd $WISPDATA/aXe/$1/
cp $WISPIPE/PYTHON/ProcessZerothOrders.py .
cp $WISPIPE/PYTHON/ZerothOrderWavelengthRanges.py .
python ProcessZerothOrders.py --verbose # --dryrun
##########################################################################

cd $WISPIPE/IDL/
idl<< EOF
.r plot_spectra.pro
plot_spectra,"$1",0,"$WISPDATA"
EOF


##########################################################################
# making single pdf file
##########################################################################
cd $WISPDATA/aXe/$1/Plots
source make_pdf.sh # written in wisp_extract.pro
rm spectra*.pdf
##########################################################################


##########################################################################
# making uvis helpfile
##########################################################################
cd $WISPDATA/aXe/$1/DATA/UVIS
cp $WISPIPE/PYTHON/make_uvis_helpfile_IB1.py .
python make_uvis_helpfile_IB1.py
##########################################################################
         

cd $WISPDATA/aXe/$1
tar -cvf "$1"_final_V6.1.tar G102_DRIZZLE G141_DRIZZLE Spectra Stamps DATA/DIRECT_GRISM/fin_*.cat DATA/DIRECT_GRISM/i*1.cat SEX/F*full.cat DATA/DIRECT_GRISM/*.reg DATA/DIRECT_GRISM/*drz.fits DATA/DIRECT_GRISM/*sci.fits DATA/DIRECT_GRISM/*rms.fits DATA/DIRECT_GRISM/*wht.fits DATA/DIRECT_GRISM/F*0.fits DATA/DIRECT_GRISM/G*.fits Plots/*.pdf DATA/UVIS/UVIS*.fits DATA/UVIS/UVIS*.list DATA/UVIS/*.txt DATA/UVIS/UVIStoIR DATA/UVIS/IRtoUVIS
gzip *.tar
         
         
         
         
         
         
         
         
