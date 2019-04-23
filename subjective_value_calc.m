% Jiaxin Cindy Tu 20190423
% figuring out subjective value based on how often the gamble is chosen compared to safe option

function [sv_2,sv_3] = subjective_value_calc(vars,varargin)
if nargin<2
    plot_on = true;
end
%% run simulation
nTrials = size(vars,1);
p_3 = NaN(10,50);
p_2 = NaN(10,50);
rng('default');
for j = 1:50
    ind = randsample(nTrials,10000,true); % sample trials with replacement
    sim_vars = vars(ind,:);
    for i = 1:10
        lowbound = -0.1+0.1*i;
        highbound = lowbound+0.1;
        a = sim_vars(:,2)==3 & sim_vars(:,5)==1 & (lowbound < sim_vars(:,1)) & (highbound >=sim_vars(:,1));
        b = a & sim_vars(:,9)==1;
        c = sim_vars(:,5)==3 & sim_vars(:,2)==1 & (lowbound <sim_vars(:,4)) & (highbound >=sim_vars(:,4));
        d = c & sim_vars(:,9)==2;
        
        p_3(i,j) = (sum(d|b))/(sum(a|c));
        
        a = sim_vars(:,2)==2 & sim_vars(:,5)==1 & (lowbound < sim_vars(:,1)) & (highbound >=sim_vars(:,1));
        b = a & sim_vars(:,9)==1;
        c = sim_vars(:,5)==2 & sim_vars(:,2)==1 & (lowbound <sim_vars(:,4)) & (highbound >=sim_vars(:,4));
        d = c & sim_vars(:,9)==2;
        
        p_2(i,j) = (sum(d|b))/(sum(a|c));
    end
end

%% Fit curve
x = [0.05:0.1:0.95]';
x = repelem(x,1,50);

log_curve = '1/(1+exp(-k*(x-x0)))'; 
% log_curve = 'log(L/x-1)/(-k)+x0';

startPoints = [5 0.2]; % initial guess

fit_x = nanmean(x,2);%x(:); %
fit_y = nanmean(p_2,2); %p_2(:);
w = ones(size(fit_y));w(fit_y==1|fit_y==0) = 0.1;
f1 = fit(fit_x,fit_y,log_curve,'Start', startPoints,'Exclude',isnan(fit_y),'Weights',w);

fit_x = nanmean(x,2);%x(:);
fit_y = nanmean(p_3,2);%p_3(:);
w = ones(size(fit_y));w(fit_y==1|fit_y==0) = 0.1;
f2 = fit(fit_x,fit_y,log_curve,'Start', startPoints,'Exclude',isnan(fit_y),'Weights',w);

sv_2 = 1/f1.x0;
sv_3 = 1/f2.x0;

if plot_on
    figure;hold on
    plot(x,p_2,'k.')
    % plot(x(std(p_2,[],2)~=0,:),p_2(std(p_2,[],2)~=0,:),'k.')
    plot(f1.x0,1./(1+exp(-f1.k*(0))),'ko')
    real_curve = 1./(1+exp(-f1.k*([0:0.05:1]-f1.x0)));
    h(1) = plot(0:0.05:1,real_curve,'k-');
    plot(x,p_3,'b.')
    % plot(x(std(p_3,[],2)~=0,:),p_3(std(p_3,[],2)~=0,:),'b.')
    plot(f2.x0,1./(1+exp(-f2.k*(0))),'bo')
    real_curve = 1./(1+exp(-f2.k*([0:0.05:1]-f2.x0)));
    h(2) = plot(0:0.05:1,real_curve,'b-');
    text(0.6,0.3,sprintf('subjective value 2 over safe = %2.2f',sv_2));
    text(0.6,0.27,sprintf('subjective value 3 over safe = %2.2f',sv_3));
    legend(h,'P(choosing 3 over safe)','P(choosing 2 over safe)','location','SE');
    xlabel('probability of gamble reward');
    ylabel('probability of chosing to gamble');
end
end