import sys
import numpy

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

def similarity(series1,series2):
  #Placeholder function for similarity tests
  #Returns perfect similarity for now
  return 1

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

def temporalWeights(timeSeries,N,maxNumGroups):
  #This function takes a timeSeries and finds the lagged weights
  #N is the size per comparison group
  #maxNumGroups caps the number of backwards comparisons you can make
  #Returns the temporal weights up to lagged by lastLag
  
  #Initialize similarity matrix
  lastLag = 5
  avgSim = numpy.zeros(lastLag)

  #Looping through temporal lag up to lastLag
  for i in range(1,lastLag+1):
    index = 0
    counter = 0
    simSum = 0

    #Copy initial current value
    current = numpy.zeros(N)
    for j in range(N):
      current[j] = timeSeries[j]
    
    print current

    while(index+N<=timeSeries.size):
      #copy comparison segment
      comparison = numpy.zeros(N)
      for j in range(N):
        comparison[j] = timeSeries[index]

      print comparison
      #Get similarity of current vs comparison series
      simVal = similarity(current,comparison)
      simSum += simVal

      #New current is comparison
      current = comparison

      #Increment counters
      index += N
      counter += 1

    #Calculate average similarity and store for lag 'i'
    avgSim[i-1] = simSum/counter
      
  #Calculate weights based on given avgSim array
  totalSim = avgSim.sum()
  weights = numpy.zeros(lastLag)
  for i in range(0,lastLag):
    weights[i] = avgSim[i]/totalSim

  #Return weights
  return weights

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

def main():
  #Initialize test data
  #timeSeries = numpy.array([0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20])
  timeSeries = numpy.array([5,5,5,30,99,52,48,33,22,84,100])
  N = 2
  numGroups = 3

  #Call weight function
  weights = temporalWeights(timeSeries,N,numGroups)

  #print results
  print(weights)

# This is the standard boilerplate that calls the main() function.
if __name__ == '__main__':
  main()
