function flies = readMonitor2(fly, expData, root_dir)
% Given metadata about a particular experiment and a specified fly, parses
% data from that night to isolate the channels containing the genotype of
% interest and throws out any dead flies.

%% Read in data files

flies = importdata([fullfile(root_dir,'Monitors','Monitor'),...
        num2str(fly.Monitor),'.txt']);

% Trim down file to days and times of interest
date_indices = [];

for i = 1:length(expData.date_strings)
    
    date_indices = [date_indices; find(strcmp(flies.textdata(:,2),expData.date_strings{i}))];
    
end

flies.data = flies.data(date_indices,:);
flies.textdata = flies.textdata(date_indices,:);

nightON = '20:30:00';
nightOFF = '07:59:00';

nightON_index = find(strcmp(flies.textdata(:,3),nightON)...
    & strcmp(flies.textdata(:,2),expData.date_strings{1}));
nightOFF_index = find(strcmp(flies.textdata(:,3),nightOFF)...
    & strcmp(flies.textdata(:,2),expData.date_strings{2}));

flies.data = flies.data(nightON_index:nightOFF_index,:);
flies.textdata = flies.textdata(nightON_index:nightOFF_index,:);

% Trim down to channels of interest
channels = str2num(fly.Channels);

flies.data = flies.data(:,end-31:end);
    
flies.data = flies.data(:,channels);


%% Throw out dead flies

% Option #1: automatically filter out dead flies based on some pre-defined
% criteria (Hypnos: no activity over 24 hrs; alternatively, can go for no
% activity after midnight on the last night or whatever else you want)

% deadIndices = [];
%
% for i=1:length(flies.data(1,:))
%     if(flies.data(1921:end,i)==0) %for midnight to end, use 1921:end
%         deadIndices = [deadIndices i];
%     end
% end

% Option #2:
% Enter additional flies to throw out (numbers relative to the channels
% actually included in this particular genotype)

% deadFlies = input('Enter channel numbers of additional flies to discard: ', 's');
% deadFlies = str2num(deadFlies);
% 
% deadIndices = [deadIndices deadFlies];

% Option #3: Read in dead flies from the metadata file (entered manually
% based on looking at the actograms)

dead_flies = str2num(fly.dead_flies);
deadIndices = zeros(1, length(dead_flies));

for i = 1:length(dead_flies)
    deadIndices(i) = find(channels==dead_flies(i));
end

flies.data(:,deadIndices) = [];


