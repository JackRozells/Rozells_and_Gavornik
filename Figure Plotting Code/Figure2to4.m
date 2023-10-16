%%Plotting after PostTraining Testing
load('FinalValuesOfMostRecentTrial.mat');

%% Figure #2: Singular Neuron Voltage Plotting Comparison

% figure
% title('No ChannelRhodopsin Activity')
% plot(RandNeuronPlot)
% 
% figure
% title('With ChannelRhodopsin Activity')
% plot(RandNeuronPlotWCHR2)

%% Figure #3 Network Analysis 
%InhibitionGraphLine = InhibitionGraph(all(~isnan(InhibitionGraph),2),:); %Removes NaN for line of Best fit

figure
title('Exc. Messenger Time over Multiplicative factor')
hold on
for n = 1:num_columns
    ErrorArrayFinal = (zeros(length(CHR2Array),2));
    for i = 1:length(CHR2Array)
        ErrorArrayFinal(:,1) = CHR2Array;
        vec = squeeze(MultiTrialArray(i,n,:,:));
        n_vals = numel(vec);
        n_nans = sum(isnan(vec));        
        n_valid = n_vals - n_nans;
        if n_valid > 1
            metric = std(vec,'omitnan') / sqrt(n_valid);
        else
            metric = NaN;
        end
        ErrorArrayFinal(i,2) = metric;
        MeanArray = zeros(Weightlength,TrialsPerValue);
        for wc = 1:Weightlength
        MeanArray(wc,:) = MultiTrialArray(i,n,wc,:);
        end
        PlotMean = mean(MeanArray,'all','omitnan');
        InhibitionGraph(i,2,n) = PlotMean; %This is anarchy rn I know working on it
    end

    X = -InhibitionGraph(:,1,1);
    Y = InhibitionGraph(:,2,n);
    Z = ErrorArrayFinal(:,2);
    errorbar(X, Y, Z);
end
ylabel('Sequence End Time')
xlabel('level of activation (Inhibitory -> Disinhibitory)')
hold on
grid on;



%% Figure 3 Rejected Values distribution

[TrialsRejectedPos, TrialsRejectedNeg] = deal(zeros(1,length(CHR2Array)));

for k = 1:(length(CHR2Array))
    TrialsRejectedPos(1,k) = ((TrialRemovalArrayPos(k))/(TrialsPerValue*(Weightlength)));
    TrialsRejectedNeg(1,k) = (TrialRemovalArrayNeg(k)/(TrialsPerValue*(Weightlength)));
end
figure
hold on
bar(-CHR2Array,TrialsRejectedPos(1:k),'m')
bar(-CHR2Array,TrialsRejectedNeg(1:k),'green')
legend('Epileptic Activity','No Activity')

%% Figure #4 Long Vs. Short training Time
ViolinArray = nan((Weightlength*TrialsPerValue),length(CHR2Array));
coordinatingarray = 0:1:length(CHR2Array);
ViolinPlot = nan(1000,length(coordinatingarray));
for i = 1:length(CHR2Array)
    Viola = MultiTrialArray(i,1,:,:);
    Viola = reshape(Viola,[],1);
    ViolinArray(:,i) = Viola;
end
ViolinArray = rot90(ViolinArray);
ViolinGraph = rot90(ViolinArray);
for n = 0:1:length(CHR2Array)
    chunkedcol = nan(100,1);
    if n == 580
    else
    % for i = 1:20
    %     chunk = n+i;
         chunkedcol(:,i) = ViolinGraph(:,(chunk));
    % end
    ncol = reshape(chunkedcol,[],1);
    colcoord = find(coordinatingarray==n);
    ViolinPlot(1:length(ncol),colcoord) = ncol;
    end
end

figure
hold 'on'
for i = 1:1:(length(coordinatingarray))
    c = i;
    if 900 >= sum(isnan(ViolinPlot(:,c)))
        vps(i) = ViolinClass(ViolinPlot(:,c),i,'Bandwidth',0.02,'ShowData',false);
    end
end