#!/bin/bash
##############################################################
# WISPIPE
# Reduction Pipeline for the WISP program
# Hakim Atek 2009
# Modified by Marc Rafelski 2012,2016
# Modified by Sophia Dai 2014,2015
# Modified by Ivano Baronchelli, 2016
# Run when UVIS data is present instead of wispipe.sh
# use findf.pro to check Q/A of flt before the pipeline
# use qacheck.pro to check Q/A of drz.fits after the pipeline
# use mastreadme.pro to prepare the tar file for mast delivery
# -- NO (use bash, not csh!) --> Call in csh:  ./wispipe_uvis.sh Par# > & log#.log
# -- Call in bash using: source ./wispipe_uvis_F140.sh Par# >& log#.log
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

#               #A1

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

#               #A2
  
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
   
 #               #A3
 
cd $WISPDATA/aXe/$1/DATA/DIRECT/
python tweakprep.py

cd $WISPIPE/IDL/
idl<< EOF
.r tweaksex_IB7.pro
tweaksex_IB7,"$1","$WISPDATA","$WISPIPE"
EOF
cd $WISPDATA/aXe/$1/DATA/DIRECT/
python tweakreg.py

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

# -------  A  ---------
 

##########################################################################
## UVIS SPECIFIC CODES
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


# -------  B  ---------

      
####################################################################################
 # FROM HERE FORTH, WORK ON DIRET_GRISM FOLDER (for both grism and direct exposures)
 # BEFORE THIS LINE, INSTEAD, EVERY ELABORATION SHOULD BE PERFORMED ON DIRECT and
 # GRISM folders ONLY
####################################################################################

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
axeprep,"$1",/both,"$WISPDATA"
EOF

# -------  C  ---------

##########################################################################
# aXe codes for stamps extraction
##########################################################################
cd $WISPDATA/aXe/$1
python G102_axe_V6_1.py # (update_wcs=no in last grism astrodrizzle AND no Background subtraction, no grism drizzle, new config)
python G141_axe_V6_1.py # (update_wcs=no in last grism astrodrizzle AND no Background subtraction, no grism drizzle, new config files)
##########################################################################

# -------  D  ---------

cd $WISPIPE/IDL/
idl<< EOF
.run mk_region_direct_IB1.pro
mk_region_direct_IB1,"$1","$WISPDATA"
.r rename_cat.pro
rename_cat,"$1","$WISPDATA"
EOF


##########################################################################
# Zero order and first order identification. Region files for grism final
# images are created here.
# Written by Vihang Mehta
##########################################################################
cd $WISPDATA/aXe/$1/
cp $WISPIPE/PYTHON/WISP_grism_region_files.py .
python WISP_grism_region_files.py G102 -c "$WISPIPE/aXe/CONFIG/"
python WISP_grism_region_files.py G141 -c "$WISPIPE/aXe/CONFIG/"
#usage: WISP_grism_region_files.py [-h] [-f FILTER] [-c CONFIG] [-p PAR_DIR] grism
##########################################################################

# -------  E  ---------

##########################################################################
# Fake program to prevent interruptions in case of errors. If the shell
# script finds make_pdf.sh, the error will not interrupt the reduction
# of other Par fields when they run in "make_pdf.sh"
# #########################################################################
cd $WISPDATA/aXe/$1/Plots
cp $WISPIPE/make_pdf.sh . # Fake program to prevent interruptions in case of errors
##########################################################################

cd $WISPIPE/IDL/
idl<< EOF
.r beam_pet.pro 
.r axe_sing_IB1.pro
.r wisp_extract_IB1.pro
wisp_extract_IB1,"$1",0,"$WISPDATA"
EOF

##########################################################################
# making single pdf file
##########################################################################
cd $WISPDATA/aXe/$1/Plots
source make_pdf.sh # written in wisp_extract.pro
rm spectra*.pdf
##########################################################################

# -------  F  ---------

##########################################################################
# Using the Zero order region files written by WISP_grism_region_files.py
# it modifies the files.dat to update the contamination column.
# written by Hugh Dickinson
##########################################################################
cd $WISPDATA/aXe/$1/
cp $WISPIPE/PYTHON/ProcessZerothOrders.py .
cp $WISPIPE/PYTHON/ZerothOrderWavelengthRanges.py .
python ProcessZerothOrders.py --verbose # --dryrun
##########################################################################


##########################################################################
# making uvis helpfile
##########################################################################
cd $WISPDATA/aXe/$1/DATA/UVIS
cp $WISPIPE/PYTHON/make_uvis_helpfile_IB1.py .
python make_uvis_helpfile_IB1.py
##########################################################################
 
# -------  G  ---------

cd $WISPDATA/aXe/$1
#tar -cvf "$1"_final_V5.1.tar Spectra Stamps DATA/DIRECT_GRISM/fin_F*.cat DATA/DIRECT_GRISM/*_flag.cat DATA/DIRECT_GRISM/*.reg DATA/DIRECT_GRISM/F*.fits DATA/DIRECT_GRISM/G*.fits SEX/F*full.cat SEX/cat_deblend_flag.cat Plots/*.pdf  G102_DRIZZLE G141_DRIZZLE DATA/UVIS/F*.fits DATA/UVIS/UVIStoIR DATA/UVIS/IRtoUVIS
tar -cvf "$1"_final_V6.1.tar Spectra Stamps DATA/DIRECT_GRISM/fin_F*.cat DATA/DIRECT_GRISM/*.reg DATA/DIRECT_GRISM/F*drz.fits DATA/DIRECT_GRISM/F*sci.fits DATA/DIRECT_GRISM/F*rms.fits DATA/DIRECT_GRISM/F*wht.fits DATA/DIRECT_GRISM/F*0.fits DATA/DIRECT_GRISM/JH*.fits DATA/DIRECT_GRISM/G*.fits SEX/F*full.cat  Plots/*.pdf G102_DRIZZLE G141_DRIZZLE DATA/UVIS/UVIS*.fits DATA/UVIS/UVIS*.list DATA/UVIS/*.txt DATA/UVIS/UVIStoIR DATA/UVIS/IRtoUVIS # DATA/DIRECT_GRISM/*_flag.cat SEX/cat_deblend_flag.cat

gzip *.tar

# -------  END  ---------
