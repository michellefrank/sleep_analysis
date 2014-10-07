function envMonitor = readEnvMonitor(expData, root_dir)
% Given metadata from an experiment of interest, reads in the environmental
% monitor, throws out dates and times that aren't of interest, and returns
% the environmental monitor struct

%% Read in environmental monitor
% Imports the environmental monitor file based on the given root directory
% and date information from expData
    
envMonitor = importdata([fullfile(root_dir,'Monitors','Monitor'),...
    num2str(expData.envMonitor),'.txt']);

% Establish boundaries for defining night - allows us to search through
% just the night hours to find flashes of light without worrying about
% light being on during the day
nightON = '20:30:00'; %'20:30:00';
nightOFF = '07:59:00';

% Throw out parts of the environmental monitor that don't matter
date_indices = [];

for i = 1:length(expData.date_strings)
    
    date_indices = [date_indices; find(strcmp(envMonitor.textdata(:,2),expData.date_strings{i}))];
    
end

envMonitor.data = envMonitor.data(date_indices,:);
envMonitor.textdata = envMonitor.textdata(date_indices,:);

nightON_index = find(strcmp(envMonitor.textdata(:,3),nightON)...
    & strcmp(envMonitor.textdata(:,2),expData.date_strings{1}));
nightOFF_index = find(strcmp(envMonitor.textdata(:,3),nightOFF)...
    & strcmp(envMonitor.textdata(:,2),expData.date_strings{2}));

envMonitor.data = envMonitor.data(nightON_index:nightOFF_index,:);
envMonitor.textdata = envMonitor.textdata(nightON_index:nightOFF_index,:);

