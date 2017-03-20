import sys
import re
import os
import requests
import numpy
import subprocess


def delete_first_line(filename):
    
    f = open(filename,"r")
    lines = f.readlines()
    f.close()
    
    f = open(filename,"w")
    for line in lines:
        if line!="w"+"\n":
            f.write(line)
    f.close()

def main():
    args = sys.argv[1:]
    if not args:
        print "INPUT: Main Folder name | Lower bound of Timestamp | Upper Bound of Timestamp"
        sys.exit(1)

    #patient_id = args[0]
    #timestamp = args[1]

    main_dir = args[0]

    os.system("mkdir ../../" + main_dir)

    patient_ids = (3126,6666,7777,8888)
    lower_range = int(args[1])
    upper_range = int(args[2])
    
    for patient_id in patient_ids:
        os.system("mkdir ../../" + main_dir + "/" + str(patient_id))
        os.system("mkdir ../../" + main_dir + "/" + str(patient_id) + "/ECG")
        os.system("mkdir ../../" + main_dir + "/" + str(patient_id) + "/PPG")

        for timestamp in range(lower_range,upper_range+1):

            ecg_file = "../../" + main_dir + "/" + str(patient_id) + "/" + "ECG/" + "ECG_" + str(patient_id) + "_" + str(timestamp) + ".txt"
            subprocess.Popen("python ecg_waveform.py " + str(patient_id) + " " + str(timestamp) + " > " + ecg_file,shell=True)
            ppg_file = "../../" + main_dir + "/" + str(patient_id) + "/" + "PPG/" + "PPG_" + str(patient_id) + "_" + str(timestamp) + ".txt"
            subprocess.Popen("python pleth_waveform.py " + str(patient_id) + " " + str(timestamp) + " > " + ppg_file,shell=True)

#f = open(filename, 'w')
#   print >> f, 'Filename:', filename  # or f.write('...\n')
#print >> f, tmp
#   f.close()


if __name__ == "__main__":
    main() 
