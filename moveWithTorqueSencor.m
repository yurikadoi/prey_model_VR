function velocity = moveWithTorqueSensor(vr)
global idle_voltage_offset


velocity = [0 0 0 0];

% Read data from NIDAQ
data = peekdata(vr.ai, 25); % 50 -> variable (25) 1/22/2018 HRK

% Remove NaN's from the data (these occur after NIDAQ has stopped)
f = isnan(mean(data, 2));
data(f,:) = [];
data = mean(data,1)';
data(isnan(data)) = 0;

velocity(2) = vr.scaling(2)*(data(5) - idle_voltage_offset(5));  % HRK 1/19/2015 changed mouse position for rotation accuracy


if isnan(velocity(2))
    keyboard
end