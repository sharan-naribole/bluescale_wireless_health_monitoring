function [lastNData,otherData]=LastNRows(dataSet,N)
%This function takes a Matrix of data and calculates removes the last N
%   rows of data. 
%Inputs:
%   dataSet: The data set of interest
%   N: Number of rows to pull from data set
%Outputs:
%   lastNData: The last N rows of data in matrix form
%   otherData: The remaining data rows.
%Part of the Blue Scale Project (ELEC 438 at Rice University)
%Last updated by Joe Chen (2/18/2014)

%Initialize return values
[numRows,numCols] = size(dataSet);
lastNData = zeros(N,numCols);
otherData = zeros(numRows-N,numCols);

%Check that the at least N+1 rows exist in the matrix
if(numRows < N) 
    disp('Error... number of rows is less than N');
else
    for i=1:numRows
        if(i<=numRows-N)
           otherData(i,:) = dataSet(i,:); 
        else
           lastNData((i-(numRows-N)),:) = dataSet(i,:); 
        end
    end
end