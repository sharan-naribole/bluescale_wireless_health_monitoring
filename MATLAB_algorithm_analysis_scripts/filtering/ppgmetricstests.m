%Tests for ppg_metrics function

%clear workspace and screen
clear;
clc;
close all;

%Load ECG data
dataPathECG = 'ECG_7777_1.txt';
dataECG = importdata(dataPathECG);

%Load PPG Data
dataPathPPG = 'PPG_7777_1.txt';
dataPPG = importdata(dataPathPPG);

%Call ECG Metrics
[rrMeanOut rrStDevOut peakTimes] = ecg_metrics(dataECG);

%Call ppg_metrics function
[pttAvgPeak,pttAvgFeet,pttAvgSlope,rrInterval, rrStd] =  ppg_metrics(dataPPG,peakTimes);