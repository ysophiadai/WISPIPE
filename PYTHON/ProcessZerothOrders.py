def generateValidGrismsForObjectsDict(workingDirectory, validGrisms) :
    # declare structure to register grisms for which each object has a valid stamp FITS file
    validGrismStampForObjectDict = {}
    # loop over grisms
    for currentGrism in validGrisms :
        # locate all stamp FITS files for the current pointing that pertain to the current grism
        grismStampFitsFiles = glob.glob('{0}/G{1}_DRIZZLE/aXeWFC3_G{2}_mef_ID*.fits'.format(workingDirectory, currentGrism, currentGrism))
        for grismStampFitsFile in grismStampFitsFiles :
            # extract the object ID from the stamp FITS file name
            objectID = int(grismStampFitsFile.split('/')[-1].split('_')[-1][2:-5])
            # update the register structure appropriately depending upon whether a previous grism also has a stamp for this object
            if objectID in validGrismStampForObjectDict :
                validGrismStampForObjectDict[objectID].append(currentGrism)
            else :
                validGrismStampForObjectDict.update({objectID : [currentGrism]})
    # return the register structure
    return validGrismStampForObjectDict

def processUnifiedSpectrumDat(dataTuple) :
    workingDirectory, currentPar, validGrisms, currentObject, dryrun, verbose = dataTuple
    if len(validGrisms) > 0 :
        grismDatFilePaths = {currentGrism : '{0}/Spectra/Par{1}_G{2}_BEAM_{3}A.dat'.format(workingDirectory, currentPar, currentGrism, currentObject) for currentGrism in validGrisms }

    unifiedDatFilePath = '{0}/Spectra/Par{1}_BEAM_{2}A.dat'.format(workingDirectory, currentPar, currentObject)

    unifiedDatFile = open(unifiedDatFilePath)
    columnNames = unifiedDatFile.readline().split()[1:]
    unifiedDatFile.close()
    unifiedDatFrame = pd.read_csv(unifiedDatFilePath, delim_whitespace=True, header=0, engine='c', names=columnNames, comment='#')

    for grism, grismDatFilePath in grismDatFilePaths.items() :
        grismDatFile = open(grismDatFilePath)
        columnNames = grismDatFile.readline().split()[1:]
        grismDatFile.close()
        grismDatFrame = pd.read_csv(grismDatFilePath, delim_whitespace=True, header=0, engine='c', names=columnNames, comment='#')
        unifiedDatFrame = unifiedDatFrame.merge(grismDatFrame[['wave', 'zeroth']].dropna(), how='left', left_on='wave', right_on='wave', suffixes=['',str(grism)])

    for grism in grismDatFilePaths.keys() :
        grismColName = 'zeroth' + str(grism)
        unifiedDatFrame['zeroth'] = np.where(np.isnan(unifiedDatFrame[grismColName]),
                                                               unifiedDatFrame['zeroth'],
                                                               unifiedDatFrame[grismColName])

    unifiedDatFrame.drop(['zeroth' + str(grism) for grism in grismDatFilePaths.keys()], axis=1, inplace=True)

    # generate some appropriately formatted output
    datFileOutput = '{0}{1}\n'.format('#'.ljust((outputColumnWidth - 1) - len(columnNames[0])), unifiedDatFrame.to_string(col_space=outputColumnWidth, index=False, header=True, justify='right', float_format=lambda x : "{:.6e}".format(x)))

    # overwrite the input .dat file using the generated data
    if not dryrun :
        outFile = open(unifiedDatFilePath, 'w')
        outFile.write(datFileOutput)
        outFile.close()
        if verbose :
            print('Updated unified .dat file written to {0}'.format(unifiedDatFilePath))
        return 0
    else :
        print('Running in dryrun mode. No files were modified.')
        if verbose :
            print('Generated unified ouput:\n{0}'.format(datFileOutput))
        return 1
    return 3

