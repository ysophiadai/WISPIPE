#!/bin/csh
##############################################################
# WISPIPE
# Ivano Baronchelli, 2016
# Call in tcsh:
# > source wispipe_nitialcheck_6_1.sh Par# /Volumes/Kudo/DATA/WISPS ~/WISPIPE
###############################################################


ur_setup 
cd $3/IDL/
# Important: don't send EOF to the program, otherwise it stops showing only the grism exposures
idl<< EOF
.run findf_IB1.pro
findf_IB1,"$1","$2"
