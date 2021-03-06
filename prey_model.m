%% last edits: 8/27 laptop MB (before deleted starttrial_times)

% **** NEED TO CALIBRATE 6uL REWARD VALVE OPENING TIME *****

function code = prey_model

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

rng('shuffle'); % shuffles random number generator at start of task

%% retrieves values from ViRMEn GUI
vr.mouseID = eval(vr.exper.variables.mouseID);
vr.debugMike = eval(vr.exper.variables.debugMike);
vr.debugMode = eval(vr.exper.variables.debugMode);
vr.RewDuration = eval(vr.exper.variables.RewDuration); % global variable used in other function(s) written by HyungGoo
vr.scalingStandard = eval(vr.exper.variables.scaling);
vr.scaledown = 2;
vr.scaling = vr.scalingStandard/vr.scaledown; % global variable used in other function(s) written by HyungGoo
vr.startTime = datestr(rem(now,1));
vr.startT = now;

%%
vr.startLocation=0;
vr.currTrack_ID=1;

vr.trialTimer_SW=0;
vr.trialTimer_On=0;

vr.ITI=0; % set to 1 to start ITI and 2 while remaining in ITI, 0 is ITI off
vr.ITI_SW=0; % stopwatch for ITI
vr.ITI_duration=1; % duration for ITI (value re-drawn each trial)
% default ITI parameters (set custom per mouse otherwise) - drawn from a
% psuedo-normal distribution

vr.startTrial_SW = 0; % keep track of how long mouse takes to start trial after track appears

vr.delay2disappear=.5; % delay until track disappears following reward

if vr.debugMode || vr.debugMike % set to 'true' in ViRMEn GUI when debugging on the rig to set all means (ITI, distance, etc) to low values for quicker debugging
    disp('DEBUG MODE RUNNING')
end
%%
if ~vr.debugMode
    disp('daqreset')
    %%daqreset %reset DAQ in case it's still in use by a previous Matlab program
    
    %%VirMenInitDAQ;
    
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
vr.trialsData=[]; % trialNum, trialType, rewEarned, rewLocation, endLocation, trialTime
vr.trialNum = 1;

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
vr.queue_len_start=30;
vr.spd_circ_queue_start=zeros(vr.queue_len_start,1);
vr.start_queue_indx=1;

vr.plotAI=0; % plots analog input

%% event signals to send to DAQ board
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
        vr.STOP_CRIT = 0.025;
        
        vr.queue_len_stop = 30; % begin training w ~.5s, then increase to 1s after learned to stop (same as stop to abort trial)
        vr.queue_len_start=30;
        vr.spd_circ_queue_stop= ones(vr.queue_len_stop, 1);
        vr.spd_circ_queue_start= zeros(vr.queue_len_stop, 1);
        
        vr.start4engage = 0;%0: if do not need to start running to engage, 1: if they need to start running to engage
        vr.start_latency_CRIT = 2;%within how many seconds should they start running to engage with the trial''
        
        vr.progRatioStart = 1;% 9:is the maximum and goal of the training
        
        vr.freq_high_value=1/15;
        vr.freq_low_value=1/5;
        
    otherwise
        disp('error: MOUSE ID NOT RECOGNIZED');
end

% make times & distances short for debugging
if vr.debugMike
    vr.rewLocation = 20;
    vr.dist_minmeanmaxstd = [10 20 30 5];
    vr.ITI_minmeanmaxstd = [1 2 3 .5];
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
vr.onSm =  [5 * ones(floor(vr.SmRew/1000*vr.SR),1 ); zeros(1, 1)]; vr.onSm = [vr.onSm zeros(length(vr.onSm),1)];
vr.onLg =  [5 * ones(floor(vr.LgRew/1000*vr.SR),1 ); zeros(1, 1)]; vr.onLg = [vr.onLg zeros(length(vr.onLg),1)];


% if ~vr.debugMode
%     % start generating pulse by signaling to Arduino board
%     putvalue(vr.dio.Line(2), 1);
% end

mouseID = vr.mouseID; display(mouseID);
vr.progRatio = vr.progRatioStart;
vr.short_distance = vr.progRatio_short_Dist(vr.progRatio);
vr.long_distance = vr.progRatio_long_Dist(vr.progRatio);

%% move correct track into place, other away/disappear, initiate variables for must run, etc
%vr.CBA = vr.trialTypes(vr.thisTrial); % vr.C = task ID, vr.B = track ID, vr.A = reward size (uL)
%vr.A = mod(vr.CBA,10);
%vr.B = mod(vr.CBA-vr.A,100)/10;
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
    case 2
        vr.currTrack_ID=2; otherTrack=1; curr_brightTrack=4; other_brightTrack = 3;
