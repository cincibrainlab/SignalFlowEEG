% ************************************************************************
% The Maryland Analysis of Developmental EEG (UMADE) Pipeline
% Version 1.0
% Developed at the Child Development Lab, University of Maryland, College Park

% Contributors to MADE pipeline:
% Ranjan Debnath (rdebnath@umd.edu)
% George A. Buzzell (gbuzzell@umd.edu)
% Santiago Morales Pamplona (moraless@umd.edu)
% Stephanie Leach (sleach12@umd.edu)
% Maureen Elizabeth Bowers (mbowers1@umd.edu)
% Nathan A. Fox (fox@umd.edu)

% MADE uses EEGLAB toolbox and some of its plugins. Before running the pipeline, you have to install the following:
% EEGLab:  https://sccn.ucsd.edu/eeglab/downloadtoolbox.php/download.php

% You also need to download the following plugins/extensions from here: https://sccn.ucsd.edu/wiki/EEGLAB_Extensions
% Specifically, download:
% MFFMatlabIO: https://github.com/arnodelorme/mffmatlabio/blob/master/README.txt
% FASTER: https://sourceforge.net/projects/faster/
%  ADJUST:  https://www.nitrc.org/projects/adjust/ [Maybe we will replace this with our own GitHub link?]

% After downloading these plugins (as zip files), you need to place it in the eeglab/plugins folder.
% For instance, for FASTER, you uncompress the downloaded extension file (e.g., 'FASTER.zip') and place it in the main EEGLAB "plugins" sub-directory/sub-folder.
% After placing all the required plugins, add the EEGLAB folder to your path by using the following code:

