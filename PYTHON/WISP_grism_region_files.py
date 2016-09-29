#! /usr/bin/env python

"""
WISP_grism_region_files.py -- Code to create region files for WISP grism data

Written by Vihang Mehta (mehta@astro.umn.edu)
Last updated 21 Sept., 2016
---------------------------------------------------------------------------------------
Usage: WISP_grism_region_files.py [-h] [-f FILTER] [-c CONFIG] [-p PAR_DIR] grism

Positional arguments:
  grism                 provide the grism name ['G102','G141']

Optional arguments:
  -h, --help            prints help
  -f FILTER, --filter FILTER
                        provide the direct image filter ['F110','F140','F160']
  -c CONFIG, --config CONFIG
                        provide the path to config files [default: config/]
  -p PAR_DIR, --par_dir PAR_DIR
                        provide the path to the PAR directory [default:<current_dir>]
  -s SAVE_SUFFIX, --save_suffix SAVE_SUFFIX
                        provide a suffix to add when saving files in order to
                        prevent overwriting existing files [default:
                        <no_suffix>]
"""

import os
import argparse
import numpy as np
import scipy.integrate
import scipy.interpolate
import astropy.io.fits as fitsio
from astropy.wcs import WCS
from astropy.wcs.utils import proj_plane_pixel_scales

def get_config_G102_F110(config_path):
    """
    Get aXe configuration parameters for G102 when using F110W filter as the direct image
    Numbers from G102.F110W.V4.3.conf (http://www.stsci.edu/hst/wfc3/analysis/grism_obs/calibrations/wfc3_g102.html)
    """
    EXT_A_0  = 41
    EXT_A_1  = 248
    DYDX_A_0 = lambda x,y:   -0.221944440536      - 0.0002663379534341786*x - 0.0018501621696214792*y +4.877038129656633e-10  *x*x +5.408087165623451e-7  *y*y +1.5530956524130845e-7 *x*y
    DYDX_A_1 = lambda x,y:    0.01409870961049523 - 6.379312386311464e-6 *x - 1.7291364097521173e-6*y -6.706042298906293e-10  *x*x +1.2760204375540773e-8 *y*y -1.4759256948695718e-10*x*y
    DLDP_A_0 = lambda x,y: 6339.59279173          + 0.201430850028975    *x + 0.0802131361796817   *y -0.00019613135070868445 *x*x +0.00003013960034834457*y*y -0.00008431572555355592*x*y
    DLDP_A_1 = lambda x,y:   24.001233940762805   - 0.0007160621018940599*x + 0.0008411542615870384*y +8.977548140491455e-7   *x*x -3.160441003220574e-7  *y*y +7.140436248957638e-7  *x*y
    DPDL_A_0 = lambda x,y: -264.55554306311785    - 0.015284337961919641 *x + 0.007028692785800708 *y +0.000016593558926983952*x*x -4.289040021460406e-6  *y*y +9.585810387600232e-6  *x*y
    DPDL_A_1 = lambda x,y:    0.04169157110485184 + 1.1332881093899574e-6*x - 1.5966113493334132e-6*y -1.3964496051633498e-9  *x*x +4.983248754757765e-10 *y*y -9.812838827422068e-10 *x*y
    RESP_A   = fitsio.getdata(os.path.join(config_path,'WFC3.IR.G102.1st.sens.2.fits'))
    SENS_A   = scipy.interpolate.interp1d(RESP_A["WAVELENGTH"],RESP_A["SENSITIVITY"])

    EXT_B_0  = -280
    EXT_B_1  = -220
    DYDX_B_0 = lambda x,y:     -4.44759883509         + 0.0013528229881200563 *x +  0.0007358132675236892*y - 1.2055028153206567e-7 *x*x - 2.4067825512095702e-6 *y*y - 2.1550315933844428e-7*x*y
    DLDP_B_0 = lambda x,y: 425747.130416              - 2.3372703881594914    *x - 24.604133293546717    *y + 0.006495073950998997  *x*x - 0.004965587131396293  *y*y + 0.003941292889403271 *x*y
    DLDP_B_1 = lambda x,y:   1591.4807567929506       + 0.01072485833724468   *x +  0.010484099575419082 *y + 1.741180520968595e-7  *x*x - 0.00001957910803090667*y*y + 2.4869927688622153e-6*x*y
    DPDL_B_0 = lambda x,y:   -267.64835287126334      + 0.0031811936021396356 *x +  0.01706185677703048  *y - 4.032994899257948e-6  *x*x - 1.0965007144950975e-8 *y*y - 2.070692200526903e-6 *x*y
    DPDL_B_1 = lambda x,y:      0.0006250000000000183 + 3.0222230432220303e-21*x +  2.584930889412207e-20*y + 2.9311834305717406e-23*x*x + 2.2626184980299305e-23*y*y + 1.525069888341582e-23*x*y
    RESP_B   = fitsio.getdata(os.path.join(config_path,'WFC3.IR.G102.0th.sens.1.fits'))
    SENS_B   = scipy.interpolate.interp1d(RESP_B["WAVELENGTH"],RESP_B["SENSITIVITY"])

    config = {'EXT_A_0':EXT_A_0,'EXT_A_1':EXT_A_1,'RESP_A':RESP_A,'SENS_A':SENS_A,
              'DYDX_A_0':DYDX_A_0,'DYDX_A_1':DYDX_A_1,
              'DLDP_A_0':DLDP_A_0,'DLDP_A_1':DLDP_A_1,'DPDL_A_0':DPDL_A_0,'DPDL_A_1':DPDL_A_1,
              'EXT_B_0':EXT_B_0,'EXT_B_1':EXT_B_1,'RESP_B':RESP_B,'SENS_B':SENS_B,
              'DYDX_B_0':DYDX_B_0,
              'DLDP_B_0':DLDP_B_0,'DLDP_B_1':DLDP_B_1,'DPDL_B_0':DPDL_B_0,'DPDL_B_1':DPDL_B_1}

    return config

