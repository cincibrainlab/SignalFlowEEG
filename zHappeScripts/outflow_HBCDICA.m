classdef outflow_HBCDICA < SignalFlowSuperClass
    methods
        function obj = outflow_HBCDICA(varargin)          
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
%             args.char_method = 'runica';
            args.char_method = 'binica';
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

            %% STEP 8: Prepare data for ICA
            EEG_copy = EEG; % make a copy of the dataset
            EEG_copy = eeg_checkset(EEG_copy);
            
            % Perform 1Hz high pass filter on copied dataset
            transband = 1;
            fl_cutoff = transband/2;
            fl_order = 3.3 / (transband / EEG.srate);
            
            if mod(floor(fl_order),2) == 0
                fl_order=floor(fl_order);
            elseif mod(floor(fl_order),2) == 1
                fl_order=floor(fl_order)+1;
            end
            
            EEG_copy = pop_firws(EEG_copy, 'fcutoff', fl_cutoff, 'ftype', 'highpass', 'wtype', 'hamming', 'forder', fl_order, 'minphase', 0);
            EEG_copy = eeg_checkset(EEG_copy);
            
            % Create 1 second epoch
            EEG_copy=eeg_regepochs(EEG_copy,'recurrence', 1, 'limits',[0 1], 'rmbase', [NaN], 'eventtype', '999'); % insert temporary marker 1 second apart and create epochs
            EEG_copy = eeg_checkset(EEG_copy);
            
            % Find bad epochs and delete them from dataset
            vol_thrs = [-1000 1000]; % [lower upper] threshold limit(s) in mV.
            emg_thrs = [-100 30]; % [lower upper] threshold limit(s) in dB.
            emg_freqs_limit = [20 40]; % [lower upper] frequency limit(s) in Hz.
            
            % Find channel/s with xx% of artifacted 1-second epochs and delete them
            chanCounter = 1; 
            ica_prep_badChans = [];
            numEpochs =EEG_copy.trials; % find the number of epochs
            all_bad_channels=0;
            
            for ch=1:EEG_copy.nbchan
                % Find artifaceted epochs by detecting outlier voltage
                EEG_copy = pop_eegthresh(EEG_copy,1, ch, vol_thrs(1), vol_thrs(2), EEG_copy.xmin, EEG_copy.xmax, 0, 0);
                EEG_copy = eeg_checkset( EEG_copy );
                
                % 1         : data type (1: electrode, 0: component)
                % 0         : display with previously marked rejections? (0: no, 1: yes)
                % 0         : reject marked trials? (0: no (but store the  marks), 1:yes)
                
                % Find artifaceted epochs by using thresholding of frequencies in the data.
                % this method mainly rejects muscle movement (EMG) artifacts
                EEG_copy = pop_rejspec( EEG_copy, 1,'elecrange',ch ,'method','fft','threshold', emg_thrs, 'freqlimits', emg_freqs_limit, 'eegplotplotallrej', 0, 'eegplotreject', 0);
                
                % method                : method to compute spectrum (fft)
                % threshold             : [lower upper] threshold limit(s) in dB.
                % freqlimits            : [lower upper] frequency limit(s) in Hz.
                % eegplotplotallrej     : 0 = Do not superpose rejection marks on previous marks stored in the dataset.
                % eegplotreject         : 0 = Do not reject marked trials (but store the  marks).
                
                % Find number of artifacted epochs
                EEG_copy = eeg_checkset( EEG_copy );
                EEG_copy = eeg_rejsuperpose( EEG_copy, 1, 1, 1, 1, 1, 1, 1, 1);
                artifacted_epochs=EEG_copy.reject.rejglobal;
                
                % Find bad channel / channel with more than 20% artifacted epochs
                if sum(artifacted_epochs) > (numEpochs*20/100)
                    ica_prep_badChans(chanCounter) = ch;
                    chanCounter=chanCounter+1;
                end
            end
            
            % If all channels are bad, save the dataset at this stage and ignore the remaining of the preprocessing.
            if numel(ica_prep_badChans)==EEG.nbchan || numel(ica_prep_badChans)+1==EEG.nbchan
                all_bad_channels=1;
                warning(['No usable data for datafile', args.datafile_names]);
                if output_format==1
                    EEG = eeg_checkset(EEG);
                    EEG = pop_editset(EEG, 'setname',  [args.datafile_names '_no_usable_data_all_bad_channels']);
                    EEG = pop_saveset(EEG, 'filename', [args.datafile_names '_no_usable_data_all_bad_channels.set'],'filepath', [args.output_location filesep 'processed_data' filesep ]); % save .set format
                elseif output_format==2
                    save([[args.output_location filesep 'processed_data' filesep ] strrep(args.datafile_names, ext, '_no_usable_data_all_bad_channels.mat')], 'EEG'); % save .mat format
                end
                
            else
                % Reject bad channel - channel with more than xx% artifacted epochs
                EEG_copy = pop_select( EEG_copy,'nochannel', ica_prep_badChans);
                EEG_copy = eeg_checkset(EEG_copy);
            end
            
            if numel(ica_prep_badChans)==0
                args.ica_preparation_bad_channels='0';
            else
                args.ica_preparation_bad_channels=num2str(ica_prep_badChans);
            end
            
            if all_bad_channels == 1
                args.length_ica_data=0;
                args.total_ICs=0;
                args.ICs_removed='0';
                args.total_epochs_before_artifact_rejection=0;
                args.total_epochs_after_artifact_rejection=0;
                args.total_channels_interpolated=0;
                %continue % ignore rest of the processing and go to next datafile
            end
            
            % Find the artifacted epochs across all channels and reject them before doing ICA.
            EEG_copy = pop_eegthresh(EEG_copy,1, 1:EEG_copy.nbchan, vol_thrs(1), vol_thrs(2), EEG_copy.xmin, EEG_copy.xmax,0,0);
            EEG_copy = eeg_checkset(EEG_copy);
            
            % 1         : data type (1: electrode, 0: component)
            % 0         : display with previously marked rejections? (0: no, 1: yes)
            % 0         : reject marked trials? (0: no (but store the  marks), 1:yes)
            
            % Find artifaceted epochs by using power threshold in 20-40Hz frequency band.
            % This method mainly rejects muscle movement (EMG) artifacts.
            EEG_copy = pop_rejspec(EEG_copy, 1,'elecrange', 1:EEG_copy.nbchan, 'method', 'fft', 'threshold', emg_thrs ,'freqlimits', emg_freqs_limit, 'eegplotplotallrej', 0, 'eegplotreject', 0);
            
            
            %EEG_copy = pop_rejspec( EEG_copy, 1,'elecrange',ch ,'method','fft','threshold', emg_thrs, 'freqlimits', emg_freqs_limit, 'eegplotplotallrej', 0, 'eegplotreject', 0);
            
            % method                : method to compute spectrum (fft)
            % threshold             : [lower upper] threshold limit(s) in dB.
            % freqlimits            : [lower upper] frequency limit(s) in Hz.
            % eegplotplotallrej     : 0 = Do not superpose rejection marks on previous marks stored in the dataset.
            % eegplotreject         : 0 = Do not reject marked trials (but store the  marks).
            
            % Find the number of artifacted epochs and reject them
            EEG_copy = eeg_checkset(EEG_copy);
            EEG_copy = eeg_rejsuperpose(EEG_copy, 1, 1, 1, 1, 1, 1, 1, 1);
            reject_artifacted_epochs=EEG_copy.reject.rejglobal;
            EEG_copy = pop_rejepoch(EEG_copy, reject_artifacted_epochs, 0);

            EEG = EEG_copy;
                
            %% STEP 9: Run ICA
            args.length_ica_data=EEG_copy.trials; % length of data (in second) fed into ICA
            EEG_copy = eeg_checkset(EEG_copy);

