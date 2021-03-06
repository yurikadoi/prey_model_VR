% last edits: MB 10-28-18 12:30pm

%coin heads: prey will presented, coin tails: prey will not presented
 
function code = prey_model_w_daq

% prey model   Code for the ViRMEn experiment xForaging.
%   code = xForaging   Returns handles to the functions that ViRMEn
%   executes during engine initialization, runtime and termination.
%store LeaveTimes already packaged based on trialtype/blocktype


% Begin header code - DO NOT EDIT
code.initialization = @initializationCodeFun;
code.runtime = @runtimeCodeFun;
code.termination = @terminationCodeFun;
% End header code - DO NOT EDIT

%% --- INITIALIZATION code: executes before the ViRMEn engine starts.
function vr = initializationCodeFun(vr)
global idle_voltage_offset
vr.idle_voltage_offset = idle_voltage_offset;
rng('shuffle'); % shuffles random numvisualber generator at start of task

%% retrieves values from ViRMEn GUI
vr.mouseID = eval(vr.exper.variables.mouseID);
vr.debugMode = eval(vr.exper.variables.debugMode);
vr.debugYurika = eval(vr.exper.variables.debugYurika);
vr.RewDuration = eval(vr.exper.variables.RewDuration); % global variable used in other function(s) written by HyungGoo
vr.scalingStandard = eval(vr.exper.variables.scaling);
vr.scaledown = 2;
vr.scaling = vr.scalingStandard/vr.scaledown; % global variable used in other function(s) written by HyungGoo
vr.startTime = datestr(rem(now,1));
vr.startT = now;

%%
vr.daq_flag = 1;%daq_flag is 1 when running on the experiment room pc with daq board connceted. it is zero when just running on my laptop
%%
vr.startLocation=0;
%vr.currTrack_ID=1;



%in the beginning of session, start vr.ITI=3 so that it starts with
%flipping coin
vr.ITI=3; % set to 1 to start ITI and 2 while remaining in ITI, 0 is ITI off

%initialzie stopwatches
vr.sessionTimer_SW = 0;
vr.trialTimer_SW=0;%stopwatch that starts at the trial onset
vr.trialTimer_On=0;
vr.searchtime_SW = 0;%stopwatch for searchtime
vr.ITI_SW=0; % stopwatch for ITI
vr.startTrial_SW = 0; % keep track of how long mouse takes to start trial after track appears
vr.wait4reappear_SW = 0; % to make some delay between the reward delivery or abortion, and the next patch appearing
vr.reappear_SW_turnedON = 0;
vr.engagingSW = 0;% keep track of how long the mouse has been engagin in a track
vr.wait4stop_SW=0; % keep track of how long it takes mouse to stop after required ITI duration has passed
vr.wait4stop_times = []; %array to store wait4stop
vr.plot_SW =0;% to make some delay between when the reward is delivered and whent the figure is plotted
vr.searchtime_duringSL = 0;
vr.searchtime_duringReappearWait=0;
vr.flippin_duringITI_SW = 0;
%initialize flags
vr.reappear_flag=0;
vr.abort_flag = 0;
vr.start_flag = 0;
vr.occur_time=0;
vr.roll_flag = 1;
vr.sound_flag = 0;
vr.flipping = 0;
vr.env_change_flag =0;
vr.changed_or_not_yet_flag = 0;
vr.toggle_flag = 0;
%initialize values
vr.delay2disappear=.5; % delay until track disappears following reward
vr.rewEarned = 0; % set to value for rew size when reward is earned
vr.atStartLocation = 1; % 0 = onTrack, 1 = at start location
vr.engageLatency{1} = [];% how long it takes the mouse to engage in a prey (only when it engages)
vr.engageLatency{2} = [];
vr.engageLatency_thisTrial = 0;
vr.wait4stop=0; % set to positive value to require mouseStop to initiate new trial
vr.okNewTrial=0; % start new trial after ITI or after ITI + mouseStopped
vr.waiting4start =0; %whether or not waiting for the mouse to start running
vr.flippin_duringITI=1; %coin-flippin count during ITI
vr.flippin_duringSL=1; %coin-flippin count during start latency
vr.flippin_duringReappearWait=1; %coin-flippin count during waiting for permission to reappear
vr.start_queue_indx=1;% indx to cycle through the queue
vr.queue_indx_stop = 1; % indx to cycle through the queue
vr.plotAI=0; % plots analog input
vr.trialNum_change_timing =0;
vr.trialNum_in_track2_change_timing = 0;

if vr.debugMode % set to 'true' in ViRMEn GUI when debugging on the rig to set all means (ITI, distance, etc) to low values for quicker debugging
    disp('DEBUG MODE RUNNING')