def get_config_G102_F140(config_path):
    """
    Get aXe configuration parameters for G102 when using F140W filter as the direct image
    Numbers from G102.F140W.V4.3.conf (http://www.stsci.edu/hst/wfc3/analysis/grism_obs/calibrations/wfc3_g102.html)
    """
    EXT_A_0  = 41
    EXT_A_1  = 248
    DYDX_A_0 = lambda x,y:   -0.353944440536      -0.0002663379534341786*x - 0.0018501621696214792*y + 4.877038129656633e-10  *x*x + 5.408087165623451e-7  *y*y + 1.5530956524130845e-7 *x*y
    DYDX_A_1 = lambda x,y:    0.01409870961049523 -6.379312386311464e-6 *x - 1.7291364097521173e-6*y - 6.706042298906293e-10  *x*x + 1.2760204375540773e-8 *y*y - 1.4759256948695718e-10*x*y
    DLDP_A_0 = lambda x,y: 6342.47293981          +0.201430850028975    *x + 0.0802131361796817   *y - 0.00019613135070868445 *x*x + 0.00003013960034834457*y*y - 0.00008431572555355592*x*y
    DLDP_A_1 = lambda x,y:   24.001233940762805   -0.0007160621018940599*x + 0.0008411542615870384*y + 8.977548140491455e-7   *x*x - 3.160441003220574e-7  *y*y + 7.140436248957638e-7  *x*y
    DPDL_A_0 = lambda x,y: -264.55554306311785    -0.015284337961919641 *x + 0.007028692785800708 *y + 0.000016593558926983952*x*x - 4.289040021460406e-6  *y*y + 9.585810387600232e-6  *x*y
    DPDL_A_1 = lambda x,y:    0.04169157110485184 +1.1332881093899574e-6*x - 1.5966113493334132e-6*y - 1.3964496051633498e-9  *x*x + 4.983248754757765e-10 *y*y - 9.812838827422068e-10 *x*y
    RESP_A   = fitsio.getdata(os.path.join(config_path,'WFC3.IR.G102.1st.sens.2.fits'))
    SENS_A   = scipy.interpolate.interp1d(RESP_A["WAVELENGTH"],RESP_A["SENSITIVITY"])

    EXT_B_0  = -280
    EXT_B_1  = -220
    DYDX_B_0 = lambda x,y:     -4.57959883509         +0.0013528229881200563 *x + 0.0007358132675236892*y - 1.2055028153206567e-7 *x*x - 2.4067825512095702e-6 *y*y - 2.1550315933844428e-7*x*y
    DLDP_B_0 = lambda x,y: 425938.108107              -2.3372703881594914    *x - 24.604133293546717   *y + 0.006495073950998997  *x*x - 0.004965587131396293  *y*y + 0.003941292889403271 *x*y
    DLDP_B_1 = lambda x,y:   1591.4807567929506       +0.01072485833724468   *x + 0.010484099575419082 *y + 1.741180520968595e-7  *x*x - 0.00001957910803090667*y*y + 2.4869927688622153e-6*x*y
    DPDL_B_0 = lambda x,y:   -267.64835287126334      +0.0031811936021396356 *x + 0.01706185677703048  *y - 4.032994899257948e-6  *x*x - 1.0965007144950975e-8 *y*y - 2.070692200526903e-6 *x*y
    DPDL_B_1 = lambda x,y:      0.0006250000000000183 +3.0222230432220303e-21*x + 2.584930889412207e-20*y + 2.9311834305717406e-23*x*x + 2.2626184980299305e-23*y*y + 1.525069888341582e-23*x*y
    RESP_B   = fitsio.getdata(os.path.join(config_path,'WFC3.IR.G102.0th.sens.1.fits'))
    SENS_B   = scipy.interpolate.interp1d(RESP_B["WAVELENGTH"],RESP_B["SENSITIVITY"])

    config = {'EXT_A_0':EXT_A_0,'EXT_A_1':EXT_A_1,'RESP_A':RESP_A,'SENS_A':SENS_A,
              'DYDX_A_0':DYDX_A_0,'DYDX_A_1':DYDX_A_1,
              'DLDP_A_0':DLDP_A_0,'DLDP_A_1':DLDP_A_1,'DPDL_A_0':DPDL_A_0,'DPDL_A_1':DPDL_A_1,
              'EXT_B_0':EXT_B_0,'EXT_B_1':EXT_B_1,'RESP_B':RESP_B,'SENS_B':SENS_B,
              'DYDX_B_0':DYDX_B_0,
              'DLDP_B_0':DLDP_B_0,'DLDP_B_1':DLDP_B_1,'DPDL_B_0':DPDL_B_0,'DPDL_B_1':DPDL_B_1}

    return config

