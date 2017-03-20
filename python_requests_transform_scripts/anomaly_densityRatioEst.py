import sys
import os
import commands
import numpy
import math
import random
import requests
from StringIO import StringIO

def GaussianKernel(sub_input,sub_mean,kernel_width):
    kk = -1*numpy.sum((sub_input-sub_mean)**2)/(2*(kernel_width**2))
    return math.exp(kk)

def KLIEP(series_ref,series_test,len_sub):
    n_ref = series_ref.size
    n_test = series_test.size - len_sub + 1
    ker = numpy.zeros((n_ref,n_ref))
    
    for i in range(0,n_ref):
        sub_input = series_test[i:i+len_sub]
        for l in range(0,n_ref):
            sub_mean = series_test[l:l+len_sub]
            ker[i][l] = GaussianKernel(sub_input,sub_mean,kernel_width)

    b = numpy.zeros(n_ref)
    for l in range(0,n_ref):
        sub_mean = series_test[l:l+len_sub]
        for i in range(0,n_ref):
            sub_input = series_ref[i:i+len_sub]
            b[l] += GaussianKernel(sub_input,sub_mean,kernel_width)

alpha = 0.01*numpy.ones(n_test)


def densityRatioEst(series_ref,series_test,len_sub):
#Computes the Density Ratio Vector
    n_ref = series_ref.size
    n_test = series_test.size - len_sub + 1

    kernel_width = numpy.std(series_ref)
    #Paper provides a more accurate Kernel Width estimation technique
    #To be implemented soon
    
    alpha = numpy.ones(n_test)
    #KLIEP algorithm to determine alphas so that the divergence of estimate from actual is minimized
    #To be implemented soon

    w = numpy.zeros(n_test)
    for i in range(0,n_test):
        sub_input = series_test[i:i+len_sub]
        for j in range(0,n_test):
            sub_mean = series_test[j:j+len_sub]
            w[i] += alpha[j]*GaussianKernel(sub_input,sub_mean,kernel_width)

    return w

def anomalyDetect(series_ref,series_test,thresh,len_sub):
#series_ref represents the reference time interval
#series_test represents the test time interval - most recent measurement
#len_sub = subsequence length
    n_ref = series_ref.size
    n_test = series_test.size - len_sub + 1

    #Let p_ref and p_te represent the probability density functions of the
    #reference and test sequence samples respectively
    #Let w(Y) = p_te(Y)/p_ref(Y) where Y is subsequence of length len_sub
    #w(Y) estimation goes here
    w = densityRatioEst(series_ref,series_test,len_sub)
    print (w)

    S = 0
    for i in range(0,n_test):
        S += numpy.log(w[i])


    if S <= thresh:
        return (0,S)
    else:
        return (1,S)

def main():
    #timeSeries = numpy.array([5,5,5,30,99,52,48,33,22,84,100])
    len_sub = 1 #forward subsequence length
    Npts = 100 #total number of points in the time series
    Ntest = 3  #number of points in the test sequence
    thresh = 2 #anomaly threshold
    patient_id = 7777
    timeSeries=[]
      
    #for i in range (Npts):
    #    timeSeries.append(random.uniform(0,100))
    #timeSeries = numpy.array(timeSeries)
    
    req = requests.get("http://polloninilab.com/ricegroup/weight_basic_measurement.php?id=%s"% str(patient_id),auth=('sharan','bluescale'))
    
    timeSeries = numpy.genfromtxt(StringIO(req.text),delimiter="|", usecols = 1,dtype = float)
    timeSeries = numpy.append(timeSeries,400)

    series_ref = timeSeries[:-Ntest]
    series_test = timeSeries[-Ntest:]

    print (anomalyDetect(series_ref,series_test,thresh,len_sub))
    #1 indicates anomaly, 0 otherwise
    #Vector of (anomaly result,density ratio estimate)


if __name__ == "__main__":
    main() 
