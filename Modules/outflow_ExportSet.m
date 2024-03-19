classdef outflow_ExportSet < SignalFlowSuperClass
% Description: Export data to .set file
% ShortTitle: Export Set
% Category: Export
% Tags: Export
%
%% Syntax:
%   obj = outflow_ExportSet(varargin)
%
%% Function Specific Inputs:
%   'char_filepath' - Charachter array containing the directory in which files will be imported from
%                  default: char(pwd)
%
%   'char_stepName' - Charachter array containing the name of the step
%                  default: ''
%
%% Disclaimer:
%  This file is part of the Cincinnati Childrens Brain Lab SignalFlowEEG Pipeline
%  
%  Please see http://github.com/cincibrainlab
%
%% Contact:
%  https://github.com/cincibrainlab/SignalFlowEEG/issues
    methods
        function obj = outflow_ExportSet(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Export Set';
            setup.flowMode = 'outflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function sfOutput = run(obj, varargin)
            % run() - Process the EEG data.
            EEG = obj.beginEEG;
            [args.QADataPre] = util_GetQAData(EEG);
            % Signal Processing Code Below

            % Gets Default Parameter if User parameter is invalid or empty 
            args.char_filepath = obj.fileIoVar;
            
            % Change this if you want a custom file name
            [~,name,ext]= fileparts(EEG.filename);
            args.char_filename = ''; % change this if you would like a suffix (args.char_filename = '_suffix';)
            EEG.filename = [name, args.char_filename,ext];

            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            [args.QADataPost] = util_GetQAData(EEG);
            EEG = obj.HistoryTable(EEG, args);

            pop_saveset(EEG,'filename', EEG.filename, 'filepath', args.char_filepath);
            sfOutput = EEG;
        end
    end
end

