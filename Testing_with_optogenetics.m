% Testing routine modified from Cone and Shouval
% (http://modeldb.yale.edu/266774) to include optogenetics modulation of
% inhibitory cell populations. Assumes you've already run
% Training_with_optogenetics.m to generate RecentTrial.mat
%
% Parameter and Variable Key:
% yt = Input Layer
% it = Excitatory
% kt = Inhibitory
% v_x = Voltage of x neuron
% R_x = Firing rate of x column of  neurons
% del_ or dt = delta

% Load model parameters, trained network structure, and set model run-time parameters

addpath('HelperFunctions')
load('RecentTrial.mat')

TrialsPerValue = 5; % Number of trials per each level of inhibition

% To convert between Channel(+) and Halo(-) change (randn +/- 5) value in
% added channel to + for Chr2 or - for Halorhodopsin
g_opsinArray = 0; % can be multiple values, e.g. [0 0.1 ...]
%Levels of inhibition, Warning: if too high will cause epileptiform-like behavior of all elements
TotalTime = 1501;

StartOpto = 0; %input('Inhibitory neurons will go to zero at time step:')
EndOpto = 9000;
Weightlength = 1; % This parameters was used when testing multiple weight matrices

%Initializing a bunch of parameters for plotting. Preallocated for speed.
[InhibitionGraph,UnalteredInhibitionGraph] = deal(zeros(length(g_opsinArray),2,num_columns));
InhibitionGraph(:,1) = g_opsinArray;
RandNeuron = randi([1 200]);
[RandNeuronPlot] = deal(zeros(5001,length(g_opsinArray)));
[SingleNeuronRate,SingleNeuronRateCHR2] = deal(zeros(5001,1));
RandSelector = randi(length(g_opsinArray));
MultiTrialArray = zeros(length(g_opsinArray),num_columns,Weightlength,TrialsPerValue);
MessengerTrialArray = zeros(length(g_opsinArray),TotalTime,Weightlength,TrialsPerValue);
MessengerWidthTrialArray = zeros(length(g_opsinArray),1,Weightlength,TrialsPerValue);
[TrialRemovalArrayPos,TrialRemovalArrayNeg] = deal(zeros(length(g_opsinArray),1));
N_eff = 0.05; % this variable is the relative conductance compared to the max g_opsin as a percent of the max.

%% main program
for MT = 1:TrialsPerValue
    for CHR2Ind = 1:length(g_opsinArray)
        gla = 0.01;
        g_opsin = g_opsinArray(CHR2Ind);
        %% initialization
        % W_ji(51:1:100,51:1:100) = 0;
        %W_ji(1:1:100,1:1:100) = 0;
        % W_ji(51:1:100,1:1:100) = 0;
        t_total = TotalTime;
        [R_yt,R_it,R_kt,sc_R,sc_R_kt] = deal(zeros(N,t_total/dt)); %rates (sc_R is spikes)
        [s_yt,s_it,s_kt] = deal(zeros(N,t_total/dt)); %activations
        [g_Ey,g_Ei,g_Ii,g_Ek] = deal(zeros(N,t_total/dt)); %conductances
        [t_ref_y,t_ref_i,t_ref_k] = deal(zeros(N,t_total/dt)); %refractory periods
        [T_ijp,T_ijd,del_W_ji] = deal(zeros(N,N)); %synapse specific traces, weight update
        [T_pt,T_dt] = deal(zeros(1,t_total/dt + dt)); %mean trace for population at time t

        all_stim1 = t_mik1(n,dt,T,t_total,p_r,npp,unit_stim,t_stim); %neuron by neuron stimulation, all pops stimulated
        one_stim1 = t_mik1(n,dt,T,t_total,p_r,npp,1,t_stim); %neuron by neuron stimulation, first pop stimulated
        for i = 1:pop
            temp = (i-1)*10;
        end
        if l == num_trials+1 || l == 1 %if first or last trial, only first pop stimulated. else all are stimulated in sequence
            t_miy = one_stim1;
        else
            t_miy = all_stim1;
        end

        %% time step loop

        for t = 2:((t_total)/dt) %at each time step
            %% pre-synaptic loop
            for i = 1:N %over each pre-synaptic neuron
                %% input layer dynamics
                if t_ref_y(i,t) == 1 %refractory period
                    v_yt(i,t) = v_rest; %set voltage of neuron i to resting potential if in refractory period
                    t_miy(i,t) = 0; %no spike for neuron i at this time
                elseif (v_it(i,t-1) < v_th) && t_miy(i,t) == 0 %subthreshold update
                    del_v_y = (g_L*(E_l-v_yt(i,t-1)))*(dt/C_m); %change in the membrane potential at each time step
                    v_yt(i,t) = v_yt(i,t-1) + del_v_y; %update membrane potential
                elseif (v_yt(i,t-1) >= v_th) || t_miy(i,t) == 1
                    v_yt(i,t) = v_hold; %voltage resets, neuron enter refractory phase
                    t_miy(i,t) = 1; %spike for neuron i at time k
                end
                if v_yt(i,t) == v_hold %if neuron spikes
                    del_R_yt = (1/dt-R_yt(i,t-1))*(dt/tau_w);
                    R_yt(i,t) = R_yt(i,t-1) + del_R_yt; %update firing rate
                    del_s_y = -(s_yt(i,t-1)*dt/tau_si) + rho*(1-s_yt(i,t-1));
                    s_yt(i,t) = s_yt(i,t-1) + del_s_y;
                    t_ref_y(i,t:t+t_refractory) = 1;
                else %if neuron does not spike
                    del_R_yt = -R_yt(i,t-1)*(dt/(tau_w));
                    R_yt(i,t) = R_yt(i,t-1) + del_R_yt;
                    del_s_y = -s_yt(i,t-1)*(dt/tau_si);
                    s_yt(i,t) = s_yt(i,t-1) + del_s_y;
                end

                %% excitatory dynamics
                if t_ref_i(i,t) == 1 %refractory period
                    v_it(i,t) = v_rest; %set voltage of neuron i to resting potential if in refractory period
                elseif (v_it(i,t-1) < v_th) %subthreshold update
                    del_v_i = ((randn/norm_noise)+g_L*(E_l-v_it(i,t-1))+ (g_Ei(i,t-1) + g_Ey(i,t-1))*(E_e - v_it(i,t-1)) + g_Ii(i,t-1)*(E_i - v_it(i,t-1)))*(dt/C_m);
                    v_it(i,t) = v_it(i,t-1) + del_v_i; %update membrane potential
                elseif (v_it(i,t-1) >= v_th)
                    v_it(i,t) = v_hold; %voltage resets, neuron enter refractory phase
                end
                if v_it(i,t) == v_hold %if neuron spikes
                    sc_R(i,t) = 1;
                    del_R_it = (1/dt-R_it(i,t-1))*(dt/tau_w);
                    R_it(i,t) = R_it(i,t-1) + del_R_it; %update firing rate
                    del_s_j = -(s_it(i,t-1)*dt/tau_se) + rho*(1-s_it(i,t-1));
                    s_it(i,t) = s_it(i,t-1) + del_s_j;
                    t_ref_i(i,t:t+t_refractory) = 1;
                else %if neuron does not spike
                    del_R_it = -R_it(i,t-1)*(dt/tau_w);
                    R_it(i,t) = R_it(i,t-1) + del_R_it;
                    del_s_j = -s_it(i,t-1)*(dt/tau_se);
                    s_it(i,t) = s_it(i,t-1) + del_s_j;
                end

                %% inhibitory dynamics
                if t_ref_k(i,t) == 1 %refractory period
                    v_kt(i,t) = v_rest; %set voltage of neuron i to resting potential if in refractory period
                elseif (v_kt(i,t-1) < v_th_i) %subthreshold update
                    if t >= StartOpto && t <= EndOpto
                        del_v_k = ((rand/norm_noise)+ gla*(E_l-v_kt(i,t-1)) + ( (g_opsin*((abs(randn)*N_eff)/norm_noise)) +  g_Ek(i,t-1) + (iG/eG)*g_Ey(i,t-1))*(E_e - v_kt(i,t-1)))*(dt/C_m);
                    else
                        del_v_k = ((randn/norm_noise)+ gla*(E_l-v_kt(i,t-1)) + (g_Ek(i,t-1) + (iG/eG)*g_Ey(i,t-1))*(E_e - v_kt(i,t-1)))*(dt/C_m);
                    end
                    v_kt(i,t) = v_kt(i,t-1) + del_v_k; %update membrane potential
                elseif (v_kt(i,t-1) >= v_th_i)
                    v_kt(i,t) = v_hold; %voltage resets, neuron enter refractory phase
                end
                if v_kt(i,t) == v_hold %if neuron spikes
                    sc_R_kt(i,t) = 1;
                    del_R_kt = (1/dt-R_kt(i,t-1))*(dt/tau_w);
                    R_kt(i,t) = R_kt(i,t-1) + del_R_kt; %update firing rate
                    del_s_k = -(s_kt(i,t-1)*dt/tau_si) + rho*(1-s_kt(i,t-1));
                    s_kt(i,t) = s_kt(i,t-1) + del_s_k;
                    t_ref_k(i,t:t+t_refractory) = 1;
                    if i == RandNeuron && g_opsin == 0
                        SingleNeuronRate(t) = 1;
                    elseif i == RandNeuron && g_opsin == g_opsinArray(CHR2Ind)
                        SingleNeuronRateCHR2(t) = 1;
                    end
                else %if neuron does not spike
                    del_R_kt = -R_kt(i,t-1)*(dt/tau_w);
                    R_kt(i,t) = R_kt(i,t-1) + del_R_kt;
                    del_s_k = -s_kt(i,t-1)*(dt/tau_si);
                    s_kt(i,t) = s_kt(i,t-1) + del_s_k;
                end

                if i == RandNeuron && g_opsin == 0
                    RandNeuronPlot = v_kt;
                elseif i == RandNeuron && g_opsin == g_opsinArray(CHR2Ind)
                    RandNeuronPlotWCHR2 = v_kt;
                end

                if i == RandNeuron && g_opsin == 0
                    RandNeuronRate = SingleNeuronRate;
                elseif i == RandNeuron && g_opsin == g_opsinArray(CHR2Ind)
                    RandNeuronRateChr2 = SingleNeuronRateCHR2;
                end
            end
            %% updating conductances
            g_Ey(:,t) = W_in(:,:)*s_yt(:,t); %input conductance
            g_Ei(:,t) = W_ji(:,:)*s_it(:,t); %recurrent excitatory conductance
            g_Ii(:,t) = M_ki(:,:)*s_kt(:,t); %I to E conductance
            g_Ek(:,t) = P_ik(:,:)*s_it(:,t); %E to I conductance

        end

        %% update weights/plotting
        %rescaling firing rates
        R_it = R_it*1000;
        R_kt = R_kt*1000;
        R_yt = R_yt*1000;

        %plotting of Figure 1
        if l == 1
            old_R_it = plot_R_it(:,:,l);
            IsimplePlot(num_columns,dt,200,R_it,R_kt)
        elseif l == num_trials
            tit = sprintf('Final Learning Trial %d (Full Stim)',num_trials);
            IsimplePlot(num_columns,dt,200,R_it,R_kt)
        elseif l == num_trials+1
            new_R_it = plot_R_it(:,:,l);
            IsimplePlot(num_columns,dt,200,R_it,R_kt)
        end
        drawnow

        %% Sorting Mechanism 1 = Normal 0 = Epileptic, Repetitious or Otherwise Invalid. Removed until updated

        MeanMessengers = mean(messengers);
        SafetyDelta = max(MeanMessengers) - min(MeanMessengers); %Creates delta between lowest and highest messenger rate to prevent repetitious behavior

        if (SafetyDelta >= 5) && (ValidityExport <= 180) %if delta is more than 10 or more than 90% of cells in column are firing it is epileptic or repetitious
            InhibitionGraph(CHR2Ind,2,:) = InhibitionExport; %Pulls endtime from SimplePlot function
        else
            InhibitionGraph(CHR2Ind,2,:) = NaN;
            MessengerWidth = NaN;
            if CHR2Ind >= ((length(g_opsinArray))/2);
                TrialRemovalArrayNeg(CHR2Ind) = TrialRemovalArrayNeg(CHR2Ind) + 1;
            elseif CHR2Ind < ((length(g_opsinArray))/2);
                TrialRemovalArrayPos(CHR2Ind) = TrialRemovalArrayPos(CHR2Ind) + 1;
            end
        end

        %  Checks if the sequence is in order, comment out if not using a full
        %  sequence and only using a single element.
        % if InhibitionExport(1)>= InhibitionExport(2)
        %    InhibitionExport = NaN(num_columns,1)
        %    if CHR2Ind >= ((length(CHR2Array))/2);
        %        TrialRemovalArrayNeg(CHR2Ind) = TrialRemovalArrayNeg(CHR2Ind) + 1;
        %    elseif CHR2Ind < ((length(CHR2Array))/2);
        %        TrialRemovalArrayPos(CHR2Ind) = TrialRemovalArrayPos(CHR2Ind) + 1;
        %    end
        % elseif InhibitionExport(2)>= InhibitionExport(3)
        %    InhibitionExport = NaN(num_columns,1)
        %    if CHR2Ind >= ((length(CHR2Array))/2);
        %        TrialRemovalArrayNeg(CHR2Ind) = TrialRemovalArrayNeg(CHR2Ind) + 1;
        %    elseif CHR2Ind < ((length(CHR2Array))/2);
        %        TrialRemovalArrayPos(CHR2Ind) = TrialRemovalArrayPos(CHR2Ind) + 1;
        %    end
        % elseif InhibitionExport(3)>= InhibitionExport(4)
        %    InhibitionExport = NaN(num_columns,1)
        %    if CHR2Ind >= ((length(CHR2Array))/2);
        %        TrialRemovalArrayNeg(CHR2Ind) = TrialRemovalArrayNeg(CHR2Ind) + 1;
        %    elseif CHR2Ind < ((length(CHR2Array))/2);
        %        TrialRemovalArrayPos(CHR2Ind) = TrialRemovalArrayPos(CHR2Ind) + 1;
        %    end
        % end

        InhibitionGraph(CHR2Ind,2,:) = InhibitionExport; %Pulls endtime from SimplePlot function

        if g_opsin == 0
            NormalNetwork = sc_R;
            NormalNetworkInh = sc_R_kt;
        elseif g_opsin == g_opsinArray(RandSelector) && 1 == Weightlength
            CHR2Network = sc_R;
            CHR2NetworkInh = sc_R_kt;
        end

        MultiTrialArray(CHR2Ind,:,1,MT) = InhibitionExport;
        MessengerTrialArray(CHR2Ind,:,1,MT) = mean(messengers,1);
        MessengerWidthTrialArray(CHR2Ind,:,1,MT) = MessengerWidth;


    end
end

%% Trial Time Log 4d array
save('FinalValuesOfMostRecentTrial') %Saves the generated values from your most recent trial.