classdef midflow_hbcd < SignalFlowSuperClass
    methods
        function obj = midflow_hbcd(varargin)          
            % Define Custom Flow Function
            setup.flabel = 'Hbcd';
            setup.flowMode = 'midflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function sfOutput = run(obj)
            % run() - Process the EEG data.           
            EEG = obj.beginEEG;
            % Signal Processing Code Below

%             channel_locations = 'D:\HBCD_pilots\run_made_locally\sample_locs\GSN129.sfp';
%             
%             % 4. Do your data need correction for anti-aliasing filter and/or task related time offset?
%             adjust_time_offset = 0; % 0 = NO (no correction), 1 = YES (correct time offset)
%             % If your data need correction for time offset, initialize the offset time (in milliseconds)
%             filter_timeoffset = 0;     % anti-aliasing time offset (in milliseconds). 0 = No time offset
%             stimulus_timeoffset   = 0; % stimulus related time offset (in milliseconds). 0 = No time offset
%             response_timeoffset = 0;    % response related time offset (in milliseconds). 0 = No time offset
%             stimulus_markers = {'0', '0'};      % enter the stimulus makers that need to be adjusted for time offset
%             respose_markers = {'0', '0'};       % enter the response makers that need to be adjusted for time offset
            
%             % 6. Do you want to delete the outer layer of the channels? (Rationale has been described in MADE manuscript)
%             %    This fnction can also be used to down sample electrodes. For example, if EEG was recorded with 128 channels but you would
%             %    like to analyse only 64 channels, you can assign the list of channnels to be excluded in the 'outerlayer_channel' variable.    
%             delete_outerlayer = 1; % 0 = NO (do not delete outer layer), 1 = YES (delete outerlayer);
%             % If you want to delete outer layer, make a list of channels to be deleted
%             outerlayer_channel = {'E17' 'E38' 'E43' 'E44' 'E48' 'E49' 'E113' 'E114' 'E119' 'E120' 'E121' 'E125' 'E126' 'E127' 'E128' 'E56' 'E63' 'E68' 'E73' 'E81' 'E88' 'E94' 'E99' 'E107'}; % list of channels
%             % recommended list for EGI 128 chanenl net: {'E17' 'E38' 'E43' 'E44' 'E48' 'E49' 'E113' 'E114' 'E119' 'E120' 'E121' 'E125' 'E126' 'E127' 'E128' 'E56' 'E63' 'E68' 'E73' 'E81' 'E88' 'E94' 'E99' 'E107'}
%             
%             % 7. Initialize the filters
%             highpass = .3; % High-pass frequency
%             lowpass  = 50; % Low-pass frequency. We recommend low-pass filter at/below line noise frequency (see manuscript for detail)
%             
%             % 10. Do you want to remove/correct baseline?
%             %remove_baseline = 1; % 0 = NO (no baseline correction), 1 = YES (baseline correction)
%             %baseline_window = [-100  0]; % baseline period in milliseconds (MS) [] = entire epoch
%             
%             % 11. Do you want to remove artifact laden epoch based on voltage threshold?
%             voltthres_rejection = 1; % 0 = NO, 1 = YES
%             volt_threshold = [-150 150]; % lower and upper threshold (in mV) 
%             
%             % 12. Do you want to perform epoch level channel interpolation for artifact laden epoch? (see manuscript for detail)
%             interp_epoch = 1; % 0 = NO, 1 = YES.
%             frontal_channels = {'E1', 'E8', 'E14', 'E21', 'E25', 'E32', 'E17'}; % If you set interp_epoch = 1, enter the list of frontal channels to check (see manuscript for detail)
%             % recommended list for EGI 128 channel net: {'E1', 'E8', 'E14', 'E21', 'E25', 'E32', 'E17'}
%             
%             %13. Do you want to interpolate the bad channels that were removed from data?
%             interp_channels = 1; % 0 = NO (Do not interpolate), 1 = YES (interpolate missing channels)
%             
%             % 14. Do you want to rereference your data?
%             rerefer_data = 1; % 0 = NO, 1 = YES
%             reref = [];
%              % Enter electrode name/s or number/s to be used for rereferencing
%             % For channel name/s enter, reref = {'channel_name', 'channel_name'};
%             % For channel number/s enter, reref = [channel_number, channel_number];
%             % For average rereference enter, reref = []; default is average rereference
            
            % 15. Do you want to save interim results?
            save_interim_result = 1; % 0 = NO (Do not save) 1 = YES (save interim results)
            
            % 16. How do you want to save your data? .set or .mat
            output_format = 1; % 1 = .set (EEGLAB data structure), 2 = .mat (Matlab data structure)
            
            
            %% Initialize output variables
            args.ica_preparation_bad_channels=[]; % number of bad channel/s due to channel/s exceeding xx% of artifacted epochs
            args.length_ica_data=[]; % length of data (in second) fed into ICA decomposition
            args.total_ICs=[]; % total independent components (ICs)
            args.ICs_removed=[]; % number of artifacted ICs
            args.total_epochs_before_artifact_rejection=[];
            args.total_epochs_after_artifact_rejection=[];
            args.total_channels_interpolated=[]; % total_channels_interpolated=faster_bad_channels+ica_preparation_bad_channels
            
            %subject=1;
