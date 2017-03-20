close all;
clear all;
clc;

addpath('filtering/');

% - - - INITIATING THE MATRIX - - - 
patient_ids = [387 2008 2011 2016 2020 2525 3126 6667 6969 8888];
%patient_ids = [2008];
Npatients = length(patient_ids);
Nmeasurements = zeros(Npatients,1); %Number of measurements of each patient
Nmeasurements_valid = zeros(Npatients,1);
Nmetrics = 14;%Weight | qrsAvg| qrsStd| rrAvg | rrStd | prAvg| prStd | stAvg | stStd | rrVar | PTTAvgPeak | PTTAvgFeet | PTTAvgSlope | Bioimpedance 
%global_matrix = zeros(Npatients,Nmetrics,Nmax_measurements);
patient_stats = zeros(Npatients,Nmetrics,2); %Mean and Standard Deviation of each metric for each patient

% - - - GENERATING THE GLOBAL MATRIX - - - 

for i = 1:1:Npatients
    id = patient_ids(i);
    
    % - - - OBTAINING THE WEIGHT AND NUMBER OF MEASUREMENTS - - - 
    system(['python ../Python/weight_measure.py ' num2str(id) ' > temp.txt']);
    fid = fopen('temp.txt');
    op = textscan(fid,'%s %f','delimiter','|');
    system('rm temp.txt');
    %system('del temp.txt');
    fclose(fid);
    
    weights = cell2mat(op(:,2)); % REMOVING THE FIRST VALUE WHICH IS EQUAL TO ZERO
    Nmeasurements(i) = length(weights);

   % - - - OBTAINING THE BIOIMPEDANCE - - - 
   system(['python ../Python/body_water_measure.py ' num2str(id) ' > temp.txt']);
   fid = fopen('temp.txt');
   op = textscan(fid,'%s %f','delimiter','|');
   system('rm temp.txt');
   %system('del temp.txt');
   fclose(fid);
    
   body_water = cell2mat(op(:,2)); % REMOVING THE FIRST VALUE WHICH IS EQUAL TO ZERO
    
    % - - - INPUTTING THE WEIGHTS INTO GLOBAL MATRIX - - - 
    %global_matrix(i,1,1:Nmeasurements(i)) = weights;
    
    % - - - OBTAINING THE ECG AND PPG METRICS - - - 
    for j=1:1:Nmeasurements(i)
        i,j
        
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
        [qrsMeanOut qrsStdOut rrMeanOut rrStDevOut ecgPeakTimes prIntMeanOut...
    prIntStdOut stIntMeanOut stIntStdOut rrVarOut] = ecg_metrics_t(ecg_waveform);
         
        if(isempty(qrsMeanOut)==1)
            continue;
        else
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
            [pttAvgPeak,pttAvgFeet,pttAvgSlope,rrInterval,rrStd] =  ppg_metrics_t(ppg_waveform,ecgPeakTimes);
            
            if(isempty(pttAvgPeak)==1)
                continue;
            else
                Nmeasurements_valid(i) = Nmeasurements_valid(i) + 1;
                global_matrix(i,1,Nmeasurements_valid(i)) = weights(j);
                global_matrix(i,2:10,Nmeasurements_valid(i)) = [qrsMeanOut qrsStdOut rrMeanOut rrStDevOut prIntMeanOut prIntStdOut stIntMeanOut stIntStdOut rrVarOut];
                global_matrix(i,11:13,Nmeasurements_valid(i)) = [pttAvgPeak pttAvgFeet pttAvgSlope];
                global_matrix(i,14,Nmeasurements_valid(i)) = body_water(j);
            end
        end
    end

%     for j=1:1:Nmetrics
%       patient_stats(i,j,1) = mean(global_matrix(i,j,1:Nmeasurements_valid(i)));
%       patient_stats(i,j,2) = std(global_matrix(i,j,1:Nmeasurements_valid(i)));
%     end

end

save(['Patient Statistics_grp_members_new_metrics_ ' datestr(now) '.mat'],'patient_ids','global_matrix');

