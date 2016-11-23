import os
import sys
from glob import glob
import numpy as np
from astropy.io import fits
from scipy.linalg import lstsq
import scipy.ndimage as nd
from scipy import optimize


class Grism():
    """Class to define parameters for the grism and create an object mask.

    Defines pathnames, filesnames, appropriate flats and catalogs. 
    Masks out object spectra using the direct image catalog.

    Args:
        gfilt (str): grism filter
        image (str): filename of grism image (only the basename)
        directlist (dict): dictionary containing arrays of direct image
            filenames for each filter
    """
    def __init__(self, gfilt, image, directlist):
        # path to grism images and SExtractor catalogs
        self.gpath = 'DATA/GRISM'
        self.dpath = 'DATA/DIRECT'
        self.gfilt = gfilt
        if gfilt == 'G102':
            self.set_G102()
        if gfilt == 'G141':
            self.set_G141()

        # grism filename and full path
        self.grism = os.path.join(self.gpath, image)
        # observation set ID
        self.base = os.path.basename(self.grism)[4:6]

        # find grism flat
        self.grism_flat = self.get_flat(image=self.grism)

        # direct image for masking 0th and 1st orders
        self.direct, self.filt = self.get_direct_image(directlist)

        # direct image flat    
        self.direct_flat = self.get_flat(imtype='direct')

        # SExtractor catalog
        self.cat = self.direct + '.coo'
        
        # check if a mask has already been made
        masks = glob(os.path.join(self.gpath, '*masked.fits'))
        usemasks = [x for x in masks if (os.path.basename(x)[4:6] == self.base) & (fits.getheader(x,0)['FILTER'] == self.gfilt)]
        if len(usemasks) > 0:
            self.mask = usemasks[0]
        else:
            # mask grism image
            self.mask = self.mask_objects()
            

    def get_direct_image(self, directlist):
        """Sets the direct image appropriate for masking the grism.

        Finds the direct image(s) associated with the grism image. 
        Filters are prioritized by the order given in self.filtlist. 
        For example, when matching to a G102 image, get_direct_image() first 
        checks for F110W images. If none exist for this field, it will 
        instead use F140W image, or an F160W image as a last resort. 

        Matching filters in this way probably has a very minor effect on
        the resulting mask (there may be some objects that are detected
        in just a single filter). It is more important that the grism
        is matched to a direct image with the same observation set ID, 
        especially for fields with multiple visits and therefore small 
        pointing differences.

        Args:
            directlist (dict): dictionary containing arrays of direct image
            filenames for each filter

        Returns:
            (tuple): tuple containing:
            
                direct (str): filename of appropriate direct image
                usefilt (str): filter of direct image
        """
        # prioritize filters in choosing direct image
        if len(directlist[self.filtlist[0]]) > 0:
            usefilt = self.filtlist[0]
        elif len(directlist[self.filtlist[1]]) > 0:
            usefilt = self.filtlist[1]
        elif len(directlist[self.filtlist[2]]) > 0:
            usefilt = self.filtlist[2]

        # find direct images with same observation set ID
        directimages = [x for x in directlist[usefilt] if x[4:6] == self.base]
        for directimage in directimages:
            if os.path.exists(os.path.join(self.dpath,directimage)):
                direct = os.path.join(self.dpath,directimage)
                break
        try:
            direct
        except UnboundLocalError:
            print '\nWARNING: No direct image match for grism image %s' % \
                        os.path.basename(self.grism)
            print 'Using %s\n' % directlist[usefilt][0]
            direct = os.path.join(self.dpath, directlist[usefilt][0])
        return direct, usefilt


    def get_flat(self, image=None, imtype='grism'):
        """Get the name of the appropriate imaging flat to use with this grism.

        From ISR WFC3 2015-17 (Brammer et al. 2015):
            The master skies were computer from calibrated images with the 
            appropriate imaging flat-field images divided out. In order to 
            fit and subtract the master sky images to observed FLT images, 
            the imaging flat must be divided from the science image.

        The imaging flat fields are:
            G102:  F105W - uc72113oi_pfl.fits
            G141:  F140W - uc721143i_pfl.fits
        """
        if imtype == 'direct':
            if self.gfilt == 'G102':
                # F105 flat
                pfl = 'uc72113oi_pfl.fits'
            elif self.gfilt == 'G141':
                # F140 flat
                pfl = 'uc721143i_pfl.fits'
        elif imtype == 'grism':
            pfl = fits.getheader(image)['PFLTFILE'].split('$')[1]
        return pfl


    def set_G102(self):
        """Defines the positions and offsets of the orders in the G102 image.

        BEAMA,B: the extent of the BEAM in the x direction wrt the
            reference pixel of the BEAM 
        XOFFB: the pixel row offset between the reference pixel of BEAM B
            and the position of the object in the direct image. This is
            a field-dependent offset, defined at a given position (x,y) 
            by a polynomial of the form:
                a0 + a1*X + a2*Y
            where X = x-REFX and Y=y-REFY

        Values are taken from the G102 config file: WFC3.IR.G102.V2.0.conf
        """
        self.beama = [41, 248]
        self.beamb = [-280, -240]
        self.xoffb = [-0.1763171, -0.0017154, 0.0150110]
