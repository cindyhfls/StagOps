% wrap stagopts
% this code wraps psth in tensor format and ignoring cell online time
% (designed for array)
% fullpath = '/Volumes/jiaxin/jeeves-raid2/benh-data/StagOps/32/Batman/Mat files';
% saveName = 'B_32_choice_stagops.mat';
function main_wrap_population_stagops()
% N.B. if using server, remember to connect first
load_path = '/Users/jiaxintu/Documents/Data/StagOpts_wrapper/neuralData/';
beh_path = '/Users/jiaxintu/Documents/Data/StagOpts_wrapper/';

region = 'PMd';
date_id = '1201';
monkey_id = 'H';
files = dir(fullfile(load_path,sprintf('*%s*%s*mat',date_id,region)));

cd(beh_path);
load(['2017',date_id,'_beh_data.mat'])

% CHANGE ME
startoffset = 2;
endoffset = 2;
binwidth = 0.001; % s
env_strobe = 6008; % see the end for strobe meanings
align_by = env_strobe; %'start'; %'start'%'choice' % change to env_strobe
isArray = 1;
save_path = sprintf('/Users/jiaxintu/Documents/Data/StagOpts_Caleb/lfads/tensor/choiceopt_aligned_%db%da',startoffset,endoffset);
% CHANGE ME

if ~exist(save_path,'dir')
    mkdir(save_path)
end
saveName = sprintf('tensor_%s_%s_%s_stagops_%dms.mat',region,monkey_id,date_id,binwidth*1000);

if exist(fullfile(save_path,saveName),'file')
   tmp = input('Overwrite file? Y/N','s'); 
   if ~(strcmp(tmp,'Y')||strcmp(tmp,'y'))
       return
   else
       disp('File overwritten');
   end
end

if isArray
    % for Vprobe data load strobe in separate file
    strobefile = dir(fullfile(load_path,sprintf('*%s*strobe*mat',date_id)));
    load(fullfile(strobefile.folder,strobefile.name));
end

data = cell(1,length(files));
count = 1;
for iF = 1:length(files)
    load(fullfile(files(iF).folder,files(iF).name))
    clear('*wf*')
    % choice = 8001 or 8002 depends on left or right is chosen
    Events = Strobed(:,2);
    ts = Strobed(:,1);
    if isArray
        signal = who('*sig*');
    else
        signal = who('*SPK*');
    end
    n_cells = length(signal);
    start_t = ts(Events==6002);
    interval = find(Events<2000,1): find(Events==6013,1,'last'); % fine tuned for events
    trial_id = Events(interval);
    trial_id = trial_id(trial_id<2000);
    trial_id = unique(trial_id);
    ts_int = ts(interval);
    end_t = ts_int(Events(interval)==6013);
    choice_t = ts_int(Events(interval)==6009);
    start_t = ts_int(Events(interval)==6002);
    event_t = ts_int(Events(interval)== env_strobe);
        assert(all(find(Events(interval)== 6009)-find(Events(interval)== 6008)==1));
    RT = ts_int(Events(interval)== 6009)-ts_int(Events(interval)== 6008); % choice acquired and choice start (two options appear)
    Event_timing.offer2 = ts_int(Events(interval)== 6004)-ts_int(Events(interval)== 6002);
    Event_timing.choice_fixationdot = ts_int(Events(interval)== 6007)-ts_int(Events(interval)== 6002);
    Event_timing.choice_options = ts_int(Events(interval)== 6008)-ts_int(Events(interval)== 6002);
    Event_timing.choice_obtained = ts_int(Events(interval)== 6009)-ts_int(Events(interval)== 6002);
    Event_timing.reward_start = ts_int(Events(interval) == 6010)-ts_int(Events(interval) == 6002);
    for i = 1:n_cells
        curr_cell = eval(signal{i});       
        %% conditions to cut
        if strcmp(align_by,'choice')            
            % obtain psths from choice
            strobesforpsth = mat2cell(choice_t,ones(size(choice_t)),1);
            temp_psth = extractPSTHgeneric(curr_cell,strobesforpsth,startoffset,endoffset,binwidth);
            spikes(:,count,:) = temp_psth(1:end,:);      
            count = count+1;
        elseif strcmp(align_by,'start') 
            strobesforpsth = mat2cell(start_t,ones(size(start_t)),1);
            temp_psth = extractPSTHgeneric(curr_cell,strobesforpsth,startoffset,endoffset,binwidth);
            spikes(:,count,:) = temp_psth(1:end,:);           
            count = count+1;
        else
            strobesforpsth = mat2cell(event_t,ones(size(event_t)),1);
            temp_psth = extractPSTHgeneric(curr_cell,strobesforpsth,startoffset,endoffset,binwidth);
            spikes(:,count,:) = temp_psth(1:end,:);
            count = count+1;
        end
    end
    clear('*sig*');clear('*SPK*');
end
dataset.spikes = spikes;
dataset.vars = wrap_vars(res_data(trial_id));
dataset.RT = RT;
dataset.datetime = datetime('now');
dataset.subject = sprintf('%s_%s_%s_stagops_%dms',region,monkey_id,date_id,binwidth*1000);
dataset.conditionId = dataset.vars(:,8); % choice side
dataset.Event_timing = Event_timing;
T = size(spikes,3);
dataset.timeMs = (0:T-1)';
dataset.trial_id = trial_id;
cd (save_path)

fprintf('Saving %s\n', saveName);
save(fullfile(save_path,saveName),'-struct', 'dataset');
%save(fullfile(save_path,saveName),'spikes','vars','subject','datetime','files');   

end


