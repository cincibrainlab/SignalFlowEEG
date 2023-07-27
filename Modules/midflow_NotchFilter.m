classdef midflow_NotchFilter < SignalFlowSuperClass
% Description: Perform Notch filtering on data
% ShortTitle: Notch Filter EEG using EEGLAB
% Category: Preprocessing
% Tags: Filter
%
%% Syntax:
%   obj = midflow_NotchFilter(varargin)
%
%% Function Specific Inputs:
%   'char_method'  - Text representing method utilized for Filtering
%               default: 'highpass' e.g. {'highpass', 'lowpass', 'notch', 'cleanline'}
%
%   'num_notchfilt' - Array of two numbers utilized for generating the line noise
%             used in harmonics calculation for notch filtering
%             default: [55 65]
%
%   'log_revfilt' - Logical boolean to invert filter from bandpass to notch
%               default: true e.g. {false -> bandpass, true -> notch}
%
%   'num_plotfreqz' - Numeric boolean to indicate whether to plot filter's frequency and phase response
%                 default: 0
%
%   'log_minphase' - Boolean for minimum-phase converted causal filter
%                default: false
%
%   'num_filtorder' - numeric override of default EEG filters
%                 default: missing
%
%   'log_dynamicfiltorder' - numeric boolean indicating whether to use dynamic filtorder determined via EEGLAB filtering function
%                        default: 0
%   
%% Disclaimer:
%  This file is part of the Cincinnati Childrens Brain Lab SignalFlowEEG Pipeline
%  
%  Please see http://github.com/cincibrainlab
%
%% Contact:
%  https://github.com/cincibrainlab/SignalFlowEEG/issues
    methods
        function obj = midflow_NotchFilter(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Notch Filter';
            setup.flowMode = 'midflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function sfOutput = run(obj)
            % run() - Process the EEG data.           
            EEG = obj.beginEEG;
            % Signal Processing Code Below

            args.num_notchfilt = [55 65];
            args.log_revfilt = false;
            args.num_plotfreqz =  0;
            args.log_minphase = false;
            args.num_filtorder = 3300;
            args.log_dynamicfiltorder = false;

            [EEG,args.results] = eeg_htpEegNotchFilterEeglab(EEG,'notchfilt', args.num_notchfilt, 'revfilt', args.log_revfilt,...
                'plotfreqz',args.num_plotfreqz, 'minphase', args.log_minphase, 'filtorder', args.num_filtorder, 'dynamicfiltorder', args.log_dynamicfiltorder );
            
            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end

