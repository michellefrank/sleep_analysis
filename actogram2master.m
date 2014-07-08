% Green coming soon

master_mode=1;
[filename_master, pathname] = uigetfile('C:\Users\Stephen Zhang\Documents\MATLAB\*.xlsx');
master_direction=importdata(fullfile(pathname,filename_master));

start_date=master_direction.textdata{1,1};
end_date=master_direction.textdata{2,1};

genos=master_direction.textdata(:,2);
genos(1:2)='';
genos=unique(genos,'stable');

n_genos=size(genos,1);

master_data_struct=struct('genotype','','data',[],'sleep',[],'sleep_bout_lengths',[],'sleep_bout_numbers',[],'activities',[]);
master_data_struct(1:n_genos,1)=master_data_struct;

for i=1:n_genos
    master_data_struct(i).genotype=genos{i};
end

master_lines_to_read=size(master_direction.textdata,1);

h = waitbar(3/master_lines_to_read,'Processing');
ii=3;
while ii<master_lines_to_read
    current_line_to_read=ii-2;
    current_monitor_name=master_direction.textdata{ii,1};
    waitbar(ii/master_lines_to_read,h,['Processing: ', current_monitor_name]);
    filename=[current_monitor_name,'.txt'];
    n_genos_of_current_monitor=sum(strcmp(master_direction.textdata(:,1),current_monitor_name));
    actogram2pc_batch;
    ii=ii+n_genos_of_current_monitor;
end
close(h)

master_output_mat=zeros(n_genos,8);
for ii=1:n_genos
    master_output_mat(ii,1:2)=mean(master_data_struct(ii).sleep);
    master_output_mat(ii,3:4)=mean(master_data_struct(ii).sleep_bout_lengths);
    master_output_mat(ii,5:6)=mean(master_data_struct(ii).sleep_bout_numbers);
    master_output_mat(ii,7:8)=mean(master_data_struct(ii).activities);
end

xlswrite(fullfile(export_path,[filename_master(1:end-5),'_output.xls']),master_output_mat);

save(fullfile(export_path,[filename_master(1:end-5),'_workspace.mat']));
%%
for ii=1:n_genos
    actogramprint( master_data_struct(ii).data, time_bounds, mat_bounds , n_days, export_path, [filename_master(1:end-5),'_',genos{ii}], [monitor_data.textdata{1,2}, ' ',genos{ii}])
end
