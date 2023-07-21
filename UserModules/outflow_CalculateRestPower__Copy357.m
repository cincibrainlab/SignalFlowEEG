classdef outflow_CalculateRestPower__Copy357 < SignalFlowSuperClass
    methods
        function obj = outflow_CalculateRestPower__Copy357(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Calculate Rest Power';
            setup.flowMode = 'outflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function sfOutput = run(obj)
            % run() - Process the EEG data.           
            EEG = obj.beginEEG;
            % Signal Processing Code Below

            args.num_gpuOn = 0;
            args.num_duration = 60;
            args.num_offset = 0;
            args.num_window = 2;
            args.char_outputdir = obj.fileIoVar;
            args.bandDefs = {'delta', 1, 4; 'theta', 4, 10; 'alpha', 10,13;
                            'beta', 13, 30; 'gamma1', 30, 55;
                            'gamma2', 65, 100};
            args.log_useParquet = false;

            [EEG,results] = eeg_htpCalcRestPower(EEG, 'gpuOn',args.num_gpuOn,'duration',args.num_duration,...
                'offset',args.num_offset,'window',args.num_window,'outputdir', args.char_outputdir,'bandDefs',args.bandDefs,'useParquet',args.log_useParquet);

            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end

