


# WISPIPE

HST WISP pipeline. This is used to reduce the WISP data. Current
version is 6.1. Documention is in the DOC directory. Read:

wispipe-dr-guidline.txt and howtolaunch.txt

In addition to this, you need to setup your paths and setup pyraf.

For pyraf, make sure you have an iraf directory in ~/. In that
directory, make sure you have a login.cl file. An example login.cl
file is located in the DOC directory.

In your .bashrc and .cshrc files, you have to have specific paths
set. Below are examples of how I set mine.

Note: If you are doing uvis_preprocess, you have to have synphot
installed or you get errors. Also, you need to have updated reference
files in these locations. 

.cshrc:

setenv WISPIPE /Users/mrafelski/WISPIPE/
setenv WISPDATA /Users/mrafelski/data/wisp/
setenv iref ~/data/iref/
setenv crrefer ~/data/synphot/
setenv mtab ~/data/synphot/mtab/
setenv crotacomp ~/data/synphot/comp/ota/
setenv crwfc3comp ~/data/synphot/comp/wfc3/

.bashrc:

export WISPIPE=/Users/mrafelski/WISPIPE/
export WISPDATA=/Users/mrafelski/data/wisp/
export iref=~/data/iref/
export mtab=~/data/synphot/mtab/
export crrefer=~/data/synphot/
export crotacomp=~/data/synphot/comp/ota/
export crwfc3comp=~/data/synphot/comp/wfc3/