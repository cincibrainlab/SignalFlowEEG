classdef midflow_BandpassFilter < SignalFlowSuperClass
% Description: Perform Bandpass filtering on data
% ShortTitle: Bandpass Filter EEG using EEGLAB
% Category: Preprocessing
% Tags: Filter
%
%% Syntax:
%   obj = midflow_BandpassFilter(varargin)
%
%% Function Specific Inputs:
%   'num_bandpassfilt' - Array of two numbers utilized for edges of bandpass filtering
%                    default: [2 80]
%
%   'log_revfilt' - logical boolean to invert filter from bandpass to notch
%               default: false e.g. {false -> bandpass, true -> notch}
%
%   'num_plotfreqz' - Numeric boolean to indicate whether to plot filter's frequency and phase response
%                 default: 0
%
%   'log_minphase' - Boolean for minimum-phase converted causal filter
%                default: false
%
%   'num_filtorder' - numeric override of default EEG filters
%                 default: 3300
%
%   'log_dynamicfiltorder' - numeric boolean indicating whether to use dynamic filtorder determined via EEGLAB filtering function
%                        default: 1
%
%% Disclaimer:
%  This file is part of the Cincinnati Childrens Brain Lab SignalFlowEEG Pipeline
%  
%  Please see http://github.com/cincibrainlab
%
%% Contact:
%  https://github.com/cincibrainlab/SignalFlowEEG/issues
    methods
        function obj = midflow_BandpassFilter(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Bandpass Filter';
            setup.flowMode = 'midflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function sfOutput = run(obj, varargin)
            % run() - Process the EEG data.           
            EEG = obj.beginEEG;
            [args.QADataPre] = util_GetQAData(EEG);
            % Signal Processing Code Below

            args.num_bandpassfilt = [2 80];
            args.log_revfilt = false;
            args.num_plotfreqz =  0;
            args.log_minphase = false;
            args.num_filtorder = 3300; % If args.log_dynamicfiltorder = true, this argument does nothing 
            args.log_dynamicfiltorder = true;

            [EEG,args.results] = eeg_htpEegBandpassFilterEeglab(EEG,'bandpassfilt', args.num_bandpassfilt, 'revfilt', args.log_revfilt,...
                'plotfreqz',args.num_plotfreqz, 'minphase', args.log_minphase, 'filtorder', args.num_filtorder, 'dynamicfiltorder', args.log_dynamicfiltorder );
            
            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            [args.QADataPost] = util_GetQAData(EEG);
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end

