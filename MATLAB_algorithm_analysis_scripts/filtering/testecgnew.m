%Tests for EKG and PPG functions

%clear workspace and screen
clear;
clc;
close all;

%Load ECG data
dataPathECG = [];
dataPathECG = [dataPathECG; 'ECG_7777_1.txt'];
dataPathECG = [dataPathECG; 'ECG_7777_2.txt'];
dataPathECG = [dataPathECG; 'ECG_7777_3.txt'];
dataPathECG = [dataPathECG; 'ECG_7777_4.txt'];
dataPathECG = [dataPathECG; 'ECG_7777_5.txt'];

%Load PPG Data
dataPathPPG = [];
dataPathPPG = [dataPathPPG; 'PPG_7777_1.txt'];
dataPathPPG = [dataPathPPG; 'PPG_7777_2.txt'];
dataPathPPG = [dataPathPPG; 'PPG_7777_3.txt'];
dataPathPPG = [dataPathPPG; 'PPG_7777_4.txt'];
dataPathPPG = [dataPathPPG; 'PPG_7777_5.txt'];

%Call ECG Metrics
myData = zeros(5,12);
for i = 1:1:5
    dataECG = importdata(dataPathECG(i,:));
    dataPPG = importdata(dataPathPPG(i,:));
    
    [qrsMeanOut qrsStdOut rrMeanOut rrStDevOut peakTimes prIntMeanOut...
        prIntStdOut stIntMeanOut stIntStdOut rrVarOut] = ecg_metrics_t(dataECG);
    
    [pttAvgPeak,pttAvgFeet,pttAvgSlope,rrInterval, rrStd] =  ppg_metrics_t(dataPPG,peakTimes);
    
    %[REF FOR SHARAN] Checking if the waveforms are thrown out
    if(isempty(qrsMeanOut))
        %[REF FOR SHARAN]
        %PPG was thrown out, throw out all waveform metrics
        %HOWEVER please keep bioimpedance and weight
        temp = zeros(1,12);
        temp(:)=nan;
        myData(i,:) = temp;
    else
        if(isempty(pttAvgPeak))
            %[REF FOR SHARAN]
            %PPG thrown out but not EKG, save bioimpedance and weight
            temp = zeros(1,3);
            temp(:)=nan;
            myData(i,:) = [qrsMeanOut qrsStdOut rrMeanOut rrStDevOut temp prIntMeanOut...
                prIntStdOut stIntMeanOut stIntStdOut rrVarOut];
        else
            %[REF FOR SHARAN]
            %Both PPG and EKG accepted, save bioimpedance and weight
            myData(i,:) = [qrsMeanOut qrsStdOut rrMeanOut rrStDevOut pttAvgPeak pttAvgFeet pttAvgSlope prIntMeanOut...
            prIntStdOut stIntMeanOut stIntStdOut rrVarOut];
        end
    end
end 

labels=['1QRS Mean','2QRS Std','3RR Mean','4RR Std','5PTTPeak','6PTTFoot','7PTTSlope','8PR Int Mean', '9PR Int Std',...
    '10 ST Int Mean','11ST Int Std', '12RR Var']
myMean = nanmean(myData) %[REF FOR SHARAN] removes NaN before calc
myStd = nanstd(myData) %[REF FOR SHARAN] removes NaN before calc


%END