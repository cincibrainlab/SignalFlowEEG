classdef inflow_ImportSet < SignalFlowSuperClass
% Description: Import data from .set file
% ShortTitle: Import SET
% Category: Import
% Tags: Import
%
%% Syntax:
%   obj = inflow_ImportSet(varargin)
%
%% Function Specific Inputs:
%   'char_filepath' - Charachter array containing the directory in which files will be imported from
%                  default: char(pwd)
%
%% Disclaimer:
%  This file is part of the Cincinnati Childrens Brain Lab SignalFlowEEG Pipeline
%  
%  Please see http://github.com/cincibrainlab
%
%% Contact:
%  https://github.com/cincibrainlab/SignalFlowEEG/issues
    methods
        function obj = inflow_ImportSet(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Import SET';
            setup.flowMode = 'inflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function EEG = run(obj)
            % run() - Process the EEG data.         
            % Signal Processing Code Below

            % Gets Default Parameter if User parameter is invalid or empty 
            args.char_filepath = obj.fileIoVar;

            % Get the folder path, file name, and file extension
            [folderPath, ~, fileExtension] = fileparts(args.char_filepath);        
            % Add the folder path to the search path
            addpath(folderPath);
            % Load the file using pop_loadset if it has a .set extension
            if strcmp(fileExtension, '.set')
                EEG = pop_loadset(args.char_filepath);
            end
            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            EEG = obj.HistoryTable(EEG, args);
        end
    end
end
