function [qrsMeanOut qrsStdOut rrMeanOut rrStDevOut peakTimes] = ecg_metrics(data)
% Function to output ECG metrics provided the ECG waveform

%Inputs
numPoints = 12500; 
samplePeriod = 0.001; %sec per sample
fcornerlp = 20; %Hz
fcornerhp = 0.5; 
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
%FFT

y_fft = abs(fft(y));            %Retain Magnitude
y_fft = y_fft(1:numPoints/2);      %Discard Half of Points
f = fsample*(0:numPoints/2-1)/numPoints;   %Prepare freq data for plot

% figure(20);
% plot(f, y_fft);
% xlim([0 50]);
% xlabel('Frequency (Hz)')
% ylabel('Amplitude')
% title('Frequency Response of Tuning Fork A4')


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
    else
        %Is one of the end points
        if(index == 1)
            %Left edge
            if(i-1 > 0)
                if(y(i-1) < y(i))
                    maxLists = [maxLists; ...
                        times(i)+(index-1)*(1/fsample) maxVal];
                end
            end
        else
            %Right edge
            if(index == numPtW)
                rightEdge = i+numPtW-1;
                if(rightEdge+1 <= numPoints)
                    if(y(rightEdge+1) < y(rightEdge))
                        maxLists = [maxLists; ...
                            times(i)+(index-1)*(1/fsample) maxVal];
                    end
                end
            else
                display('Something is wrong'); 
            end
        end
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
      %If we remove a point, i = i+1
   else
      i = i+1;
   end
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

i=1;
while(i <= numPeaks)
   rValue = maxLists(i,2);
   qValue = qDips(i,2);
   sValue = sDips(i,2);
   
   if(abs(qrsAvg(1)-(rValue-qValue)) > qrsDev(1)*2 || abs(qrsAvg(2)-(rValue-sValue)) > qrsDev(2)*2)
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
%Check QRS Slopes

[qrSlope, rsSlope,myVals] = qrsSlopes(maxLists,qDips,sDips);

i=1;
while(i <= numPeaks)
    myQR = myVals(i,1); %[mean, std]
    myRS = myVals(i,2); %[mean, std]
    
    if(myQR < (qrSlope(1)-0*qrSlope(2))...
            || myRS < (rsSlope(1)-0*rsSlope(2)))
        maxLists(i,:) = [];
        qDips(i,:) = [];
        sDips(i,:) = [];
        myVals(i,:) = [];
        numPeaks = numPeaks - 1;
        %Erasing entry i, makes i = i+1
    else
        i = i + 1;
    end
end


%[Output] True QRS time
qrsTime = sDips(:,1)-qDips(:,1);
qrsMeanOut = mean(qrsTime);
qrsStdOut = std(qrsTime);




%%
%Calculate average RR interval
rrIntervals = [];
for i=1:1:numPeaks-1
   %Pull values
   leftTime = maxLists(i,1);
   rightTime = maxLists(i+1,1);
   leftVal = maxLists(i,2);
   rightVal = maxLists(i+1,2);
   
   %sum RR intervals
   rrIntervals = [rrIntervals rightTime-leftTime];
end
rrMean = mean(rrIntervals);
rrStDev = std(rrIntervals);

filtRR = [];
for i=1:1:numPeaks-1
    if(abs(rrIntervals(i)-rrMean) <= 2*rrStDev)
       filtRR = [filtRR rrIntervals(i)]; 
    end
end

%[output] RR mean and variation
rrMeanOut = mean(filtRR);
rrStDevOut = std(filtRR);

%[Output] peak times
peakTimes = maxLists(:,1);

%%
%Waveform Throwout check
%Must be done after all processing

%Step 1: If number of peaks less than six, throw out waveform
if(numPeaks < 6)
    qrsMeanOut = [];
    qrsStdOut = [];
   rrMeanOut = [];
   rrStDevOut = [];
   peakTimes = [];
   return; 
end


%%
%Plot results
% figure(2);
% subplot(2,1,1);
% plot(times',dataSeg);
% xlabel('Time (s)');
% ylabel('EKG Values');
% title('Unfiltered EKG Signal');
% grid on;
% hold on;
% subplot(2,1,2);
% plot(times',y);
% xlabel('Time (s)');
% ylabel('EKG Values');
% title('Filtered EKG Signal');
% grid on;
% hold on;
% hr = plot(maxLists(:,1),maxLists(:,2),'.r','markersize',16);
% hold on;
% hq = plot(qDips(:,1),qDips(:,2),'xk','markersize',16);
% hold on;
% hs = plot(sDips(:,1),sDips(:,2),'.m','markersize',16);
% hold on;
% legend([hr hq hs],'Q Dips','R Peaks','S Dips');