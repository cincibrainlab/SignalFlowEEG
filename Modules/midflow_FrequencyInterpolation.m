classdef midflow_FrequencyInterpolation < SignalFlowSuperClass
% Description: Perform Frequency Interpolation on data
% ShortTitle: Frequency Interpolation EEG 
% Category: Preprocessing
% Tags: Filter
%
%% Syntax:
%   obj = midflow_FrequencyInterpolation(varargin)
%
%% Function Specific Inputs:
%   'num_targetfrequency' - Number indicating target frequency used for window in 
%                       filtering and interpolation calculations
%                       default: 60
%   
%   'num_halfmargin' - Number indicating width of neighbouring frequencies used
%                  in spectrum interpolation
%                  default: 2
% 
%% Disclaimer:
%  This file is part of the Cincinnati Childrens Brain Lab SignalFlowEEG Pipeline
%  
%  Please see http://github.com/cincibrainlab
%
%% Contact:
%  https://github.com/cincibrainlab/SignalFlowEEG/issues
    methods
        function obj = midflow_FrequencyInterpolation(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Frequency Interpolation EEG';
            setup.flowMode = 'midflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function sfOutput = run(obj)
            % run() - Process the EEG data.           
            EEG = obj.beginEEG;
            % Signal Processing Code Below

            args.num_targetfrequency = 60;
            args.num_halfmargin = 2;

            [EEG,args.results] = eeg_htpEegFrequencyInterpolation(EEG,'targetfrequency', args.num_targetfrequency, 'halfmargin', args.num_halfmargin);
            
            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end

