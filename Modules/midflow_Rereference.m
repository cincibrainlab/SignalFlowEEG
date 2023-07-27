classdef midflow_Rereference < SignalFlowSuperClass
% Description: Rereference data to Average Reference.
% ShortTitle: Average reference EEG data
% Category: Preprocessing
% Tags: Channel
%
%% Syntax:
%   obj = midflow_Rereference(varargin)
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
        function obj = midflow_Rereference(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Average reference EEG data';
            setup.flowMode = 'midflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function sfOutput = run(obj)
            % run() - Process the EEG data.           
            EEG = obj.beginEEG;
            [args.QADataPre] = util_GetQAData(EEG);
            % Signal Processing Code Below

            [EEG,args.results] = eeg_htpEegRereferenceEeglab(EEG);
            args.method = 'Average';
            
            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            [args.QADataPost] = util_GetQAData(EEG);
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end

