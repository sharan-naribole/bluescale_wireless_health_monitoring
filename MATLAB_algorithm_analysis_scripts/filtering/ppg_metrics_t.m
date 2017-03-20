function [pttAvgPeak,pttAvgFeet,pttAvgSlope,rrInterval, rrStd] =  ppg_metrics(data,ecgPeakTimes)

%%
%History Tracking
% jc [4/3/2014] Created basic function
% jc [4/4/2014] Deleted temp outputs, added RR-intervals, suppressed
%               plots/outputs

%%
%Inputs

numPoints = 12500; 
samplePeriod = 0.001; %sec per sample
fcornerlp = 20; %Hz
fcornerhp = 0.5; 
windowSize = 0.5; %time (sec) 


%%
%Check if ecg is thrown out

%If ECG is thrown out, ecgPeakTimes = [] and must throw out PPG also
if(isempty(ecgPeakTimes))
   pttAvgPeak = [];
   pttAvgFeet = [];
   pttAvgSlope = [];
   rrInterval = [];
   rrStd = [];
   return;
end

%%
%Data Filtering

%Calc rates
totalTime = numPoints*samplePeriod; %seconds
fsample = 1/samplePeriod;

%Set times
times = linspace(0,totalTime,numPoints);

%Filter (LP)
fnorm = fcornerlp/(fsample/2);
[b,a] = butter(10, fnorm, 'low');
y = filtfilt(b,a,data);

%Filter (HP)
fnorm = fcornerhp/(fsample/2);
[b,a] = butter(5, fnorm, 'high');
y = filtfilt(b,a,y);


%%
%Find Peaks

%Checking each window
numPtW = windowSize*fsample;
maxLists = [];
for i=1:numPtW:numPoints-numPtW-1
    curVals = y(i:i+numPtW-1);
    [maxVal,index] = max(curVals);
    
    curMean = mean(curVals);
    curStDev = std(curVals);
    
    if(abs(maxVal - curMean) > 1.5*curStDev...
            && index < numPtW && index > 1)
        maxLists = [maxLists; ...
            times(i)+(index-1)*(1/fsample) maxVal];
    end
end

%Get Number of peaks
numPeaks = size(maxLists);
numPeaks = numPeaks(1);

%Eliminate any peaks at the beginning 0.5s
i=1;
while(i<=numPeaks)
   if(maxLists(i,1) < 0.5)
      maxLists(i,:) = [];
      numPeaks = numPeaks - 1;
   end
   i = i+1;
end

%%
%Find foot (local min before PPG peak)

%QRS Times
feet = zeros(numPeaks,2);

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
   footValue = compValue;
   footTime = compTime;
   feet(i,:) = [footTime footValue];
end

i=1;
peakToFoot = maxLists(:,2) - feet(:,2);
meanPeakToFoot = mean(peakToFoot);
stdPeakToFoot = std(peakToFoot);
while(i <= numPeaks)
   rValue = maxLists(i,2);
   footValue = feet(i,2);
   
   if((meanPeakToFoot-(rValue-footValue)) > stdPeakToFoot*2)
       maxLists(i,:) = [];
       feet(i,:) = [];
       numPeaks = numPeaks - 1;
   end
   i = i+1; 
end


%%
%Find max slope point

%Initialize max slope matrix
maxSlopeTimes = zeros(numPeaks,2); %Time value, intensity (not slope)

%Get point to point differences in data
ydiff = diff(y);

for i = 1:1:numPeaks 
   %Get subsection of feet and peaks
   timeLeft = find(times < maxLists(i,1)); 
   timeRight = find(times >= feet(i,1));
   timeIndicies = intersect(timeLeft,timeRight);
   curMaxTime = 0;
   curMaxSlope = 0;
   curMaxIntensity = 0;
   
   %Check slope of each index (Left diff)
   for j = timeIndicies
       if(ydiff(j) > curMaxSlope)
          curMaxSlope = ydiff(j);
          curMaxTime = times(j);
          curMaxIntensity = y(j);
       end
   end
   maxSlopeTimes(i,:) = [curMaxTime curMaxIntensity];
end

%%
%Calculate Pulse Transit times

%Initialize
ptt = []; %Ordering: foot, slope, peak
%numPeaks
%Iterate through each foot-slope-peak grouping
for i = 1:1:numPeaks
   %Find all ECG peak times before foot
   footTime = feet(i,1);
   ecgIndicies = find(ecgPeakTimes < footTime);
   numTimesFound = length(ecgIndicies);
   
   %If a time is found, then add to matrix
   if(numTimesFound > 0)
       ecgCurIndex = ecgIndicies(end); %Last time corresponds to this grouping
       ecgCurTime = ecgPeakTimes(ecgCurIndex);
       ptt = [ptt;...
           footTime-ecgCurTime, maxSlopeTimes(i,1)-ecgCurTime, maxLists(i,1)-ecgCurTime];
       
       %[5/29/2014] Erase all times before the CurIndex up to this index
       ecgPeakTimes(1:1:ecgCurIndex) = [];
   end
end

%Calculate stats of each
pttMean = mean(ptt);
pttStd = std(ptt);

%Output each
pttAvgFeet = pttMean(1);
pttAvgSlope = pttMean(2);
pttAvgPeak = pttMean(3);


%%
%Calculate RR-intervals

rr = diff(maxLists(:,1));
rrInterval = mean(rr);
rrStd = std(rr);

%%
%Waveform Throwout check
%Must be done after all processing

%Step 1: If number of peaks less than six, throw out waveform
if(numPeaks < 6)
   pttAvgPeak = [];
   pttAvgFeet = [];
   pttAvgSlope = [];
   rrInterval = [];
   rrStd = [];
   return; 
end

%%
%Plot Results (TODO: Comment out)

% figure(3);
% subplot(2,1,1);
% plot(times',data);
% xlabel('Time (s)');
% ylabel('Intensity');
% title('Unfiltered PPG Signal');
% grid on;
% hold on;
% subplot(2,1,2);
% plot(times',y);
% xlabel('Time (s)');
% ylabel('Intensity');
% title('Filtered PPG Signal');
% grid on;
% hold on;
% 
% %Plot R peaks
% plot(maxLists(:,1),maxLists(:,2),'.r','markersize',16);
% hold on;
% 
% %Plot feet
% plot(feet(:,1),feet(:,2),'.g','markersize',16);
% hold on;
% 
% %Max Slope times
% plot(maxSlopeTimes(:,1),maxSlopeTimes(:,2),'.m','markersize',16);
% hold on;

