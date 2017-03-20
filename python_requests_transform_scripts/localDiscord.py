import sys
import re
import os
import shutil
import commands
import requests
import urllib
import ftplib
import numpy

def distance(series1,series2):
  return euclideanDistance(series1,series2)

def euclideanDistance(series1,series2):
  length = series1.size
  if(series2.size != length):
    print 'error, please enter series of the same length'
    return 0
  else:
    curSum = 0;
    for i in range(length):
      curSum += (series1[i] - series2[i])**2
    ret = curSum**(0.5)
    return ret


def bruteForce(timeSeries,windowSize):
  best_so_far_dist = 0
  best_so_far_loc = 0

  for p in range(1,timeSeries.size-windowSize+1):
    nearest_neighbor_dist = 1000000000000
    for q in range(1,timeSeries.size-windowSize+1):
      if(abs(p-q) >= windowSize):
        dist = distance(timeSeries[p:(p+windowSize-1)],timeSeries[q:(q+windowSize-1)])
        if(dist < nearest_neighbor_dist):
          nearest_neighbor_dist = dist
  if(nearest_neighbor_dist > best_so_far_dist):
    best_so_far_dist = nearest_neighbor_dist
    best_so_far_loc = p
  return (best_so_far_dist, best_so_far_loc)

def main():
  timeSeries = numpy.array([5,5,5,30,99,52,48,33,22,84,100])
  windowSize = 3
  
  dist, loc = bruteForce(timeSeries,windowSize)
  print dist
  print loc
   
if __name__ == "__main__":
    main() 