def processSingleStamp(dataTuple) :
    workingDirectory, currentPar, currentGrism, stampFilePath, zeroOrderRanges, dryrun, verbose = dataTuple
    # Now attempt to locate the corresponding .dat file in the "Spectra"
    # directory
    currentObject = None
    try :
        currentObject = int(re.search(r'.*aXeWFC3_G{0}_mef_ID([0-9]+).fits'.format(currentGrism), stampFilePath).group(1))
    except Exception as error :
        print ('Could not determine object/beam ID.')
        raise SystemExit

    if verbose :
        print ('{0}: Working on Beam {1}...'.format(sys.argv[0], currentObject))

    datFilePath = '{0}/Spectra/Par{1}_G{2}_BEAM_{3}A.dat'.format(workingDirectory, currentPar, currentGrism, currentObject)
    if not os.path.exists(datFilePath) :
        print ('Could not locate .dat file for G{0} in Par{1} at expected location ({2})'.format(
        currentGrism, currentPar, datFilePath)
        )
        # No need to crash here, just skip to the next stampPath
        return 2

    if verbose :
        print ('{0}: Working on .dat file "{1}"...'.format(sys.argv[0], datFilePath))

    # Finally, the data to process the .dat file are assembled

    # Parse the .dat file into a pandas dataframe
    datFile = open(datFilePath)
    columnNames = datFile.readline().split()[1:]
    datFile.close()
    datFileFrame = pd.read_csv(datFilePath, delim_whitespace=True, header=0, engine='c', names=columnNames, comment='#')

    # set the stamp file to provide the context in which the presence of zeroth order images should be computed
    zeroOrderRanges.setDrizzledStampFilePath(stampFilePath)
    # update the dataframe column for the zeroth orders to reflect the computation
    datFileFrame['zeroth'] = zeroOrderRanges.getWavelengthZerothOrderFlags(datFileFrame['wave'].values)

    # generate some appropriately formatted output
    datFileOutput = '{0}{1}\n'.format('#'.ljust((outputColumnWidth - 1) - len(columnNames[0])), datFileFrame.to_string(col_space=outputColumnWidth, index=False, header=True, justify='right', float_format=lambda x : "{:.6e}".format(x)))

    # overwrite the input .dat file using the generated data
    if not dryrun :
        outFile = open(datFilePath, 'w')
        outFile.write(datFileOutput)
        outFile.close()
        if verbose :
            print('Updated .dat file written to {0}'.format(datFilePath))
        return 0
    else :
        print('Running in dryrun mode. No files were modified.')
        if verbose :
            print('Generated ouput:\n{0}'.format(datFileOutput))
        return 1
    return 3


