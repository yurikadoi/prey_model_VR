function flush_water(sDur)
% flush water
% 2018 HRK newly created from test_water_value.m
%% initialize the channel
VirMEn_Def
SR = 5000;
daqreset
vr.ao = analogoutput('nidaq','dev1');
addchannel(vr.ao,[0 1]);
set(vr.ao,'samplerate',SR);

vr.ai = analoginput('nidaq', 'Dev1'); % connect to the DAQ card
% 0 : dX, 1: dY, 2: licking 3: LED photodiode
% 4: start start/stop dio
set(vr.ai,'InputType','SingleEnded'); %% added by HRK 11/10/2014
addchannel(vr.ai,0:8); %
% set channel name % 6/14/2015
set(vr.ai,'samplerate',1000,'samplespertrigger',1e7); % define buffer

% switch MACHINE_NAME
%     case 'Mcb-UCHIDA-VS2'
%     set(vr.ai.Channel(1),'SensorRange',[-1 1], 'InputRange', [-1 1], 'UnitsRange', [-1 1])
% end
start(vr.ai);

vr.dio = digitalio('nidaq', 'dev1');
addline(vr.dio,0:7,'out');
start(vr.dio);
% if trials are aborted, it is set to 1. reset all to zero.
putvalue(vr.dio,[0 0 0 0 0 0 0 0]);

% vSnd = 5 * ones(40*SR,1); vSnd(1:2:end) = vSnd(1:2:end) * -1;
vSnd = 5 * zeros(40*SR,1); vSnd(1:2:end) = vSnd(1:2:end) * -1;
iSndOff = floor(0.08 * SR);
vSnd(iSndOff:end) = 0;

on0 =  [5 * zeros(floor(7/1000*SR),1 ); zeros(1, 1)]; on0 = [on0 vSnd(1:length(on0))];
on3 =  [5 * ones(floor(3/1000*SR),1 ); zeros(1, 1)]; on3 = [on3 vSnd(1:length(on3))];
on6 =  [5 * ones(floor(6/1000*SR),1 ); zeros(1, 1)]; on6 = [on6 vSnd(1:length(on6))];
on8 =  [5 * ones(floor(8/1000*SR),1 ); zeros(1, 1)]; on8 = [on8 vSnd(1:length(on8))];
on16 =  [5 * ones(floor(16/1000*SR),1 ); zeros(1, 1)]; on16 = [on16 vSnd(1:length(on16))];
on20 =  [5 * ones(floor(20/1000*SR),1 ); zeros(1, 1)]; on20 = [on20 vSnd(1:length(on20))];
on25 =  [5 * ones(floor(25/1000*SR),1 ); zeros(1, 1)]; on25 = [on25 vSnd(1:length(on25))];
on30 =  [5 * ones(floor(30/1000*SR),1 ); zeros(1, 1)]; on30 = [on30 vSnd(1:length(on30))];
on35 =  [5 * ones(floor(35/1000*SR),1 ); zeros(1, 1)]; on35 = [on35 vSnd(1:length(on35))];
on40 =  [5 * ones(floor(40/1000*SR),1 ); zeros(1, 1)]; on40 = [on40 vSnd(1:length(on40))];
on50 =  [5 * ones(floor(50/1000*SR),1 ); zeros(1, 1)]; on50 = [on50 vSnd(1:length(on50))];
on75 =  [5 * ones(floor(75/1000*SR),1 ); zeros(1, 1)]; on75 = [on75 vSnd(1:length(on75))];
on100 =  [5 * ones(floor(100/1000*SR),1 ); zeros(1, 1)]; on100 = [on100 vSnd(1:length(on100))];
on150 =  [5 * ones(floor(150/1000*SR),1 ); zeros(1, 1)]; on150 = [on150 vSnd(1:length(on150))];
on200 =  [5 * ones(floor(200/1000*SR),1 ); zeros(1, 1)]; on200 = [on200 vSnd(1:length(on200))];
on300 =  [5 * ones(floor(300/1000*SR),1 ); zeros(1, 1)]; on300 = [on300 vSnd(1:length(on300))];
on1000 = [5 * ones(floor(1000/1000*SR),1); zeros(1, 1)]; on1000 = [on1000 vSnd(1:length(on1000))];
on2000 = [5 * ones(floor(2000/1000*SR),1); zeros(1, 1)]; on2000 = [on2000 vSnd(1:length(on2000))];
on5000 = [5 * ones(floor(5000/1000*SR),1); zeros(1, 1)]; on5000 = [on5000 vSnd(1:length(on5000))];
on10000 = [5 * ones(floor(10000/1000*SR),1); zeros(1, 1)]; on10000 = [on10000 vSnd(1:length(on10000))];
on20000 = [5 * ones(floor(20000/1000*SR),1); zeros(1, 1)]; on20000 = [on20000 vSnd(1:length(on20000))];

off1000 = [zeros(1,1*SR)]';
laser20000 = [5 * ones(floor(20000/1000*SR),1); zeros(1, 1)]; 
laser20000 = [zeros(size(laser20000)) laser20000];

%% flush water+

% out_data = [0 5 * ones(1, floor( 20)) 0]';
% out_data = [zeros(size(out_data)) out_data];   % reward + no sound


% out_data = on2000;
% out_data = [on10000(:,1) on10000(:,1)];
% out_data = [on1000(:,1) on1000(:,1)];

out_data = on10000;

% if is_arg('sDur')
%     on = [5 * ones(floor(sDur*1000/1000*SR),1); zeros(1, 1)]; on = [on vSnd(1:length(on))];
% end
% out_data = on200 ;*9-------
% out_data = on0 ;

tic
putdata(vr.ao, out_data);
toc
tic
start(vr.ao);
toc
% pause(length(out_data)/1000 + 0.01);
% stop(vr.ao);
global idle_voltage_offset
global idle_voltage_std
% load([MACHINE_NAME '_offsets.mat']);
pause(3);
[data time] = getdata(vr.ai, vr.ai.SamplesAvailable);
% use median instead of
% mean. I have error signals from rotary encoder.
idle_voltage_offset = median(data);
idle_voltage_std = std(data);
% save([MACHINE_NAME '_offsets.mat'], 'idle_voltage_offset','idle_voltage_std');
fid = figure(20); set(fid,'tag', 'restV'); 
subplot(2,1,1); hist(data(:, [1]),50);
title(sprintf('Ch0, median+-std: %f +- %f', idle_voltage_offset(1), std(data(:,1))));
yl = ylim;
hold on; plot(idle_voltage_offset(1), yl(2),'v'); hold off;
subplot(2,1,2); hist(data(:,2), 50);
yl = ylim;
hold on; plot(idle_voltage_offset(2), yl(2),'v'); hold off;
title(sprintf('Ch1, median+-std: %f +- %f', idle_voltage_offset(2), std(data(:,2))));
xlabel('Time (s)'); ylabel('Signal (V)');
%%
pathname = 'C:\ViRMEn\ViRMeN_data\patchForaging\init\';
save([pathname date '.mat'],'idle_voltage_offset');
