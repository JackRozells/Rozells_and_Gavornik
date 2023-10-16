%% Figure 5 Plots
% This plots multiple violins side by side of each of the following

%load('Times.mat')
for ii = 1:26
for i = 1:100
    SavedPeaks(i,ii) = (MessengerWidthTrialArray(ii,:,1,i));
end
end
SavedPeaks = rot90(SavedPeaks);
SavedPeaks = rot90(SavedPeaks);

figure
hold 'on'
for i = 1:1:26
    if 900 >= sum(isnan(SavedPeaks(:,i)))
        if i <= 10
        vps(i) = ViolinClass(SavedPeaks(:,i),i,'Bandwidth',0.3,'ShowData',false,'ViolinColor',[0 0.4470 0.7410]);
        elseif i == 11
            vps(i) = ViolinClass(SavedPeaks(:,i),i,'Bandwidth',0.3,'ShowData',false,'ViolinColor',[0.7 0.7 0.7]);
        else
        vps(i) = ViolinClass(SavedPeaks(:,i),i,'Bandwidth',0.3,'ShowData',false,'ViolinColor',[0.9290 0.6940 0.1250]);
        end
    end
end
xticks([1 6 11 16 21 26])
xticklabels([-1 -0.5 0 0.5 1 1.5])
xlim([0 27])

%%
%load('MessengerRateArray.mat')
%load('DisViolinData600ms.mat')
for ii = 1:3
for i = 1:100 %100
    if MultiTrialArray(ii,1,1,i) >= 1.5
        MultiTrialArray(ii,1,1,i) = NaN;
    end
    SavedPeaks(i,ii) = MultiTrialArray(ii,1,1,i);
end
end
SavedPeaks = rot90(SavedPeaks);
SavedPeaks = rot90(SavedPeaks);

figure
hold 'on'
for i = 1:1:3
    if 900 >= sum(isnan(SavedPeaks(:,i)))
        if i == 1
        vps(i) = ViolinClass(SavedPeaks(:,i),i,'Bandwidth',0.04,'ShowData',false,'ViolinColor',[0 0.4470 0.7410]);
        elseif i == 2
            vps(i) = ViolinClass(SavedPeaks(:,i),i,'Bandwidth',0.04,'ShowData',false,'ViolinColor',[0.7 0.7 0.7]);
        else
        vps(i) = ViolinClass(SavedPeaks(:,i),i,'Bandwidth',0.04,'ShowData',false,'ViolinColor',[0.9290 0.6940 0.1250]);
        end
    end
end
xticks([1 2 3])
xticklabels([-1 0 1.5])
xlim([0 4])