end
%%
if ~vr.debugMode
    disp('daqreset')
    if vr.daq_flag == 1
        daqreset %reset DAQ in case it's still in use by a previous Matlab program
        VirMenInitDAQ;
    end
    vr.pathname = 'C:\ViRMEn\ViRMeN_data\prey_model';
    cd(vr.pathname);
    vr.filename = datestr(now,'yyyymmdd_HHMM');
    vr.filenameExper = ['Exper',datestr(now,'yyyymmdd_HHMM')];
    vr.filenameTaskVars = ['TaskVars',datestr(now,'yymmdd_HHMM')];
    vr.filenameTrials = ['Trials',datestr(now,'yymmdd_HHMM')]; % data for each trial
    vr.filenameStats = ['Stats',datestr(now,'yymmdd_HHMM')]; % summary statistics per session
    
    exper = copyVirmenObject(vr.exper);
    save([vr.pathname '\' vr.filenameExper '.mat'],'exper');
    taskVars = vr.mouseID; %save other variables at termination
    save([vr.pathname '\' vr.filenameTaskVars '.mat'],'taskVars');
    trials = [];
    save([vr.pathname '\' vr.filenameTrials '.mat'],'trials');
    stats = [];
    save([vr.pathname '\' vr.filenameStats '.mat'],'stats');
end

%% determine the index of tracks
vr.indx_track{1} = vr.worlds{vr.currentWorld}.objects.indices.mainFloor1;
vr.indx_track{2} = vr.worlds{vr.currentWorld}.objects.indices.mainFloor1B;
%vr.indx_track{3} = vr.worlds{vr.currentWorld}.objects.indices.mainFloor1_bright;
%vr.indx_track{4} = vr.worlds{vr.currentWorld}.objects.indices.mainFloor1B_bright;
% get all relevant coordinates, etc. for tracks (floors)
for k = 1:length(vr.indx_track)
    
    % determine the indices of the first and last vertex of tracks
    vr.vertexFirstLast_track{k} = vr.worlds{vr.currentWorld}.objects.vertices(vr.indx_track{k},:);
    
    % create an array of all vertex indices belonging to tracks
    vr.trackIndx{k} = vr.vertexFirstLast_track{k}(1):vr.vertexFirstLast_track{k}(2);
    
    %store original coordinates for tracks
    vr.track_xOrig{k} = vr.worlds{vr.currentWorld}.surface.vertices(1, vr.trackIndx{k});
    vr.track_yOrig{k} = vr.worlds{vr.currentWorld}.surface.vertices(2, vr.trackIndx{k});
    vr.track_zOrig{k} = vr.worlds{vr.currentWorld}.surface.vertices(3, vr.trackIndx{k});
end
%%
vr.totalWater = 0; % keep track of water earned
vr.preyData=[]; %storing vr.trialNum vr.CBA vr.RewSize vr.engageLatency vr.wait4stop_SW vr.searchtime_SW
vr.trialNum = 0;% keep track of trial number
vr.RewSize = 0; %store reward size
vr.lastRewEarned = [];% keep track of the time when the last reward is earned
%% initialize A,B,C
%%C:experiment type(3 for Yurika's prey model), B:track type (1 or 2),
%%A:reward size (2 or 4)
vr.CBA = 0;
vr.A = 0; vr.B = 0; vr.C = 0;
%%
vr.trackLength = eval(vr.exper.variables.floor1height);

%% KEYPRESS COMMANDS
vr.dispStartTime = 81; %'q'
vr.dispWater = 87; %'w'
vr.dispHistory = 69; %'e'
vr.dispToggle = 84; %'t'
vr.dispStats = 82; %'r'

%when debugging use shorter handling time and more frequent prey encounter
%(just for the sake of convernience)
if vr.debugYurika == 0
    vr.handling_time{1}=15;
    vr.handling_time{2}=30;
    
    vr.lambda_1A = 1/72;
    vr.lambda_1B = 1/36;
    vr.lambda_1C = 1/18;
    vr.lambda_2 = 1/36;
else
    vr.handling_time{1}=5;
    vr.handling_time{2}=10;
    vr.lambda_1A = 1/72;
    vr.lambda_1B = 1/36;
    vr.lambda_1C = 1/18;
    vr.lambda_2 = 1/36;
end




%% number of cell = vr.B (which determines track # for trial type)
vr.rewTrials{1}=[]; % concatenate a 1 for rew trial, 0 for unrew
vr.rewTrials{2}=[];
%%
%ProgRatio
vr.progRatio_flag = 0;% if not using prog ratio, set it as zero, if using prog ratio set it as one
vr.progRatio=0; % set > 0 if using progressive ratio for rews
vr.progRatioStart = 0;
vr.progRatio_short_Dist = [20 30 40 50 60 70 80 90 100];
vr.progRatio_long_Dist = 2*vr.progRatio_short_Dist;

%%
%variables
vr.taskType_ID = [2 4]; % [2 4] track 1 = big reward short distance, track 2 = small reward long distance
vr.progRatio_flag = 0;% if not using prog ratio, set it as zero, if using prog ratio set it as one
vr.wait4stop=1;%0: if do not need to wait for stop, 1: if they need to stop to initiate the new trial

vr.queue_len_stop = 30; % begin training w ~.5s, then increase to 1s after learned to stop (same as stop to abort trial)
vr.queue_len_start=30;

vr.start4engage = 1;%0: if do not need to start running to engage, 1: if they need to start running to engage
vr.start_latency_CRIT = 5;%within how many seconds should they start running to engage with the trial

vr.progRatioStart = 1;% 9:is the maximum and goal of the training

vr.y_disposition = 0.15;% determines the speed of movement of track

vr.wait4reappear_CRIT=2;% how long (minimum) it takes for the patch to reappear either after reward or abort

vr.brightness = .6;
%%
%env condition
vr.env_change_flag = 0;% whether the environment (namely, the frequency of high-value prey) changes during a session or not
vr.change_timing = 25*60; %at what seconds, does the environment change

if vr.debugYurika == 0
    vr.freq_high_value=vr.lambda_1A;
    vr.freq_low_value=vr.lambda_2;
    
else
    vr.freq_high_value=1/10;
    vr.freq_low_value=1/10;
    vr.before_change_freq_high_value = 1/10;
    vr.after_change_freq_high_value = 1/10;
end

if vr.env_change_flag ==1 %if changing the environment in the middle of a session
    vr.before_change_freq_high_value = vr.lambda_1C;
    vr.after_change_freq_high_value = vr.lambda_1A;
end
%%
%variables that is dependent on individual mouse
switch vr.mouseID
%     case 1
%         disp('mouse #1: obiwan');
%         vr.STOP_CRIT = 0.025;
%         vr.START_CRIT = 0.08;
    case 2
        disp('mouse #2: skywalker');
        vr.STOP_CRIT = 0.025;
        vr.START_CRIT = 0.12;
    otherwise
        disp('error: MOUSE ID NOT RECOGNIZED');
end
%%
vr.spd_circ_queue_stop= ones(vr.queue_len_stop, 1);
vr.spd_circ_queue_start= zeros(vr.queue_len_stop, 1);

%%
vr.onLg_h2o = 4; vr.onSm_h2o = 2;
vr.LgRew = 22.5; vr.SmRew = 12.5;  %calibrated temporally on 11/5/18
%%
%set rew valve open times
vr.SR = 1000;
vr.vSnd = 5 * ones(20*vr.SR,1); vr.vSnd(1:2:end) = vr.vSnd(1:2:end) * -1;
vr.iSndOff = floor(0.08 * vr.SR);
vr.vSnd(vr.iSndOff:end) = 0;

%water sizes (valve openings), create reward valve outdata for DAQ board
vr.onSm_outdata =  [5 * ones(floor(vr.SmRew/1000*vr.SR),1 ); zeros(1, 1)]; vr.onSm_outdata = [vr.onSm_outdata (4/5)*vr.onSm_outdata zeros(length(vr.onSm_outdata),1) zeros(length(vr.onSm_outdata),1)];
vr.onLg_outdata =  [5 * ones(floor(vr.LgRew/1000*vr.SR),1 ); zeros(1, 1)]; vr.onLg_outdata = [vr.onLg_outdata (4/5)*vr.onLg_outdata zeros(length(vr.onLg_outdata),1) zeros(length(vr.onLg_outdata),1)];

%create sound outdata for DAQ board
vr.sound_length = 50;
vr.sound_outdata = [zeros(vr.sound_length,1) -4*ones(vr.sound_length,1) zeros(vr.sound_length,1) 5*ones(vr.sound_length,1)];

%% event signals to send to DAQ board
vr.event_engageTrial_outdata=[zeros(10,1) 0.5*ones(10,1) zeros(10,1) zeros(10,1)];
vr.event_abortTrial_outdata=[zeros(10,1) -2*ones(10,1) zeros(10,1) zeros(10,1)];% upon abort trial, signal negative voltage to DAQ - change value to 1 to trigger
vr.event_newTrial=0; % when track appears, signal trial type w A.B mV for later readout of trialtype from DAQ file
for iA = 1:6
    for iB = 1:9
        vr.event_newTrial_outdata{iB}{iA} = [zeros(10,1) ((iA+.1*iB)/2)*ones(10,1) zeros(10,1) zeros(10,1)];
    end
end

%%
mouseID = vr.mouseID; display(mouseID);
%%set progratop start and the distances
vr.progRatio = vr.progRatioStart;
vr.short_distance = vr.progRatio_short_Dist(vr.progRatio);
vr.long_distance = vr.progRatio_long_Dist(vr.progRatio);

%% move correct track into place, other away/disappear, initiate variables for must run, etc
%flip a coin to decide which track to appear as the first trial
vr.C = 3;

vr.worlds{vr.currentWorld}.surface.colors(4,vr.trackIndx{1}) = 0;
vr.worlds{vr.currentWorld}.surface.colors(4,vr.trackIndx{2}) = 0;
vr.worlds{vr.currentWorld}.surface.vertices(3,vr.trackIndx{1}) = vr.track_zOrig{1}+60;
vr.worlds{vr.currentWorld}.surface.vertices(3,vr.trackIndx{2}) = vr.track_zOrig{2}+60;

%% DELIVER 2uL WATER TO START SESSION - you are delivering large here, not small ***
if vr.daq_flag == 1
    if ~vr.debugMode
        if vr.daq_flag == 1
            out_data = vr.onLg_outdata;
            vr.totalWater = vr.totalWater + vr.onLg_h2o;
            
            putdata(vr.ao, out_data);
            start(vr.ao);
            trigger(vr.ao);
            
            display(datestr(now));
            
            [data, time, abstime] = getdata(vr.ai, vr.ai.SamplesAvailable*1.02);
            data_temp=data;
            data_temp(:,1)=-5*(data_temp(:,1)-repmat(idle_voltage_offset(1),[length(data_temp(:,1)),1]));
            figure; plot(time, data_temp(:,1:4)); % plot analog input
        end
    end
end
%% --- RUNTIME code: executes on every iteration of the ViRMEn engine.
function vr = runtimeCodeFun(vr)
global idle_voltage_offset
vr.sessionTimer_SW = vr.sessionTimer_SW + vr.dt;

vr.dp_cache = vr.dp; % cache current velocity so value measured even if changed to zero
%cache = vr.dp_cache; display(cache)
%vr.dp(:,2:end)=0;
%dp = vr.dp; display(dp)
%start the trial timer
if vr.trialTimer_On>0
    vr.trialTimer_SW = vr.trialTimer_SW + vr.dt;
end

if vr.ITI==0 && vr.abort_flag ==0
    vr.dp=[0 0 0 0];
    vr.startTrial_SW = vr.startTrial_SW + vr.dt;
    vr.spd_circ_queue_start(vr.start_queue_indx) = vr.dp_cache(:,2); % add current speed to queue
    vr.start_queue_indx = vr.start_queue_indx + 1; % move to next spot in queue
    
    % if the mouse needs to start to engage and if they are eligiable to
    % start, compare the mouse speed and start criteria
    if vr.start4engage == 1 && vr.waiting4start ==1
        if vr.start_flag==0 && nanmean(vr.spd_circ_queue_start(~isnan(vr.spd_circ_queue_start))) > vr.START_CRIT
            vr.waiting4start =0;
            vr.start_flag=1;%flag to show that mouse started to engage
            vr.engageLatency_thisTrial  = vr.trialTimer_SW;%storing engage latency
            %vr.engageLatency_times = [vr.engageLatency_times vr.engageLatency];
            % store engage latency per track type
            switch vr.currentB
                case 1
                    vr.engageLatency{1}=[vr.engageLatency{1} vr.engageLatency_thisTrial];
                case 2
                    vr.engageLatency{2}=[vr.engageLatency{2} vr.engageLatency_thisTrial];
            end
            
            vr.engagingSW = 0;%reset the engaging SW
            %vr.position(2) = vr.position(2) + vr.setSpeed*vr.dt;
            
            
        end
        
    end
    % once mouse decide to engage, move the track in a constant speed (vr.y_disposition)
    if  vr.start_flag > 0
        if vr.start_flag==1
            vr.start_flag=2;%only send engage event signal once
            %engage event signal
            out_data=vr.event_engageTrial_outdata;
            vr.flipping = 0;
            if vr.daq_flag==1
                putdata(vr.ao, out_data);
                start(vr.ao);
                trigger(vr.ao);
            end
        end
        
        vr.dp=[0 vr.y_disposition 0 0];%move the track in a constant speed
        vr.engagingSW = vr.engagingSW + vr.dt;% add time passed to the engaging SW
    end
    if vr.start_queue_indx > vr.queue_len_start % start over beginning of queue if at the end
        vr.start_queue_indx = 1;
    end
    %% keep flipping the coin during the start latency
    if vr.startTrial_SW >= vr.flippin_duringSL && vr.flipping > 0
        %flip coin
        % flip coin for high value track
        n=rand(1);
        if n < vr.freq_high_value
            vr.track1_occur_or_not=1;
        else
            vr.track1_occur_or_not=0;
        end
        % flip coin for low value track
        m=rand(1);
        if m < vr.freq_low_value
            vr.track2_occur_or_not=1;
        else
            vr.track2_occur_or_not=0;
        end
        %flip coin every second
        vr.flippin_duringSL = vr.flippin_duringSL + 1;
        
        
        if vr.track1_occur_or_not ==1 && vr.track2_occur_or_not == 0
            %track1 appears
            vr.B=1;
            vr.reappear_flag=1;%set reappearing flag to one so that if mouse abort this trial, the new track will appear right after 2 sec
            vr.flippin_duringReappearWait=1;%reset reappear waiting time to zero
            vr.flipping = 0;% no more flipping once get positive
            vr.searchtime_duringSL = vr.startTrial_SW;%how many seconds has passed by the time the coin was flipped positive
            %disp('aaaa')
        elseif vr.track1_occur_or_not==0 && vr.track2_occur_or_not == 1
            %track2 appears
            vr.B=2;
            vr.reappear_flag=1;
            vr.flippin_duringReappearWait=1;
            vr.flipping = 0;
            vr.searchtime_duringSL = vr.startTrial_SW;%how many seconds has passed by the time the coin was flipped positive
            %disp('bbbb')
            %if both coins flipped positive at the same time, flip another coin
            %to decide which track to appear next
        elseif vr.track1_occur_or_not == 1 && vr.track2_occur_or_not == 1
            %flip another coin
            l=rand(1);
            if l < vr.freq_low_value/(vr.freq_high_value + vr.freq_low_value)
                vr.track2_occur_or_not = 1;
                vr.track1_occur_or_not = 0;
                vr.B=2;
                vr.reappear_flag=1;
                vr.flippin_duringReappearWait=1;
                vr.flipping = 0;
                vr.searchtime_duringSL = vr.startTrial_SW;%how many seconds has passed by the time the coin was flipped positive
                
                %disp('cccc')
            else
                vr.track2_occur_or_not = 0;
                vr.track1_occur_or_not = 1;
                vr.B=1;
                vr.reappear_flag=1;
                vr.flippin_duringReappearWait=1;
                vr.flipping = 0;
                vr.searchtime_duringSL = vr.startTrial_SW;%how many seconds has passed by the time the coin was flipped positive
                
                %disp('dddd')
            end
            
        else
            %track does not appear in this sec, keep flipping the coin
            
        end
        %set the value of A according to the value of B
        if vr.B==1
            vr.A=4;
        elseif vr.B==2
            vr.A=2;
        end
        if vr.toggle_flag == 1
            disp('seconds passed flippin_duringSL')
            disp(vr.flippin_duringSL)
        end
    end
    
    %% MOUSE DID NOT RUN, ABORT TRIAL
    % if they are supposed to run to engage
    if vr.start4engage == 1
        %but they did not run and 5 sec has passed, it means they abort
        %this trial
        if vr.start_flag == 0 && vr.startTrial_SW>vr.start_latency_CRIT && nanmax(vr.spd_circ_queue_start(~isnan(vr.spd_circ_queue_start))) < vr.START_CRIT
            disp('mouse aborted trial')
            vr.ITI=1.5; % initialize ITI after abort trial
            vr.rewTrials{vr.currentB} = [vr.rewTrials{vr.currentB} 0]; % add zero for unrew trial
            vr.abort_flag = 1;
            vr.RewSize = 0;
            vr.engageLatency_thisTrial =0;
            vr.spd_circ_queue_start=zeros(vr.queue_len_start,1);
            
            vr.flippin_duringReappearWait=1;%reset reappear waiting time count to zero
            if vr.reappear_flag ==0
                vr.searchtime_duringSL = vr.startTrial_SW;
            end
            %abort event signal
            out_data=vr.event_abortTrial_outdata;
            if vr.daq_flag==1
                putdata(vr.ao, out_data);
                start(vr.ao);
                trigger(vr.ao);
            end
            
        end
    else
    end
    %% when the handling time is over, reward earned: switch to ITI
    if vr.start_flag > 0 && vr.engagingSW >= vr.handling_time{vr.currentB}
        disp('position > rewLocation')
        vr.ITI = 0.5;
        vr.flipping = 1;
        %vr.reappear_flag=0;
    end
end

if vr.ITI == 0.5
    vr.dp=[0 0 0 0];
    %make the track brighter to let the mouse know this is the goal
    vr.worlds{vr.currentWorld}.surface.colors(4,vr.trackIndx{vr.currTrack_ID}) = vr.brightness + 0.2;
    
    vr.ITI=1;
    A_currentA = [vr.A vr.currentA];
    display(A_currentA)
    vr.rewEarned = vr.currentA;
    vr.RewSize = vr.rewEarned;
    vr.rewTrials{vr.currentB}=[vr.rewTrials{vr.currentB} 1]; % add 1 for successful rew trials
    vr.trialTimer_On=0; % turn off trial time
end
%% *** NEW TRIAL START: Leave startLocation
if vr.atStartLocation==1 && vr.position(2) > vr.startLocation+2
    vr.atStartLocation = 0; %reset to start location
    
end
%% inter-trial interval
% ITI #s: 1 = initialize after reward, 1.5 init after abort, 2 = track disappears after delay following reward
% 3 = waiting before eligible to start new trial, 4 = waiting to detect stop before initiating new trial
if vr.ITI > 0
    vr.dp=[0 0 0 0];
    %% initialize ITI
    if vr.ITI==1 % initialize after rewarded trial
        disp('ITI=1')
        preyData_newLine = [vr.trialNum vr.CBA vr.RewSize vr.engageLatency_thisTrial vr.wait4stop_SW vr.searchtime_SW];
        display(preyData_newLine)
        vr.preyData  = [vr.preyData ; vr.trialNum vr.CBA vr.RewSize vr.engageLatency_thisTrial vr.wait4stop_SW vr.searchtime_SW];
        
        vr.searchtime_SW = 0;%initialize the search time SW
        vr.wait4reappear_SW = 0;%reset wait4reappear SW
        vr.ITI_SW = 0 - vr.dt; % initialize SW to -vr.dt because adding vr.dt to SW later this same iteration
        vr.ITI=2; % run next block after 'delay2disappear' time has elapsed
    elseif vr.ITI==1.5 % initialize after aborted trial
        disp('ITI=1.5')
        preyData_newLine = [vr.trialNum vr.CBA vr.RewSize vr.engageLatency_thisTrial vr.wait4stop_SW vr.searchtime_SW];
        display(preyData_newLine)
        vr.preyData  = [vr.preyData ; vr.trialNum vr.CBA vr.RewSize vr.engageLatency_thisTrial vr.wait4stop_SW vr.searchtime_SW];
        
        vr.searchtime_SW = 0;%initialize the search time SW
        vr.wait4reappear_SW = 0;%reset wait4reappear SW
        vr.ITI_SW = 0 - vr.dt; % initialize SW to -vr.dt because adding vr.dt to SW later this same iteration
        vr.ITI=2.5;
    end
    
    %% track disappears following delay after reward(ITI=2) or immediately after aborted trial(ITI=2.5)
    if (vr.ITI==2 && vr.ITI_SW >= vr.delay2disappear) || (vr.ITI==2.5 && vr.ITI_SW >= vr.delay2disappear)
        vr.plot_SW =0;
        vr.reappear_SW_turnedON = 1;
        % make track(s) disappear
        vr.worlds{vr.currentWorld}.surface.colors(4,vr.trackIndx{1}) = 0;
        vr.worlds{vr.currentWorld}.surface.colors(4,vr.trackIndx{2}) = 0;
        
        vr.worlds{vr.currentWorld}.surface.vertices(3,vr.trackIndx{1}) = vr.track_zOrig{1}+60;
        vr.worlds{vr.currentWorld}.surface.vertices(3,vr.trackIndx{2}) = vr.track_zOrig{2}+60;
        
        vr.wait4reappear_SW = vr.wait4reappear_SW + vr.dt;% add elapsed time to stopwatch
        
        %if coin was flipped positive during start latency, just wait for 2
        %sec and go to ITI=4
        if vr.reappear_flag == 1 && vr.wait4reappear_SW > 2
            if vr.wait4stop > 0 % begin next ITI if do not need to wait for stop, otherwise initialize speed queue
                %reset speed queue to detect mouse stop
                vr.spd_circ_queue_stop= ones(vr.queue_len_stop, 1);%initialize the speed queue
                vr.queue_indx_stop = 1;% initialize the speed queue index
                vr.wait4stop_SW = 0;%initialize the wait4stop stop watch
            end
            vr.searchtime_SW = vr.searchtime_duringSL + vr.searchtime_duringReappearWait;
            vr.ITI=4;
            vr.sound_flag = 1;
            vr.reappear_flag = 2;
            %vr.wait4stop_SW = 0;%initialize the wait4stop stop watch
    
        end
        %if coin was flipped negative during start latency, keep flipping
        %coin for 2 sec
        if vr.reappear_flag == 0
            %display([vr.wait4reappear_SW vr.flippin_duringReappearWait])
            
            %flip coin for 2 sec
            if vr.wait4reappear_SW > vr.flippin_duringReappearWait && vr.flippin_duringReappearWait < 2.5
                %flip coin
                n=rand(1);
                if n < vr.freq_high_value
                    vr.track1_occur_or_not=1;
                else
                    vr.track1_occur_or_not=0;
                end
                m=rand(1);
                if m < vr.freq_low_value
                    vr.track2_occur_or_not=1;
                else
                    vr.track2_occur_or_not=0;
                end
                vr.flippin_duringReappearWait=vr.flippin_duringReappearWait+1;
                if vr.track1_occur_or_not ==1 && vr.track2_occur_or_not == 0
                    %track1 appears
                    vr.B=1;
                    vr.reappear_flag = 1;
                    vr.searchtime_duringReappearWait = vr.wait4reappear_SW;%how many seconds has passed by the time the coin was flipped positive
                    
                elseif vr.track1_occur_or_not==0 && vr.track2_occur_or_not == 1
                    %track2 appears
                    vr.B=2;
                    vr.reappear_flag = 1;
                    vr.searchtime_duringReappearWait = vr.wait4reappear_SW;%how many seconds has passed by the time the coin was flipped positive
                    
                elseif vr.track1_occur_or_not == 1 && vr.track2_occur_or_not == 1
                    %flip another coin
                    l=rand(1);
                    if l < vr.freq_low_value/(vr.freq_high_value + vr.freq_low_value)
                        vr.track2_occur_or_not = 1;
                        vr.track1_occur_or_not = 0;
                        vr.B=2;
                        vr.reappear_flag = 1;
                        vr.searchtime_duringReappearWait = vr.wait4reappear_SW;%how many seconds has passed by the time the coin was flipped positive
                        
                    else
                        vr.track2_occur_or_not = 0;
                        vr.track1_occur_or_not = 1;
                        vr.B=1;
                        vr.reappear_flag = 1;
                        vr.searchtime_duringReappearWait = vr.wait4reappear_SW;%how many seconds has passed by the time the coin was flipped positive
                        
                    end
                    
                else
                    
                    %track does not appear in this sec, keep flipping the coin
                    if vr.toggle_flag==1
                        disp('seconds passed flippin_duringReappearWait')
                        disp(vr.flippin_duringReappearWait)
                    end
                    %if 2 sec has passed without positive coin, go to search
                    %time
                    
                end
            elseif vr.wait4reappear_SW > 2 && vr.reappear_flag == 0
                vr.ITI=3;
                vr.searchtime_duringReappearWait = vr.wait4reappear_SW;%how many seconds has passed by the time the coin was flipped positive
                vr.searchtime_SW = vr.searchtime_duringSL + vr.searchtime_duringReappearWait;

                vr.flippin_duringITI_SW = 0;
                
            end
        end
        %%%%%%%
        
        if vr.B==1
            vr.A=4;
        elseif vr.B==2
            vr.A=2;
        end
        %end
        %%%%%%
        
        vr.flippin_duringITI=1;%initialize the flippin count during ITI
        vr.plotAI=1; % plot analog input from previous trial
    end
    
    vr.ITI_SW = vr.ITI_SW + vr.dt;
    
    %% 3: waiting before eligible to start new trial
    if vr.ITI==3 && vr.reappear_flag==0
        
        %vr.searchtime=vr.searchtime_duringSL + vr.searchtime_duringReappearWait;
        vr.searchtime_SW = vr.searchtime_SW + vr.dt;% add time passed to the search time SW
        vr.flippin_duringITI_SW = vr.flippin_duringITI_SW + vr.dt;
        if vr.wait4stop > 0 % begin next ITI if do not need to wait for stop, otherwise initialize speed queue
            %reset speed queue to detect mouse stop
            vr.spd_circ_queue_stop= ones(vr.queue_len_stop, 1);%initialize the speed queue
            vr.queue_indx_stop = 1;% initialize the speed queue index
            vr.wait4stop_SW = 0;%initialize the wait4stop stop watch
        end
        
        if vr.flippin_duringITI_SW > vr.flippin_duringITI
            %flip coin
            n=rand(1);
            if n < vr.freq_high_value
                vr.track1_occur_or_not=1;
            else
                vr.track1_occur_or_not=0;
            end
            m=rand(1);
            if m < vr.freq_low_value
                vr.track2_occur_or_not=1;
            else
                vr.track2_occur_or_not=0;
            end
            vr.flippin_duringITI = vr.flippin_duringITI + 1;
            if vr.track1_occur_or_not ==1 && vr.track2_occur_or_not == 0
                %track1 appears
                vr.B=1;
                vr.ITI=4;
                vr.sound_flag = 1;
                %vr.wait4stop_SW = 0;%initialize the wait4stop stop watch
                
            elseif vr.track1_occur_or_not==0 && vr.track2_occur_or_not == 1
                %track2 appears
                vr.B=2;
                vr.ITI=4;
                vr.sound_flag = 1;
                %vr.wait4stop_SW = 0;%initialize the wait4stop stop watch
                
            elseif vr.track1_occur_or_not == 1 && vr.track2_occur_or_not == 1
                %flip another coin
                l=rand(1);
                if l < vr.freq_low_value/(vr.freq_high_value + vr.freq_low_value)
                    vr.track2_occur_or_not = 1;
                    vr.track1_occur_or_not = 0;
                    vr.B=2;
                    vr.ITI=4;
                    vr.sound_flag = 1;
                    %vr.wait4stop_SW = 0;%initialize the wait4stop stop watch
                    
                else
                    vr.track2_occur_or_not = 0;
                    vr.track1_occur_or_not = 1;
                    vr.B=1;
                    vr.ITI=4;
                    vr.sound_flag = 1;
                    %vr.wait4stop_SW = 0;%initialize the wait4stop stop watch
                end
                if vr.ITI==4
                    vr.sound_flag = 1;
                    %vr.wait4stop_SW = 0;%initialize the wait4stop stop watch
                end
                
            else
                %track does not appear in this sec, keep flipping the coin
            end
            if vr.toggle_flag==1
                disp('seconds passed flippin_duringITI')
                disp(vr.flippin_duringITI)
            end
        end
        %%%%%%%
        
        if vr.B==1
            vr.A=4;
        elseif vr.B==2
            vr.A=2;
        end
    end
    
    %% 4: waiting for mouse to stop if required to start new trial
    if vr.ITI==4
%         if vr.abort_flag ==1
%             %display(vr.searchtime_duringSL);
%             %display(vr.searchtime_duringReappearWait)
%             %vr.searchtime_SW = vr.searchtime_duringSL + vr.searchtime_duringReappearWait;
%             vr.abort_flag =0;
%         end
        
        if vr.ITI_SW >= vr.wait4reappear_CRIT || (vr.wait4reappear_SW >= vr.wait4reappear_CRIT && vr.reappear_SW_turnedON == 1)
            %deliver sound to let the mouse know that the search time is
            %over and they are eligible to start a new trial as soon as
            %they stop running
            %deliver sound only once when the search time is voer
            if vr.sound_flag == 1
                vr.sound_flag = 0;
                if ~vr.debugMode
                    if vr.daq_flag == 1
                        out_data = vr.sound_outdata;
                        putdata(vr.ao, out_data);
                        start(vr.ao);
                        trigger(vr.ao);
                        disp('sound output3')
                        vr.spd_circ_queue_stop= 2*ones(vr.queue_len_stop, 1);%initialize the speed queue so that there is at least .5 sec delay between the sound and the new track appearing
                    end
                end
            end
            vr.wait4stop_SW = vr.wait4stop_SW + vr.dt; % add elapsed time to stopwatch
            vr.spd_circ_queue_stop( vr.queue_indx_stop) = vr.dp_cache(:,2); % add current speed to queue
            vr.queue_indx_stop = vr.queue_indx_stop + 1; % move to next spot in queue
            
            if vr.queue_indx_stop > vr.queue_len_stop % start over beginning of queue if at the end
                vr.queue_indx_stop = 1;
            end
             
            
            
            
            % MOUSE STOPPED
            % if the speed is under the stop criteria
            if nanmax(vr.spd_circ_queue_stop(~isnan(vr.spd_circ_queue_stop))) < vr.STOP_CRIT
                disp('mouse stopped')
                vr.okNewTrial=1;%make the new trial flag to postivie
                vr.wait4stop_times = [vr.wait4stop_times vr.wait4stop_SW];%store the time that the mouse took to stop
                median_wait4stop = median(vr.wait4stop_times); display(median_wait4stop)
            end
        end
    end
    
    %%
    %if it is okay to start a new trial
    if vr.okNewTrial==1
        %display the previous trial reward
        if isempty(vr.rewTrials{vr.B})
            prevRew=0;
        else
            if vr.rewTrials{vr.B}(end)>0
                prevRew=vr.A;
            else
                prevRew=0;
            end
        end

        %dispalay the content of next trial
        okNewTrial_time_tNum_tType = [now vr.trialNum vr.CBA]; display(okNewTrial_time_tNum_tType)
        vr.position(2) = vr.startLocation;
        
        %increment trial number
        vr.trialNum = vr.trialNum + 1;
        
        %dispalay the content of next trial
        vr.CBA = vr.A + vr.B*10 + vr.C*100;
        currentCBA = vr.CBA; display(currentCBA);
        
        %if changing the distance based on the prog ratio
        if vr.progRatio_flag == 1
            vr.progRatio=vr.progRatioStart+floor(vr.trialNum/20);
            if vr.progRatio > 9
                vr.progRatio=9;
            end
            vr.short_distance = vr.progRatio_short_Dist(vr.progRatio);
            vr.long_distance = vr.progRatio_long_Dist(vr.progRatio);
        end
        % make tracks appear, move into place
        disp('tracks appear')
        switch vr.B
            case 1
                vr.currTrack_ID=1;
                vr.rewLocation = vr.short_distance;
            case 2
                vr.currTrack_ID=2;
                vr.rewLocation = vr.long_distance;
        end
        vr.worlds{vr.currentWorld}.surface.colors(4,vr.trackIndx{vr.currTrack_ID}) = vr.brightness;
        vr.worlds{vr.currentWorld}.surface.vertices(3,vr.trackIndx{vr.currTrack_ID}) = vr.track_zOrig{vr.currTrack_ID};
        vr.atStartLocation = 1;
        
        vr.event_newTrial=1;
        vr.okNewTrial=0;
        vr.ITI=0;
        vr.abort_flag=0;
        vr.start_flag=0;
        vr.flippin_duringSL = 1;
        
        vr.startTrial_SW = 0;%reset the start trial SW
        vr.waiting4start = 1;% whether the current state is waiting for the mouse to start running for engagement
        vr.flipping = 1;%if it is okay to flip or not (1:flip, 0:don't flip)
        
        vr.trialTimer_On=1;
        vr.trialTimer_SW=0; % reset trial timer
        vr.reappear_flag=0;
        
        vr.searchtime_duringSL = 0;
        vr.searchtime_duringReappearWait=0;
        
        %reset start speed queue to detect mouse start
        vr.spd_circ_queue_start=zeros(vr.queue_len_start,1);
        
        %save the current CBA because CBA may be updated when coin flipped
        %postive
        vr.currentA=vr.A;
        vr.currentB=vr.B;
        vr.currentC=vr.C;
        if vr.env_change_flag==1
            if vr.sessionTimer_SW < vr.change_timing
                vr.freq_high_value = vr.before_change_freq_high_value;
            else
                vr.changed_or_not_yet_flag = vr.changed_or_not_yet_flag + 1;
                vr.freq_high_value = vr.after_change_freq_high_value;
            end
        end
        if vr.changed_or_not_yet_flag == 1 % when the env changes, store the trial number and the time of the changing timing
            disp('environment change');

            vr.trialNum_change_timing = vr.trialNum;
            vr.trialNum_in_track1_change_timing = length(vr.rewTrials{1}) + 1;
            vr.trialNum_in_track2_change_timing = length(vr.rewTrials{2}) + 1;
            vr.time_change_timing = vr.sessionTimer_SW;
        end
    end
end

%% Deliver Reward
if vr.rewEarned > 0
    currRew = vr.rewEarned;
    vr.rewEarned = 0; %reset
    vr.lastRewEarned = datestr(rem(now,1));
    vr.plot_SW =0;
    switch currRew
        case 2
            vr.totalWater = vr.totalWater + vr.onSm_h2o;% add how much water the mouse get this time, to the total water
            SmRewEarned = vr.totalWater; display(SmRewEarned);% show how much water the mouse got so far in total
            if ~vr.debugMode
                disp('outdata onSm');
                out_data = vr.onSm_outdata;
                if vr.daq_flag == 1
                    putdata(vr.ao, out_data);%send reward event signal and reward valve signal to DAQ
                    start(vr.ao);
                    trigger(vr.ao);
                end
                
            end
            
        case 4
            vr.totalWater = vr.totalWater + vr.onLg_h2o;% add how much water the mouse get this time, to the total water
            LgRewEarned = vr.totalWater; display(LgRewEarned);% show how much water the mouse got so far in total
            if ~vr.debugMode
                disp('outdata onLg');
                out_data = vr.onLg_outdata;
                if vr.daq_flag == 1
                    putdata(vr.ao, out_data);%send reward event signal and reward valve signal to DAQ
                    start(vr.ao);
                    trigger(vr.ao);
                end
            end
            
    end
end

%% Keypress commands
x = vr.keyPressed;
if isnan(x) ~= 1
    switch x
        case vr.dispWater %'w'
            disp('last rew earned: ');
            display(vr.lastRewEarned);
            disp('total water');
            display(vr.totalWater);
            
        case vr.dispHistory % 'e'
            wait4stop_times = vr.wait4stop_times; display(wait4stop_times);
            
            tData = round(vr.preyData);
            display(tData)
            
            rews_trials_water = [sum(vr.rewTrials{1})+sum(vr.rewTrials{2}) tData(end,1) vr.totalWater];
            display(rews_trials_water)
            
        case vr.dispStartTime %'q'
            start_last_end = ['start:' vr.startTime ' lastRew:' vr.lastRewEarned ' curr:' datestr(rem(now,1))];
            display(start_last_end);
            
        case vr.dispToggle %'t'
            if vr.toggle_flag ==0
                vr.toggle_flag = 1;
            elseif vr.toggle_flag ==1
                vr.toggle_flag = 0;
            end
        case vr.dispStats %'r'
            
            %iTrialType=1;
            median_engageLatency=[];
            if ~isempty(vr.rewTrials{1}) && ~isempty(vr.rewTrials{2})
                vr.percentRew_1 = [sum(vr.rewTrials{1})/length(vr.rewTrials{1})];
                vr.median_engageLatency_1=median(vr.engageLatency{1});
                vr.percentRew_2 = [sum(vr.rewTrials{2})/length(vr.rewTrials{2})];
                vr.median_engageLatency_2=median(vr.engageLatency{2});
                overall_percentRew=[vr.percentRew_1 vr.percentRew_2]; display(overall_percentRew);
                overall_median_engage_latency=[vr.median_engageLatency_1 vr.median_engageLatency_2]; display(overall_median_engage_latency);
            end
            
            if vr.wait4stop>0
                overall_median_wait4stop = median(vr.wait4stop_times);
                display(overall_median_wait4stop)
                
            end
            
            if vr.env_change_flag ==1 && vr.trialNum_change_timing > 1 && ~isempty(vr.rewTrials{1}) && ~isempty(vr.rewTrials{2}) && vr.changed_or_not_yet_flag > 1
                
                switchFromTo = [vr.before_change_freq_high_value vr.after_change_freq_high_value]; display(switchFromTo)
                
                display(vr.trialNum_in_track1_change_timing)
                
                display(vr.trialNum_in_track2_change_timing)
                
                percent_before_after_track1 = [sum(vr.rewTrials{1}(1:vr.trialNum_in_track1_change_timing-1))/length(vr.rewTrials{1}(1:vr.trialNum_in_track1_change_timing-1)) sum(vr.rewTrials{1}(vr.trialNum_in_track1_change_timing:end))/length(vr.rewTrials{1}(vr.trialNum_in_track1_change_timing:end))];
                
                percent_before_after_track2 = [sum(vr.rewTrials{2}(1:vr.trialNum_in_track2_change_timing-1))/length(vr.rewTrials{2}(1:vr.trialNum_in_track2_change_timing-1)) sum(vr.rewTrials{2}(vr.trialNum_in_track2_change_timing:end))/length(vr.rewTrials{2}(vr.trialNum_in_track2_change_timing:end))];

                context1_percentRew = [percent_before_after_track1(1) percent_before_after_track2(1)];display(context1_percentRew)
                context2_percentRew = [percent_before_after_track1(2) percent_before_after_track2(2)];display(context2_percentRew)
            end
            
    end
end

if vr.event_newTrial > 0 % sent AO signal for new trial signaling trial type
    vr.event_newTrial = 0;
    
    disp('event_newTrial');
    
    out_data = vr.event_newTrial_outdata{vr.B}{vr.A};
    if vr.changed_or_not_yet_flag == 1 % when the env changes, store the trial number and the time of the changing timing
        disp('environment change');
        out_data=[zeros(10,1) (-(vr.A+.5))*ones(10,1) zeros(10,1) zeros(10,1)];
    end
    if vr.daq_flag == 1
        putdata(vr.ao, out_data);
        start(vr.ao);
        trigger(vr.ao);
    end
end
if vr.daq_flag==1
    vr.plot_SW = vr.plot_SW + vr.dt;
    if vr.plotAI>0 && vr.plot_SW > 2% plot relevant data from analog input from previous trial 2 sec after reward
        vr.plotAI=0;
        data = peekdata(vr.ai, min([vr.ai.SamplesAvailable*1.02 vr.SR * 20])); % 1000 * 8
        data_temp=data;
        data_temp(:,1)=-5*(data_temp(:,1)-repmat(idle_voltage_offset(1),[length(data_temp(:,1)),1]));
        plot(data_temp(:,1:4)); % plot analog input
        flushdata(vr.ai, 'all');
    end
end

%% --- TERMINATION code: executes after the ViRMEn engine stops.
function vr = terminationCodeFun(vr)
global idle_voltage_offset
if vr.daq_flag == 1
    if ~vr.debugMode
        fclose all;
        putvalue(vr.dio.Line(2), 0);
        stop(vr.ai);
    end
end
endTime = datestr(rem(now,1));

mID = vr.mouseID; display(mID);
start_last_end = ['start:' vr.startTime ', lastRew:' vr.lastRewEarned ', end:' endTime];
display(start_last_end);
summary.mID = mID; summary.start_last_end = start_last_end;

tData = vr.preyData;

rews_trials_water = [sum(vr.rewTrials{1})+sum(vr.rewTrials{2}) tData(end,1) vr.totalWater];
summary.rews_trials_water = rews_trials_water; display(rews_trials_water)


%display and store


iTrialType=1;
median_engageLatency=[];
while iTrialType<=2 && ~isempty(vr.rewTrials{iTrialType})
    percentRew = [iTrialType sum(vr.rewTrials{iTrialType})/length(vr.rewTrials{iTrialType})];
    summary.percentRew(iTrialType) = sum(vr.rewTrials{iTrialType})/length(vr.rewTrials{iTrialType});
    median_engageLatency_per_track=[iTrialType median(vr.engageLatency{iTrialType})];
    summary.median_engageLatency(iTrialType)=median(vr.engageLatency{iTrialType});
    iTrialType=iTrialType+1;
    
end

if ~isempty(vr.rewTrials{1}) && ~isempty(vr.rewTrials{2})
    overall_percentRew=[summary.percentRew(1) summary.percentRew(2)]; display(overall_percentRew);
    overall_median_engage_latency=[summary.median_engageLatency(1) summary.median_engageLatency(2)]; display(overall_median_engage_latency);
end

if vr.wait4stop>0
    overall_median_wait4stop = median(vr.wait4stop_times);
    summary.median_wait4stop=overall_median_wait4stop; display(overall_median_wait4stop)
    
end

if vr.env_change_flag ==1 && vr.trialNum_change_timing > 1 && ~isempty(vr.rewTrials{1}) && ~isempty(vr.rewTrials{2}) && vr.changed_or_not_yet_flag > 1
    
    switchFromTo = [vr.before_change_freq_high_value vr.after_change_freq_high_value]; display(switchFromTo)
    
    percent_before_after_track1 = [sum(vr.rewTrials{1}(1:vr.trialNum_in_track1_change_timing-1))/length(vr.rewTrials{1}(1:vr.trialNum_in_track1_change_timing-1)) sum(vr.rewTrials{1}(vr.trialNum_in_track1_change_timing:end))/length(vr.rewTrials{1}(vr.trialNum_in_track1_change_timing:end))];
    summary.percent_before_after_track1 = [sum(vr.rewTrials{1}(1:vr.trialNum_in_track1_change_timing-1))/length(vr.rewTrials{1}(1:vr.trialNum_in_track1_change_timing-1)) sum(vr.rewTrials{1}(vr.trialNum_in_track1_change_timing:end))/length(vr.rewTrials{1}(vr.trialNum_in_track1_change_timing:end))];
    
    percent_before_after_track2 = [sum(vr.rewTrials{2}(1:vr.trialNum_in_track2_change_timing-1))/length(vr.rewTrials{2}(1:vr.trialNum_in_track2_change_timing-1)) sum(vr.rewTrials{2}(vr.trialNum_in_track2_change_timing:end))/length(vr.rewTrials{2}(vr.trialNum_in_track2_change_timing:end))];
    summary.percent_before_after_track2 = [sum(vr.rewTrials{2}(1:vr.trialNum_in_track2_change_timing-1))/length(vr.rewTrials{2}(1:vr.trialNum_in_track2_change_timing-1)) sum(vr.rewTrials{2}(vr.trialNum_in_track2_change_timing:end))/length(vr.rewTrials{2}(vr.trialNum_in_track2_change_timing:end))];

    
    context1_percentRew = [percent_before_after_track1(1) percent_before_after_track2(1)];display(context1_percentRew)
    context2_percentRew = [percent_before_after_track1(2) percent_before_after_track2(2)];display(context2_percentRew)
end

answer = inputdlg({'mouse','Comment'},'Question',[1; 5]);
sessionDate = datestr(now,'yyyymmdd');

taskVars = vr;
save([vr.pathname '\' vr.filenameTaskVars '.mat'],'taskVars','-append');

stats = summary;
save([vr.pathname '\' vr.filenameStats '.mat'],'stats','-append');

trials = vr.preyData;
save([vr.pathname '\' vr.filenameTrials '.mat'],'trials','-append');

if ~isempty(answer)
    comment = answer{2};
    save([vr.pathname '\' vr.filenameExper '.mat'],'comment','-append')
    if ~exist([vr.pathname '\' answer{1}],'dir')
        mkdir([vr.pathname '\' answer{1}]);
    end
    if ~exist([vr.pathname '\' answer{1} '\' sessionDate],'dir')
        mkdir([vr.pathname '\' answer{1} '\' sessionDate]);
    else
        sessionDate = datestr(now,'yyyymmdd_HHMM');
        mkdir([vr.pathname '\' answer{1} '\' sessionDate]);
    end
    
    movefile([vr.pathname '\' vr.filenameTrials '.mat'],[vr.pathname '\' answer{1} '\' sessionDate '\Trials',datestr(now,'mmdd'),'.mat']);
    movefile([vr.pathname '\' vr.filenameExper '.mat'],[vr.pathname '\' answer{1} '\' sessionDate '\Exper',datestr(now,'mmdd'),'.mat']);
    movefile([vr.pathname '\' vr.filenameTaskVars '.mat'],[vr.pathname '\' answer{1} '\' sessionDate '\TaskVars',datestr(now,'mmdd'),'.mat']);
    movefile([vr.pathname '\' vr.filenameStats '.mat'],[vr.pathname '\' answer{1} '\' sessionDate '\Stats',datestr(now,'mmdd'),'.mat']);
    
    %move daq file from temp folder
    daqPath = 'C:\VirmenDataTmp';
    daqDir = dir('C:\VirmenDataTmp');
    if vr.daq_flag == 1
        movefile([daqPath '\' daqDir(end).name],[vr.pathname '\' answer{1} '\' sessionDate '\DaqData',datestr(now,'mmdd'),'.daq']);
    end
end
