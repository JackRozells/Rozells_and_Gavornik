load('Control.mat')
  W_ji(W_ji==0) = NaN;
  W_ji(W_ji==0.0002) = NaN;
  NoOpto_W_ij = W_ji;
  %W_ji_change(W_ji_change==0) = NaN;
  W_ji_change(W_ji_change==0.0002) = NaN;
  NoOpto_change = W_ji_change;
load('inhibition.mat')
  W_ji(W_ji==0) = NaN;
  W_ji(W_ji==0.0002) = NaN;
  Inh_W_ij = W_ji;
  %W_ji_change(W_ji_change==0) = NaN;
  W_ji_change(W_ji_change==0.0002) = NaN;
  Inh_change = W_ji_change;
load('Disinhibition.mat')
  W_ji(W_ji==0) = NaN;
  W_ji(W_ji==0.0002) = NaN;
  Dis_W_ij = W_ji;
  %W_ji_change(W_ji_change==0) = NaN;
  W_ji_change(W_ji_change==0.0002) = NaN;
  Dis_change = W_ji_change;

figure
hold on
    Opto = Dis_W_ij;
    control = NoOpto_W_ij;
    Inh = Inh_W_ij;
O = histogram(Opto(:), 'Normalization' ,'pdf');
A = histogram(control(:),'Normalization','pdf');
I = histogram(Inh(:),'Normalization','pdf');
legend

%%
figure
[f,x_values] = ecdf(Opto(:));
J = plot(x_values,f);
hold on;
[f,x_values] = ecdf(control(:));
K = plot(x_values,f,'r--');
[f,x_values] = ecdf(Inh(:));
L = plot(x_values,f,'yellow');
set(J,'LineWidth',2);
set(K,'LineWidth',2);
set(L,'LineWidth',2);
legend([J K L],'Chr2','Control','Nphr')