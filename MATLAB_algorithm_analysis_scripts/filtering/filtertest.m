%Testing filters

%clear workspace and screen
clear;
clc;
close all;

%Inputs
numPoints = 12500; 
samplePeriod = 0.001; %sec per sample
fcornerlp = 20; %Hz
fcornerhp = 2; 
windowSize = 0.15; %time (sec) (0.15 for EKG, 0.5 ppg)

%Calc rates
totalTime = numPoints*samplePeriod; %seconds
fsample = 1/samplePeriod;
dataLoadPath = 'ECG_8888_1.txt';

%Load values
%data = importdata(dataLoadPath,'|');
%dataSeg = data(:,2);
data = importdata(dataLoadPath);
dataSeg = data;
% dataSeg = data(numPoints/4,1);

%%
%Filtering

%Filter (LP)
fnorm = fcornerlp/(fsample/2);
[b,a] = butter(10, fnorm, 'low');
y = filtfilt(b,a,dataSeg);

%Mean y values 
ymean = mean(y);
ystdev = std(y);

%Filter out highly deviated values
% badTimes = [];
% for i=1:1:numPoints
%    if(abs(y(i)-ymean) > 2*ystdev)
%        y(i) = ymean;
%        badTimes = [badTimes (i-1)*samplePeriod];
%    end
% end

%Filter (HP)
fnorm = fcornerhp/(fsample/2);
[b,a] = butter(5, fnorm, 'high');
y = filtfilt(b,a,y);

%%

%Checking windows
times = linspace(0,totalTime,numPoints);
numPtW = windowSize*fsample;
maxLists = [];
for i=1:numPtW:numPoints-numPtW-1
    curVals = y(i:i+numPtW-1);
    [maxVal,index] = max(curVals);
    
    curMean = mean(curVals);
    curStDev = std(curVals);
    
    if(abs(maxVal - curMean) > 2*curStDev...
            && index < numPtW && index > 1)
        maxLists = [maxLists; ...
            times(i)+(index-1)*(1/fsample) maxVal];
    end
end


numPeaks = length(maxLists);

%%
%Finding Q & S around R intervals

%QRS Times
qrsTimes = zeros(1,numPeaks);
qDips = zeros(numPeaks,2);
sDips = zeros(numPeaks,2);
qrsDiff = zeros(numPeaks,2); %Col 1: rVal-qVal;;; Col 2: rVal-sVal

for i=1:1:numPeaks
   %Get current peak
   peakTime = maxLists(i,1);
   peakValue = maxLists(i,2);
   
   %Find Q (left from R)
   compValue = peakValue;
   compTime = peakTime;
   indexLeft = find(times < compTime);
   curIndex = indexLeft(end);
   flag = 1;
   while(flag)      
       if(y(curIndex) < compValue)
           compTime = times(curIndex);
           compValue = y(curIndex);
           curIndex = curIndex-1;
       else
           flag = 0;
       end
   end
   qValue = compValue;
   qTime = compTime;
   qDips(i,:) = [qTime qValue];
   qrsDiff(i,1) = peakValue - qValue;
   
   %Find S (right from R)
   compValue = peakValue;
   compTime = peakTime;
   flag = 1;
   indexRight = find(times > compTime);
   curIndex = indexRight(2);
   while(flag)
       if(curIndex<=numPoints)
           if(y(curIndex) < compValue)
               compTime = times(curIndex);
               compValue = y(curIndex);
               curIndex = curIndex+1;
           else
               flag = 0;
           end
       else
           flag = 0;
       end
   end
   sValue = compValue;
   sTime = compTime;
   sDips(i,:) = [sTime sValue];
   qrsDiff(i,2) = peakValue - sValue;
end

qrsAvg = mean(qrsDiff);
qrsDev = std(qrsDiff);

i=1;
while(i <= numPeaks)
   rValue = maxLists(i,2);
   qValue = qDips(i,2);
   sValue = sDips(i,2);
   
   if(abs((rValue-qValue)-qrsAvg(1)) > qrsDev(1)*2 || abs((rValue-sValue)-qrsAvg(2)) > qrsDev(2)*2)
       maxLists(i,:) = [];
       sDips(i,:) = [];
       qDips(i,:) = [];
       qrsDiff(i,:) = [];
       numPeaks = numPeaks - 1;
   end
   i = i+1; 
end

qrsAvg = mean(qrsDiff);
qrsDev = std(qrsDiff);

%Calculate S-Q Time (QRS Time)
qrsTime = sDips(:,1)-qDips(:,1);

%%
%Calculate average RR interval
rrIntervals = [];
badTimeCounter = 1;
for i=1:1:numPeaks-1
   %Pull values
   leftTime = maxLists(i,1);
   rightTime = maxLists(i+1,1);
   leftVal = maxLists(i,2);
   rightVal = maxLists(i+1,2);
   
   %sum RR intervals
   rrIntervals = [rrIntervals rightTime-leftTime];
end
rrMean = mean(rrIntervals)
rrStDev = std(rrIntervals)

filtRR = [];
for i=1:1:numPeaks-1
    if(abs(rrIntervals(i)-rrMean) <= 2*rrStDev)
       filtRR = [filtRR rrIntervals(i)]; 
    end
end
rrMeanOut = mean(filtRR)
rrStDevOut = std(filtRR)

%%
%Plot results
%times = linspace(0,15/4,numPoints/4);
figure(3);
subplot(2,1,1);
plot(times',dataSeg);
xlabel('Time (s)');
ylabel('EKG Values');
title('Unfiltered EKG Signal');
grid on;
hold on;
subplot(2,1,2);
plot(times',y);
xlabel('Time (s)');
ylabel('EKG Values');
title('Filtered EKG Signal');
grid on;
hold on;
plot(maxLists(:,1),maxLists(:,2),'.r','markersize',16);
hold on;
plot(qDips(:,1),qDips(:,2),'.g','markersize',16);
hold on;
plot(sDips(:,1),sDips(:,2),'.m','markersize',16);