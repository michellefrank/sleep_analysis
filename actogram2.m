% Generate actogram from .txt monitor data
% Written by Stephen Zhang 2014-5-14
% Will [probably] *definitely* be made better by Michelle Frank

% Problems to be solved
%
% 1. Aspect ratio of the final file (looks hideous now)
%
% 2. Way of choosing location to export pdfs

%% Import initial data
% Get the file and start the drama
[filename, pathname] = uigetfile('/Users/michelle/Documents/flies/light/Monitors/*.txt');

export_path = '/Users/michelle/Documents/flies/light/AnalyzedData';

% Master data structure file, separated into textdata and data
monitor_data=importdata(fullfile(pathname,filename));

%% Separate data into desired days/times

% Select dates to include
start_date = input('Enter start date (e.g. 7 Apr 14): ', 's');
end_date = input('Enter final date (e.g. 10 Apr 14): ', 's');

% Pare down monitor data to just those dates
start = str2double(start_date(1:2));
finish = str2double(end_date(1:2));
days = start:finish;
month_info = start_date(end-5:end);

% Create new cell containing the days of interest
date_strings = {};

for i = 1:length(days)
    
    date_strings{i} = [num2str(days(i)), ' ', month_info];
    
end

% Find those days in the monitor file
date_indices = [];

for i = 1:length(date_strings)
    
    date_indices = [date_indices; find(strcmp(monitor_data.textdata(:,2), date_strings{i}))];
    
end

% Delete the unwanted days
monitor_data.data = monitor_data.data(date_indices,:);
monitor_data.textdata = monitor_data.textdata(date_indices,:);

% Select start time
start_time = '08:00:00';%input('Enter start time: (e.g. 08:00:00): ', 's');
end_time = '07:59:00';

% Edit file to start at that point
start_index = find(strcmp(monitor_data.textdata(:,3),start_time)...
    & strcmp(monitor_data.textdata(:,2),date_strings{1}));
end_index = find(strcmp(monitor_data.textdata(:,3),end_time)...
    & strcmp(monitor_data.textdata(:,2),date_strings{end}));

monitor_data.data = monitor_data.data(start_index:end_index,:);
monitor_data.textdata = monitor_data.textdata(start_index:end_index,:);

%%
% Use two time points to determine whether the inter-recording inverval is 0.5 or 1 min
interval=round((datenum(monitor_data.textdata{20,3})-datenum(monitor_data.textdata{19,3}))/3.472222015261650e-04)/2;

% If there's no start time, use the first time point to determine what time of the day the trial
% started
first_time=(datenum(monitor_data.textdata{1,3})-735600)/6.9444e-04;
first_time_hr=first_time/60;

% Use the period to determine how many points should be binned
kitty_points_per_bin=round(5/interval);

% Obtain the actogram data
pared_data=monitor_data.data(:,end-31:end);

% Determine how many bins there will be
n_bins=ceil(size(pared_data,1)/kitty_points_per_bin);

% Determine how many points will be in the last bin
mod_bins=mod(size(pared_data,1),kitty_points_per_bin);
if mod_bins==0;
    mod_bins=kitty_points_per_bin;
end

% Prime the binned data matrix
oblonsky_binned_data=zeros(n_bins,32);

% Bin the data. Calculate the last bin separately
for i=1:n_bins-1
    oblonsky_binned_data(i,:)=sum(pared_data((i-1)*kitty_points_per_bin+1:i*kitty_points_per_bin,:));
end
oblonsky_binned_data(n_bins,:)=sum(pared_data((n_bins-1)*kitty_points_per_bin+1:(n_bins-1)*kitty_points_per_bin+mod_bins,:));

%% Separate data by days
% Determine how many bins will be on the first day
n_bins_first_day=round((1920-first_time)/kitty_points_per_bin/interval);

% Determine how many days there will be
n_days=ceil((n_bins-n_bins_first_day)/288)+1;

% Set the bounds, in terms of bins, for each day's data
mat_bounds=zeros(n_days,2);
mat_bounds(1,1)=1;
mat_bounds(1,2)=n_bins_first_day;
for i=2:n_days-1
    mat_bounds(i,1)=mat_bounds(i-1,2)+1;
    mat_bounds(i,2)=mat_bounds(i-1,2)+288;
end
mat_bounds(n_days,1)=mat_bounds(n_days-1,2)+1;
mat_bounds(n_days,2)=n_bins;

% Calculate the bounds, in terms of time stamps, for each day's data
time_bounds=zeros(n_days,2);
time_bounds(1,1)=first_time_hr;
time_bounds(1,2)=32;
time_bounds(2:end,1)=8;
time_bounds(2:end-1,2)=32;
time_bounds(end,2)=5/60+8+(mat_bounds(n_days,2)-mat_bounds(n_days,1))*5/60;

%% Plotting data
% The plot will be in 2 x 4 format
subplot_plan=[2,4];
% A placeholder variable for how many panels have been plotted
panels_done=0;

