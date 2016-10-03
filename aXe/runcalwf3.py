#!/usr/bin/env python
#
import glob
import os
import wfc3tools
#from wfc3tools import calwf3
from wfc3tools.calwf3 import calwf3
from subprocess import call

#from pyraf import iraf
#from iraf import stsdas
#from iraf import hst_calib
#from iraf import wfc3
#from wfc import calwf3

#stsdas.hst_calib.wfc3

#, hst_calib, wfc3, calwf3

raw = glob.glob('*_raw.fits')

for f in raw:
       print "Processing %s" % (f)
       calwf3(f)
       #calwf3.calwf3(f)
       #call(['calwf3.e',f])


