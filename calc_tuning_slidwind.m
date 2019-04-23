% Jiaxin Cindy Tu 20190423
% Strait et al. 2015 Fig 3B sliding window
function [significance,selectivity]=calc_tuning_slidwind(data)
if ~exist('spikeBinMs','var')
    spikeBinMs = 10;
end

sigma = 20*spikeBinMs; % ms gaussian smoothing kernel
wind = -15:15; % 310 ms window
plot_t = 16:5:385;
x = [-100:299];

event_ts = [0,100,200]*spikeBinMs;
event_str = {'Stim 1', 'Stim 2','Fixation'};

legend_str = {'rew1','rew2','prob1','prob2','choice side','choice order','ev1','ev2','sv1','sv2','reward'};
idx = 9:10; % select two from legend


use_raw = true;
if ~use_raw
    rate = pm(1).rates;
else
    spikes = permute(data(1).spikes,[2,3,1]);%     spikes = pm(iDay).rawCounts;
    % smooth and downsample
    rate = smoothdata(spikes,2,'gaussian',sigma*2);
    rate = rate(:,1:spikeBinMs:end,:);
end

n_neuron = size(rate,1);
selectivity = NaN(n_neuron,11,length(plot_t));
significance = NaN(n_neuron,11,length(plot_t));

counter = 0;
for iDay = 1:length(data)
    if ~use_raw
        rate = pm(iDay).rates;
    else
        spikes = permute(data(iDay).spikes,[2,3,1]);%         spikes = pm(iDay).rawCounts;
        % smooth and downsample
        rate = smoothdata(spikes,2,'gaussian',sigma*2);
        rate = rate(:,1:spikeBinMs:end,:);
    end
    vars = data(iDay).vars;
    [sv_2,sv_3] = subjective_value_calc(vars);
    n_neuron = size(rate,1);
    for iN = 1:n_neuron
        iN
        counter = counter+1;
        
        % temporal profile of selectivity
        rew1 = vars(:,2);
        rew2 = vars(:,5);
        prob1 = vars(:,1);
        prob2 = vars(:,4);
        choice_side = vars(:,8);
        choice_order = vars(:,9);
        ev1 = vars(:,3);
        ev2 = vars(:,6);
        srew1 = rew1;
        srew1(rew1==2) = rew1(rew1==2)*sv_2;
        srew1(rew1==3) = rew1(rew1==3)*sv_3;
        srew2 = rew2;
        srew2(rew2==2) = rew2(rew2==2)*sv_2;
        srew2(rew2==3) = rew2(rew2==3)*sv_3;
        sv1 = srew1.*prob1;
        sv2 = srew2.*prob2;
        reward = vars(:,10);
        
        psth = squeeze(rate(iN,:,:))';
        
        cond = vars(:,2)>1 & vars(:,5)>1 ; % exclude safe options
        beta = NaN(11,length(plot_t)); % 1st dim: ev1,ev2
        p = NaN(11,length(plot_t));
        count = 0;
        for tt = plot_t% trial start -1s to +4s
            count = count+1;
            FR = zscore(sum(psth(:,wind+tt),2)/length(wind+tt)*(1000/spikeBinMs));
            [B,~,stats] = glmfit(rew1(cond),FR(cond));
            beta(1,count) = B(2); p(1,count) = stats.p(2);
            [B,~,stats] = glmfit(rew2(cond),FR(cond));
            beta(2,count) = B(2);p(2,count) = stats.p(2);
            [B,~,stats] = glmfit(prob1(cond),FR(cond));
            beta(3,count) = B(2);p(3,count) = stats.p(2);
            [B,~,stats] = glmfit(prob2(cond),FR(cond));
            beta(4,count) = B(2);p(4,count) = stats.p(2);
            [B,~,stats] = glmfit(choice_side(cond),FR(cond));
            beta(5,count) = B(2);p(5,count) = stats.p(2);
            [B,~,stats] = glmfit(choice_order(cond),FR(cond));
            beta(6,count) = B(2);p(6,count) = stats.p(2);
            [B,~,stats] = glmfit(ev1(cond),FR(cond));
            beta(7,count) = B(2);p(7,count) = stats.p(2);
            [B,~,stats] = glmfit(ev2(cond),FR(cond));
            beta(8,count) = B(2);p(8,count) = stats.p(2);
            [B,~,stats] = glmfit(sv1(cond),FR(cond));
            beta(9,count) = B(2);p(9,count) = stats.p(2);
            [B,~,stats] = glmfit(sv2(cond),FR(cond));
            beta(10,count) = B(2);p(10,count) = stats.p(2);
            [B,~,stats] = glmfit(reward(cond),FR(cond));
            beta(11,count) = B(2);p(11,count) = stats.p(2);
        end
        selectivity(counter,:,:) = beta;
        significance(counter,:,:) = p;
    end
    close all
end

% %% Plot individual selectivity
% legend_str = {'rew1','rew2','prob1','prob2','choice side','choice order','ev1','ev2'};
%
% tts = size(psth,2);
% figure;hold on
% iN = 1;  % example neuron
% plot(x(plot_t)*spikeBinMs,squeeze(selectivity(iN,1,:)),'b-');
% plot(x(plot_t)*spikeBinMs,squeeze(selectivity(iN,2,:)),'r-');
% arrayfun(@vline,event_ts);
% text(event_ts,repelem(max(ylim),1,3),event_str);
% ylabel('beta');
% legend(legend_str(1:2));
% xlabel('ms');
% title(sprintf('neuron = %d',iN));

%% Plot Percentage modulated
figure;hold on
plot(x(plot_t)*spikeBinMs,squeeze(nanmean(significance(:,idx,:)<0.05))'*100,'-');
arrayfun(@vline,event_ts);
text(event_ts,repelem(max(ylim),1,3),event_str);
tmp = arrayfun(@(i)myBinomTest(i,n_neuron,0.05),4:10);
hline(find(tmp<0.05,1)+3,'Color','r'); % binomial test corrected chance level
ylabel('% neurons modulated');
xlabel('ms');
legend(legend_str(idx));
title('Selectivity');

%% Plot total selectivity
whichvar = 3;
tmp = abs(selectivity);
tmp(significance>0.05) = NaN;
tmp = squeeze(tmp(:,whichvar,:));
[~,maxi] = max(tmp,[],2);
[~,sorti] = sort(maxi);
figure;hold on
imagesc([x(1),x(end)],[min(sorti),max(sorti)],tmp(sorti,:));
ylim([1,size(significance,1)])
xlim([x(1),x(end)]);
arrayfun(@vline,event_ts/spikeBinMs);
c = colorbar;set(get(c,'title'),'string','Selectivity');
xticks(event_ts/spikeBinMs);
xticklabels(event_str);
title(legend_str(whichvar));
ylabel('sorted neurons');
end