% k is the index number for pages
for k=1:4
    % Set figure size
    figure(101)
    set(gcf,'Position',[0 0 1000 691])
    
    % j is the index number for panels
    for j=1:8
        subplot(subplot_plan(1),subplot_plan(2),j);
        hold on
        
        % i is the index number for days
        for i=1:n_days
            bbar=bar(time_bounds(i,1):5/60:time_bounds(i,1)+(mat_bounds(i,2)-mat_bounds(i,1))*5/60,... % A weird way to determine what the actual x-values are for each point
                oblonsky_binned_data(mat_bounds(i,1):mat_bounds(i,2),j+panels_done)... % The actual y-values for each point
                /100/n_days+(n_days-i)/n_days); % Normalize against 100 and divide each panel into days
            line([8,32],[(n_days-i)/n_days,(n_days-i)/n_days],'Color',[0 0 0]); % This is a line per request of Michelle
            set(bbar,'EdgeColor',[0 128/255 128/255]) % Set the bar edge color to black. One vote for purple [153/255 102/255 204/255] from Stephen
            set(bbar,'FaceColor',[0 128/255 128/255]) % Set the bar face color to black. One vote for purple from Stephen 
            set(bbar,'BaseValue',(n_days-i)/n_days); % Elevate the bars to restrict them to their own little sub-panels
        end
        
        % Make the figure readable
        xlim([8,32]);
        ylim([0,1]);
        
        % Set X labels
        set(gca,'XTick',[8 12 16 20 24 28 32]);
        set(gca,'xticklabel',[8 12 16 20 24 4 8]);
        set(gca,'yticklabel',[]);
        
        % Draw a box and put on the titles
        box on
        title([monitor_data.textdata{1,2},' ',filename(1:end-4) ,' Channel ',num2str(j+panels_done)])
        hold off
    end
    
    % Make figures look tighter
    tightfig;
    
    % Resize the figures to fit on a piece of paper better (could be improved)
    set(gcf,'Position',[0 0 1400 1000],'Color',[1 1 1])
    
    % Export and append the pdf files (Does not work on mac. Sorry)
    export_fig(fullfile(export_path,[filename(1:end-4),'_actogram_', num2str(k), '.pdf']));
    close 101
    panels_done=panels_done+8;
end

%% Sleep data

% Binarize binned data so that one bin of no movement counts as 5 min of
% sleep
sleep_mat=oblonsky_binned_data==0;

% Calculate the sleep bounds
n_sleep_bounds=(n_days-2)*2;

% Keep the last day/night data for now
if mat_bounds(end,2)-mat_bounds(end,1)<=143
    n_sleep_bounds=n_sleep_bounds+1;
else
    n_sleep_bounds=n_sleep_bounds+2;
end

% Determine the sleep bounds
sleep_bounds=zeros(n_sleep_bounds,2);
sleep_bounds(1,1)=mat_bounds(2,1);
sleep_bounds(1,2)=sleep_bounds(1,1)+143;
for i=2:n_sleep_bounds
    sleep_bounds(i,1)=sleep_bounds(i-1,2)+1;
    sleep_bounds(i,2)=sleep_bounds(i,1)+143;
end
sleep_bounds(n_sleep_bounds,2)=n_bins;

% Determine whether Day 1 is a full day or not
if mat_bounds(1,2)-mat_bounds(1,1)==287
    % If full day, tell us and add day 1 to the sleep bounds
    disp('Keeping day 1 sleep data')
    sleep_bounds=[1,144;145,288;sleep_bounds];
    n_sleep_bounds=n_sleep_bounds+2;
else
    % If not full day, tell us and keep the sleep bounds as they are
    disp('Discarding day 1 sleep data')
end

% Calculate the sleep results accordingly
sleep_results=zeros(size(sleep_bounds,1),32);
for i=1:n_sleep_bounds
sleep_results(i,:)=(sum(sleep_mat(sleep_bounds(i,1):sleep_bounds(i,2),:)))*5;
end

% If the last day/night sleep data are incomplete, they are discarded.
if mat_bounds(end,2)-mat_bounds(end,1)~=143 && mat_bounds(end,2)-mat_bounds(end,1)~=287
    disp('Last day/night sleep data are not complete, thus discarded')
    sleep_results(n_sleep_bounds,:)=[];
    n_sleep_bounds=n_sleep_bounds-1;
    sleep_bounds(n_sleep_bounds,:)=[];
else
    disp('Keeping the last day/night sleep data')
end

% Comment something here so it looks green
sleep_results'

%% Sleep bout and activity calculations
% Green will be added later
sleep_bout_num=zeros(n_sleep_bounds,32);
sleep_bout_length=zeros(n_sleep_bounds,32);
activity_mat=zeros(n_sleep_bounds,32);

for i=1:32
    for j=1:n_sleep_bounds
        tempsleepvec=sleep_mat(sleep_bounds(j,1):sleep_bounds(j,2),i);
        tempactivityvec=oblonsky_binned_data(sleep_bounds(j,1):sleep_bounds(j,2),i);
        tempsleepchainmat=chainfinder(tempsleepvec);
        sleep_bout_num(j,i)=size(tempsleepchainmat,1);
        if ~isempty(tempsleepchainmat)
            sleep_bout_length(j,i)=mean(tempsleepchainmat(:,2))*5;
        else
            sleep_bout_length(j,i)=0;
        end
        activity_mat(j,i)=mean(tempactivityvec(tempsleepvec==0));
    end
end
disp('Sleep bout numbers:')
sleep_bout_num'

disp('Sleep bout lengths:')
sleep_bout_length'

disp('Activities')
activity_mat'