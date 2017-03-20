%Test Script for Blue Scale Alert
%Part of the Blue Scale Project (ELEC 438 at Rice University)
%Last updated by Joe Chen (2/18/2014)

%Clear workspace
clc;
clear;


%-------------------------------------------------------------------------
%CONTROLLABLE VARIABLES
%-------------------------------------------------------------------------

thres = 2; %Individual attribute alert threshold is a deviation that's 2*MAD
N = 3; %Number of most recent data measurements to not include in median
numTrainingData = 2; %Required amount of training data pts to produce alert


%-------------------------------------------------------------------------
%INITIALIZING TEST DATA
%-------------------------------------------------------------------------

%7 attributes (columns) and 4 time measurements (rows)
%These are the old data points included in the average
fullDataSet = [1 5 9 7 3 2 9;
    10 50 30 22 99 66 1;
    100 33 1000 99 87 252 333;
    22 55 7 6 5000 3 2;
    55 2 3 10 6 7 1000
    0 10 7 8 54 3 2];

%The new test data point coming into the system
newData = [1000 3 5 2 1 1 1];

%Weights for each attribute
weights = [0.05 0.05 0.2 0.2 0.2 0.2 0.1];


%-------------------------------------------------------------------------
%DATA PROCESSING
%-------------------------------------------------------------------------

%Check if an alert is allowed to be sent
[numRows,numCols] = size(fullDataSet);
if(numTrainingData>(numRows-(N-1)))
   display('*********************************************************');
   display('Not enough training data to check for alert try again ');
   display('with more data or a smaller N');
   display('*********************************************************');
   return;
end

%Remove most recent N-1 rows from the dataSet
[lastNData, dataSet] = LastNRows(fullDataSet,N-1);
numOldDataPoints = numRows-(N-1);

%Add newData to end of lastNData
lastNData = [lastNData; newData];


%-------------------------------------------------------------------------
%MEDIAN CALCULATIONS
%-------------------------------------------------------------------------

%Calculate median and MAD of each attribute/column
[med, mad] = MAD(dataSet);

%Calculate each attribute's individual deviation
recentAvg = mean(lastNData);
medDeviation = abs((recentAvg-med)./mad);

%Calculate overall deviation metric
overallDeviation = sum(weights.*medDeviation);


%-------------------------------------------------------------------------
%MEAN CALCULATIONS
%-------------------------------------------------------------------------

%Calculate old average & stdev of each attribute/column
oldMean = mean(dataSet);
oldStDev = std(dataSet);

%Calculate recent avg difference from old average
%    Note: recentAvg is calcualted in the MEDIAN section
meanDeviation = abs(oldMean-recentAvg);


%-------------------------------------------------------------------------
%ALERTS
%-------------------------------------------------------------------------

%Individual alerts (median)
display('*********************************************************');
display('MEDIAN ALERTS');
for i=1:numCols
    if(medDeviation(i) > thres)
        temp = sprintf('[!!] Attribute %d is not within normal levels.',i);
        disp(temp);
        disp('     Please consult a physician.');
    else
        temp = sprintf('[OK] Attribute %d is within normal levels',i);
        disp(temp);
    end
end
display('*********************************************************');

%Individual alerts (mean)
display('*********************************************************');
display('MEAN ALERTS');
for i=1:numCols
    if(meanDeviation(i) > thres*oldStDev(i)/sqrt(numOldDataPoints))
        temp = sprintf('[!!] Attribute %d is not within normal levels.',i);
        disp(temp);
        disp('     Please consult a physician.');
    else
        temp = sprintf('[OK] Attribute %d is within normal levels',i);
        disp(temp);
    end
end
display('*********************************************************');