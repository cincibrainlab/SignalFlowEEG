classdef outflow_Adjust < SignalFlowSuperClass
    methods
        function obj = outflow_Adjust(varargin)          
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
                
            %% STEP 10: Run adjust to find artifacted ICA components
            badICs=[]; 
            EEG_copy = EEG;
            EEG_copy =eeg_regepochs(EEG_copy,'recurrence', 1, 'limits',[0 1], 'rmbase', [NaN], 'eventtype', '999'); % insert temporary marker 1 second apart and create epochs
            EEG_copy = eeg_checkset(EEG_copy);
            
            if size(EEG_copy.icaweights,1) == size(EEG_copy.icaweights,2)
                if args.save_interim_result==1
                    badICs = adjusted_ADJUST(EEG_copy, [[args.output_location filesep 'ica_data' filesep] ['testTODOFIX' '_adjust_report']]);
                else
                    badICs = adjusted_ADJUST(EEG_copy, [[args.output_location filesep 'processed_data' filesep] [args.datafile_names '_adjust_report']]);
                end
                close all;
            else % if rank is less than the number of electrodes, throw a warning message
                warning('The rank is less than the number of electrodes. ADJUST will be skipped. Artefacted ICs will have to be manually rejected for this participant');
            end
            
            % Mark the bad ICs found by ADJUST
            for ic=1:length(badICs)
                EEG.reject.gcompreject(1, badICs(ic))=1;
                EEG = eeg_checkset(EEG);
            end
            args.total_ICs=size(EEG.icasphere, 1);
            if numel(badICs)==0
                args.ICs_removed='0';
            else
                args.ICs_removed=num2str(double(badICs));
            end
            
            % Save dataset after ICA, if saving interim results was preferred
            EEG = eeg_checkset(EEG);
            EEG = pop_editset(EEG, 'setname',  [subject '_ica_data']);
            EEG = pop_saveset(EEG, 'filename', ['sub-' subject '_ses-V03_task-ALL_acq-eeg_eeg_ica_data.set'],'filepath', [args.output_location filesep 'ica_data' filesep ]); % save .set format
            
            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end

