classdef outflow_AutoSave < SignalFlowSuperClass
    methods 
         function obj = outflow_AutoSave(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Auto Save';
            setup.flowMode = 'outflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
         end

        function sfOutput = run(obj, varargin)
            % run() - Process the EEG data.

            % Get SIgnal Flow Control 
            % Still remove moduleArray and currentIndex from the super
            % class 

            % Just get previous module from varagerin 

            % with the single File Execute make a check if its the auto
            % save and only pass to that 

            % Parse inputs
            p = inputParser;
            addOptional(p, 'moduleArray', {}, @(x) iscell(x));
            addOptional(p, 'currentIndex', 0, @(x) isnumeric(x));
            parse(p, varargin{:});
            in = p.Results;
        
            obj.moduleArray = in.moduleArray;
            obj.currentIndex = in.currentIndex;
            EEG = obj.beginEEG;
            [args.QADataPre] = util_GetQAData(EEG);
            % Signal Processing Code Below
        
            % Gets Default Parameter if User parameter is invalid or empty 
            args.char_filepath = obj.fileIoVar;
        
            % Change this if you want a custom file name
            [~,name,ext]= fileparts(EEG.filename);
            args.char_filename = ''; % change this if you would like a suffix (args.char_filename = '_suffix';)
            EEG.filename = [name, args.char_filename,ext];
        
            % Get previous module's display name and index
            if ~isempty(obj.moduleArray) && obj.currentIndex > 1
                previousModule = obj.moduleArray{obj.currentIndex - 1};
                previousDisplayName = previousModule.displayName;
                previousIndex = obj.currentIndex - 1;
            else
                previousDisplayName = 'Unknown';
                previousIndex = 0;
            end
        
            % Create folder if not exists
            targetFolder = fullfile(obj.fileIoVar, sprintf('%d_%s', previousIndex, previousDisplayName));
            if ~exist(targetFolder, 'dir')
                mkdir(targetFolder);
            end
            
            args.char_filepath = targetFolder;

            %Parameters and run history are stored in EEG.etc.SignalFlow.History field in EEG structure
            [args.QADataPost] = util_GetQAData(EEG);
            EEG = obj.HistoryTable(EEG, args);
            
            if strcmp(previousDisplayName, "Calculate connectivity and graph")
                sourceFolder = fullfile(previousModule.fileIoVar, 'eeg_htpGraphPhaseBcm');
                if exist(sourceFolder, 'dir')
                    destinationFolder = fullfile(targetFolder, 'eeg_htpGraphPhaseBcm');
                    if ~exist(destinationFolder, 'dir')
                        mkdir(destinationFolder);
                    end
                    copyfile(sourceFolder, destinationFolder);
                else
                    warning('Source folder does not exist.');
                end
            elseif strcmp(previousDisplayName, "Calculate Rest Power")
                sourceFolder = fullfile(previousModule.fileIoVar, 'eeg_htpCalcRestPower');
                if exist(sourceFolder, 'dir')
                    destinationFolder = fullfile(targetFolder, 'eeg_htpCalcRestPower');
                    if ~exist(destinationFolder, 'dir')
                        mkdir(destinationFolder);
                    end
                    copyfile(sourceFolder, destinationFolder);
                else
                    warning('Source folder does not exist.');
                end
            elseif strcmp(previousDisplayName, "Calculate Source")
                sourceFolder = fullfile(previousModule.fileIoVar, 'eeg_htpCalcSource');
                if exist(sourceFolder, 'dir')
                    destinationFolder = fullfile(targetFolder, 'eeg_htpCalcSource');
                    if ~exist(destinationFolder, 'dir')
                        mkdir(destinationFolder);
                    end
                    copyfile(sourceFolder, destinationFolder);
                else
                    warning('Source folder does not exist.');
                end
            elseif strcmp(previousDisplayName, "SET to Excel")
                % Define source and destination paths
                sourceFile = fullfile(previousModule.fileIoVar, 'A00_ANALYSIS_study.xlsx');
                destinationFile = fullfile(targetFolder, 'A00_ANALYSIS_study.xlsx');
    
                % Check if source file exists
                if exist(sourceFile, 'file')
                    % Copy the file to the destination folder
                    copyfile(sourceFile, destinationFile);
                else
                    % Display a warning if the source file doesn't exist
                    warning('Source file "%s" does not exist.', sourceFile);
                end 
            elseif strcmp(previousDisplayName, "SET to Tidy")
                sourceFolder = fullfile(previousModule.fileIoVar, 'tidy_results');
                if exist(sourceFolder, 'dir')
                    destinationFolder = fullfile(targetFolder, 'tidy_results');
                    if ~exist(destinationFolder, 'dir')
                        mkdir(destinationFolder);
                    end
                    copyfile(sourceFolder, destinationFolder);
                else
                    warning('Source folder does not exist.');
                end
            else
                % Save EEG data
                saveFilename = fullfile(EEG.filename);
                pop_saveset(EEG,'filename', saveFilename, 'filepath', args.char_filepath);
                
            end

            sfOutput = EEG;
        end

    end
end