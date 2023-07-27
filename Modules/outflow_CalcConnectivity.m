classdef outflow_CalcConnectivity < SignalFlowSuperClass
    methods
        function obj = outflow_CalcConnectivity(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Calculate connectivity and graph';
            setup.flowMode = 'outflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function sfOutput = run(obj)
            % run() - Process the EEG data.           
            EEG = obj.beginEEG;
            [args.QADataPre] = util_GetQAData(EEG);
            % Signal Processing Code Below

            args.num_gpuOn = 1;
            args.char_outputdir = obj.fileIoVar;
            args.bandDefs = {
                'delta', 2 , 3.5;
                'theta', 3.5, 7.5;
                'alpha1', 8, 10;
                'alpha2', 10.5, 12.5;
                'beta', 13, 30;
                'gamma1', 30, 55;
                'gamma2', 65, 90;
                };

            [EEG,args.results] = eeg_htpGraphPhaseBcm(EEG, 'gpuOn',args.num_gpuOn, 'outputdir', args.char_outputdir,'bandDefs',args.bandDefs);

            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            [args.QADataPost] = util_GetQAData(EEG);
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end

