function code = xForaging_tau_edits % MB: 8/7



% possibly GET RID OF TRAJECTORY SAVE??

% redesignate trialIDs

%rid REDUNDANT saving of speed lick etc
% test analysis of these data FROM .dat file

%debug virmen jump backwards error??? (observed when patchappear earlier
%than patch bottom

%debug obj already started error

%recallibrate

% RECORD VIDEOS


% save trajectory data
%measurementsToSave = [now vr.position(2) vr.dp_cache vr.dt];
%fwrite(vr.fid,measurementsToSave,'double');

%***can also dissociate effort from time by having different thresholds for
%meanspeed for SAME time cost
%%line ~1092 found an error in previous code:
%vr.spd_circ_queue_stop_stop= ones( vr.queue_len_stop, 1);
%instead of 'vr.spd_circ_queue_stop='

%LOSING PRECISION FOR REWARD DELIVERY TIMES BY USING (RESETING) STOPWATCHES
%TO TIME REPEAT REWS?? - can write a code to test this


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

rng('shuffle');

vr.mouseID = eval(vr.exper.variables.mouseID);
vr.debugMode = eval(vr.exper.variables.debugMode);
vr.RewDuration = eval(vr.exper.variables.RewDuration);
vr.scalingStandard = eval(vr.exper.variables.scaling);
vr.fixBlock = eval(vr.exper.variables.fixBlock); %allow for manual choice of HiLg or LoSm context
vr.startTime = datestr(rem(now,1));
vr.startT = now;

vr.eventData = [];
eventData = vr.eventData;

%%
if ~vr.debugMode
    
    daqreset %reset DAQ in case it's still in use by a previous Matlab program
    
    VirMenInitDAQ;
    
    vr.pathname = 'C:\ViRMEn\ViRMeN_data\foraging';
    cd(vr.pathname);
    vr.filename = datestr(now,'yyyymmdd_HHMM');
    vr.filenameExper = ['Exper',datestr(now,'yyyymmdd_HHMM')];
    vr.filenameEvents = ['Events',datestr(now,'yymmdd_HHMM')]; %save Events data
    vr.filenameTaskVars = ['TaskVars',datestr(now,'yymmdd_HHMM')];
    vr.filenamePatches = ['Patches',datestr(now,'yymmdd_HHMM')]; %data for each patch
    
    %save trajectory data
    %fwrite(vr.fid,length(measurementsToSave),'double');
    
    exper = copyVirmenObject(vr.exper);
    save([vr.pathname '\' vr.filenameExper '.mat'],'exper');
    
    save([vr.pathname '\' vr.filenameEvents '.mat'],'eventData');
    taskVars = vr.mouseID; %save other variables at termination
    save([vr.pathname '\' vr.filenameTaskVars '.mat'],'taskVars');
    patches = [];
    save([vr.pathname '\' vr.filenamePatches '.mat'],'patches');
    
end

vr.patchesMelt = 1; %patches disappear after reward or exit
vr.meltAB = 0; vr.meltB = 0; vr.meltA = 0; %switches for patchmelts
vr.meltA_1s = 0; vr.meltAB_1s = 0;
vr.meltA_1s_SW = 0; vr.meltAB_1s_SW = 0;

%% determine the index of patches
vr.indx_patchA{1} = vr.worlds{vr.currentWorld}.objects.indices.patchA;
vr.indx_patchB{1} = vr.worlds{vr.currentWorld}.objects.indices.patchB;
vr.indx_patchA{2} = vr.worlds{vr.currentWorld}.objects.indices.patchA2;
vr.indx_patchB{2} = vr.worlds{vr.currentWorld}.objects.indices.patchB2;

for k = 1:length(vr.indx_patchA)
    % determine the indices of the first and last vertex of patches
    vr.vertexFirstLast_patchA{k} = vr.worlds{vr.currentWorld}.objects.vertices(vr.indx_patchA{k},:);
    vr.vertexFirstLast_patchB{k} = vr.worlds{vr.currentWorld}.objects.vertices(vr.indx_patchB{k},:);
    
    % create an array of all vertex indices belonging to patches
    vr.patchIndxA{k} = vr.vertexFirstLast_patchA{k}(1):vr.vertexFirstLast_patchA{k}(2);
    vr.patchIndxB{k} = vr.vertexFirstLast_patchB{k}(1):vr.vertexFirstLast_patchB{k}(2);
    
    %store original coordinates for patches
    vr.patchA_xOrig{k} = vr.worlds{vr.currentWorld}.surface.vertices(1, vr.patchIndxA{k});
    vr.patchA_yOrig{k} = vr.worlds{vr.currentWorld}.surface.vertices(2, vr.patchIndxA{k});
    vr.patchA_zOrig{k} = vr.worlds{vr.currentWorld}.surface.vertices(3, vr.patchIndxA{k});
    vr.patchB_xOrig{k} = vr.worlds{vr.currentWorld}.surface.vertices(1, vr.patchIndxB{k});
    vr.patchB_yOrig{k} = vr.worlds{vr.currentWorld}.surface.vertices(2, vr.patchIndxB{k});
    vr.patchB_zOrig{k} = vr.worlds{vr.currentWorld}.surface.vertices(3, vr.patchIndxB{k});
    
    if vr.patchesMelt == 1;
        
        %start with patches invisible
        vr.worlds{vr.currentWorld}.surface.colors(4,vr.patchIndxA{k}) = 0;
        vr.worlds{vr.currentWorld}.surface.colors(4,vr.patchIndxB{k}) = 0;
        
        %move patches away
        vr.worlds{vr.currentWorld}.surface.vertices(3, vr.patchIndxA{k}) = ...
            vr.patchA_zOrig{k} + 60;
        vr.worlds{vr.currentWorld}.surface.vertices(3, vr.patchIndxB{k}) = ...
            vr.patchB_zOrig{k} + 60;
    end
end

%% determine the index of floors
vr.indx_floor{1}{1} = vr.worlds{vr.currentWorld}.objects.indices.mainFloor1;
vr.indx_floor{2}{1} = vr.worlds{vr.currentWorld}.objects.indices.mainFloor2;
vr.indx_floor{3}{1} = vr.worlds{vr.currentWorld}.objects.indices.mainFloor3;
vr.indx_floor{1}{2} = vr.worlds{vr.currentWorld}.objects.indices.mainFloor1B;
vr.indx_floor{2}{2} = vr.worlds{vr.currentWorld}.objects.indices.mainFloor2B;

for k = 1:length(vr.indx_floor)
    for j = 1:length(vr.indx_floor{k})
        % determine the indices of the first and last vertex of floors
        vr.vertexFirstLast_floor{k}{j} = vr.worlds{vr.currentWorld}.objects.vertices(vr.indx_floor{k}{j},:);
        
        % create an array of all vertex indices belonging to floors
        vr.floorIndx{k}{j} = vr.vertexFirstLast_floor{k}{j}(1):vr.vertexFirstLast_floor{k}{j}(2);
        
        %store original coordinates for floors
        vr.floor_xOrig{k}{j} = vr.worlds{vr.currentWorld}.surface.vertices(1, vr.floorIndx{k}{j});
        vr.floor_yOrig{k}{j} = vr.worlds{vr.currentWorld}.surface.vertices(2, vr.floorIndx{k}{j});
        vr.floor_zOrig{k}{j} = vr.worlds{vr.currentWorld}.surface.vertices(3, vr.floorIndx{k}{j});
        
        if j > 1 % floors (except default #1), invisible/moved
            vr.worlds{vr.currentWorld}.surface.colors(4,vr.floorIndx{k}{j}) = 0;
            vr.worlds{vr.currentWorld}.surface.vertices(3, vr.floorIndx{k}{j}) = ...
                vr.floor_zOrig{k}{j} + 60;
        end
    end
end

vr.totalWater = 0;
vr.isMoving = 0;
vr.isMov_didStop = 0;

vr.leaveQEligible = 0;
vr.leaveQEligTime = 0;
vr.leaveQInitTime = 0;

vr.stopQEligible = 0;
vr.stopQEligTime = 0;
vr.stopQStopTime = 0;

vr.trainingStage = 2; %default to 1 if unspecificed ?????
vr.rewDeliver = 0;
vr.trialNum = 0;
vr.trialType = 0;

vr.timeXtemp = [];
%vr.timeXsave{1} = [];
vr.data1temp = [];
vr.data2temp = [];
%vr.data2save{1} = [];
vr.data3temp = []; %use for concatanating data per trial
%vr.data3save{1} = []; %use to save long term data for each trial
vr.data4temp = [];
%vr.data4save{1} = [];
vr.data5temp = [];
vr.data6temp = [];
vr.data7temp = [];
%vr.data5save{1} = [];
vr.dataXsaveCount = 1; %trial number data for
vr.trialTrajectory = [];
vr.trajectory = [];
vr.lastRewEarned = [];

vr.didStop = 0;
vr.didnotStopYet = 0; %set to 1 after patchHit
vr.didnotStop_last = 0; %use to tally each consecutive <- (can't spell this) didnotstop

vr.patchData = [];
vr.patchStops = [];
vr.stopCoordinates = [];
vr.countStops = 0; %using for travelType > 1

vr.traveltime_SW = 0; %use to count
vr.traveltimes = [];
vr.traveltime2_SW = 0; %use to count
vr.traveltimes2 = [];
vr.TT = []; %travel times for easy access w no trial history info, etc
vr.TT2 = [];

%get coordinates for patchform mids and boundaries
vr.patchA_mid = eval(vr.exper.variables.patchAY);
vr.patchB_mid = eval(vr.exper.variables.patchBY);

vr.patchHeight = eval(vr.exper.variables.patchHeight);
vr.patchWidth = eval(vr.exper.variables.patchWidth);
vr.patchA_bottom = vr.patchA_mid - .5*vr.patchHeight;
vr.patchA_top = vr.patchA_mid + .5*vr.patchHeight;
vr.patchB_bottom_orig = vr.patchB_mid - .5*vr.patchHeight;

vr.floor1height = eval(vr.exper.variables.floor1height);
vr.floor2height = eval(vr.exper.variables.floor2height);
vr.floor3height = vr.floor2height;
vr.floor3y = eval(vr.exper.variables.floor3y);

%% KEYPRESS COMMANDS
vr.dispStartTime = 81; %'q'
vr.dispWater = 87; %'w'
vr.dispHistory = 69; %'e'
%65; %'a'
vr.dispWhatever = 82; %'r'
vr.toggleDisp = 84; %'t'; *toggles dispSet value 0,1,2
vr.dispSet = 0; %value for low(0), med(1), or high(2) amount of printing for debugging

vr.coordinates = [];

%for water calibration, need to turn caliWaterLOCK off to 0 to use*
vr.runCaliWater = 59; %';'

vr.rewKeyMed = 85; % 'u' 

vr.caliWater = 0; %calibrate water sizes per x # deliveries
vr.caliSize =12; %8/1/18  %4uL=22.5  2uL=12.5 1uL=7    6/6/17 vr.XLgRew = 23; vr.MdRew = 12; vr.SmRew = 7; %10/26/18 %4uL=25 2uL=13 %10/31/18 %4uL=21, 2uL=12
vr.caliPause = .25;
vr.caliTimes = 500;
vr.caliSW = 0;
vr.caliCount = 0;
vr.caliWaterLOCK = 0; %set to 1 to avoid accidental keypress for calibration 100x deliver h2o

%{
    vr.onXLgh2o = 4;
    vr.onLgh2o = 3;
    vr.onMdh2o = 2;
    vr.onSmh2o = 1;
    vr.XLgRew = 47; vr.LgRew = 34; vr.MdRew = 17; vr.SmRew = 10;
%}

vr.trialHistory = [];

vr.initiateLeave = 0; % for travelTypes 2 & 3, set to 1 when leaveThreshold is exceeded
%vr.initiateElig = 0;
vr.foraging = 0;
vr.patchHit = 0;
vr.nextRew_SW = 0;
vr.foraging_SW = 0;
vr.nextRew_DUR = 1; %default to 1, modify later
vr.isMov_SW = 0;
vr.isMov_patchOn = 0;
vr.isMov_patchOn_SW = 0;
vr.wait4Mov = 0; % for trainingStage==1 in task travelTypes 2 and 3, set to 1 after reward before start moving again

vr.plotLicks_SW = 0;
vr.plotLicks_SW_on = 0;
vr.plotLicks_plotTime = 0.25; %plot licks .25s after reward delivery, 3/6/17 .9 -> .25
vr.plotLicks_flushSW = 0;
vr.plotLicks_flushSW_on = 0;
vr.plotLicks_flushTime = .5; %plot/save/flush 1s after patch leave, 3/6/17 1.0->.5
vr.plotLicks_flush = 0; %plot licks and flush ai data

vr.postRewTS2_SW = 0;
vr.postRewTS2_offTime = 1;

vr.rateIncrease = 0; %set to vr.B each patch for increasing delay between rews
vr.rewCounter = 1; %set to 1 at first reward(stop) then increase w each following in patch
vr.rewEarned = 0;
vr.firstTrial = 1;

vr.eligibleRew = 0; %reset to 1 at beginning of each trial, zero after patch disappears

vr.onTrack = 0; %0 = onPatch, 1 = just switched on, 2 = been on
vr.onPatch = 2; % 0 = onTrack, 1 = on Patch B, 2 = reset to Patch A

for i = 1:9
    vr.before4after(i,1:4) = [0 0 0 0]; %use to tally trials that mouse leaves before, during, or after IRI=4, AND +4after
end

%defaults
vr.setTT = 12; %default to 12seconds traveltime
vr.randTT = 0; %set to possible TTs to select rand TT for session
vr.preTT = 1; %amount of time (s) before TT when patch should appear
vr.TS3_stopTimeLim = vr.preTT; % must stop within X amount of time from patch on
vr.isMov_patchOn_rewTime = vr.preTT;
vr.isMov_patchOn_offTime = 2*vr.preTT;
vr.setSpeed = 5; %default speed for isMoving

vr.LEAVE_CRIT = .1; %threshold speed to initate patch leave
vr.RUN_CRIT = .1; %treshold speed minimum maintained during run to next patch
vr.STOP_CRIT = 0.05; %default
vr.queue_len_stop = 30; %*** time this later, is it 1/2 second???
vr.spd_circ_queue_stop= ones(vr.queue_len_stop, 1);
vr.queue_idx_stop = 1;
vr.queue_len_leave = 30; %*** TIME THIS TIME THIS
vr.spd_circ_queue_leave= zeros(vr.queue_len_leave, 1);
vr.queue_idx_leave = 1;
vr.maxIRI = 20; %6/25 30->20
vr.whichBlock = 1;

vr.switchAfterBlock1 = 0; % for mouse w single block of 1 type before block switch for remainder of session

vr.progRatioStart = 0;

vr.event_patchOn = 0;
vr.event_patchOff = 0;

vr.patchesRand = 0; % if 1, patches assigned random locations per trial
vr.patchesMove = 1; % set to > 0 for any kind of varied locations, even if not random for example in prog ratio
vr.scaledown = 2; %divide scaling by term
vr.IPI = 50; %inter patch interval
% ***MUST change patchBY in ViRMEn table or add code for change here to be
% sufficient (if patchesMove == 0)

vr.BL_switchTo = 0; % > 0 (= BL_ID) when time to switch at next patchHit

vr.currBL_ID = 1; %curr ID for block/patch type (color,texture,etc)
vr.diffBlocks = 0; % set to zero if only one type of block

vr.taskType_ID = [1 13]; % index for trial type sets

vr.travelType = 1; % 1 = fix distance between patches, mouse running speed determines travel time
% 2 = fix time between patches, mouse must run at least X speed for a set
% amount of time to travel to next patch
% 3 = mouse must run to iniate travel from patch to patch but does not need
% to maintain any speed for the duration

vr.doubleSize = 0;
vr.patchesExp = 0; % set to value for 'mean' (approximately since maxed) patch distance for exponential distribution
vr.appearBefore = -1; %distance before patchBottom which patch appears
% default to -1 to make patch appear 1 AU after patchBottom

switch vr.mouseID

        

        
        
    case 26
        display('26');
        vr.trainingStage = 2;
        vr.STOP_CRIT = 0.025;
        vr.taskType_ID = [7 9];
        vr.travelType = 1;
        vr.IPI = 60;
        vr.patchesMove = 1;
        %vr.progRatioStart = 9;
        
    case 27
        display('mouse #27');
        vr.trainingStage = 2; %4-17 -> TS2 (from TS0)
        vr.STOP_CRIT = 0.025;
        vr.taskType_ID = [7 7];
        vr.travelType = 1;
        vr.IPI = 100;
        vr.patchesMove = 1;
        %vr.progRatioStart = 8;
        
    case 28
        display('28');
        vr.trainingStage = 2;
        vr.STOP_CRIT = 0.04;
        vr.taskType_ID = [7 7];
        vr.travelType = 1;
        vr.IPI = 60;
        vr.patchesMove = 1;
        %vr.progRatioStart = 10;
        
        
    otherwise
        display('error: MOUSE ID NOT RECOGNIZED');
end

travelType = vr.travelType; display(travelType);
trainingStage = vr.trainingStage; display(trainingStage);

if vr.randTT(1)>0
    vr.setTT = vr.randTT(randsample(length(vr.randTT),1));
    randTTset = vr.setTT; display(randTTset);
end

%% trial types

% vr.trialTypes_Set{1}{x} = varying rates of increase inter-reward intervals
% x = rates of increase (4/1, 4/2, or 2/1)
vr.trialTypes_Set{1}{1} = [101 101 101 101 101]; %when run through block for prog ratio, move to next distance
vr.trialTypes_Set{1}{12} = [111 111 111 111 111 121 121 121 121 121];
vr.trialTypes_Set{1}{14} = [111 111 111 111 111 141 141 141 141 141];
vr.trialTypes_Set{1}{24} = [121 121 121 121 121 141 141 141 141 141];

% vr.trialTypes_Set{2}{x} = varying size of reward. x = rew sizes 4 Lg, 2 Md, 1 Sm
vr.trialTypes_Set{2}{1} = [202 202 202 202 202];
vr.trialTypes_Set{2}{3} = [221 221 221 221 222 222 222 222 223 223 223 223 ...
    221 221 221 221 222 222 222 222 223 223 223 223 ...
    221 221 221 221 222 222 222 222 223 223 223 223];

vr.trialTypes_Set{2}{4} = [221 221 221 221 221 221 221 221 221 221 ...
    222 222 222 222 222 222 222 222 222 222 ...
    224 224 224 224 224 224 224 224 224 224];

%% 5 is like two but with IRI increases +2 +4 +8 +16...
vr.trialTypes_Set{5}{1} = [502 502 502 502 502];

vr.trialTypes_Set{5}{4} = [521 521 521 521 521 521 521 521 521 521 ...
    522 522 522 522 522 522 522 522 522 522 ...
    524 524 524 524 524 524 524 524 524 524];

vr.trialTypes_Set{5}{5} = [521 521 521 521 521 521 521 521 521 521 ...
    521 521 521 521 521 521 521 521 521 521 ...
    522 522 522 522 522 522 522 522 522 522 ...
    522 522 522 522 522 522 522 522 522 522 ...
    524 524 524 524 524 524 524 524 524 524 ...
    524 524 524 524 524 524 524 524 524 524];

%% 7 is probablistic reward schedule based on exponential decay of reward rate
vr.trialTypes_Set{7}{5} = [721 721 721 721 721 721 721 721 721 721 ...
    722 722 722 722 722 722 722 722 722 722 ...
    724 724 724 724 724 724 724 724 724 724];

% changed 06-17-18
vr.trialTypes_Set{7}{6} = [711 711 711 ...
    721 721 721 ...
    731 731 731 ...
    712 712 712 ...
    722 722 722 ...
    732 732 732 ...
    714 714 714 ...
    724 724 724 ...
    734 734 734];

%{
vr.trialTypes_Set{7}{7} = [711 711 711 791 ...
    721 721 721 791 ...
    731 731 731 791 ...
    712 712 712 792 ...
    722 722 722 792 ...
    732 732 732 792 ...
    714 714 794 784 ...
    724 724 794 784 ...
    734 734 794 784]; %792, 794, 784 = probe trials
%}
    %{
    %5-17-18 % probes LgMdSm[0], Lg[0,.4,.8,1.2] for m26, for m27: probes LgMdSm[0] + Lg[0 2.4 4.8 7.2] [0 .4 .8 1.2 4.2] [0 4.2] [0 2.2]
    vr.trialTypes_Set{7}{7} = [711 711 711 ...
    721 721 721 ...
    791 791 791 ...
    712 712 712 ...
    722 722 722 ...
    792 792 792 ...
    754 754 764 ...
    764 724 ...
    774 774 784 784 794];
    %}
    %{
     %5-27-18 % probes LgMd [0 1 2 3 4], [0 2 4] [0 2], used again 5/29 for
     %m27 & m28 (though got rid of Medium probes), added 784 - no rew
    vr.trialTypes_Set{7}{7} = [711 711 711 ...
    721 721 721 ...
    731 731 731 ...
    712 712 712 ...
    722 722 722 ...
    732 732 732 ...
    714 754 754 ...
    724 774 774 ...
    784 794 794];
    %}
    %{
    % 6-1-18, 9 = [0 .4 .8 1.2 3.6] 8 = [0 1.2 3.6], 7 = [0 .4 .8 1.2], 6 = [0 1.2]
    % 6-2-18, 9 = [0 .6 1.2 1.8 2.4] 8 = [0 1.2 2.4 3.6 4.8], 7 = [0 1.8 3.6 5.4 7.2], 6 = [0 2.4 4.8 7.2 9.6]
    vr.trialTypes_Set{7}{7} = [711 711 711 ...
    721 721 721 ...
    731 731 731 ...
    712 712 712 ...
    722 722 722 ...
    732 732 732 ...
    774 794 794 ...
    774 784 784 ... 
    734 764 764];
    %}
    %6-8-18
    vr.trialTypes_Set{7}{7} = [711 711 711 ...
    721 721 721 ...
    731 731 731 ...
    712 712 712 ...
    722 722 722 ...
    732 732 732 ...
    784 784 774 ...
    774 764 764 ... 
    734 734 734];
    %{
    % 6-6-18
    vr.trialTypes_Set{7}{7} = [711 711 711 ...
    721 721 721 ...
    731 731 731 ...
    712 712 712 ...
    722 722 722 ...
    732 732 732 ...
    794 794 724 ...
    774 774 724 ... 
    754 754 734];
    %}
    %{
    %6-4-18
    vr.trialTypes_Set{7}{7} = [711 711 711 ...
    721 721 721 ...
    731 731 731 ...
    712 712 712 ...
    722 722 722 ...
    732 732 732 ...
    794 794 784 ...
    784 774 774 ... 
    764 764 724];
    %}
    %{
mouse 27, 4-30,5-2
% 784 = Lg026, 774 = Lg06, 764 = Lg03
% 782 = Md026, 762 = Md03
% 761 = Sm03
vr.trialTypes_Set{7}{8} = [711 761 ...
    721 761 ...
    731 761 ...
    712 712 782 ...
    722 782 ...
    732 762 762 ...
    714 714 784 ...
    724 774 784 ...
    774 764 764];
%}
    %{
    commented out 5-22-18
    %% changed 5-9-17
    % 794 = Lg[0 .2 .6 1.2 2.0], 764 = [0 1 2] (medium similarly)
    vr.trialTypes_Set{7}{8} = [711 711 711 ...
    721 721 721 ...
    731 731 731 ...
    712 792 792 ...
    722 762 762 ...
    732 732 732 ...
    714 794 794 ...
    724 764 764 ...
    734 734 734];
    %}
    
    
    % 5-22-18, rew size RPEs 794 and 792 (t=0 reward then switch next rew size)
    % 754 and 752 added 5/30/18 - [0 2], no rew size change for comparison
    vr.trialTypes_Set{7}{8} = [711 711 711 ...
    721 721 721 ...
    731 731 731 ...
    712 712 712 ...
    722 722 752 ...
    752 792 792 ...
    714 714 714 ...
    724 724 752 ...
    754 794 794];
    
    %{
   % mice 25/26, 5-3-18 **commented out 5-9-18 but changed within on some
   previous days**
% 784 = Lg0124, 774 = Lg04, 764 = Lg02
% 782 = Md0124, 762 = Md02
% 761 = Sm02
    vr.trialTypes_Set{7}{8} = [711 711 761 ...
    721 721 761 ...
    731 731 731 ...
    712 712 782 ...
    722 782 ...
    732 762 762 ...
    714 784 784 ...
    724 774 774 ...
    734 764 764];
%}
    
    
vr.trialTypes_Set{7}{9} = [721 721 721 721 721 721 721 721 721 721 762 ...
    724 724 724 724 724 724 724 724 724 724 782]; % blocks of 5 Lg or Sm followed by Medium probe, medium has specific reward timings [0 2 6 14 30]
    
%{
    mouse27 4-27
    % 794 = Lg0126, 784 = Lg026, 774 = Lg06, 764 = Lg04, 754 = Lg02
% 792 = Md0126, 782 = Md026, 772 = Md06, 762 = Md04, 752 = Md02
% 761 = Sm04, %751 = Sm02
[711 711 721 721 721 731 751 761 751 761 ...
    712 712 722 722 732 752 762 772 782 792 ...
    714 714 724 724 734 754 764 774 784 794];
%}

%% *** write probe timings in terms of IRI, not absolute time
if vr.taskType_ID(1)==7 && vr.taskType_ID(2)==7
    %[0 .2 .8 3.8], [0 1.2 2.4 3.8]
    vr.probeTrialRews{8} = [1.2 1.2 1.4];
    vr.probeTrialRews{7} = [.2 .6 3];
    vr.probeTrialRews{6} = [1.8 2];

    
     % test RPE: [0 .6 1.2 1.8 2.4 4.8], [0 1.2 2.4 4.8], [0 2.4 4.8], [0 4.8]
    %{
    vr.probeTrialRews{8} = [.6 .6 .6 .6 2.4];
    vr.probeTrialRews{7} = [1.2 1.2 2.4];
    vr.probeTrialRews{6} = [2.4 2.4];
    vr.probeTrialRews{5} = 4.8;
    %}
    %{
    % 6-8-18, 8 [0 .6 1.2 1.8 2.4], 7[.8 1.6 2.4] ,6 [0 1.2 2.4], 5 [0 2.4]
    vr.probeTrialRews{9} = [.4 .4 .4 .4 .4 .4];
    vr.probeTrialRews{8} = [.6 .6 .6 .6];
    vr.probeTrialRews{7} = [.8 .8 .8];
    vr.probeTrialRews{6} = [1.2 1.2];
    vr.probeTrialRews{5} = [2.4];
    %}
    %{
    % 6-6-18
    vr.probeTrialRews{9} = [1 2 3 4];
    vr.probeTrialRews{7} = [2 4];
    vr.probeTrialRews{5} = [4];
    %}
    %{
    % 6-4-18, 9 [0 .6 1.2 1.8 2.4], 8 [0 .8 1.6 2.4], 7 [0 1.2 2.4], 6 [0 2.4]
    vr.probeTrialRews{9} = [.4 .4 .4 .4 .4 .4];
    vr.probeTrialRews{8} = [.6 .6 .6 .6];
    vr.probeTrialRews{7} = [.8 .8 .8];
    vr.probeTrialRews{6} = [1.2 1.2];
    vr.probeTrialRews{5} = [2.4];
    %}
    %{
    % 6-2-18 6-2-18, 9 = [0 .6 1.2 1.8 2.4] 8 = [0 1.2 2.4 3.6 4.8], 7 = [0 1.8 3.6 5.4 7.2], 6 = [0 2.4 4.8 7.2 9.6]
    vr.probeTrialRews{9} = [.6 .6 .6 .6];
    vr.probeTrialRews{8} = [1.2 1.2 1.2 1.2];
    vr.probeTrialRews{7} = [1.8 1.8 1.8 1.8];
    vr.probeTrialRews{6} = [2.4 2.4 2.4 2.4];
    %}
    %{
     % 6-1-18, 9 = [0 .4 .8 1.2 3.6] 8 = [0 1.2 3.6], 7 = [0 .4 .8 1.2], 6 = [0 1.2]
    vr.probeTrialRews{9} = [.4 .4 .4 2.4];
    vr.probeTrialRews{8} = [1.2 2.4];
    vr.probeTrialRews{7} = [.4 .4 .4];
    vr.probeTrialRews{6} = [1.2];
    %}
    
    %{
    vr.probeTrialRews{8} = [.2 .8 5];
    vr.probeTrialRews{9} = [1 2 3];
%}
    %{
%above commented out, changed to below 5-15-18
vr.probeTrialRews{9} = [];
% below added 5-15-18
%vr.probeTrialRews{5} = [2 2 2 2];
%vr.probeTrialRews{7} = 4;
% below added 5-17 (above commented out) probes: {5} Lg[0,.4,.8,1.2]
%vr.probeTrialRews{5} = [.4 .4 .4];
% above commented out and below added 5-17 for m27, probes LgMdSm[0] + Lg[0 2.4 4.8 7.2] [0 .4 .8 1.2 4.2] [0 4.2] [0 2.2]
vr.probeTrialRews{5} = [.4 .4 .4 3];
vr.probeTrialRews{6} = [2.4 2.4 2.4];
vr.probeTrialRews{7} = 1.8;
vr.probeTrialRews{8} = 4.2;
    %}
    %{
    vr.probeTrialRews{5} = [1 1 1 1];
    vr.probeTrialRews{7} = [2 2];
    vr.probeTrialRews{9} = 2;
    vr.probeTrialRews{8} = [];
    %}
   
    
elseif vr.taskType_ID(1)==7 && vr.taskType_ID(2)==8
    
    % 5-21-18: flip reward size after t=0
    vr.probeTrialRews{9} = 2;
    vr.probeTrialRews{5} = 2;
    
    %{
    commented out 5-21
    % for probing 'leak' rate of observed signal
    %  Lg/Md [0 .2 .6 1.2 2.0], [0 1 2]
    vr.probeTrialRews{6} = [.8 1.2]; % 0 1 2
    vr.probeTrialRews{9} = [.2 .4 .6 .8];
    %}
    %{
commented out 5-9-17    
vr.probeTrialRews{6} = 2;
    vr.probeTrialRews{7} = 5;
    vr.probeTrialRews{8} = [.2 .6 1.2 3];
    %}
    
    %{
    % 4-30-18/5-2-18 version
    vr.probeTrialRews{6} = 2;
    vr.probeTrialRews{7} = 4;
    vr.probeTrialRews{8} = [1 1 2];
    %}
    %{
    % 4-30-18/5-2-18 version
    vr.probeTrialRews{6} = 3;
    vr.probeTrialRews{7} = 6;
    vr.probeTrialRews{8} = [2 4];
    %}
    %{
    *4-29-18 version
    vr.probeTrialRews{5} = 2;
    vr.probeTrialRews{6} = 4;
    vr.probeTrialRews{7} = 6;
    vr.probeTrialRews{8} = [2 4];
    vr.probeTrialRews{9} = [1 1 4];
    %}
    
elseif vr.taskType_ID(1)==7 && vr.taskType_ID(2)==9
    %{
    vr.probeTrialRews{6} = [2 4 8 16];
    vr.probeTrialRews{8} = [2 4 8 16];
    %}
    vr.probeTrialRews{6} = [1 1];
    vr.probeTrialRews{8} = [1 1];
    
    % Medium probes 762 & 782 times: [0 2 6 14 30]
    % (difference is whether they followed Sm or Lg block
    
end



%% 8 is probablistic reward schedule based on exponential decay of reward rate
vr.trialTypes_Set{8}{1} = [821 822 824 821 822 824 821 822 822 824];
vr.trialTypes_Set{8}{9} = [824 824 824];

vr.trialTypes_Set{8}{2} = [812 812 812 812 812 ...
    822 822 822 822 822 ...
    832 832 832 832 832 ...
    842 842 842 842 842 ...
    852 852 852 852 852 ...
    862 862 862 862 862 ...
    872 872 872 872 872 ...
    882 882 882 882 882 ...
    892 892 892 892 892];

% hi reward rate trials (2 highest tau, 2 highest N0)
vr.trialTypes_Set{8}{3} = [812 812 812 812 812 ...
    822 822 822 822 822 ...
    842 842 842 842 842 ...
    852 852 852 852 852];

% low reward rate trials (2 lowest tau, 2 lowest N0)
vr.trialTypes_Set{8}{4} = [892 892 892 892 892 ...
    882 882 882 882 882 ...
    862 862 862 862 862 ...
    852 852 852 852 852];

%% 9 is same as 8 but no reward at T=0 (patch goes to full illumination at that time to start PRT, previously illuminated to 50%
vr.trialTypes_Set{9}{1} = [812 812 812 812 812 ...
    822 822 822 822 822 ...
    832 832 832 832 832];
vr.trialTypes_Set{9}{2} = [812 812 812 812 812 ...
    822 822 822 822 822 ...
    832 832 832 832 832 ...
    842 842 842 842 842 ...
    852 852 852 852 852 ...
    862 862 862 862 862 ...
    872 872 872 872 872 ...
    882 882 882 882 882 ...
    892 892 892 892 892];



% vr.trialTypes_Set{2}{x} = 2 block types (initially run entire session of
% block type, switch across days, not within session until further training
% Block Hi/Lg = 3/4 patches Hi/Lg, 1/4 Md/Md (#4)
% Block Sm/Lo = 3/4 patches Sm/Lo, 1/4 Md/Md (#3)
vr.trialTypes_Set{3}{1} = [302 302 302 302 302];
vr.trialTypes_Set{3}{3} = [341 341 341 341 341 322 322 322 322 322 ...
    341 341 341 341 341 341 341 341 341 341];
vr.trialTypes_Set{3}{4} = [413 413 413 413 413 422 422 422 422 422 ...
    413 413 413 413 413 413 413 413 413 413];

%
vr.trialTypes_Set{4}{1} = [302 302 302 302 302 302 302 302 302 302 ...
    302 302 302 302 302 302 302 302 302 302];

vr.trialTypes_Set{4}{3} = [341 341 341 341 341 321 321 321 321 321 ...
    341 341 341 341 341 341 341 341 341 341 ...
    341 341 341 341 341 321 321 321 321 321 ...
    341 341 341 341 341 341 341 341 341 341]; %8/1/16 changed from 20 trials per block to 40

vr.trialTypes_Set{4}{4} = [411 411 411 411 411 421 421 421 421 421 ...
    411 411 411 411 411 411 411 411 411 411 ...
    411 411 411 411 411 421 421 421 421 421 ...
    411 411 411 411 411 411 411 411 411 411];


% set = 6
%IRI increases: 5) 2,4;  6) 1,1,1,4;  7) 2,2,2,4;  8) 1,2,3,4;  9) 1,1,1,1,1,1,4  -> after IRI=4: 6,8 or probe
vr.trialTypes_Set{6}{1} = [601 601 601 601 601];
vr.trialTypes_Set{6}{10} = [641 841 941 651 851 951 661 861 961 671 871 971 681 881 981 691 891 991];
% vr.C = 6, (after IRI=4 IRI's +2s each; C = 8 +4 each, C = 9 no more rew (probe)




if vr.taskType_ID(1)==3
    vr.diffBlocks = 1;
    if vr.fixBlock > 0 && vr.fixBlock < 5
        vr.whichBlock = vr.fixBlock; %whichBlock = 3 or 4 corresponding to vr.CBA
        %whereas currBL_ID = 1 or 2 depending on corresponding ID for
        %floor/patch ID
        BlockType_FIXED = vr.whichBlock; display(BlockType_FIXED);
    elseif vr.fixBlock >= 5
        
        vr.switchAfterBlock1 = 1; % 1 block of type 3/4 then switch for remainder of session
        % (switch value to '2' after switch)
        
        vr.whichBlock = vr.fixBlock-2; %whichBlock = 3(if 5) or 4(if 6)
        Block1_FIXED = vr.whichBlock; display(Block1_FIXED);
        
    else %randomize if not specified
        vr.whichBlock = randi([1,2])+2; %3 or 4
        BlockType_Rand = vr.whichBlock; display(BlockType_Rand);
    end
    
    switch vr.whichBlock
        
        case 3
            vr.currBL_ID = 2;
        case 4
            display('correct currBL_ID already = 1');
    end
end

%% haz rate, cum rew, & rew probabilities for prob rew task versions
if vr.taskType_ID(1)==7
    
    vr.maxRewTime = 50; % cut off at 50 seconds, when hazard rate drops below 1/1000
    vr.minInterval = 0.2; % frequency of possible reward timings
    
    % equation: hazard = N0 * e^(A*T)
    % equation: integral (cumulative reward intake curve) = N0 * 1/A * e^(A*T) - N0/A
    vr.expDecay_A = [-.125 -.125 -.125];
    vr.expDecay_N0 = [.5 .25 .125];
    vr.expDecay_times = 0:vr.minInterval:vr.maxRewTime;
    
    vr.expDecay_prevRew = 0; % for subtracting to calculate time to next reward
    %vr.expDecay_currRew = 0;
    
    A = vr.expDecay_A;
    N0 = vr.expDecay_N0;
    T = vr.expDecay_times;
    
    
    for iParameters = 1:length(vr.expDecay_A)
        
        expDecay_Haz{iParameters} = zeros(1,length(vr.expDecay_times));
        expDecay_Int{iParameters} = zeros(1,length(vr.expDecay_times));
        expDecay_RewProb{iParameters} = zeros(1,length(vr.expDecay_times));
        
        for iTime=1:length(vr.expDecay_times)
            % exponential decay of hazard rate
            expDecay_Haz{iParameters}(iTime) = N0(iParameters)*exp(A(iParameters)*T(iTime));
            
            % cumulative reward function (integral of expDecay_Haz)
            % *** does not account for initial reward at time t = 0, and does
            % not account for different reward sizes ***
            expDecay_Int{iParameters}(iTime) = (N0(iParameters)*(1/A(iParameters))*exp(A(iParameters)*T(iTime)))-N0(iParameters)*(1/A(iParameters))*exp(A(iParameters)*T(1));
            
            % reward probabilities for each time point
            if iTime>1
                expDecay_RewProb{iParameters}(iTime) = expDecay_Int{iParameters}(iTime)-expDecay_Int{iParameters}(iTime-1);
            else
                expDecay_RewProb{iParameters}(iTime) = 0; % (reward probability is actually 1 at t=0, but this value is not used to compute that)
            end
        end
    end
    
    vr.expDecay_Haz = expDecay_Haz;
    vr.expDecay_Int = expDecay_Int;
    vr.expDecay_RewProb = expDecay_RewProb;
    
    vr.expDecay_Indx = 1; % use to keep track of index for next probabilistically assigned reward timing
    
    %vr.RewTimes2{1} = []; % use to keep track of probRewTimes for earned rewards
    vr.RewTimes{1} = [];
    vr.RewTimes_thisPatch = 0;
    vr.RewTimes_patchNum = 1; % use as index for RewTimes
    
    if ~vr.debugMode
        vr.filenameRewTimes = ['RewTimes',datestr(now,'yymmdd_HHMM')]; %data for each patch
        RewTimes = [];
        save([vr.pathname '\' vr.filenameRewTimes '.mat'],'RewTimes');
    end
    
    vr.expDecay_tau = []; % will be unused but set to someting so no error later when saving
    
elseif vr.taskType_ID(1)==8 || vr.taskType_ID(1)==9
    
    vr.maxRewTime = 50; % cut off at 50 seconds, when hazard rate drops below 1/1000
    vr.minInterval = 0.2; % frequency of possible reward timings
    
    % equation: hazard = N0 * e^(-T/tau)
    %vr.expDecay_A = [-.125 -.125 -.125];
    
    vr.expDecay_tau = [8 4 2 8 4 2 8 4 2];
    vr.expDecay_N0 = [1 1 1 .5 .5 .5 .25 .25 .25];
    vr.expDecay_times = 0:vr.minInterval:vr.maxRewTime;
    
    vr.expDecay_prevRew = 0; % for subtracting to calculate time to next reward
    %vr.expDecay_currRew = 0;
    
    %A = vr.expDecay_A;
    tau = vr.expDecay_tau;
    N0 = vr.expDecay_N0;
    T = vr.expDecay_times;
    
    
    for iParameters = 1:length(vr.expDecay_tau)
        
        expDecay_Haz{iParameters} = zeros(1,length(vr.expDecay_times));
        expDecay_Int{iParameters} = zeros(1,length(vr.expDecay_times));
        expDecay_RewProb{iParameters} = zeros(1,length(vr.expDecay_times));
        
        for iTime=1:length(vr.expDecay_times)
            % exponential decay of hazard rate
            expDecay_Haz{iParameters}(iTime) = N0(iParameters)*exp(-T(iTime)/tau(iParameters));
            
            % cumulative reward function (integral of expDecay_Haz)
            % *** does not account for initial reward at time t = 0, and does
            % not account for different reward sizes ***
            expDecay_Int{iParameters}(iTime) = N0(iParameters)*tau(iParameters)*(1-exp(-T(iTime)/tau(iParameters)));
            
            % reward probabilities for each time point
            if iTime>1
                expDecay_RewProb{iParameters}(iTime) = expDecay_Int{iParameters}(iTime)-expDecay_Int{iParameters}(iTime-1);
            else
                expDecay_RewProb{iParameters}(iTime) = 0; % (reward probability is actually 1 at t=0, but this value is not used to compute that)
            end
        end
    end
    
    vr.expDecay_Haz = expDecay_Haz;
    vr.expDecay_Int = expDecay_Int;
    vr.expDecay_RewProb = expDecay_RewProb;
    
    vr.expDecay_Indx = 1; % use to keep track of index for next probabilistically assigned reward timing
    
    %vr.RewTimes2{1} = []; % use to keep track of probRewTimes for earned rewards
    vr.RewTimes{1} = [];
    vr.RewTimes_thisPatch = 0;
    vr.RewTimes_patchNum = 1; % use as index for RewTimes
    
    if ~vr.debugMode
        vr.filenameRewTimes = ['RewTimes',datestr(now,'yymmdd_HHMM')]; %data for each patch
        RewTimes = [];
        save([vr.pathname '\' vr.filenameRewTimes '.mat'],'RewTimes');
    end
    
    %% sanity check plot to test functions-
    %{
    xmax= 20;
    ymax= 8;
    figure;
    subplot(3,1,1)
    plot(vr.expDecay_times,vr.expDecay_Int{1},'b'); hold on;
    plot(vr.expDecay_times,vr.expDecay_Int{2},'b--');
    plot(vr.expDecay_times,vr.expDecay_Int{3},'b:');
    plot(vr.expDecay_times,vr.expDecay_Int{4},'c');
    plot(vr.expDecay_times,vr.expDecay_Int{5},'c--');
    plot(vr.expDecay_times,vr.expDecay_Int{6},'c:');
    plot(vr.expDecay_times,vr.expDecay_Int{7},'g');
    plot(vr.expDecay_times,vr.expDecay_Int{8},'g--');
    plot(vr.expDecay_times,vr.expDecay_Int{9},'g:');
    
    xlim([0 xmax])
    ylim([0 ymax])

    subplot(3,1,2)
    plot(vr.expDecay_times,vr.expDecay_Haz{1},'b'); hold on;
    plot(vr.expDecay_times,vr.expDecay_Haz{2},'b--');
    plot(vr.expDecay_times,vr.expDecay_Haz{3},'b:');
    plot(vr.expDecay_times,vr.expDecay_Haz{4},'c');
    plot(vr.expDecay_times,vr.expDecay_Haz{5},'c--');
    plot(vr.expDecay_times,vr.expDecay_Haz{6},'c:');
    plot(vr.expDecay_times,vr.expDecay_Haz{7},'g');
    plot(vr.expDecay_times,vr.expDecay_Haz{8},'g--');
    plot(vr.expDecay_times,vr.expDecay_Haz{9},'g:');
    xlim([0 xmax])
    
    subplot(3,1,3)
    plot(vr.expDecay_times,vr.expDecay_RewProb{1},'b'); hold on;
    plot(vr.expDecay_times,vr.expDecay_RewProb{2},'b--');
    plot(vr.expDecay_times,vr.expDecay_RewProb{3},'b:');
    plot(vr.expDecay_times,vr.expDecay_RewProb{4},'c');
    plot(vr.expDecay_times,vr.expDecay_RewProb{5},'c--');
    plot(vr.expDecay_times,vr.expDecay_RewProb{6},'c:');
    plot(vr.expDecay_times,vr.expDecay_RewProb{7},'g');
    plot(vr.expDecay_times,vr.expDecay_RewProb{8},'g--');
    plot(vr.expDecay_times,vr.expDecay_RewProb{9},'g:');
    xlim([0 xmax])
    %}
    
end


vr.blockTypes = [vr.taskType_ID(2) vr.taskType_ID(2) vr.taskType_ID(2) vr.taskType_ID(2)];
vr.blockNum = 1; %total block count
vr.thisBlock  = 1; %count within cycle
%perm1 = randperm(length(vr.blockTypes)); %randomize blocks
%vr.blockTypes = vr.blockTypes(perm1);
vr.currentBlock = vr.blockTypes(vr.thisBlock);
vr.blockHistory = vr.currentBlock;
vr.repeatBlocks = 0;
vr.prevBlockType = 0;

%training stage == 0 (deliver water at 1/2 or 3/4 of patch OR if patchstop
%after patch on), use progressive ratio for patch distances
vr.progRatioDist = [5 10 15 20 25 30 35 40 45 50 60 70 80 90 100]; %60-100 added 8-6-16

if vr.trainingStage==0
    
    vr.patchesMove = 1;
    
    if vr.progRatioStart > 0
        vr.progRatio = vr.progRatioStart;
        progRatioStart = vr.progRatioStart; display(progRatioStart);
    else
        vr.progRatio = 1;
    end
else
    vr.progRatio = 0; % >0 if using progRatio, use same variable to keep track of indx within vr.progRatioDist
end

vr.TS1_SW = 0; %in early training mouse must wait 0.5s after pach appears before stop = rew
vr.TS1_delay = 0.5;

vr.trialTypes = vr.trialTypes_Set{vr.taskType_ID(1)}{vr.blockTypes(vr.thisBlock)};

%trialTprint = [vr.trialTypes_Set]
%taskTprint = vr.taskType_ID
%blockTprint = vr.blockTypes
%thisBlock = vr.thisBlock
%trailTypesPrint9 = vr.trialTypes_Set{vr.taskType_ID(1)}
%trialTypesPrint = vr.trialTypes_Set{vr.taskType_ID(1)}{vr.blockTypes(vr.thisBlock)}

%randomize trial order
if vr.taskType_ID(1)==4 || vr.switchAfterBlock1 == 1 %do not randomize first 5 of block if taskType_ID(1) == 4 - or for switchAfter1
    perm4 = randperm(length(vr.trialTypes)-5)+5;
    display(perm4);
    vr.trialTypes = [vr.trialTypes(1:5) vr.trialTypes(perm4)];
    TT4 = vr.trialTypes; display(TT4);
elseif vr.taskType_ID(1)==7 && vr.taskType_ID(2)==9
    
    prevTrialOrder = vr.trialTypes; display(prevTrialOrder)
    flipCoin = randi(2);
    if flipCoin==2
        % switch Sm/Lg block order
        
    vr.trialTypes = [vr.trialTypes(end/2+1:end) vr.trialTypes(1:end/2)];
    flipTrialOrder = vr.trialTypes; display(flipTrialOrder)
    else
        %no change
        sameTrialOrder = vr.trialTypes; display(sameTrialOrder)
    end
    
else
    
    perm2 = randperm(length(vr.trialTypes)); %randomize trial order
    vr.trialTypes = vr.trialTypes(perm2);
end

vr.thisTrial = 1; %index # within vr.trialTypes loop
vr.CBA = 0; %vr.DCBA = 0;
vr.A = 0; vr.B = 0; vr.C = 0;

if vr.travelType == 1
    vr.patchB_top = vr.IPI + vr.patchHeight;
    vr.patchB_bottom = vr.IPI;
    vr.patchB_mid = vr.patchB_bottom + .5*vr.patchHeight; %reassigned in case vr.IPI not == 50
    
    vr.stopBoundA_top = vr.patchA_top-2;
    vr.stopBoundA_bottom = vr.patchA_bottom;
    vr.stopBoundB_bottom = vr.patchB_bottom;
    vr.waitBoundA_top = vr.patchA_top-1;
    vr.waitBoundA_bottom = vr.patchA_bottom-5;
    vr.waitBoundB_bottom = vr.patchB_bottom-5;
    
    patchB_BOTTOM = vr.patchB_bottom; display(patchB_BOTTOM);
    
    vr.patchAppear = vr.stopBoundB_bottom - vr.appearBefore;
    if vr.dispSet > 0
        patchAppear = vr.patchAppear;
        display(patchAppear);
    end
    
    
    
    vr.trackLength = vr.patchB_bottom - vr.patchA_top;
    
else % move patchBs away if travelType > 1
    vr.patchB_top = 999;
    vr.patchB_bottom = 990;
    vr.patchB_mid = 995;
    
    display('wtf?');
    
    vr.stopBoundA_top = vr.patchA_top-2;
    vr.stopBoundA_bottom = vr.patchA_bottom;
    vr.stopBoundB_bottom = 999;
    vr.waitBoundA_top = vr.patchA_top-1;
    vr.waitBoundA_bottom = vr.patchA_bottom-5;
    vr.waitBoundB_bottom = 999;
    
    vr.trackLength = 999;
    
end

%calibrations 1/27
%15 = 2 uL
%34 = 4 uL
%47 = 6 uL
%75 = 8 uL


vr.onXLgh2o = 4;
vr.onLgh2o = 3;
vr.onMdh2o = 2;
vr.onSmh2o = 1;
vr.XLgRew = 23; vr.MdRew = 12; vr.SmRew = 7; %4-19-18
vr.LgRew = 16; % Lg not measured this calibration*
%10/25 changed from 18->14 for 'medium', measured at 1.5uL
%(for current task size not varied so any one size is fine as long as consistent throughout)

%vr.XLgRew = 47; vr.LgRew = 34; vr.MdRew = 17; vr.SmRew = 10;


%set reward valve open times
vr.SR = 1000; %STOP HARDCODING THIS, FIX W CODE TO EXTRACT VALUE FROM .AO
vr.vSnd = 5 * ones(20*vr.SR,1); vr.vSnd(1:2:end) = vr.vSnd(1:2:end) * -1;
vr.iSndOff = floor(0.08 * vr.SR);
vr.vSnd(vr.iSndOff:end) = 0;

%water sizes (valve opening): NEED TO RECALLIBRATE
%vr.onSm =  [5 * ones(floor(vr.SmRew/1000*vr.SR),1 ); zeros(1, 1)]; vr.onSm = [vr.onSm .5*vr.vSnd(1:length(vr.onSm))];
vr.onSm =  [5 * ones(floor(vr.SmRew/1000*vr.SR),1 ); zeros(1, 1)]; vr.onSm = [vr.onSm zeros(length(vr.onSm),1) zeros(length(vr.onSm),1) zeros(length(vr.onSm),1)];

%vr.onMd =  [5 * ones(floor(vr.MdRew/1000*vr.SR),1 ); zeros(1, 1)]; vr.onMd = [vr.onMd .5*vr.vSnd(1:length(vr.onMd))];
vr.onMd =  [5 * ones(floor(vr.MdRew/1000*vr.SR),1 ); zeros(1, 1)]; vr.onMd = [vr.onMd zeros(length(vr.onMd),1) zeros(length(vr.onMd),1) zeros(length(vr.onMd),1)];

%vr.onLg =  [5 * ones(floor(vr.LgRew/1000*vr.SR),1 ); zeros(1, 1)]; vr.onLg = [vr.onLg .5*vr.vSnd(1:length(vr.onLg))];
vr.onLg =  [5 * ones(floor(vr.LgRew/1000*vr.SR),1 ); zeros(1, 1)]; vr.onLg = [vr.onLg zeros(length(vr.onLg),1) zeros(length(vr.onLg),1) zeros(length(vr.onLg),1)];

%vr.onXLg =  [5 * ones(floor(vr.XLgRew/1000*vr.SR),1 ); zeros(1, 1)]; vr.onXLg = [vr.onXLg .5*vr.vSnd(1:length(vr.onXLg))];
vr.onXLg =  [5 * ones(floor(vr.XLgRew/1000*vr.SR),1 ); zeros(1, 1)]; vr.onXLg = [vr.onXLg zeros(length(vr.onXLg),1) zeros(length(vr.onXLg),1) zeros(length(vr.onXLg),1)];

vr.scaling = vr.scalingStandard/vr.scaledown;
%stnd_sdown_scaling = [vr.scalingStandard vr.scaledown vr.scaling];
%display(stnd_sdown_scaling);

vr.event_patchOnXHi = [zeros(10,1) 4*ones(10,1) zeros(10,1) zeros(10,1)];
vr.event_patchOnHi = [zeros(10,1) 3*ones(10,1) zeros(10,1) zeros(10,1)];
vr.event_patchOnMd = [zeros(10,1) 2*ones(10,1) zeros(10,1) zeros(10,1)];
vr.event_patchOnLo = [zeros(10,1) 1*ones(10,1) zeros(10,1) zeros(10,1)];
vr.event_patchOff_1s = [zeros(10,1) -1*ones(10,1) zeros(10,1) zeros(10,1)];



for iA = 1:4
    for iB = 1:9
        
        vr.event_patchOnProbeID{iB}{iA} = [zeros(10,1) (iA+.1*iB)*ones(10,1) zeros(10,1) zeros(10,1)];
    end
end


if ~vr.debugMode
    % start generating pulse by signaling to Arduino board
    putvalue(vr.dio.Line(2), 1);
end

mouseID = vr.mouseID; trainingStage = vr.trainingStage;
display(mouseID);
display(trainingStage);

%% DELIVER 2uL WATER TO START SESSION
if ~vr.debugMode
    %vr.manualRewSm = [vr.manualRewSm,now];
    out_data = vr.onMd;
    vr.totalWater = vr.totalWater + vr.onMdh2o;
    display('829: sm rew manual delivery')
    putdata(vr.ao, out_data);
    start(vr.ao);
    trigger(vr.ao);
    display(datestr(now));
    %plot licks
    % retrieve analog input data
    %[data, time, abstime] = getdata(vr.ai, min([vr.ai.SamplesAvailable*1.02 vr.SR * 10]));
    [data, time, abstime] = getdata(vr.ai, vr.ai.SamplesAvailable*1.02);
    
    figure;
    plot(time, data(:, [1:4]));
    %plot(time, data(:,3)) % probably data(:,3)
    % flush remaining data in memory
    %flushdata(vr.ai, 'all');
end

if vr.currBL_ID > 1
    display('SWITCH TO APPROPRIATE FLOORS/PATCHES');
    
    %move floors{:}{1} away and currBL_ID floors back into place
    for k = 1:length(vr.indx_floor)
        % {1} away and invisible
        vr.worlds{vr.currentWorld}.surface.colors(4,vr.floorIndx{k}{1}) = 0;
        vr.worlds{vr.currentWorld}.surface.vertices(3, vr.floorIndx{k}{1}) = ...
            vr.floor_zOrig{k}{1} + 60;
        %floors{:}{currBL_ID} orig coordinates and visible
        vr.worlds{vr.currentWorld}.surface.colors(4,vr.floorIndx{k}{vr.currBL_ID}) = 1;
        vr.worlds{vr.currentWorld}.surface.vertices(3, vr.floorIndx{k}{vr.currBL_ID}) = ...
            vr.floor_zOrig{k}{vr.currBL_ID};
        
    end
end
if vr.travelType > 1
    %move away all floor 2s
    for k = 1:length(vr.indx_floor{2})
        confirmlengthequals2 = length(vr.indx_floor{2}); display(confirmlengthequals2);
        % {1} away and invisible
        vr.worlds{vr.currentWorld}.surface.colors(4,vr.floorIndx{2}{k}) = 0;
        vr.worlds{vr.currentWorld}.surface.vertices(3, vr.floorIndx{2}{k}) = ...
            vr.floor_zOrig{2}{k} + 60;
    end
    
end



%% --- RUNTIME code: executes on every iteration of the ViRMEn engine.
function vr = runtimeCodeFun(vr)
velocity_begin=vr.velocity; %display(velocity_begin)

vr.dp_cache = vr.dp; % cache current displacement value to store
%treadmill velocity it even in versions of task where vr.dp is set to 0

vr.traveltime_SW = vr.traveltime_SW + vr.dt;
vr.traveltime2_SW = vr.traveltime2_SW + vr.dt;

if vr.event_patchOn > 0
    vr.event_patchOn = 0;
    
    if vr.taskType_ID(1)==2 || vr.taskType_ID(1)==5 || vr.taskType_ID(1)==7 || vr.taskType_ID(1)==8 || vr.taskType_ID(1)==9
        %display('890: patchOn');
        
        if vr.taskType_ID(1)==7 && vr.B > 4 && (vr.taskType_ID(2)==7 || vr.taskType_ID(2)==8 || vr.taskType_ID(2)==9)
            %probe trial
            
            out_data = vr.event_patchOnProbeID{vr.B}{vr.A};
            
            
            
        else
            
            switch vr.taskType_ID(1)
                case {2,5,7,8,9} %redundant but kinda necessary, if you know what i mean <-- what the fuck is that supposed to mean??
                    
                    switch vr.A
                        case 1
                            %display('896 outdata patchOnLo');
                            out_data = vr.event_patchOnLo;
                        case 2
                            %display('899 outdata patchOnMd');
                            out_data = vr.event_patchOnMd;
                        case 3
                            %display('902 outdata patchOnHi');
                            out_data = vr.event_patchOnHi;
                        case 4
                            %display('905 outdata patchOnXHi');
                            out_data = vr.event_patchOnXHi;
                    end
                    if vr.dispSet > 0
                        display('outdata patchOn');
                    end
            end
        end
        
        putdata(vr.ao, out_data);
        start(vr.ao);
        trigger(vr.ao);
    end
end

if vr.event_patchOff > 0
    vr.event_patchOff = 0;
    if vr.dispSet > 0
        display('outdata patchOff_.5s_858');
    end
    out_data = vr.event_patchOff_1s;
    putdata(vr.ao, out_data);
    start(vr.ao);
    trigger(vr.ao);
end

if vr.travelType > 1
    vr.dp(2) = 0; %reset y displacement to 0 in non-speed-controlled task versions
end

if vr.plotLicks_SW_on > 0 % plots licks after each reward deliver, right?
    vr.plotLicks_SW = vr.plotLicks_SW + vr.dt;
    if vr.plotLicks_SW > vr.plotLicks_plotTime
        vr.plotLicks_SW_on = 0;
        vr.plotLicks_SW = 0;
        
        % retrieve analog input data
        %[data, time, abstime] = getdata(vr.ai, vr.ai.SamplesAvailable*1.02);
        
        %[data, time, abstime] = getdata(vr.ai, min([vr.ai.SamplesAvailable*1.02 vr.SR * 20])); % 1000 * 8
        
        data = peekdata(vr.ai, min([vr.ai.SamplesAvailable*1.02 vr.SR * 20])); % 1000 * 8
        flushdata(vr.ai, 'all');
        
        vr.data1temp = [vr.data1temp; data(:,1)];
        vr.data2temp = [vr.data2temp; data(:,2)];
        vr.data3temp = [vr.data3temp; data(:,3)];
        vr.data4temp = [vr.data4temp; data(:,4)];
        
        %vr.timeXtemp = [vr.timeXtemp; time];
        
        plot([vr.data1temp vr.data2temp vr.data3temp vr.data4tem]);
        
        if vr.dispSet > 0
            display('post-rew plot (no flush)');
        end
    end
end
if vr.plotLicks_flushSW_on > 0
    
    if vr.plotLicks_flushSW_on==1
        vr.plotLicks_flushSW_on = 2;
        if vr.dispSet > 0
            display('plotLicks_flushSW_on 1->2 (initiate)');
        end
    end
    
    vr.plotLicks_flushSW = vr.plotLicks_flushSW + vr.dt;
    if vr.plotLicks_flushSW > vr.plotLicks_flushTime
        vr.plotLicks_flushSW_on = 0;
        vr.plotLicks_flushSW = 0;
        vr.plotLicks_flush = 1;
    end
end

%plots the licks/speed after leaving patch
if vr.plotLicks_flush > 0
    
    %[data, time, abstime] = getdata(vr.ai, min([vr.ai.SamplesAvailable*1.02 vr.SR * 60]));
    %[data, time, abstime] = getdata(vr.ai, vr.ai.SamplesAvailable*1.02);
    
    %[data, time, abstime] = getdata(vr.ai, min([vr.ai.SamplesAvailable*1.02 vr.SR * 20])); % 1000 * 8
    
    data = peekdata(vr.ai, min([vr.ai.SamplesAvailable*1.02 vr.SR * 20])); % 1000 * 8
    flushdata(vr.ai, 'all');
    
    vr.data1temp = [vr.data1temp; data(:,1)];
    vr.data2temp = [vr.data2temp; data(:,2)];
    vr.data3temp = [vr.data3temp; data(:,3)];
    vr.data4temp = [vr.data4temp; data(:,4)];

    
    %vr.timeXtemp = [vr.timeXtemp; time];
    
    
    %plot licks
    vr.plotLicks_flush = 0;
    
    plot([vr.data1temp vr.data2temp vr.data3temp vr.data4temp]);
    
    
    %}
    flushdata(vr.ai, 'all');
    %display('plot licks post-leave: yes flush');
    vr.data1temp = [];
    vr.data2temp = [];
    vr.data3temp = []; %reset for next trial
    vr.data4temp = [];

    
    vr.event_patchOff = 1; %display('patch OFF triggered TTL');
    if vr.dispSet > 0
        display('event_patchOff_950')
    end
end

%% wait for rewards
if vr.foraging > 0
    
    %run one time per initial stop on patch
    if vr.foraging == 1
        vr.foraging_SW = 0;
        vr.nextRew_SW = 0;
        vr.rewCounter = 1;
        
        % reset timing index & previous reward time for probabilistic task
        if vr.taskType_ID(1)==7 || vr.taskType_ID(1)==8 || vr.taskType_ID(1)==9
            vr.expDecay_Indx = 1;
            vr.expDecay_prevRew = 0;
            vr.RewTimes_thisPatch = [];
            if vr.dispSet > 0
                display('expDecay_Indx reset to 1, expDecay_prevRew = 0')
            end
            
        end
        
        %reset speed_circ_queue_leave
        if vr.travelType > 1
            vr.spd_circ_queue_leave= zeros(vr.queue_len_leave, 1);
            vr.queue_idx_leave = 1;
            if vr.dispSet > 0
                display('leave queue initialized');
            end
            vr.leaveQInitTime = now;
            vr.leaveQEligible = 0; % not eligible to leave until run through speedqueue once
            
            %probably necessary
            vr.isMoving = 0;
            vr.isMov_patchOn = 0;
        end
        
        vr.foraging = 3; % (3 because goes to 2 for each new reward, 3 between rews)
        
        % compute current interval to next reward
        if vr.taskType_ID(1) <= 4 %types 1-5 use fixed rates of increase IRI
            vr.nextRew_DUR = (vr.rewCounter)*vr.rateIncrease;
            
        elseif vr.taskType_ID(1)==5
            vr.nextRew_DUR = (vr.B*2^vr.rewCounter)/2;
            
            
        elseif vr.taskType_ID(1)==7 && vr.taskType_ID(2)>6 && vr.B > 4
            disp('*probe trial*')
            B = vr.B;
            
            vr.RewTimes_thisPatch = [vr.RewTimes_thisPatch vr.expDecay_prevRew];
            
            RewTimes_thisPatch = [vr.CBA vr.RewTimes_thisPatch];
            display(RewTimes_thisPatch)
            
            
            
            if length(vr.RewTimes_thisPatch)>length(vr.probeTrialRews{B})
                vr.nextRew_DUR = 999; ProbeTrial_PatchDepleted = 999;
                display(ProbeTrial_PatchDepleted)
                RewTimes_thisPatch = [vr.CBA vr.RewTimes_thisPatch];
                display(RewTimes_thisPatch)
            else
                probeType = B; display(probeType);
                vr.nextRew_DUR = vr.probeTrialRews{B}(length(vr.RewTimes_thisPatch));
                vr.expDecay_prevRew = vr.expDecay_prevRew + vr.nextRew_DUR;
            end
            
        elseif vr.taskType_ID(1)==7 || vr.taskType_ID(1)==8 || vr.taskType_ID(1)==9
            
            B = vr.B;
            if vr.dispSet > 0
                display(B)
            end
            
            B = vr.B;
            
            vr.RewTimes_thisPatch = [vr.RewTimes_thisPatch vr.expDecay_prevRew];
            
            RewTimes_thisPatch = [vr.CBA vr.RewTimes_thisPatch];
            display(RewTimes_thisPatch)
            
            for i = vr.expDecay_Indx+1:1:length(vr.expDecay_RewProb{B})+1
                
                if i > length(vr.expDecay_RewProb{B})
                    vr.nextRew_DUR = 999; PATCH_DEPLETED = 999;
                    display(PATCH_DEPLETED)
                    RewTimes_thisPatch = [vr.CBA vr.RewTimes_thisPatch];
                    display(RewTimes_thisPatch)
                    
                else
                    n = rand; % draw rand number between 0 - 1 to compare to
                    
                    if vr.dispSet > 0
                        i_prob_rand = [i vr.expDecay_RewProb{B}(i) n];
                        display(i_prob_rand)
                    end
                    
                    if n < vr.expDecay_RewProb{B}(i)
                        vr.nextRew_DUR = vr.expDecay_times(i) - vr.expDecay_prevRew;
                        vr.expDecay_Indx = i;
                        
                        rewDur_Next_Prev = [vr.nextRew_DUR vr.expDecay_times(i) vr.expDecay_prevRew];
                        if vr.dispSet > 0
                            display(rewDur_Next_Prev)
                        end
                        
                        % update value for 'prevRew' to next reward time
                        % (value unused until this next reward becomes 'previous'
                        vr.expDecay_prevRew = vr.expDecay_times(i);
                        
                        break
                        
                    end
                end
            end
            
        else
            
            display('ERROR UNRECOGNIZED VALUE ERROR ERROR')
            
        end
        
        %% switch reward size for probe trial
        if vr.taskType_ID(1)==7 && vr.taskType_ID(2)==8 && vr.B >8
            switch vr.A
                case 4
                    vr.A = 2;  A = vr.A; display(A)
                case 2
                    vr.A = 4; A = vr.A; display(A)
            end
        end
        
        firstIRI = vr.nextRew_DUR;
        display(firstIRI);
    end
    
    %run one time per each subsequent reward delivery on patch
    if vr.foraging == 2
        
        vr.foraging = 3;
        
        %% compute current interval to next reward
        if vr.taskType_ID(1) <= 4
            vr.nextRew_DUR = (vr.rewCounter)*vr.rateIncrease;
        elseif vr.taskType_ID(1)==5
            vr.nextRew_DUR = (vr.B*2^vr.rewCounter)/2;
            
        elseif vr.taskType_ID(1)==7 && vr.taskType_ID(2)>6 && vr.B > 4
            disp('*probe rew*')
            B = vr.B;
            
            vr.RewTimes_thisPatch = [vr.RewTimes_thisPatch vr.expDecay_prevRew];
            
            RewTimes_thisPatch = [vr.CBA vr.RewTimes_thisPatch];
            display(RewTimes_thisPatch)
            
            if length(vr.RewTimes_thisPatch)>length(vr.probeTrialRews{B})
                vr.nextRew_DUR = 999; ProbeTrial_PatchDepleted = 999;
                display(ProbeTrial_PatchDepleted)
                RewTimes_thisPatch = [vr.CBA vr.RewTimes_thisPatch];
                display(RewTimes_thisPatch)
            else
                probeType = B; display(probeType);
                vr.nextRew_DUR = vr.probeTrialRews{B}(length(vr.RewTimes_thisPatch));
                vr.expDecay_prevRew = vr.expDecay_prevRew + vr.nextRew_DUR;
            end
            
        elseif vr.taskType_ID(1)==7 || vr.taskType_ID(1)==8 || vr.taskType_ID(1)==9
            
            B = vr.B;
            
            vr.RewTimes_thisPatch = [vr.RewTimes_thisPatch vr.expDecay_prevRew];
            
            RewTimes_thisPatch = [vr.CBA vr.RewTimes_thisPatch];
            display(RewTimes_thisPatch)
            
            for i = vr.expDecay_Indx+1:1:length(vr.expDecay_RewProb{B})+1
                
                if i > length(vr.expDecay_RewProb{B})
                    vr.nextRew_DUR = 999; PATCH_DEPLETED = 999;
                    display(PATCH_DEPLETED)
                    RewTimes_thisPatch = [vr.CBA vr.RewTimes_thisPatch];
                    display(RewTimes_thisPatch)
                    
                else
                    n = rand; % draw rand number between 0 - 1 to compare to
                    
                    if vr.dispSet > 0
                        i_prob_rand = [i vr.expDecay_RewProb{B}(i) n];
                        display(i_prob_rand)
                    end
                    
                    if n < vr.expDecay_RewProb{B}(i)
                        vr.nextRew_DUR = vr.expDecay_times(i) - vr.expDecay_prevRew;
                        vr.expDecay_Indx = i;
                        
                        rewDur_Next_Prev = [vr.nextRew_DUR vr.expDecay_times(i) vr.expDecay_prevRew];
                        if vr.dispSet > 0
                            display(rewDur_Next_Prev)
                        end
                        
                        % update value for 'prevRew' to next reward time
                        % (value unused until this next reward becomes 'previous'
                        vr.expDecay_prevRew = vr.expDecay_times(i);
                        
                        break
                        
                    end
                end
            end
        else
            
            display('error unrecognized: CHECK WHY/WHEN THIS LINE RAN CHECK WHY THIS LINE RAN');
            
            
        end
        
        %% switch reward size for probe trial
        if vr.taskType_ID(1)==7 && vr.taskType_ID(2)==8 && vr.B >8
            switch vr.A
                case 4
                    vr.A = 2;  A = vr.A; display(A)
                case 2
                    vr.A = 4; A = vr.A; display(A)
            end
        end
        
        %%
        currIRI = vr.nextRew_DUR;
        display(currIRI);
    end
    
    % update stopwatches and leave queue speed
    vr.nextRew_SW = vr.nextRew_SW + vr.dt; % SW for this reward
    vr.foraging_SW = vr.foraging_SW + vr.dt; %keep SW for entire patch stay
    
    
    %PATCH LEAVE (travelType 1)
    
    if (vr.travelType==1 && ((vr.onPatch == 2 && vr.position(2) >  vr.waitBoundA_top) || ...
            (vr.position(2) <  vr.waitBoundA_bottom) || ...
            (vr.onPatch ==1 && vr.position(2) <  vr.waitBoundB_bottom)))
        
        %start timer for save/plot/flush lick data
        vr.plotLicks_SW = 0;
        vr.plotLicks_SW_on = 0;
        vr.plotLicks_flushSW = 0;
        vr.plotLicks_flushSW_on = 1;
        if vr.dispSet > 0
            display('vr.plotLicks_flushSW_on = 1 _ 1502');
        end
        
        c_timeStamp = now;
        c_trialNum = vr.trialNum;
        c_trialType = vr.CBA;
        
        %store patchData
        numRews = vr.rewCounter;
        leaveInterval = vr.nextRew_DUR;
        foragingTime = vr.foraging_SW;
        
        c_event = vr.CBA; display(c_event);
        
        if vr.travelType == 1
            if vr.onPatch == 2 && vr.position(2) >= vr.waitBoundA_top
                if vr.dispSet > 0
                    display('patchA exit: top');
                end
                vr.meltA = 1;
            elseif vr.position(2) < vr.waitBoundA_bottom
                display('patchA exit: back');
                vr.meltA = 1;
            else %vr.onPatch == 1 && vr.position(2) < vr.waitBoundB_bottom
                display('patchB exit: back');
                vr.meltAB = 1;
            end
        end
        
        c_foragingTime = vr.foraging_SW;
        
        vr.eventData = [vr.eventData, c_trialNum, c_trialType, c_event, c_timeStamp];
        eventData = vr.eventData;
        vr.patchData = [vr.patchData c_trialNum c_trialType numRews leaveInterval foragingTime];
        patches = vr.patchData;
        
        if ~vr.debugMode
            %save data from patch
            save([vr.pathname '\' vr.filenameEvents '.mat'],'eventData','-append');
            save([vr.pathname '\' vr.filenamePatches '.mat'],'patches','-append');
        end
        
        
        if vr.taskType_ID(1)==7 || vr.taskType_ID(1)==8 || vr.taskType_ID(1)==9
            %vr.RewTimes2 = [vr.RewTimes2 vr.RewTimes_thisPatch];
            
            vr.RewTimes{vr.RewTimes_patchNum} = [vr.CBA vr.RewTimes_thisPatch c_foragingTime];
            vr.RewTimes_patchNum = vr.RewTimes_patchNum + 1;
            
            %RewTimes_thisPatch2 = [vr.CBA vr.RewTimes_thisPatch];
            %display(RewTimes_thisPatch2)
            
            RewTimes_thisPatch = [vr.CBA vr.RewTimes_thisPatch c_foragingTime];
            display(RewTimes_thisPatch)
            
            % ***
            if ~vr.debugMode
                RewTimes = vr.RewTimes;
                save([vr.pathname '\' vr.filenameRewTimes '.mat'],'RewTimes');
            end
        end
        
        vr.foraging = 0;
        %vr.foraging_SW = 0;
        vr.nextRew_SW = 0;
        vr.eligibleRew = 0;
        
        display(c_foragingTime);
        
    elseif vr.nextRew_SW >= vr.nextRew_DUR
        
        vr.foraging = 2;
        vr.nextRew_SW = 0;
        vr.rewEarned = vr.A;
        vr.rewCounter = vr.rewCounter + 1;
        
    end
end

%% DETECT STOP ON PATCH
if vr.foraging == 0 && vr.eligibleRew > 0 && vr.travelType == 1
    
    %patchAppear = vr.patchAppear; display(patchAppear);
    
    %%turn patches on, move floors 1 and 2
    if vr.position(2) > vr.patchAppear
        
        %display('vr position 2 patch appear');
        
        %% switch patches if block change
        if vr.BL_switchTo > 0
            switchTo = vr.BL_switchTo;
            if switchTo == 1
                switchFrom = 2;
            else
                switchFrom = 1;
            end
            switch_to_from = [switchTo switchFrom];
            display(switch_to_from);
            
            vr.BL_switchTo = 0; %reset
            vr.currBL_ID = switchTo;
            % **correct patches should automatically move into place/visible**
            display('SWITCH TO APPROPRIATE FLOORS');
            
            %move floors{:}{1} away and currBL_ID floors back into place
            for k = 1:length(vr.indx_floor)
                
                % {switchFrom} away and invisible
                vr.worlds{vr.currentWorld}.surface.colors(4,vr.floorIndx{k}{switchFrom}) = 0;
                vr.worlds{vr.currentWorld}.surface.vertices(3, vr.floorIndx{k}{switchFrom}) = ...
                    vr.floor_zOrig{k}{switchFrom} + 60;
                
                %floors{:}{currBL_ID} orig coordinates and visible
                vr.worlds{vr.currentWorld}.surface.colors(4,vr.floorIndx{k}{vr.currBL_ID}) = 1;
                vr.worlds{vr.currentWorld}.surface.vertices(3, vr.floorIndx{k}{vr.currBL_ID}) = ...
                    vr.floor_zOrig{k}{vr.currBL_ID};
            end
        end
        
        %% turns patches on and move into place if necessary
        if vr.eligibleRew == 1
            
            display('how many times this runs?')
            
            vr.event_patchOn = 1;
            if vr.dispSet > 0
                display('patch on triggered TTL');
            end
            
            vr.eligibleRew = 2;
            if vr.dispSet > 0
                display('eligible Rew 1 -> 2 and reset TS1_SW');
            end
            
            if vr.trainingStage<= 1
                vr.TS1_SW = 0; %reset TS1 stopwatch
            end
            
            if vr.patchesMove > 0 %move patchB into correct location y axis
                if vr.dispSet > 0
                    display('patchesMove into place');
                end
                vr.worlds{vr.currentWorld}.surface.vertices(2, vr.patchIndxB{vr.currBL_ID}) = ...
                    vr.patchB_yOrig{vr.currBL_ID} - vr.patchB_bottom_orig + vr.IPI;
                
                if vr.dispSet > 0
                    patchAppear = vr.patchAppear; display(patchAppear);
                    stopbottom = vr.stopBoundB_bottom; display(stopbottom);
                    %bottom_orig = vr.patchB_bottom_orig; display(bottom_orig);
                    IPI = vr.IPI; display(IPI);
                end
            end
            
            %move into location z (up/down) axis
            vr.worlds{vr.currentWorld}.surface.vertices(3, vr.patchIndxA{vr.currBL_ID}) = ...
                vr.patchA_zOrig{vr.currBL_ID};
            vr.worlds{vr.currentWorld}.surface.vertices(3, vr.patchIndxB{vr.currBL_ID}) = ...
                vr.patchB_zOrig{vr.currBL_ID};
            
            %visible
            if vr.taskType_ID(1)==9 %turn patch illumination only halfway for taskTypeI_ID(1)==9
                vr.worlds{vr.currentWorld}.surface.colors(4,vr.patchIndxA{vr.currBL_ID}) = .6;
                vr.worlds{vr.currentWorld}.surface.colors(4,vr.patchIndxB{vr.currBL_ID}) = .6;
            else
                vr.worlds{vr.currentWorld}.surface.colors(4,vr.patchIndxA{vr.currBL_ID}) = 1;
                vr.worlds{vr.currentWorld}.surface.colors(4,vr.patchIndxB{vr.currBL_ID}) = 1;
            end
            
            %move floors 1,2 *should always make patches appear at distances that
            %do not distort the texture (i.e. if stripe was at point 100, don't
            %want to set floor to a number like 98.5 bc the stipe might appear at
            %point 100.5 instead and cause incongruency of floor visual cue upon patch appear)
            
            vr.worlds{vr.currentWorld}.surface.vertices(2, vr.floorIndx{1}{vr.currBL_ID}) = ...
                vr.floor_yOrig{1}{vr.currBL_ID} + vr.IPI + vr.patchHeight;
            vr.worlds{vr.currentWorld}.surface.vertices(2, vr.floorIndx{2}{vr.currBL_ID}) = ...
                vr.floor_yOrig{2}{vr.currBL_ID} - vr.patchHeight;
            vr.worlds{vr.currentWorld}.surface.vertices(2, vr.floorIndx{3}{vr.currBL_ID}) = ...
                vr.floor_yOrig{3}{vr.currBL_ID} - vr.floor3y + vr.IPI - vr.floor3height/2;
            
            IPI = vr.IPI; display(IPI);
            %floor1moveto = vr.floor_yOrig{1}{vr.currBL_ID} + vr.IPI + vr.patchHeight; display(floor1moveto);
            %floor3height = vr.floor3height; display(floor3height);
        end
    end
    
    %if vr.trainingStage> 1
    %detect possible stop IF patches have been turned on
    if vr.travelType == 1 && vr.trainingStage > 0
        if vr.eligibleRew == 2 && ((vr.position(2) > vr.stopBoundB_bottom-2 || (vr.position(2) > vr.stopBoundA_bottom ...
                && vr.position(2) < vr.stopBoundA_top)) && (vr.trainingStage>= 2 || vr.TS1_SW >= vr.TS1_delay))
            
            if vr.patchHit == 0
                vr.patchHit = 1;
                vr.didnotStopYet = 1;
                
                %reset speed_circ_queue_stop
                vr.spd_circ_queue_stop= ones( vr.queue_len_stop, 1);
                vr.queue_idx_stop = 1;
                
                % SAVE EVENT FOR patch HIT
                c_timeStamp = now;
                c_trialNum = vr.trialNum;
                c_trialType = vr.CBA;
                
                c_event = 21; %patchHit
                
                vr.eventData = [vr.eventData, c_trialNum, c_trialType, c_event, c_timeStamp];
                eventData = vr.eventData;
                
                if ~vr.debugMode
                    %save event ID for patchHit
                    save([vr.pathname '\' vr.filenameEvents '.mat'],'eventData','-append');
                end
            end
            
            % put speed in the queue before being overwritten
            %vr.spd_circ_queue_stop( vr.queue_idx_stop) = sqrt(sum(vr.dp_cache(:, [1 2]).^2));
            vr.spd_circ_queue_stop( vr.queue_idx_stop) = vr.dp_cache(:, 2);
            % instant_spd = vr.spd_circ_queue_stop( vr.queue_idx_stop) % for debug
            vr.queue_idx_stop = vr.queue_idx_stop + 1;
            if vr.queue_idx_stop > vr.queue_len_stop
                vr.queue_idx_stop = 1;
            end
            
            %% MOUSE STOPPED
            if nanmax(vr.spd_circ_queue_stop(~isnan(vr.spd_circ_queue_stop))) < vr.STOP_CRIT
                
                % SAVE EVENT FOR DID STOP
                c_timeStamp = now;
                c_trialNum = vr.trialNum;
                c_trialType = vr.CBA;
                
                c_event = 31; %patchstop
                
                vr.eventData = [vr.eventData, c_trialNum, c_trialType, c_event, c_timeStamp];
                eventData = vr.eventData;
                if ~vr.debugMode
                    %save event ID for didStop
                    save([vr.pathname '\' vr.filenameEvents '.mat'],'eventData','-append');
                end
                
                c_stopCoordinates = vr.position(2);
                
                traveltime(1) = vr.traveltime_SW;
                vr.traveltimes = [vr.traveltimes, c_trialNum, c_trialType, traveltime(1), c_timeStamp];
                vr.TT = [vr.TT, traveltime(1)];
                traveltime(2) = vr.traveltime2_SW;
                vr.traveltimes2 = [vr.traveltimes2, c_trialNum, c_trialType, traveltime(2), c_timeStamp];
                vr.TT2 = [vr.TT2, traveltime(2)];
                display(traveltime);
                
                vr.stopCoordinates = [vr.stopCoordinates, vr.trialNum, vr.position(2)];
                vr.stopCoordinates = [vr.stopCoordinates, c_trialNum, c_trialType, c_stopCoordinates, c_timeStamp];
                
                vr.didStop = 1;
                vr.didnotStopYet = 0;
                vr.didnotStop_last = 0;
                didStop_patchType = vr.B; display(didStop_patchType);
                
                %% DELIVER T=0 REWARD for every taskType_ID *except* taskType_ID(1)==9
                if vr.taskType_ID(1)==9 %visible : turn patches to full illumination for stop for taskType_ID(1)==9
                    
                    if vr.onPatch==2; %only illuminate patch A if already transported back
                        vr.worlds{vr.currentWorld}.surface.colors(4,vr.patchIndxA{vr.currBL_ID}) = 1;
                    else
                        vr.worlds{vr.currentWorld}.surface.colors(4,vr.patchIndxA{vr.currBL_ID}) = 1;
                        vr.worlds{vr.currentWorld}.surface.colors(4,vr.patchIndxB{vr.currBL_ID}) = 1;
                    end
                else
                    vr.rewEarned = vr.A;
                end
                
                if vr.trainingStage> 1
                    vr.foraging = 1; %switch to repeated reward delivery
                else
                    vr.eligibleRew = 0; %would keep trying to detect stops since foraging == 0
                    vr.meltAB_1s = 1;
                end
                
                %assign values for current delay, rate of increase
                %moved into first run through foraging==1
                %vr.rewCounter = 1;
                
                vr.rateIncrease = vr.B; %2/5/16 IROIs = 1, 2, & 4sec
            end
        end
    end
    
    if vr.trainingStage<= 1
        vr.TS1_SW = vr.TS1_SW + vr.dt;
    end
end

%% DELIVER REWARD
if vr.rewEarned > 0
    currRew = vr.rewEarned;
    vr.rewEarned = 0; %reset
    vr.lastRewEarned = datestr(rem(now,1));
    
    switch currRew
        case 1
            %display('Sm rew earned');
            %ms_uL = [vr.SmRew vr.onSmh2o]; display(ms_uL);
            vr.totalWater = vr.totalWater + vr.onSmh2o;
            SmRewEarned = vr.totalWater; display(SmRewEarned);
            if ~vr.debugMode
                display('outdata onSm');
                out_data = vr.onSm;
                putdata(vr.ao, out_data);
                start(vr.ao);
                trigger(vr.ao);
                vr.plotLicks_SW_on = 1;
            end
            
        case 2
            %display('Md rew earned');
            %ms_uL = [vr.MdRew vr.onMdh2o]; display(ms_uL);
            vr.totalWater = vr.totalWater + vr.onMdh2o;
            MdRewEarned = vr.totalWater; display(MdRewEarned);
            if ~vr.debugMode
                display('outdata onMd');
                out_data = vr.onMd;
                putdata(vr.ao, out_data);
                start(vr.ao);
                trigger(vr.ao);
                
                vr.plotLicks_SW_on = 1;
            end
            
        case 3
            %display('Lg rew earned');
            %ms_uL = [vr.LgRew vr.onLgh2o]; display(ms_uL);
            vr.totalWater = vr.totalWater + vr.onLgh2o;
            LgRewEarned = vr.totalWater; display(LgRewEarned);
            if ~vr.debugMode
                display('outdata onLg');
                out_data = vr.onLg;
                putdata(vr.ao, out_data);
                start(vr.ao);
                trigger(vr.ao);
                
                vr.plotLicks_SW_on = 1;
            end
            
        case 4
            %display('XLg rew earned');
            %ms_uL = [vr.XLgRew vr.onXLgh2o]; display(ms_uL);
            vr.totalWater = vr.totalWater + vr.onXLgh2o;
            XLgRewEarned = vr.totalWater; display(XLgRewEarned);
            if ~vr.debugMode
                display('outdata onXLg');
                out_data = vr.onXLg;
                putdata(vr.ao, out_data);
                start(vr.ao);
                trigger(vr.ao);
                
                vr.plotLicks_SW_on = 1;
            end
            
            
    end
end


%% Keypress commands
x = vr.keyPressed;

if isnan(x) ~= 1
    switch x
        case vr.dispWater
            display('last rew earned: ');
            display(vr.lastRewEarned);
            display('total water');
            display(vr.totalWater);
            
        case vr.dispHistory % 'e'
            %bHist = vr.blockHistory;
            tHist = vr.trialHistory;
            %bNum = vr.blockNum;
            if vr.travelType == 1
                mID_tNum_stops = [vr.mouseID vr.trialNum sum(vr.patchStops)];
            else
                mID_tNum_stops = [vr.mouseID vr.trialNum vr.countStops];
            end
            display(tHist);
            %display(bHist); %display(bNum);
            display(mID_tNum_stops);
            
        case vr.toggleDisp % 't'
            vr.dispSet = vr.dispSet + 1;
            if vr.dispSet > 2
                vr.dispSet = 0;
            end
            toggle_dispSet = vr.dispSet; display(toggle_dispSet);
            
            
            
        case vr.rewKeyMed %med water delivery (pressed 'u')
            
            display('ATTEMPTED Med Rew Manual Delivery');
            display('*but manual reward key turned OFF*');
            %{
            vr.totalWater = vr.totalWater + vr.onMdh2o;
            if ~vr.debugMode
                display('1741 manual water delivery')
                out_data = vr.onMd;
                putdata(vr.ao, out_data);
                start(vr.ao);
                trigger(vr.ao);
                
            end
            %}
            
            %{
                case vr.dispCoordinates
                    y = vr.position(2);
                    vr.coordinates = [vr.coordinates y];
                    display('y coordinate = ');
                    display(vr.coordinates);
            %}
            
        case vr.dispStartTime
            SLC = ['start:' vr.startTime ' lastRew:' vr.lastRewEarned ' curr:' datestr(rem(now,1))];
            disp(SLC);
            
        case vr.dispWhatever
            if vr.trainingStage>= 2
                if vr.dispSet > 0
                    patchData = vr.patchData;
                    display(patchData);
                    
                    
                    numStops = sum(vr.patchStops);
                    display(numStops);
                    percentStops = sum(vr.patchStops)/length(vr.patchStops);
                    display(percentStops);
                end
                
                %c_trialNum c_trialType numRews leaveInterval foragingTime
                patches = vr.patchData;
                pNum = patches(1:5:length(patches));
                pType = patches(2:5:length(patches));
                pRews = patches(3:5:length(patches));
                pInts = patches(4:5:length(patches));
                pTime = patches(5:5:length(patches));
                
                if vr.taskType_ID(1)==1
                    pHi = pType==111; pMd = pType==121; pLo = pType==141;
                    
                    pTimeHi = pTime(pHi); pTimeMd = pTime(pMd); pTimeLo = pTime(pLo);
                    
                    pRewsHi = pRews(pHi); pRewsMd = pRews(pMd); pRewsLo = pRews(pLo);
                    
                    %1 = Hi, 2 = Md, 3 = Lo
                    meanforagetime(1) = mean(pTimeHi);
                    meanforagetime(2) = mean(pTimeMd);
                    meanforagetime(3) = mean(pTimeLo);
                    
                    meanrews(1) = mean(pRewsHi);
                    meanrews(2) = mean(pRewsMd);
                    meanrews(3) = mean(pRewsLo);
                    
                    display(meanforagetime);
                    display(meanrews);
                    
                elseif vr.taskType_ID(1)==2
                    
                    pLg = pType==223; pMd = pType==222; pSm = pType==221;
                    
                    pTimeLg = pTime(pLg); pTimeMd = pTime(pMd); pTimeSm = pTime(pSm);
                    
                    pRewsLg = pRews(pLg); pRewsMd = pRews(pMd); pRewsSm = pRews(pSm);
                    
                    % USE SAME NOTATION FOR PRINTOUT even though Lg rew
                    % vr.B == 3, and small vr.B == 1
                    %1 = Lg, 2 = Md, 3 = Sm
                    meanforagetime(1) = mean(pTimeLg);
                    meanforagetime(2) = mean(pTimeMd);
                    meanforagetime(3) = mean(pTimeSm);
                    
                    meanrews(1) = mean(pRewsLg);
                    meanrews(2) = mean(pRewsMd);
                    meanrews(3) = mean(pRewsSm);
                    
                    display(meanforagetime);
                    display(meanrews);
                    
                elseif vr.taskType_ID(1)==5
                    pXLg = pType==524; pMd = pType==522; pSm = pType==521;
                    
                    pTimeXLg = pTime(pXLg); pTimeMd = pTime(pMd); pTimeSm = pTime(pSm);
                    
                    pRewsXLg = pRews(pXLg); pRewsMd = pRews(pMd); pRewsSm = pRews(pSm);
                    
                    % USE SAME NOTATION FOR PRINTOUT even though XLg rew
                    % vr.B == 3, and small vr.B == 1
                    %1 = XLg, 2 = Md, 3 = Sm
                    meanforagetime(1) = mean(pTimeXLg);
                    meanforagetime(2) = mean(pTimeMd);
                    
                    meanrews(1) = mean(pRewsXLg);
                    meanrews(2) = mean(pRewsMd);
                    
                    if vr.taskType_ID(2) == 4
                        meanforagetime(3) = mean(pTimeSm);
                        meanrews(3) = mean(pRewsSm);
                    end
                    
                    display(meanforagetime);
                    display(meanrews);
                    
                elseif vr.taskType_ID(1)==7
                    pXLg = pType==724;
                    pMd = pType==722;
                    pSm = pType==721;
                    
                    pTimeXLg = pTime(pXLg);
                    pTimeMd = pTime(pMd);
                    pTimeSm = pTime(pSm);
                    
                    pRewsXLg = pRews(pXLg);
                    pRewsMd = pRews(pMd);
                    pRewsSm = pRews(pSm);
                    
                    if vr.taskType_ID(2)==6
                        pXLg_Hi= pType==714; pXLg_Md= pType==724; pXLg_Lo= pType==734;
                        pMd_Hi = pType==712; pMd_Md = pType==722; pMd_Lo = pType==732;
                        pSm_Hi = pType==711; pSm_Md = pType==721; pSm_Lo = pType==731;
                        
                        pTimeXLg_Hi = pTime(pXLg_Hi);
                        pTimeXLg_Md = pTime(pXLg_Md);
                        pTimeXLg_Lo = pTime(pXLg_Lo);
                        
                        pTimeMd_Hi = pTime(pMd_Hi);
                        pTimeMd_Md = pTime(pMd_Md);
                        pTimeMd_Lo = pTime(pMd_Lo);
                        
                        pTimeSm_Hi = pTime(pSm_Hi);
                        pTimeSm_Md = pTime(pSm_Md);
                        pTimeSm_Lo = pTime(pSm_Lo);
                        
                        pRewsXLg_Hi = pRews(pXLg_Hi);
                        pRewsXLg_Md = pRews(pXLg_Md);
                        pRewsXLg_Lo = pRews(pXLg_Lo);
                        
                        pRewsMd_Hi = pRews(pMd_Hi);
                        pRewsMd_Md = pRews(pMd_Md);
                        pRewsMd_Lo = pRews(pMd_Lo);
                        
                        pRewsSm_Hi = pRews(pSm_Hi);
                        pRewsSm_Md = pRews(pSm_Md);
                        pRewsSm_Lo = pRews(pSm_Lo);
                        
                        meanforagetime_Hi = [mean(pTimeXLg_Hi) mean(pTimeMd_Hi) mean(pTimeSm_Hi)];
                        meanforagetime_Md = [mean(pTimeXLg_Md) mean(pTimeMd_Md) mean(pTimeSm_Md)];
                        meanforagetime_Lo = [mean(pTimeXLg_Lo) mean(pTimeMd_Lo) mean(pTimeSm_Lo)];
                        
                        
                        display(meanforagetime_Hi)
                        display(meanforagetime_Md)
                        display(meanforagetime_Lo)
                        
                    else
                        
                        meanforagetime(1) = mean(pTimeXLg);
                        meanforagetime(2) = mean(pTimeMd);
                        meanforagetime(3) = mean(pTimeSm);
                        
                        meanrews(1) = mean(pRewsXLg);
                        meanrews(2) = mean(pRewsMd);
                        meanrews(3) = mean(pRewsSm);
                        
                        display(meanforagetime);
                        display(meanrews);
                        
                    end
                    
                    if vr.dispSet > 0
                        %for i = 1:length(vr.RewTimes2)
                        %    RTs2 = [i vr.RewTimes2{i}];
                        %    display(RTs2);
                        %end
                        
                        for i = 1:length(vr.RewTimes)
                            RTs = [i vr.RewTimes{i}];
                            display(RTs);
                        end
                        
                    end
                    
                    
                elseif vr.taskType_ID(1)==8 || vr.taskType_ID(1)==9
                    
                    if vr.taskType_ID(2)==2 %written in terms of N0(Hi,Md,Lo)/tau
                        pHi8= pType==812; pHi4= pType==822; pHi2= pType==832;
                        pMd8 = pType==842; pMd4 = pType==852; pMd2 = pType==862;
                        pLo8 = pType==872; pLo4 = pType==882; pLo2 = pType==892;
                        
                        pTimeHi8 = pTime(pHi8);
                        pTimeHi4 = pTime(pHi4);
                        pTimeHi2 = pTime(pHi2);
                        pTimeMd8 = pTime(pMd8);
                        pTimeMd4 = pTime(pMd4);
                        pTimeMd2 = pTime(pMd2);
                        pTimeLo8 = pTime(pLo8);
                        pTimeLo4 = pTime(pLo4);
                        pTimeLo2 = pTime(pLo2);
                        
                        %{
                        pRewsHi8 = pRews(pHi8);
                        pRewsHi4 = pRews(pHi4);
                        pRewsHi2 = pRews(pHi4);
                        pRewsMd8 = pRews(pMd8);
                        pRewsMd4 = pRews(pMd4);
                        pRewsMd2 = pRews(pMd4);
                        pRewsLo8 = pRews(pLo8);
                        pRewsLo4 = pRews(pLo4);
                        pRewsLo2 = pRews(pLo4);
                        %}
                        
                        meanforagetime_Hi = [mean(pTimeHi8) mean(pTimeHi4) mean(pTimeHi2)];
                        meanforagetime_Md = [mean(pTimeMd8) mean(pTimeMd4) mean(pTimeMd2)];
                        meanforagetime_Lo = [mean(pTimeLo8) mean(pTimeLo4) mean(pTimeLo2)];
                        
                        display(meanforagetime_Hi)
                        display(meanforagetime_Md)
                        display(meanforagetime_Lo)
                        
                    elseif vr.taskType_ID(2)==3
                        pHi8= pType==812; pHi4= pType==822;
                        pMd8 = pType==842; pMd4 = pType==852;
                        
                        
                        pTimeHi8 = pTime(pHi8);
                        pTimeHi4 = pTime(pHi4);
                        pTimeMd8 = pTime(pMd8);
                        pTimeMd4 = pTime(pMd4);
                        
                        meanforagetime_Hi = [mean(pTimeHi8) mean(pTimeHi4)];
                        meanforagetime_Md = [mean(pTimeMd8) mean(pTimeMd4)];
                        
                        display(meanforagetime_Hi)
                        display(meanforagetime_Md)
                        
                    elseif vr.taskType_ID(2)==4
                        pMd4 = pType==852; pMd2 = pType==862;
                        pLo4 = pType==882; pLo2 = pType==892;
                        
                        pTimeMd4 = pTime(pMd4);
                        pTimeMd2 = pTime(pMd2);
                        pTimeLo4 = pTime(pLo4);
                        pTimeLo2 = pTime(pLo2);
                        
                        meanforagetime_Md = [mean(pTimeMd4) mean(pTimeMd2)];
                        meanforagetime_Lo = [mean(pTimeLo4) mean(pTimeLo2)];
                        
                        display(meanforagetime_Md)
                        display(meanforagetime_Lo)
                        
                        
                    elseif vr.taskType_ID(1)==9 && vr.taskType_ID(2)==1
                        pHi8= pType==812; pHi4= pType==822; pHi2= pType==832;
                        
                        pTimeHi8 = pTime(pHi8);
                        pTimeHi4 = pTime(pHi4);
                        pTimeHi2 = pTime(pHi2);
                        
                        meanforagetime_Hi = [mean(pTimeHi8) mean(pTimeHi4) mean(pTimeHi2)];
                        display(meanforagetime_Hi)
                        
                    else
                        
                        display('ERROR WHAT TASK TYPE?????')
                        
                    end
                    
                    if vr.dispSet > 0
                        %for i = 1:length(vr.RewTimes2)
                        %    RTs2 = [i vr.RewTimes2{i}];
                        %    display(RTs2);
                        %end
                        
                        for i = 1:length(vr.RewTimes)
                            RTs = [i vr.RewTimes{i}];
                            display(RTs);
                        end
                        
                    end
                    
                elseif vr.taskType_ID(1)==3
                    
                    pHi_blockH = pType==413;
                    pMd_blockH = pType==422;
                    
                    pLo_blockL = pType==341;
                    pMd_blockL = pType==322;
                    
                    if sum(pHi_blockH) > 0
                        %sum_pHi = sum(pHi_blockH); display(sum_pHi);
                        
                        pTimeHi_blockH = pTime(pHi_blockH);
                        pTimeMd_blockH = pTime(pMd_blockH);
                        
                        pRewsHi_blockH = pRews(pHi_blockH); pRewsMd_blockH = pRews(pMd_blockH);
                        
                        meanforagetime_HiMd(1) = mean(pTimeHi_blockH);
                        meanforagetime_HiMd(2) = mean(pTimeMd_blockH);
                        
                        meanrews_HiMd(1) = mean(pRewsHi_blockH);
                        meanrews_HiMd(2) = mean(pRewsMd_blockH);
                        
                        display(meanforagetime_HiMd);
                        display(meanrews_HiMd);
                        
                    else
                        %display('sum pHi = 0');
                    end
                    
                    if sum(pLo_blockL) > 0
                        %sum_pLo = sum(pLo_blockL); display(sum_pLo);
                        
                        pTimeLo_blockL = pTime(pLo_blockL);
                        pTimeMd_blockL = pTime(pMd_blockL);
                        
                        pRewsLo_blockL = pRews(pLo_blockL); pRewsMd_blockL = pRews(pMd_blockL);
                        
                        meanforagetime_LoMd(1) = mean(pTimeLo_blockL);
                        meanforagetime_LoMd(2) = mean(pTimeMd_blockL);
                        
                        meanrews_LoMd(1) = mean(pRewsLo_blockL);
                        meanrews_LoMd(2) = mean(pRewsMd_blockL);
                        
                        display(meanforagetime_LoMd);
                        display(meanrews_LoMd);
                        
                    else
                        %display('sum pLo = 0');
                    end
                    
                    Md_count_LoBlock_HiBlock = [sum(pMd_blockL) sum(pMd_blockH)];
                    display(Md_count_LoBlock_HiBlock);
                    
                    if Md_count_LoBlock_HiBlock(1) >= 5 && Md_count_LoBlock_HiBlock(2) >= 5
                        mean_Md5_LoBL_HiBL(1) = mean(pTimeMd_blockL(1:5));
                        mean_Md5_LoBL_HiBL(2) = mean(pTimeMd_blockH(1:5));
                        display(mean_Md5_LoBL_HiBL);
                    end
                    
                    
                elseif vr.taskType_ID(1)==4
                    
                    pHi_blockH = pType==411;
                    pMd_blockH = pType==421;
                    
                    pLo_blockL = pType==341;
                    pMd_blockL = pType==321;
                    
                    if sum(pHi_blockH) > 0
                        %sum_pHi = sum(pHi_blockH); display(sum_pHi);
                        
                        pTimeHi_blockH = pTime(pHi_blockH);
                        pTimeMd_blockH = pTime(pMd_blockH);
                        
                        pRewsHi_blockH = pRews(pHi_blockH); pRewsMd_blockH = pRews(pMd_blockH);
                        
                        meanforagetime_HiMd(1) = mean(pTimeHi_blockH);
                        meanforagetime_HiMd(2) = mean(pTimeMd_blockH);
                        
                        meanrews_HiMd(1) = mean(pRewsHi_blockH);
                        meanrews_HiMd(2) = mean(pRewsMd_blockH);
                        
                        display(meanforagetime_HiMd);
                        display(meanrews_HiMd);
                        
                    else
                        %display('sum pHi = 0');
                    end
                    
                    if sum(pLo_blockL) > 0
                        %sum_pLo = sum(pLo_blockL); display(sum_pLo);
                        
                        pTimeLo_blockL = pTime(pLo_blockL);
                        pTimeMd_blockL = pTime(pMd_blockL);
                        
                        pRewsLo_blockL = pRews(pLo_blockL); pRewsMd_blockL = pRews(pMd_blockL);
                        
                        meanforagetime_LoMd(1) = mean(pTimeLo_blockL);
                        meanforagetime_LoMd(2) = mean(pTimeMd_blockL);
                        
                        meanrews_LoMd(1) = mean(pRewsLo_blockL);
                        meanrews_LoMd(2) = mean(pRewsMd_blockL);
                        
                        display(meanforagetime_LoMd);
                        display(meanrews_LoMd);
                        
                    else
                        %display('sum pLo = 0');
                    end
                end
                
                meanTTmedTT(1) = mean(vr.TT); % *** FIX TT DISPLAYS
                meanTTmedTT(2) = median(vr.TT);
                display(meanTTmedTT);
            end
            
        case  vr.runCaliWater
            
            %sizeTest = input('water size to test');
            
            %vr.caliSize = sizeTest;
            
            if vr.caliWaterLOCK == 0 %safety to prevent accidental keypress trigger
                vr.caliWater = 1;
            end
            
        otherwise
            %display(x);
    end
end

%% reset from patchB to patchA
if vr.travelType == 1 && vr.position(2) >= vr.patchB_mid
    vr.position(2) = vr.patchA_mid;
    vr.onPatch = 2;
    vr.meltB = 1;
    
    if vr.trainingStage<= 1 && vr.eligibleRew > 0
        vr.rewEarned = vr.A;
        vr.meltA_1s = 1;
        vr.eligibleRew = 0;
        
        c_timeStamp = now;
        c_trialNum = vr.trialNum;
        c_trialType = vr.CBA;
        traveltime = vr.traveltime_SW;
        vr.traveltimes = [vr.traveltimes, c_trialNum, c_trialType, traveltime, c_timeStamp];
        vr.TT = [vr.TT, traveltime];
        display(traveltime);
        
    end
end

%% reset from too far backwards below patchA
if vr.position(2) <= 0 - (vr.patchHeight + .5*vr.patchHeight)
    vr.position(2) = vr.patchA_mid;
    display('WENT BACKWARDS 1 TRACK LENGTH'); %need to reset targs if this happens
end

%% DID NOT STOP
if vr.trainingStage> 1 && vr.onPatch == 2 && vr.position(2) > vr.waitBoundA_top && vr.didnotStopYet == 1
    vr.didnotStopYet = 0;
    
    %start timer for save/plot/flush lick data
    vr.plotLicks_SW = 0;
    vr.plotLicks_SW_on = 0;
    vr.plotLicks_flushSW = 0;
    vr.plotLicks_flushSW_on = 1;
    display('vr.plotLicks_flushSW_on = 1 _ 2368');
    
    % SAVE EVENT FOR DID NOT STOP AND N/A for ('didnotwait')
    c_timeStamp = now;
    c_trialNum = vr.trialNum;
    c_trialType = vr.CBA;
    
    c_event = 33; %didnotStop
    
    c_event2 = 59; %n/a for leaveTime bc didn't stop
    
    % & for N/A IF trainingStage>= 2 **NEED TO EDIT IF WANT DATA GOOD FOR
    % TS <= 1, 'didstops' will cause variation in event nums per trial
    vr.eventData = [vr.eventData, c_trialNum, c_trialType, c_event, c_timeStamp, ...
        c_trialNum, c_trialType, c_event2, c_timeStamp];
    
    eventData = vr.eventData;
    
    if ~vr.debugMode
        %save event ID for didnotStop
        save([vr.pathname '\' vr.filenameEvents '.mat'],'eventData','-append');
    end
    if vr.trainingStage> 1
        vr.didnotStop_last = vr.didnotStop_last + 1;
        didnotStop = vr.didnotStop_last;
        display(didnotStop);
    end
end

%%
if vr.travelType == 1
    %% *** NEW TRIAL START: Leave patchA (going forward)
    if vr.onPatch == 2 && vr.position(2) > vr.patchA_top
        
        
        vr.meltA = 1;
        
        if vr.trainingStage<= 1
            %start timer for save/plot/flush lick data
            vr.plotLicks_SW = 0;
            vr.plotLicks_SW_on = 0;
            vr.plotLicks_flushSW = 0;
            vr.plotLicks_flushSW_on = 1;
            display('vr.plotLicks_flushSW_on = 1 _ 2469');
        end
        
        
        %store trajectory information from previous trial
        if vr.trialNum > 0
            
            vr.trajectory{vr.trialNum} = vr.trialTrajectory;
            vr.trialTrajectory = [];
            
            if vr.trainingStage>= 2
                vr.patchStops = [vr.patchStops vr.didStop];
            end
        end
        
        vr.traveltime_SW = 0; %reset traveltime_SW
        %only reset other one (traveltime2) following a stopped patch*
        
        vr.onPatch = 0; %reset
        vr.trialNum = vr.trialNum + 1;
        
        if vr.didStop > 0
            vr.thisTrial = vr.thisTrial + 1;
            vr.traveltime2_SW = 0; %only zero this stopwatch after patchstop
        elseif vr.trainingStage<= 1
            if vr.trialNum > 1 %skip at start of first trial
                vr.thisTrial = vr.thisTrial + 1;
            end
        end
        
        %vr.foraging_SW = 0;
        vr.eligibleRew = 1;
        if vr.dispSet > 0
            display('eligiblerew');
        end
        
        vr.didStop = 0;
        vr.patchHit = 0;
        
        if vr.thisTrial <= length(vr.trialTypes)
            tNum_stops_thisTrial = [vr.trialNum sum(vr.patchStops) vr.thisTrial]; display(tNum_stops_thisTrial);
        else %end of vr.trialTypes indices
            vr.thisTrial = 1; %reset
            tNum_stops_thisTrial = [vr.trialNum sum(vr.patchStops) vr.thisTrial];
            display(tNum_stops_thisTrial);
            
            if vr.progRatio > 0
                if vr.progRatio < length(vr.progRatioDist)
                    vr.progRatio = vr.progRatio + 1;
                    
                else
                    display('prog ratio at MAX DISTANCE');
                end
                progDist = [vr.progRatio vr.progRatioDist(vr.progRatio)];
                display(progDist);
            end
            
            vr.blockNum = vr.blockNum + 1; %total count
            vr.thisBlock = vr.thisBlock + 1; %count within cycle
            
            vr.prevBlockType = 0; %commented out line below since all block types are currently same
            %vr.prevBlockType = vr.C; %store curr blocktype for comparison w next
            
            if vr.thisBlock > length(vr.blockTypes)
                vr.thisBlock = 1;
                display('ENTIRE SET OF BLOCKS COMPLETED, reset blocks');
                %reshuffle blocks
                perm1 = randperm(length(vr.blockTypes));
                vr.blockTypes = vr.blockTypes(perm1);
                if vr.dispSet > 0
                    BL_Types = vr.blockTypes; display(BL_Types);
                    
                end
            end
            if vr.taskType_ID(1)==3 && vr.switchAfterBlock1 == 1
                vr.switchAfterBlock1 = 2; %change value to 2 after so only 1 switch
                
                switchFrom = vr.blockTypes(1);
                
                switch switchFrom
                    case 3
                        vr.blockTypes = [4 4 4 4 4 4 4 4 4 4];
                        vr.BL_switchTo = 1; %from Sm (2)
                    case 4
                        vr.blockTypes = [3 3 3 3 3 3 3 3 3 3];
                        vr.BL_switchTo = 2; %from Lg (1)
                end
                fromBL1_to = [switchFrom vr.blockTypes(1)]; display(fromBL1_to);
            end
            
            
            newBlockNum = vr.blockNum; display(newBlockNum);
            
            vr.currentBlock = vr.blockTypes(vr.thisBlock);
            vr.blockHistory = [vr.blockHistory vr.currentBlock];
            blockHistory = vr.blockHistory;
            display(blockHistory);
            
            if vr.taskType_ID(1)==4
                if vr.currentBlock == vr.whichBlock
                    display('same block REPEAT, no switch');
                else
                    which_to_curr = [vr.whichBlock vr.currentBlock]; display(which_to_curr);
                    vr.whichBlock = vr.currentBlock;
                    
                    switch vr.whichBlock
                        case 3
                            vr.BL_switchTo = 2;
                        case 4
                            vr.BL_switchTo = 1;
                    end
                end
            end
            
            %shuffle trial types
            vr.trialTypes = vr.trialTypes_Set{vr.taskType_ID(1)}{vr.blockTypes(vr.thisBlock)};
            
            %randomize trial order
            if vr.taskType_ID(1)==4 || vr.switchAfterBlock1 == 2 %do not randomize first 5 of block if taskType_ID(1) == 4
                vr.switchAfterBlock1 = 3; %only skip first 5 for first 2 blocks
                perm4 = randperm(length(vr.trialTypes)-5)+5;
                vr.trialTypes = [vr.trialTypes(1:5) vr.trialTypes(perm4)];
                TT4 = vr.trialTypes; display(TT4);
                
            elseif vr.taskType_ID(1)==7 && vr.taskType_ID(2)==9
                
                prevTrialOrder = vr.trialTypes; display(prevTrialOrder)
                flipCoin = randi(2);
                if flipCoin==2
                    % switch Sm/Lg block order
                    
                    vr.trialTypes = [vr.trialTypes(end/2+1:end) vr.trialTypes(1:end/2)];
                    %vr.trialTypes = [vr.trialTypes(7:12) vr.trialTypes(1:6)];
                    flipTrialOrder = vr.trialTypes; display(flipTrialOrder)
                else
                    %no change
                    sameTrialOrder = vr.trialTypes; display(sameTrialOrder)
                end
                
                
                
            else
                perm2 = randperm(length(vr.trialTypes));
                vr.trialTypes = vr.trialTypes(perm2);
            end
            
            %CBA assignment repeated below because need to do every trial but
            %also need to do once per block switch for counting repeatBlocks
            vr.CBA = vr.trialTypes(vr.thisTrial);
            
            vr.A = mod(vr.CBA,10);
            vr.B = mod(vr.CBA-vr.A,100)/10;
            vr.C = mod(vr.CBA-vr.A-vr.B*10,1000)/100;
            
        end
        
        % set distance to next patch
        if vr.travelType == 1
            if vr.patchesMove > 0
                if vr.progRatio > 0
                    display('PROGRESSIVE RATIO FOR PATCH DISTANCE');
                    vr.IPI = vr.progRatioDist(vr.progRatio);
                    vr.patchB_bottom = vr.IPI; % DOUBLE CHECK THIS
                    vr.patchB_mid = vr.patchB_bottom + .5*vr.patchHeight;
                    vr.patchB_top = vr.patchB_bottom + vr.patchHeight;
                    vr.stopBoundB_bottom = vr.patchB_bottom;
                    vr.waitBoundB_bottom = vr.patchB_bottom-5;
                    
                    patchBottom = vr.patchB_bottom;
                    
                    patchB_BOTTOM = vr.patchB_bottom; display(patchB_BOTTOM);
                    
                    vr.patchAppear = vr.stopBoundB_bottom - vr.appearBefore;
                    if vr.dispSet > 0
                        patchAppear = vr.patchAppear;
                        display(patchAppear);
                    end
                    
                    if vr.dispSet > 0
                        display(patchBottom);
                    end
                end
            end
        end
        
        vr.CBA = vr.trialTypes(vr.thisTrial);
        vr.trialHistory = [vr.trialHistory, vr.CBA];
        
        currentCBA = vr.CBA; display(currentCBA);
        
        %C = experiment type, B = IRI rate change, A = rew size
        vr.A = mod(vr.CBA,10);
        vr.B = mod(vr.CBA-vr.A,100)/10;
        vr.C = mod(vr.CBA-vr.A-vr.B*10,1000)/100;
        
        % SAVE EVENT FOR TRIAL START
        c_timeStamp = now;
        c_trialNum = vr.trialNum;
        c_trialType = vr.CBA;
        
        c_event = 11; %new trial
        
        vr.eventData = [vr.eventData, c_trialNum, c_trialType, c_event, c_timeStamp];
        eventData = vr.eventData;
        if ~vr.debugMode
            %save event ID for newTrial
            save([vr.pathname '\' vr.filenameEvents '.mat'],'eventData','-append');
        end
    end
end


%% save trajectory data
measurementsToSave = [now vr.position(2) vr.dp_cache vr.dt];
vr.trialTrajectory = [vr.trialTrajectory; measurementsToSave];
%fwrite(vr.fid,measurementsToSave,'double');

%% patchmelts

if vr.meltAB_1s > 0;
    
    if vr.meltAB_1s == 1;
        vr.meltAB_1s_SW = 0; %reset
        if vr.dispSet > 0
            display('meltAB_1s');
        end
        vr.meltAB_1s = 2;
    end
    
    vr.meltAB_1s_SW = vr.meltAB_1s_SW + vr.dt;
    
    if vr.meltAB_1s_SW >= 1
        if vr.dispSet > 0
            display('meltAB_1s 2 -> 0 (SW internal reset)');
        end
        vr.meltAB_1s = 0; %reset
        vr.meltAB_1s_SW = 0; %reset
        %turn targA off
        vr.meltAB = 1;
    end
end

if vr.meltA_1s > 0;
    
    if vr.meltA_1s == 1;
        vr.meltA_1s_SW = 0; %reset
        if vr.dispSet > 0
            display('meltA_1s');
        end
        vr.meltA_1s = 2;
    end
    
    vr.meltA_1s_SW = vr.meltA_1s_SW + vr.dt;
    
    if vr.meltA_1s_SW >= 1
        if vr.dispSet > 0
            display('meltA_1s 2 -> 0 (SW internal reset)');
        end
        vr.meltA_1s = 0; %reset
        vr.meltA_1s_SW = 0; %reset
        
        %turn targA off
        vr.meltA = 1;
    end
end

if vr.meltAB > 0
    vr.meltAB = 0;
    if vr.dispSet > 0
        display('patchmelt = meltAB');
    end
    %move away
    vr.worlds{vr.currentWorld}.surface.vertices(3, vr.patchIndxA{vr.currBL_ID}) = ...
        vr.patchA_zOrig{vr.currBL_ID} + 60;
    vr.worlds{vr.currentWorld}.surface.vertices(3, vr.patchIndxB{vr.currBL_ID}) = ...
        vr.patchB_zOrig{vr.currBL_ID} + 60;
    %invisible
    vr.worlds{vr.currentWorld}.surface.colors(4,vr.patchIndxA{vr.currBL_ID}) = 0;
    vr.worlds{vr.currentWorld}.surface.colors(4,vr.patchIndxB{vr.currBL_ID}) = 0;
    
    %move floors 1,2 back
    vr.worlds{vr.currentWorld}.surface.vertices(2, vr.floorIndx{1}{vr.currBL_ID}) = ...
        vr.floor_yOrig{1}{vr.currBL_ID};
    vr.worlds{vr.currentWorld}.surface.vertices(2, vr.floorIndx{2}{vr.currBL_ID}) = ...
        vr.floor_yOrig{2}{vr.currBL_ID};
    vr.worlds{vr.currentWorld}.surface.vertices(2, vr.floorIndx{3}{vr.currBL_ID}) = ...
        vr.floor_yOrig{3}{vr.currBL_ID};
end

if vr.meltA > 0
    if vr.dispSet > 0
        display('patchmelt = meltA');
    end
    vr.meltA = 0;
    %move away
    vr.worlds{vr.currentWorld}.surface.vertices(3, vr.patchIndxA{vr.currBL_ID}) = ...
        vr.patchA_zOrig{vr.currBL_ID} + 60;
    %invisible
    vr.worlds{vr.currentWorld}.surface.colors(4,vr.patchIndxA{vr.currBL_ID}) = 0;
    
    %move floor 2 back
    vr.worlds{vr.currentWorld}.surface.vertices(2, vr.floorIndx{2}{vr.currBL_ID}) = ...
        vr.floor_yOrig{2}{vr.currBL_ID};
end

if vr.meltB > 0
    if vr.dispSet > 0
        display('patchmelt = meltB');
    end
    vr.meltB = 0;
    %move away
    vr.worlds{vr.currentWorld}.surface.vertices(3, vr.patchIndxB{vr.currBL_ID}) = ...
        vr.patchB_zOrig{vr.currBL_ID} + 60;
    %invisible
    vr.worlds{vr.currentWorld}.surface.colors(4,vr.patchIndxB{vr.currBL_ID}) = 0;
    
    %move floor 1 back
    vr.worlds{vr.currentWorld}.surface.vertices(2, vr.floorIndx{1}{vr.currBL_ID}) = ...
        vr.floor_yOrig{1}{vr.currBL_ID};
    vr.worlds{vr.currentWorld}.surface.vertices(2, vr.floorIndx{3}{vr.currBL_ID}) = ...
        vr.floor_yOrig{3}{vr.currBL_ID};
end

if vr.caliWater > 0
    if vr.caliWater == 1
        vr.caliWater = 2;
        caliSize = vr.caliSize; display(caliSize);
        vr.caliCount = 0;
        caliTimes = vr.caliTimes; display(caliTimes);
        caliPause = vr.caliPause; display(caliPause);
        vr.caliSW = 0;
        
        vr.onCali =  [5 * ones(floor(vr.caliSize/1000*vr.SR),1 ); zeros(1, 1)]; vr.onCali = [vr.onCali zeros(length(vr.onCali),1) zeros(length(vr.onCali),1) zeros(length(vr.onCali),1)];
    end
    
    vr.caliSW = vr.caliSW + vr.dt;
    
    if vr.caliSW >= vr.caliPause
        vr.caliSW = 0; %reset stopwatch
        vr.caliCount = vr.caliCount + 1;
        caliCount = vr.caliCount; display(caliCount);
        
        %deliver calibration 'reward'
        if ~vr.debugMode
            display('2470 calibration h20')
            out_data = vr.onCali;
            putdata(vr.ao, out_data);
            start(vr.ao);
            trigger(vr.ao);
            
        end
    end
    
    if vr.caliCount >= vr.caliTimes
        vr.caliWater = 0;
        display('calibration complete');
        caliSize = vr.caliSize; display(caliSize);
        vr.caliCount = 0; vr.caliSW = 0;
        caliTimes = vr.caliTimes; display(caliTimes);
    end
    
end

%% --- TERMINATION code: executes after the ViRMEn engine stops.
function vr = terminationCodeFun(vr)

display(datestr(now))

if ~vr.debugMode
    fclose all;
    %turn off camera
    putvalue(vr.dio.Line(2), 0);
    stop(vr.ai);
end

endTime = datestr(rem(now,1));
endT = now;

mID = vr.mouseID; display(mID);
SLC = ['start:' vr.startTime ', lastRew:' vr.lastRewEarned ', end:' endTime];
disp(SLC);

if vr.randTT(1)>0
    randTT = vr.setTT; display(randTT);
end

if vr.travelType == 1
    trials_stops_water_TS = [vr.trialNum-1 sum(vr.patchStops) vr.totalWater vr.trainingStage];
else
    trials_stops_water_TS = [vr.trialNum-1 vr.countStops vr.totalWater vr.trainingStage];
end
display(trials_stops_water_TS);

%{
if vr.trainingStage>= 2
    numStops = sum(vr.patchStops);
    percentStops = numStops/length(vr.patchStops);
    num_percent_Stops = [numStops percentStops];
    display(num_percent_Stops);
    z.num_percent_Stops = num_percent_Stops;
end
%}

if ~vr.debugMode %save all files and move to appropriate folders
    answer = inputdlg({'mouse','Comment'},'Question',[1; 5]);
    sessionDate = datestr(now,'yyyymmdd');
    
    %save task variables
    z.mouseID = vr.mouseID;
    
    z.scaling = vr.scaling;
    z.RewDuration = vr.RewDuration;
    z.scalingStandard = vr.scalingStandard;
    z.scaledown = vr.scaledown;
    z.startTime = vr.startTime;
    z.startT = vr.startT; % added 5/17
    
    %% *** can use as a rough estimate of performance immprovement?
    z.totalWater = vr.totalWater;
    
    z.trainingStage = vr.trainingStage;
    z.patchStops = vr.patchStops;
    z.countStops = vr.countStops;
    
    z.stopCoordinates = vr.stopCoordinates;
    z.trackLength = vr.trackLength;
    z.STOP_CRIT = vr.STOP_CRIT;
    z.LEAVE_CRIT = vr.LEAVE_CRIT;
    z.RUN_CRIT = vr.RUN_CRIT;
    %z.WAIT_CRIT = vr.WAIT_CRIT;
    z.queue_len_stop = vr.queue_len_stop;
    %z.queue_len_wait = vr.queue_len_wait;
    z.blockHistory = vr.blockHistory;
    z.blockNum = vr.blockNum;
    z.trialHistory = vr.trialHistory;
    z.trialNum = vr.trialNum;
    z.traveltimes = vr.traveltimes;
    z.traveltimes2 = vr.traveltimes2;
    z.TT = vr.TT; z.TT2 = vr.TT2;
    z.taskType_ID = vr.taskType_ID;
    z.progRatio = vr.progRatio;
    z.progRatioDist = vr.progRatioDist;
    z.progRatioStart = vr.progRatioStart;
    z.TS1_delay = vr.TS1_delay;
    z.switchAfterBlock1 = vr.switchAfterBlock1;
    
    z.patchesMelt = vr.patchesMelt;
    z.patchesMove = vr.patchesMove;
    z.patchesRand = vr.patchesRand;
    z.IPI = vr.IPI;
    z.patchHeight = vr.patchHeight;
    z.patchB_bottom = vr.patchB_bottom;
    
    z.lastRewEarned = vr.lastRewEarned;
    
    z.onXLgh2o = vr.onXLgh2o;
    z.onLgh2o = vr.onLgh2o;
    z.onMdh2o = vr.onMdh2o;
    z.onSmh2o = vr.onSmh2o;
    z.XLgRew = vr.XLgRew;
    z.LgRew = vr.LgRew;
    z.MdRew = vr.MdRew;
    z.SmRew = vr.SmRew;
    
    z.SR = vr.SR;
    z.vSnd = vr.vSnd;
    z.iSndOff = vr.iSndOff;
    
    %z.bw_blocks = vr.bw_blocks; % set to 1 for black and white blocks w diff mean travel distance, 2 for background color change too
    z.diffBlocks = vr.diffBlocks;
    z.fixBlock = vr.fixBlock;
    z.whichBlock = vr.whichBlock;
    z.currBL_ID = vr.currBL_ID;
    
    z.trialTypes_Set = vr.trialTypes_Set;
    
    z.endT = endT;
    z.travelType = vr.travelType;
    
    z.setTT = vr.setTT;
    z.preTT = vr.preTT;
    z.randTT = vr.randTT;
    z.setSpeed = vr.setSpeed;
    
    z.trajectory = vr.trajectory;
    %z.data2save = vr.data2save;
    %z.data3save = vr.data3save;
    %z.data4save = vr.data4save;
    %z.data5save = vr.data5save;
    %z.timeXsave = vr.timeXsave;
    
    ok = vr;
    
    if vr.taskType_ID(1)==7 || vr.taskType_ID(1)==8 || vr.taskType_ID(1)==9
        
        z.maxRewTime = vr.maxRewTime;
        z.minInterval = vr.minInterval;
        %z.expDecay_tau = vr.expDecay_tau;
        z.expDecay_N0 = vr.expDecay_N0;
        z.expDecay_times = vr.expDecay_times;
        z.expDecay_Haz = vr.expDecay_Haz;
        z.expDecay_Int = vr.expDecay_Int;
        z.expDecay_RewProb = vr.expDecay_RewProb;
        
    end
    
    taskVars = ok;
    save([vr.pathname '\' vr.filenameTaskVars '.mat'],'taskVars','-append');
    
    if ~isempty(answer)
        comment = answer{2}; %#ok<NASGU>
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
        
        movefile([vr.pathname '\' vr.filenameExper '.mat'],[vr.pathname '\' answer{1} '\' sessionDate '\Exper',datestr(now,'mmdd'),'.mat']);
        movefile([vr.pathname '\' vr.filenameEvents '.mat'],[vr.pathname '\' answer{1} '\' sessionDate '\Events',datestr(now,'mmdd'),'.mat']);
        movefile([vr.pathname '\' vr.filenameTaskVars '.mat'],[vr.pathname '\' answer{1} '\' sessionDate '\TaskVars',datestr(now,'mmdd'),'.mat']);
        movefile([vr.pathname '\' vr.filenamePatches '.mat'],[vr.pathname '\' answer{1} '\' sessionDate '\Patches',datestr(now,'mmdd'),'.mat']);
        if vr.taskType_ID(1)==7 || vr.taskType_ID(1)==8 || vr.taskType_ID(1)==9
            movefile([vr.pathname '\' vr.filenameRewTimes '.mat'],[vr.pathname '\' answer{1} '\' sessionDate '\RewTimes',datestr(now,'mmdd'),'.mat']);
        else
            display('non probabilistic taskType_ID, so no RewTimes file')
        end
        
        %move daq file from temp folder
        daqPath = 'C:\VirmenDataTmp';
        daqDir = dir('C:\VirmenDataTmp');
        
        movefile([daqPath '\' daqDir(end).name],[vr.pathname '\' answer{1} '\' sessionDate '\DaqData',datestr(now,'mmdd'),'.daq']);
        
    end
    
    %c_trialNum c_trialType numRews leaveInterval foragingTime
    patches = vr.patchData;
    pNum = patches(1:5:length(patches));
    pType = patches(2:5:length(patches));
    pRews = patches(3:5:length(patches));
    pInts = patches(4:5:length(patches));
    pTime = patches(5:5:length(patches));
    
    %% ***
    if vr.taskType_ID(1)==1
        pHi = pType==111; pMd = pType==121; pLo = pType==141;
        
        pTimeHi = pTime(pHi); pTimeMd = pTime(pMd); pTimeLo = pTime(pLo);
        
        pRewsHi = pRews(pHi); pRewsMd = pRews(pMd); pRewsLo = pRews(pLo);
        
        %1 = Hi, 2 = Md, 3 = Lo
        meanforagetime(1) = mean(pTimeHi);
        meanforagetime(2) = mean(pTimeMd);
        meanforagetime(3) = mean(pTimeLo);
        
        meanrews(1) = mean(pRewsHi);
        meanrews(2) = mean(pRewsMd);
        meanrews(3) = mean(pRewsLo);
        
        
        display(meanforagetime);
        display(meanrews);
        
        
    elseif vr.taskType_ID(1)==2
        
        pLg = pType==223; pMd = pType==222; pSm = pType==221;
        
        pTimeLg = pTime(pLg); pTimeMd = pTime(pMd); pTimeSm = pTime(pSm);
        
        pRewsLg = pRews(pLg); pRewsMd = pRews(pMd); pRewsSm = pRews(pSm);
        
        % USE SAME NOTATION FOR PRINTOUT even though Lg rew
        % vr.B == 3, and small vr.B == 1
        %1 = Lg, 2 = Md, 3 = Sm
        meanforagetime(1) = mean(pTimeLg);
        meanforagetime(2) = mean(pTimeMd);
        meanforagetime(3) = mean(pTimeSm);
        
        meanrews(1) = mean(pRewsLg);
        meanrews(2) = mean(pRewsMd);
        meanrews(3) = mean(pRewsSm);
        
        meanTTmedTT(1) = mean(vr.TT); % *** FIX TT DISPLAYS
        meanTTmedTT(2) = median(vr.TT);
        
        display(meanforagetime);
        display(meanrews);
        
    elseif vr.taskType_ID(1)==5
        
        pXLg = pType==524; pMd = pType==522; pSm = pType==521;
        
        pTimeXLg = pTime(pXLg); pTimeMd = pTime(pMd); pTimeSm = pTime(pSm);
        
        pRewsXLg = pRews(pXLg); pRewsMd = pRews(pMd); pRewsSm = pRews(pSm);
        
        % USE SAME NOTATION FOR PRINTOUT even though XLg rew
        % vr.B == 3, and small vr.B == 1
        %1 = XLg, 2 = Md, 3 = Sm
        meanforagetime(1) = mean(pTimeXLg);
        meanforagetime(2) = mean(pTimeMd);
        
        meanrews(1) = mean(pRewsXLg);
        meanrews(2) = mean(pRewsMd);
        
        %if vr.taskType_ID(2) == 4
        meanforagetime(3) = mean(pTimeSm);
        meanrews(3) = mean(pRewsSm);
        %end
        
        display(meanforagetime);
        display(meanrews);
        
        if ~isnan(meanforagetime(1)) && ~isnan(meanforagetime(2))
            
            semforagetime(1) = std(pTimeXLg)/sqrt(length(pTimeXLg));
            semforagetime(2) = std(pTimeMd)/sqrt(length(pTimeMd));
            
            if vr.taskType_ID(2) == 4 && ~isnan(meanforagetime(3))
                semforagetime(3) = std(pTimeSm)/sqrt(length(pTimeSm));
            end
            
            figure;
            errorbar(1,meanforagetime(1),semforagetime(1)); hold on;
            errorbar(2,meanforagetime(2),semforagetime(2),'g');
            if vr.taskType_ID(2) == 4 && ~isnan(meanforagetime(3))
                errorbar(3,meanforagetime(3),semforagetime(3),'m');
                
                ylim([0 max(meanforagetime)+max(semforagetime)+2]);
                xlim([.8 3.2]);
                set(gca,'xtick',[1 2 3],'xticklabel',[1 2 3])
                
            else
                ylim([0 max(meanforagetime)+max(semforagetime)+2]);
                xlim([.8 2.2]);
                set(gca,'xtick',[1 2],'xticklabel',[1 2])
                %xtick(1:1:3);
            end
            
        else
            display('NaN for 1+ means');
        end
        
    elseif vr.taskType_ID(1)==7
        
        pXLg = pType==724; pMd = pType==722; pSm = pType==721;
        
        pTimeXLg = pTime(pXLg); pTimeMd = pTime(pMd); pTimeSm = pTime(pSm);
        
        pRewsXLg = pRews(pXLg); pRewsMd = pRews(pMd); pRewsSm = pRews(pSm);
        
        if vr.taskType_ID(2)==6 || vr.taskType_ID(2)==7 || vr.taskType_ID(2)==8 || vr.taskType_ID(2)==9
            pXLg_Hi= pType==714; pXLg_Md= pType==724; pXLg_Lo= pType==734;
            pMd_Hi = pType==712; pMd_Md = pType==722; pMd_Lo = pType==732;
            pSm_Hi = pType==711; pSm_Md = pType==721; pSm_Lo = pType==731;
            
            pTimeXLg_Hi = pTime(pXLg_Hi);
            pTimeXLg_Md = pTime(pXLg_Md);
            pTimeXLg_Lo = pTime(pXLg_Lo);
            
            pTimeMd_Hi = pTime(pMd_Hi);
            pTimeMd_Md = pTime(pMd_Md);
            pTimeMd_Lo = pTime(pMd_Lo);
            
            pTimeSm_Hi = pTime(pSm_Hi);
            pTimeSm_Md = pTime(pSm_Md);
            pTimeSm_Lo = pTime(pSm_Lo);
            
            meanforagetime_Hi = [mean(pTimeXLg_Hi) mean(pTimeMd_Hi) mean(pTimeSm_Hi)];
            meanforagetime_Md = [mean(pTimeXLg_Md) mean(pTimeMd_Md) mean(pTimeSm_Md)];
            meanforagetime_Lo = [mean(pTimeXLg_Lo) mean(pTimeMd_Lo) mean(pTimeSm_Lo)];
            
            display(meanforagetime_Hi)
            display(meanforagetime_Md)
            display(meanforagetime_Lo)
            
            figure;
            if ~isnan(meanforagetime_Hi(1)) && ~isnan(meanforagetime_Hi(2)) && ~isnan(meanforagetime_Hi(3))
                semforagetime_Hi(1) = std(pTimeXLg_Hi)/sqrt(length(pTimeXLg_Hi));
                semforagetime_Hi(2) = std(pTimeMd_Hi)/sqrt(length(pTimeMd_Hi));
                semforagetime_Hi(3) = std(pTimeSm_Hi)/sqrt(length(pTimeSm_Hi));
                
                errorbar(1:3,meanforagetime_Hi,semforagetime_Hi,'b'); hold on;
            end
            
            if ~isnan(meanforagetime_Md(1)) && ~isnan(meanforagetime_Md(2)) && ~isnan(meanforagetime_Md(3))
                semforagetime_Md(1) = std(pTimeXLg_Md)/sqrt(length(pTimeXLg_Md));
                semforagetime_Md(2) = std(pTimeMd_Md)/sqrt(length(pTimeMd_Md));
                semforagetime_Md(3) = std(pTimeSm_Md)/sqrt(length(pTimeSm_Md));
                
                errorbar(1:3,meanforagetime_Md,semforagetime_Md,'m');
            end
            
            if ~isnan(meanforagetime_Lo(1)) && ~isnan(meanforagetime_Lo(2)) && ~isnan(meanforagetime_Lo(3))
                semforagetime_Lo(1) = std(pTimeXLg_Lo)/sqrt(length(pTimeXLg_Lo));
                semforagetime_Lo(2) = std(pTimeMd_Lo)/sqrt(length(pTimeMd_Lo));
                semforagetime_Lo(3) = std(pTimeSm_Lo)/sqrt(length(pTimeSm_Lo));
                
                errorbar(1:3,meanforagetime_Lo,semforagetime_Lo,'r');
            end
            
            if ~isempty(meanforagetime_Hi) && ~isempty(meanforagetime_Md) && ~isempty(meanforagetime_Lo) && ...
                    exist('semforagetime_Hi','var') && exist('semforagetime_Md','var') && exist('semforagetime_Lo','var')
                ylim([0 (max([max(meanforagetime_Hi) max(meanforagetime_Md) max(meanforagetime_Lo)]) ...
                    + max([max(semforagetime_Hi) max(semforagetime_Md) max(semforagetime_Lo)]) + 2)]);
                xlim([.8 3.2]);
                set(gca,'xtick',[1 2 3],'xticklabel',{'XLg' 'Md' 'Sm'})
            end
            
        else
            
            meanforagetime(1) = mean(pTimeXLg);
            meanforagetime(2) = mean(pTimeMd);
            meanforagetime(3) = mean(pTimeSm);
            
            meanrews(1) = mean(pRewsXLg);
            meanrews(2) = mean(pRewsMd);
            meanrews(3) = mean(pRewsSm);
            
            display(meanforagetime);
            display(meanrews);
            
            
            if ~isnan(meanforagetime(1)) && ~isnan(meanforagetime(2)) && ~isnan(meanforagetime(3))
                
                semforagetime(1) = std(pTimeXLg)/sqrt(length(pTimeXLg));
                semforagetime(2) = std(pTimeMd)/sqrt(length(pTimeMd));
                semforagetime(3) = std(pTimeSm)/sqrt(length(pTimeSm));
                
                figure;
                errorbar(1,meanforagetime(1),semforagetime(1)); hold on;
                errorbar(2,meanforagetime(2),semforagetime(2),'g');
                errorbar(3,meanforagetime(3),semforagetime(3),'m');
                
                ylim([0 max(meanforagetime)+max(semforagetime)+2]);
                xlim([.8 3.2]);
                set(gca,'xtick',[1 2 3],'xticklabel',['XLg' 'Md' 'Sm'])
            else
                display('NaN for 1+ means');
            end
        end
        
    elseif vr.taskType_ID(1)==8 || vr.taskType_ID(1)==9
        
        if vr.taskType_ID(2)==2 %written in terms of N0(Hi,Md,Lo)/tau
            pHi8= pType==812; pHi4= pType==822; pHi2= pType==832;
            pMd8 = pType==842; pMd4 = pType==852; pMd2 = pType==862;
            pLo8 = pType==872; pLo4 = pType==882; pLo2 = pType==892;
            
            pTimeHi8 = pTime(pHi8);
            pTimeHi4 = pTime(pHi4);
            pTimeHi2 = pTime(pHi2);
            pTimeMd8 = pTime(pMd8);
            pTimeMd4 = pTime(pMd4);
            pTimeMd2 = pTime(pMd2);
            pTimeLo8 = pTime(pLo8);
            pTimeLo4 = pTime(pLo4);
            pTimeLo2 = pTime(pLo2);
            
            %{
                        pRewsHi8 = pRews(pHi8);
                        pRewsHi4 = pRews(pHi4);
                        pRewsHi2 = pRews(pHi4);
                        pRewsMd8 = pRews(pMd8);
                        pRewsMd4 = pRews(pMd4);
                        pRewsMd2 = pRews(pMd4);
                        pRewsLo8 = pRews(pLo8);
                        pRewsLo4 = pRews(pLo4);
                        pRewsLo2 = pRews(pLo4);
            %}
            
            meanforagetime_Hi = [mean(pTimeHi8) mean(pTimeHi4) mean(pTimeHi2)];
            meanforagetime_Md = [mean(pTimeMd8) mean(pTimeMd4) mean(pTimeMd2)];
            meanforagetime_Lo = [mean(pTimeLo8) mean(pTimeLo4) mean(pTimeLo2)];
            
            display(meanforagetime_Hi)
            display(meanforagetime_Md)
            display(meanforagetime_Lo)
            
            figure;
            if ~isnan(meanforagetime_Hi(1)) && ~isnan(meanforagetime_Hi(2)) && ~isnan(meanforagetime_Hi(3))
                semforagetime_Hi(1) = std(pTimeHi8)/sqrt(length(pTimeHi8));
                semforagetime_Hi(2) = std(pTimeHi4)/sqrt(length(pTimeHi4));
                semforagetime_Hi(3) = std(pTimeHi2)/sqrt(length(pTimeHi2));
                
                errorbar(1:3,meanforagetime_Hi,semforagetime_Hi,'b'); hold on;
            end
            
            if ~isnan(meanforagetime_Md(1)) && ~isnan(meanforagetime_Md(2)) && ~isnan(meanforagetime_Md(3))
                semforagetime_Md(1) = std(pTimeMd8)/sqrt(length(pTimeMd8));
                semforagetime_Md(2) = std(pTimeMd4)/sqrt(length(pTimeMd4));
                semforagetime_Md(3) = std(pTimeMd2)/sqrt(length(pTimeMd2));
                
                errorbar(1:3,meanforagetime_Md,semforagetime_Md,'m');
            end
            
            if ~isnan(meanforagetime_Lo(1)) && ~isnan(meanforagetime_Lo(2)) && ~isnan(meanforagetime_Lo(3))
                semforagetime_Lo(1) = std(pTimeLo8)/sqrt(length(pTimeLo8));
                semforagetime_Lo(2) = std(pTimeLo4)/sqrt(length(pTimeLo4));
                semforagetime_Lo(3) = std(pTimeLo2)/sqrt(length(pTimeLo2));
                
                errorbar(1:3,meanforagetime_Lo,semforagetime_Lo,'r');
            end
            
            if ~isempty(meanforagetime_Hi) && ~isempty(meanforagetime_Md) && ~isempty(meanforagetime_Lo) && ...
                    exist('semforagetime_Hi','var') && exist('semforagetime_Md','var') && exist('semforagetime_Lo','var')
                ylim([0 (max([max(meanforagetime_Hi) max(meanforagetime_Md) max(meanforagetime_Lo)]) ...
                    + max([max(semforagetime_Hi) max(semforagetime_Md) max(semforagetime_Lo)]) + 2)]);
                xlim([.8 3.2]);
                set(gca,'xtick',[1 2 3],'xticklabel',{'XLg' 'Md' 'Sm'})
            end
            
        elseif vr.taskType_ID(2)==3
            pHi8= pType==812; pHi4= pType==822;
            pMd8 = pType==842; pMd4 = pType==852;
            
            
            pTimeHi8 = pTime(pHi8);
            pTimeHi4 = pTime(pHi4);
            pTimeMd8 = pTime(pMd8);
            pTimeMd4 = pTime(pMd4);
            
            meanforagetime_Hi = [mean(pTimeHi8) mean(pTimeHi4)];
            meanforagetime_Md = [mean(pTimeMd8) mean(pTimeMd4)];
            
            display(meanforagetime_Hi)
            display(meanforagetime_Md)
            
            figure;
            if ~isnan(meanforagetime_Hi(1)) && ~isnan(meanforagetime_Hi(2))
                semforagetime_Hi(1) = std(pTimeHi8)/sqrt(length(pTimeHi8));
                semforagetime_Hi(2) = std(pTimeHi4)/sqrt(length(pTimeHi4));
                
                errorbar(1:2,meanforagetime_Hi,semforagetime_Hi,'b'); hold on;
            end
            
            if ~isnan(meanforagetime_Md(1)) && ~isnan(meanforagetime_Md(2))
                semforagetime_Md(1) = std(pTimeMd8)/sqrt(length(pTimeMd8));
                semforagetime_Md(2) = std(pTimeMd4)/sqrt(length(pTimeMd4));
                
                errorbar(1:2,meanforagetime_Md,semforagetime_Md,'m');
            end
            if ~isempty(meanforagetime_Hi) && ~isempty(meanforagetime_Md) && ...
                    exist('semforagetime_Hi','var') && exist('semforagetime_Md','var')
                ylim([0 (max([max(meanforagetime_Hi) max(meanforagetime_Md)]) ...
                    + max([max(semforagetime_Hi) max(semforagetime_Md)]) + 2)]);
                xlim([.8 2.2]);
                set(gca,'xtick',[1 2],'xticklabel',{'XLg' 'Md'})
            end
            
        elseif vr.taskType_ID(2)==4
            pMd4 = pType==852; pMd2 = pType==862;
            pLo4 = pType==882; pLo2 = pType==892;
            
            pTimeMd4 = pTime(pMd4);
            pTimeMd2 = pTime(pMd2);
            pTimeLo4 = pTime(pLo4);
            pTimeLo2 = pTime(pLo2);
            
            meanforagetime_Md = [mean(pTimeMd4) mean(pTimeMd2)];
            meanforagetime_Lo = [mean(pTimeLo4) mean(pTimeLo2)];
            
            display(meanforagetime_Md)
            display(meanforagetime_Lo)
            
            figure;
            if ~isnan(meanforagetime_Md(1)) && ~isnan(meanforagetime_Md(2))
                semforagetime_Md(1) = std(pTimeMd4)/sqrt(length(pTimeMd4));
                semforagetime_Md(2) = std(pTimeMd2)/sqrt(length(pTimeMd2));
                
                errorbar(1:2,meanforagetime_Md,semforagetime_Md,'m'); hold on;
            end
            
            if ~isnan(meanforagetime_Lo(1)) && ~isnan(meanforagetime_Lo(2))
                semforagetime_Lo(1) = std(pTimeLo4)/sqrt(length(pTimeLo4));
                semforagetime_Lo(2) = std(pTimeLo2)/sqrt(length(pTimeLo2));
                
                errorbar(1:2,meanforagetime_Lo,semforagetime_Lo,'r');
            end
            
            if ~isempty(meanforagetime_Md) && ~isempty(meanforagetime_Lo) && ...
                    exist('semforagetime_Md','var') && exist('semforagetime_Lo','var')
                ylim([0 (max([max(meanforagetime_Md) max(meanforagetime_Lo)]) ...
                    + max([max(semforagetime_Md) max(semforagetime_Lo)]) + 2)]);
                xlim([.8 2.2]);
                set(gca,'xtick',[1 2],'xticklabel',{'Md' 'Sm'})
            end
        elseif vr.taskType_ID(1)==9 && vr.taskType_ID(2)==1
            pHi8= pType==812; pHi4= pType==822; pHi2= pType==832;
            
            pTimeHi8 = pTime(pHi8);
            pTimeHi4 = pTime(pHi4);
            pTimeHi2 = pTime(pHi2);
            
            meanforagetime_Hi = [mean(pTimeHi8) mean(pTimeHi4) mean(pTimeHi2)];
            display(meanforagetime_Hi)
            
            figure;
            if ~isnan(meanforagetime_Hi(1)) && ~isnan(meanforagetime_Hi(2)) && ~isnan(meanforagetime_Hi(3))
                semforagetime_Hi(1) = std(pTimeHi8)/sqrt(length(pTimeHi8));
                semforagetime_Hi(2) = std(pTimeHi4)/sqrt(length(pTimeHi4));
                semforagetime_Hi(3) = std(pTimeHi2)/sqrt(length(pTimeHi2));
                
                errorbar(1:3,meanforagetime_Hi,semforagetime_Hi,'b'); hold on;
            end
            
        else
            display('ERROR WHAT TASK TYPE?????')
            
        end
        
        if vr.dispSet > 0
            %for i = 1:length(vr.RewTimes2)
            %    RTs2 = [i vr.RewTimes2{i}];
            %    display(RTs2);
            %end
            
            for i = 1:length(vr.RewTimes)
                RTs = [i vr.RewTimes{i}];
                display(RTs);
            end
            
        end
        
    elseif vr.taskType_ID(1)==3
        
        pHi_blockH = pType==413;
        pMd_blockH = pType==422;
        
        pLo_blockL = pType==341;
        pMd_blockL = pType==322;
        
        if sum(pHi_blockH) > 0
            %sum_pHi = sum(pHi_blockH); display(sum_pHi);
            
            pTimeHi_blockH = pTime(pHi_blockH);
            pTimeMd_blockH = pTime(pMd_blockH);
            
            pRewsHi_blockH = pRews(pHi_blockH); pRewsMd_blockH = pRews(pMd_blockH);
            
            meanforagetime_HiMd(1) = mean(pTimeHi_blockH);
            meanforagetime_HiMd(2) = mean(pTimeMd_blockH);
            
            meanrews_HiMd(1) = mean(pRewsHi_blockH);
            meanrews_HiMd(2) = mean(pRewsMd_blockH);
            
            display(meanforagetime_HiMd);
            display(meanrews_HiMd);
            
        else
            %display('sum pHi = 0');
        end
        
        if sum(pLo_blockL) > 0
            %sum_pLo = sum(pLo_blockL); display(sum_pLo);
            
            pTimeLo_blockL = pTime(pLo_blockL);
            pTimeMd_blockL = pTime(pMd_blockL);
            
            pRewsLo_blockL = pRews(pLo_blockL); pRewsMd_blockL = pRews(pMd_blockL);
            
            meanforagetime_LoMd(1) = mean(pTimeLo_blockL);
            meanforagetime_LoMd(2) = mean(pTimeMd_blockL);
            
            meanrews_LoMd(1) = mean(pRewsLo_blockL);
            meanrews_LoMd(2) = mean(pRewsMd_blockL);
            
            display(meanforagetime_LoMd);
            display(meanrews_LoMd);
            
        else
            %display('sum pLo = 0');
        end
        
        Md_count_LoBlock_HiBlock = [sum(pMd_blockL) sum(pMd_blockH)];
        display(Md_count_LoBlock_HiBlock);
        
        if Md_count_LoBlock_HiBlock(1) >= 5 && Md_count_LoBlock_HiBlock(2) >= 5
            mean_Md5_LoBL_HiBL(1) = mean(pTimeMd_blockL(1:5));
            mean_Md5_LoBL_HiBL(2) = mean(pTimeMd_blockH(1:5));
            display(mean_Md5_LoBL_HiBL);
        end
        
        fixBlock = vr.fixBlock; display(fixBlock);
        
    elseif vr.taskType_ID(1)==4
        
        pHi_blockH = pType==411;
        pMd_blockH = pType==421;
        
        pLo_blockL = pType==341;
        pMd_blockL = pType==321;
        
        if sum(pHi_blockH) > 0
            %sum_pHi = sum(pHi_blockH); display(sum_pHi);
            
            pTimeHi_blockH = pTime(pHi_blockH);
            pTimeMd_blockH = pTime(pMd_blockH);
            
            pRewsHi_blockH = pRews(pHi_blockH); pRewsMd_blockH = pRews(pMd_blockH);
            
            meanforagetime_HiMd(1) = mean(pTimeHi_blockH);
            meanforagetime_HiMd(2) = mean(pTimeMd_blockH);
            
            meanrews_HiMd(1) = mean(pRewsHi_blockH);
            meanrews_HiMd(2) = mean(pRewsMd_blockH);
            
            display(meanforagetime_HiMd);
            display(meanrews_HiMd);
            
        else
            %display('sum pHi = 0');
        end
        
        if sum(pLo_blockL) > 0
            %sum_pLo = sum(pLo_blockL); display(sum_pLo);
            
            pTimeLo_blockL = pTime(pLo_blockL);
            pTimeMd_blockL = pTime(pMd_blockL);
            
            pRewsLo_blockL = pRews(pLo_blockL); pRewsMd_blockL = pRews(pMd_blockL);
            
            meanforagetime_LoMd(1) = mean(pTimeLo_blockL);
            meanforagetime_LoMd(2) = mean(pTimeMd_blockL);
            
            meanrews_LoMd(1) = mean(pRewsLo_blockL);
            meanrews_LoMd(2) = mean(pRewsMd_blockL);
            
            display(meanforagetime_LoMd);
            display(meanrews_LoMd);
            
        else
            %display('sum pLo = 0');
        end
        
        
        
        
    else
        display('**ERROR task type ID not recognized ERROR**');
        
    end
    
    meanTTmedTT(1) = mean(vr.TT); % *** FIX TT DISPLAYS
    meanTTmedTT(2) = median(vr.TT);
    display(meanTTmedTT);
end

