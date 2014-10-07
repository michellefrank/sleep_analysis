function [consolidatedFlies, controlActivity] = getIsSleepingSpont2(checkStruct, flies, norm_offset)
% Outputs both a struct and an array of sleeping flies from a given night if passed
% information about stimulus onset/offset and a struct containing data for
% the night of interest. The main difference between flyArray and
% consolidatedFlies is the format (struct vs. array) and the fact that the
% struct uses a NaN for flies that were already awake prior to stim onset.
% checkStruct contains keys found in the environmental monitor for all
% epochs of light stimulus.
% night is the night for which data is going to be parsed.
%
% This function is an adaptation of getIsSleeping specifically to find
% spontaneously waking flies in a night on which no stimulus was delivered.
% The night of interest should be the control night, and the checkStruct
% here should be a structure containing the times of various stimuli as
% found using getIsSleeping.


%{

relevant component of checkStruct has the form [as passed from
light_analysisRevised]

for k=1:numStim

    stim_windows{k}.onsetConv = envMonitor.textdata(stim_windows{k}.onset,1);
    stim_windows{k}.offsetConv = envMonitor.textdata(stim_windows{k}.offset,1);
    stim_windows{k}.sleepStartConv = envMonitor.textdata(stim_windows{k}.sleepStart,1);
    stim_windows{k}.checkActivityConv = envMonitor.textdata(stim_windows{k}.checkActivity,1);
end

(where numStim is the TOTAL number of stimuli found in the environmental
monitor, not just the number of that particular night)

%}


%% Search through night for light pulses
% Given info about the locations of light pulses from the environmental monitor, 
% find any corresponding epochs in the night of interest

% Convert times from experimental night to indices for the control night

nightlyStimPulses = length(checkStruct);

for k=1:nightlyStimPulses
    checkStruct{k}.onsetFly = find(strcmp(flies.textdata(:,3),checkStruct{k}.onset(1)))-norm_offset;
    checkStruct{k}.offsetFly = find(strcmp(flies.textdata(:,3),checkStruct{k}.offset(1)))-norm_offset;
    checkStruct{k}.sleepStartFly = find(strcmp(flies.textdata(:,3),checkStruct{k}.sleepStart(1)))-norm_offset;
    checkStruct{k}.checkActivityFly = find(strcmp(flies.textdata(:,3),checkStruct{k}.checkActivity(1)))-norm_offset; 
end

% Make new cell array to specifically hold info for this night
nightWindows = {};
for i=1:nightlyStimPulses
    
    nightWindows{i} = struct();
    
end

% Get indices to check

for k=1:nightlyStimPulses
    
    nightWindows{k}.checkSleep = checkStruct{k}.sleepStartFly:checkStruct{k}.onsetFly-1;
    nightWindows{k}.checkWake = checkStruct{k}.onsetFly:checkStruct{k}.checkActivityFly-1;
    
end

% Make fly sleep data structure
numFlies = length(flies.data(1,:));
flyArray = cell(nightlyStimPulses,numFlies); %Make cell of form {row: stim pulse; column: individual fly}

for i = 1:nightlyStimPulses
    
    for j = 1:numFlies
        flyArray{i,j} = struct();
    end
    
end

controlActivity = [];

% Find flies that woke up

for i = 1:nightlyStimPulses

    for j = 1:numFlies

        controlActivity(i,j) = sum(flies.data(nightWindows{i}.checkWake,j));
        
        if find(flies.data(nightWindows{i}.checkSleep,j)) %If there's any activity in the window before the stim, classify sleep as false
            flyArray{i,j}.isSleep = 0;
        else
            flyArray{i,j}.isSleep = 1;
        end
       
        if flyArray{i,j}.isSleep == 0
            flyArray{i,j}.isWakes = NaN; %If the flies weren't asleep before the stimulus, call it a NaN
        elseif find(flies.data(nightWindows{i}.checkWake,j)) %If there's any activity during the stim interval, make it a 1!
            flyArray{i,j}.isWakes = 1;
        else
            flyArray{i,j}.isWakes = 0;
        end
            
    end
    
end

controlActivity = reshape(controlActivity, [], 1);

%Rearrange stuff into an array of form [stimNum fliesWaking] for each stimulus

consolidatedFlies = zeros(nightlyStimPulses, numFlies);

for i = 1:nightlyStimPulses
    
    for j = 1:numFlies
        
        consolidatedFlies(i,j) = flyArray{i,j}.isWakes;
        
    end
    
end