% addpath(genpath(('...')) % Enter the path of the EEGLAB folder in this line

% Please cite the following references for in any manuscripts produced utilizing MADE pipeline:

% EEGLAB: A Delorme & S Makeig (2004) EEGLAB: an open source toolbox for
% analysis of single-trial EEG dynamics. Journal of Neuroscience Methods, 134, 9?21.

% firfilt (filter plugin): developed by Andreas Widmann (https://home.uni-leipzig.de/biocog/content/de/mitarbeiter/widmann/eeglab-plugins/)

% FASTER: Nolan, H., Whelan, R., Reilly, R.B., 2010. FASTER: Fully Automated Statistical
% Thresholding for EEG artifact Rejection. Journal of Neuroscience Methods, 192, 152?162.

% ADJUST: Mognon, A., Jovicich, J., Bruzzone, L., Buiatti, M., 2011. ADJUST: An automatic EEG
% artifact detector based on the joint use of spatial and temporal features. Psychophysiology, 48, 229?240.
% Our group has modified ADJUST plugin to improve selection of ICA components containing artifacts

% This pipeline is released under the GNU General Public License version 3.

% ************************************************************************

%% User input: user provide relevant information to be used for data processing
% Preprocessing of EEG data involves using some common parameters for
% every subject. This part of the script initializes the common parameters.

clear % clear matlab workspace
clc % clear matlab command window
%addpath('X:\Toolbox\eeglab13_6_5b');% enter the path of the EEGLAB folder in this line
addpath('D:\eeglab2021.1');

eeglab; close;
%addpath(genpath('C:\Users\Berger\Documents\eeglab13_4_4b'))

% 1. Enter the path of the folder that has the raw data to be analyzed
rawdata_location = 'D:\HBCD_pilots\run_made_locally\new_files';

% 2. Enter the path of the folder where you want to save the processed data
%output_location = 'Z:\HBCD\Piloting\Data\Preprocessing';
output_location = 'D:\HBCD_pilots\run_made_locally\new_files';

% 3. Enter the path of the channel location file
channel_locations = 'D:\HBCD_pilots\run_made_locally\sample_locs\GSN129.sfp';

% 4. Do your data need correction for anti-aliasing filter and/or task related time offset?
adjust_time_offset = 0; % 0 = NO (no correction), 1 = YES (correct time offset)
% If your data need correction for time offset, initialize the offset time (in milliseconds)
filter_timeoffset = 0;     % anti-aliasing time offset (in milliseconds). 0 = No time offset
stimulus_timeoffset   = 0; % stimulus related time offset (in milliseconds). 0 = No time offset
response_timeoffset = 0;    % response related time offset (in milliseconds). 0 = No time offset
stimulus_markers = {'0', '0'};      % enter the stimulus makers that need to be adjusted for time offset
respose_markers = {'0', '0'};       % enter the response makers that need to be adjusted for time offset

% 6. Do you want to delete the outer layer of the channels? (Rationale has been described in MADE manuscript)
%    This fnction can also be used to down sample electrodes. For example, if EEG was recorded with 128 channels but you would
%    like to analyse only 64 channels, you can assign the list of channnels to be excluded in the 'outerlayer_channel' variable.    
delete_outerlayer = 1; % 0 = NO (do not delete outer layer), 1 = YES (delete outerlayer);
% If you want to delete outer layer, make a list of channels to be deleted
outerlayer_channel = {'E17' 'E38' 'E43' 'E44' 'E48' 'E49' 'E113' 'E114' 'E119' 'E120' 'E121' 'E125' 'E126' 'E127' 'E128' 'E56' 'E63' 'E68' 'E73' 'E81' 'E88' 'E94' 'E99' 'E107'}; % list of channels
% recommended list for EGI 128 chanenl net: {'E17' 'E38' 'E43' 'E44' 'E48' 'E49' 'E113' 'E114' 'E119' 'E120' 'E121' 'E125' 'E126' 'E127' 'E128' 'E56' 'E63' 'E68' 'E73' 'E81' 'E88' 'E94' 'E99' 'E107'}

% 7. Initialize the filters
highpass = .3; % High-pass frequency
lowpass  = 50; % Low-pass frequency. We recommend low-pass filter at/below line noise frequency (see manuscript for detail)

% 10. Do you want to remove/correct baseline?
%remove_baseline = 1; % 0 = NO (no baseline correction), 1 = YES (baseline correction)
%baseline_window = [-100  0]; % baseline period in milliseconds (MS) [] = entire epoch

% 11. Do you want to remove artifact laden epoch based on voltage threshold?
voltthres_rejection = 1; % 0 = NO, 1 = YES
volt_threshold = [-150 150]; % lower and upper threshold (in mV) 

% 12. Do you want to perform epoch level channel interpolation for artifact laden epoch? (see manuscript for detail)
interp_epoch = 1; % 0 = NO, 1 = YES.
frontal_channels = {'E1', 'E8', 'E14', 'E21', 'E25', 'E32', 'E17'}; % If you set interp_epoch = 1, enter the list of frontal channels to check (see manuscript for detail)
% recommended list for EGI 128 channel net: {'E1', 'E8', 'E14', 'E21', 'E25', 'E32', 'E17'}

%13. Do you want to interpolate the bad channels that were removed from data?
interp_channels = 1; % 0 = NO (Do not interpolate), 1 = YES (interpolate missing channels)

% 14. Do you want to rereference your data?
rerefer_data = 1; % 0 = NO, 1 = YES
reref = [];
 % Enter electrode name/s or number/s to be used for rereferencing
% For channel name/s enter, reref = {'channel_name', 'channel_name'};
% For channel number/s enter, reref = [channel_number, channel_number];
% For average rereference enter, reref = []; default is average rereference

% 15. Do you want to save interim results?
save_interim_result = 1; % 0 = NO (Do not save) 1 = YES (save interim results)

% 16. How do you want to save your data? .set or .mat
output_format = 1; % 1 = .set (EEGLAB data structure), 2 = .mat (Matlab data structure)


%% Initialize output variables
reference_used_for_faster=[]; % reference channel used for running faster to identify bad channel/s
faster_bad_channels=[]; % number of bad channel/s identified by faster
ica_preparation_bad_channels=[]; % number of bad channel/s due to channel/s exceeding xx% of artifacted epochs
length_ica_data=[]; % length of data (in second) fed into ICA decomposition
total_ICs=[]; % total independent components (ICs)
ICs_removed=[]; % number of artifacted ICs
total_epochs_before_artifact_rejection=[];
total_epochs_after_artifact_rejection=[];
total_channels_interpolated=[]; % total_channels_interpolated=faster_bad_channels+ica_preparation_bad_channels


%% Import files if they are in MFF format
%    cd('Z:\HBCD\Piloting\Data\Preprocessing\Scripts');HBCD_import();
    
%% Remove outer channels, filter, merge files, then run faster to remove bad channels
%Files to SKIP filter faster merge:
% skip_FILT = {'PISTL0019' %bc MMN won't merge with other tasks
%     };

%Filter Faster
%cd('Z:\HBCD\Piloting\Data\Preprocessing\Scripts'); 
HBCD_merge_filter_faster();

    datafile_names=dir([output_location filesep 'filtered_data' filesep '*.set']);
    datafile_names=datafile_names(~ismember({datafile_names.name},{'.', '..', '.DS_Store', 'MADE errors out files', 'not_official_pilots', 'All_Epoched'}));
    datafile_names={datafile_names.name};
    [filepath,name,ext] = fileparts(char(datafile_names{1}));

%Files to SKIP ICA
% skip_ICA = {'PISTL0019'  %MMN not merging with other tasks, already processed
%     };
    
%% Loop over all data files
for s=1:length(datafile_names)
    %subject=1;
    EEG=[];
    file = datafile_names{s};
    subject = file(5:13);
    if ~(exist([output_location filesep 'ica_data' filesep 'sub-' subject '_ses-V03_ica_data.set'],'file') > 0) && ~contains(skip_ICA, subject)
        fprintf('\n\n\n*** Processing subject %d (%s) ***\n\n\n', s, datafile_names{s});
        
        %% STEP 1: Load the filtered data
        %EEG=mff_import([rawdata_location filesep datafile_names{subject}]);
        
        EEG = pop_loadset('filename',[datafile_names{s} ],'filepath',[output_location filesep 'filtered_data' filesep]);
        EEG = eeg_checkset(EEG);
        
        %% STEP 8: Prepare data for ICA
        EEG_copy=[];
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
            warning(['No usable data for datafile', datafile_names{s}]);
            if output_format==1
                EEG = eeg_checkset(EEG);
                EEG = pop_editset(EEG, 'setname',  [datafile_names{s} '_no_usable_data_all_bad_channels']);
                EEG = pop_saveset(EEG, 'filename', [datafile_names{s} '_no_usable_data_all_bad_channels.set'],'filepath', [output_location filesep 'processed_data' filesep ]); % save .set format
            elseif output_format==2
                save([[output_location filesep 'processed_data' filesep ] strrep(datafile_names{s}, ext, '_no_usable_data_all_bad_channels.mat')], 'EEG'); % save .mat format
            end
            
        else
            % Reject bad channel - channel with more than xx% artifacted epochs
            EEG_copy = pop_select( EEG_copy,'nochannel', ica_prep_badChans);
            EEG_copy = eeg_checkset(EEG_copy);
        end
        
        if numel(ica_prep_badChans)==0
            ica_preparation_bad_channels{s}='0';
        else
            ica_preparation_bad_channels{s}=num2str(ica_prep_badChans);
        end
        
        if all_bad_channels == 1
            length_ica_data(s)=0;
            total_ICs(s)=0;
            ICs_removed{s}='0';
            total_epochs_before_artifact_rejection(s)=0;
            total_epochs_after_artifact_rejection(s)=0;
            total_channels_interpolated(s)=0;
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
        length_ica_data(s)=EEG_copy.trials; % length of data (in second) fed into ICA
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
        
        events = EEG.event;
        
        
        %% STEP 10: Run adjust to find artifacted ICA components
        badICs=[]; EEG_copy =[];
        EEG_copy = EEG;
        EEG_copy =eeg_regepochs(EEG_copy,'recurrence', 1, 'limits',[0 1], 'rmbase', [NaN], 'eventtype', '999'); % insert temporary marker 1 second apart and create epochs
        EEG_copy = eeg_checkset(EEG_copy);
        
        if size(EEG_copy.icaweights,1) == size(EEG_copy.icaweights,2)
            if save_interim_result==1
                badICs = adjusted_ADJUST(EEG_copy, [[output_location filesep 'ica_data' filesep] [datafile_names{s} '_adjust_report']]);
            else
                badICs = adjusted_ADJUST(EEG_copy, [[output_location filesep 'processed_data' filesep] [datafile_names{s} '_adjust_report']]);
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
        total_ICs(s)=size(EEG.icasphere, 1);
        if numel(badICs)==0
            ICs_removed{s}='0';
        else
            ICs_removed{s}=num2str(double(badICs));
        end
        
        % Save dataset after ICA, if saving interim results was preferred
        EEG = eeg_checkset(EEG);
        EEG = pop_editset(EEG, 'setname',  [subject '_ica_data']);
        EEG = pop_saveset(EEG, 'filename', ['sub-' subject '_ses-V03_task-ALL_acq-eeg_eeg_ica_data.set'],'filepath', [output_location filesep 'ica_data' filesep ]); % save .set format
        
        
        
                %% STEP 11: Remove artifacted ICA components from data
        all_bad_ICs=0;
        ICs2remove=find(EEG.reject.gcompreject); % find ICs to remove
        
        
        EEG = eeg_checkset( EEG );
        EEG = pop_subcomp( EEG, ICs2remove, 0); % remove ICs from dataset
        
        
        EEG = eeg_checkset(EEG);
        EEG = pop_editset(EEG, 'setname',  [subject '_adjust_data']);
        EEG = pop_saveset(EEG, 'filename', ['sub-' subject '_ses-V03_task-ALL_acq-eeg_eeg_adjust.set'],'filepath', [output_location filesep 'adjust' filesep ]); % save .set format
        

    end %end if - ica doesn't exist
end % end of subject loop

%% Run Epoching and Artifact Rejection
%cd('Z:\HBCD\Piloting\Data\Preprocessing\Scripts'); 
HBCD_MADE_Epoching();

%% Create the report table for all the data files with relevant preprocessing outputs.
% report_table=table(datafile_names', reference_used_for_faster', faster_bad_channels', ica_preparation_bad_channels', length_ica_data', ...
%     total_ICs', ICs_removed', total_epochs_before_artifact_rejection', total_epochs_after_artifact_rejection',total_channels_interpolated');
% 
% report_table.Properties.VariableNames={'datafile_names', 'reference_used_for_faster', 'faster_bad_channels', ...
%     'ica_preparation_bad_channels', 'length_ica_data', 'total_ICs', 'ICs_removed', 'total_epochs_before_artifact_rejection', ...
%     'total_epochs_after_artifact_rejection', 'total_channels_interpolated'};
% writetable(report_table, ['MADE_preprocessing_report_', datestr(now,'dd-mm-yyyy'),'.csv']);
