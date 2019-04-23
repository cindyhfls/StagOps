load_path = '/Volumes/jiaxin/jeeves-raid2/benh-data/StagOps/Striatum Pre-Cocaine/Batman/Mat files';
files = dir(fullfile(load_path,'*.mat'));

strobe_path = '/Volumes/jiaxin/jeeves-raid2/benh-data/StagOps/Striatum Pre-Cocaine/Batman/Mat files/Strobes';

region = 'VS';
monkey_id = 'B';

startoffset = 1;
endoffset = 3;
binwidth = 0.001; % s
env_strobe = 0;
align_by = 'start';%'choice';/env_strobe % see the end for strobe meanings

save_path = sprintf('/Users/jiaxintu/Documents/Data/StagOpts_Caleb/vs_tensor/start_aligned_%db%da',startoffset,endoffset);
if ~exist(save_path,'dir')
    mkdir(save_path)
end
if ~exist(strobe_path,'dir')
    mkdir(strobe_path)
end

% data = cell(1,length(files));
%%
for iF = 1:length(files)
    iF
    count = 1;
    date_id = files(iF).name(strfind(files(iF).name,monkey_id)+1:strfind(files(iF).name,'.plx')-1);
    saveName = sprintf('tensor_%s_%s_%s_stagops_%dms.mat',region,monkey_id,date_id,binwidth*1000);
    load(fullfile(files(iF).folder,files(iF).name))
    
    if exist(fullfile(strobe_path,[monkey_id,date_id,'_strobe.mat']),'file')
        load(fullfile(strobe_path,[monkey_id,date_id,'_strobe.mat']),'Strobed');
    else
        Strobed = getstrobes_plx(EVT01,EVT02,EVT03,EVT04,EVT05,EVT06); % don't call this every time because it is time consuming
        save(fullfile(strobe_path,[monkey_id,date_id,'_strobe.mat']),'Strobed');
    end
    
    Events = Strobed(:,2);
    ts = Strobed(:,1);
    signal = who('*SPK*');
    n_cells = length(signal);
    
    interval = find(Events==4001,1): find(Events==4009,1,'last')+9; % fine tuned for events
    ts_int = ts(interval);
    
    Events_int = Events(interval);
    
    event_t = ts_int(Events_int== env_strobe);
    start_t = ts_int(Events_int== 4001);
    choice_t = ts_int(find(Events_int== 4008)-1);
    RT = ts_int(find(Events_int== 4008)-1)-ts_int(Events_int== 4007); % choice acquired and choice start (two options appear)
    Event_timing.offer2 = ts_int(Events_int== 4003)-start_t;
    Event_timing.choice_fixationdot = ts_int(Events_int== 4006)-start_t;
    Event_timing.choice_options = ts_int(Events_int== 4007)-start_t;
    Event_timing.choice_obtained = ts_int(find(Events_int == 4008)-1)-start_t;
    Event_timing.feedback_start = ts_int(Events_int == 4008)-start_t;
    
    spikes = NaN(length(choice_t),n_cells,(startoffset+endoffset)/binwidth);
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
            % obtain psths from start
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
    clear('*SPK*','*EVT*');
    dataset.spikes = spikes;
    [dataset.vars,dataset.trial_id] = wrap_vars_Caleb(Events_int);
    dataset.RT = RT;
    dataset.datetime = datetime('now');
    dataset.subject = sprintf('%s_%s_%s_stagops_%dms',region,monkey_id,date_id,binwidth*1000);
    dataset.conditionId = dataset.vars(:,8); % choice side
    dataset.Event_timing = Event_timing;
    T = size(spikes,3);
    dataset.timeMs = (0:T-1)';
    fprintf('Saving %s\n', saveName);
    save(fullfile(save_path,saveName),'-struct', 'dataset');
end

cd (save_path)
function [vars,trial_id] = wrap_vars_Caleb(Events_int)
k = find(Events_int == 4009);
trial_id = Events_int(k+1);

% prob
Lprob = Events_int(k+3)/100;
Rprob = Events_int(k+4)/100;

