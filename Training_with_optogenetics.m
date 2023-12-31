% Training routine modified from Cone and Shouval
% (http://modeldb.yale.edu/266774) to include optogenetics modulation of
% inhibitory cell populations
%
% Creates and train a network of x neurons and y columns to a sequence of
% y elements. Model parameters are defined in ModelParameters.m . Generates
% RecentTrial.mat to hold trained network weights

%% Parameter initialization

addpath('HelperFunctions')

% network structure parameters
num_columns = 1;
npp = 100;
ppc = 2*npp;
N = ppc*num_columns;
pop = num_columns*2;
n = N;
unit_num = 1:2:(2*num_columns);
num_trials = 100;

norm_noise = 10;

% time parameters
dt = 1; %time step
T = 50/dt; %time stimulated
delta = 600/dt; %time in between stimulation
t_total = 1501; %time of trial
D = 10/dt; %intrinsic delay
tau_w = 40; %estimate time window

% t_stim set the training times
t_stim = [1 1001]; % single column network training to 1 second
%[1 501 1001 1501 2001]; 4 columns training to 500 ms each column

% g_opsin sets the strength and valence of optogenetic currents, see paper for values
g_opsin = 0;

run('ModelParameters.m') %most parameters are stored in this file

[all_stim,one_stim,plot_R_it] = deal(zeros(pop,t_total/dt,num_trials+1));
sc_R_it = zeros(N,t_total/dt,num_trials+1);
ff_vect = zeros(1,num_trials+1);
rec_vect = zeros(1,num_trials+1);
W_ji_change = zeros(ppc,ppc,num_trials+1);

%% main program
for l = 1:num_trials+1
    % initialization
    [v_yt,v_it,v_kt] = deal(zeros(N,t_total/dt)+v_rest); %membrane potentials
    [R_yt,R_it,R_kt,sc_R] = deal(zeros(N,t_total/dt)); %rates (sc_R is spikes)
    [s_yt,s_it,s_kt] = deal(zeros(N,t_total/dt)); %activations
    [g_Ey,g_Ei,g_Ii,g_Ek] = deal(zeros(N,t_total/dt)); %conductances
    [t_ref_y,t_ref_i,t_ref_k] = deal(zeros(N,t_total/dt)); %refractory periods
    [T_ijp,T_ijd,del_W_ji] = deal(zeros(N,N)); %synapse specific traces, weight update
    [T_pt,T_dt] = deal(zeros(1,t_total/dt + dt)); %mean trace for population at time t

    all_stim1 = t_mik1(n,dt,T,t_total,p_r,npp,unit_stim,t_stim); %neuron by neuron stimulation, all pops stimulated
    one_stim1 = t_mik1(n,dt,T,t_total,p_r,npp,1,t_stim); %neuron by neuron stimulation, first pop stimulated
    for i = 1:pop
        temp = (i-1)*10;
        all_stim(i,:,l) = mean(all_stim1(temp+1:temp+10,:),1); %population stimulation, all pops stimulated
        one_stim(i,:,l) = mean(one_stim1(temp+1:temp+10,:),1); %population stimulation, first pops stimulated
    end
    if l == num_trials+1 || l == 1 %if first or last trial, only first pop stimulated. else all are stimulated in sequence
        t_miy = one_stim1;
    else
        t_miy = all_stim1;
    end

    % time step loop
    for t = 2:((t_total)/dt) %at each time step
        % pre-synaptic loop
        for i = 1:N %over each pre-synaptic neuron
            % input layer dynamics
            if t_ref_y(i,t) == 1 %refractory period
                v_yt(i,t) = v_rest; %set voltage of neuron i to ressting potential if in refractory period
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

            % excitatory dynamics
            if t_ref_i(i,t) == 1 %refractory period
                v_it(i,t) = v_rest; %set voltage of neuron i to ressting potential if in refractory period
            elseif (v_it(i,t-1) < v_th) %subthreshold update
                del_v_i = ((randn/norm_noise)+g_L*(E_l-v_it(i,t-1)) + (g_Ei(i,t-1) + g_Ey(i,t-1))*(E_e - v_it(i,t-1)) + g_Ii(i,t-1)*(E_i - v_it(i,t-1)))*(dt/C_m);
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

            % inhibitory dynamics
            if t_ref_k(i,t) == 1 %refractory period
                v_kt(i,t) = v_rest; %set voltage of neuron i to ressting potential if in refractory period
            elseif (v_kt(i,t-1) < v_th_i) %subthreshold update
                del_v_k = ((randn/norm_noise)+ g_L*(E_l-v_kt(i,t-1)) + (g_opsin*((N_eff*abs(randn))/(norm_noise))) +(g_Ek(i,t-1) + (iG/eG)*g_Ey(i,t-1))*(E_e - v_kt(i,t-1)))*(dt/C_m);
                v_kt(i,t) = v_kt(i,t-1) + del_v_k; %update membrane potential
            elseif (v_kt(i,t-1) >= v_th_i)
                v_kt(i,t) = v_hold; %voltage resets, neuron enter refractory phase
            end
            if v_kt(i,t) == v_hold %if neuron spikes
                del_R_kt = (1/dt-R_kt(i,t-1))*(dt/tau_w);
                R_kt(i,t) = R_kt(i,t-1) + del_R_kt; %update firing rate
                del_s_k = -(s_kt(i,t-1)*dt/tau_si) + rho*(1-s_kt(i,t-1));
                s_kt(i,t) = s_kt(i,t-1) + del_s_k;
                t_ref_k(i,t:t+t_refractory) = 1;
            else %if neuron does not spike
                del_R_kt = -R_kt(i,t-1)*(dt/tau_w);
                R_kt(i,t) = R_kt(i,t-1) + del_R_kt;
                del_s_k = -s_kt(i,t-1)*(dt/tau_si);
                s_kt(i,t) = s_kt(i,t-1) + del_s_k;
            end

            % post-synaptic loop
            for j = 1:N
                if (rec_identity(i,j) ~= 0 || ff_identity(i,j) ~= 0) && (t > D) && (l < num_trials + 1) && (t< t_total/dt) %only looks for traces at synapses with allowed connections and times
                    % Hebbian and Trace dynamics
                    if trace_refractory(i,j) == 0
                        if rec_identity(i,j) ~= 0 %selects recurrent synapses
                            if R_it(i,t-D) > .01 && R_it(j,t-1) > .01
                                H_d = eta_d*R_it(i,t-D)*R_it(j,t-dt); %Hebbian learning term for depression
                                H_p = eta_p*R_it(i,t-D)*R_it(j,t-dt); %Hebbian learning term for potentiation
                            else
                                H_d = 0; %Hebbian learning term for depression
                                H_p = 0; %Hebbian learning term for potentiation
                            end
                            del_T_ijp = (-T_ijp(i,j) + H_p*(T_max_p - T_ijp(i,j)))*(dt/tau_p); %change in LTP eligibility trace
                            del_T_ijd = (-T_ijd(i,j) + H_d*(T_max_d - T_ijd(i,j)))*(dt/tau_d); %change in LTD eligibility trace
                            T_ijp(i,j) = T_ijp(i,j) + del_T_ijp; %update LTP eligibility trace
                            T_ijd(i,j) = T_ijd(i,j) + del_T_ijd; %update LTD eligibility trace
                        elseif ff_identity(i,j) ~= 0 %selects ff synapses
                            if R_it(i,t-D) > .03 && R_it(j,t-1) > .03
                                H_d = eta_d1*R_it(i,t-D)*R_it(j,t-dt); %Hebbian learning term for depression
                                H_p = eta_p1*R_it(i,t-D)*R_it(j,t-dt); %Hebbian learning term for potentiation
                            else
                                H_d = 0; %Hebbian learning term for depression
                                H_p = 0; %Hebbian learning term for potentiation
                            end
                            del_T_ijp = (-T_ijp(i,j) + H_p*(T_max_p1 - T_ijp(i,j)))*(dt/tau_p1); %change in LTP eligibility trace
                            del_T_ijd = (-T_ijd(i,j) + H_d*(T_max_d1 - T_ijd(i,j)))*(dt/tau_d1); %change in LTD eligibility trace
                            T_ijp(i,j) = T_ijp(i,j) + del_T_ijp; %update LTP eligibility trace
                            T_ijd(i,j) = T_ijd(i,j) + del_T_ijd; %update LTD eligibility trace
                        end
                    else
                        T_ijp(i,j) = 0;
                        T_ijd(i,j) = 0;
                        trace_refractory(i,j) = trace_refractory(i,j) - 1/dt; %#ok<SAGROW> 
                    end

                    % Learning dynamics at time of reward
                    if rew_vect(t) == 1 %during reward window
                        if l>1 && rec_identity(i,j) ~= 0 %selects recurrent synapses
                            del_W_ji(i,j) = del_W_ji(i,j) + eta_rec*(T_ijp(i,j)-T_ijd(i,j))*(2*dt/delay_time); %change in recurrent weights
                        elseif l>1 && ff_identity(i,j)~= 0 %selects ff synapses
                            del_W_ji(i,j) = del_W_ji(i,j) + eta_ff*(T_ijp(i,j)-T_ijd(i,j))*(2*dt/delay_time); %change in ff weights
                        else
                            del_W_ji(i,j) = del_W_ji(i,j) + 0;
                        end
                    elseif rew_vect(t) == 2 %at time of reward (end of reward window)
                        trace_refractory(i,j) = 25/dt; %#ok<SAGROW> 
                    end

                end
            end
        end
        % updating conductances
        g_Ey(:,t) = W_in(:,:)*s_yt(:,t); %input conductance
        g_Ei(:,t) = W_ji(:,:)*s_it(:,t); %recurrent excitatory conductance
        g_Ii(:,t) = M_ki(:,:)*s_kt(:,t); %I to E conductance
        g_Ek(:,t) = P_ik(:,:)*s_it(:,t); %E to I conductance


    end

    % update weights/plotting
    W_ji = W_ji + del_W_ji;
    W_ji = W_ji.*(W_ji > 0).*(1-isnan(W_ji)); %cuts off weights <0
    W_ji_change(:,:,l) = W_ji;

    sc_R_it(:,:,l) = sc_R; %spiking for plotting
    for o = 1:pop
        temp = (o-1)*100;
        plot_R_it(o,:,l) = mean(R_it(temp+1:temp+100,:),1); % population average firing rates for plotting
    end
    %rescaling firing rates
    R_it = R_it*1000;
    R_kt = R_kt*1000;
    R_yt = R_yt*1000;

end

save('RecentTrial','-v7.3') % this file will be used by Testing_with_optogenetics.m

%% Plotting histograms

% Zero weights and feed-forward bias the histogram, remove to clarify 
% presentation of trained recurrent weights
W_ji_change(W_ji_change==0) = NaN;
W_ji_change(W_ji_change==0.0002) = NaN; 

figure
histogram(W_ji_change, 'Normalization' ,'pdf');
