classdef outflow_RemoveArtifactedICAcomponents < SignalFlowSuperClass
    methods
        function obj = outflow_RemoveArtifactedICAcomponents(varargin)          
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
                
                
            %% STEP 11: Remove artifacted ICA components from data
            args.all_bad_ICs=0;
            ICs2remove=find(EEG.reject.gcompreject); % find ICs to remove
            
            
            EEG = eeg_checkset( EEG );
            EEG = pop_subcomp( EEG, ICs2remove, 0); % remove ICs from dataset
            
            
            EEG = eeg_checkset(EEG);
            EEG = pop_editset(EEG, 'setname',  [subject '_adjust_data']);
            EEG = pop_saveset(EEG, 'filename', ['sub-' subject '_ses-V03_task-ALL_acq-eeg_eeg_adjust.set'],'filepath', [args.output_location filesep 'adjust' filesep ]); % save .set format
            
            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end

