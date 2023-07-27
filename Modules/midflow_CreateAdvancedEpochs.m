classdef midflow_CreateAdvancedEpochs < SignalFlowSuperClass
    methods
        function obj = midflow_CreateAdvancedEpochs(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Create Advanced Epochs';
            setup.flowMode = 'midflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function sfOutput = run(obj)
            % run() - Process the EEG data.           
            EEG = obj.beginEEG;
            [args.QADataPre] = util_GetQAData(EEG);
            % Signal Processing Code Below

            rOccTemp = {'E83', 'E90', 'E96', 'E100', 'E89', 'E95', 'E99', 'E88', 'E94'};
            lOccTemp = {'E57', 'E58', 'E65', 'E70', 'E63', 'E64', 'E69', 'E68', 'E73'};
            
            args.char_mainTrigger = {'DIN3'};
            args.char_backupTrigger = {'ch1+', 'ch2+'};
            args.num_epochLength = [-.1 .4];
            args.num_baselineLength = [-100 0];
            args.char_rois = [rOccTemp lOccTemp];

            [EEG,args.results] = eeg_htpEegAdvancedEpochs(EEG, args.char_mainTrigger, args.char_backupTrigger,args.num_epochLength, args.num_baselineLength, args.char_rois);
            
            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            [args.QADataPost] = util_GetQAData(EEG);
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end