def get_config_G102_F160(config_path):
    """
    Get aXe configuration parameters for G102 when using F160W filter as the direct image
    Numbers from G102.F160W.V4.3.conf (http://www.stsci.edu/hst/wfc3/analysis/grism_obs/calibrations/wfc3_g102.html)
    """
    EXT_A_0  = 41
    EXT_A_1  = 248
    DYDX_A_0 = lambda x,y:   -0.384944440536      - 0.0002663379534341786*x - 0.0018501621696214792*y + 4.877038129656633e-10  *x*x + 5.408087165623451e-7  *y*y + 1.5530956524130845e-7 *x*y
    DYDX_A_1 = lambda x,y:    0.01409870961049523 - 6.379312386311464e-6 *x - 1.7291364097521173e-6*y - 6.706042298906293e-10  *x*x + 1.2760204375540773e-8 *y*y - 1.4759256948695718e-10*x*y
    DLDP_A_0 = lambda x,y: 6343.7450052           + 0.201430850028975    *x + 0.0802131361796817   *y - 0.00019613135070868445 *x*x + 0.00003013960034834457*y*y - 0.00008431572555355592*x*y
    DLDP_A_1 = lambda x,y:   24.001233940762805   - 0.0007160621018940599*x + 0.0008411542615870384*y + 8.977548140491455e-7   *x*x - 3.160441003220574e-7  *y*y + 7.140436248957638e-7  *x*y
    DPDL_A_0 = lambda x,y: -264.55554306311785    - 0.015284337961919641 *x + 0.007028692785800708 *y + 0.000016593558926983952*x*x - 4.289040021460406e-6  *y*y + 9.585810387600232e-6  *x*y
    DPDL_A_1 = lambda x,y:    0.04169157110485184 + 1.1332881093899574e-6*x - 1.5966113493334132e-6*y - 1.3964496051633498e-9  *x*x + 4.983248754757765e-10 *y*y - 9.812838827422068e-10 *x*y
    RESP_A   = fitsio.getdata(os.path.join(config_path,'WFC3.IR.G102.1st.sens.2.fits'))
    SENS_A   = scipy.interpolate.interp1d(RESP_A["WAVELENGTH"],RESP_A["SENSITIVITY"])

    EXT_B_0  = -280
    EXT_B_1  = -220
    DYDX_B_0 = lambda x,y:     -4.61059883509         + 0.0013528229881200563 *x +  0.0007358132675236892*y -1.2055028153206567e-7 *x*x - 2.4067825512095702e-6 *y*y - 2.1550315933844428e-7*x*y
    DLDP_B_0 = lambda x,y: 426022.456587              - 2.3372703881594914    *x - 24.604133293546717    *y +0.006495073950998997  *x*x - 0.004965587131396293  *y*y + 0.003941292889403271 *x*y
    DLDP_B_1 = lambda x,y:   1591.4807567929506       + 0.01072485833724468   *x +  0.010484099575419082 *y +1.741180520968595e-7  *x*x - 0.00001957910803090667*y*y + 2.4869927688622153e-6*x*y
    DPDL_B_0 = lambda x,y:   -267.64835287126334      + 0.0031811936021396356 *x +  0.01706185677703048  *y -4.032994899257948e-6  *x*x - 1.0965007144950975e-8 *y*y - 2.070692200526903e-6 *x*y
    DPDL_B_1 = lambda x,y:      0.0006250000000000183 + 3.0222230432220303e-21*x +  2.584930889412207e-20*y +2.9311834305717406e-23*x*x + 2.2626184980299305e-23*y*y + 1.525069888341582e-23*x*y
    RESP_B   = fitsio.getdata(os.path.join(config_path,'WFC3.IR.G102.0th.sens.1.fits'))
    SENS_B   = scipy.interpolate.interp1d(RESP_B["WAVELENGTH"],RESP_B["SENSITIVITY"])

    config = {'EXT_A_0':EXT_A_0,'EXT_A_1':EXT_A_1,'RESP_A':RESP_A,'SENS_A':SENS_A,
              'DYDX_A_0':DYDX_A_0,'DYDX_A_1':DYDX_A_1,
              'DLDP_A_0':DLDP_A_0,'DLDP_A_1':DLDP_A_1,'DPDL_A_0':DPDL_A_0,'DPDL_A_1':DPDL_A_1,
              'EXT_B_0':EXT_B_0,'EXT_B_1':EXT_B_1,'RESP_B':RESP_B,'SENS_B':SENS_B,
              'DYDX_B_0':DYDX_B_0,
              'DLDP_B_0':DLDP_B_0,'DLDP_B_1':DLDP_B_1,'DPDL_B_0':DPDL_B_0,'DPDL_B_1':DPDL_B_1}

    return config

def get_config_G141_F110(config_path):
    """
    Get aXe configuration parameters for G141 when using F110W filter as the direct image
    Numbers from G141.F110W.V4.3.conf (http://www.stsci.edu/hst/wfc3/analysis/grism_obs/calibrations/wfc3_g141.html)
    """
    EXT_A_0  = 15
    EXT_A_1  = 196
    DYDX_A_0 = lambda x,y:    2.21396481352        - 0.00019752130624389416*x - 0.002202066565067532 *y + 3.143514082596283e-8   *x*x + 4.3212786880932414e-7  *y*y + 1.210435999122636e-7  *x*y
    DYDX_A_1 = lambda x,y:    0.010205281672977665 - 6.06056923866002e-6   *x - 3.2485600412356953e-6*y + 4.2363866304617406e-10 *x*x + 1.230956851333159e-8   *y*y + 1.6123073931033502e-9 *x*y
    DLDP_A_0 = lambda x,y: 8945.98953225           + 0.08044032819916265   *x - 0.009279698766495334 *y + 0.000021856641668116504*x*x - 0.000011048008881387708*y*y + 0.00003352712538187608*x*y
    DLDP_A_1 = lambda x,y:   44.97227893276267     + 0.0004927891511929662 *x + 0.0035782416625653765*y - 9.175233345083485e-7   *x*x + 2.2355060371418054e-7  *y*y - 9.258690000316504e-7  *x*y
    DPDL_A_0 = lambda x,y: -198.97909709239238     + 0.00022085642768667504*x + 0.015657459895358234 *y - 4.20679688923729e-6    *x*x + 1.2280573229146504e-6  *y*y - 5.155391423878844e-6  *x*y
    DPDL_A_1 = lambda x,y:    0.022228565039576174 - 2.2310680636779698e-7 *x - 1.7250484537749406e-6*y + 4.1766971161196834e-10 *x*x - 1.0112004248938472e-10 *y*y + 4.956649137022331e-10 *x*y
    RESP_A   = fitsio.getdata(os.path.join(config_path,'WFC3.IR.G141.1st.sens.2.fits'))
    SENS_A   = scipy.interpolate.interp1d(RESP_A["WAVELENGTH"],RESP_A["SENSITIVITY"])

    EXT_B_0  = -207
    EXT_B_1  = -177
    DYDX_B_0 = lambda x,y:     -0.0650164710212       + 0.001119940227389483 *x  - 0.00040208366824463386*y - 1.4194849412846487e-7 *x*x - 1.8676580206140632e-6 *y*y + 4.3309224018307426e-8  *x*y
    DLDP_B_0 = lambda x,y: 596231.123276              -11.142828121887003    *x  -36.64357684013913      *y + 0.011419229673613265  *x*x + 0.006832291128275392  *y*y - 0.0007734484905564656  *x*y
    DLDP_B_1 = lambda x,y:   3005.100296560758        - 0.030048806158424805 *x  + 0.007875269629428604  *y + 0.00001042904281029149*x*x + 0.00003500270057271983*y*y - 0.000029167649909560617*x*y
    DPDL_B_0 = lambda x,y:   -198.54772435079127      + 0.0018167722687743144*x  + 0.012732046102747235  *y - 3.1545156431674204e-6 *x*x - 7.78838498521172e-8   *y*y - 1.5746821630565375e-6  *x*y
    DPDL_B_1 = lambda x,y:      0.0003333333333333646 - 7.051596740287148e-20*x  - 4.8635321687450096e-20*y + 4.7199609155642836e-23*x*x + 5.44539123505613e-23  *y*y + 3.3757517911810997e-23 *x*y
    RESP_B   = fitsio.getdata(os.path.join(config_path,'WFC3.IR.G141.0th.sens.1.fits'))
    SENS_B   = scipy.interpolate.interp1d(RESP_B["WAVELENGTH"],RESP_B["SENSITIVITY"])

    config = {'EXT_A_0':EXT_A_0,'EXT_A_1':EXT_A_1,'RESP_A':RESP_A,'SENS_A':SENS_A,
              'DYDX_A_0':DYDX_A_0,'DYDX_A_1':DYDX_A_1,
              'DLDP_A_0':DLDP_A_0,'DLDP_A_1':DLDP_A_1,'DPDL_A_0':DPDL_A_0,'DPDL_A_1':DPDL_A_1,
              'EXT_B_0':EXT_B_0,'EXT_B_1':EXT_B_1,'RESP_B':RESP_B,'SENS_B':SENS_B,
              'DYDX_B_0':DYDX_B_0,
              'DLDP_B_0':DLDP_B_0,'DLDP_B_1':DLDP_B_1,'DPDL_B_0':DPDL_B_0,'DPDL_B_1':DPDL_B_1}

    return config

