classdef midflow_ResampleData < SignalFlowSuperClass
% Description: Resamples data to newly specified sampling rate
% ShortTitle: Resample EEG data
% Category: Preprocessing
% Tags: Resample
%
%% Syntax:
%   obj = midflow_ResampleData(varargin)
%
%% Function Specific Inputs
%   'num_srate'     - Number specifying new sampling rate
%                     default: 500
%
%% Disclaimer:
%  This file is part of the Cincinnati Childrens Brain Lab SignalFlowEEG Pipeline
%  
%  Please see http://github.com/cincibrainlab
%
%% Contact:
%  https://github.com/cincibrainlab/SignalFlowEEG/issues
    methods
        function obj = midflow_ResampleData(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Resample EEG data';
            setup.flowMode = 'midflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function sfOutput = run(obj)
            % run() - Process the EEG data.           
            EEG = obj.beginEEG;
            % Signal Processing Code Below

            args.num_srate = 500;

            [EEG,args.results] = eeg_htpEegResampleDataEeglab(EEG,'srate', args.num_srate);
            
            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end

