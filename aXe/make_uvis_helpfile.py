import pyfits
import os

bluefilt='none'
redfilt='none'
rootpath='./'
bpath=rootpath+'F475X_drz.fits'
rpath=rootpath+'F600LP_drz.fits'
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
    print >>fout, "The filters listed in the names of the UVIS files "
    print >>fout, "do not necessarily reflect the actual filters used "
    print >>fout, "by the WISP program. Our naming convention has been "
    print >>fout, "chosen to name all of the UVIS files consistently "
    print >>fout, "as F475X for the bluer filter and F600LP for the "
    print >>fout, "redder filter, regardless of whether F606W and F814W "
    print >>fout, "were actually used. The actual filters can be "
    print >>fout, "determined from the header information or the WISP "
    print >>fout, "pdf table of observations. The filters used on this "
    print >>fout, "field are actually:"
    print >>fout, "Blue: %s" % (bluefilt)
    print >>fout, "Red:  %s" % (redfilt)
    fout.close()