def get_config_G141_F140(config_path):
    """
    Get aXe configuration parameters for G141 when using F140W filter as the direct image
    Numbers from G141.F140W.V4.3.conf (http://www.stsci.edu/hst/wfc3/analysis/grism_obs/calibrations/wfc3_g141.html)
    """
    EXT_A_0  = 15
    EXT_A_1  = 196
    DYDX_A_0 = lambda x,y:    2.08196481352         - 0.00019752130624389416*x - 0.002202066565067532 *y  + 3.143514082596283e-8   *x*x + 4.3212786880932414e-7  *y*y + 1.210435999122636e-7  *x*y
    DYDX_A_1 = lambda x,y:    0.010205281672977665  - 6.06056923866002e-6   *x - 3.2485600412356953e-6*y  + 4.2363866304617406e-10 *x*x + 1.230956851333159e-8   *y*y + 1.6123073931033502e-9 *x*y
    DLDP_A_0 = lambda x,y: 8951.38620572            + 0.08044032819916265   *x - 0.009279698766495334 *y  + 0.000021856641668116504*x*x - 0.000011048008881387708*y*y + 0.00003352712538187608*x*y
    DLDP_A_1 = lambda x,y:   44.97227893276267      + 0.0004927891511929662 *x + 0.0035782416625653765*y  - 9.175233345083485e-7   *x*x + 2.2355060371418054e-7  *y*y - 9.258690000316504e-7  *x*y
    DPDL_A_0 = lambda x,y: -198.97909709239238      + 0.00022085642768667504*x + 0.015657459895358234 *y  - 4.20679688923729e-6    *x*x + 1.2280573229146504e-6  *y*y - 5.155391423878844e-6  *x*y
    DPDL_A_1 = lambda x,y:    0.022228565039576174  - 2.2310680636779698e-7 *x - 1.7250484537749406e-6*y  + 4.1766971161196834e-10 *x*x - 1.0112004248938472e-10 *y*y + 4.956649137022331e-10 *x*y
    RESP_A   = fitsio.getdata(os.path.join(config_path,'WFC3.IR.G141.1st.sens.2.fits'))
    SENS_A   = scipy.interpolate.interp1d(RESP_A["WAVELENGTH"],RESP_A["SENSITIVITY"])

    EXT_B_0  = -207
    EXT_B_1  = -177
    DYDX_B_0 = lambda x,y:     -0.197016471021         + 0.001119940227389483 *x -  0.00040208366824463386*y - 1.4194849412846487e-7 *x*x - 1.8676580206140632e-6 *y*y + 4.3309224018307426e-8  *x*y
    DLDP_B_0 = lambda x,y: 596591.735312               -11.142828121887003    *x - 36.64357684013913      *y + 0.011419229673613265  *x*x + 0.006832291128275392  *y*y - 0.0007734484905564656  *x*y
    DLDP_B_1 = lambda x,y:   3005.100296560758         - 0.030048806158424805 *x +  0.007875269629428604  *y + 0.00001042904281029149*x*x + 0.00003500270057271983*y*y - 0.000029167649909560617*x*y
    DPDL_B_0 = lambda x,y:   -198.54772435079127       + 0.0018167722687743144*x +  0.012732046102747235  *y - 3.1545156431674204e-6 *x*x - 7.78838498521172e-8   *y*y - 1.5746821630565375e-6  *x*y
    DPDL_B_1 = lambda x,y:      0.00033333333333336466 - 7.051596740287148e-20*x -  4.8635321687450096e-20*y + 4.7199609155642836e-23*x*x + 5.44539123505613e-23  *y*y + 3.3757517911810997e-23 *x*y
    RESP_B   = fitsio.getdata(os.path.join(config_path,'WFC3.IR.G141.0th.sens.1.fits'))
    SENS_B   = scipy.interpolate.interp1d(RESP_B["WAVELENGTH"],RESP_B["SENSITIVITY"])

    config = {'EXT_A_0':EXT_A_0,'EXT_A_1':EXT_A_1,'RESP_A':RESP_A,'SENS_A':SENS_A,
              'DYDX_A_0':DYDX_A_0,'DYDX_A_1':DYDX_A_1,
              'DLDP_A_0':DLDP_A_0,'DLDP_A_1':DLDP_A_1,'DPDL_A_0':DPDL_A_0,'DPDL_A_1':DPDL_A_1,
              'EXT_B_0':EXT_B_0,'EXT_B_1':EXT_B_1,'RESP_B':RESP_B,'SENS_B':SENS_B,
              'DYDX_B_0':DYDX_B_0,
              'DLDP_B_0':DLDP_B_0,'DLDP_B_1':DLDP_B_1,'DPDL_B_0':DPDL_B_0,'DPDL_B_1':DPDL_B_1}

    return config

