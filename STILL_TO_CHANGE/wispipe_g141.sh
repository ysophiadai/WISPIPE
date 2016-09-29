#!/bin/csh
##############################################################
# WISPIPE
# Reduction Pipeline for the WISP program
# Hakim Atek 2009
# Modified by Sophia Dai 2014,2015
# Call in csh:  ./wispipe_g141.sh Par# /Volumes/Kudo/DATA/WISPS ~/WISPIPE > & log#-[datetime].log
###############################################################
#setenv iref /Volumes/data/iref/

#cd /Users/marcar/data2/WISPS/aXe/$1
#pwd

cd $3/IDL/
ur_setup common ssb43l
idl<< EOF
.run process.pro
process,"$1","$2","$3"
.run cross_clean.pro
.run im_clean.pro
im_clean,"$1","$2","$3"
EOF
##### ADDED for tweakreg #######
ur_setup common ssb43l
idl<< EOF
.r tweakprep_g141
tweakprep_g141,"$1","$2"
EOF
cd $2/aXe/$1/DATA/DIRECT/
python tweakprep.py
idl<< EOF
.r tweaksex_g141
tweaksex_g141,"$1","$2"
EOF
cd $2/aXe/$1/DATA/DIRECT/
python tweakreg.py
idl<< EOF
.r tweakprepgrism_g141
tweakprepgrism_g141,"$1","$2"
EOF
cd $2/aXe/$1/DATA/GRISM/
python tweakprepgrism.py
idl<< EOF
.r drizprep_g141
drizprep_g141,"$1","$2"
EOF
##### ABOVE ADDED for tweakreg #######
cd $3/IDL/
idl<< EOF
.run depth.pro
.run match_cat_g141.pro
.run axeprep.pro
.run ddread.pro
match_cat_g141,"$1","$2"
axeprep,"$1","$2"
EOF
cd $2/aXe/$1
#ur_setup common ssb43l
python G141_axe_2015.py
#ur_setup common ssb43l
cd $3/IDL/
idl<< EOF
.run find_zo.pro
find_zo,"$1","$2"
.r beam_pet.pro 
.r axe_sing_g141.pro
.r wisp_extract_g141.pro
wisp_extract_g141,"$1",0,"$2"
.r rename_cat_g141
rename_cat_g141,"$1","$2"
EOF

cd $2/aXe/$1
tar -cvf "$1"_final_V5.0.tar Spectra  Stamps Plots/*_spectra.pdf DATA/DIRECT_GRISM/*_flag.cat G141_DRIZZLE DATA/DIRECT_GRISM/F*W*_drz.fits DATA/DIRECT_GRISM/fin*.cat DATA/DIRECT_GRISM/G*.fits DATA/DIRECT_GRISM/*reg DATA/DIRECT_GRISM/i*1.cat DATA/DIRECT_GRISM/F1*.fits

gzip *.tar
#echo "wisp_extract,'Par5',0" | idl

