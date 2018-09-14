function code = dark_freerews_progratio % MB: 8/6/18

%deliver small size rewards automatically every X # of seconds for
%habituation. however, offer pseudorandom rew sizes (sm/md/lg) for prog
%ratio running to train to run


% Begin header code - DO NOT EDIT
code.initialization = @initializationCodeFun;
code.runtime = @runtimeCodeFun;
code.termination = @terminationCodeFun;
% End header code - DO NOT EDIT

function vr = initializationCodeFun(vr)

rng('shuffle');



vr.mouseID = eval(vr.exper.variables.mouseID);
vr.debugMode = eval(vr.exper.variables.debugMode);
vr.RewDuration = eval(vr.exper.variables.RewDuration);
vr.scalingStandard = eval(vr.exper.variables.scaling);



daqreset %reset DAQ in case it's still in use by a previous Matlab program

VirMenInitDAQ;

vr.pathname = 'C:\ViRMEn\ViRMeN_data\foraging';
cd(vr.pathname);


vr.startTime = datestr(rem(now,1));
vr.startT = now;

vr.eventData = [];

vr.totalWater = 0;

vr.scaledown = 2; %divide scaling by term
vr.IPI = 50;


vr.rewDeliver = 0;
vr.trialNum = 1;

vr.rewEarned = 0;

vr.progRatioStart = 0; % number can be added to progratio variable to start higher

%% KEYPRESS COMMANDS
vr.dispStartTime = 81; %'q'
vr.dispWater = 87; %'w'
vr.dispHistory = 69; %'e'

vr.dispWhatever = 82; %'r'


vr.toggleAutoH20 = 84; % t
vr.autoOFF = 0; %turn water timer off

vr.rewKeyMed = 85; % 'u'

% rew sizes
vr.onXLgh2o = 4;
vr.onLgh2o = 3;
vr.onMdh2o = 2;
vr.onSmh2o = 1;
vr.XLgRew = 23; vr.LgRew = 23; vr.MdRew = 13; vr.SmRew = 7;
%set reward valve open times
vr.SR = 1000; %STOP HARDCODING THIS, FIX W CODE TO EXTRACT VALUE FROM .AO
vr.vSnd = 5 * ones(20*vr.SR,1); vr.vSnd(1:2:end) = vr.vSnd(1:2:end) * -1;
vr.iSndOff = floor(0.08 * vr.SR);
vr.vSnd(vr.iSndOff:end) = 0;

%water sizes (valve opening): NEED TO RECALLIBRATE
vr.onSm =  [5 * ones(floor(vr.SmRew/1000*vr.SR),1 ); zeros(1, 1)]; vr.onSm = [vr.onSm vr.vSnd(1:length(vr.onSm))];
%vr.onSmh2o = 2; %measured 6/9/16

vr.onMd =  [5 * ones(floor(vr.MdRew/1000*vr.SR),1 ); zeros(1, 1)]; vr.onMd = [vr.onMd vr.vSnd(1:length(vr.onMd))];
%onMdh2o = 4uL; 6/9/16

vr.onLg =  [5 * ones(floor(vr.LgRew/1000*vr.SR),1 ); zeros(1, 1)]; vr.onLg = [vr.onLg vr.vSnd(1:length(vr.onLg))];
%vr.onLgh2o = 6; %measured 6/9/16


vr.scaling = vr.scalingStandard/vr.scaledown;



vr.progRatioDist = [5 10 15 20 25 30 35 40 45 50 60 70 80 90 100];
vr.progRatio = vr.progRatioStart;
vr.distance_thistrial = vr.progRatioDist(vr.progRatioStart + 1);

vr.rew_SW = 0;
vr.rewtimes = [20 30 40 50]; %vary possible time to next reward
vr.rewtime_thistrial = 20; % always start with 20

vr.rewsize_thistrial = 3; % always start w large

vr.hold = 0; % hold for 1 second after water delivery to avoid triggerring twice at once
vr.hold_SW = 0;

vr.pause_autorew = 0; % if earning rewards from moving on treadmill
%pause automatic delivery of timed rews so that all rews must be earned from running distance
vr.pause_autorew_SW = 0;
vr.pause_autorew_timeout = 30;


switch vr.mouseID
    case {1,3}
        vr.progRatioStart = 5;
    case 4
        vr.progRatioStart = 3;
    otherwise
        display('mouse ID not recognized')
end

% start generating pulse by signaling to Arduino board
putvalue(vr.dio.Line(2), 1);


%% DELIVER small WATER TO START SESSION

%vr.manualRewSm = [vr.manualRewSm,now];
out_data = vr.onSm;
vr.totalWater = vr.totalWater + vr.onSmh2o;
putdata(vr.ao, out_data);
start(vr.ao);
trigger(vr.ao);
display('Sm Rew Manual Delivery');
display(datestr(now));
%plot licks
% retrieve analog input data
[data, time, abstime] = getdata(vr.ai, min([vr.ai.SamplesAvailable*1.02 vr.SR * 10])); % 1000 * 8
% data
plot(time, data(:,3)) % probably data(:,3)
% flush remaining data in memory
flushdata(vr.ai, 'all');





function vr = runtimeCodeFun(vr)

vr.dp_cache = vr.dp; % cache current displacement value to store