if __name__ == "__main__" :
    from ZerothOrderWavelengthRanges import ZerothOrderWavelengthRanges
    import pandas as pd
    import numpy as np
    import sys
    import os
    import glob
    import re
    import argparse
    import multiprocessing

    parser = argparse.ArgumentParser(description='Add information about zeroth order contamination to .dat files.')
    parser.add_argument('--dryrun', action='store_const', const=True, dest='dryrun')
    parser.add_argument('--verbose', action='store_const', const=True, dest='verbose')
    parser.add_argument('--outputColumnWidth', action='store', dest='outputColumnWidth', nargs=1)
    parsedArgs = parser.parse_args()

    dryrun = True if parsedArgs.dryrun is not None else False
    verbose = True if parsedArgs.verbose is not None else False
    outputColumnWidth = parsedArgs.outputColumnWidth if parsedArgs.outputColumnWidth is not None else 15

    workingDirectory = os.getcwd()

    if verbose :
        print ('{0}: Working in {1}...'.format(sys.argv[0], workingDirectory))


    grismToDirectFilterMap = {102 : [110, 140, 160], 141 : [160, 140, 110]}

    # Determine the field ID of the current directory
    currentPar = None
    try :
        currentPar = int(re.search(r'.*Par([0-9]+)', workingDirectory).group(1))
    except Exception as error :
        print ('Could not determine field ID. {0}'.format(error))
        raise SystemExit

    if verbose :
        print ('{0}: Working on Field {1}...'.format(sys.argv[0], currentPar))

    # Check for grism directories
    grismDirectories = glob.glob(workingDirectory + '/G*_DRIZZLE')
    if not grismDirectories :
        print ('Could not locate directories containing grism data.')
        raise SystemExit

    # Register of grisms for which stamps exist for any object in the pointing
    grismsWithStamps = { grism : False for grism in grismToDirectFilterMap.keys() }

    for grismDirectory in grismDirectories :
        # extract grism number
        currentGrism = None
        try :
            currentGrism = int(re.search(r'.*G([0-9]+)_DRIZZLE', grismDirectory).group(1))
        except Exception as error :
            print ('*** WARNING: Could not determine grism ID for directory {}. Directory name does not conform with expected format.')
            # Do not exit in case other directories yield valid grism IDs
            continue

        if verbose :
            print ('{0}: Working on Grism {1}...'.format(sys.argv[0], currentGrism))

        # Check whether an appropriate region file is present in "DATA/DIRECT_GRISM"
        regionFilePath = '{0}/DATA/DIRECT_GRISM/G{1}_0th.reg'.format(workingDirectory, currentGrism)
        if not os.path.exists(regionFilePath) :
            print ('*** WARNING: Zeroth order grism file for G{0} in Par{1} not found at expected location ({2})'.format(currentGrism, currentPar, regionFilePath))
            # Do not exit in case other grisms have valid region files
            continue

        if verbose :
            print ('{0}: Located region file at {1}...'.format(sys.argv[0], regionFilePath))

        # Check whether an appropriate sextractor catalogue is present in "DATA/DIRECT_GRISM"
        foundCatalogueFile = False
        catalogueFilePath = None
        for trialFilter in grismToDirectFilterMap[currentGrism] :
            catalogueFilePath = '{0}/DATA/DIRECT_GRISM/fin_F{1}.cat'.format(workingDirectory, trialFilter)
            if not os.path.exists(catalogueFilePath) :
                print ('Sextractor catalogue file for G{0} in Par{1} not found at trial location ({2})'.format(currentGrism, currentPar, catalogueFilePath))
            else :
                foundCatalogueFile = True
                break
        if not foundCatalogueFile :
            print ('*** WARNING: Sextractor catalogue file for G{0} in Par{1} not found at any trial locations.'.format(currentGrism, currentPar))
            # Do not exit in case other grisms have valid sextractor catalogues
            continue

        if verbose :
            print ('{0}: Located sextractor catalogue file at {1}...'.format(sys.argv[0], catalogueFilePath))

        # Loop over stamp FITS files in "G***_DRIZZLE" if the stamp is not present then
        # the presence of a .dat is irrelevant because computation of zeroth order
        # positions will not be possible
        grismStampFitsFiles = glob.glob('{0}/G{1}_DRIZZLE/aXeWFC3_G{2}_mef_ID*.fits'.format(workingDirectory, currentGrism, currentGrism))
        if not grismStampFitsFiles :
            print ('Could not locate any stamp files for G{0} in Par{1} at expected location ({2})'.format(
            currentGrism, currentPar, '{0}/G{1}_DRIZZLE'.format(workingDirectory, currentGrism))
            )
            # Do not exit in case other grisms have valid stamps
            continue

        # Update the register of grisms for which stamps exist for any object in the pointing
        grismsWithStamps[currentGrism] = True

        # instantiate the class to compute the wavelength ranges affected by zeroth order images
        zeroOrderRanges = ZerothOrderWavelengthRanges(regionFilePath, catalogueFilePath)

        # for stampFilePath in grismStampFitsFiles :
        # Parallelized processing of individual stamps

        # Acquire almost all available processors, leaving two for desktop interaction or default to 1
        # processor if fewer than 3 are available
        numcpu = multiprocessing.cpu_count() - 2 if multiprocessing.cpu_count() > 2 else 1
        print('Using {0} processors'.format(numcpu))

        # instantiate a pool of processors to perform the required parallel tasks
        processorPool = multiprocessing.Pool(numcpu)

        # assemble data to pass to parallel instances
        dataTuples = [(workingDirectory, currentPar, currentGrism, stampFilePath, zeroOrderRanges, dryrun, verbose) for stampFilePath in grismStampFitsFiles ]
        results = processorPool.map(processSingleStamp, dataTuples)

    # Construct a dictionary to register the grisms for which each object in the pointing has a stamp
    validGrismsForObjectsDict = generateValidGrismsForObjectsDict(workingDirectory, [ key for key, value in grismsWithStamps.items() if value ])

    # now combine zeroth order columns from grism-specific files into a unified file
    dataTuples = [ (workingDirectory, currentPar, validGrismsForObjectsDict[currentObject], currentObject, dryrun, verbose) for currentObject in validGrismsForObjectsDict.keys() ]
    #print ('dataTuples => {}'.format(dataTuples))
    results = processorPool.map(processUnifiedSpectrumDat, dataTuples)