%             [filepath,name,ext] = fileparts(char(EEG.filename));
%             file = EEG.setname;
%             subject = file(5:13);
%             if ~(exist([  filesep 'ica_data' filesep 'sub-' subject '_ses-V03_ica_data.set'],'file') > 0) && ~contains(skip_ICA, subject)
%                 fprintf('\n\n\n*** Processing subject %d (%s) ***\n\n\n', s, datafile_names{s});
                
            %% STEP 1: Load the filtered data
            %EEG=mff_import([rawdata_location filesep datafile_names{subject}]);
            
            
%                 EEG = pop_loadset('filename',[datafile_names{s} ],'filepath',[output_location filesep 'filtered_data' filesep]);
            EEG = eeg_checkset(EEG);
            
            %% STEP 8: Prepare data for ICA
%                 EEG_copy=[];
            EEG_copy=EEG; % make a copy of the dataset
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
            chanCounter = 1; ica_prep_badChans = [];
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
%                 warning(['No usable data for datafile', datafile_names{s}]);
%                 if output_format==1
%                     EEG = eeg_checkset(EEG);
%                     EEG = pop_editset(EEG, 'setname',  [datafile_names{s} '_no_usable_data_all_bad_channels']);
%                     EEG = pop_saveset(EEG, 'filename', [datafile_names{s} '_no_usable_data_all_bad_channels.set'],'filepath', [output_location filesep 'processed_data' filesep ]); % save .set format
%                 elseif output_format==2
%                     save([[output_location filesep 'processed_data' filesep ] strrep(datafile_names{s}, ext, '_no_usable_data_all_bad_channels.mat')], 'EEG'); % save .mat format
%                 end
                
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
            
            %% STEP 9: Run ICA
            args.length_ica_data=EEG_copy.trials; % length of data (in second) fed into ICA
            EEG_copy = eeg_checkset(EEG_copy);
            EEG_copy = pop_runica(EEG_copy, 'icatype', 'runica', 'extended', 1, 'stop', 1E-7, 'interupt','off');
            
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
            
%                 events = EEG.event;
            
            
            %% STEP 10: Run adjust to find artifacted ICA components
            badICs=[]; 
%                 EEG_copy =[];
            EEG_copy = EEG;
            EEG_copy =eeg_regepochs(EEG_copy,'recurrence', 1, 'limits',[0 1], 'rmbase', [NaN], 'eventtype', '999'); % insert temporary marker 1 second apart and create epochs
            EEG_copy = eeg_checkset(EEG_copy);
            
            if size(EEG_copy.icaweights,1) == size(EEG_copy.icaweights,2)
%                 if save_interim_result==1
%                     badICs = adjusted_ADJUST(EEG_copy, [[output_location filesep 'ica_data' filesep] [datafile_names{s} '_adjust_report']]);
%                 else
%                     badICs = adjusted_ADJUST(EEG_copy, [[output_location filesep 'processed_data' filesep] [datafile_names{s} '_adjust_report']]);
%                 end
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
%             EEG = eeg_checkset(EEG);
%             EEG = pop_editset(EEG, 'setname',  [subject '_ica_data']);
%             EEG = pop_saveset(EEG, 'filename', ['sub-' subject '_ses-V03_task-ALL_acq-eeg_eeg_ica_data.set'],'filepath', [output_location filesep 'ica_data' filesep ]); % save .set format
            
            
            
                    %% STEP 11: Remove artifacted ICA components from data
%                 all_bad_ICs=0;
            ICs2remove=find(EEG.reject.gcompreject); % find ICs to remove
            
            
            EEG = eeg_checkset( EEG );
            EEG = pop_subcomp( EEG, ICs2remove, 0); % remove ICs from dataset
            
            
%             EEG = eeg_checkset(EEG);
%             EEG = pop_editset(EEG, 'setname',  [subject '_adjust_data']);
%             EEG = pop_saveset(EEG, 'filename', ['sub-' subject '_ses-V03_task-ALL_acq-eeg_eeg_adjust.set'],'filepath', [output_location filesep 'adjust' filesep ]); % save .set format
            
        
        
            %% Run Epoching and Artifact Rejection
            %cd('Z:\HBCD\Piloting\Data\Preprocessing\Scripts'); 
%             HBCD_MADE_Epoching();
            

            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end