end
vr.CBA = vr.A + vr.B*10 + vr.C*100;


vr.worlds{vr.currentWorld}.surface.colors(4,vr.trackIndx{vr.currTrack_ID}) = 1;
vr.worlds{vr.currentWorld}.surface.colors(4,vr.trackIndx{otherTrack}) = 0;
vr.worlds{vr.currentWorld}.surface.colors(4,vr.trackIndx{curr_brightTrack}) = 0;
vr.worlds{vr.currentWorld}.surface.colors(4,vr.trackIndx{other_brightTrack}) = 0;
vr.worlds{vr.currentWorld}.surface.vertices(3,vr.trackIndx{vr.currTrack_ID}) = vr.track_zOrig{vr.currTrack_ID};
vr.worlds{vr.currentWorld}.surface.vertices(3,vr.trackIndx{otherTrack}) = vr.track_zOrig{otherTrack}+60;
vr.worlds{vr.currentWorld}.surface.vertices(3,vr.trackIndx{curr_brightTrack}) = vr.track_zOrig{curr_brightTrack}+60;
vr.worlds{vr.currentWorld}.surface.vertices(3,vr.trackIndx{other_brightTrack}) = vr.track_zOrig{other_brightTrack}+60;

vr.abort_flag = 0;
vr.start_flag = 0;
vr.occur_time=0;
vr.roll_flag = 1;
%% DELIVER 2uL WATER TO START SESSION
% if ~vr.debugMode
%     out_data = vr.onMd;
%     vr.totalWater = vr.totalWater + vr.onMd_h2o;
%     putdata(vr.ao, out_data);
%     start(vr.ao);
%     trigger(vr.ao);
%     display(datestr(now));
%
%     [data, time, abstime] = getdata(vr.ai, vr.ai.SamplesAvailable*1.02);
%     figure; plot(time, data(:, [2 3 4 5])); % plot analog input
% end
%% --- RUNTIME code: executes on every iteration of the ViRMEn engine.
function vr = runtimeCodeFun(vr)

vr.dp_cache = vr.dp; % cache current velocity so value measured even if changed to zero

if vr.trialTimer_On>0
    vr.trialTimer_SW = vr.trialTimer_SW + vr.dt;
end

if vr.ITI==0 && vr.abort_flag ==0
    vr.dp(2) = 0;
    vr.startTrial_SW = vr.startTrial_SW + vr.dt;
    vr.spd_circ_queue_start(vr.start_queue_indx) = vr.dp_cache(:,2); % add current speed to queue
    vr.start_queue_indx = vr.start_queue_indx + 1; % move to next spot in queue
    if nanmin(vr.spd_circ_queue_start(~isnan(vr.spd_circ_queue_start))) > .05
        vr.start_flag=1;
    end
    if vr.start_queue_indx > vr.queue_len_start % start over beginning of queue if at the end
        vr.start_queue_indx = 1;
    end
    %% MOUSE DID NOT RUN, ABORT TRIAL
    %if vr.start_queue_indx>(vr.queue_len_start-1) && nanmax(vr.spd_circ_queue_start(~isnan(vr.spd_circ_queue_start))) < .05
    if vr.start4engage == 1
        if vr.start_flag == 0 && vr.startTrial_SW>vr.start_latency_CRIT && nanmax(vr.spd_circ_queue_start(~isnan(vr.spd_circ_queue_start))) < .05
            disp('mouse aborted trial')
            vr.ITI=1.5; % *initialize ITI after abort trial
            vr.rewTrials{vr.B} = [vr.rewTrials{vr.B} 0]; % add zero for unrew trial
            vr.abort_flag = 1;
            out_data=vr.event_abortTrial_outdata;
            vr.spd_circ_queue_start=zeros(vr.queue_len_start,1);
            %             putdata(vr.ao, out_data);
            %             start(vr.ao);
            %             trigger(vr.ao);
        end
    end
    %% reward earned: switch to ITI
    if vr.position(2) >= vr.rewLocation
        disp('position > rewLocation')
        vr.endLocation=vr.position(2); % store location of trial completed to save later
        vr.ITI = 0.5;
    end
    if vr.ITI == 0.5
        %make the track brighter to let the mouse know this is the goal
        vr.worlds{vr.currentWorld}.surface.colors(4,vr.trackIndx{vr.currTrack_ID}) = 0;
        vr.worlds{vr.currentWorld}.surface.colors(4,vr.trackIndx{vr.currTrack_ID+2}) = 1;
        vr.worlds{vr.currentWorld}.surface.vertices(3,vr.trackIndx{vr.currTrack_ID}) = vr.track_zOrig{vr.currTrack_ID}+60;
        vr.worlds{vr.currentWorld}.surface.vertices(3,vr.trackIndx{vr.currTrack_ID+2}) = vr.track_zOrig{vr.currTrack_ID+2};
        
        vr.ITI=1;
        vr.rewEarned = vr.A;
        vr.rewTrials{vr.B}=[vr.rewTrials{vr.B} 1]; % add 1 for successful rew trials
        vr.trialTimer_On=0; % turn off trial timer
    end
    
    %% *** NEW TRIAL START: Leave startLocation
    if vr.atStartLocation==1 && vr.position(2) > vr.startLocation+2
        
        vr.atStartLocation = 0; %reset to start location
    end
    
