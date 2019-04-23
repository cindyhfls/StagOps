% vars - A [T x 11] matrix where each row is one of T trials and each of 11 columns is a variable:
% 
% 1.  [1st option] probability to win
% 2.  [1st option] reward size
% 3.  [1st option] expected value
% 4.  [2nd option] probability to win
% 5.  [2nd option] reward size
% 6.  [2nd option] expected value
% 7.  Side of first (1 = L; 0 = R); % it's actually 1 for L and 2 for R...
% 8.  Choice (Left or Right)
% 9.  Choice (1st or 2nd)
% 10. Experienced reward
% 11. Valid trial (1 = use for analyses; 2 = invalid trial)

% Jiaxin Cindy Tu 20190423
% Reproducing Strait et al., 2015 Neuron Figure 2B
function choice_predictor(vars)
%%
choice = 2-vars(2:end,9); % 0 or 1
prob1 = vars(2:end,1);
rew1 = vars(2:end,2);
prob2 = vars(2:end,4);
rew2 = vars(2:end,5);
prevWL = vars(1:end-1,10)~=0; % receive a reward last trial
prevC = 2-vars(1:end-1,9);
order = vars(2:end,7)==1;
%%
[B,~,STATS] = glmfit([prob1,rew1,prob2,rew2,prevWL,prevC,order],choice,'binomial');
%%
labelstr = {'prob1','rew1','prob2','rew2','prev W/L','prev choice','order'};
figure;
b = bar(B(2:end));
b.FaceColor = 'flat';
b.CData(1:2,:) = [0,0,1;0,0,1];
b.CData(3:4,:) = [1,0,0;1,0,0];
b.CData(5:7,:) = [0,1,0;0,1,0;0,1,0];
starbarchart(STATS.p(2:end),b);
text(mean(xlim),min(ylim)+0.1*diff(ylim),sprintf('n=%d trials',length(vars)));
yl = ylim;
ylim(yl*1.5);
ylabel('beta');
xlabel('predictor');
title('Logistic regression on contribution to choices');
set(gca,'XTickLabels',labelstr);
xtickangle(45);
end
