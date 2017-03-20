close all;
clear all;
clc;

addpath('filtering/');

measure_id = 3;%Measurement_id
patient_id = 8889; %Scenario patient ID
normal_id = 4; % Sorted number in [3126,6666,7777,8888]

Nmetrics = 14;%Weight | qrsAvg| qrsStd| rrAvg | rrStd | prAvg| prStd | stAvg | stStd | rrVar | PTTAvgPeak | PTTAvgFeet | PTTAvgSlope | Bioimpedance 

scenario_metrics = zeros(Nmetrics,1);
z_scores = zeros(Nmetrics,1);

id = patient_id;
j = measure_id;

system(['python ../Python/weight_measure.py ' num2str(id) ' > temp.txt']);
fid = fopen('temp.txt');
op = textscan(fid,'%s %f','delimiter','|');
system('rm temp.txt');
fclose(fid);

weights = cell2mat(op(:,2)); % REMOVING THE FIRST VALUE WHICH IS EQUAL TO ZERO

Nmeasurements = length(weights);

% - - - OBTAINING THE BIOIMPEDANCE - - - 
system(['python ../Python/body_water_measure.py ' num2str(id) ' > temp.txt']);
fid = fopen('temp.txt');
op = textscan(fid,'%s %f','delimiter','|');
system('rm temp.txt');
fclose(fid);

body_water = cell2mat(op(:,2));

system(['python ../Python/ecg_waveform.py ' num2str(id) ' ' num2str(j) ' > temp.txt']);
fid = fopen('temp.txt');
op = textscan(fid,'%f');
fclose(fid);
system('rm temp.txt');

ecg_waveform = cell2mat(op);
[qrsMeanOut qrsStdOut rrMeanOut rrStDevOut ecgPeakTimes prIntMeanOut...
    prIntStdOut stIntMeanOut stIntStdOut rrVarOut] = ecg_metrics_t(ecg_waveform);

if(isempty(qrsMeanOut)==1)
    continue;
else
    %scenario_metrics(i,2,j) = qrsAvg;
    %scenario_metrics(i,3,j) = qrsDev;

    % - - - PPG METRICS - - - 
    system(['python ../Python/pleth_waveform.py ' num2str(id) ' ' num2str(j) ' > temp.txt']);
    fid = fopen('temp.txt');
    op = textscan(fid,'%f');
    fclose(fid);
    system('rm temp.txt');

    ppg_waveform = cell2mat(op);
    [pttAvgPeak,pttAvgFeet,pttAvgSlope,rrInterval,rrStd] =  ppg_metrics_t(ppg_waveform,ecgPeakTimes);

    if(isempty(pttAvgPeak)==1)
        continue;
    else
        scenario_metrics(1) = weights(Nmeasurements-j+1);
        scenario_metrics(2:10) = [qrsMeanOut qrsStdOut rrMeanOut rrStDevOut prIntMeanOut prIntStdOut stIntMeanOut stIntStdOut rrVarOut];
        scenario_metrics(11:13) = [pttAvgPeak pttAvgFeet pttAvgSlope];
        scenario_metrics(14) = body_water(Nmeasurements-j+1);
    end
end

% - - - Z-SCORE COMPUTATION - - -
load('Patient Statistics_grp_members_new_metrics_ 30-May-2014 11:13:04.mat');

for i=1:1:Nmetrics
    mean_metric = patient_stats(normal_id,i,1);
    std_metric = patient_stats(normal_id,i,2);
    
    z_scores(i) = (scenario_metrics(i) - mean_metric)/std_metric;
end
