% **** NEED TO CALIBRATE 6uL REWARD VALVE OPENING TIME *****
%coin heads: prey will presented, coin tails: prey will not presented

function code = prey_model_w_daq

% xForaging   Code for the ViRMEn experiment xForaging.
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
vr.currTrack_ID=1;

vr.trialTimer_SW=0;
vr.trialTimer_On=0;

%in the beginning of session, start vr.ITI=3 so that it starts with
%flipping coin
vr.ITI=3; % set to 1 to start ITI and 2 while remaining in ITI, 0 is ITI off
vr.searchtime_SW = 0;
vr.p=0;
vr.reappear_flag=0;
vr.ITI_SW=0; % stopwatch for ITI
vr.ITI_duration=1; % duration for ITI (value re-drawn each trial)
% default ITI parameters (set custom per mouse otherwise) - drawn from a
% psuedo-normal distribution

vr.startTrial_SW = 0; % keep track of how long mouse takes to start trial after track appears
vr.wait4reappear_SW = 0;
vr.delay2disappear=.5; % delay until track disappears following reward
vr.delay2reappear = 2; %delay until the next track appears when the coin is flipped heads

vr.engagingSW = 0;
vr.waiting4start =0;
if vr.debugMode % set to 'true' in ViRMEn GUI when debugging on the rig to set all means (ITI, distance, etc) to low values for quicker debugging
    disp('DEBUG MODE RUNNING')
end
%%
if ~vr.debugMode
    disp('daqreset')
    if vr.daq_flag == 1
        daqreset %reset DAQ in case it's still in use by a previous Matlab program
        VirMenInitDAQ_noLaser;
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
vr.indx_track{3} = vr.worlds{vr.currentWorld}.objects.indices.mainFloor1_bright;
vr.indx_track{4} = vr.worlds{vr.currentWorld}.objects.indices.mainFloor1B_bright;
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

vr.totalWater = 0; % keep track of water earned
vr.preyData=[]; % trialNum, trialType, rewEarned, rewLocation, endLocation, trialTime
vr.trialNum = 1;
vr.RewSize = 0;
vr.lastRewEarned = [];

vr.trackLength = eval(vr.exper.variables.floor1height);

%% KEYPRESS COMMANDS
vr.dispStartTime = 81; %'q'
vr.dispWater = 87; %'w'
vr.dispHistory = 69; %'e'
%65; %'a'
vr.dispWhatever = 82; %'r'
vr.toggleDisp = 84; %'t'; *toggles dispSet value 0,1,2
vr.dispSet = 0; %value for low(0), med(1), or high(2) amount of printing for debugging
%';' = 59
% 'u'= 85

