% simple accuracy track
function behavior_accuracy(vars)
wind = -49:50;
count = 0;
T_Range = 50:10:length(vars)-50;
accuracy = NaN(1,length(T_Range));
for i = T_Range
    count = count+1;
    Tr = i+wind;
    accuracy(count) = mean((vars(Tr,3)-vars(Tr,6)>0) == (vars(Tr,9)==1));
end
figure;
plot(T_Range,accuracy*100);
ylabel('% choosing the better ev');
xlabel('trial number (window = 100 trial)'); 
ylim([50,100]);
end