end

%% inter-trial interval
% ITI #s: 1 = initialize after reward, 1.5 init after abort, 2 = track disappears after delay following reward
% 3 = waiting before eligible to start new trial, 4 = waiting to detect stop before initiating new trial
if vr.ITI > 0
    %% initialize ITI
    if vr.ITI==1 % initialize after rewarded trial
        
        vr.ITI_SW = 0 - vr.dt; % initialize SW to -vr.dt because adding vr.dt to SW later this same iteration
        vr.ITI=2; % run next block after 'delay2disappear' time has elapsed
        
    elseif vr.ITI==1.5 % initialize after aborted trial
        
        vr.ITI_SW = 0 - vr.dt; % initialize SW to -vr.dt because adding vr.dt to SW later this same iteration
        vr.ITI=2.5; % run next block immediately
    end
    
    %% track disappears following delay after reward(ITI=2) or immediately after aborted trial(ITI=2.5)
    if (vr.ITI==2 && vr.ITI_SW >= vr.delay2disappear) || vr.ITI==2.5
        
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
        while 1
            if vr.roll_flag == 1
                disp('dice rolled')
                while 1
                    n=rand(120,1);
                    freq_track1=vr.freq_high_value;
                    track1_occur_time=find(n < freq_track1);
                    if isempty(track1_occur_time)
                    else
                        break;
                    end
                end
                
                while 1
                    n=rand(120,1);
                    freq_track2=vr.freq_low_value;
                    track2_occur_time=find(n < freq_track2);
                    if isempty(track2_occur_time)
                    else
                        break;
                    end
                end
                vr.rolls_for_2min=zeros(120,1);
                track12=intersect(track1_occur_time,track2_occur_time);
                track1_only=setdiff(track1_occur_time,track2_occur_time);
                track2_only=setdiff(track2_occur_time,track1_occur_time);
                if isempty(track1_only) || isempty(track2_only)
                else
                    vr.rolls_for_2min(track1_only)=1;
                    vr.rolls_for_2min(track2_only)=2;
                    vr.rolls_for_2min(track12)=3;
                    for j=1:length(find(vr.rolls_for_2min==3))
                        m=rand(1);
                        if m < 1/4
                            vr.rolls_for_2min(find(vr.rolls_for_2min==3,j))=2;
                        else
                            vr.rolls_for_2min(find(vr.rolls_for_2min==3,j))=1;
                        end
                    end
                    
                    vr.occur_time_inds=find(vr.rolls_for_2min~=0);
                    vr.roll_flag = 0;
                    vr.k=1;
                    break;
                end
            else
                break;
            end
            
        end
        while vr.k < (length(vr.occur_time_inds) + 1)
            if vr.k==1
                
                vr.occur_time = vr.occur_time_inds(vr.k);
                vr.B=vr.rolls_for_2min(vr.occur_time_inds(vr.k));
                vr.k=vr.k+1;
                break;
            elseif vr.k>1
                
                vr.occur_time = vr.occur_time_inds(vr.k)-vr.occur_time_inds(vr.k-1);
                vr.B=vr.rolls_for_2min(vr.occur_time_inds(vr.k));
                vr.k=vr.k+1;
                if vr.k == length(vr.occur_time_inds)
                    vr.roll_flag=1;
                end
                break;
            end
        end
        if vr.B==1
            vr.A=4;
        elseif vr.B==2
            vr.A=2;
        end
        
    end
    
    vr.ITI_SW = vr.ITI_SW + vr.dt;
    
    %% 3: waiting before eligible to start new trial
    if vr.ITI==3 && (vr.ITI_SW > vr.occur_time)
        vr.plotAI=1; % plot analog input from previous trial
        ITI_SW_crossedthresh = vr.ITI_SW; display(ITI_SW_crossedthresh)
        
        if vr.wait4stop==0 % begin next trial if do not need to wait for stop, otherwise initialize speed queue
            vr.okNewTrial = 1;
        else
            vr.ITI=4;
            %reset speed queue to detect mouse stop
            vr.spd_circ_queue_stop= ones(vr.queue_len_stop, 1);
            vr.queue_indx_stop = 1;
            disp('speed queue initialized');
            vr.wait4stop_SW = 0 - vr.dt; % initialize SW below zero because will add vr.dt back same iteration below
        end
    end
    
    %% 4: waiting for mouse to stop if required to start new trial
    if vr.ITI==4
        vr.wait4stop_SW = vr.wait4stop_SW + vr.dt; % add elapsed time to stopwatch
        vr.spd_circ_queue_stop( vr.queue_indx_stop) = vr.dp_cache(:,2); % add current speed to queue
        vr.queue_indx_stop = vr.queue_indx_stop + 1; % move to next spot in queue
        
        if vr.queue_indx_stop > vr.queue_len_stop % start over beginning of queue if at the end
            vr.queue_indx_stop = 1;
        end
        
        % MOUSE STOPPED
        if nanmax(vr.spd_circ_queue_stop(~isnan(vr.spd_circ_queue_stop))) < vr.STOP_CRIT
            vr.okNewTrial=1;
            vr.wait4stop_times = [vr.wait4stop_times vr.wait4stop_SW];
            median_wait4stop = median(vr.wait4stop_times); display(median_wait4stop)
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
        % concatenate data from previous data to vr.trialsData
        vr.trialsData = [vr.trialsData; vr.trialNum vr.CBA prevRew vr.rewLocation vr.trialTimer_SW];
        
        vr.event_newTrial=1;
        vr.okNewTrial=0;
        vr.ITI=0;
        vr.abort_flag=0;
        vr.start_flag=0;
        
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
        
        vr.trialTimer_On=1;
        vr.trialTimer_SW=0; % reset trial timer
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
                out_data = vr.onSm;
                %                 putdata(vr.ao, out_data);
                %                 start(vr.ao);
                %                 trigger(vr.ao);
            end
            
        case 4
            vr.totalWater = vr.totalWater + vr.onLg_h2o;
            LgRewEarned = vr.totalWater; display(LgRewEarned);
            if ~vr.debugMode
                disp('outdata onMd');
                out_data = vr.onLg;
                %                 putdata(vr.ao, out_data);
                %                 start(vr.ao);
                %                 trigger(vr.ao);
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
            
            tData = round(vr.trialsData);
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
    %     out_data = vr.event_newTrial_outdata{vr.B}{vr.A};
    %     putdata(vr.ao, out_data);
    %     start(vr.ao);
    %     trigger(vr.ao);
