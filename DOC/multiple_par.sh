#!/bin/bash

##########################################################################################################################
# HOW TO LAUNCH MULTIPLE PROCESSES AT THE SAME TIME
#
# 1) Cancel all the old processes eventually present (otherwise they would be run )
# 2) Add a new line with the following sintax:
#    > source ./WISPIPE/wispipe_6_2.sh Par#  >& log_Par#_6.2.log
#    EXAMPLE:
#    > source ~/WISPIPE/wispipe_6.2.sh Par364 >& ~/WISPIPE/LOG/log_Par364_6.2.log
#
# NOTE: Uvis data can be processed in the same way BUT ONLY IF they were already preprocessed.
#       For the preprocess, use a bash shell and astroconda environment.
#
# Ivano Baronchelli 2016
###########################################################################################################################

#source ~/WISPIPE/wispipe_6.2.sh Par188 >& ~/WISPIPE/LOG/log_Par188_6.2.log
#source ~/WISPIPE/wispipe_6.2.sh Par189 >& ~/WISPIPE/LOG/log_Par189_6.2.log
#source ~/WISPIPE/wispipe_6.2.sh Par302 >& ~/WISPIPE/LOG/log_Par302_6.2.log
source ~/WISPIPE/wispipe_6.2.sh Par364 >& ~/WISPIPE/LOG/log_Par364_6.2.log
