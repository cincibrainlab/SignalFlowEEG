classdef outflow_CalculateSource < SignalFlowSuperClass
    methods
        function obj = outflow_CalculateSource(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Calculate Source';
            setup.flowMode = 'outflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function sfOutput = run(obj, varargin)
            % run() - Process the EEG data.           
            EEG = obj.beginEEG;
            [args.QADataPre] = util_GetQAData(EEG);
            % Signal Processing Code Below

            args.char_outputdir = obj.fileIoVar;
            args.bandDefs = {'delta', 2, 3.5; 'theta', 3.5, 7.5; 'alpha1', 8, 10;
                            'alpha2', 10, 12; 'beta', 13, 30; 'gamma1', 30, 55;
                            'gamma2', 65, 80; 'epsilon', 81, 120; };
            args.log_headless = false;
            args.char_nettype = 'EGI128';
            args.log_confirmplot = false;
            args.log_saveset = true;
            args.log_computeheadmodel = false;
            args.char_headmodelfile = 'Empty';
            args.log_deletetempfiles = false;
            args.log_usepreexisting = false;
            args.log_resetprotocol = false;

            [EEG,args.results] = eeg_htpCalcSource(EEG, 'outputdir', args.char_outputdir,'bandDefs',args.bandDefs,'headless',args.log_headless,...
                'nettype',args.char_nettype,'confirmplot',args.log_confirmplot,'saveset',args.log_saveset,'computeheadmodel',args.log_computeheadmodel,...
                'headmodelfile',args.char_headmodelfile,'deletetempfiles',args.log_deletetempfiles,'usepreexisting',args.log_usepreexisting,'resetprotocol',args.log_resetprotocol);
            
            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            [args.QADataPost] = util_GetQAData(EEG);
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end

