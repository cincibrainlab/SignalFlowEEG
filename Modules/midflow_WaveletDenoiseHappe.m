classdef midflow_WaveletDenoiseHappe < SignalFlowSuperClass
    methods
        function obj = midflow_WaveletDenoiseHappe(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Wavelet Denoise';
            setup.flowMode = 'midflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function sfOutput = run(obj)
            % run() - Process the EEG data.           
            EEG = obj.beginEEG;
            % Signal Processing Code Below
       
            args.log_isErp = true;% Default is false
            args.num_wavLvl = [];
            args.char_wavelet = 'bior6.8'; % 'coif4' update with HAPPEv3;
            args.char_DenoisingMethod = "Bayes";
            args.char_ThresholdRule = '';
            args.char_NoiseEstimate = 'LevelDependent';
            args.num_highpass = 30;
            args.num_lowpass = .5;
            args.log_filtOn = true;

            [EEG,args.results] = eeg_htpEegWaveletDenoiseHappe(EEG, 'isErp', args.log_isErp);
            
            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end