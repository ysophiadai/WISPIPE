#!/bin/bash

##########################################################################################################################
# HOW TO LAUNCH MULTIPLE PROCESSES AT THE SAME TIME
#
# 1) Cancel all the old processes eventually present (otherwise they would be run )
# 2) Add two new line with the following sintax:
#    > cd $WISPIPE
#    > source wispipe.sh Par# > & log_Par#_6.1.log
#    EXAMPLE:
#    > cd $WISPIPE
#    > source wispipe.sh Par364 > & log_364_6.1.log
# 4) Press enter multiple times (approximately 25-30 times for each field processed, also depending on the number of
#    exposures processed)
#
# NOTE: Uvis data can be processed in the same way (wispipe_uvis_6_1.sh) BUT ONLY IF 
#       the uvis preprocess has already been run indipendently in a bash shell, inside the astroconda environment.
#       To do this, use wispipe_uvis_preprocess.sh
#
# Ivano Baronchelli 2016
###########################################################################################################################

cd $WISPIPE
source wispipe.sh Par1 > & LOG/log_1_6.1.log
cd $WISPIPE
source wispipe.sh Par3 > & LOG/log_3_6.1.log
cd $WISPIPE		   
source wispipe.sh Par4 > & LOG/log_4_6.1.log
cd $WISPIPE		   
source wispipe.sh Par5 > & LOG/log_5_6.1.log
cd $WISPIPE		   
source wispipe.sh Par6 > & LOG/log_6_6.1.log
cd $WISPIPE		   
source wispipe.sh Par7 > & LOG/log_7_6.1.log
cd $WISPIPE		   
source wispipe.sh Par8 > & LOG/log_8_6.1.log
cd $WISPIPE		   
source wispipe.sh Par9 > & LOG/log_9_6.1.log
cd $WISPIPE
source wispipe.sh Par1 > & LOG/log_10_6.1.log
