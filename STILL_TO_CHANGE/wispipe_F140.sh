#!/bin/csh
##############################################################
# WISPIPE
# Reduction Pipeline for the WISP program
# Hakim Atek 2009
# Modified by Marc Rafelski 2012
# Modified by Sophia Dai 2014, 2015
# This version is for the Cycle 19 data that only took one IR exposure - F140W instead of F110W and F160W
# Call in csh:  ./wispipe_F140.sh Par# /Volumes/Kudo/DATA/WISPS ~/WISPIPE > & log#-[datetime].log
###############################################################

cd $3/IDL/

ur_setup common ssb43l
idl<< EOF
.run process.pro
process,"$1","$2","$3"
.run cross_clean.pro
.run im_clean.pro
im_clean,"$1",/both, /F140only,"$2","$3"
EOF
# tweakreg #######
ur_setup common ssb43l
idl<< EOF
.r tweakprep_f140
tweakprep_f140,"$1","$2"
EOF
cd $2/aXe/$1/DATA/DIRECT/
python tweakprep.py
idl<< EOF
.r tweaksex_f140
tweaksex_f140,"$1","$2"
EOF
cd $2/aXe/$1/DATA/DIRECT/
python tweakreg.py
idl<< EOF
.r tweakprepgrism_f140
tweakprepgrism_f140,"$1","$2"
EOF
cd $2/aXe/$1/DATA/GRISM/
python tweakprepgrism.py
idl<< EOF
.r drizprep
drizprep,"$1","$2",/f140only
EOF
#Then prepare for the aXe
cd $3/IDL/
idl<< EOF
.run depth.pro
.run match_cat.pro
.run axeprep.pro
.run ddread.pro
.r axeprep_f140
match_cat_g141,"$1","$2"
axeprep_F140,"$1",/both,"$2"
EOF
cd $2/aXe/$1
python G102_axe_F140.py
python G141_axe_F140.py

#Finally generate the output
cd $3/IDL/
idl<< EOF
.run find_zo_F140.pro
find_zo_F140,"$1",/both,"$2"
EOF
idl<< EOF
.r beam_pet.pro 
.r axe_sing_F140.pro
.r wisp_extract_F140.pro
wisp_extract_F140,"$1",0,"$2"
.r rename_cat_F140
rename_cat_F140,"$1","$2"
EOF

cd $2/aXe/$1

tar -cvf "$1"_final_V5.0.tar Spectra  Stamps Plots/"$1"_spectra.pdf G102_DRIZZLE G141_DRIZZLE DATA/DIRECT_GRISM/*_flag.cat DATA/DIRECT_GRISM/F*W*_drz.fits DATA/DIRECT_GRISM/fin_*cat DATA/DIRECT_GRISM/G*.fits DATA/DIRECT_GRISM/*reg DATA/DIRECT_GRISM/i*1.cat DATA/DIRECT_GRISM/F1*.fits
gzip *.tar
#echo "wisp_extract,'Par5',0" | idl
