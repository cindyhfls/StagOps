% CT 20190417
% get strobes from plexon more efficiently

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
%%
% for n = 1: size(strobes,1)
%     if n == size(strobes,1)
%         s{1} = EVT01(EVT01>strobes(n,1));
%         s{2} = EVT02(EVT02>strobes(n,1));
%         s{3} = EVT03(EVT03>strobes(n,1));
%         s{4} = EVT04(EVT04>strobes(n,1));
%         s{5} = EVT05(EVT05>strobes(n,1));
%     else
%         s{1} = EVT01(EVT01>strobes(n,1) & EVT01<strobes(n+1,1));
%         s{2} = EVT02(EVT02>strobes(n,1) & EVT02<strobes(n+1,1));
%         s{3} = EVT03(EVT03>strobes(n,1) & EVT03<strobes(n+1,1));
%         s{4} = EVT04(EVT04>strobes(n,1) & EVT04<strobes(n+1,1));
%         s{5} = EVT05(EVT05>strobes(n,1) & EVT05<strobes(n+1,1));
%     end
%     dig6 = vertcat(s{:});
% %     if ~isempty(dig6)
%         tmp = arrayfun(@(k)find(cellfun(@(C)any(C==k),s)),sort(dig6))-1;
%         rbase5 = 10.^(5:-1:0)*tmp;
% %         rbase5 = 0;
% %         for i = 1:6
% %             lowest = min(dig6);
% %             j = find(cellfun(@(C)any(C==lowest),s));
% %             rbase5 = rbase5 + ((j-1)*10^(6-i));
% %             dig6 = setdiff(dig6,lowest);
% %         end
%         r = base2dec(num2str(rbase5),5);
%         strobes(n,2) = r;
% %     end
% end
% toc
