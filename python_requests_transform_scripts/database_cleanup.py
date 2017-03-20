import sys
import re
import os
import shutil
import commands
import requests
import urllib
import ftplib
import numpy
from StringIO import StringIO


def main():
    
    valid_ID = [222,234,245,242,387,1100,1231,2008,2011,2014,2016,2020,2524,2525,2863,3000,3001,3002,3126,3141,6666,6969,7777,8170,8888];

    #COLLECTING PATIENT ID LIST FROM DATABASE
    req = requests.get("http://129.7.44.143/bluescale/patient_id_collection.php",auth=('sharan','bluescale'))
    full_ID = numpy.genfromtxt(StringIO(req.text),delimiter="\n", dtype = int)

    print "== BEGINNING DATABASE CLEANUP =="
    for id in full_ID:
        if id not in valid_ID:
            print id
            #DELETING THE PATIENT ID RECORD FOR THE ID NOT PRESENT IN THE VALID ID LIST
            req = requests.get("http://129.7.44.143/bluescale/database_cleanup.php?id=%s"% str(id),auth=('sharan','bluescale'))
            print req.text

    #OUTPUTTING THE PATIENT IDs left in the database after Cleanup
    req = requests.get("http://129.7.44.143/bluescale/patient_id_collection.php",auth=('sharan','bluescale'))
    remaining_ID = numpy.genfromtxt(StringIO(req.text),delimiter="\n", dtype = int)

    print " == REMAINING PATIENT IDs AFTER CLEANUP =="
    for id in remaining_ID:
        print id


if __name__ == "__main__":
    main() 
