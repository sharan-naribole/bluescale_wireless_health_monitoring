function [qrsMeanOut qrsStdOut rrMeanOut rrStDevOut peakTimes prIntMeanOut...
    prIntStdOut stIntMeanOut stIntStdOut rrVarOut] = ecg_metrics(data)
% Function to output ECG metrics provided the ECG waveform

%Inputs
numPoints = 12500; 
samplePeriod = 0.001; %sec per sample
fcornerlp = 20; %Hz
fcornerlp2 = 10; %Hz, for P and T peak detection
fcornerhp = 0.5; 
windowSize = 0.15; %time (sec) (0.15 for EKG, 0.5 ppg)
subWindowIndexSize = 100; %Checks +/- 100 points

%Calc rates
totalTime = numPoints*samplePeriod; %seconds
fsample = 1/samplePeriod;

%Mask data
dataSeg = data;

%%
%Filtering (main)

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
% [5/28/2014] Filtering (extra strong for P and T peak detection)

%Filter (LP)
% fnorm = fcornerlp2/(fsample/2);
% [b,a] = butter(10, fnorm, 'low');
% y_strong = filtfilt(b,a,dataSeg);

%Mean y values 
% ymean = mean(y);
% ystdev = std(y);

%Filter out highly deviated values
% badTimes = [];
% for i=1:1:numPoints
%    if(abs(y(i)-ymean) > 2*ystdev)
%        y(i) = ymean;
%        badTimes = [badTimes (i-1)*samplePeriod];
%    end
% end

%Filter (HP)
% fnorm = fcornerhp/(fsample/2);
% [b,a] = butter(5, fnorm, 'high');
% y_strong = filtfilt(b,a,y_strong);

%%
%FFT

% y_fft = abs(fft(y));            %Retain Magnitude
% y_fft = y_fft(1:numPoints/2);      %Discard Half of Points
% f = fsample*(0:numPoints/2-1)/numPoints;   %Prepare freq data for plot

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
    if(abs(rrIntervals(i)-rrMean) <= 2.5*rrStDev && abs(rrIntervals(i)-rrMean) <= 1.5)
       filtRR = [filtRR rrIntervals(i)]; 
    end
end

%[output] RR mean and variation
rrMeanOut = mean(filtRR);
rrStDevOut = std(filtRR);
rrVarOut = var(filtRR);

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
   prIntMeanOut = [];
    prIntStdOut = [];
    stIntMeanOut = [];
    stIntStdOut = [];
    stAmpMeanOut =[];
    stAmpStdOut = [];
   return; 
end

%If range is greater than 4500, there's probably something wrong
if(range(y) > 4500)
   qrsMeanOut = [];
   qrsStdOut = [];
   rrMeanOut = [];
   rrStDevOut = [];
   peakTimes = [];
      prIntMeanOut = [];
    prIntStdOut = [];
    stIntMeanOut = [];
    stIntStdOut = [];
    stAmpMeanOut =[];
    stAmpStdOut = [];
   return;
end


%%
%[5/28/2014] Finding P and T peaks

%Initialize arrays
pPeaks = zeros(numPeaks,2); %first element will be 0,0
tPeaks = zeros(numPeaks,2); %last element will be 0,0

for i=1:1:numPeaks-1
    %Get border R times to check RR interval
    timeDiff = maxLists(i+1,1) - maxLists(i,1);
    
    %Sanity check to make sure QRS has not been skipped
    if(timeDiff < rrMeanOut + 2.5*rrStDevOut && timeDiff <= 1.5)
        %Get S (left QRS) and Q (right QRS) points
        myS = sDips(i,:);
        myQ = qDips(i+1,:);

        %Midpoint partitions left (T peak) and right (P peak) zones
        midPoint = mean([myS(1); myQ(1)]);

        %Get partitions
        leftInd = find(times <= midPoint & times > myS(1));
        rightInd = find(times > midPoint & times <= myQ(1));
        leftVals = y(leftInd);
        leftTimes = times(leftInd);
        rightVals = y(rightInd);
        rightTimes = times(rightInd);

        %Check partitions, if any are 0, then quit attempt
        if(isempty(leftVals) || isempty(rightVals))
            continue;
        end
        
        %Get peaks of each partition
        [tVal, tInd] = max(leftVals);
        [pVal, pInd] = max(rightVals);

        %If end point, must check if it's a real maximum
        if(tInd == 1 || tInd == length(leftVals))
            cutOff = floor(length(leftVals)*.2);
            leftVals = leftVals(cutOff:1:(length(leftVals)-cutOff));
            
            [tVal, tInd] = max(leftVals);
            tTime = leftTimes(tInd);
            if(tInd == 1 || tInd == length(leftVals))
                %Quit without saving values for this set
                tVal = 0;
                tTime = 0;
            end
        else
            %Find time of each partition
            tTime = leftTimes(tInd);
        end
        
        if(pInd == 1 || pInd == length(rightVals))
            cutOff = floor(length(rightVals)*.2);
            rightVals = rightVals(cutOff:1:(length(rightVals)-cutOff));
            
            [pVal, pInd] = max(rightVals);
            pTime = rightTimes(pInd);
            if(pInd == 1 || pInd == length(rightVals))
                %Quit without saving values for this set
                pVal = 0;
                pTime = 0;
            end
        else
            %Find time of each partition
            pTime = rightTimes(pInd);
        end

        %Store in array
        if(length(tTime) > 0 && length(pTime) > 0)
            tPeaks(i,:) = [tTime tVal];
            pPeaks(i+1,:) = [pTime pVal];
        end
    end
end

%%
%[5/29/2014] Calculate PR and ST metrics

%Initialize arrays
prInterval = []; %PR interval goes from P peak to Q dip
stInterval = [];
stAmplitude = [];

for i=1:1:numPeaks
    myQ = qDips(i,:);
    myR = maxLists(i,:);
    myS = sDips(i,:);
    myP = pPeaks(i,:);
    myT = tPeaks(i,:);
    
    %If a P peak was found
    if(myP(1) > 0)
        %PR interval goes from P peak to Q dip
        prInterval = [prInterval; myQ(1) - myP(1)];
    end
    
    %If a T peak was found
    if(myT(1) > 0)
       stInterval = [stInterval; myT(1) - myS(1)];
       stAmplitude = [stAmplitude; myT(2) - myS(2)];
    end
end

%[Output] PR interval, ST interval, ST amplitude
prIntMeanOut = mean(prInterval);
prIntStdOut = std(prInterval);
stIntMeanOut = mean(stInterval);
stIntStdOut = std(stInterval);
stAmpMeanOut = mean(stAmplitude);
stAmpStdOut = std(stAmplitude);

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
% ht = plot(tPeaks(:,1),tPeaks(:,2),'.g','markersize',16);
% hold on;
% hp = plot(pPeaks(:,1),pPeaks(:,2),'.y','markersize',16);
% hold on;
% legend([hr hq hs ht hp],'Q Dips','R Peaks','S Dips','T Peaks','P Peaks');