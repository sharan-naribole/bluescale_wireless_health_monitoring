close all;
clear all;
clc;

addpath('filtering/');

% - - - INITIATING THE MATRIX - - - 
id = 8888;
Npatients = length(id);
%Nmeasurements_valid = zeros(Npatients,1);
%Nmetrics = 14;%Weight | qrsAvg| qrsStd| rrAvg | rrStd | prAvg| prStd | stAvg | stStd | rrVar | PTTAvgPeak | PTTAvgFeet | PTTAvgSlope | Bioimpedance 
%global_matrix = zeros(Npatients,Nmetrics,Nmax_measurements);

%patient_stats = zeros(Npatients,Nmetrics,2); %Mean and Standard Deviation of each metric for each patient

system(['python ../Python/weight_measure.py ' num2str(id) ' > temp.txt']);
fid = fopen('temp.txt');
op = textscan(fid,'%s %f','delimiter','|');
system('rm temp.txt');
%system('del temp.txt');
fclose(fid);

weights = cell2mat(op(:,2)); % REMOVING THE FIRST VALUE WHICH IS EQUAL TO ZERO
timestamps = op(:,1);
Nmeasurements = length(weights);
numPoints = 12500;
ecg_data = zeros(Nmeasurements,numPoints);
ppg_data = zeros(Nmeasurements,numPoints);

% - - - OBTAINING THE ECG AND PPG METRICS - - - 
for j=1:1:Nmeasurements

    j
    
    if id==2016 && j>21 && j<24
        continue;
    end

    % - - - ECG METRICS - - -
    system(['python ../Python/ecg_waveform.py ' num2str(id) ' ' num2str(j) ' > temp.txt']);
    fid = fopen('temp.txt');
    op = textscan(fid,'%f');
    fclose(fid);
    system('rm temp.txt');
    %system('del temp.txt');

    ecg_waveform = cell2mat(op);
    ecg_data(j,:) = ecg_waveform;
    %[qrsMeanOut qrsStdOut rrMeanOut rrStDevOut ecgPeakTimes prIntMeanOut...
%prIntStdOut stIntMeanOut stIntStdOut rrVarOut] = ecg_metrics_t(ecg_waveform);

%     if(isempty(qrsMeanOut)==1)
%         continue;
%     else
        %global_matrix(i,2,j) = qrsAvg;
        %global_matrix(i,3,j) = qrsDev;

        % - - - PPG METRICS - - - 
        system(['python ../Python/pleth_waveform.py ' num2str(id) ' ' num2str(j) ' > temp.txt']);
        fid = fopen('temp.txt');
        op = textscan(fid,'%f');
        fclose(fid);
        system('rm temp.txt');
        %system('del temp.txt');

        ppg_waveform = cell2mat(op);
        ppg_data(j,:) = ppg_waveform;
        %[pttAvgPeak,pttAvgFeet,pttAvgSlope,rrInterval,rrStd] =  ppg_metrics_t(ppg_waveform,ecgPeakTimes);

%         if(isempty(pttAvgPeak)==1)
%             continue;
%         else
%             Nmeasurements_valid(i) = Nmeasurements_valid(i) + 1;
%             global_matrix(i,1,Nmeasurements_valid(i)) = weights(j);
%             global_matrix(i,2:10,Nmeasurements_valid(i)) = [qrsMeanOut qrsStdOut rrMeanOut rrStDevOut prIntMeanOut prIntStdOut stIntMeanOut stIntStdOut rrVarOut];
%             global_matrix(i,11:13,Nmeasurements_valid(i)) = [pttAvgPeak pttAvgFeet pttAvgSlope];
%             global_matrix(i,14,Nmeasurements_valid(i)) = body_water(j);
%         end
end

% for j=1:1:Nmetrics
%   patient_stats(i,j,1) = mean(global_matrix(i,j,1:Nmeasurements_valid(i)));
%   patient_stats(i,j,2) = std(global_matrix(i,j,1:Nmeasurements_valid(i)));
% end

save(['ECG_PPG_RAW_DATA_ID_' num2str(id) '_' datestr(now) '.mat'],'ecg_data','ppg_data','timestamps');

