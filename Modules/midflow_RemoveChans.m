classdef midflow_RemoveChans < SignalFlowSuperClass
% Description: Mark channels for rejection and interpolation
% ShortTitle: Reject Bad Channels
% Category: Preprocessing
% Tags: Channel
%
%% Syntax:
%   obj = midflow_RemoveChans(varargin)
%
%% Function Specific Inputs:
%   'log_trim'  - boolean to indicate whether to trim beginning and end of file for edge effects
%             default: false
%             
%             Removes first and last 10 secs of data
%
%   'num_minimumduration' - Number to indicate a minimum duration of data required for removal of channels and interpolation
%                       default: 100 secs
%
%   'num_threshold' - Number to utilize for threshold in automated detection/marking of bad channels via various measures (probability, kurtosis,and spectrum)
%                 default: 5
%
%   'log_removechannel' - true/false if channels should be removed after marking prior to next step.
%                      default: false
%    
%   'log_automark'      - turns on and off automatic detection 
%                      default: false
%
%% Disclaimer:
%  This file is part of the Cincinnati Childrens Brain Lab SignalFlowEEG Pipeline
%  
%  Please see http://github.com/cincibrainlab
%
%% Contact:
%  https://github.com/cincibrainlab/SignalFlowEEG/issues
    methods
        function obj = midflow_RemoveChans(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Reject Bad Channels';
            setup.flowMode = 'midflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function sfOutput = run(obj)
            % run() - Process the EEG data.           
            EEG = obj.beginEEG;
            % Signal Processing Code Below

            args.log_trim = false;
            args.num_minimumduration = 10;
            args.num_threshold =  5;
            args.log_removechannel = false;
            args.log_automark = false;

            [EEG,results] = eeg_htpEegRemoveChansEeglab(EEG,'trim', args.log_trim, 'minimumduration', args.num_minimumduration,...
                'threshold',args.num_threshold, 'removechannel', args.log_removechannel, 'automark', args.log_automark);
            
            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end

