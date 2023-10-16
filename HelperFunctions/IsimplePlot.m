 function IsimplePlot(num_columns,dt,cellsPerColumn,R_it,R_kt)

% usage for excitatory only simplePlot(num_columns,delta,200,R_it);

% cellsPerColumn = 200;

InhibitionExport = zeros(num_columns,1)

[nNeurons,tSteps] = size(R_it);
t = 1e-3*(0:tSteps-1)*dt; % units are wrong, should scale to max time or somethign

iNeuron = 1:nNeurons;

ValidityExport = zeros(3)

figure;
ah1 = subplot(1,1,1);
title('Excitatory Timer Cells');
%ah2 = subplot(2,1,2);
xlabel('t (s)')
hold(ah1,'on');
%hold(ah2,'on');

for col = 1:num_columns
    ind1 = (col-1)*cellsPerColumn + 1;
    ind2 = ind1 + cellsPerColumn/2;
    ind3 = ind2 + cellsPerColumn/2;
    iTimer = find(iNeuron >= ind1 & iNeuron < ind2);
    iMessenger = find(iNeuron >= ind2 & iNeuron < ind3);

    
    timers = R_it(iTimer,:); %#ok<*FNDSB>
    messengers = R_it(iMessenger,:);
    InhTimers = R_kt(iTimer,:);
    
    % Find the peak rates for the timers individually
    [maxTind,iM] = max(timers');
    tTind = t(iM); % times of peak for each cell
    tTindMu = mean(tTind);
    tTindSE = std(tTind)/sqrt(cellsPerColumn/2);
    % Find the peak for the population mean
    [maxTpop,iM] = max(mean(timers,1));
    tTpop = t(iM); % times of peak for each cell
    
     % Find the peak rates for the messengers individually
    [maxMind,iM] = max(messengers');
    tMind = t(iM); % times of peak for each cell
    tMindMu = mean(tMind);
    tMindSE = std(tMind)/sqrt(cellsPerColumn/2);
    % Find the peak for the population mean
    [maxMpop,iM] = max(mean(messengers,1));
    tMpop = t(iM); % times of peak for each cell
    % 
    ph = plot(ah1,t,mean(timers,1),'Linewidth',2);
    ph = plot(ah1,t,mean(InhTimers,1),'Linewidth',2);
    plot(ah1,tTpop*[1 1],[0 140],'LineStyle','--','Color',ph.Color,'Linewidth',2); % peak of population average
    plot(ah1,t,mean(messengers,1),'Linewidth',2);
    %IGNORE     plot(tMindMu*[1 1],[0 20],'LineStyle','--','Color',ph.Color,'Linewidth',1); % mean of individual peaks
    %IGNORE     plot((tMindMu+tMindSE)*[1 1],[0 20],'LineStyle',':','Color',ph.Color,'Linewidth',1); % mean of individual peaks
    %IGNORE     plot((tMindMu-tMindSE)*[1 1],[0 20],'LineStyle',':','Color',ph.Color,'Linewidth',2); % mean of individual peaks
    plot(ah1,tMpop*[1 1],[0 70],'LineStyle','--','Color',ph.Color,'Linewidth',2); % peak of population average    
    plot(ah1,tMpop*[1 1],[0 100],'LineStyle','--','Color',ph.Color,'Linewidth',2);
    InhibitionExport(col) = tMpop;

    % %Fill region of 1 std
     MeanMessengers = mean(messengers,1);
     MessengerSTD = std(mean(messengers,1));
     for i = 1:length(MeanMessengers)
     if MeanMessengers(i) >= MessengerSTD && MeanMessengers(i) >= 3
        FillRegion(i) = i;
        minFillRegion = min(FillRegion)*0.001;
        maxFillRegion = max(FillRegion)*0.001;
        DiffWidth = maxFillRegion-minFillRegion;
     else
        DiffWidth = NaN;
        FillRegion(i) = NaN;
     end
     end
     if isnan(DiffWidth) == 1
     patch(ah1,[minFillRegion minFillRegion maxFillRegion maxFillRegion],[0 200 200 0],'r','FaceAlpha',0.1,'EdgeColor','none');
     end
     ylim(ah1,[0 maxTpop+10])
     xlim(ah1,[0 max(t)])
     %plot(ah2,t,(mean(timers) - mean(InhTimers)))

end
    ValidityExport = maxMpop;
    assignin('base','InhibitionExport', InhibitionExport);
    assignin('base','ValidityExport', ValidityExport);
    assignin('base','messengers', messengers);
    assignin('base','messengerrate', maxMpop);
    assignin('base','MessengerWidth', DiffWidth);
    assignin('base','FillRegion',FillRegion);
    