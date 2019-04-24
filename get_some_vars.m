function V = get_some_vars(vars)
V.str = {'prob1', 'offer1', 'ev1', 'prob2', 'offer2', 'ev2',...
    'first side','choice side','choice order','reward experienced',...
    'chosen_prob','chosen_offer','chosen_ev',...
    'probL','offerL','evL','probR','offerR','evR'};
V.vars = NaN(size(vars,1),length(V.str));
V.vars(:,1:10) = vars(:,1:10);
% chosen_prob
V.vars(vars(:,9)==1,11) = vars(vars(:,9)==1,1);
V.vars(vars(:,9)==2,11) = vars(vars(:,9)==2,4);
% chosen_offer
V.vars(vars(:,9)==1,12) = vars(vars(:,9)==1,2);
V.vars(vars(:,9)==2,12) = vars(vars(:,9)==2,5);
% chosen_ev
V.vars(:,13) = V.vars(:,12).*V.vars(:,11);
% probL
V.vars(vars(:,7)==1,14) = vars(vars(:,7)==1,1);
V.vars(vars(:,7)~=1,14) = vars(vars(:,7)~=1,4);
% offerL
V.vars(vars(:,7)==1,15) = vars(vars(:,7)==1,2);
V.vars(vars(:,7)~=1,15) = vars(vars(:,7)~=1,5);
% evL
V.vars(vars(:,7)==1,16) = vars(vars(:,7)==1,3);
V.vars(vars(:,7)~=1,16) = vars(vars(:,7)~=1,6);
% probR
V.vars(vars(:,7)==1,17) = vars(vars(:,7)==1,4);
V.vars(vars(:,7)~=1,17) = vars(vars(:,7)~=1,1);
% offerR
V.vars(vars(:,7)==1,18) = vars(vars(:,7)==1,5);
V.vars(vars(:,7)~=1,18) = vars(vars(:,7)~=1,2);
% evR
V.vars(vars(:,7)==1,19) = vars(vars(:,7)==1,6);
V.vars(vars(:,7)~=1,19) = vars(vars(:,7)~=1,3);
end