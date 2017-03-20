function [med,mad]=MAD(dataSet)
%This function takes a 1D Array of data and calculates the median (med) and
%   median absolute deviation (mad)  of that array. If you pass it a 
%   matrix, it will return the med and mad of each column.
%Part of the Blue Scale Project (ELEC 438 at Rice University)
%Last updated by Joe Chen (2/18/2014)
med = median(dataSet);
[numRows, numColumns] = size(dataSet);
temp = zeros(numRows,numColumns);
for i=1:numRows
    temp(i,:) = med;
end
temp2 = abs(dataSet-temp);
mad = median(temp2);