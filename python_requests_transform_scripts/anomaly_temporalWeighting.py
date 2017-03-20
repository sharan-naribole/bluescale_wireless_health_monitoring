import sys
import numpy
import random
import pylab as pl
import requests
from StringIO import StringIO

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

def similarity(series1,series2):
  #Placeholder function for similarity tests
  #Returns Euclidean Distance Similarity for now
  return 1/numpy.sqrt(numpy.sum((series1-series2)**2))
  #return 1

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

def temporalWeights(timeSeries,N,maxLag,maxGrps):
  #This function takes a timeSeries and finds the temporal weights to be used in calculating median and MAD
  #N is the subsequence length
  #maxGrps caps the number of historical subsequences to use
  #maxLag denotes the number of lags to consider for temporal weighting
  #Returns the temporal weights up to lagged by lastLag
  
  Npts = timeSeries.size
  
  #Initialize similarity matrix
  lastLag = min(maxLag,Npts-N)
  avgSim = numpy.zeros(lastLag)

  #Looping through temporal lag up to last lag
  for lag in range(1,lastLag+1):
      simSum = 0

      #Get similarity for valid subsequence in historical data
      index_1 = 0
      while index_1 + lag + N <= Npts and index_1<=maxGrps:
          index_2 = index_1 + lag
          series_1 = timeSeries[index_1:index_1+N]
          series_2 = timeSeries[index_2:index_2+N]
          
          #Similarity value
          simVal = similarity(series_1,series_2)
          simSum += simVal
          
          #Increment counter
          index_1 += 1
    
      avgSim[lag-1] = simSum/(index_1-1)
      #print index_1-1

  #Calculate weights based on given avgSim array
  totalSim = avgSim.sum()
  weights = numpy.zeros(lastLag)
  for i in range(0,lastLag):
      weights[i] = avgSim[i]/totalSim

  #Return weights
  return weights

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
def anomaly_detect(series,N,thresh,maxLag,maxGrps):
    current = series[0:N]
    historical = series[N:]

    t_weights = temporalWeights(historical,N,maxLag,maxGrps)

    #WEIGHTED MEDIAN AND MEDIAN ABSOLUTE DEVIATION CALCULATION
    #CONSTRUCTING WEIGHTED MEDIAN AND WEIGHTED MEDIAN ABSOLUTE DEVIATION
    historical_weighted = numpy.zeros(t_weights.size)
    for i in range(0,t_weights.size):
        historical_weighted[i] = historical[i]*t_weights[i]

    median_weighted = numpy.median(historical_weighted)
    mad_weighted = numpy.median(numpy.absolute(historical_weighted - median_weighted))

    if numpy.median(current) >= (median_weighted + (thresh*mad_weighted)):
        return 1
    else:
        return 0


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

def main():
    #Initialize test data
    #timeSeries = numpy.array([0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20])
    #timeSeries = numpy.array([5,5,5,30,99,52,48,33,22,84,100])
    Npts = 500
    N = 2
    maxLag = 10
    maxGrps = 10
    thresh = 1.65
    patient_id = 7777
    
    timeSeries=[]

    #for i in range (Npts):
    #    timeSeries.append(random.uniform(0,100))
    
    #timeSeries = numpy.array(timeSeries)
    
    req = requests.get("http://polloninilab.com/ricegroup/weight_basic_measurement.php?id=%s"% str(patient_id),auth=('sharan','bluescale'))
    timeSeries = numpy.genfromtxt(StringIO(req.text),delimiter="|", usecols = 1,dtype = float)
    timeSeries = numpy.append(timeSeries,200)
    
    pl.plot(range(1,timeSeries.size+1),timeSeries)
    pl.ylabel('WEIGHT (lb)')
    pl.xlabel('MEASUREMENT INDEX')
    pl.title('VOLUNTEER WEIGHT VARIATION')
    pl.show()
    
    series_reversed = timeSeries[::-1]
    
    history = series_reversed[N:]
    
    #Call weight function
    weights = temporalWeights(history,N,maxLag,maxGrps)

    print ("Temporal Weights for the given Historical Data")
    print (weights)
    
    pl.plot(range(1,weights.size+1),weights)
    pl.ylabel('TEMPORAL WEIGHTS')
    pl.xlabel('LAG (UNITS OF MEASUREMENT INDEX)')
    pl.title('TEMPORAL WEIGHT VERSUS LAG')
    pl.show()

    print ("ANOMALY DETECTION: ")
    print (anomaly_detect(series_reversed,N,thresh,maxLag,maxGrps))

# This is the standard boilerplate that calls the main() function.
if __name__ == '__main__':
    main()


