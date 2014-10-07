% Given metadata from an experiment of interest, reads in the environmental
% monitor, throws out dates and times that aren't of interest, and returns
% the environmental monitor struct

%% Read in environmental monitor
% Imports the environmental monitor file based on the given root directory
% and date information from expData

[filename, pathname] = uigetfile('/Users/michelle/Documents/flies/light/Monitors/*.txt');

% Master data structure file, separated into textdata and data
envMon=importdata(fullfile(pathname,filename));

% Establish boundaries for defining night - allows us to search through
% just the night hours to find flashes of light without worrying about
% light being on during the day
start_time = '20:30:00';
end_time = '07:59:00';


% Select dates to include
start_date = input('Enter start date (e.g. 7 Apr 14): ', 's');
end_date = input('Enter final date (e.g. 10 Apr 14): ', 's');

start_idx = find(strcmp(envMon.textdata(:,2), start_date));
end_idx = find(strcmp(envMon.textdata(:,2), end_date));

date_indices = start_idx(1):end_idx(end);

% Delete the unwanted days
envMon.data = envMon.data(date_indices,:);
envMon.textdata = envMon.textdata(date_indices,:);


% Edit file to start at that point
start_index = find(strcmp(envMon.textdata(:,3),start_time)...
    & strcmp(envMon.textdata(:,2),start_date));
end_index = find(strcmp(envMon.textdata(:,3),end_time)...
    & strcmp(envMon.textdata(:,2),end_date));

envMon.data = envMon.data(start_index:end_index,:);
envMon.textdata = envMon.textdata(start_index:end_index,:);


%% Find places in envMon with lights on

% Extract light intensities from envMon
light_intensities = [];
light_intensities = envMon.data(:,9);
stim_indices = [];

%Search through environmental monitor for places where the light was on
stim_indices = find(light_intensities > 0);


% Extract dates and times of stimuli

stim_times = cell(length(stim_indices),2);

for i = 1:length(stim_indices)
    stim_times(i,1) = envMon.textdata(stim_indices(i),2);
    stim_times(i,2) = envMon.textdata(stim_indices(i),3);
end

%% Convert to form for Iris's program

month_dict = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};

%Split day info into components

for i = 1:length(stim_times)
    yr = stim_times{i,1}(end-1:end);
    month = stim_times{i,1}(end-5:end-3);
    day = stim_times{i,1}(1:end-7);
    
    yr = ['20',yr];
    month = find(strcmp(month_dict, month));
    month = ['0',num2str(month)];
    
    if length(day)==1
        day = ['0',day];
    end
    
    stim_times{i,1} = [month,'/',day,'/',yr];
    
end

%% Print data to a csv


fileID = fopen('stim_data.txt','w');
formatSpec = '%s %s\n';

for row = 1:length(stim_indices)
fprintf(fileID,formatSpec,stim_times{row,:});
end

fclose(fileID);