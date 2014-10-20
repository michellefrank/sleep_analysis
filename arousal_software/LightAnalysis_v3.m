% Script for reading in metadata about experiment parameters, importing
% relevant monitor data, and calculating the percentage of flies that wake
% up following a given light stimulus
% V.3 by MMF 03.05.14

%% Set global parameters

% Enter the experiment date
expFile = '2014-10-02';
expDate = expFile(1:10);

% Set the root directory and extension to save the files
root_dir = '/Users/michelle/Documents/flies/Joinage';
specific_dir = uigetdir(root_dir);

% Set the number of bins to check for sleep before a stimulus
sleep_delay = 12; %6 min

% Set the number of bins to check after a stimulus for waking
wake_offset = 5; %Three minutes from the onset of a thirty-second stim

% Set the offset (in number of bins) to check for normalization; if you
% don't want to normalize, make this zero
norm_offset = 20;

%% Import metadata and environmental monitor

% Import metadata
expInfo = ReadYaml([fullfile(specific_dir,expFile),'.yaml']);

% Import environmental monitor
%envMonitor = readEnvMonitor(expInfo,root_dir);


% Set the path to save the files to (based on default structure + info from
% expInfo)

save_path = fullfile('AnalyzedData',['Group-',num2str(expInfo.group_num)], expDate);

%% Find indices corresponding to stimulus onset
stim_indices = [];

save_path = ['Group-',num2str(expInfo.group_num)];

%% Find places in environment monitor with stim on
%Search through environmental monitor for places where the light was on
stim_indices = [];

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
% The findWake function imports the relevant data and parses arousal
% responses.

% Create cell array of structs to house all of the data
wakeResults = {};

for i = 1:length(expInfo.flies)
    
    wakeResults{i} = struct;
    wakeResults{i}.genotype = expInfo.flies{i}.genotype;
    
    [wakeResults{i}.wakeResults, wakeResults{i}.sleepActivity, wakeResults{i}.wakeActivity, wakeResults{i}.controlActivity] = findWake(expInfo.flies{i}, expInfo, stim_windows, numStim, root_dir, save_path, norm_offset);
    
end

%% Print aggregate info to a csv

% Create cell to hold all of the aggregate stuff
wakeFinal = {'Genotype', 'Stimulus Number', 'Stim Intensity', 'Normalized Percent Awakened', 'Percent Awakened', 'Percent Spontaneous'};

index = 2;

for i = 1:length(wakeResults)
    
    for j = 1:numStim
        wakeFinal{index,1} = wakeResults{i}.genotype;
        wakeFinal{index,2} = wakeResults{i}.wakeResults(j,1);
        wakeFinal{index,3} = wakeResults{i}.wakeResults(j,2);
        wakeFinal{index,4} = wakeResults{i}.wakeResults(j,3);
        wakeFinal{index,5} = wakeResults{i}.wakeResults(j,4);
        wakeFinal{index,6} = wakeResults{i}.wakeResults(j,5);
        index = index + 1;
    end
    
end

% Export that data to a csv
fileSaveDir = [fullfile(root_dir, save_path), '/results.csv'];
   
cell2csv(fileSaveDir, wakeFinal);


%% Do the same for activity computations

activity_wake = {'Genotype', 'Intensity', 'Activity'};
activity_sleep = {'Genotype', 'Intensity', 'Activity'};

index_sleep = 2;
index_wake = 2;

% control activity: export cell of form 'genotype, mean, sem, n'

control_activity = {'Genotype', 'Mean', 'SEM', 'n'};
index_ctl = 2;

for i = 1:length(wakeResults)
    
    control_activity{index_ctl,1} = wakeResults{i}.genotype;
    control_activity{index_ctl,2} = mean(wakeResults{i}.controlActivity);
    control_activity{index_ctl,3} = stderr(wakeResults{i}.controlActivity);
    control_activity{index_ctl,4} = length(wakeResults{i}.controlActivity);
    
    index_ctl = index_ctl + 1;
    
    for j = 1:length(wakeResults{i}.sleepActivity)
        activity_sleep{index_sleep,1} = wakeResults{i}.genotype;
        activity_sleep{index_sleep,2} = wakeResults{i}.sleepActivity(j,1);
        activity_sleep{index_sleep,3} = wakeResults{i}.sleepActivity(j,2);
        index_sleep = index_sleep + 1;
    end
    
    for k = 1:length(wakeResults{i}.wakeActivity)
        activity_wake{index_wake,1} = wakeResults{i}.genotype;
        activity_wake{index_wake,2} = wakeResults{i}.wakeActivity(k,1);
        activity_wake{index_wake,3} = wakeResults{i}.wakeActivity(k,2);
        index_wake = index_wake + 1;
    end
    
end
    
cell2csv([fullfile(root_dir, save_path), '/activity_wake.csv'], activity_wake);
cell2csv([fullfile(root_dir, save_path), '/activity_sleep.csv'], activity_sleep);
cell2csv([fullfile(root_dir, save_path), '/activity_control.csv'], control_activity);



%% Analyze

%{
% Find intensity values used
intensity_vals = unique(wakeResults{1}.wakeResults(:,2));


for i = 1:length(wakeResults)
    
    wakeResults{i}.analyzed = {};
    
    for j = length(intensity_vals)
        wakeResults.analyzed{i} = struct;
        wakeResults.analyzed{i}.intensity = intensity_vals(j);
        
        ixs = find(
%}