#        """From G102.F*W.V4.32.conf"""
#        self.beama = [41, 248]
#        self.beamb = [-280, -220]
#        self.xoffb = [0.0]

        # set the order in which to use direct image catalogs for masking
        #   only use F160 if nothing else is available
        self.filtlist = ['F110', 'F140', 'F160']


    def set_G141(self):
        """Defines the positions and offsets of the orders in the G141 image.

        BEAMA,B: the extent of the BEAM in the x direction wrt the
            reference pixel of the BEAM 
        XOFFB: the pixel row offset between the reference pixel of BEAM B
            and the position of the object in the direct image. This is
            a field-dependent offset, defined at a given position (x,y) 
            by a polynomial of the form:
                a0 + a1*X + a2*Y
            where X = x-REFX and Y=y-REFY

        Values are taken from the G141 config file: WFC3.IR.G141.V2.0.conf
        """
        self.beama = [15, 196]
        self.beamb = [-207, -177]
        self.xoffb = [-0.2400520, -0.0023144, 0.0111089]
        
        # set the order in which to use direct image catalogs for masking
        #   only use F110 if nothing else is available
        self.filtlist = ['F160', 'F140', 'F110']


    def sigma_clip(self, imarr, sig):
        """Performs sigma clipping on a data array.
 
        Args:
            imarr (float): data array
            sig (float): sigma of clipping
        
        Returns:
            w (tuple): the indices of pixels to be clipped
        """
        med = np.median(imarr[imarr != 0])
        std = np.std(imarr[imarr != 0])
        w = np.where(imarr > (med + sig*std))
        return w


    def mask_objects(self):
        """Masks 0th and 1st orders of the grism image.

        0th and 1st orders are zeroed out of the grism image and the
        resulting masked image is written to file. The output is 
        [grism_image]_masked.fits

        Returns:
            output (str): filename of mask
        """
        im,hdr = fits.getdata(self.grism, header=True)
        y,x = np.ogrid[:im.shape[0], :im.shape[1]]

        cat = np.genfromtxt(self.cat)
        ##-->
        # the catalogs contain entries from running sextractor on each
        # image extension. Use only those from the SCI extension
        # MR Oct 2016 changed this to only run sextractor on the SCI extension
        # So had to change this code as well.
        #w = np.where(cat[:,0] == 1)
        #pdb.set_trace()
        #nobj = w[0][1]
        nobj = cat.shape[0]
        #for i in range(cat[:,0].shape[0]):
        for i in range(nobj):
        ##<--
            ### define the ellipse
            xc = cat[:,1][i]
            yc = cat[:,2][i]
            a = cat[:,3][i]
            b = cat[:,4][i]
            # convert position angle to radians
            # SExtractor defines position angle CCW from x
            theta = 2*np.pi - cat[:,5][i] * np.pi/180.
            A = (np.cos(theta)/a)**2 + (np.sin(theta)/b)**2
            B = -2. * np.cos(theta) * np.sin(theta) * (1/a**2 - 1/b**2)
            C = (np.sin(theta)/a)**2 + (np.cos(theta)/b)**2

            ### 1st order ###
            # extent of 1st order
            xmin = xc + self.beama[0]
            xmax = xc + self.beama[1]
            # spatial extent
            r2 = A*(x-xc)**2 + B*(x-xc)*(y-yc) + C*(y-yc)**2
            mask = np.where(r2 <= (3.5)**2)
            ymin = np.min(mask[0])
            ymax = np.max(mask[0])
            # mask
            im[ymin:ymax,xmin:xmax] = 0

            ### 0th order ###
            # offset in x
            xoff = xc + self.xoffb[0] + self.xoffb[1]*xc + self.xoffb[2]*yc
            # extent of 0th order
            xmin = xoff + self.beamb[0]
            xmax = xoff + self.beamb[1]
            # center of 0th order
            xb = (xmin + xmax) / 2.
            # mask 0th order
            r2 = A*(x-xb)**2 + B*(x-xb)*(y-yc) + C*(y-yc)**2
            mask = np.where(r2 < (3.5)**2)
            # mask
            im[mask] = 0

        ### mask left column ###
        # try 2 rounds of sigma clipping on left column
        left = im[:,:100]
        mask = self.sigma_clip(left, 1.5)
        im[mask] = 0

        del left
        left = im[:,:100]
        mask2 = self.sigma_clip(left, 1.5)
        im[mask2] = 0

        hdr['FILTER'] = self.gfilt
        output = self.grism.replace('.fits','_masked.fits')
        fits.writeto(output, im, header=hdr, clobber=True)
        return output