%             EEG_copy = pop_runica(EEG_copy, 'icatype', 'runica', 'extended', 1, 'stop', 1E-7, 'interupt','off');
%             EEG_copy = eeg_htpEegIcaEeglab(EEG_copy,'method', args.char_method,'icadir','/srv/Analysis/Nate_Projects/Github/SignalFlow_Modules_Dev/zHappeScripts/icaweights');
            
            % Find the ICA weights that would be transferred to the original dataset
            ICA_WINV=EEG_copy.icawinv;  %LY: pretty sure this is the same as the "A" variable in HAPPE v1
            ICA_SPHERE=EEG_copy.icasphere;
            ICA_WEIGHTS=EEG_copy.icaweights;
            ICA_CHANSIND=EEG_copy.icachansind;
            
            % If channels were removed from copied dataset during preparation of ica, then remove
            % those channels from original dataset as well before transferring ica weights.
            EEG = eeg_checkset(EEG);
            EEG = pop_select(EEG,'nochannel', ica_prep_badChans);
            
            % Transfer the ICA weights of the copied dataset to the original dataset
            EEG.icawinv=ICA_WINV;
            EEG.icasphere=ICA_SPHERE;
            EEG.icaweights=ICA_WEIGHTS;
            EEG.icachansind=ICA_CHANSIND;
            EEG = eeg_checkset(EEG);
            
            args.events = EEG.event;
            
            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end

