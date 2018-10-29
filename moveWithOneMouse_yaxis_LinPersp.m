% code by HRK, last edits: MB 10-18-18

function velocity = moveWithOneMouse_yaxis_LinPersp(vr)
% y value only***
global manual_inst_vel
global animal_inst_vel

velocity = [0 0 0 0];

% Read data from NIDAQ
data = peekdata(vr.ai,50);

% Remove NaN's from the data (these occur after NIDAQ has stopped)
f = isnan(mean(data,2));
data(f,:) = [];
data = mean(data,1)';
data(isnan(data)) = 0;

% Update velocity
% data = [cosd(-45) -sind(-45); sind(-45) cosd(-45)]*data; % commented out
% by HRK. 11/10/2014
if ~isfield(vr,'scaling')
    vr.scaling = [13 13];
end

velocity(2) = vr.scaling(2)*data(1);  % HRK 1/19/2015 changed mouse position for rotation accuracy

velocity(4) = vr.scaling(1) * (data(1) - 0.3 * (data(2)/3)); % HRK 2/17/2015 realized that I was doing unnatual way!

velocity(1:2) = [cos(vr.position(4)) -sin(vr.position(4)); sin(vr.position(4)) cos(vr.position(4))]*velocity(1:2)';

% assign animal's instantaneous velocity
animal_inst_vel = velocity;

% overwrite with manual instantaneous velocity
if ~isempty(manual_inst_vel) && size(manual_inst_vel,2) == 4
   velocity(~isnan(manual_inst_vel)) = manual_inst_vel(~isnan(manual_inst_vel));
end