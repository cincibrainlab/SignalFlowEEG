classdef midflow_CreateEpochs_1Second < SignalFlowSuperClass
% Description: Perform epoch creation for Non-ERP datasets
% ShortTitle: Create Regular Epochs (EEGLAB)
% Category: Preprocessing
% Tags: Epoching
%
%% Syntax:
%   obj = midflow_CreateEpochs__Copy287(varargin)
%
%% Function Specific Inputs:
%   'num_epochlength'  - Integer representing the recurrence interval in seconds of epochs
%               default: 2
%
%   'num_epochlimits' - array of two integers representing latencies interval in seconds relative to the time-locking events 
%               default: [0 epochlength]
%
%% Disclaimer:
%  This file is part of the Cincinnati Childrens Brain Lab SignalFlowEEG Pipeline
%  
%  Please see http://github.com/cincibrainlab
%
%% Contact:
%  https://github.com/cincibrainlab/SignalFlowEEG/issues
    methods
        function obj = midflow_CreateEpochs_1Second(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Create Regular Epochs 1 second';
            setup.flowMode = 'midflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function sfOutput = run(obj, varargin)
            % run() - Process the EEG data.           
            EEG = obj.beginEEG;
            [args.QADataPre] = util_GetQAData(EEG);
            % Signal Processing Code Below

            args.num_epochlength = 1;
            args.num_epochlimits = [0 args.num_epochlength];

            [EEG,args.results] = eeg_htpEegCreateEpochsEeglab(EEG,'epochlength', args.num_epochlength, 'epochlimits', args.num_epochlimits);
            
            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            [args.QADataPost] = util_GetQAData(EEG);
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end

