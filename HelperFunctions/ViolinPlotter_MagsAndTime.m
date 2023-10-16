load('MessengerRateArray.mat')
load('MessengerTimeArray.mat')

ngOpsin = 26;
nTrials = 100;
opsinVals = linspace(-1,1.5,26);

SavedPeaks = zeros(nTrials,ngOpsin);
SavedTimes = zeros(size(SavedPeaks));
for ii = 1:ngOpsin
    for jj = 1:nTrials
        SavedPeaks(jj,ii) = max(MessengerTrialArray(ii,:,1,jj));
        SavedTimes(jj,ii) = MultiTrialArray(ii,1,1,jj);
    end
end
SavedPeaks = rot90(rot90(SavedPeaks));
SavedTimes = rot90(rot90(SavedTimes));

violinOpts = {'ShowData',false,'ShowBox',false,...
    'ShowWhiskers',false,'ShowMedian',false,...
    'ShowQuartiles',true,'ShowMean',false,...
    'ShowRange',false};

%%
fh1 = figure;
hold 'on'
for ii = 1:ngOpsin
    if ii <= 10
        color = [0 0.4470 0.7410]; 
    elseif ii == 11
        color = [0.7 0.7 0.7];
    else
        color = [0.9290 0.6940 0.1250];
    end
    vps_1(ii) = ViolinClass(SavedPeaks(:,ii),ii,violinOpts{:},...
        'Bandwidth',0.3,'ViolinColor',color); %#ok<SAGROW> 
end
xticks([1 6 11 16 21 26])
xticklabels([-1 -0.5 0 0.5 1 1.5])
xlim([0 27])
xlabel('g_{opsin} (AU)');
ylabel('Peak M Cell Firing Rate (Hz)')
print(fh1,'M_Cell_PeakRates_vs_gOpsin','-dpdf');

%%
fh2 = figure;
plot([0 27],[600 600],'k--');
hold 'on'
for ii = 1:ngOpsin
    if ii <= 10
        color = [0 0.4470 0.7410]; 
    elseif ii == 11
        color = [0.7 0.7 0.7];
    else
        color = [0.9290 0.6940 0.1250];
    end
    vps_2(ii) = ViolinClass(1000*SavedTimes(:,ii),ii,violinOpts{:},...
        'Bandwidth',21.1840,'ViolinColor',color); %#ok<SAGROW> 
end
xticks([1 6 11 16 21 26])
xticklabels([-1 -0.5 0 0.5 1 1.5])
xlim([0 27])
xlabel('g_{opsin} (AU)');
ylabel('M Cell Reported Time')
print(fh2,'M_Cell_ReportTimes_vs_gOpsin','-dpdf');
