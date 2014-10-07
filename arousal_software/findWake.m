function [responses, allActivities_wake, allActivities_sleep, controlActivity] = findWake(fly, expData, stim_windows, numStim, root_dir, save_path, norm_offset)
% For each genotype used in a given experiment, imports the monitor
% containing those flies, parses out on the relevant channels,
% calculates the percentage that woke up, and returns that value as a cell.
% fly = the genotype of interest (e.g. 'ED')
% stim_windows = the windows containing a stimulus, calculated in the
% LightAnalysis script
% save_path is the path to which the file should be saved
% norm_offset is the number of bins back to check for spontaneous wakenings.
% If so, normalization computes the spontaneous wakenings from a 10 minute
% period prior to simulus onset.

%% Import the monitor info we're interested in and search it for flies that wake up

flies = readMonitor2(fly, expData, root_dir);

[flyArray, flySleepArray, stimTimes] = getIsSleeping(stim_windows, flies, numStim);

% Find percent of flies awakening in response to each stimulus
% Because we put NaNs into the sleep array for all flies who weren't sleeping before stim onset, the percent is just the number of wakings (nansum) over the total number of flies - the number who weren't sleeping 

PercentAwakened = zeros(1,length(flySleepArray(:,1)));

for i=1:length(PercentAwakened)
    
    PercentAwakened(i) = nansum(flySleepArray(i,:)) / ( length(flySleepArray(i,:)) - sum(isnan(flySleepArray(i,:))) );
    
end

%% Normalization
% Find spontaneously waking flies by checking over a window of time before stimulus onset for any flies that wake up
    
[controlArray, controlActivity] = getIsSleepingSpont2(stimTimes,flies,norm_offset);


% Calculate spontaneous wakenings

PercentSpontaneous = zeros(1, length(controlArray(:,1)));

for i=1:length(PercentSpontaneous)
    PercentSpontaneous(i) = nansum(controlArray(i,:)) / ( length(controlArray(i,:)) - sum(isnan(controlArray(i,:))) );
end


% Normalize NoI wakenings - (% aroused - % spontaneously awake)/ (100% - % spontaneously awake)
NormalizedPercents = zeros(1, length(controlArray(:,1)));

for i = 1:length(NormalizedPercents)
    NormalizedPercents(i) = ( PercentAwakened(i) - PercentSpontaneous(i) ) / (1 - PercentSpontaneous(i));
end

% Extract intensity stuff
intensities = str2num(expData.stim_intensities);

% Format stuff into an array with elements 
% Stimulus Number, Stim Intensity, Normalized Percent Awakened, Percent Awakened, Percent Spontaneous

LightResponsesAggregate = [];
for i = 1:numStim
    LightResponsesAggregate(i,1) = i;
    LightResponsesAggregate(i,2) = intensities(i);
    LightResponsesAggregate(i,3) = NormalizedPercents(i);
    LightResponsesAggregate(i,4) = PercentAwakened(i);
    LightResponsesAggregate(i,5) = PercentSpontaneous(i);
end

% Sort that array by the intensities
[Y,I] = sort(LightResponsesAggregate(:,2));
responses = LightResponsesAggregate(I,:);


%% Extract activity info

allActivities_sleep = [];
allActivities_wake = [];

for i = 1:length(flyArray(:,1))
    
    for j = 1:length(flyArray(1,:))
        
        if flyArray{i,j}.isSleep == 0
            
            allActivities_wake = [allActivities_wake; intensities(i), flyArray{i,j}.activity];
        
        else
            
            allActivities_sleep = [allActivities_sleep; intensities(i), flyArray{i,j}.activity];
        
        end
    end
end

% sort by intensity

[Y,I] = sort(allActivities_wake(:,1));
[y2,I2] = sort(allActivities_sleep(:,1));
allActivities_wake = allActivities_wake(I,:);
allActivities_sleep = allActivities_sleep(I2,:);    
    


%% Export the raw sleep array (of flies sleeping vs not sleeping)

LightResponsesRaw = {'Stimulus Number', 'Stim intensity'};

for i = 1:length(flySleepArray(1,:))
    LightResponsesRaw{1,i+2} = '';
end

for i = 1:numStim
    LightResponsesRaw{i+1,1} = i;
    LightResponsesRaw{i+1,2} = intensities(i);
    
    for j = 1:length(flySleepArray(1,:))
        LightResponsesRaw{i+1,j+2} = flySleepArray(i,j);
    end
end
    
fileSaveRaw = [fullfile(root_dir, save_path, 'raw', fly.genotype), '-raw.csv'];
cell2csv(fileSaveRaw, LightResponsesRaw);


