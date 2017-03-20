function [qrSlope,rsSlope,myVals] = qrsSlopes(maxLists, qDips, sDips)

[numPts,~] = size(maxLists);
qrsSlopes = zeros(numPts,2); %[QRSlope, RS Slope]

for i = 1:1:numPts
    myQR = (maxLists(i,2)-qDips(i,2))/(maxLists(i,1)-qDips(i,1));
    myRS = (sDips(i,2)-maxLists(i,2))/(sDips(i,1)-maxLists(i,1));
    
    qrsSlopes(i,:) = [abs(myQR), abs(myRS)];
end

qrsMean = mean(qrsSlopes);
qrsStd = std(qrsSlopes);

qrSlope = [qrsMean(:,1) qrsStd(:,1)];
rsSlope = [qrsMean(:,2) qrsStd(:,2)];
myVals = qrsSlopes;