def get_config_G141_F160(config_path):
    """
    Get aXe configuration parameters for G141 when using F160W filter as the direct image
    Numbers from G141.F160W.V4.3.conf (http://www.stsci.edu/hst/wfc3/analysis/grism_obs/calibrations/wfc3_g141.html)
    """
    EXT_A_0  = 15
    EXT_A_1  = 196
    DYDX_A_0 = lambda x,y:    2.05096481352         - 0.00019752130624389416*x - 0.002202066565067532 *y + 3.143514082596283e-8   *x*x + 4.3212786880932414e-7  *y*y + 1.210435999122636e-7  *x*y
    DYDX_A_1 = lambda x,y:    0.010205281672977665  - 6.06056923866002e-6   *x - 3.2485600412356953e-6*y + 4.2363866304617406e-10 *x*x + 1.230956851333159e-8   *y*y + 1.6123073931033502e-9 *x*y
    DLDP_A_0 = lambda x,y: 8953.7697365             + 0.08044032819916265   *x - 0.009279698766495334 *y + 0.000021856641668116504*x*x - 0.000011048008881387708*y*y + 0.00003352712538187608*x*y
    DLDP_A_1 = lambda x,y:   44.97227893276267      + 0.0004927891511929662 *x + 0.0035782416625653765*y - 9.175233345083485e-7   *x*x + 2.2355060371418054e-7  *y*y - 9.258690000316504e-7  *x*y
    DPDL_A_0 = lambda x,y: -198.97909709239238      + 0.00022085642768667504*x + 0.015657459895358234 *y - 4.20679688923729e-6    *x*x + 1.2280573229146504e-6  *y*y - 5.155391423878844e-6  *x*y
    DPDL_A_1 = lambda x,y:    0.022228565039576174  - 2.2310680636779698e-7 *x - 1.7250484537749406e-6*y + 4.1766971161196834e-10 *x*x - 1.0112004248938472e-10 *y*y + 4.956649137022331e-10 *x*y
    RESP_A   = fitsio.getdata(os.path.join(config_path,'WFC3.IR.G141.1st.sens.2.fits'))
    SENS_A   = scipy.interpolate.interp1d(RESP_A["WAVELENGTH"],RESP_A["SENSITIVITY"])

    EXT_B_0  = -207
    EXT_B_1  = -177
    DYDX_B_0 = lambda x,y:     -0.228016471021         +  0.001119940227389483 *x  -  0.00040208366824463386*y - 1.4194849412846487e-7 *x*x - 1.8676580206140632e-6 *y*y + 4.3309224018307426e-8  *x*y
    DLDP_B_0 = lambda x,y: 596751.005628               - 11.142828121887003    *x  - 36.64357684013913      *y + 0.011419229673613265  *x*x + 0.006832291128275392  *y*y - 0.0007734484905564656  *x*y
    DLDP_B_1 = lambda x,y:   3005.100296560758         -  0.030048806158424805 *x  +  0.007875269629428604  *y + 0.00001042904281029149*x*x + 0.00003500270057271983*y*y - 0.000029167649909560617*x*y
    DPDL_B_0 = lambda x,y:   -198.54772435079127       +  0.0018167722687743144*x  +  0.012732046102747235  *y - 3.1545156431674204e-6 *x*x - 7.78838498521172e-8   *y*y - 1.5746821630565375e-6  *x*y
    DPDL_B_1 = lambda x,y:      0.00033333333333336466 -  7.051596740287148e-20*x  -  4.8635321687450096e-20*y + 4.7199609155642836e-23*x*x + 5.44539123505613e-23  *y*y + 3.3757517911810997e-23 *x*y
    RESP_B   = fitsio.getdata(os.path.join(config_path,'WFC3.IR.G141.0th.sens.1.fits'))
    SENS_B   = scipy.interpolate.interp1d(RESP_B["WAVELENGTH"],RESP_B["SENSITIVITY"])

    config = {'EXT_A_0':EXT_A_0,'EXT_A_1':EXT_A_1,'RESP_A':RESP_A,'SENS_A':SENS_A,
              'DYDX_A_0':DYDX_A_0,'DYDX_A_1':DYDX_A_1,
              'DLDP_A_0':DLDP_A_0,'DLDP_A_1':DLDP_A_1,'DPDL_A_0':DPDL_A_0,'DPDL_A_1':DPDL_A_1,
              'EXT_B_0':EXT_B_0,'EXT_B_1':EXT_B_1,'RESP_B':RESP_B,'SENS_B':SENS_B,
              'DYDX_B_0':DYDX_B_0,
              'DLDP_B_0':DLDP_B_0,'DLDP_B_1':DLDP_B_1,'DPDL_B_0':DPDL_B_0,'DPDL_B_1':DPDL_B_1}

    return config

def get_pivot_delx(x,y,config):
    """
    Get the pivot wavelength where most of the flux for the zeroth order is transmitted.
    Ideally there is a range of x-pixels over which the zero order is dispersed, but
    we are only interested in identifying a single location for the zero order. Hence,
    we will use the pivot wavelength of the response curve.
    """
    wave_B = config['RESP_B']['WAVELENGTH']
    delx_B = config['DPDL_B_0'](x,y) + config['DPDL_B_1'](x,y)*wave_B
    return scipy.integrate.simps(delx_B*config['SENS_B'](wave_B),delx_B) / \
           scipy.integrate.simps(       config['SENS_B'](wave_B),delx_B)

def get_0th(x,y,config):
    """
    Perform the transformations using the aXe configuration parameters to find the
    position of the zero orders. This will return a single (x,y) coord for the zero
    order using the pivot wavlength for the zeroth order response curve.
    """
    delx = get_pivot_delx(x,y,config)
    dely = config['DYDX_B_0'](x,y)
    return x+delx, y+dely

get_0th = np.vectorize(get_0th,excluded=['config',])

def get_1st(x,y,config):
    """
    Perform the transformations using the aXe configuration parameters to find the
    position of the first order dispersion. This will return an array of (x,y) coords
    which identify the center of the dispersion trace for a given object.
    """
    delx = np.arange(config['EXT_A_0'],config['EXT_A_1'],1)
    dely = config['DYDX_A_0'](x,y) + config['DYDX_A_1'](x,y) * delx
    return x+delx, y+dely