%%%%%%%%%%%%%%
%%% functions
%%%%%%%%%%%%%%
%% % get vars from saved mat, for SB Yoo's code
function vars = wrap_vars(res_data)
vars = NaN(length(res_data),11);
for iT = 1:length(res_data)
    vars(iT,1) = res_data{iT}.opt1_prob;
    vars(iT,2) = res_data{iT}.opt1_val+1;
    vars(iT,4) = res_data{iT}.opt2_prob;
    vars(iT,5) = res_data{iT}.opt2_val+1;
    vars(iT,7) = strcmp(res_data{iT}.opt1_side,'left');
    vars(iT,8) = double(~res_data{iT}.choice_res);
    % I think Michael used choice = 1 for right and 0 for left, but let's
    % just correct it to the same as Caleb
    if strcmp(res_data{iT}.opt1_side,'left') == vars(iT,8)
        vars(iT,9) = 1;
    else
        vars(iT,9) = 2;
    end
    vars(iT,10) = res_data{iT}.outcome; % unlike Caleb, Michael's outcome is the reward amount
    if res_data{iT}.outcome == 0
        switch vars(iT,9)
            case 1
                tmp = vars(iT,2)==1;
            case 2
                tmp = vars(iT,4)==1;
        end
        if tmp
            vars(iT,10) = 1; % safe reward (Michael happen to code the safe reward and lose gamble as the same outcome)
        end
    else
        vars(iT,10) = res_data{iT}.outcome+1;
    end
    vars(iT,11) = 1; % valid trial
end
vars(:,3) = vars(:,1).*vars(:,2);
vars(:,6) = vars(:,4).*vars(:,5);
end

%% directly getting vars from strobe if using Caleb Strait's code
function vars = extractVarsStagops(Events) 
%% wrap to :
% 1.  [1st option] probability to win
% 2.  [1st option] reward size
% 3.  [1st option] expected value
% 4.  [2nd option] probability to win
% 5.  [2nd option] reward size
% 6.  [2nd option] expected value
% 7.  Side of first (1 = L; 0 = R)
% 8.  Choice (Left or Right)
% 9.  Choice (1st or 2nd)
% 10. Experienced reward
% 11. Valid trial (1 = use for analyses; 2 = invalid trial)
%% strobe meaning
% prob
Lprob = (Events(Events>=3000 &Events<=3100)-3000)/100;
Rprob=(Events(Events>=3300 &Events<=3400)-3300)/100;
% notBlueOps Color of rectangles 0:Blue 1:Green 2:Safe % blue is large,
% green is huge
notBlueOps = Events(Events>=13000 & Events<=13500)-13000;
notBlueOps1 = floor(notBlueOps/100);
notBlueOps1(notBlueOps1>=3)=notBlueOps1(notBlueOps1>=3)-3;
notBlueOps2 = floor(mod(notBlueOps,100)/10);
notBlueOps2(notBlueOps2>=3)=notBlueOps2(notBlueOps2>=3)-3;
% notBlueOps2 = floor(mod(notBlueOps,100)/10);

% reward
Lrew = ones(size(Lprob));
Lrew(notBlueOps1==0) = 2;
Lrew(notBlueOps1==1) = 3;
Rrew = ones(size(Lprob));
Rrew(notBlueOps2==0) = 2;
Rrew(notBlueOps2==1) = 3;

%order
order = Events(Events>=12000 &Events<=12300)-12000;
order = round(order,-1)/10;
Lfirst = floor(order/10)==1;

% choice
choice = Events(Events>=8000 & Events<=8003)-8000;
choiceisL = choice==1;

%gamble outcome
outcome = Events(Events>=10000 &Events<=10003)-10000;% Gamble outcome 0:Safe 1:Lose 2:Win
reward = zeros(size(Lprob));
reward(outcome==0)=1;
reward(outcome==2&choiceisL) = Lrew(choiceisL&outcome==2);
reward(outcome==2&~choiceisL) = Rrew(~choiceisL&outcome==2);

%% Get all in one mat
nT = length(Lprob);
vars = NaN(nT,11);
vars(Lfirst,1) = Lprob(Lfirst);
vars(~Lfirst,1) = Rprob(~Lfirst);
vars(Lfirst,2) = Lrew(Lfirst);
vars(~Lfirst,2) = Rrew(~Lfirst);
vars(:,3) = vars(:,1).*vars(:,2);
vars(Lfirst,4) = Rprob(Lfirst);
vars(~Lfirst,4) = Lprob(~Lfirst);
vars(Lfirst,5) = Rrew(Lfirst);
vars(~Lfirst,5) = Lrew(~Lfirst);
vars(:,6) = vars(:,4).*vars(:,5);
vars(:,7) = Lfirst;
vars(:,8) = choiceisL;
vars(:,9) = choiceisL==Lfirst;
vars(vars(:,9)==0,9) = 2;
vars(:,10) = reward;
vars(:,11) = ones(nT,1);
end

%%% strobe for joystick
% strobe_opt.session_start     = 6000;
% strobe_opt.obtained_fixation = 6006; % should be two fixation obtain in one trial.
% strobe_opt.offer1_start      = 6002;
% strobe_opt.offer1_end        = 6003;
% strobe_opt.offer2_start      = 6004;
% strobe_opt.offer2_end        = 6005;
% strobe_opt.choice_fix_start  = 6007;
% strobe_opt.choice_start      = 6008; % This indicate choice period starts.
% strobe_opt.choice_obtained   = 6009;
% strobe_opt.reward_start      = 6010;
% strobe_opt.reward_end        = 6011;
% strobe_opt.ITI_start         = 6012;
% strobe_opt.ITI_end           = 6013;
% strobe_opt.session_end       = 6789;
