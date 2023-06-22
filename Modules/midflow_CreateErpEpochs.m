classdef midflow_CreateErpEpochs < SignalFlowSuperClass
% Description: Perform epoch creation for ERP datasets
% Category: Preprocessing
% ShortTitle: Create ERP epoch (EEGLAB)
% Tags: Epoching
%
%% Syntax:
%   obj = midflow_CreateErpEpochs(varargin)
%
%% Function Specific Inputs:
%   'char_epochevent' - 
%                   default: missing
%
%   'num_epochlimits' - array of two integers representing interval in secs relative to the time-locking event 
%                   default: [-.5 2.750]
%
%   'log_rmbaseline' - Boolean indicating if baseline should be removed
%                  default: false
%
%   'num_baselinelimits' - Array of numbers indicating limits in secs to use for baseline removal process.
%                      default: [-.5 0]
%
%% Disclaimer:
%  This file is part of the Cincinnati Childrens Brain Lab SignalFlowEEG Pipeline
%  
%  Please see http://github.com/cincibrainlab
%
%% Contact:
%  https://github.com/cincibrainlab/SignalFlowEEG/issues
    methods
        function obj = midflow_CreateErpEpochs(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Create ERP epoch';
            setup.flowMode = 'midflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function sfOutput = run(obj)
            % run() - Process the EEG data.           
            EEG = obj.beginEEG;
            % Signal Processing Code Below

            args.char_epochevent = missing;
            args.num_epochlimits = [-.500 2.750];
            args.log_rmbaseline = false;
            args.num_baselinelimits = [-.5 0];

            EEG = eeg_htpEegCreateErpEpochsEeglab(EEG,'epochlimits', args.num_epochlimits, 'rmbaseline', args.log_rmbaseline,...
                'baselinelimits',args.num_baselinelimits);
            
            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end

