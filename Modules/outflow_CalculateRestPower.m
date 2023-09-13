classdef outflow_CalculateRestPower < SignalFlowSuperClass
    methods
        function obj = outflow_CalculateRestPower(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Calculate Rest Power';
            setup.flowMode = 'outflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function sfOutput = run(obj)
            % run() - Process the EEG data.           
            EEG = obj.beginEEG;
            [args.QADataPre] = util_GetQAData(EEG);
            % Signal Processing Code Below

            args.num_gpuOn = 0;
            args.num_duration = 60;
            args.num_offset = 0;
            args.num_window = 2; 
            args.bandDefs = {'delta', 2, 3.5; 'theta', 3.5, 7.5; 'alpha1', 8, 10;
                            'alpha2', 10.5, 12.5; 'beta', 13, 30; 'gamma1', 30, 55;
                            'gamma2', 65, 80; 'epsilon', 81, 120; };
            args.log_useParquet = false;
            
            if ~isempty(obj.fileIoVar) %Will be printed to output directory 
                args.char_outputdir = obj.fileIoVar;
                [EEG,args.results] = eeg_htpCalcRestPower(EEG, 'gpuOn',args.num_gpuOn,'duration',args.num_duration,...
                'offset',args.num_offset,'window',args.num_window,'outputdir', args.char_outputdir,'bandDefs',args.bandDefs,'useParquet',args.log_useParquet);
            else %Will be printed to input directory
                [EEG,args.results] = eeg_htpCalcRestPower(EEG, 'gpuOn',args.num_gpuOn,'duration',args.num_duration,...
                'offset',args.num_offset,'window',args.num_window,'bandDefs',args.bandDefs,'useParquet',args.log_useParquet);
            end
            
            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            [args.QADataPost] = util_GetQAData(EEG);
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end