def set_grism_flat(grism, verbose=True):
    """Sets the flat to be used in processing the grism FLTs.

    The FLT will be multipled by the appropriate grism flat-field image
    and divided by the direct flat-field image that was used in 
    creating the master skies. 

    Args:
        grism (fit_multi_sky.Grism): instance of Grism class
        verbose (Optional[bool]): print the names of the flats to stdout.
            Default is True.

    Returns:
        flat (float): the grism flat divided by the imaging flat
    """
    if verbose:
        print 'Set flat for grism: %s' % grism.gfilt
        print '    Grism flat: %s' % grism.grism_flat
        print '    Image flat: %s' % grism.direct_flat

    iref = os.getenv('iref')
    direct_flat = fits.open(os.path.join(iref, grism.direct_flat))
    grism_flat = fits.open(os.path.join(iref, grism.grism_flat))

    # divide grism flat by image flat
    flat = grism_flat[1].data[5:1019,5:1019]/direct_flat[1].data[5:1019,5:1019]

    flat[flat <= 0] = 5
    flat[flat > 5] = 5

    return flat


def obj_lstsq(x, b, A, wht):
    """Objective function for least squares."""
    return (b-np.dot(x, A))*wht


def fit_sky(grism, skypath, add_constant=True, verbose=True):
    """Fit multiple sky components to the background of an FLT.

    Fit the background in two iterations, one with and one without weights.
    Get least-sq coefficients of the multiple sky components. Build a model
    of the sky as a linear combination of these components and use this 
    to sky-subtract the FLT.

    Input FLT image is overwritten with the corrected (sky-subtracted) version.

    Args:
        grism (fit_multi_sky.Grism): instance of Grism class
        skypath (str): path (relative or absolute) to directory containing
            the master skies.
        add_constant (Optional[bool]): add a constant background value to fit
        verbose (Optional[bool]): print info about the fit to stdout.
            Default is True.
    """
    flt = grism.grism
    im = fits.open(flt, mode='update', do_not_scale_image_data=True)
    gfilt = grism.gfilt

    if verbose:
        print '\nFitting %s:  %s' % (gfilt, os.path.basename(flt))
        print 'Using mask: %s from %s direct image catalog' % (
                    os.path.basename(grism.mask), grism.filt)

    # get flat
    flat = set_grism_flat(grism, verbose=verbose)

    # masked grism image
    masked_im = fits.getdata(grism.mask)

    # master skies from grism_master_sky_v0.5.tar.gz
    skies = ['excess_%s_clean.fits'%gfilt, 'excess_lo_%s_clean.fits'%gfilt, \
             'zodi_%s_clean.fits'%gfilt, '%s_scattered_light.fits'%gfilt]
    skies = [x for x in skies if (os.path.exists(os.path.join(skypath,x)) == 1)]
    ims = []

    for sky in skies:
        mastersky = os.path.join(skypath, sky)
        if os.path.exists(mastersky):
            ims.append(fits.open(mastersky)[0].data.flatten())

    if add_constant:
        ims.append(im[1].data.flatten()*0. + 1)
        skies.append('Constant')

    ims = np.array(ims)

    # define basic mask
    dq_ok = (im[3].data & (4+32+16+512+2048+4096)) == 0
    mask = (masked_im != 0) & dq_ok

    #####################################################
    ### first iteration of fit: non-weighted least-sq ###
    #####################################################
    # The areas of sky to use in calculating fit:
    #   unmasked, i.e. no object flux (masked_im != 0)
    #   DQ mask is ok, i.e. no bad pixels
    #   WHT > 0
    #   image*flat between 1st and 98th percentiles
    mask_full = dq_ok & ((im[1].data*flat) < np.percentile((im[1].data*flat)[mask], 98)) & (im[2].data > 0) & ((im[1].data*flat) > np.percentile((im[1].data*flat)[mask], 1)) & (masked_im != 0)

    data = (im[1].data*flat)[mask_full].flatten()
    xcoeff, resid, rank, ss = lstsq(ims[:, mask_full.flatten()].T, data)
    model = np.dot(xcoeff, ims).reshape((1014,1014))
    # correct for sky
    corr = im[1].data*flat - model

    ########################################################
    # second iteration: improved mask, weighted least-sq ###
    ########################################################
    # Areas of sky to use in second iteration:
    #   unmasked, i.e. no object flux (masked_im != 0)
    #   DQ mask is ok, i.e. no bad pixels
    #   WHT > 0
    #   corrected image from first iteration between 1st and 98th percentiles
    mask_full = dq_ok & (corr < np.percentile(corr[mask], 98)) & (im[2].data > 0) & (corr > np.percentile(corr[mask], 1)) & (masked_im != 0)

    data = (im[1].data*flat)[mask_full].flatten()
    wht = 1./(im[2].data)[mask_full].flatten()
    p0 = np.ones(ims.shape[0])
    popt = optimize.leastsq(obj_lstsq, p0, 
                            args=(data, ims[:,mask_full.flatten()], wht), 
                            full_output=True, ftol=1.49e-8/1000., 
                            xtol=1.49e-8/ 1000.)
    xcoeff = popt[0]
    model = np.dot(xcoeff, ims).reshape((1014,1014))
    corr = im[1].data*flat - model

    ######################### 
    ### remove bad pixels ###
    #########################
    # bad pixels will be replaced with Gaussian noise
    data = corr[mask_full]
    hist,bins = np.histogram(data, bins=np.arange(-0.1,0.1,0.001))
    bc = 0.5 * (bins[1:] + bins[:-1])
    binsize = bins[1] - bins[0]
    # fit a gaussian
    gaussfunc = lambda x,a,mu,sig: a * np.exp(-(x-mu)**2 / (2.*sig**2))
    p0 = [np.max(hist), bc[hist.shape[0]/2.],(np.max(bc)-np.min(bc))/4.]
    popt,pcov = optimize.curve_fit(gaussfunc, bc, hist, p0=p0)
    mu = popt[1] if popt[1] >= 0. else 0.
    sigma = np.abs(popt[2])
    # replace pixels identified as bad detector pixels in the DQ array
    bad = np.where(im[3].data & 4 == 4)
    noise = np.random.normal(0, 1, corr[bad].shape[0])
    corr[bad] = mu + noise * sigma

    # replace the bad pixels that the flat reintroduces
    blurred = nd.median_filter(corr, size=5)
    w = np.where((im[3].data & (8+16+32)) != 0)
    corr[w] = blurred[w]

    if verbose:
        print 'Simultaneous sky components:'
    for i in range(len(skies)):
        if verbose:
            print '   %s %.3f' %(skies[i], xcoeff[i])
        # Update header keywords    
        im[0].header['GSKY%02d' %(i+1)] = (xcoeff[i], 
                                           'Grism    sky: %s' %(skies[i]))

    # Put the result in the FLT data extension
    im[1].data = np.float32(corr*1.)
    im.flush()


