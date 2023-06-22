classdef inflow_HappeMergeSet < SignalFlowSuperClass
    methods
        function obj = inflow_HappeMergeSet(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'HAPPE Merge SET';
            setup.flowMode = 'inflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function EEG = run(obj)
            % run() - Process the EEG data.         
            % Signal Processing Code Below

            % Gets Default Parameter if User parameter is invalid or empty 
            args.char_filepath = obj.fileIoVar;
            args.highpass = .3;
            args.lowpass = 50;
            args.high_transband = args.highpass; % High pass transition band
            args.low_transband = 10; % Low pass transition band
            args.channel_locations = '/srv/Analysis/Nate_Projects/Github/SignalFlow_Modules_Dev/zHappeScripts/GSN129.sfp';
            args.outerlayer_channel = {'E17' 'E38' 'E43' 'E44' 'E48' 'E49' 'E113' 'E114' 'E119' 'E120' 'E121' 'E125' 'E126' 'E127' 'E128' 'E56' 'E63' 'E68' 'E73' 'E81' 'E88' 'E94' 'E99' 'E107'}; % list of channels
            args.output_location = '/srv/Analysis/Nate_Projects/Test_Happe_HBCD_Output/';

            % Get the folder path, file name, and file extension
            [folderPath, ~, fileExtension] = fileparts(args.char_filepath);        
            % Add the folder path to the search path
            addpath(folderPath);
            %Merge the files similarly to HAPPE
            args.reference_used_for_faster =[];
            
                   
            sub_file_list=dir([args.char_filepath]);
            sub_file_list={sub_file_list.name};
            sub_file_list=sub_file_list(contains(sub_file_list,{'.set'}));
            
            ALLEEG=[];
            % TODO fix this
            subject = 'TestSubject';
                    
            for c=1:length(sub_file_list) %loop throuh files for this participant
                entirefilename = sub_file_list{c};
                
                EEG = pop_loadset('filename',entirefilename,'filepath',args.char_filepath);
                EEG = eeg_checkset( EEG );
                
                % add label to the event structure to include input file name, FACE,
                % MMN etc.....
                EEG = pop_editeventfield( EEG, 'indices',  strcat('1:', int2str(length(EEG.event))), 'input_file',{EEG.filename});
                EEG = eeg_checkset( EEG );
                
                %remove discontinuities
                disconMarkers = find(strcmp({EEG.event.type}, 'boundary')); % boundary markers often indicate discontinuity
                if size(disconMarkers) > 0
                    EEG = eeg_eegrej( EEG, [1 EEG.event(disconMarkers(1)).latency] ); % remove discontinuous chunk... if not EGI, MODIFY BEFORE USING THIS SECTION
                    EEG = eeg_checkset( EEG );
                end
                % remove data after last trsp (OPTIONAL for EGI files... useful when file has noisy data at the end)
                % trsp_flags = find(strcmp({EEG.event.type},'TRSP')); % find indices of TRSP flags
                % EEG = eeg_eegrej( EEG, [(EEG.event(trsp_flags(end)).latency+(1.5*EEG.srate)) EEG.pnts] ); % remove everything 1.5 seconds after the last TRSP
                % EEG = eeg_checkset( EEG );
               
                %% Filter data
                % Calculate filder order using the formula: m = dF / (df / fs), where m = filter order,
                % df = transition band width, dF = normalized transition width, fs = sampling rate
                % dF is specific for the window type. Hamming window dF = 3.3                
                
                hp_fl_order = 3.3 / (args.high_transband / EEG.srate);
                lp_fl_order = 3.3 / (args.low_transband / EEG.srate);
                
                % Round filter order to next higher even integer. Filter order is always even integer.
                if mod(floor(hp_fl_order),2) == 0
                    hp_fl_order=floor(hp_fl_order);
                elseif mod(floor(hp_fl_order),2) == 1
                    hp_fl_order=floor(hp_fl_order)+1;
                end
                
                if mod(floor(lp_fl_order),2) == 0
                    lp_fl_order=floor(lp_fl_order)+2;
                elseif mod(floor(lp_fl_order),2) == 1
                    lp_fl_order=floor(lp_fl_order)+1;
                end
                
                % Calculate cutoff frequency
                high_cutoff = args.highpass/2;
                low_cutoff = args.lowpass + (args.low_transband/2);
                
                % Performing highpass filtering
                EEG = eeg_checkset( EEG );
                EEG = pop_firws(EEG, 'fcutoff', high_cutoff, 'ftype', 'highpass', 'wtype', 'hamming', 'forder', hp_fl_order, 'minphase', 0);
                %[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
                EEG = eeg_checkset( EEG );
                
                % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
                
                % pop_firws() - filter window type hamming ('wtype', 'hamming')
                % pop_firws() - applying zero-phase (non-causal) filter ('minphase', 0)
                
                % Performing lowpass filtering
                EEG = eeg_checkset( EEG );
                EEG = pop_firws(EEG, 'fcutoff', low_cutoff, 'ftype', 'lowpass', 'wtype', 'hamming', 'forder', lp_fl_order, 'minphase', 0);
                %[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
                EEG = eeg_checkset( EEG );
                     
                % pop_firws() - transition band width: 10 Hz
                % pop_firws() - filter window type hamming ('wtype', 'hamming')
                % pop_firws() - applying zero-phase (non-causal) filter ('minphase', 0)
                
                EEG.chanlocs(end).labels = ' Cz'; % changed "end+1" to "end" since Cz is already in the file
                
                EEG = eeg_checkset( EEG );
                
                % Import the file that contains scalp locations of Cz channels.
                EEG=pop_chanedit(EEG, 'load',{args.channel_locations 'filetype' 'autodetect'});
                EEG = eeg_checkset( EEG );
                
                nbchans=cell(1,EEG.nbchan);
                for i=1:EEG.nbchan
                    nbchans{i}= EEG.chanlocs(i).labels;
                end
                
                chans_labels=cell(1,EEG.nbchan);
                 
                for i=1:EEG.nbchan
                  chans_labels{i}= EEG.chanlocs(i).labels;
                end
                [chans,chansidx] = ismember(args.outerlayer_channel, chans_labels);
                outerlayer_channel_idx = chansidx(chansidx ~= 0);
        
                EEG = pop_select( EEG,'nochannel', outerlayer_channel_idx); %remove outer layer of channels
                EEG = eeg_checkset( EEG );
                
                [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, c);
                
                EEG_idx(c)=1;
            end %end loop through files for this participant
                   
            %% Merging files
          
            EEG2Merge= find(EEG_idx==1);
            if length(EEG2Merge) >=2
                EEG = pop_mergeset(ALLEEG,EEG2Merge);
                EEG = eeg_checkset( EEG );
                EEG = pop_editset(EEG, 'setname', [subject '_Merged']);
            end

            %% Run faster
            ref_chan=[]; FASTbadChans=[]; all_chan_bad_FAST=0;
            ref_chan=find(any(EEG.data, 2)==0);
            if numel(ref_chan)>1
                error(['There are more than 1 zeroed channel (i.e. zero value throughout recording) in data.'...
                    ' Only reference channel should be zeroed channel. Delete the zeroed channel/s which is not reference channel.']);
            elseif numel(ref_chan)==1
                list_properties = channel_properties(EEG, 1:EEG.nbchan, EEG.nbchan); % run faster
                FASTbadIdx=min_z(list_properties);
                FASTbadChans=find(FASTbadIdx==1);
                FASTbadChans=FASTbadChans(FASTbadChans~=ref_chan);
                args.reference_used_for_faste={EEG.chanlocs(ref_chan).labels};
                EEG = eeg_checkset(EEG);
                args.channels_analysed=EEG.chanlocs; % keep full channel locations to use later for interpolation of bad channels
            elseif numel(ref_chan)==0
                warning('Reference channel is not present in data. Cz channel will be used as reference channel.');
                ref_chan=find(strcmp({EEG.chanlocs.labels}, 'Cz')); % find Cz channel index

                EEG_copy=EEG; % make a copy of the dataset
                EEG_copy = pop_reref( EEG_copy, ref_chan,'keepref','on'); % rerefer to Cz in copied dataset
                EEG_copy = eeg_checkset(EEG_copy);
                list_properties = channel_properties(EEG_copy, 1:EEG_copy.nbchan, EEG.nbchan); % run faster on copied dataset
                FASTbadIdx=min_z(list_properties);
                FASTbadChans=find(FASTbadIdx==1);
                args.channels_analysed=EEG.chanlocs;
                args.reference_used_for_faster={EEG.chanlocs(ref_chan).labels};
            end
                
            % If FASTER identifies all channels as bad channels, save the dataset
            % at this stage and ignore the remaining of the preprocessing.
            if numel(FASTbadChans)==EEG.nbchan || numel(FASTbadChans)+1==EEG.nbchan
                all_chan_bad_FAST=1;
                % TODO fix this
                datafile_names = 'Testdatafile_names';
                warning(['No usable data for datafile', datafile_names]);
                if output_format==1
                    EEG = eeg_checkset(EEG);
                    EEG = pop_editset(EEG, 'setname',  strrep(datafile_names, ext, '_no_usable_data_all_bad_channels'));
                    EEG = pop_saveset(EEG, 'filename', strrep(datafile_name, ext, '_no_usable_data_all_bad_channels.set'),'filepath', [args.output_location filesep 'processed_data' filesep ]); % save .set format
                elseif output_format==2
                    save([[args.output_location filesep 'processed_data' filesep ] strrep(datafile_names, ext, '_no_usable_data_all_bad_channels.mat')], 'EEG'); % save .mat format
                end
            else
                % Reject channels that are bad as identified by Faster
                EEG = pop_select( EEG,'nochannel', FASTbadChans);
                EEG = eeg_checkset(EEG);
                if numel(ref_chan)==1
                    ref_chan=find(any(EEG.data, 2)==0);
                    EEG = pop_select( EEG,'nochannel', ref_chan); % remove reference channel
                end
            end
                
            if numel(FASTbadChans)==0
                args.faster_bad_channels='0';
            else
                args.faster_bad_channels=num2str(FASTbadChans');
            end
            
            if all_chan_bad_FAST==1
                args.faster_bad_channels='0';
                args.ica_preparation_bad_channels='0';
                args.length_ica_data=0;
                args.total_ICs=0;
                args.ICs_removed='0';
                args.total_epochs_before_artifact_rejection=0;
                args.total_epochs_after_artifact_rejection=0;
                args.total_channels_interpolated=0;
                %continue % ignore rest of the processing and go to next subject
            end
                    
            %% VISUAL INSPECTION (QUICK)... checking filtered data with chunks removed for issues ... final check before saving
            %plot filtered eeg data for the current task
    %         pop_eegplot(EEG,1,1,1);
    %         % window to pause code
    %         uiwait(msgbox({'Visually inspecting merged EEG for... '; ''; ['Subject:   ' subject]; ''; 'When you are finished, hit OK to continue'; ''}));
    %         fprintf('\n\n')
    %         disp('Saving and then moving onto the next subject');
    %         
            %% Give a name to the dataset and save on hard drive
            EEG = eeg_checkset( EEG );
            EEG = pop_editset(EEG, 'setname', ['sub-' subject '_ses-V03_task-ALL_acq-eeg_eeg_filtered_data']);
            EEG = pop_saveset( EEG, 'filename',['sub-' subject '_ses-V03_task-ALL_acq-eeg_eeg_filtered_data.set'],'filepath', args.output_location );
            [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            EEG = obj.HistoryTable(EEG, args);
            
%             %% Remove the saved dataset from EEGLAB memory
%             STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG=[]; CURRENTSET=[];
        end
    end
end
