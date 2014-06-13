function findWake(fly, expData, stim_windows, numStim, root_dir, save_path, norm_offset)
% For each genotype used in a given experiment, imports the monitor
% containing those flies, parses out on the relevant channels, and
% calculates the percentage that woke up.
% fly = the genotype of interest (e.g. 'ED')
% stim_windows = the windows containing a stimulus, calculated in the
% LightAnalysis script
% save_path is the path to which the file should be saved
% norm_offset is the number of bins back to check for spontaneous wakenings.
% If so, normalization computes the spontaneous wakenings from a 10 minute
% period prior to simulus onset.

%% Import the monitor info we're interested in and search it for flies that wake up

flies = readMonitor2(fly, expData, root_dir);

[~, flySleepArray, stimTimes] = getIsSleeping(stim_windows, flies, numStim);

% Find percent of flies awakening in response to each stimulus
% Because we put NaNs into the sleep array for all flies who weren't sleeping before stim onset, the percent is just the number of wakings (nansum) over the total number of flies - the number who weren't sleeping 

PercentAwakened = zeros(1,length(flySleepArray(:,1)));

for i=1:length(PercentAwakened)
    
    PercentAwakened(i) = nansum(flySleepArray(i,:)) / ( length(flySleepArray(i,:)) - sum(isnan(flySleepArray(i,:))) );
    
end

%% Save it all!

LightResponses = {'Stimulus', 'Percent Awakened'};

for i = 1:numStim
    LightResponses{i+1,1} = i;
    LightResponses{i+1,2} = PercentAwakened(i);
end
    
% Export that cell into a file

fileSave = [fullfile(root_dir, save_path, fly.genotype), '.csv'];
% cell2csv(fileSave,LightResponses);


%% Normalization
% Find spontaneously waking flies by checking over a window of time before stimulus onset for any flies that wake up


if norm_offset
    
    controlArray = getIsSleepingSpont2(stimTimes,flies,norm_offset);

    
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
    
    % Format stuff into a cell
    LightResponsesNormed = {'Stimulus', 'Normalized Percent Awakened', 'Percent Awakened', 'Percent Spontaneous', 'Stim intensity'};
    
    for i = 1:numStim
        LightResponsesNormed{i+1,1} = i;
        LightResponsesNormed{i+1,2} = NormalizedPercents(i);
        LightResponsesNormed{i+1,3} = PercentAwakened(i);
        LightResponsesNormed{i+1,4} = PercentSpontaneous(i);
        LightResponsesNormed{i+1,5} = intensities(i);
    end

    % Export that cell into a file
    fileSaveNorm = [fullfile(root_dir, save_path, fly.genotype), '-normed.csv'];

    cell2csv(fileSaveNorm,LightResponsesNormed);
    
end

%% Also export the raw sleep array (of flies sleeping vs not sleeping)

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
    
fileSaveRaw = [fullfile(root_dir, save_path, fly.genotype), '-raw.csv'];
cell2csv(fileSaveRaw, LightResponsesRaw);

% LightResponsesRaw = {'Stimulus Number'};
% 
% for i = 1:length(flySleepArray(1,:))
%     LightResponsesRaw{1,i+1} = '';
% end
% 
% 
% for i = 1:numStim
%     LightResponsesRaw{i+1,1} = i;
%     
%     for j = 1:length(flySleepArray(1,:))
%         LightResponsesRaw{i+1,j+1} = flySleepArray(i,j);
%     end
% end
%     
% fileSaveRaw = [fullfile(root_dir, save_path, fly.genotype), '-raw.csv'];
% cell2csv(fileSaveRaw, LightResponsesRaw);


