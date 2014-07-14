% This file enables batch processing monitor files and organize data based
% on genotypes.

%% Initiation

% Label batch processing and read the batch processing parameter file 
master_mode=1;
[filename_master, pathname] = uigetfile('C:\Users\Stephen Zhang\Documents\MATLAB\*.xlsx'); % This address should be changed according to the user

%% Processing the parameter files
% Load the parameter file in to RAM
master_direction=importdata(fullfile(pathname,filename_master));

% Read the start and end dates from the parameter file
start_date=master_direction.textdata{1,1};
end_date=master_direction.textdata{2,1};

% Find the unique genotypes
genos=master_direction.textdata(:,2);
genos(1:2)='';
genos=unique(genos,'stable');

% Determine the number of unique genotypes
n_genos=size(genos,1);

% Construct the master data file (in the structure form)
master_data_struct=struct('genotype','','data',[],'sleep',[],'sleep_bout_lengths',[],'sleep_bout_numbers',[],'activities',[]);
master_data_struct(1:n_genos,1)=master_data_struct;

% Label the genotypes on the master data strcuture
for i=1:n_genos
    master_data_struct(i).genotype=genos{i};
end

% Determine how many lines to read from the parameter file. Each genotype
% can be read multiple times if appear multiple times in the parameter
% file.
master_lines_to_read=size(master_direction.textdata,1);

%% Processing the monitor files
% Initiate the waitbar
h = waitbar(3/master_lines_to_read,'Processing');

% Read from the 3rd line (the first two lines are dedicated to initiation and end dates)
ii=3;
while ii<master_lines_to_read
    % Determine which line of the parameter file to read
    current_line_to_read=ii-2;
    
    % Adjust the waitbar progress
    waitbar(ii/master_lines_to_read,h,['Processing: ', current_monitor_name]);
    
    % Obtain the monitor name
    current_monitor_name=master_direction.textdata{ii,1};
    filename=[current_monitor_name,'.txt'];
       
    % Determine the number of genoypes to read from the current monitor
    % file
    n_genos_of_current_monitor=sum(strcmp(master_direction.textdata(:,1),current_monitor_name));
    
    % Use the actogram2 code to read the monitor
    actogram2pc_batch;
    
    % Determine which line to read next from the next monitor file
    ii=ii+n_genos_of_current_monitor;
end
close(h)

%% Output files
% Prime the the cell to write data in
master_output_cell=cell(n_genos+1,12);
master_output_cell(1,:)={'geno','# loaded','# alive','total sleep','day sleep',...
    'night sleep','day bout length','night bout length','day bout number',...
    'night bout number','day activity','night activity'};

for ii=1:n_genos
    % First column shows the genotypes
    master_output_cell{ii+1,1}=genos{ii};
    
    % Second column shows how many flies loaded
    master_output_cell{ii+1,2}=master_direction.data(ii);
    
    % Third column shows how many flies remained alive at the end
    master_output_cell{ii+1,3}=master_direction.data(ii);
    
    % Forth column shows average total sleep per genotype
    master_output_cell{ii+1,4}=mean(master_data_struct(ii).sleep(:,1))+mean(master_data_struct(ii).sleep(:,2));
    
    % Fifth column shows average day-time sleep per genotype
    master_output_cell{ii+1,5}=mean(master_data_struct(ii).sleep(:,1));
    
    % Sixth column shows average night-time sleep per genotype
    master_output_cell{ii+1,6}=mean(master_data_struct(ii).sleep(:,2));
    
    % Seventh column shows average day-time sleep bout length per genotype
    master_output_cell{ii+1,7}=mean(master_data_struct(ii).sleep_bout_lengths(:,1));
    
    % Eighth column shows average night-time sleep bout length per genotype
    master_output_cell{ii+1,8}=mean(master_data_struct(ii).sleep_bout_lengths(:,2));
    
    % Ninth column shows average day-time sleep bout number per genotype
    master_output_cell{ii+1,9}=mean(master_data_struct(ii).sleep_bout_numbers(:,1));
    
    % Tenth column shows average night-time sleep bout number per genotype
    master_output_cell{ii+1,10}=mean(master_data_struct(ii).sleep_bout_numbers(:,2));
    
    % Eleventh column shows average day-time activity per genotype
    master_output_cell{ii+1,11}=mean(master_data_struct(ii).activities(:,1));
    
    % Twelfth column shows average night-time activity per genotype
    master_output_cell{ii+1,12}=mean(master_data_struct(ii).activities(:,2));
end


% Write the cell data
cell2csv(fullfile(export_path,[filename_master(1:end-5),'_output.csv']),master_output_cell);

% Save the work space
save(fullfile(export_path,[filename_master(1:end-5),'_workspace.mat']));

% Save the actograms
for ii=1:n_genos
    actogramprint( master_data_struct(ii).data, time_bounds, mat_bounds , n_days, export_path, [filename_master(1:end-5),'_',genos{ii}], [monitor_data.textdata{1,2}, ' ',genos{ii}])
end
