classdef midflow_InterpolateChans < SignalFlowSuperClass
% Description: Interpolate channels utilizing specified method 
% ShortTitle: Channel Interpolation
% Category: Preprocessing
% Tags: Channel
%
%% Syntax:
%   obj = midflow_InterpolateChans(varargin)
%
%% Function Specific Inputs:
%   'char_method'  - Text representing method utilized for interpolation of channels
%               default: 'spherical' e.g. {'invdist'/'v4', 'spherical', 'spacetime'}
%   
%   'num_channels'  - Numeric list representing channels utilized 
%                 default: []
%
%% Disclaimer:
%  This file is part of the Cincinnati Childrens Brain Lab SignalFlowEEG Pipeline
%  
%  Please see http://github.com/cincibrainlab
%
%% Contact:
%  https://github.com/cincibrainlab/SignalFlowEEG/issues
    methods
        function obj = midflow_InterpolateChans(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Channel Interpolation';
            setup.flowMode = 'midflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function sfOutput = run(obj)
            % run() - Process the EEG data.           
            EEG = obj.beginEEG;
            % Signal Processing Code Below

            args.char_method = 'spherical';
            args.num_channels = [];

            [EEG,args.results] = eeg_htpEegInterpolateChansEeglab(EEG,'method', args.char_method, 'channels', args.num_channels);
            
            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end

