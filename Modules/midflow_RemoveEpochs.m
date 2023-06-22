classdef midflow_RemoveEpochs < SignalFlowSuperClass
% Description: Perform manual epoch rejection
% ShortTitle: Visual epoch removal
% Category: Preprocessing
% Tags: Epoch
%
%% Syntax:
%   obj = midflow_RemoveEpochs(varargin)
%
%% Function Specific Inputs:
%   'num_limits' - 
%                   default: [EEG.xmin EEG.xmax]
%
%   'log_thresholdrejection' -
%                   default: false 
%
%   'num_threshold' - 
%                   default: 50 
%   'char_events' - 
%                   default: '' 
%
%% Disclaimer:
%  This file is part of the Cincinnati Childrens Brain Lab SignalFlowEEG Pipeline
%  
%  Please see http://github.com/cincibrainlab
%
%% Contact:
%  https://github.com/cincibrainlab/SignalFlowEEG/issues
    methods
        function obj = midflow_RemoveEpochs(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Visual epoch removal';
            setup.flowMode = 'midflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function sfOutput = run(obj)
            % run() - Process the EEG data.           
            EEG = obj.beginEEG;
            % Signal Processing Code Below

            args.num_limits = [EEG.xmin EEG.xmax];
            args.log_thresholdrejection = false;
            args.num_threshold =  50;
            args.char_events = {};

            [EEG,results] = eeg_htpEegRemoveEpochsEeglab(EEG,'limits', args.num_limits, 'thresholdrejection', args.log_thresholdrejection,...
                'threshold',args.num_threshold, 'events', args.char_events);
            
            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end

