function irasterToFiringRate(binaryData,InhbinaryData,decayWindow,RasterMap,Npop)
% assume that decayWindow is in same units as time steps in binaryData

[rows,cols] = size(binaryData);
rateData = zeros(rows,cols);
for row = 1:rows
    for col = 2:cols
        rateData(row,col) = rateData(row,col-1) - rateData(row,col-1)/decayWindow + binaryData(row,col);
    end
end

[rows,cols] = size(InhbinaryData);
InhrateData = zeros(rows,cols);
for row = 1:rows
    for col = 2:cols
        InhrateData(row,col) = InhrateData(row,col-1) - InhrateData(row,col-1)/decayWindow + InhbinaryData(row,col);
    end
end


InhrateData = InhrateData*(-1);

[plotratedata,plotinhratedata] = deal(zeros(rows+Npop,cols));

plotratedata(1:1:rows,:) = rateData;
plotinhratedata((Npop+1:1:rows+Npop),:) = InhrateData;

plotdata = plotratedata + plotinhratedata;

figure;
imagesc(plotdata);
colorbar
colormap(RasterMap)
clim([-10 16])