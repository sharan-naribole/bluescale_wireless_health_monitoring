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

def gettext(ftp, filename):
    outfile = open(filename,'w')
    #fetch a text file
    #if outfile is None:
    #    outfile = sys.stdout
    # use a lambda to add newlines to the lines read from the server
    ftp.retrlines("RETR " + filename, lambda s, w=outfile.write: w(s+"\n"))

def getbinary(ftp, filename):
    outfile = open(filename,'wb')    
    # fetch a binary file
    #if outfile is None:
    #    outfile = sys.stdout
    ftp.retrbinary("RETR " + filename, outfile.write)

#ALTERNATIVE ONE-LINE VERSION: urllib.urlretrieve('ftp://username:password@server/path/to/file', 'file')

def upload(ftp, file):
    ext = os.path.splitext(file)[1]
    if ext in (".txt", ".htm", ".html",".php"):
        ftp.storlines("STOR " + file, open(file))
    else:
        ftp.storbinary("STOR " + file, open(file, "rb"), 1024)


def main():
    args = sys.argv[1:]
    if not args: 
        print ("Please enter the Patient ID and the Timestamp ID")
        #Timestamp ID = n corresponds to the nth most recent measurement
        sys.exit(1)

    #print args
    patient_id = args[0]
    timestamp_id = args[1]
    
    #CODE FOR URL RETRIEVAL
    req = requests.get("http://129.7.44.143/bluescale/pleth_waveform.php?id=%s&ts=%s"% (str(patient_id),str(timestamp_id)),auth=('sharan','bluescale'))
    print (req.text)

    #THE WAVEFORM VECTOR
    waveform = numpy.genfromtxt(StringIO(req.text),delimiter="\n", dtype = float)
    #print waveform

    #WAVEFORM PLOT
    #pl.plot(range(1,waveform.size+1),waveform)
    #pl.show()

if __name__ == "__main__":
    main() 
