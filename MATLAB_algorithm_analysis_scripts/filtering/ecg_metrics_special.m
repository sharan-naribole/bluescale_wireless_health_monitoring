function [rrMeanOut rrStDevOut peakTimes] = ecg_metrics(data)
% Function to output ECG metrics provided the ECG waveform

%Inputs
numPoints = 12500; 
samplePeriod = 0.001; %sec per sample
fcornerlp = 20; %Hz
fcornerhp = 1; 
windowSize = 0.15; %time (sec) (0.15 for EKG, 0.5 ppg)
subWindowIndexSize = 100; %Checks +/- 100 points

%Calc rates
totalTime = numPoints*samplePeriod; %seconds
fsample = 1/samplePeriod;

%Mask data
dataSeg = data;

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
    
    if(index*samplePeriod>0.5 && index*samplePeriod<(totalTime-0.5))
        subCurVals = y(((i+(index-1))-(subWindowIndexSize)):((i+(index-1))+(subWindowIndexSize)));
    else
        subCurVals = curVals;
    end
    
    curMean = mean(subCurVals);
    curStDev = std(subCurVals);
    
%     if(abs(maxVal - curMean) > 2*curStDev...
%             && index < numPtW && index > 1)
      if(index < numPtW && index > 1)
        maxLists = [maxLists; ...
            times(i)+(index-1)*(1/fsample) maxVal];
      end
end

numPeaks = size(maxLists);
numPeaks = numPeaks(1);

%Eliminate any peaks at the beginning 0.5s
i=1;
while(i<=numPeaks)
   if(maxLists(i,1) < 0.5 || maxLists(i,1) > totalTime-0.5)
      maxLists(i,:) = [];
      numPeaks = numPeaks - 1;
   end
   i = i+1;
end

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

% i=1;
% while(i <= numPeaks)
%    rValue = maxLists(i,2);
%    qValue = qDips(i,2);
%    sValue = sDips(i,2);
%    
%    if((qrsAvg(1)-(rValue-qValue)) > qrsDev(1)*0.5 || (qrsAvg(2)-(rValue-sValue)) > qrsDev(2)*0.5)
%        maxLists(i,:) = [];
%        sDips(i,:) = [];
%        qDips(i,:) = [];
%        qrsDiff(i,:) = [];
%        numPeaks = numPeaks - 1;
%        
%        qrsAvg = mean(qrsDiff);
%        qrsDev = std(qrsDiff);
%    end
%    i = i+1; 
% end

qrsAvg = mean(qrsDiff);
qrsDev = std(qrsDiff);

%%
%Filter peaks based on slope

%Alterable vars
checkWindow = 2; %second
slopeVals = [];

%Calculate RS difference
rsTimeDiff = sDips(:,1) - maxLists(:,1);
rsValDiff = sDips(:,2) - maxLists(:,2);
rsSlopes = [maxLists(:,1) rsValDiff./rsTimeDiff];

for i = 1:checkWindow:floor(totalTime)
    [indexInWindow,~] = find(rsSlopes(:,1) < i + checkWindow & rsSlopes(:,1) > i);
    ret = max(abs(rsSlopes(indexInWindow,2)));
%     if(~isnan(ret))
        slopeVals = [slopeVals ret];
%     end
end
slopeVals
avgRSlope = mean(slopeVals);
stdRSlope = std(slopeVals);

j=1;
while(j <= numPeaks)
   curSlope = rsSlopes(j,2);
   
   if(abs(curSlope - avgRSlope) > 2.5*stdRSlope)
       maxLists(j,:) = [];
       sDips(j,:) = [];
       qDips(j,:) = [];
       qrsDiff(j,:) = [];
       rsSlopes(j,:) = [];
       numPeaks = numPeaks - 1;
   end
   
   j = j+1; 
end

%Reupdate QRS
qrsAvg = mean(qrsDiff);
qrsDev = std(qrsDiff);


%%
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
    if(abs(rrIntervals(i)-rrMean) <= 2*rrStDev && rrIntervals(i) <= 1.5)
       filtRR = [filtRR rrIntervals(i)]; 
    end
end
rrMeanOut = mean(filtRR)
rrStDevOut = std(filtRR)

%Output peak times
peakTimes = maxLists(:,1);

%%
%Waveform Throwout check
%Must be done after all processing

%Step 1: If number of peaks less than six, throw out waveform
if(numPeaks < 3)
   rrMeanOut = [];
   rrStDevOut = [];
   peakTimes = [];
   return; 
end


%%
%Plot results
figure(2);
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