def clean_par(skypath, verbose=True):
    """Cleans all grism FLTs for the Par.

    Direct images and image lists should be in DATA/DIRECT.
    Grism images and image lists should be in DATA/GRISM.

    The FLT images are overwritten with the corrected   
    (sky-subtracted) versions.

    Args:
        skypath (str): path (relative or absolute) to directory containing
            the master skies.
        verbose (Optional[bool]): print info about the masking and sky fit 
            to stdout. Default is True
    """
    # lists of images to be corrected
    g102list = 'DATA/GRISM/G102_clean.list'
    g141list = 'DATA/GRISM/G141_clean.list'

    # image lists, necessary for determining which flats to use
    directlist = {}
    for filt in ['F110', 'F140', 'F160']:
        filtlist = np.array([], dtype='S100')
        imlist = 'DATA/DIRECT/%s_clean.list'%filt
        if os.stat(imlist).st_size != 0:
            d = np.genfromtxt(imlist, dtype='S100')
            print d.size,d,imlist
            if d.size != 0:
             if d.size==1:
              AA=d
             if d.size>1:
              AA=d[0]
             if AA != 'none':
                filtlist = np.append(filtlist, d)
        directlist[filt] = filtlist

    for glist,filt in zip([g102list,g141list],['G102','G141']):
        # not every par has both grisms
        if os.stat(glist).st_size != 0:
            imlist = np.genfromtxt(glist, dtype='S100')
            for image in imlist:
                # check that grism file in G*_clean.list exists
                if os.path.exists(os.path.join('DATA/GRISM',image)):
                    grism = Grism(filt, image, directlist)
                    fit_sky(grism, skypath, verbose=verbose)


def main():
    """Stand-alone script to fit grism FLTs with a multi-component sky.
    
    Based on threedhst.grism_sky written by Gabe Brammer.
    See the ISR WFC3 2015-17 (Brammer et al. 2015)
    http://www.stsci.edu/hst/wfc3/documents/ISRs/WFC3-2015-17.pdf    

    Master skies are:
        Zodiacal background: zodi_G102_clean.fits, zodi_G141_clean.fits
        Helium excess: excess_G102_clean.fits, excess_lo_G141_clean.fits
        Scattered light: G141_scattered_light.fits

    Args:
        argv[1]: path (relative or absolute) to directory containing
            the master skies.
    """
    skypath = sys.argv[1]
    clean_par(skypath)


if __name__ == '__main__':
    main()
