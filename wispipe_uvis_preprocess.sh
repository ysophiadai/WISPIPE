#!/bin/bash
##############################################################
# WISPIPE
# Reduction Pipeline for the WISP program
# Ivano Baronchelli 2016
#
# Preprocess uvis data. This bash code should be called before 
# wispipe_uvis.sh
#
# Call in a bash (not tcsh!) shell (and astroconda environment):
# source wispipe_uvis_preprocess.sh Par369 /Volumes/PROMISE_PEGASUS/TEST_DIR/DATA/WISPS ~/WISPIPE >>log_uvis_prep_369_t1.log
###############################################################

# NOTE1 : This shell script must be run in bash (not in tcsh)
#        before launching this code, astroconda must also be activate
#
# NOTE2 : How to run this code: Just remove the comments to the
#         appropriate case to run the preprocess step in the correct way.



cd $3/IDL/
echo "========================================================="
echo "Before this task you should check the input files using "
echo "findf.pro"
echo "========================================================="
echo "Select the correct case you are dealing with editing "
echo "wispipe_uvis_preprocess_6_1.sh (this file just launched)"
echo "========================================================="
########          
########          #######################################################
########          #                PHASE 1: CHECK
########          #######################################################
########          
########          ### ------------------------------------------------
########          ###  Check the names of the darks required
########          ### ------------------------------------------------
########          #   idl -e "uvis_preprocess.pro","$1","$2","$3", /darksonly
########          ### ------------------------------------------------
########          
########          
########          #######################################################
########          #                PHASE 2: PREPROCESS
########          #######################################################
########          
########          
########          ### ------------------------------------------------
########          ###  Case 1: both uvis filters are present
########          ### ------------------------------------------------
########          #   idl -e "uvis_preprocess.pro","$1","$2","$3",/uvis2,/mp
########          ### ------------------------------------------------
########          
########          
########          
########          ### ------------------------------------------------
########          ###  Case 2: only one uvis filter is observed
########          ### ------------------------------------------------
########          #   idl -e "uvis_preprocess.pro","$1","$2","$3", /uvis2,/mp,/single
########          ### ------------------------------------------------
########          
########          
########          ### ------------------------------------------------
########          ###  Case 4: Observations before october 2012 note: remove comment from only one line
########          ### ------------------------------------------------
########          #   idl -e "uvis_preprocess.pro","$1","$2","$3", /uvis2,/mp
   idl -e "uvis_preprocess.pro","$1","$2","$3", /uvis2,/mp,/nopostflash
########          #   idl -e "uvis_preprocess.pro","$1","$2","$3", /uvis2,/mp,/single
########          #   idl -e "uvis_preprocess.pro","$1","$2","$3", /uvis2,/mp,/single,/nopostflash
########          ### ------------------------------------------------
########          
########          
########          
########          #######################################################
########          #                PHASE 3: SOMETHING WRONG?
########          #######################################################
########          
########          
########          #### ------------------------------------------------
########          #### If everything worked, apart for calwf3:
########          #### ------------------------------------------------
########          #    idl -e "uvis_preprocess.pro","$1","$2","$3",/uvis2,/mp,/calwf3only
########          #### ------------------------------------------------