class WISP_Region_Files():

    """
    Class to handle the creation of the WISP grism region files.

    Prerequisites:
        A WISP Par directory structure with grism and direct images available
        (both drizzled and undrizzled) as well as the source catalog.
        A config directory with grism response curves.

    Input:
        grism -- name of the grism [G102,G141]
        filt  -- name of the direct image filter [F110,F140,F160]
        config_path -- path to the config directory with grism response curve
        par_dir -- path to the WISP Par directory
        save_suffix -- provide a suffix to use when saving output files (to avoid
                       overwriting existing files)
    """

    def __init__(self,grism,filt,config_path,par_dir,save_suffix,mag_limit=None):

        """ Initialize the class with input parameters and check for the availability
        of config and input files. """

        self.grism = grism
        self.filt = filt
        self.config_path = config_path
        self.par_dir = par_dir
        self.save_suffix = save_suffix

        if mag_limit: self.mag_limit = mag_limit
        else: self.mag_limit = 23.5 if self.grism=='G102' else 23.0

        self.check_config_files()
        if not self.filt: self.get_direct_image_filter()
        self.check_input_files()

    def process(self):

        """ Main function to handle all the processing done by this class. Ideally,
        one should setup the class and use this function to perform all the tasks. """

        self.get_config()
        self.get_input()
        self.compute_positions()
        self.write_region_files()
        self.write_text_files()

        print "[WISP_grism_region_files.py] Finished writing region files for %s + %s." % (self.grism,self.filt)

    def check_config_files(self):

        """ Check the availability of the config files. """

        config_files = np.array([os.path.join(self.config_path,'WFC3.IR.G102.1st.sens.2.fits'),
                                 os.path.join(self.config_path,'WFC3.IR.G102.0th.sens.1.fits'),
                                 os.path.join(self.config_path,'WFC3.IR.G141.1st.sens.2.fits'),
                                 os.path.join(self.config_path,'WFC3.IR.G141.0th.sens.1.fits')])
        check_list = np.array([not os.path.isfile(fname) for fname in config_files])

        if any(check_list):
            raise Exception("[WISP_grism_region_files.py] Some config files not found. " \
                            "Please check the provided path to config directory: (%s)." % self.config_path)

    def check_input_files(self):

        """ Check the availability of the input files. """

        input_file_list = np.array([os.path.join(self.par_dir,'DATA/DIRECT_GRISM/%s.fits'     % self.filt),
                                    os.path.join(self.par_dir,'DATA/DIRECT_GRISM/%sW_drz.fits'% self.filt),
                                    os.path.join(self.par_dir,'DATA/DIRECT_GRISM/%s.fits'     % self.grism),
                                    os.path.join(self.par_dir,'DATA/DIRECT_GRISM/%s_drz.fits' % self.grism),
                                    os.path.join(self.par_dir,'DATA/DIRECT_GRISM/fin_%s.cat'  % self.filt)])

        check_list = np.array([not os.path.isfile(fname) for fname in input_file_list])

        if any(check_list):
            raise Exception("[WISP_grism_region_files.py] These input files were not found: %s. "\
                            "Please check the provided path to data directory: (%s). " % (
                                            ''.join(input_file_list[check_list]),self.par_dir))

    def get_direct_image_filter(self):

        """ When the direct filter is not defined (set to None), look for the available
        direct images to figure out the optimal filter to use. """

        if   self.grism=='G102':
            if   os.path.isfile(os.path.join(self.par_dir,'DATA/DIRECT_GRISM/F110.fits')):
                self.filt = 'F110'
                print "[WISP_grism_region_files.py] Using G102 + F110W."
            elif os.path.isfile(os.path.join(self.par_dir,'DATA/DIRECT_GRISM/F140.fits')):
                self.filt = 'F140'
                print "[WISP_grism_region_files.py] Warning: No F110W! Using G102 + F140W."
            elif os.path.isfile(os.path.join(self.par_dir,'DATA/DIRECT_GRISM/F160.fits')):
                self.filt = 'F160'
                print "[WISP_grism_region_files.py] Warning: No F110W or F140W! Using  G102 + F160W."
            else:
                raise Exception("[WISP_grism_region_files.py] No valid IR direct image found.")

        elif self.grism=='G141':
            if   os.path.isfile(os.path.join(self.par_dir,'DATA/DIRECT_GRISM/F160.fits')):
                self.filt = 'F160'
                print "[WISP_grism_region_files.py] Using G141 + F160W."
            elif os.path.isfile(os.path.join(self.par_dir,'DATA/DIRECT_GRISM/F140.fits')):
                self.filt = 'F140'
                print "[WISP_grism_region_files.py] Warning: No F160W! Using G141 + F140W."
            elif os.path.isfile(os.path.join(self.par_dir,'DATA/DIRECT_GRISM/F110.fits')):
                self.filt = 'F110'
                print "[WISP_grism_region_files.py] Warning: No F160W or F140W! Using G141 + F110W."
            else:
                raise Exception("[WISP_grism_region_files.py] No valid IR direct image found.")

        else: raise Exception("[WISP_grism_region_files.py] Invalid grism.")

    def get_config(self):

        """ Get the configuration parameters for the given grism and filter. """

        if   self.grism=='G102' and self.filt=='F110': self.config = get_config_G102_F110(config_path=self.config_path)
        elif self.grism=='G102' and self.filt=='F140': self.config = get_config_G102_F140(config_path=self.config_path)
        elif self.grism=='G102' and self.filt=='F160': self.config = get_config_G102_F160(config_path=self.config_path)
        elif self.grism=='G141' and self.filt=='F110': self.config = get_config_G141_F110(config_path=self.config_path)
        elif self.grism=='G141' and self.filt=='F140': self.config = get_config_G141_F140(config_path=self.config_path)
        elif self.grism=='G141' and self.filt=='F160': self.config = get_config_G141_F160(config_path=self.config_path)
        else: raise Exception("[WISP_grism_region_files.py] No config available for %s/%s combination." % (self.filt,self.grism))

    def get_input(self):

        """ Get the input files for the given grism and filter: direct image, grism image (both drizzled and undrizzled) along with
        the direct image catalog. """

        self.dir_flt_img,self.dir_flt_hdr = fitsio.getdata(os.path.join(self.par_dir,'DATA/DIRECT_GRISM/%s.fits'     % self.filt), header=True)
        self.dir_drz_img,self.dir_drz_hdr = fitsio.getdata(os.path.join(self.par_dir,'DATA/DIRECT_GRISM/%sW_drz.fits'% self.filt), header=True)
        self.grs_flt_img,self.grs_flt_hdr = fitsio.getdata(os.path.join(self.par_dir,'DATA/DIRECT_GRISM/%s.fits'     % self.grism),header=True)
        self.grs_drz_img,self.grs_drz_hdr = fitsio.getdata(os.path.join(self.par_dir,'DATA/DIRECT_GRISM/%s_drz.fits' % self.grism),header=True)

        self.dir_flt_wcs = WCS(self.dir_flt_hdr)
        self.dir_drz_wcs = WCS(self.dir_drz_hdr)
        self.grs_flt_wcs = WCS(self.grs_flt_hdr)
        self.grs_drz_wcs = WCS(self.grs_drz_hdr)

        self.catalog = np.genfromtxt(os.path.join(self.par_dir,'DATA/DIRECT_GRISM/fin_%s.cat' % self.filt),
                                        dtype=[('NAME','|S22'),('NUM',int),
                                               ('X',float),('Y',float),('A',float),('B',float),('THETA',float),
                                               ('RA',float),('DEC',float),('A_WORLD',float),('B_WORLD',float),('THETA_WORLD',float),
                                               ('MAG',float),('MAGERR',float),('CLASS_STAR',float),('FLAGS',int)])

        self.bright_cond = (self.catalog['MAG']<=self.mag_limit) & (self.catalog['NUM']<1000)

    def compute_positions(self):

        """ Compute the positions of the zeroth and first orders in the grism images. """

        # Setup different colors for bright and faint objects
        self.region_colors = np.array(['green']*len(self.catalog),dtype='|S5')
        self.region_colors[self.bright_cond] = 'red'

        # Location of sources in the drizzled direct image
        self.dir_drz_reg = np.recarray((len(self.catalog),),dtype=[('id',int),('x',float),('y',float),('mag',float),('color','|S5')])
        self.dir_drz_reg['x']     = self.catalog['X']
        self.dir_drz_reg['y']     = self.catalog['Y']
        self.dir_drz_reg['id']    = self.catalog['NUM']
        self.dir_drz_reg['mag']   = self.catalog['MAG']
        self.dir_drz_reg['color'] = self.region_colors

        # Location of sources in the un-drizzled direct image
        dir_flt_x,dir_flt_y = self.dir_flt_wcs.all_world2pix(self.catalog['RA'],self.catalog['DEC'],1)
        self.dir_flt_reg = np.recarray((len(self.catalog),),dtype=[('id',int),('x',float),('y',float),('mag',float),('color','|S5')])
        self.dir_flt_reg['x']     = dir_flt_x
        self.dir_flt_reg['y']     = dir_flt_y
        self.dir_flt_reg['id']    = self.catalog['NUM']
        self.dir_flt_reg['mag']   = self.catalog['MAG']
        self.dir_flt_reg['color'] = self.region_colors

        # Location of zeroth orders in the un-drizzled grism image
        grs_flt_x_0th,grs_flt_y_0th = get_0th(dir_flt_x,dir_flt_y,self.config)
        self.grs_flt_reg_0th = np.recarray((len(self.catalog),),dtype=[('id',int),('x',float),('y',float),('mag',float),('color','|S5')])
        self.grs_flt_reg_0th['x']     = grs_flt_x_0th
        self.grs_flt_reg_0th['y']     = grs_flt_y_0th
        self.grs_flt_reg_0th['id']    = self.catalog['NUM']
        self.grs_flt_reg_0th['mag']   = self.catalog['MAG']
        self.grs_flt_reg_0th['color'] = self.region_colors

        # Location of zeroth orders in the drizzled grism image
        _tmpx,_tmpy = self.grs_flt_wcs.all_pix2world(grs_flt_x_0th,grs_flt_y_0th,1)
        grs_drz_x_0th,grs_drz_y_0th = self.grs_drz_wcs.all_world2pix(_tmpx,_tmpy,1)
        self.grs_drz_reg_0th = np.recarray((len(self.catalog),),dtype=[('id',int),('x',float),('y',float),('mag',float),('color','|S5')])
        self.grs_drz_reg_0th['x']     = grs_drz_x_0th
        self.grs_drz_reg_0th['y']     = grs_drz_y_0th
        self.grs_drz_reg_0th['id']    = self.catalog['NUM']
        self.grs_drz_reg_0th['mag']   = self.catalog['MAG']
        self.grs_drz_reg_0th['color'] = self.region_colors

        # Location of first orders in the un-drizzled grism image
        grs_flt_x_1st,grs_flt_y_1st = np.zeros((2,len(self.catalog)))
        grs_flt_dx_1st = np.zeros(len(self.catalog))
        grs_flt_dy_1st = 8 * proj_plane_pixel_scales(self.grs_drz_wcs)[1] / proj_plane_pixel_scales(self.grs_flt_wcs)[1]
        for i,(x,y) in enumerate(zip(dir_flt_x,dir_flt_y)):
            fx,fy = get_1st(x,y,self.config)
            grs_flt_x_1st[i], grs_flt_y_1st[i] = np.mean(fx), np.median(fy)
            grs_flt_dx_1st[i] = fx[-1] - fx[0]
            grs_flt_th_1st = np.degrees(np.arctan((fy[-1]-fy[0])/(fx[-1]-fx[0])))
        self.grs_flt_reg_1st = np.recarray((len(self.catalog),),dtype=[('id',int),('x',float),('y',float),('dx',float),('dy',float),('theta',float),('mag',float),('color','|S5')])
        self.grs_flt_reg_1st['x']     = grs_flt_x_1st
        self.grs_flt_reg_1st['y']     = grs_flt_y_1st
        self.grs_flt_reg_1st['dx']    = grs_flt_dx_1st
        self.grs_flt_reg_1st['dy']    = grs_flt_dy_1st
        self.grs_flt_reg_1st['theta'] = grs_flt_th_1st
        self.grs_flt_reg_1st['id']    = self.catalog['NUM']
        self.grs_flt_reg_1st['mag']   = self.catalog['MAG']
        self.grs_flt_reg_1st['color'] = self.region_colors

        # Location of first orders in the drizzled grism image
        _tmpx,_tmpy = self.grs_flt_wcs.all_pix2world(grs_flt_x_1st,grs_flt_y_1st,1)
        grs_drz_x_1st,grs_drz_y_1st = self.grs_drz_wcs.all_world2pix(_tmpx,_tmpy,1)
        grs_drz_dx_1st = grs_flt_dx_1st * proj_plane_pixel_scales(self.grs_flt_wcs)[0] / proj_plane_pixel_scales(self.grs_drz_wcs)[0]
        grs_drz_dy_1st = 8
        self.grs_drz_reg_1st = np.recarray((len(self.catalog),),dtype=[('id',int),('x',float),('y',float),('dx',float),('dy',float),('theta',float),('mag',float),('color','|S5')])
        self.grs_drz_reg_1st['x']     = grs_drz_x_1st
        self.grs_drz_reg_1st['y']     = grs_drz_y_1st
        self.grs_drz_reg_1st['dx']    = grs_drz_dx_1st
        self.grs_drz_reg_1st['dy']    = grs_drz_dy_1st
        self.grs_drz_reg_1st['theta'] = grs_flt_th_1st
        self.grs_drz_reg_1st['id']    = self.catalog['NUM']
        self.grs_drz_reg_1st['mag']   = self.catalog['MAG']
        self.grs_drz_reg_1st['color'] = self.region_colors

    def write_region_files(self):

        """ Write out all the region files. """

        # Save the region file for the drizzled direct image
        np.savetxt(os.path.join(self.par_dir,'DATA/DIRECT_GRISM/%s_drz%s.reg' % (self.filt,self.save_suffix)),
                   self.dir_drz_reg[['x','y','color','id','mag']],
                   fmt="circle(%15.4f,%15.4f,5) #width=2 color=%s font='helvetica 14 bold' text={%i (%.2f)}", comments='')

        # Save the region file for the un-drizzled direct image
        np.savetxt(os.path.join(self.par_dir,'DATA/DIRECT_GRISM/%s%s.reg' % (self.filt,self.save_suffix)),
                   self.dir_flt_reg[['x','y','color','id','mag']],
                   fmt="circle(%15.4f,%15.4f,5) #width=2 color=%s font='helvetica 14 bold' text={%i (%.2f)}", comments='')

        # Save the region file for the un-drizzled grism image
        np.savetxt(os.path.join(self.par_dir,'DATA/DIRECT_GRISM/%s_0th%s.reg' % (self.grism,self.save_suffix)),
                   self.grs_flt_reg_0th[['x','y','color','id','mag']],
                   fmt="circle(%15.4f,%15.4f,5) #width=2 color=%s font='helvetica 14 bold' text={%i (%.2f)}", comments='')

        # Save the region file for the drizzled grism image
        np.savetxt(os.path.join(self.par_dir,'DATA/DIRECT_GRISM/%s_drz_0th%s.reg' % (self.grism,self.save_suffix)),
                   self.grs_drz_reg_0th[['x','y','color','id','mag']],
                   fmt="circle(%15.4f,%15.4f,5) #width=2 color=%s font='helvetica 14 bold' text={%i (%.2f)}", comments='')

        # Save the region file for the un-drizzled grism image
        np.savetxt(os.path.join(self.par_dir,'DATA/DIRECT_GRISM/%s_1st%s.reg' % (self.grism,self.save_suffix)),
                   self.grs_flt_reg_1st[['x','y','dx','dy','theta','color','id']],
                   fmt="box(%15.4f,%15.4f,%10.2f,%10.2f,%10.2f) #width=1 color=%s font='helvetica 14 bold' text={%i}", comments='')

        # Save the region file for the drizzled grism image
        np.savetxt(os.path.join(self.par_dir,'DATA/DIRECT_GRISM/%s_drz_1st%s.reg' % (self.grism,self.save_suffix)),
                   self.grs_drz_reg_1st[['x','y','dx','dy','theta','color','id']],
                   fmt="box(%15.4f,%15.4f,%10.2f,%10.2f,%10.2f) #width=1 color=%s font='helvetica 14 bold' text={%i}", comments='')

    def write_text_files(self):

        """ Write out all the region files. """

        # Save the text file for the un-drizzled grism image
        np.savetxt(os.path.join(self.par_dir,'DATA/DIRECT_GRISM/%s_0th%s.txt' % (self.grism,self.save_suffix)),
                   self.grs_flt_reg_0th[['id','x','y','mag']],
                   fmt="%5i%15.4f%15.4f%15.4f",
                   header="Position of Zeroth orders\n" \
                          "%3s%15s%15s%15s" % ("ID","x","y",self.filt+"_MAG"))

        # Save the text file for the drizzled grism image
        np.savetxt(os.path.join(self.par_dir,'DATA/DIRECT_GRISM/%s_drz_0th%s.txt' % (self.grism,self.save_suffix)),
                   self.grs_drz_reg_0th[['id','x','y','mag']],
                   fmt="%5i%15.4f%15.4f%15.4f",
                   header="Position of Zeroth orders\n" \
                          "%3s%15s%15s%15s" % ("ID","x","y",self.filt+"_MAG"))

        # Save the text file for the un-drizzled grism image
        np.savetxt(os.path.join(self.par_dir,'DATA/DIRECT_GRISM/%s_1st%s.txt' % (self.grism,self.save_suffix)),
                   self.grs_flt_reg_1st[['id','x','y','dx','theta','mag']],
                   fmt="%5i%15.4f%15.4f%10.2f%10.2f%15.4f",
                   header="Position of First orders\n(x,y) gives the center of the box and dx gives the length\n" \
                          "%3s%15s%15s%10s%10s%15s" % ("ID","x","y","dx","theta",self.filt+"_MAG"))

        # Save the text file for the drizzled grism image
        np.savetxt(os.path.join(self.par_dir,'DATA/DIRECT_GRISM/%s_drz_1st%s.txt' % (self.grism,self.save_suffix)),
                   self.grs_drz_reg_1st[['id','x','y','dx','theta','mag']],
                   fmt="%5i%15.4f%15.4f%10.2f%10.2f%15.4f",
                   header="Position of First orders\n(x,y) gives the center of the box and dx gives the length\n" \
                          "%3s%15s%15s%10s%10s%15s" % ("ID","x","y","dx","theta",self.filt+"_MAG"))

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument("grism",help="provide the grism name ['G102','G141']",type=str)
    parser.add_argument("-f","--filter",help="provide the direct image filter ['F110','F140','F160']",type=str,default=None)
    parser.add_argument("-c","--config",help="provide the path to config files [default: config/]",type=str,default='config/')
    parser.add_argument("-p","--par_dir",help="provide the path to the PAR directory [default: <current_dir>]",type=str,default='')
    parser.add_argument("-s","--save_suffix",help="provide a suffix to add when saving files in order to prevent overwriting existing files [default: <no_suffix>]",type=str,default='')
    args = parser.parse_args()

    WISP_reg_files = WISP_Region_Files(grism=args.grism,filt=args.filter,config_path=args.config,par_dir=args.par_dir,save_suffix=args.save_suffix)
    WISP_reg_files.process()