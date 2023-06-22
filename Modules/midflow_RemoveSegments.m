classdef midflow_RemoveSegments < SignalFlowSuperClass
% Description: Select and reject atifactual regions in data
% ShortTitle: Visual continuous artifact removal
% Category: Preprocessing
% Tags: Artifact
%
%% Syntax:
%   obj = midflow_RemoveSegments(varargin)
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
        function obj = midflow_RemoveSegments(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Visual continuous artifact removal';
            setup.flowMode = 'midflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function sfOutput = run(obj)
            % run() - Process the EEG data.           
            EEG = obj.beginEEG;
            % Signal Processing Code Below

            [EEG,results] = eeg_htpEegRemoveSegmentsEeglab(EEG);
            args.proc_removed_regions = EEG.vhtp.eeg_htpEegRemoveSegmentsEeglab.proc_removed_regions;
            
            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end

