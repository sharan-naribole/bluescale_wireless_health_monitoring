close all;
clear all;
clc;

addpath('filtering/');

measure_id = 4;%Measurement_id
patient_id = 7778; %Scenario patient ID
normal_id = 3; % Sorted number in [3126,6666,7777,8888]

Nmetrics = 2;%Weight | qrsAvg| qrsStd| rrAvg | rrStd | prAvg| prStd | stAvg | stStd | rrVar | PTTAvgPeak | PTTAvgFeet | PTTAvgSlope | Bioimpedance 

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
scenario_metrics(1) = weights(Nmeasurements-j+1);
scenario_metrics(2) = body_water(Nmeasurements-j+1);

% - - - Z-SCORE COMPUTATION - - -
load('Patient Statistics_grp_members_new_metrics_ 30-May-2014 11:13:04.mat');

for i=1:1:Nmetrics
    if(i==2)
      j=14;  
    else
        j=i;
    end
      mean_metric = patient_stats(normal_id,j,1);
      std_metric = patient_stats(normal_id,j,2);
      z_scores(i) = (scenario_metrics(i) - mean_metric)/std_metric;
end
