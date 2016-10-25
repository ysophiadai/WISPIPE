#!/bin/bash

##########################################################################################################################
# HOW TO LAUNCH MULTIPLE uvis PRE-PROCESSES AT THE SAME TIME
#
# All the fields MUST have the same characteristics (wispipe_uvis_preprocess_6_1.sh
# must be set in the same way for all the fields) on which it is run
#
# 1) Cancel all the old processes eventually present (otherwise they would be run )
# 2) Add two new line with the following sintax:
#    > cd <path-WISPIPE>/WISPIPE
#    > source wispipe_uvis_preprocess_6_1.sh Par# <path-of-aXe-and-data-folders> <path-of-wispipe-programs> >>log_Par#_6.1.log
#    EXAMPLE:
#    > cd Users/ivano/WISPIPE
#    > source wispipe_uvis_preprocess_6_1.sh Par63 /Volumes/PROMISE_PEGASUS/DATA_V6/WISPS /Users/ivano/WISPIPE >>LOG_reduction_6_1/log_63_6.1.log
#
# IMPORTANT-1 : This shell script MUST be run in a bash shell (and astroconda environment)
# IMPORTANT-2 : Before running this program, mnake sure that all the fields that must be preprocessed are ok with the
#               characteristics set in wispipe_uvis_preprocess_6_1.sh)
#
# Ivano Baronchelli 2016
###########################################################################################################################

# these here below are just examples. Sobstitute them before starting with a new set of Par fields.

cd ~/WISPIPE
source wispipe_uvis_preprocess_6_1.sh Par63 >>LOG_reduction_6_1/log_63_6.1.log

cd ~/WISPIPE
source wispipe_uvis_preprocess_6_1.sh Par64 >>LOG_reduction_6_1/log_64_6.1.log

cd ~/WISPIPE
source wispipe_uvis_preprocess_6_1.sh Par66 >>LOG_reduction_6_1/log_66_6.1.log
 