% number of cell = vr.B (which determines track # for trial type)
vr.rewTrials{1}=[]; % concatenate a 1 for rew trial, 0 for unrew
vr.rewTrials{2}=[];


vr.rewEarned = 0; % set to value for rew size when reward is earned
vr.atStartLocation = 1; % 0 = onTrack, 1 = at start location

vr.wait4stop=0; % set to positive value to require mouseStop to initiate new trial
vr.okNewTrial=0; % start new trial after ITI or after ITI + mouseStopped

vr.wait4stop_SW=0; % keep track of how long it takes mouse to stop after required ITI duration has passed
vr.wait4stop_times = [];

%defaults
vr.STOP_CRIT = 0.025; %default
vr.queue_len_stop = 30; % default to ~0.5 seconds, make ~1 second later after mouse has learned to stop
vr.spd_circ_queue_stop= ones(vr.queue_len_stop, 1); % make cue array to cycle through
vr.queue_indx_stop = 1; % indx to cycle through the queue
vr.queue_len_start=60;
vr.spd_circ_queue_start=zeros(vr.queue_len_start,1);
vr.start_queue_indx=1;

if vr.debugYurika == 0
    vr.handling_time{1}=15;
    vr.handling_time{2}=30;
    
    vr.lambda_1A = 1/60;
    vr.lambda_1B = 1/30;
    vr.lambda_1C = 1/15;
    vr.lambda_2 = 1/30;
else
    vr.handling_time{1}=2;
    vr.handling_time{2}=4;
end
vr.p=0;
vr.q=0;
vr.r=0;
vr.plotAI=0; % plots analog input
vr.wait4reappear_CRIT = 2;
vr.engageLatency = 0;

%% event signals to send to DAQ board
vr.event_engageTrial_outdata=[zeros(10,1) 0.5*ones(10,1)];
vr.event_abortTrial_outdata=[zeros(10,1) -2*ones(10,1)];% upon abort trial, signal negative voltage to DAQ - change value to 1 to trigger
vr.event_newTrial=0; % when track appears, signal trial type w A.B mV for later readout of trialtype from DAQ file
for iA = 1:6
    for iB = 1:9
        vr.event_newTrial_outdata{iB}{iA} = [zeros(10,1) ((iA+.1*iB)/2)*ones(10,1)];
    end
end

vr.progRatio=0; % set > 0 if using progressive ratio for rews
vr.progRatioStart = 0;
vr.progRatio_short_Dist = [20 30 40 50 60 70 80 90 100];
vr.progRatio_long_Dist = 2*vr.progRatio_short_Dist;
switch vr.mouseID
    case 1
        disp('mouse #1: obiwan');
        vr.progRatio=1; % set > 0 if using progressive ratio for rews
        vr.taskType_ID = [2 4]; % [2 4] track 1 = big reward short distance, track 2 = small reward long distance
        
        vr.wait4stop=1;%0: if do not need to wait for stop, 1: if they need to stop to initiate the new trial
        vr.STOP_CRIT = 0.06;
        vr.START_CRIT = 0.1;
        vr.queue_len_stop = 30; % begin training w ~.5s, then increase to 1s after learned to stop (same as stop to abort trial)
        vr.queue_len_start=30;
        vr.spd_circ_queue_stop= ones(vr.queue_len_stop, 1);
        vr.spd_circ_queue_start= zeros(vr.queue_len_stop, 1);
        
        vr.start4engage = 1;%0: if do not need to start running to engage, 1: if they need to start running to engage
        vr.start_latency_CRIT = 5;%within how many seconds should they start running to engage with the trial
        
        vr.progRatioStart = 1;% 9:is the maximum and goal of the training
        if vr.debugYurika == 0
            vr.freq_high_value=vr.lambda_1B;
            vr.freq_low_value=vr.lambda_2;
        else
            vr.freq_high_value=1/4;
            vr.freq_low_value=1/4;
        end
        %vr.setSpeed = 10;
        vr.y_disposition = 0.15;
        
        vr.wait4reappear_CRIT=2;
        
        
    otherwise
        disp('error: MOUSE ID NOT RECOGNIZED');
end


vr.CBA = 0;
vr.A = 0; vr.B = 0; vr.C = 0;

vr.onLg_h2o = 4; vr.onSm_h2o = 2;
vr.LgRew = 25; vr.SmRew = 12.5;  %8-1-18 calibrated

%set rew valve open times
vr.SR = 1000;
vr.vSnd = 5 * ones(20*vr.SR,1); vr.vSnd(1:2:end) = vr.vSnd(1:2:end) * -1;
vr.iSndOff = floor(0.08 * vr.SR);
vr.vSnd(vr.iSndOff:end) = 0;

%water sizes (valve openings)
vr.onSm_outdata =  [5 * ones(floor(vr.SmRew/1000*vr.SR),1 ); zeros(1, 1)]; vr.onSm_outdata = [vr.onSm_outdata (4/5)*vr.onSm_outdata];
vr.onLg_outdata =  [5 * ones(floor(vr.LgRew/1000*vr.SR),1 ); zeros(1, 1)]; vr.onLg_outdata = [vr.onLg_outdata (4/5)*vr.onLg_outdata];

%sound
vr.sound = [5 * ones(floor(25/1000*vr.SR),1 ); zeros(1, 1)]; vr.sound = [vr.sound zeros(length(vr.sound),1)];

% if ~vr.debugMode
%     % start generating pulse by signaling to Arduino board
%     putvalue(vr.dio.Line(2), 1);
% end

mouseID = vr.mouseID; display(mouseID);
vr.progRatio = vr.progRatioStart;
vr.short_distance = vr.progRatio_short_Dist(vr.progRatio);
vr.long_distance = vr.progRatio_long_Dist(vr.progRatio);

%% move correct track into place, other away/disappear, initiate variables for must run, etc
vr.C = 3;

m=rand(1);
if m > 0.5
    vr.B=1;
    vr.A=4;
    vr.rewLocation = vr.short_distance;
else
    vr.B=2;
    vr.A=2;
    vr.rewLocation = vr.long_distance;
end
switch vr.B
    case 1
        vr.currTrack_ID=1; otherTrack=2; curr_brightTrack=3; other_brightTrack = 4;
        vr.currentA = 4; vr.currentB = 1;
    case 2
        vr.currTrack_ID=2; otherTrack=1; curr_brightTrack=4; other_brightTrack = 3;
        vr.currentA = 2; vr.currentB = 2;
end
vr.CBA = vr.A + vr.B*10 + vr.C*100;

vr.worlds{vr.currentWorld}.surface.colors(4,vr.trackIndx{vr.currTrack_ID}) = 0;
vr.worlds{vr.currentWorld}.surface.colors(4,vr.trackIndx{otherTrack}) = 0;
vr.worlds{vr.currentWorld}.surface.colors(4,vr.trackIndx{curr_brightTrack}) = 0;
vr.worlds{vr.currentWorld}.surface.colors(4,vr.trackIndx{other_brightTrack}) = 0;
vr.worlds{vr.currentWorld}.surface.vertices(3,vr.trackIndx{vr.currTrack_ID}) = vr.track_zOrig{vr.currTrack_ID}+60;
vr.worlds{vr.currentWorld}.surface.vertices(3,vr.trackIndx{otherTrack}) = vr.track_zOrig{otherTrack}+60;
vr.worlds{vr.currentWorld}.surface.vertices(3,vr.trackIndx{curr_brightTrack}) = vr.track_zOrig{curr_brightTrack}+60;
vr.worlds{vr.currentWorld}.surface.vertices(3,vr.trackIndx{other_brightTrack}) = vr.track_zOrig{other_brightTrack}+60;

vr.abort_flag = 0;
vr.start_flag = 0;
vr.occur_time=0;
vr.roll_flag = 1;

vr.flipping = 0;
%% DELIVER 2uL WATER TO START SESSION
if vr.daq_flag == 1
    if ~vr.debugMode
        if vr.daq_flag == 1
            out_data = vr.onLg_outdata;
            vr.totalWater = vr.totalWater + vr.onLg_h2o;
            
            putdata(vr.ao, out_data);
            disp('line278')
            start(vr.ao);
            trigger(vr.ao);
            
            display(datestr(now));
            
            [data, time, abstime] = getdata(vr.ai, vr.ai.SamplesAvailable*1.02);
            figure; plot(time, data(:, [2 3 4 5])); % plot analog input
        end
    end
end
%% --- RUNTIME code: executes on every iteration of the ViRMEn engine.
function vr = runtimeCodeFun(vr)

vr.dp_cache = vr.dp; % cache current velocity so value measured even if changed to zero
%constant speed from Mike's code
%vr.dp(2) = 0;

if vr.trialTimer_On>0
    vr.trialTimer_SW = vr.trialTimer_SW + vr.dt;
end

if vr.ITI==0 && vr.abort_flag ==0

    %output to speaker to make the cue sound
%     if ~vr.debugMode
%         if vr.daq_flag == 1
%             out_data = vr.sound;
%             putdata(vr.ao, out_data);
%             start(vr.ao);
%             trigger(vr.ao);
%         end
%     end
    %vr.velocity = [0 10 0 0]
    vr.dp=[0 0 0 0];
    vr.startTrial_SW = vr.startTrial_SW + vr.dt;
    vr.spd_circ_queue_start(vr.start_queue_indx) = vr.dp_cache(:,2); % add current speed to queue
    vr.start_queue_indx = vr.start_queue_indx + 1; % move to next spot in queue
    
    %disp(vr.waiting4start)
    if vr.start4engage == 1 && vr.waiting4start ==1
        %disp((vr.spd_circ_queue_start(~isnan(vr.spd_circ_queue_start))))
        if vr.start_flag==0 && nanmean(vr.spd_circ_queue_start(~isnan(vr.spd_circ_queue_start))) > vr.START_CRIT
            vr.waiting4start =0;
            disp('w=0')
            vr.start_flag=1;
            vr.engageLatency  = vr.trialTimer_SW;
            vr.engagingSW = 0;
            %vr.position(2) = vr.position(2) + vr.setSpeed*vr.dt;
            
            
        end

    end
    if  vr.start_flag > 0
        
        if vr.start_flag==1
            vr.start_flag=2;
            %engage event signal
            out_data=vr.event_engageTrial_outdata;
            vr.flipping = 0;
            if vr.daq_flag==1
                putdata(vr.ao, out_data);
                disp('line333')
                start(vr.ao);
                disp('line336')
                trigger(vr.ao);
            end
        end
        vr.dp=[0 vr.y_disposition 0 0];
        vr.engagingSW = vr.engagingSW + vr.dt;
    end
    if vr.start_queue_indx > vr.queue_len_start % start over beginning of queue if at the end
        vr.start_queue_indx = 1;
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%keep flipping the coin during the start latency
    if vr.startTrial_SW >= vr.q && vr.q < 5.5 && vr.flipping > 0
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
        vr.q = vr.q + 1;
        if vr.track1_occur_or_not ==1 && vr.track2_occur_or_not == 0
            %track1 appears
            vr.B=1;
            vr.reappear_flag=1;
            vr.wait4reappear_SW = 0;
            vr.r=0;
            vr.flipping = 0;
            disp('aaaa')
        elseif vr.track1_occur_or_not==0 && vr.track2_occur_or_not == 1
            %track2 appears
            vr.B=2;
            vr.reappear_flag=1;
            vr.wait4reappear_SW = 0;
            vr.r=0;
            vr.flipping = 0;
            
            disp('bbbb')
        elseif vr.track1_occur_or_not == 1 && vr.track2_occur_or_not == 1
            %flip another coin
            l=rand(1);
            if l < vr.freq_low_value/(vr.freq_high_value + vr.freq_low_value)
                vr.track2_occur_or_not = 1;
                vr.track1_occur_or_not = 0;
                vr.B=2;
                vr.reappear_flag=1;
                vr.wait4reappear_SW = 0;
                vr.r=0;
                vr.flipping = 0;
                
                disp('cccc')
            else
                vr.track2_occur_or_not = 0;
                vr.track1_occur_or_not = 1;
                vr.B=1;
                vr.reappear_flag=1;
                vr.wait4reappear_SW = 0;
                vr.r=0;
                vr.flipping = 0;
                
                disp('dddd')
            end
            
        else
            %track does not appear in this sec, keep flipping the coin
            
        end
        if vr.B==1
            vr.A=4;
        elseif vr.B==2
            vr.A=2;
        end
        disp('seconds passed q')
        disp(vr.q)
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%
    %% MOUSE DID NOT RUN, ABORT TRIAL
    %if vr.cantstopwontstop_queue_indx>(vr.cantstopwontstop_queue_len-1) && nanmax(vr.cantstopwontstop_queue(~isnan(vr.cantstopwontstop_queue))) < .05
    if vr.start4engage == 1
        if vr.start_flag == 0 && vr.startTrial_SW>vr.start_latency_CRIT && nanmax(vr.spd_circ_queue_start(~isnan(vr.spd_circ_queue_start))) < vr.START_CRIT
            disp('mouse aborted trial')
            vr.ITI=1.5; % *initialize ITI after abort trial
            vr.rewTrials{vr.B} = [vr.rewTrials{vr.B} 0]; % add zero for unrew trial
            vr.abort_flag = 1;
            vr.RewSize = 0;
            vr.engageLatency = 0;
            vr.spd_circ_queue_start=zeros(vr.queue_len_start,1);
            %abort event signal
            out_data=vr.event_abortTrial_outdata;
            if vr.daq_flag==1
                putdata(vr.ao, out_data);
                disp('line428')
                start(vr.ao);
                trigger(vr.ao);
            end
            
        end
    else
    end
    %% reward earned: switch to ITI
    if vr.start_flag > 0 && vr.engagingSW >= vr.handling_time{vr.currentB}
        disp('position > rewLocation')
        vr.ITI = 0.5;
        vr.flipping = 1;
        vr.reappear_flag=0;
    end
end

if vr.ITI == 0.5
    disp('ITI=0.5')
    vr.dp=[0 0 0 0];
    %make the track brighter to let the mouse know this is the goal
    vr.worlds{vr.currentWorld}.surface.colors(4,vr.trackIndx{vr.currTrack_ID}) = 0;
    vr.worlds{vr.currentWorld}.surface.colors(4,vr.trackIndx{vr.currTrack_ID+2}) = 1;
    vr.worlds{vr.currentWorld}.surface.vertices(3,vr.trackIndx{vr.currTrack_ID}) = vr.track_zOrig{vr.currTrack_ID}+60;
    vr.worlds{vr.currentWorld}.surface.vertices(3,vr.trackIndx{vr.currTrack_ID+2}) = vr.track_zOrig{vr.currTrack_ID+2};
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
        vr.ITI_SW = 0 - vr.dt; % initialize SW to -vr.dt because adding vr.dt to SW later this same iteration
        vr.ITI=2; % run next block after 'delay2disappear' time has elapsed
    elseif vr.ITI==1.5 % initialize after aborted trial
        disp('ITI=1.5')
        vr.ITI_SW = 0 - vr.dt; % initialize SW to -vr.dt because adding vr.dt to SW later this same iteration
        vr.ITI=2.5;
    end
    
    %% track disappears following delay after reward(ITI=2) or immediately after aborted trial(ITI=2.5)
    if (vr.ITI==2 && vr.ITI_SW >= vr.delay2disappear) || vr.ITI==2.5
        disp('ITI=2 or 2.5')
        vr.ITI=3;
        % make track(s) disappear
        vr.worlds{vr.currentWorld}.surface.colors(4,vr.trackIndx{1}) = 0;
        vr.worlds{vr.currentWorld}.surface.colors(4,vr.trackIndx{2}) = 0;
        vr.worlds{vr.currentWorld}.surface.colors(4,vr.trackIndx{3}) = 0;
        vr.worlds{vr.currentWorld}.surface.colors(4,vr.trackIndx{4}) = 0;
        vr.worlds{vr.currentWorld}.surface.vertices(3,vr.trackIndx{1}) = vr.track_zOrig{1}+60;
        vr.worlds{vr.currentWorld}.surface.vertices(3,vr.trackIndx{2}) = vr.track_zOrig{2}+60;
        vr.worlds{vr.currentWorld}.surface.vertices(3,vr.trackIndx{3}) = vr.track_zOrig{3}+60;
        vr.worlds{vr.currentWorld}.surface.vertices(3,vr.trackIndx{4}) = vr.track_zOrig{4}+60;
        %%%%%%%
        vr.searchtime_SW = 0;
        vr.p=0;
        vr.plotAI=1; % plot analog input from previous trial
    end
    
    vr.ITI_SW = vr.ITI_SW + vr.dt;
    %% 3: waiting before eligible to start new trial
    if vr.ITI==3 && vr.reappear_flag==0
        
        vr.searchtime_SW = vr.searchtime_SW + vr.dt;
        if vr.wait4stop > 0 % begin next ITI if do not need to wait for stop, otherwise initialize speed queue
        
            %reset speed queue to detect mouse stop
            vr.spd_circ_queue_stop= ones(vr.queue_len_stop, 1);
            vr.queue_indx_stop = 1;
            %disp('stop-speed queue initialized');
            %vr.wait4stop_SW = 0 - vr.dt; % initialize SW below zero
            %because will add vr.dt back same iteration below??????
            vr.wait4stop_SW = 0;
        end
        
        if vr.ITI_SW > vr.p
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
            vr.p = vr.p + 1;
            if vr.track1_occur_or_not ==1 && vr.track2_occur_or_not == 0
                %track1 appears
                vr.B=1;
                vr.ITI=4;
            elseif vr.track1_occur_or_not==0 && vr.track2_occur_or_not == 1
                %track2 appears
                vr.B=2;
                vr.ITI=4;
            elseif vr.track1_occur_or_not == 1 && vr.track2_occur_or_not == 1
                %flip another coin
                l=rand(1);
                if l < vr.freq_low_value/(vr.freq_high_value + vr.freq_low_value)
                    vr.track2_occur_or_not = 1;
                    vr.track1_occur_or_not = 0;
                    vr.B=2;
                    vr.ITI=4;
                else
                    vr.track2_occur_or_not = 0;
                    vr.track1_occur_or_not = 1;
                    vr.B=1;
                    vr.ITI=4;
                end
                
            else
                %track does not appear in this sec, keep flipping the coin
                
            end
            disp('seconds passed p')
            disp(vr.p)
            
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
        if vr.ITI_SW >= vr.wait4reappear_CRIT || vr.wait4reappear_SW >= vr.wait4reappear_CRIT
            vr.wait4stop_SW = vr.wait4stop_SW + vr.dt; % add elapsed time to stopwatch
            vr.spd_circ_queue_stop( vr.queue_indx_stop) = vr.dp_cache(:,2); % add current speed to queue
            vr.queue_indx_stop = vr.queue_indx_stop + 1; % move to next spot in queue
            
            if vr.queue_indx_stop > vr.queue_len_stop % start over beginning of queue if at the end
                vr.queue_indx_stop = 1;
            end
            
            % MOUSE STOPPED
            if nanmax(vr.spd_circ_queue_stop(~isnan(vr.spd_circ_queue_stop))) < vr.STOP_CRIT
                disp('mouse stopped')
                vr.okNewTrial=1;
                vr.wait4stop_times = [vr.wait4stop_times vr.wait4stop_SW];
                median_wait4stop = median(vr.wait4stop_times); display(median_wait4stop)
            end
        end
    end
    if vr.reappear_flag==1 && vr.abort_flag == 1
        vr.reappear_flag = 0;
        % make track(s) disappear
        vr.worlds{vr.currentWorld}.surface.colors(4,vr.trackIndx{1}) = 0;
        vr.worlds{vr.currentWorld}.surface.colors(4,vr.trackIndx{2}) = 0;
        vr.worlds{vr.currentWorld}.surface.colors(4,vr.trackIndx{3}) = 0;
        vr.worlds{vr.currentWorld}.surface.colors(4,vr.trackIndx{4}) = 0;
        vr.worlds{vr.currentWorld}.surface.vertices(3,vr.trackIndx{1}) = vr.track_zOrig{1}+60;
        vr.worlds{vr.currentWorld}.surface.vertices(3,vr.trackIndx{2}) = vr.track_zOrig{2}+60;
        vr.worlds{vr.currentWorld}.surface.vertices(3,vr.trackIndx{3}) = vr.track_zOrig{3}+60;
        vr.worlds{vr.currentWorld}.surface.vertices(3,vr.trackIndx{4}) = vr.track_zOrig{4}+60;
        vr.wait4reappear_SW = vr.wait4reappear_SW + vr.dt;% add elapsed time to stopwatch
        if vr.wait4reappear_SW > vr.r && vr.r < 2.5
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
            if vr.track1_occur_or_not ==1 && vr.track2_occur_or_not == 0
                %track1 appears
                vr.B=1;
                vr.ITI=4;
            elseif vr.track1_occur_or_not==0 && vr.track2_occur_or_not == 1
                %track2 appears
                vr.B=2;
                vr.ITI=4;
            elseif vr.track1_occur_or_not == 1 && vr.track2_occur_or_not == 1
                %flip another coin
                l=rand(1);
                if l < vr.freq_low_value/(vr.freq_high_value + vr.freq_low_value)
                    vr.track2_occur_or_not = 1;
                    vr.track1_occur_or_not = 0;
                    vr.B=2;
                    vr.ITI=4;
                else
                    vr.track2_occur_or_not = 0;
                    vr.track1_occur_or_not = 1;
                    vr.B=1;
                    vr.ITI=4;
                end
                
            else
                vr.r=vr.r+1;
                %track does not appear in this sec, keep flipping the coin
                disp('seconds passed r')
                disp(vr.r)
                
            end
            if vr.wait4reappear_SW > 2
                vr.ITI=4;
            end
            
        end
        %%%%%%%
        
        if vr.B==1
            vr.A=4;
        elseif vr.B==2
            vr.A=2;
        end
    end
    %%
    if vr.okNewTrial==1
        if isempty(vr.rewTrials{vr.B})
            prevRew=0;
        else
            if vr.rewTrials{vr.B}(end)>0
                prevRew=vr.A; testingif_vrA_or_1v0=prevRew; display('testingif_vrA_or_1v0')
            else
                prevRew=0;
            end
        end
        % concatenate data from previous data to vr.preyData
        
        preyData_newLine = [vr.trialNum vr.CBA vr.RewSize vr.engageLatency vr.wait4stop_SW vr.searchtime_SW];
        display(preyData_newLine)
        vr.preyData  = [vr.preyData ; vr.trialNum vr.CBA vr.RewSize vr.engageLatency vr.wait4stop_SW vr.searchtime_SW];
        
        vr.event_newTrial=1;
        vr.okNewTrial=0;
        vr.ITI=0;
        vr.abort_flag=0;
        vr.start_flag=0;
        vr.q = 1;
        
        okNewTrial_time_tNum_tType = [now vr.trialNum vr.CBA]; display(okNewTrial_time_tNum_tType)
        vr.position(2) = vr.startLocation;
        
        vr.atStartLocation = 1;
        
        vr.trialNum = vr.trialNum + 1;
        
        vr.CBA = vr.A + vr.B*10 + vr.C*100;
        currentCBA = vr.CBA; display(currentCBA);
        
        % make tracks appear, move into place
        vr.progRatio=vr.progRatioStart+floor(vr.trialNum/20);
        if vr.progRatio > 9
            vr.progRatio=9;
        end
        vr.short_distance = vr.progRatio_short_Dist(vr.progRatio);
        vr.long_distance = vr.progRatio_long_Dist(vr.progRatio);
        disp('tracks appear')
        disp('dist prog ratio is')
        disp(vr.progRatio)
        switch vr.B
            case 1
                vr.currTrack_ID=1;
                vr.rewLocation = vr.short_distance;
            case 2
                vr.currTrack_ID=2;
                vr.rewLocation = vr.long_distance;
        end
        vr.worlds{vr.currentWorld}.surface.colors(4,vr.trackIndx{vr.currTrack_ID}) = 1;
        vr.worlds{vr.currentWorld}.surface.vertices(3,vr.trackIndx{vr.currTrack_ID}) = vr.track_zOrig{vr.currTrack_ID};
        
        vr.startTrial_SW = 0;
        vr.startTrial_latency = 1;
        vr.waiting4start = 1;
        vr.flipping = 1;

        disp('w=1,reappearflag=0')
        vr.trialTimer_On=1;
        vr.trialTimer_SW=0; % reset trial timer
        vr.reappear_flag=0;
        
        
        %reset start speed queue to detect mouse start
        vr.spd_circ_queue_start=zeros(vr.queue_len_start,1);
        vr.currentA=vr.A;
        vr.currentB=vr.B;
    end
end

%% Deliver Reward
if vr.rewEarned > 0
    currRew = vr.rewEarned;
    vr.rewEarned = 0; %reset
    vr.lastRewEarned = datestr(rem(now,1));
    
    switch currRew
        case 2
            vr.totalWater = vr.totalWater + vr.onSm_h2o;
            SmRewEarned = vr.totalWater; display(SmRewEarned);
            if ~vr.debugMode
                disp('outdata onSm');
                out_data = vr.onSm_outdata;
                if vr.daq_flag == 1
                    putdata(vr.ao, out_data);
                    disp('line739')
                    start(vr.ao);
                    trigger(vr.ao);
                end
                
            end
            
        case 4
            vr.totalWater = vr.totalWater + vr.onLg_h2o;
            LgRewEarned = vr.totalWater; display(LgRewEarned);
            if ~vr.debugMode
                disp('outdata onLg');
                out_data = vr.onLg_outdata;
                if vr.daq_flag == 1
                    putdata(vr.ao, out_data);
                    disp('line754')
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
        case vr.dispWater
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
            
        case vr.toggleDisp % 't'
            vr.dispSet = vr.dispSet + 1;
            if vr.dispSet > 2
                vr.dispSet = 0;
            end
            toggle_dispSet = vr.dispSet; display(toggle_dispSet);
            
        case vr.dispStartTime
            start_last_end = ['start:' vr.startTime ' lastRew:' vr.lastRewEarned ' curr:' datestr(rem(now,1))];
            display(start_last_end);
            
        case vr.dispWhatever
            
            if vr.wait4stop>0
                wait4stop_times = vr.wait4stop_times; display(wait4stop_times)
                median_wait4stop = median(vr.wait4stop_times); display(median_wait4stop)
                
                iTrialType=1;
                
                while ~isempty(vr.rewTrials{iTrialType}) && iTrialType<=2
                    percentRew = [iTrialType sum(vr.rewTrials{iTrialType})/length(vr.rewTrials{iTrialType})];
                    display(percentRew)
                    iTrialType=iTrialType+1;
                end
                
                iTrialType=1;
                while ~isempty(vr.rewTrials{iTrialType}) && iTrialType<=2
                    startLatency = [iTrialType mean(vr.startLatency{iTrialType})];
                    display(startLatency)
                    iTrialType=iTrialType+1;
                end
                
            end
    end
end

if vr.event_newTrial > 0 % sent AO signal for new trial signaling trial type
    vr.event_newTrial = 0;
    if vr.dispSet > 0
        disp('event_newTrial');
    end
    out_data = vr.event_newTrial_outdata{vr.B}{vr.A};
    if vr.daq_flag == 1
        putdata(vr.ao, out_data);
        disp('line827')
        start(vr.ao);
        trigger(vr.ao);
    end
end
if vr.daq_flag==1
    
    if vr.plotAI>0 % plot relevant data from analog input from previous trial
        vr.plotAI=0;
        data = peekdata(vr.ai, min([vr.ai.SamplesAvailable*1.02 vr.SR * 20])); % 1000 * 8
        flushdata(vr.ai, 'all');
        plot(data(:,2:5))
    end
end

%% --- TERMINATION code: executes after the ViRMEn engine stops.
function vr = terminationCodeFun(vr)

if vr.wait4stop>0
    median_wait4stop = median(vr.wait4stop_times);
    summary.median_wait4stop=median_wait4stop; display(median_wait4stop)
    
    %summary.median_startTrial=median_startTrial; display(median_startTrial)
end

iTrialType=1;
while iTrialType<=2 && ~isempty(vr.rewTrials{iTrialType})
    percentRew = [iTrialType sum(vr.rewTrials{iTrialType})/length(vr.rewTrials{iTrialType})];
    summary.percentRew(iTrialType) = sum(vr.rewTrials{iTrialType})/length(vr.rewTrials{iTrialType}); display(percentRew)
    iTrialType=iTrialType+1;
end
iTrialType=1;
while iTrialType<=2 && ~isempty(vr.rewTrials{iTrialType})
    %startLatency = [iTrialType mean(vr.startLatency{iTrialType})];
    %display(startLatency)
    iTrialType=iTrialType+1;
end
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

tData = round(vr.preyData);

rews_trials_water = [sum(vr.rewTrials{1})+sum(vr.rewTrials{2}) tData(end,1) vr.totalWater];
summary.rews_trials_water = rews_trials_water; display(rews_trials_water)


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
