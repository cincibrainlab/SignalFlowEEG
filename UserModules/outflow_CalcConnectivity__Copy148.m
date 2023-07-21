classdef outflow_CalcConnectivity__Copy148 < SignalFlowSuperClass
    methods
        function obj = outflow_CalcConnectivity__Copy148(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Gamma Only';
            setup.flowMode = 'outflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function sfOutput = run(obj)
            % run() - Process the EEG data.           
            EEG = obj.beginEEG;
            % Signal Processing Code Below

            args.num_gpuOn = 1;
            args.char_outputdir = obj.fileIoVar;
            args.bandDefs = {
                'gamma1', 30, 55;
                };

            [EEG,results] = eeg_htpGraphPhaseBcm(EEG, 'gpuOn',args.num_gpuOn, 'outputdir', args.char_outputdir,'bandDefs',args.bandDefs);

            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end

