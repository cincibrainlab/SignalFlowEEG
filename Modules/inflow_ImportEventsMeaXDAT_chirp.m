classdef inflow_ImportEventsMeaXDAT_assr < SignalFlowSuperClass
%% Disclaimer:
%  This file is part of the Cincinnati Childrens Brain Lab SignalFlowEEG Pipeline
%  
%  Please see http://github.com/cincibrainlab
%
%% Contact:
%  https://github.com/cincibrainlab/SignalFlowEEG/issues
    methods
        function obj = inflow_ImportEventsMeaXDAT_assr(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Import Events MEA XDAT File Assr';
            setup.flowMode = 'inflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function EEG = run(obj, varargin)
            args.char_filepath = char_filepath;
            
            
            args.char_netType = 'MEAXDAT';
            
            % Get the folder path, file name, and file extension
            [folderPath, ~, fileExtension] = fileparts(args.char_filepath);        
            % Add the folder path to the search path
            addpath(folderPath);
            % Load the file using pop_loadset if it has a .set extension
            if strcmp(fileExtension, '.xdat')
                EEG = util_allegoXDatEvents_chirp(args.char_filepath);
                %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
                EEG = obj.HistoryTable(EEG, args);
            else
                EEG = [];
            end
            [args.QADataPost] = util_GetQAData(EEG);
            EEG = obj.HistoryTable(EEG, args);
        end
    end
end