if vr.autoOFF==0
    if vr.pause_autorew==0
        vr.rew_SW = vr.rew_SW + vr.dt;
    else
        vr.pause_autorew_SW = vr.pause_autorew_SW + vr.dt;
        if vr.pause_autorew_SW > vr.pause_autorew_timeout
            vr.pause_autorew=0;
            display('autorew timer back on')
        end
    end
    
    if vr.rew_SW >= vr.rewtime_thistrial
        vr.rewEarned = 2;
        vr.rew_SW = 0;
        vr.rewtime_thistrial = vr.rewtimes(randi(length(vr.rewtimes)));
        rewtime_thistrial = vr.rewtime_thistrial; display(rewtime_thistrial)
    end
    
end

if vr.hold > 0
    vr.hold_SW = vr.hold_SW + vr.dt;
    
    if vr.hold_SW >= .2
        vr.hold = 0;
        vr.hold_SW = 0;
        %display('hold=0')
    end
end



if vr.position(2) > vr.distance_thistrial
    vr.rewEarned = randi(3);
    
    %move back to beginning
    vr.position(2) = 0;
    vr.trialNum = vr.trialNum + 1;
    
    vr.distance_thistrial = vr.progRatioDist(floor(vr.trialNum/10)+1);
    distance_nexttrial = vr.distance_thistrial; display(distance_nexttrial)
    
    if vr.pause_autorew==0
        vr.pause_autorew = 1; vr.pause_autorew_SW = 0; display('rew earned: pause autorew')
    end
end

%% DELIVER REWARD
if vr.rewEarned > 0 && vr.hold == 0
    
    vr.hold = 1; % pause so next rew does not get delivered
    
    currRew = vr.rewEarned;
    vr.rewEarned = 0; %reset
    vr.lastRewEarned = datestr(rem(now,1));
    
    switch currRew
        case 1
            %display('Sm rew earned');
            %ms_uL = [vr.SmRew vr.onSmh2o]; display(ms_uL);
            vr.totalWater = vr.totalWater + vr.onSmh2o;
            SmRewEarned = vr.totalWater; display(SmRewEarned);
            
            out_data = vr.onSm;
            putdata(vr.ao, out_data);
            start(vr.ao);
            trigger(vr.ao);
            
            %plot licks
            % retrieve analog input data
            [data, time, abstime] = getdata(vr.ai, min([vr.ai.SamplesAvailable*1.02 vr.SR * 10])); % 1000 * 8
            % data
            plot(time, data(:,3)) % probably data(:,3)
            % flush remaining data in memory
            flushdata(vr.ai, 'all');
            
            
        case 2
            %display('Md rew earned');
            %ms_uL = [vr.MdRew vr.onMdh2o]; display(ms_uL);
            vr.totalWater = vr.totalWater + vr.onMdh2o;
            MdRewEarned = vr.totalWater; display(MdRewEarned);
            
            out_data = vr.onMd;
            putdata(vr.ao, out_data);
            start(vr.ao);
            trigger(vr.ao);
            
            %plot licks
            % retrieve analog input data
            [data, time, abstime] = getdata(vr.ai, min([vr.ai.SamplesAvailable*1.02 vr.SR * 10])); % 1000 * 8
            % data
            plot(time, data(:,3)) % probably data(:,3)
            % flush remaining data in memory
            flushdata(vr.ai, 'all');
            
            
        case 3
            %display('Lg rew earned');
            %ms_uL = [vr.LgRew vr.onLgh2o]; display(ms_uL);
            vr.totalWater = vr.totalWater + vr.onLgh2o;
            LgRewEarned = vr.totalWater; display(LgRewEarned);
            
            out_data = vr.onLg;
            putdata(vr.ao, out_data);
            start(vr.ao);
            trigger(vr.ao);
            
            %plot licks
            % retrieve analog input data
            [data, time, abstime] = getdata(vr.ai, min([vr.ai.SamplesAvailable*1.02 vr.SR * 10])); % 1000 * 8
            % data
            plot(time, data(:,3)) % probably data(:,3)
            % flush remaining data in memory
            flushdata(vr.ai, 'all');
            
    end
end



%% reset if mouse goes backwards too far

if vr.position(2) <= -10
    vr.position(2) = 0;
    display('went backwards, reset position to zero');
end

x = vr.keyPressed;

if isnan(x) ~= 1
    switch x
        case vr.toggleAutoH20
            if vr.autoOFF==0
                vr.autoOFF = 1;
                display('Auto H20 timer OFF')
            else
                vr.autoOFF = 0;
                display('Auto H20 timer ON')
            end
    end
    
end


%% --- TERMINATION code: executes after the ViRMEn engine stops.
function vr = terminationCodeFun(vr)

display(datestr(now))


fclose all;

%turn off camera
putvalue(vr.dio.Line(2), 0);

stop(vr.ai);



endTime = datestr(rem(now,1));
endT = now;

mID = vr.mouseID; display(mID);
%SLC = ['start:' vr.startTime ', lastRew:' vr.lastRewEarned ', end:' endTime];
SLC = ['start:' vr.startTime ', end:' endTime];
disp(SLC);

trials_water = [vr.trialNum vr.totalWater];
display(trials_water)

progRatio_end = vr.distance_thistrial; display(progRatio_end)

