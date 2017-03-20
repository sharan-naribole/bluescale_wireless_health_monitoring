close all;
clear all;
clc;

addpath('filtering/');

% - - - INITIATING THE MATRIX - - - 
patient_ids = [387 2008 2011 2016 2020 2525 3126 6667 6969 8888];
Npatients = length(patient_ids);
Nmetrics = 2;%Weight | Bioimpedance 

patient_stats = zeros(Npatients,Nmetrics,2); %Mean and Standard Deviation of each metric for each patient

% - - - GENERATING THE GLOBAL MATRIX - - - 

for i = 1:1:Npatients    
    id = patient_ids(i);
    
    % - - - OBTAINING THE WEIGHT AND NUMBER OF MEASUREMENTS - - - 
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
    
   body_water = cell2mat(op(:,2)); % REMOVING THE FIRST VALUE WHICH IS EQUAL TO ZERO
    
    % - - - INPUTTING THE WEIGHTS INTO GLOBAL MATRIX - - - 
    global_matrix(i,1,1:Nmeasurements) = weights;
    global_matrix(i,2,1:Nmeasurements) = body_water;
end

save(['Patient Statistics_simple_batch_ ' datestr(now) '.mat'],'patient_ids','global_matrix');

