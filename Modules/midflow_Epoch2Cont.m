classdef midflow_Epoch2Cont < SignalFlowSuperClass
% Description: Converts epoched to continous data.
% ShortTitle: Epoched to continuous data
% Category: Preprocessing
% Tags: Epoching
%
%% Syntax:
%   obj = midflow_Epoch2Cont(varargin)
%
%% Function Specific Inputs:
%
%% Disclaimer:
%  This file is part of the Cincinnati Childrens Brain Lab SignalFlowEEG Pipeline
%  
%  Please see http://github.com/cincibrainlab
%
%% Contact:
%  https://github.com/cincibrainlab/SignalFlowEEG/issues
    methods
        function obj = midflow_Epoch2Cont(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Epoched to continuous data';
            setup.flowMode = 'midflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function EEG = run(obj)
            % run() - Process the EEG data.           
            EEG = obj.beginEEG;
            % Signal Processing Code Below

            if length(size(EEG.data)) > 2
                % starting dimensions
                [nchans, npnts, ntrial] = size(EEG.data);
                EEG.data = double(reshape(EEG.data, nchans, npnts * ntrial));
                EEG.pnts = npnts * ntrial;
                EEG.times = 1:1 / EEG.srate:(size(EEG.data, 2) / EEG.srate) * 1000;
            else
                warning('Data is likely already continuous.')
                fprintf('No trial dimension present in data');
            end
        
            EEG = eeg_checkset(EEG);
            EEG.data = double(EEG.data);
            args.completed = true;
            
            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            EEG = obj.HistoryTable(EEG, args);
        end
    end
end

