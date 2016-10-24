#!/bin/bash
#
# OBSOLETE! Replaced by IDL program mutiple_uvis_preprocess.pro
# Call that program instead with a list of fields.
#
#
#
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



cd $WISPIPE/IDL/
echo "========================================================="
echo "Before this task you should check the input files using "
echo "findf.pro"
echo "========================================================="
echo "Select the correct case you are dealing with editing "
echo "wispipe_uvis_preprocess_6_1.sh (this file just launched)"
echo "========================================================="
########     
########     #######################################################
########     #                PHASE 1: CHECK
########     #######################################################
########     
########     ### ------------------------------------------------
########     ###  Check the names of the darks required
########     ### ------------------------------------------------
########     #   idl -e "uvis_preprocess,'$1',/darksonly"
########     ### ------------------------------------------------
########     
########     
########     #######################################################
########     #                PHASE 2: PREPROCESS
########     #######################################################
########     
########     
########     ### ------------------------------------------------
########     ###  Case 1: both uvis filters are present
########     ### ------------------------------------------------
########     ### 1A) OBSERVATIONS BEFORE OCTOBER 2012
########     # idl -e "uvis_preprocess,'$1', /nopostflash"
########     ### ------------------------------------------------
########     ### 1B) OBSERVATIONS AFTER OCTOBER 2012
   idl -e "uvis_preprocess,'$1'"
########     ### ------------------------------------------------
########     
########     
########     ### ------------------------------------------------
########     ###  Case 2: only one uvis filter is observed
########     ### ------------------------------------------------
########     ### 2A) OBSERVATIONS BEFORE OCTOBER 2012
########     #   idl -e "uvis_preprocess,'$1',/single,/nopostflash"
########     ### ------------------------------------------------
########     ### 2B) OBSERVATIONS AFTER OCTOBER 2012
########     #   idl -e "uvis_preprocess,'$1',/single"
########     ### ------------------------------------------------
########     
########       
########     #######################################################
########     #                PHASE 3: SOMETHING WRONG?
########     #######################################################
########     
########     
########     #### ------------------------------------------------
########     #### If everything worked, apart for calwf3:
########     #### ------------------------------------------------
########     #    idl -e "uvis_preprocess,'$1',/calwf3only"
########     #### ------------------------------------------------
