classdef outflow_PrepareDataForICA < SignalFlowSuperClass
    methods
        function obj = outflow_PrepareDataForICA(varargin)          
            % Define Custom Flow Function
            setup.flabel = 'Happe Reject Channels';
            setup.flowMode = 'outflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function sfOutput = run(obj)
            % run() - Process the EEG data.           
            EEG = obj.beginEEG;
            % Signal Processing Code Below
            args.output_location = obj.fileIoVar;
            %TODO fix this
            args.datafile_names=dir([args.output_location filesep 'filtered_data' filesep '*.set']);
            args.save_interim_result = 1;
            %TODO fix this
%             file = args.datafile_names;
            %TODO fix this
            subject = 'testSubject';
            %TODO fix this
%             if ~(exist([args.output_location filesep 'ica_data' filesep 'sub-' subject '_ses-V03_ica_data.set'],'file') > 0) && ~contains(skip_ICA, subject)
            %TODO fix this    
%             fprintf('\n\n\n*** Processing subject %d (%s) ***\n\n\n', s, args.datafile_names{s});
                
            
            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end

