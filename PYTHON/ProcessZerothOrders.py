if __name__ == "__main__" :
    from ZerothOrderWavelengthRanges import ZerothOrderWavelengthRanges
    import pandas as pd
    import sys
    import os
    import glob
    import re
    import argparse

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

    for grismDirectory in grismDirectories :
        # extract grism number
        currentGrism = None
        try :
            currentGrism = int(re.search(r'.*G([0-9]+)_DRIZZLE', grismDirectory).group(1))
        except Exception as error :
            print ('Could not determine grism ID.')
            raise SystemExit

        if verbose :
            print ('{0}: Working on Grism {1}...'.format(sys.argv[0], currentGrism))

        # Check whether an appropriate region file is present in "DATA/DIRECT_GRISM"
        regionFilePath = '{0}/DATA/DIRECT_GRISM/G{1}_0th.reg'.format(workingDirectory, currentGrism)
        if not os.path.exists(regionFilePath) :
            print ('Zeroth order grism file for G{0} in Par{1} not found at expected location ({2})'.format(currentGrism, currentPar, regionFilePath))
            raise SystemExit

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
            print ('Sextractor catalogue file for G{0} in Par{1} not found at any trial locations.'.format(currentGrism, currentPar))
            raise SystemExit

        if verbose :
            print ('{0}: Located sectractor catalogue file at {1}...'.format(sys.argv[0], catalogueFilePath))

        # Loop over stamp FITS files in "G***_DRIZZLE" if the stamp is not present then
        # the presence of a .dat is irrelevant because computation of zeroth order
        # positions will not be possible
        grismStampFitsFiles = glob.glob('{0}/G{1}_DRIZZLE/aXeWFC3_G{2}_mef_ID*.fits'.format(workingDirectory, currentGrism, currentGrism))
        if not grismStampFitsFiles :
            print ('Could not locate any stamp files for G{0} in Par{1} at expected location ({2})'.format(
            currentGrism, currentPar, '{0}/G{1}_DRIZZLE'.format(workingDirectory, currentGrism))
            )
            raise SystemExit

        for stampFilePath in grismStampFitsFiles :
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
                continue

            if verbose :
                print ('{0}: Working on .dat file "{1}"...'.format(sys.argv[0], datFilePath))

            # Finally, the data to process the .dat file are assembled

            # Parse the .dat file into a pandas dataframe
            datFile = open(datFilePath)
            columnNames = datFile.readline().split()[1:]
            datFile.close()
            datFileFrame = pd.read_csv(datFilePath, delim_whitespace=True, header=0, engine='c', names=columnNames, comment='#')

            # instantiate the class to compute the wavelength ranges affected by zeroth order images
            zeroOrderRanges = ZerothOrderWavelengthRanges(stampFilePath, regionFilePath, catalogueFilePath)
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
            else :
                print('Running in dryrun mode. No files were modified.')
                if verbose :
                    print('Generated ouput:\n{0}'.format(datFileOutput))
