classdef outflow_Set2Tidy < SignalFlowSuperClass
% Description: A class for processing EEG data and organizing it in a tidy format.
% ShortTitle: SET to Tidy
% Category: Export
% Tags: Export
%   This class inherits from SignalFlowSuperClass and provides
%   functionality to process EEG data and store it in a tidy table.
%   It accepts three inputs: EEG data, an optional options structure,
%   and an optional guiMode boolean.
%
%% Syntax:
%   obj = outflow_Set2Tidy(varargin)
%
%% Function Specific Inputs:
%   'char_OutputFormat' - Charachter array containing the format Tidy Table will be stored in
%                  default: 'parquet'
%
%   'char_Suffix' - Charachter array
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
        function obj = outflow_Set2Tidy(varargin)

            % Define Custom Flow Function
            setup.flabel = 'SET to Tidy';
            setup.flowMode = 'outflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function sfOutput = run(obj)
            % run() - Process the EEG data.
            EEG = obj.beginEEG;
            % Signal Processing Code Below
            
            args.char_OutputDir = obj.fileIoVar;
            args.char_OutputFormat = 'parquet';
            args.char_Suffix = '';
            
            eeg_htpTidyData(EEG, 'OutputFormat', args.char_OutputFormat,'OutputDir', args.char_OutputDir,'Suffix', args.char_Suffix)

            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end

    end
end
