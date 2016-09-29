import pyfits
import os

# New version of the original make_uvis_helpfile.py
# Original Author: unknown
# Last modifications: Ivano Baronchelli Sept. 2016

bluefilt='none'
redfilt='none'
rootpath='./'

# bpath=rootpath+'F475X_drz.fits'
# rpath=rootpath+'F600LP_drz.fits'
bpath=rootpath+'UVIS1_drz.fits'
rpath=rootpath+'UVIS2_drz.fits'

if os.path.exists(bpath)==1:
    fblue=pyfits.open(bpath)
    bluefilt=fblue[0].header['FILTER']
    fblue.close()
if os.path.exists(rpath)==1:
    fred=pyfits.open(rpath)
    redfilt=fred[0].header['FILTER']
    fred.close()

if os.path.exists(rootpath):
    fout=open(rootpath+'NOTES_ON_UVIS_FILTERS.txt','w')
    print >>fout, "IMPORTANT NOTE: Our naming convention has been "
    print >>fout, "chosen to name all of the UVIS files consistently "
    print >>fout, "as UVIS1 for the bluer filter and UVIS2 for the "
    print >>fout, "redder filter, regardless of whether "
    print >>fout, "F475X, F606W, F600LP or F814W were actually used."
    print >>fout, "The actual filters can be determined from the header"
    print >>fout, "information or the WISP pdf table of observations."
    print >>fout, "The filters used on this field are actually:"
    print >>fout, "UVIS1: %s" % (bluefilt)
    print >>fout, "UVIS2:  %s" % (redfilt)
    fout.close()