end

% if vr.plotAI>0 % plot relevant data from analog input from previous trial
%     vr.plotAI=0;
%     data = peekdata(vr.ai, min([vr.ai.SamplesAvailable*1.02 vr.SR * 20])); % 1000 * 8
%     flushdata(vr.ai, 'all');
%     plot(data(:,2:5))
% end

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

% if ~vr.debugMode
%     fclose all;
%     %turn off camera - wait, what camera?
%     putvalue(vr.dio.Line(2), 0);
% %     stop(vr.ai);
% end

endTime = datestr(rem(now,1));

mID = vr.mouseID; display(mID);
start_last_end = ['start:' vr.startTime ', lastRew:' vr.lastRewEarned ', end:' endTime];
display(start_last_end);
summary.mID = mID; summary.start_last_end = start_last_end;

tData = round(vr.trialsData);

rews_trials_water = [sum(vr.rewTrials{1})+sum(vr.rewTrials{2}) tData(end,1) vr.totalWater];
summary.rews_trials_water = rews_trials_water; display(rews_trials_water)

if ~vr.debugMode %save all files and move to appropriate folders
    answer = inputdlg({'mouse','Comment'},'Question',[1; 5]);
    sessionDate = datestr(now,'yyyymmdd');
    
    taskVars = vr;
    save([vr.pathname '\' vr.filenameTaskVars '.mat'],'taskVars','-append');
    
    stats = summary;
    save([vr.pathname '\' vr.filenameStats '.mat'],'stats','-append');
    
    trials = vr.trialsData;
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
        
        %movefile([daqPath '\' daqDir(end).name],[vr.pathname '\' answer{1} '\' sessionDate '\DaqData',datestr(now,'mmdd'),'.daq']);
    end
end