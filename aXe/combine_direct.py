import sys
import os,string,time
from pyraf import iraf
from iraf import proto, imred, ccdred
from pyraf.irafpar import IrafParS

#####
# This program has been implemented in the GRISM_axe.py programs, but for backwards capabilities you can run this in the par directory
#####

def combine_f160():
    # Clean GRISM Images:
    # ============================   
    owd = os.getcwd()
    os.chdir('./DATA/DIRECT_GRISM/') 
    iraf.fixpix(images="@F160_clean.list//[1]%'",masks="/Users/ydai/WISPIPE/aXe/CONFIG/bp_mask_v5.pl",linterp=1000,cinterp="INDEF")
    iraf.combine(input="@F160_clean.list//[1]%'",output="F160.fits",combine="median",reject="crrej")
    os.chdir(owd)

def combine_f140():
    # Clean GRISM Images:
    # ============================   
    owd = os.getcwd()
    os.chdir('./DATA/DIRECT_GRISM/') 
    iraf.fixpix(images="@F140_clean.list//[1]%'",masks="/Users/ydai/WISPIPE/aXe/CONFIG/bp_mask_v5.pl",linterp=1000,cinterp="INDEF")
    iraf.combine(input="@F140_clean.list//[1]%'",output="F140.fits",combine="median",reject="crrej")
    os.chdir(owd)

def combine_f110():
    # Clean GRISM Images:
    # ============================   
    owd = os.getcwd()
    os.chdir('./DATA/DIRECT_GRISM/') 
    iraf.fixpix(images="@F110_clean.list//[1]%'",masks="/Users/ydai/WISPIPE/aXe/CONFIG/bp_mask_v5.pl",linterp=1000,cinterp="INDEF")
    iraf.combine(input="@F110_clean.list//[1]%'",output="F110.fits",combine="median",reject="crrej")
    os.chdir(owd)


  #***************************************************************************************** 
    #            aXe -- MAIN PROGRAMME
    #*****************************************************************************************
def main():

    # Running iolprep:
    owd = os.getcwd()
    #change dir to data path
    os.chdir('./DATA/DIRECT_GRISM/')

    f = open('F160.list', "r")
    text = f.read()
    print text[0:4]

    if text[0:4] == 'none': 
        print 'combining with F140W filter ............................' 
        #change dir back to original working directory (owd)
        os.chdir(owd) 
        combine_f140()
    else:
        print 'combining with F160W filter ............................'
        #change dir back to original working directory (owd)
        os.chdir(owd) 
        combine_f160()

    os.chdir('./DATA/DIRECT_GRISM/')
    f = open('F110.list', "r")
    text2 = f.read()
    print text2[0:4]
    
    if text2[0:4] == 'none': 
        print 'No F110W filter - not combining F110W ............................' 
        #change dir back to original working directory (owd)
    else:
        print 'combining with F110W filter ............................'
        #change dir back to original working directory (owd)
        os.chdir(owd) 
        combine_f110()

    

main()
