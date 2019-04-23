% Generic code for extract psth
% N.B. this code was originally designed for search task, so their could be
% multiple time strobes in each trial
% strobesforpsth is a cell of timestamp in nTrials with nEvents in each
% cell
% Created 2018.02.13
% Jiaxin Tu

% SYNTAX:
% function [psth]= extractpsthgeneric(SPK,strobesforpsth)
% function [psth]= extractpsthgeneric(SPK,strobesforpsth,startoffset,endoffset,binsize)
% startoffset and endoffset in seconds
% binsize in seconds, e.g. 0.01 stands for 10 ms
function [psth]= extractPSTHgeneric(SPK,strobesforpsth,varargin)
trialnum = length(strobesforpsth);
if isempty(varargin)
    varargin=cell(1,3);
end

if isempty(varargin{1})
    startoffset =5; % 5 s before start
else
    startoffset = varargin{1};
end
if isempty(varargin{2})
    endoffset = 5; % 5 s after start
else
    endoffset = varargin{2};
end
if length(varargin)<3 || isempty(varargin{3})
    binsize = 0.02; % s which is 20ms
else
    binsize = varargin{3};
end


% preallocate memory


psth = NaN(trialnum,(startoffset+endoffset)*1/binsize);
count = 1;
for i=1:trialnum
    startat= strobesforpsth{i}-startoffset; % 10s before actual start Timestamp
    stopat = strobesforpsth{i}+endoffset; % 10s after actual start Timestamp
    if ~isempty(startat)&& numel(startat)==1
        spikes=SPK(SPK>startat&SPK<stopat);% SPKs are actually time stamps
        spikes=spikes-startat;
        psth(count,:)=histcounts(spikes,0:binsize:(startoffset+endoffset));
        count = count+1;
    elseif ~isempty(startat)&& numel(startat)>1
        for k = 1:numel(startat)
            tempstart = startat(k);
            tempstop = stopat(k);
            spikes=SPK(SPK>tempstart&SPK<tempstop);% SPKs are actually time stamps
            spikes=spikes-tempstart;
            psth(count,:)=histcounts(spikes,0:binsize:(startoffset+endoffset));
            count = count+1;
        end
    end
end
end
