% Script for reading in metadata about experiment parameters, importing
% relevant monitor data, and calculating the percentage of flies that wake
% up following a given light stimulus
% V.3 by MMF 03.05.14

%% Set global parameters

% Enter the expirment date
expDate = '2014-05-24';

% Set the root directory and extension to save the files
root_dir = '/Users/michelle/Documents/flies/light';

% Set the number of bins to check for sleep before a stimulus
sleep_delay = 12; %6 min

% Set the number of bins to check after a stimulus for waking
wake_offset = 5; %Three minutes from the onset of a thirty-second stim

% Set the offset (in number of bins) to check for normalization; if you
% don't want to normalize, make this zero
norm_offset = 20;

%% Import metadata and environmental monitor

% Import metadata
expInfo = ReadYaml([fullfile(root_dir, 'Metadata',expDate),'.yaml']);

% Import environmental monitor
envMonitor = readEnvMonitor(expInfo,root_dir);

% Set the path to save the files to (based on default structure + info from
% expInfo)

save_path = fullfile('AnalyzedData',['Group-',num2str(expInfo.group_num)], expDate);

%% Find places in environment monitor with lights on

light_intensities = [];
light_intensities = envMonitor.data(:,9);
stim_indices = [];

%Search through environmental monitor for places where the light was on
stim_indices = find(light_intensities > 10);

%Set up array to hold info about the windows
stim_windows = {};

winDex = 1;
stim_windows{1} = struct();
stim_windows{1}.onset = stim_indices(1);

%Step through indices and identify places where they jump; store as stim
%onset and offset
for k=2:length(stim_indices)
    
    if stim_indices(k) - stim_indices(k-1) ~= 1
        stim_windows{winDex}.offset = stim_indices(k-1);
        winDex = winDex + 1;
        stim_windows{winDex} = struct();
        stim_windows{winDex}.onset = stim_indices(k);
    end
        
end

stim_windows{winDex}.offset = stim_indices(end);

numStim = winDex;

% Define periods of interest before and after the stimulus
for k=1:numStim
    
    stim_windows{k}.sleepStart = stim_windows{k}.onset-sleep_delay;
    stim_windows{k}.checkActivity = stim_windows{k}.offset+wake_offset;
    
end

stimDateTimes = {};

% Convert indices to key that can be used to search monitor data
for k=1:numStim
    
    stim_windows{k}.onsetConv = envMonitor.textdata(stim_windows{k}.onset,1);
    stim_windows{k}.offsetConv = envMonitor.textdata(stim_windows{k}.offset,1);
    stim_windows{k}.sleepStartConv = envMonitor.textdata(stim_windows{k}.sleepStart,1);
    stim_windows{k}.checkActivityConv = envMonitor.textdata(stim_windows{k}.checkActivity,1);
    stimDateTimes{k} = [envMonitor.textdata(stim_windows{k}.onset,2), envMonitor.textdata(stim_windows{k}.onset,3)];

end




%% Search through fly monitors for activity for each of the given genotypes
% The findWake function imports the relevant data and saves the info to a
% csv file

for i = 1:length(expInfo.flies)
    
    findWake(expInfo.flies{i}, expInfo, stim_windows, numStim, root_dir, save_path, norm_offset);
    
end

