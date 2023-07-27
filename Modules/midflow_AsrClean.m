classdef midflow_AsrClean < SignalFlowSuperClass
% Description: Perform ASR cleaning via the clean_rawdata plugin provided through the EEGLAB interface
% ShortTitle: Artifact Subspace Reconstruction
% Category: Preprocessing
% Tags: Artifact
%
%% Syntax:
%   obj = midflow_AsrClean(varargin)
%
%% Function Specific Inputs:
%   'num_asrmode'   - Integer indicating type of ASR cleaning performed
%                 Modes:
%                   1: flatline channel rejection, IIR highpass filter, correlation with reconstructed channel rejection, line-noise channel rejection
%                   
%                       Mode 1 will negate 'asrburst' and 'asrwindow' parameters
%
%                   2: ASR burst reparation, window rejection
%
%                       Mode 2 will negate 'asrflatline', 'asrhighpass', 'asrchannel', and 'asrnoisy' parameters
%
%                   3: flatline channel rejection, IIR highpass filter, correlation with reconstructed channel rejection, line-noise channel rejection, ASR burst reparation, window rejection
%
%                   4: ASR burst reparation, window rejection
%
%                       Mode 4 will negate 'asrflatline', 'asrhighpass', 'asrchannel', and 'asrnoisy' parameters
%
%                   5: Custom
%                 
%                 default: 2
%                 
%   'num_asrflatline' - Integer representing the seconds of the max flatline duration. Longer flatline is abnormal.
%                    default: 5
%
%   'num_asrhighpass' - Array of numbers indicating the transition band in Hz for the high-pass filter.  
%                   default: [0.25 0.75]
%
%   'num_asrchannel' - Number indicating the minimum channel correlation. Channels correlated to reconstructed channel at a value less than parameter is abnormal.  Needs accurate channel locations.  
%                  default: 0.85
%
%   'num_asrnoisy' - Integer indicating the number of stdevs, based on channels, used to determine if channel has certain higher line noise to signal ratio to be considered abnormal.
%                default: 4
%
%   'num_asrburst' - Integer indicating stdev cutoff for burst removal. Lower the value the more conservative the removal.         
%                default: 20
%
%   'num_asrwindow' - Number indicating the max fraction of dirty channels accepted in output for each window. 
%                 default: 0.25
%
%   'num_asrmaxmem' - Number 
%                 default: 64
%
%% Disclaimer:
%  This file is part of the Cincinnati Childrens Brain Lab SignalFlowEEG Pipeline
%  
%  Please see http://github.com/cincibrainlab
%
%% Contact:
%  https://github.com/cincibrainlab/SignalFlowEEG/issues
    methods
        function obj = midflow_AsrClean(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Artifact Subspace Reconstruction';
            setup.flowMode = 'midflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});

        end

        function sfOutput = run(obj)
            % run() - Process the EEG data.           
            EEG = obj.beginEEG;
            [args.QADataPre] = util_GetQAData(EEG);
            % Signal Processing Code Below

            args.num_asrmode = 2;             
            args.num_asrflatline = 5;         
            args.num_asrhighpass = [0.25 0.75];   
            args.num_asrchannel = 0.85;         
            args.num_asrnoisy = 4;           
            args.num_asrburst = 20;           
            args.num_asrwindow = 0.25;        
            args.num_asrmaxmem = 64;           

            [EEG,args.results] = eeg_htpEegAsrCleanEeglab(EEG,'asrmode', args.num_asrmode, 'asrflatline', args.num_asrflatline,...
                'asrhighpass',args.num_asrhighpass, 'asrchannel', args.num_asrchannel, 'asrnoisy', args.num_asrnoisy,...
                'asrburst', args.num_asrburst, 'asrwindow', args.num_asrwindow, 'asrmaxmem', args.num_asrmaxmem);
            
            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            [args.QADataPost] = util_GetQAData(EEG);
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end

