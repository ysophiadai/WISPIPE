#!/bin/csh

##########################################################################################################################
# HOW TO LAUNCH MULTIPLE PROCESSES AT THE SAME TIME
#
# 1) Cancel all the old processes eventually present (otherwise they would be run )
# 2) Add two new line with the following sintax:
#    > cd <path-WISPIPE>/WISPIPE
#    > source wispipe_6_1.sh Par# <path-of-aXe-and-data-folders> <path-of-wispipe-programs> > & log_Par#_6.1.log
#    EXAMPLE:
#    > cd Users/ivano/WISPIPE
#    > source wispipe_6_1.sh Par364 /Volumes/PROMISE_PEGASUS/TEST_DIR/DATA/WISPS /Users/ivano/WISPIPE > & log_364_6.1.log
# 4) Press enter multiple times (approximately 25-30 times for each field processed, also depending on the number of
#    exposures processed)
#
# NOTE: Uvis data can be processed in the same way (wispipe_uvis_6_1.sh) BUT ONLY IF 
#       the uvis preprocess has already been run indipendently in a bash shell, inside the astroconda environment.
#       To do this, use wispipe_uvis_preprocess.sh
#
# Ivano Baronchelli 2016
###########################################################################################################################

cd ~/WISPIPE
source wispipe_6_1.sh Par1 /Volumes/PROMISE_PEGASUS/DATA_V6/WISPS /Users/ivano/WISPIPE > & LOG_reduction_6_1/log_1_6.1.log
cd ~/WISPIPE
source wispipe_6_1.sh Par3 /Volumes/PROMISE_PEGASUS/DATA_V6/WISPS /Users/ivano/WISPIPE > & LOG_reduction_6_1/log_3_6.1.log
cd ~/WISPIPE
source wispipe_6_1.sh Par4 /Volumes/PROMISE_PEGASUS/DATA_V6/WISPS /Users/ivano/WISPIPE > & LOG_reduction_6_1/log_4_6.1.log
cd ~/WISPIPE
source wispipe_6_1.sh Par5 /Volumes/PROMISE_PEGASUS/DATA_V6/WISPS /Users/ivano/WISPIPE > & LOG_reduction_6_1/log_5_6.1.log
cd ~/WISPIPE
source wispipe_6_1.sh Par6 /Volumes/PROMISE_PEGASUS/DATA_V6/WISPS /Users/ivano/WISPIPE > & LOG_reduction_6_1/log_6_6.1.log
cd ~/WISPIPE
source wispipe_6_1.sh Par7 /Volumes/PROMISE_PEGASUS/DATA_V6/WISPS /Users/ivano/WISPIPE > & LOG_reduction_6_1/log_7_6.1.log
cd ~/WISPIPE
source wispipe_6_1.sh Par8 /Volumes/PROMISE_PEGASUS/DATA_V6/WISPS /Users/ivano/WISPIPE > & LOG_reduction_6_1/log_8_6.1.log
cd ~/WISPIPE
source wispipe_6_1.sh Par9 /Volumes/PROMISE_PEGASUS/DATA_V6/WISPS /Users/ivano/WISPIPE > & LOG_reduction_6_1/log_9_6.1.log
cd ~/WISPIPE
source wispipe_6_1.sh Par10 /Volumes/PROMISE_PEGASUS/DATA_V6/WISPS /Users/ivano/WISPIPE > & LOG_reduction_6_1/log_10_6.1.log
