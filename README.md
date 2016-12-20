
WISPIPE
==============
[![astropy](http://img.shields.io/badge/powered%20by-AstroPy-orange.svg?style=flat)](http://www.astropy.org/)

The HST WISP pipeline is used to reduce the WISP data. Current version is **6.2**.

Installation
------------

```
$ git clone https://github.com/HSTWISP/WISPIPE.git
```
Make sure to read the readme file in the DOC directory on dependencies (e.g. astroconda and Ureka):  

`DOC/README.txt`

As described in this file, you need to setup your paths and setup pyraf.

For pyraf, make sure you have an iraf directory in ~/. In that
directory, make sure you have a login.cl file. An example login.cl
file is located in the DOC directory.

In your .bashrc, you have to have specific paths set. Below are examples of how to do it, but you have to replace the username and make sure the files are located where you point to.

Note: If you are doing uvis_preprocess, you have to have synphot installed or you get errors. Also, you need to have updated reference files in these locations. 

bashrc setup
------------

.bashrc:  

export WISPIPE=/Users/mrafelski/WISPIPE/  
export WISPDATA=/Users/mrafelski/data/wisp/  
export iref=~/data/iref/  
export mtab=~/data/synphot/mtab/  
export crrefer=~/data/synphot/  
export crotacomp=~/data/synphot/comp/ota/  
export crwfc3comp=~/data/synphot/comp/wfc3/