% reward
notBlueOps = Events_int(k+7);
notBlueOps1 = floor(notBlueOps/100);
notBlueOps2 = floor(mod(notBlueOps,100)/10);

Lrew = ones(size(Lprob));
Lrew(notBlueOps1==0) = 2;
Lrew(notBlueOps1==1) = 3;
Rrew = ones(size(Lprob));
Rrew(notBlueOps2==0) = 2;
Rrew(notBlueOps2==1) = 3;

% order
order = Events_int(k+6);
order = round(order,-1)/10;
Lfirst = floor(order/10)==1;
optionorder = floor(order/10);

% choice
choice = Events_int(k+8);
choiceisL = choice==1;

%gamble outcome
outcome = Events_int(k+9);
reward = zeros(size(Lprob));
reward(outcome==0)=1;
reward(outcome==2&choiceisL) = Lrew(choiceisL&outcome==2);
reward(outcome==2&~choiceisL) = Rrew(~choiceisL&outcome==2);

% correction for prob for safe options
Lprob(Lrew==1) = 1;
Rprob(Rrew==1) = 1;

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
vars(:,7) = optionorder;
vars(:,8) = choiceisL;
vars(:,9) = choiceisL==Lfirst;
vars(vars(:,9)==0,9) = 2;
vars(:,10) = reward;
end

function strobes = getstrobes_plx(EVT01,EVT02,EVT03,EVT04,EVT05,EVT06)

strobes(:,1) = EVT06;

s = cell(size(strobes,1),5);
s(1:end-1,1) = arrayfun(@(n)EVT01(EVT01>strobes(n,1)& EVT01<strobes(n+1,1)),1:size(strobes,1)-1,'UniformOutput',false);
s(1:end-1,2) = arrayfun(@(n)EVT02(EVT02>strobes(n,1)& EVT02<strobes(n+1,1)),1:size(strobes,1)-1,'UniformOutput',false);
s(1:end-1,3) = arrayfun(@(n)EVT03(EVT03>strobes(n,1)& EVT03<strobes(n+1,1)),1:size(strobes,1)-1,'UniformOutput',false);
s(1:end-1,4) = arrayfun(@(n)EVT04(EVT04>strobes(n,1)& EVT04<strobes(n+1,1)),1:size(strobes,1)-1,'UniformOutput',false);
s(1:end-1,5) = arrayfun(@(n)EVT05(EVT05>strobes(n,1)& EVT05<strobes(n+1,1)),1:size(strobes,1)-1,'UniformOutput',false);
s{end,1} = EVT01(EVT01>strobes(end,1));
s{end,2} = EVT02(EVT02>strobes(end,1));
s{end,3} = EVT03(EVT03>strobes(end,1));
s{end,4} = EVT04(EVT04>strobes(end,1));
s{end,5} = EVT05(EVT05>strobes(end,1));

for n = 1:size(strobes,1)
    try
        dig6 = vertcat(s{n,:});
        tmp = arrayfun(@(k)find(cellfun(@(C)any(C==k),s(n,:))),sort(dig6))-1;
        rbase5 = 10.^(5:-1:0)*tmp;
        r = base2dec(num2str(rbase5),5);
        strobes(n,2) = r;
    catch err
        strobes(n,2) = NaN;
        warning(err.message);
    end
end


end


%% StrobeNames
% firstOpOn = 4001;
% firstOpOff = 4002;
% secondOpOn = 4003;
% secondOpOff = 4035;
% fixOn = 4004;
% fixationdot = 4006;
% goSignal = 4007; (also option appears)
% feedbackOn = 4008;
% feedbackOff = 4009;
% lookAtOp1 = 4051;
% lookAtOp2 = 4052;
% fixAcquired = 4061;
% fixLost = 4062;
% leftOpFixAcquired = 4071;
% leftOpFixLost = 4072;
% rightOpFixAcquired = 4073;
% rightOpFixLost = 4074;

% after 4009
% +1 trial number
% +2 numOps
% +3 probLeft (%)
% +4 probRight (%)
% +5 probCenter (%)
% +6 order
% +7 notBlueOps
% +8 choice (==L)
% +9 gambleoutcome (no gamble = 0, gamble lose = 1, gamble win = 2
