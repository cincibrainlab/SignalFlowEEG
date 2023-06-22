classdef midflow_RemoveComps < SignalFlowSuperClass
% Description: Select and reject/keep components from data
% ShortTitle: Visual component removal
% Category: Preprocessing
% Tags: Artifact
%
%% Syntax:
%   obj = midflow_RemoveComps(varargin)
%
%% Function Specific Inputs:
%    'num_maxcomps'  - Number of maximum components to utilize in thresholding and plotting
%                  default: 24
%    
%    'char_dpreset'   - display size preset ('1080p')
%                  default: 'dynamic'
%    
%    'num_removeics' - bypass GUI and remove user specified components defined as vector of integers.
%                  default: []
%
%    'num_freqrange' - Array of two numbers utilized for the frequency range for extended detail about specific components when plotting activity
%                 default: [2 80]
%
%% Disclaimer:
%  This file is part of the Cincinnati Childrens Brain Lab SignalFlowEEG Pipeline
%  
%  Please see http://github.com/cincibrainlab
%
%% Contact:
%  https://github.com/cincibrainlab/SignalFlowEEG/issues
    methods
        function obj = midflow_RemoveComps(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Visual component removal';
            setup.flowMode = 'midflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function sfOutput = run(obj)
            % run() - Process the EEG data.           
            EEG = obj.beginEEG;
            % Signal Processing Code Below

            args.num_maxcomps = 24;
            args.char_dpreset = 'dynamic';
            args.num_removeics =  [];
            args.num_freqrange = [2 80];

            [EEG,results] = eeg_htpEegRemoveCompsEeglab(EEG,'maxcomps', args.num_maxcomps, 'dpreset', args.char_dpreset, 'freqrange', args.num_freqrange);
            
            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end

