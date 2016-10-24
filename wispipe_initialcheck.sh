#!/bin/csh
##############################################################
# WISPIPE
# Ivano Baronchelli, 2016
# Call in tcsh:
###### OLD ###### > source wispipe_initialcheck_6_1.sh Par# /Volumes/Kudo/DATA/WISPS ~/WISPIPE
# > source wispipe_initialcheck.sh Par#
# e.g.: source wispipe_initialcheck.sh Par302
###############################################################


ur_setup common primary
#cd $3/IDL/
cd $WISPIPE/IDL
# Important: don't send EOF to the program, otherwise it stops showing only the grism exposures
idl<< EOF
.run findf_IB1.pro
findf_IB1,'$1','$WISPDATA'
