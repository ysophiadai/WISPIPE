
# coding: utf-8

from astropy.io import fits as astrofits
from astropy.utils.exceptions import AstropyDeprecationWarning
import numpy as np
import pandas as pd
import pyregion # http://pyregion.readthedocs.io/en/latest/
import copy
import itertools
import warnings
import time
from matplotlib import pyplot as pyplot

# suppress annoying warnings from astropy!
warnings.simplefilter('ignore', AstropyDeprecationWarning)

class ZerothOrderWavelengthRanges():
    """
    A class that determines the ranges of wavelengths within a particular drizzled, wavelength calibrated
    stamp image for a target of interest that intersect with the positions of zeroth order dispersion images
    for non-target sources.

    The class can compute and return sequences of wavelength ranges within the stamp that intersect with the
    positions of zeroth order dispersion images.

    The class distinguished two categories of zeroth order images:
    1) Those that intersect with the non-zero region of the spectrum extraction model extension in the drizzled
    stamp FITS file. These are more likely to contaminate the extracted spectrum.
    2) Those that fall anywhere within the drizzled stamp image bounds (including those in category 1).

    If supplied a single wavelength (in Angstrom units), the class's getWavelengthZeroOrderFlag method will
    return an integer flag that can assume the following values:
    0 -- If no zeroth order images fall within the stamp bounds at the specified wavelength.
    1 -- If at least one zeroth order image falls within the stamp bounds but outside the non-zero region
     of the spectrum extraction model extension at the specified wavelength.
    2 -- If at least one zeroth order image falls within the non-zero region of the spectrum extraction
    model extension at the specified wavelength.
    3 -- If at least one zeroth order image for an object with direct image magnitude brighter than a settable
    threshold (default is 22.5) falls within the non-zero region of the spectrum extraction model extension
    at the specified wavelength.

    If supplied a 1-dimensional array-like sequence of values specifying wavelengths (in Angstrom units),
    the class's getWavelengthZeroOrderFlags method will return a similarly sized numpy.ndarray, populated
    with integer flag values with identical interpretation to the flag returned by the getWavelengthZeroOrderFlag
    method.
    """

    def __init__(self,
                 zerothOrderRegionFilePath,
                 sextractorCatalogueFilePath,
                 posAngleCorrection = 0.0,
                 regionMajorAxisPaddingFactor = 1.0,
                 regionMinorAxisPaddingFactor = 1.0,
                 brightSourceMagnitudeThreshold = 22.5) :
        """
        Constructor:

        Positional Arguments:

        zerothOrderRegionFilePath -- The path of the SAO DS9 format region file specifying the
        positions of the zeroth order dispersion images in the appropriate full, drizzled grism
        image.

        sextractorCatalogueFilePath -- The path of the catalogue file that is produced for the
        direct image FITS file by the sextractor utility. This is used to determine the likely
        extent and shape of the zeroth order region image.

        Keyword Arguments :

        posAngleCorrection -- Optional correction in clockwise degrees to be applied to the position
        angle of an elliptical zeroth order region (default: 0)

        regionMajorAxisPaddingFactor -- Optional multiplicative factor intended to increase the major
        axis length of an elliptical region in order to provide a margin of saftey if desired (default: 1).

        regionMinorAxisPaddingFactor -- Optional multiplicative factor intended to increase the minor
        axis length of an elliptical region in order to provide a margin of saftey if desired (default: 1).

        """
        # Class properties that are initialized upon construction
        self.drizzledStampPath = None
        self.zerothOrderRegionFilePath = zerothOrderRegionFilePath
        self.sextractorCatalogueFilePath = sextractorCatalogueFilePath
        self.brightSourceMagnitudeThreshold = brightSourceMagnitudeThreshold

        # Class properties that are initialized lazily as required by the various class methods
        self.drizzledStampScienceHeader = None
        self.drizzledStampModelExtension = None
        self.sextractorCatalogue = None
        self.drizzleCoefficients = None
        self.drizzledStampBBoxCoordinates = None
        self.drizzledStampWavelengthParameters = None
        self.rawZerothOrderRegions = None
        self.zerothOrderRegions = None
        self.zerothOrderRegionMask = None
        self.brightZerothOrderRegionMask = None
        self.extractionModelMask = None

        # Class properties that encapsulate the final computation products
        self.regionWavelengthRanges = None
        self.regionInModelWavelengthRanges = None
        self.brightRegionWavelengthRanges = None
        self.brightRegionInModelWavelengthRanges = None

        # Class properties that may be initialized upon construction if specified
        # but will fall back to effective no-op defaults otherwise.
        self.regionPositionAngleCorrection = posAngleCorrection
        self.regionMajorAxisPaddingFactor = regionMajorAxisPaddingFactor
        self.regionMinorAxisPaddingFactor = regionMinorAxisPaddingFactor

        # region loading is time consuming so only perform this step once per field
        self.loadRegions()
        # the following need only occur once per field
        self.parseSextractorCatalogue()

        print('ZerothOrderWavelengthRanges constructor\n{}\n{}'.format(zerothOrderRegionFilePath,sextractorCatalogueFilePath))

    def loadRegions(self) :
        """
        Utility method uses the pyregion module (http://pyregion.readthedocs.io/en/latest/) to load
        and parse a SAO DS9 format region file specifying the positions of the zeroth order dispersion
        images in the appropriate full, drizzled grism
        image.
        """
        if self.rawZerothOrderRegions is None :
            self.rawZerothOrderRegions = pyregion.open(self.zerothOrderRegionFilePath)

    def loadDrizzledStampScienceHeader(self) :
        """
        Utility method loads the header for the science extension from the drizzled stamp
        FITS file.
        """
        if self.drizzledStampScienceHeader is None :
            # Load the science header from the drizzled stamp FITS file
            self.drizzledStampScienceHeader = astrofits.getheader(self.drizzledStampPath, 'SCI')

    def loadDrizzledStampModelExtension(self) :
        """
        Utility method loads the data for the extraction model extension from the drizzled stamp
        FITS file.
        """
        if self.drizzledStampModelExtension is None :
            self.drizzledStampModelExtension = astrofits.getdata(self.drizzledStampPath, 'MOD')

    def loadWavelengthParameters(self) :
        """
        Utility method that loads the coefficients required to map from x-pixel to wavelength coordinates
        within the drizzled stamp images from the corresponding 'SCI' extension header.
        """
        if self.drizzledStampScienceHeader is None :
            self.loadDrizzledStampScienceHeader()

        if self.drizzledStampWavelengthParameters is None :
            self.drizzledStampWavelengthParameters = {'CRPIX1' : self.drizzledStampScienceHeader['CRPIX1'],
                                                      'CRVAL1' : self.drizzledStampScienceHeader['CRVAL1'],
                                                      'CDELT1' : self.drizzledStampScienceHeader['CDELT1']}

    def loadDrizzleCoefficients(self) :
        """
        Utility method that loads the coefficients used by the aXedrizzle utility to wavelength calibrate
        the drizzled stamp image and rectify any curvature of the spectral trace the drizzled stamp 'SCI'
        extension header.
        """
        if self.drizzledStampScienceHeader is None :
            self.loadDrizzledStampScienceHeader()

        if self.drizzleCoefficients is None :
            self.drizzleCoefficients = {'D001OUXC' : self.drizzledStampScienceHeader['D001OUXC'],
                                        'D001OUYC' : self.drizzledStampScienceHeader['D001OUYC'],
                                        'DRZ00' : self.drizzledStampScienceHeader['DRZ00'],
                                        'DRZ10' : self.drizzledStampScienceHeader['DRZ10'],
                                        'DRZ01' : self.drizzledStampScienceHeader['DRZ01'],
                                        'DRZ11' : self.drizzledStampScienceHeader['DRZ11'],
                                        'D001INXC' : self.drizzledStampScienceHeader['D001INXC'],
                                        'DRZ02' : self.drizzledStampScienceHeader['DRZ02'],
                                        'DRZ12' : self.drizzledStampScienceHeader['DRZ12'],
                                        'D001INYC' : self.drizzledStampScienceHeader['D001INYC']}

    def loadDrizzledStampBBoxCoordinates(self) :
        """
        Utility method that loads the coordinates of the drizzled stamp bounding box in the full,
        drizzled grism image from the drizzled stamp 'SCI' extension header.
        """
        if self.drizzledStampScienceHeader is None :
            self.loadDrizzledStampScienceHeader()

        if self.drizzledStampBBoxCoordinates is None :
            self.drizzledStampBBoxCoordinates = ((self.drizzledStampScienceHeader['BB0X'], self.drizzledStampScienceHeader['BB0Y']),
                                                 (self.drizzledStampScienceHeader['BB1X'], self.drizzledStampScienceHeader['BB1Y']))

    def applyDrizzleCoefficients(self) :
        """
        Method which corrects the positions of the zeroth order image regions within the stamp to reflect the
        distortions introduced by the aXedrizzle utility. See http://adsabs.harvard.edu/abs/2005ASPC..347..138K
        for more details.
        """
        if self.drizzleCoefficients is None :
            self.loadDrizzleCoefficients()

        # operate on a copy of the parsed region data
        zerothOrderRegionsCopy = copy.deepcopy(self.zerothOrderRegions)

        for region in zerothOrderRegionsCopy :
            # Apply a 1 pixel decrement because ds9 region files enumerate pixels from 1
            # whereas the drizzle correction assumes a zero pixel origin
            region.coord_list[0] -= 1
            region.coord_list[1] -= 1

            # Apply the drizzle corrections as specified in: http://adsabs.harvard.edu/abs/2005ASPC..347..138K
            correctedX = self.drizzledStampScienceHeader['D001OUXC'] + (self.drizzledStampScienceHeader['DRZ00'] + self.drizzledStampScienceHeader['DRZ01']*(region.coord_list[0]-self.drizzledStampScienceHeader['D001INXC']) + self.drizzledStampScienceHeader['DRZ02']*(region.coord_list[1]-self.drizzledStampScienceHeader['D001INYC']))
            correctedY = self.drizzledStampScienceHeader['D001OUYC'] + (self.drizzledStampScienceHeader['DRZ10'] + self.drizzledStampScienceHeader['DRZ11']*(region.coord_list[0]-self.drizzledStampScienceHeader['D001INXC']) + self.drizzledStampScienceHeader['DRZ12']*(region.coord_list[1]-self.drizzledStampScienceHeader['D001INYC']))

            # There is no need to reapply the 1 pixel offset since this is handled by the pyregion module
            # processing that happens later
            region.coord_list[0] = correctedX
            region.coord_list[1] = correctedY

        # Replace the originally parsed regions with the modified regions
        self.zerothOrderRegions = zerothOrderRegionsCopy

    def parseSextractorCatalogue(self) :
        """
        Utility method that parses the catalogue of sources extracted from the direct image by the
        sextractor utility
        """
        if self.sextractorCatalogue is None :
            self.sextractorCatalogue = pd.read_csv(self.sextractorCatalogueFilePath,
                                                   delim_whitespace=True,
                                                   header=0,
                                                   names=['RA_DEC_NAME',
                                                          'NUMBER',
                                                          'X_IMAGE',
                                                          'Y_IMAGE',
                                                          'A_IMAGE',
                                                          'B_IMAGE',
                                                          'THETA_IMAGE',
                                                          'X_WORLD',
                                                          'Y_WORLD',
                                                          'A_WORLD',
                                                          'B_WORLD',
                                                          'THETA_WORLD',
                                                          'MAG', # Use a generic name here to account for different filters
                                                          'MAGERR_AUTO',
                                                          'CLASS_STAR',
                                                          'FLAGS'], comment='#', engine='c')

    def applyRegionShapesFromCatalogue(self) :
        """
        Method that modifies the shape parameters of the zeroth order regions to better reflect the
        morphology of the direct target image that is specified in the catalogue file that is produced by
        the sextractor utility
        """
        if self.sextractorCatalogue is None :
            self.parseSextractorCatalogue()

        # operate on a copy of the parsed region data
        zerothOrderRegionsCopy = copy.deepcopy(self.zerothOrderRegions)

        for region in zerothOrderRegionsCopy :
            # Extract the object ID for the zeroth order being processed from the region file annotation
            if 'circle' not in region.name and 'ellipse' not in region.name :
                continue
            zeroOrderId = int(region.attr[1]['text'].split()[0])
            # Attempt to extract the elliptical shape parameters for the object ID from the parsed sextractor catalogue
            zeroOrderImageData = self.sextractorCatalogue[self.sextractorCatalogue['NUMBER'] == zeroOrderId][['A_IMAGE','B_IMAGE','THETA_IMAGE']]
            # Initialize the zeroth order region parameters in case the required object ID could not be found in the catalogue
            majorAxis, minorAxis, positionAngle = (5, 5, 0)
            # If the object ID was found in the catalogue then replace the initial values with the catalogue values
            if len(zeroOrderImageData) > 0 :
                majorAxis, minorAxis, positionAngle = zeroOrderImageData.iloc[0]

            # Update the region definition from its original circular prescription to an ellipse
            region.name = 'ellipse'
            # Define the elliptical coordinates of the region - apply optional correction factors here
            region.coord_list = [region.coord_list[0],
                                 region.coord_list[1],
                                 self.regionMajorAxisPaddingFactor * majorAxis,
                                 self.regionMinorAxisPaddingFactor * minorAxis,
                                 positionAngle + self.regionPositionAngleCorrection]

        # Replace the originally parsed regions with the modified regions
        self.zerothOrderRegions = zerothOrderRegionsCopy

    def mapRegionsToStampCoordinates(self) :
        """
        Utility method that maps coordinates of a region from the full drizzled grism image into the
        stamp coordinate system
        """
        if self.drizzledStampBBoxCoordinates is None :
            self.loadDrizzledStampBBoxCoordinates()

        # operate on a copy of the parsed region data
        zerothOrderRegionsCopy = copy.deepcopy(self.rawZerothOrderRegions)

        for region in zerothOrderRegionsCopy :
            # map the region coordinates from the full dispersed image into the stamp bounding box
            stampPixelX = region.coord_list[0] - self.drizzledStampBBoxCoordinates[0][0]
            stampPixelY = region.coord_list[1] - self.drizzledStampBBoxCoordinates[0][1]
            # update the region coordinates with the modified values
            region.coord_list[0] = stampPixelX
            region.coord_list[1] = stampPixelY

        # Replace the originally parsed regions with the modified regions
        self.zerothOrderRegions = zerothOrderRegionsCopy

    def mapStampXPixelToWavelength(self, xPixel):
        """
        Utility method that computes the wavelength corresponding to a specified x-pixel coordinate in the
        drizzled stamp coordinate system

        Positional arguments:

        xPixel -- the index of a pixel in the x direction in the drizzled stamp coordinate system
        """
        if self.drizzledStampWavelengthParameters is None :
            self.loadWavelengthParameters()
        refPixel = self.drizzledStampWavelengthParameters['CRPIX1']
        refWavelength = self.drizzledStampWavelengthParameters['CRVAL1']
        deltaWavelengthPerPixel = self.drizzledStampWavelengthParameters['CDELT1']
        return (xPixel - refPixel)*deltaWavelengthPerPixel + refWavelength

    def getBrightZerothOrderRegions(self, regions) :
        """
        Method that filters out faint zeroth order regions according to the magnitude of the direct
        target image that is specified in the catalogue file that is produced by the sextractor utility
        """
        if self.sextractorCatalogue is None :
            self.parseSextractorCatalogue()

        # operate on a copy of the passed-in region data, do not copy the instance
        # variable since some manipulation of the region shapes and coordinates may
        # have taken place
        zerothOrderRegionsCopy = copy.deepcopy(regions)

        for regionIndex, region in enumerate(zerothOrderRegionsCopy) :
            # Extract the object ID for the zeroth order being processed from the region file annotation
            if 'circle' not in region.name and 'ellipse' not in region.name :
                continue
            zeroOrderId = int(region.attr[1]['text'].split()[0])
            # Attempt to extract the magnitude for the object ID from the parsed sextractor catalogue
            zeroOrderMagnitudeData = self.sextractorCatalogue[self.sextractorCatalogue['NUMBER'] == zeroOrderId]['MAG']
            if len(zeroOrderMagnitudeData) > 0 :
                zeroOrderMagnitude = zeroOrderMagnitudeData.iloc[0]
                if zeroOrderMagnitude > self.brightSourceMagnitudeThreshold :
                    # the object is fainter than the threshold magnitude - discard it
                    del zerothOrderRegionsCopy[regionIndex]

        return zerothOrderRegionsCopy


    def computeRegionWavelengthRanges(self) :
        """
        Method which initiates computation of the ranges of wavelengths that intersect zeroth order image regions.
        """
        # Ensure that the drizzled stamp file path has been specified
        if self.drizzledStampPath is None :
            raise RuntimeError('No drizzled stamp path has been specified.')
        else :
            print('Using drizzled stamp:', self.drizzledStampPath)

        # perform required loading and mapping of region coordinates
        self.mapRegionsToStampCoordinates() # automatically loads BBox coordinates
        self.applyDrizzleCoefficients() # automatically loads drizzle coefficients
        self.applyRegionShapesFromCatalogue()

        # operate on a copy of the parsed region data
        zerothOrderRegionsCopy = copy.deepcopy(self.zerothOrderRegions)

        # ensure that the regions are mapped into the image coordinates of the drizzled stamp
        imageCoordRegionList = zerothOrderRegionsCopy.as_imagecoord(self.drizzledStampScienceHeader)

        # create a second copy containing only sources with magnitudes brighter than 22.5
        # TODO: make magnitude threshold a parameters
        brightImageCoordRegionList = self.getBrightZerothOrderRegions(imageCoordRegionList)

        #intentionally ignore model mask returned in first call, it is identical to that returned by the second call
        (brightRegionMask, _, self.brightRegionWavelengthRanges, self.brightRegionInModelWavelengthRanges) = self.doComputeRegionWavelengthRanges(brightImageCoordRegionList)
        (regionMask, modelMask, self.regionWavelengthRanges, self.regionInModelWavelengthRanges) = self.doComputeRegionWavelengthRanges(imageCoordRegionList)

        return (regionMask, brightRegionMask, modelMask)

    def doComputeRegionWavelengthRanges(self, imageCoordRegionList) :
        """
        Method which actually computes the ranges of wavelengths that intersect zeroth order image regions.
        """

        # create a 2d pixel mask for the zeroth order regions that intersect the drizzled stamp boundaries
        stampFitsFile = astrofits.open(self.drizzledStampPath)
        regionMask = imageCoordRegionList.get_mask(hdu=stampFitsFile['SCI'])
        stampFitsFile.close()

        # Load the model extension from the drizzled stamp file
        self.loadDrizzledStampModelExtension()

        # find pixels of model containing non-zero pixels
        modelMask = self.drizzledStampModelExtension > 0
        print('regionMask.shape', regionMask.shape)
        print('modelMask.shape', modelMask.shape)

        # find the x-pixel ranges where the region mask is true (irrespective of the model value)
        flatRegionMask = np.any(regionMask, axis=0)

        # find x-pixel ranges where the model is non-zero and the region mask is true
        regionInModelMask = copy.deepcopy(regionMask)
        regionInModelMask[np.logical_not(modelMask)] = False
        flatRegionInModelMask = np.any(regionInModelMask, axis=0)

        # list the indices of x-pixels that have some contamination from zeroth-orders with and without considering
        # the extraction model
        regionInModelWavelengthIndices = [idx for idx,value in enumerate(flatRegionInModelMask) if value == True]
        regionWavelengthIndices = [idx for idx,value in enumerate(flatRegionMask) if value == True]

        # gather groups of contiguous indices
        groupedRegionWavelengthIndices = [list(group) for _,group in itertools.groupby(regionWavelengthIndices,key=lambda n,c=itertools.count():n-next(c))]
        groupedRegionInModelWavelengthIndices = [list(group) for _,group in itertools.groupby(regionInModelWavelengthIndices,key=lambda n,c=itertools.count():n-next(c))]

        # isolate the first and last pixels from each range and convert to wavelengths
        regionWavelengthRanges = [[self.mapStampXPixelToWavelength(indexRange[0]),
                                   self.mapStampXPixelToWavelength(indexRange[-1])]
                                  for indexRange in groupedRegionWavelengthIndices]

        regionInModelWavelengthRanges = [[self.mapStampXPixelToWavelength(indexRange[0]),
                                          self.mapStampXPixelToWavelength(indexRange[-1])]
                                         for indexRange in groupedRegionInModelWavelengthIndices]

        return (regionMask, modelMask, regionWavelengthRanges, regionInModelWavelengthRanges)

    def getRegionWavelengthRanges(self) :
        """
        Returns a tuple containing two lists of lists specifying the ranges of wavelengths for the drizzled
        stamp that are intersect a zeroth order image. The first element of the tuple lists the wavelength
        ranges for zeroth orders that fall anywhere within the drizzled stamp boundaries. The second element
        lists the wavelength ranges for zeroth orders that intersect the non-zero pixels in the extraction
        model for the target object.
        """
        if self.regionWavelengthRanges is None or self.brightRegionWavelengthRanges is None or self.regionInModelWavelengthRanges is None :
            self.zerothOrderRegionMask, self.brightZerothOrderRegionMask, self.extractionModelMask = self.computeRegionWavelengthRanges()
        return (self.regionWavelengthRanges, self.brightRegionWavelengthRanges, self.regionInModelWavelengthRanges)

    def getWavelengthZeroOrderFlag(self, wavelength) :
        """
        Compute and return the zeroth order status flag for wavelength value specified in Anstroms.

        The zeroth order status flag can assume one of the following values:
        0 -- If no zeroth order images fall within the stamp bounds at the specified wavelength.
        1 -- If at least one zeroth order image falls within the stamp bounds but outside the non-zero region
        of the spectrum extraction model extension at the specified wavelength.
        2 -- If at least one zeroth order image falls within the non-zero region of the spectrum extraction
        model extension at the specified wavelength.
        """
        flag = 0
        regionWavelengthRanges, brightRegionWavelengthRanges, regionInModelWavelengthRanges = self.getRegionWavelengthRanges()
        # test whether wavelength corresponds to any zeroth order in the stamp bounds
        for wavelengthRange in regionWavelengthRanges :
            if wavelength >= wavelengthRange[0] and wavelength <= wavelengthRange[1] :
                flag += 1
                break
        # test whether wavelength corresponds to any zeroth order within the non-zero range of the
        # extraction model
        for wavelengthRange in regionInModelWavelengthRanges :
            if wavelength >= wavelengthRange[0] and wavelength <= wavelengthRange[1] :
                flag += 1
                break
        # test whether the direct image magnitude of the source is brighter than a threshold magnitude
        for wavelengthRange in brightRegionWavelengthRanges :
            if wavelength >= wavelengthRange[0] and wavelength <= wavelengthRange[1] :
                flag += 1
                break
        return flag

    def getWavelengthZerothOrderFlags(self, wavelengths) :
        """
        Compute and return the zeroth order status flags for the elements of an array-like structure
        of wavelength values specified in Anstroms in the context of the passed grism stamp file.

        The zeroth order status flag can assume one of the following values:
        0 -- If no zeroth order images fall within the stamp bounds at the specified wavelength.
        1 -- If at least one zeroth order image falls within the stamp bounds but outside the non-zero region
        of the spectrum extraction model extension at the specified wavelength.
        2 -- If at least one zeroth order image falls within the non-zero region of the spectrum extraction
        model extension at the specified wavelength.
        3 -- If at least one zeroth order image for an object with direct image magnitude brighter than a settable
        threshold (default is 22.5) falls within the non-zero region of the spectrum extraction model extension
        at the specified wavelength.
        """
        return np.array([ self.getWavelengthZeroOrderFlag(wavelength) for wavelength in wavelengths ])

    def setDrizzledStampFilePath(self, drizzledStampPath) :
        """
        Set the path for the drizzled, wavelength-calibrated grism stamp file
        """
        self.drizzledStampPath = drizzledStampPath
        self.resetDrizzledStampParameters()

    def resetDrizzledStampParameters(self) :
        self.drizzledStampScienceHeader = None
        self.drizzledStampModelExtension = None
        self.drizzleCoefficients = None
        self.drizzledStampBBoxCoordinates = None
        self.drizzledStampWavelengthParameters = None
        self.zerothOrderRegions = None
        self.zerothOrderRegionMask = None
        self.brightZerothOrderRegionMask = None
        self.extractionModelMask = None
        self.regionWavelengthRanges = None
        self.regionInModelWavelengthRanges = None

    def plot(self) :
        """
        Utility method to plot the region and model masks as a useful sanity check.
        """
        if self.zerothOrderRegionMask is None or self.brightZerothOrderRegionMask is None or self.extractionModelMask is None :
            self.zerothOrderRegionMask, self.brightZerothOrderRegionMask, self.extractionModelMask = self.computeRegionWavelengthRanges()

        figure = pyplot.figure(figsize=(10, 12))
        pyplot.ylabel('Pixels')
        pyplot.xlabel('Pixels')
        axes = pyplot.subplot(3,1,1)
        pyplot.ylim([0, self.zerothOrderRegionMask.shape[0]])
        pyplot.xlim([0, self.zerothOrderRegionMask.shape[1]])
        pyplot.title('Zeroth Order Region Map', y=1.4)
        pyplot.imshow(self.zerothOrderRegionMask, cmap='hot')
        axes.set_aspect('auto')
        wavelengthAxes = axes.twiny()
        pyplot.xlim(self.mapStampXPixelToWavelength(0), self.mapStampXPixelToWavelength(self.zerothOrderRegionMask.shape[1]))
        pyplot.xlabel(r'Wavelength $\AA$')

        figure = pyplot.figure(figsize=(10, 12))
        pyplot.ylabel('Pixels')
        pyplot.xlabel('Pixels')
        axes = pyplot.subplot(3,1,1)
        pyplot.ylim([0, self.brightZerothOrderRegionMask.shape[0]])
        pyplot.xlim([0, self.brightZerothOrderRegionMask.shape[1]])
        pyplot.title('Bright (m < {}) Zeroth Order Region Map'.format(self.brightSourceMagnitudeThreshold), y=1.4)
        pyplot.imshow(self.brightZerothOrderRegionMask, cmap='hot')
        axes.set_aspect('auto')
        wavelengthAxes = axes.twiny()
        pyplot.xlim(self.mapStampXPixelToWavelength(0), self.mapStampXPixelToWavelength(self.brightZerothOrderRegionMask.shape[1]))
        pyplot.xlabel(r'Wavelength $\AA$')

        axes = pyplot.subplot(3,1,3)
        pyplot.ylabel('Pixels')
        pyplot.xlabel('Pixels')
        pyplot.ylim([0, self.extractionModelMask.shape[0]])
        pyplot.xlim([0, self.extractionModelMask.shape[1]])
        pyplot.title('Non-Zero Model Map', y=1.4)
        pyplot.imshow(self.extractionModelMask, cmap='hot')
        axes.set_aspect('auto')
        wavelengthAxes = axes.twiny()
        pyplot.xlim(self.mapStampXPixelToWavelength(0), self.mapStampXPixelToWavelength(self.extractionModelMask.shape[1]))
        pyplot.xlabel(r'Wavelength $\AA$')

        pyplot.tight_layout(pad=2, h_pad=1)

        return figure
