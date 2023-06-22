%Find which tasks exist for each participant
%Lydia 1/18/2023
cd(rawdata_location)
folder_list=dir([rawdata_location filesep '*_bids']); %finds everything in data location
folder_list={folder_list.name}; %list of just the names of each folder
folder_list=folder_list(~ismember(folder_list,{'.', '..', '.DS_Store'})); %also have . and .. directories that need to be removed

 
for i= 1:length(datafile_names)
          exist_tasks = [];

  bids_folder=folder_list{i}; % Dataset ID to be analysed
  subject = bids_folder(1:9);  
  subject_tasks=[subject '_taskscompleted.mat'];
  if ~exist([[output_location filesep 'Task_completed' filesep] subject_tasks])
      tasks = dir([rawdata_location filesep bids_folder filesep ['sub-' subject] filesep 'ses-V03' filesep 'eeg' filesep '*.set']);
      tasks = {tasks.name};
      for t = 1:length(tasks)
        if contains(tasks(t), 'MMN')
            tt = 'MMN';
        elseif contains(tasks(t), 'RS')
            tt = 'RS';
        elseif contains(tasks(t), 'VEP')
            tt = 'VEP';
        elseif contains(tasks(t), 'FACE')
            tt = 'FACE';
        end
        exist_tasks{t} = tt;
      end
      save([[output_location filesep 'Task_completed' filesep] subject_tasks],'exist_tasks');

  end
end

