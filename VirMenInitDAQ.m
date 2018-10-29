% laser edits MB 10-23-18

VirMEn_Def;
vr.DAQ_BOARD = 'Dev1';
try
    daqhwinfo
    DAQ_MODE = 'legacy'
catch 
    DAQ_MODE = 'session'
end

% 5000 -> 7000 2/3/2015 HRK
vr.AO_SR = 1000; % 7000->1000 5/19/2015 HRK now I don't use sound from this ao
vr.finalPathname = VIRMEN_DATA_DIR;
vr.pathname = VIRMEN_DATA_DIR;
daq_filename = datestr(now,'yyyymmdd_HHMMSS')
vr.filename = daq_filename;

if ~vr.debugMode
    
    % TrialSE, Reward can be changed to digital input (second port) after
    % confirming that the timestamp is same between AI and DI
    cAI_ChannelName = {'Velocity','Lick','RewValve','Events'};%,'Photo1','Photo2','OptoLaser'};
    
    switch( DAQ_MODE)
        case 'legacy'
            display('sanity check')
            %reset DAQ in case it's still in use by a previous Matlab program
            daqreset;
            % initalize and start analog input
            vr.ai = analoginput('nidaq', vr.DAQ_BOARD); % connect to the DAQ card
            % 0 : dX, 1: dY, 2: licking 3: LED photodiode 
            % 4: start start/stop dio
            addchannel(vr.ai,0:(length(cAI_ChannelName)-1)); %
            % set channel name % 6/14/2015
            for iCh = 1:length(cAI_ChannelName)
               set(vr.ai.Channel(iCh), 'ChannelName', cAI_ChannelName{iCh});
            end
            set(vr.ai,'samplerate',1000,'samplespertrigger',1e7); % define buffer
            set(vr.ai,'InputType','SingleEnded'); %% added by HRK 11/10/2014
            set(vr.ai,'LoggingMode','Disk&Memory','LogFileName', [VIRMEN_DATA_TMP_DIR vr.filename '.daq']);
            set(vr.ai,'TriggerType', 'Manual')
            start(vr.ai);
            tTIC = tic;

            pause(0.5); % take a break...
%             tvBeforeTrigger = clock();
            sBeforeTrigger = toc(tTIC);
            trigger(vr.ai); % start acquisition
%             tvAfterTrigger = clock();
            sAfterTrigger = toc(tTIC);
            %     fprintf(1, 'Before: %s\nInitialTrigger: %s\nAfter: %s\n', ...
            %         datestr(tvBeforeTrigger), datestr(vr.ai.InitialTriggerTime), datestr(tvAfterTrigger));
%             sB = etime([tvBeforeTrigger], tvBeforeTrigger * 1000);
%             sT = etime([vr.ai.InitialTriggerTime], tvBeforeTrigger * 1000);
%             sA = etime([tvAfterTrigger], tvBeforeTrigger * 1000);

            sB = 0;
            sT = sBeforeTrigger * 1000;
            sA = sAfterTrigger * 1000;

            fprintf(1, 'InitTriggerTime test: %f (before), %f (trig), %f (after)\n', sB, sT, sA);
            % initialize analog output
            vr.ao = analogoutput('nidaq', vr.DAQ_BOARD);
            addchannel(vr.ao,[0 1 2 3]); % one per vr.AO channel: 0 = reward, 1 = event signals to DAQ AI, 2 = opto laser, 3 = auditory tone
            %     set(vr.ao,'samplerate',40000);
            set(vr.ao,'samplerate', vr.AO_SR); % HRK
            set(vr.ao,'TriggerType', 'manual'); % HRK
            set(vr.ao.Channel,'DefaultChannelValue',0)
            set(vr.ao,'OutOfDataMode','DefaultValue')
            
            % initialize sound output
            vr.ao_snd = analogoutput('winsound');
            vr.ao_snd.SampleRate = 8000;
            addchannel(vr.ao_snd, 1:2);
            set(vr.ao_snd,'TriggerType', 'manual');
            
            % initialize and start digital output
            vr.dio = digitalio('nidaq', vr.DAQ_BOARD);
            addline(vr.dio,0:7,'out');
            start(vr.dio);
            % if trials are aborted, it is set to 1. reset all to zero.
            putvalue(vr.dio,[0 0 0 0 0 0 0 0]); 
            
        case 'session' 
            % helpful code comparison
            % http://www.mathworks.com/help/daq/transition-your-code-to-session-based-interface.html?refresh=true
            daq.reset
            d = daq.getDevices
            vr.sin = daq.createSession('ni')
            set(vr.sin ,'Rate',1000)
            vr.sin.addAnalogInputChannel('Dev1', 0, 'Voltage');
            set(vr.sin.Channels(1:2), 'TerminalConfig','SingleEnded')
            vr.sin.NumberOfScans = 1e7;
%             set(vr.ai,'samplespertrigger',1e7); % define buffer
%             set(vr.ai,'LoggingMode','Disk&Memory','LogFileName', [vr.pathname '\' vr.filename '.daq']);
%             set(vr.ai,'TriggerType', 'Manual')
%             start(vr.ai);
            pause(0.5); % take a break...
            tvBeforeTrigger = clock();
            
            vr.sin.startBackground;
            
            tvAfterTrigger = clock();
            sB = etime([tvBeforeTrigger], tvBeforeTrigger);
            sT = etime([vr.ai.InitialTriggerTime], tvBeforeTrigger);
            sA = etime([tvAfterTrigger], tvBeforeTrigger);
            fprintf(1, 'InitTriggerTime test: %f (before), %f (trig), %f (after)\n', sB, sT, sA);
            
            vr.sout = daq.createSession('ni');
            vr.sout.addAnalogOutputChannel('Dev2',0:1,'Voltage');

            %     set(vr.ao,'samplerate',40000);
            vr.sout.Rate = vr.AO_SR; % HRK
%             set(vr.ao,'TriggerType', 'manual'); % HRK
                       
            % initialize sound output
            vr.ao_snd = analogoutput('winsound');
            vr.ao_snd.SampleRate = 8000;
            addchannel(vr.ao_snd, 1:2);
            
            % initialize and start digital output
            vr.dio = digitalio('nidaq', vr.DAQ_BOARD);
            addline(vr.dio,0:7,'out');
            start(vr.dio);
            
        otherwise
            error('Unknown DAQ mode: %s', DAQ_MODE);
    end
    % initialize msPrevEvent
    global g_exp
    g_exp.InitialTriggerTime = vr.ai.InitialTriggerTime;
    g_exp.msInitialTocTime = 1000 * mean([sBeforeTrigger sAfterTrigger]);
    g_exp.InitialTicTime = tTIC;
    
end

% disp(vr.RewDuration)
% generate beep sound voltage signal to indicate reward delivery
vSnd = 5 * ones(10*vr.AO_SR,1); vSnd(1:2:end) = vSnd(1:2:end) * -1;
iSndOff = floor(0.080 * vr.AO_SR); % sound for 80ms
vSnd(iSndOff:end) = 0;
% beep sound for signaling trial start
% left speaker is in the rig. windows pannel volumn is 50 (half),
% matlab application volumn is also half. speaker knob is half way.
vr.vSnd = [vSnd(1:(iSndOff+5)) zeros(size(vSnd(1:(iSndOff+5)))) ];

out_data = [0 5 * ones(1, floor(vr.RewDuration/1000*vr.AO_SR)) 0]';
% out_data = [out_data vSnd(1:length(out_data))]; % reward + sound
out_data = [out_data zeros(size(out_data))];   % reward + no sound
vr.vRewOut = out_data;
