% This script was automatically generated

% External dependencies locations
%eeglab_sfPlugin.mat
addpath('/srv/Analysis/Nate_Projects/eeglab2022');

%vhtp_sfPlugin.mat
addpath(genpath('/srv/Analysis/Nate_Projects/Github/vhtp'));

% Open EEG Lab
eeglab nogui

% Project Information
obj.proj.last_message = '<font color="black"><br>2023/05/12 17:59:39 | Module Refresh: Base 30 | User 0 | Pipeline 3</font><font color="black"><br>2023/05/12 17:59:39 | Success: added outflow_ExportSet (U5LVLI) to Pipeline Builder.</font><font color="black"><br>2023/05/12 17:59:39 | Module Refresh: Base 30 | User 0 | Pipeline 3</font><font color="black"><br>2023/05/12 17:59:36 | Module Refresh: Base 30 | User 0 | Pipeline 2</font><font color="black"><br>2023/05/12 17:59:36 | Success: added midflow_LowpassFilter (LKPKV5) to Pipeline Builder.</font><font color="black"><br>2023/05/12 17:59:36 | Module Refresh: Base 30 | User 0 | Pipeline 2</font><font color="black"><br>2023/05/12 17:59:33 | Module Refresh: Base 30 | User 0 | Pipeline 1</font><font color="black"><br>2023/05/12 17:59:33 | Success: added inflow_ImportSet (H5V682) to Pipeline Builder.</font><font color="black"><br>2023/05/12 17:59:33 | Module Refresh: Base 30 | User 0 | Pipeline 1</font><font color="black"><br>2023/05/12 17:59:22 | Module Refresh: Base 30 | User 0 | Pipeline 0</font><font color="black"><br>2023/05/12 17:59:22 | Scanning available Base and User Modules.</font><font color="red"><br><strong>2023/05/12 17:59:22 * Fail: </strong></font><font color="black">/srv/Analysis/Nate_Projects/Github/SignalFlow_Modules_Dev/UserModules folder not found. Check SignalFlow Paths</font><font color="green"><br><strong>2023/05/12 17:59:22 | Pass: </strong></font><font color="black">Modules folder present with 30 files.</font><font color="blue"><br><strong>2023/05/12 17:59:21 | Find and Load Available FlowFunction Modules</strong></font><font color="green"><br><strong>2023/05/12 17:59:21 | Pass: </strong></font><font color="black">SignalFlow Folder: /srv/Analysis/Nate_Projects/Github/SignalFlow_Modules_Dev</font><font color="blue"><br><strong>2023/05/12 17:59:21 | SignalFlow Version 23.1</strong></font>';
obj.proj.name = 'SignalFlowHBCDExample';
obj.proj.desc = 'Example SignalFLowEEG modules for HBCD';
obj.proj.author = 'Nathan Suer';
obj.proj.path_import = '/srv/Analysis/Nate_Projects/Test_Happe_HBCD_Input';
obj.proj.path_temp = '/srv/Analysis/Nate_Projects/';
obj.proj.path_results = '/srv/Analysis/Nate_Projects/Test_Happe_HBCD_Output/';

% Module Information
obj.module.Modules = {'inflow_HappeMergeSet','midflow_hbcd','midflow_HBCDMADEEpoching','outflow_ExportSet'};

%Add Modules to workflow
obj.module.TargetModuleArray = AddModules(obj.module.Modules);
% Set file locations for import and output (inflow and outflow)
obj.module.TargetModuleArray{1,1}.fileIoVar = obj.proj.path_import;
obj.module.TargetModuleArray{1,4}.fileIoVar = obj.proj.path_results;

% Run Workflow
EEG = obj.module.TargetModuleArray{1}.run(); 
obj.module.TargetModuleArray{1}.endEEG = EEG;
obj.module.TargetModuleArray{2}.beginEEG = EEG;
EEG = obj.module.TargetModuleArray{2}.run();
obj.module.TargetModuleArray{2}.endEEG = EEG;
obj.module.TargetModuleArray{3}.beginEEG = EEG;
EEG = obj.module.TargetModuleArray{3}.run();
obj.module.TargetModuleArray{3}.endEEG = EEG;
obj.module.TargetModuleArray{4}.beginEEG = EEG;
EEG = obj.module.TargetModuleArray{4}.run();
obj.module.TargetModuleArray{4}.endEEG = EEG;


% Required Functions to run Modules
function Workflow = AddModules(ModuleCellArray)
    Workflow = cell(1, 0);
    for i = 1:numel(ModuleCellArray)
        module_to_be_added =  feval(ModuleCellArray{i});
        Workflow{end + 1} = module_to_be_added;
    end
end

function singleFileExecute(obj,importFile)
    % This function is responsible for executing a single file based on the input file's
    % extension, and running the pipeline defined by the TargetModuleArray.

    % Extract the file extension from the given input file.
    [~, ~, fileExtension] = fileparts(importFile);
    % Define an array of valid file extensions that the function can process.
    validExtensions = {'.set', '.raw', '.edf'};
    % Check if the file extension of the input file is within the valid extensions.
    if ismember(fileExtension, validExtensions)
        % Set the input file path for the first TargetModule.
        obj.module.TargetModuleArray{1}.fileIoVar = importFile;
        % Check if the input file exists and update the boolValidImportFile flag.
        boolValidImportFile = exist(obj.module.TargetModuleArray{1}.fileIoVar, 'file') == 2;               
        % If both the input file and output directory are valid, execute the pipeline.
        if boolValidImportFile
            % Run the first TargetModule.
            EEG = obj.module.TargetModuleArray{1}.run(); 
            obj.module.TargetModuleArray{1}.endEEG = EEG;
            if ~isempty(EEG)
                % Iterate through the rest of the TargetModuleArray and execute each module.
                for i = 2:length(obj.module.TargetModuleArray)
                    if strcmp(obj.module.TargetModuleArray{i}.flowMode,'outflow') && isempty(obj.module.TargetModuleArray{i}.fileIoVar)
                        labelStruct = obj.Project_GetFolderLabels;
                        % Find the index of the 'path_results' label in the labelStruct array.
                        pathResults = strcmp({labelStruct.tag}, 'path_results');
                        % Set the output directory of the last TargetModule to the folder corresponding to the 'path_results' label.
                        if ~ismissing(labelStruct(pathResults).folder)
                            obj.module.TargetModuleArray{i}.fileIoVar = labelStruct(pathResults).folder;
                        end 
                    end
                    obj.module.TargetModuleArray{i}.beginEEG = EEG;
                    EEG = obj.module.TargetModuleArray{i}.run();
                    obj.module.TargetModuleArray{i}.endEEG = EEG;
                end
            end
        end        
    end
end