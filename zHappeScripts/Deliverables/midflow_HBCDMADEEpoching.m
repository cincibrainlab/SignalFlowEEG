classdef midflow_HBCDMADEEpoching < SignalFlowSuperClass
    methods
        function obj = midflow_HBCDMADEEpoching(varargin)          
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
            args.rerefer_data = 1; % 0 = NO, 1 = YES
            args.reref = [];
            args.interp_epoch = 1;
            args.frontal_channels = {'E1', 'E8', 'E14', 'E21', 'E25', 'E32', 'E17'};
            args.volt_threshold = [-150 150];
            args.interp_channels = 1;

            %% MADE Epoching and Artifact Rejection
            % Lydia, 1/18/2023
            
%             EEG_chan = pop_loadset('filename','sub-PIUNC0012_ses-V03_merged.set','filepath','Y:\HBCD\Official_Pilot\MADE_preprocessed\sub-PIUNC0012\merged_data');
%             EEG_chan = eeg_checkset(EEG_chan);
%             
%             channels_analysed=EEG_chan.chanlocs;
%             
%             %creates list of files to be preprocessed
%             datafile_names=dir([output_location filesep 'adjust' filesep '*.set']);
%             datafile_names=datafile_names(~ismember({datafile_names.name},{'.', '..', '.DS_Store', 'MADE errors out files', 'not_official_pilots', 'All_Epoched'}));
%             datafile_names={datafile_names.name};
%             [filepath,name,ext] = fileparts(char(datafile_names{1}));
%             
%             %Find which tasks should exist
%             %cd('Z:\HBCD\Piloting\Data\Preprocessing\Scripts'); 
%             
%             write_ExistTasksmat();
%             
%             for subject=1:length(datafile_names) %temp subject loop
%                 
%                 %load in mat file of tasks completed
%                 id = datafile_names{subject};
%                 subjectname = id(5:13);
%             %     load(['Z:\HBCD\Official_Pilot\MADE_preprocessed\Task_completed\' subjectname '_taskscompleted.mat'])
%                 load(['D:\HBCD_pilots\run_made_locally\new_files\Task_completed\' subjectname '_taskscompleted.mat'])
%             
%                 %check if epoched files exist for this participant in the respective task folders
%                 existsMatrix = zeros(1, length(exist_tasks)); % matrix that will tell us which tasks have already been epoched
%                 for c = 1:length(exist_tasks) % loop through list of tasks they completed
%                     currentTask = exist_tasks(c);
%                     if strcmp(currentTask, 'RS') % check RS
%                         if exist([output_location filesep 'All_Epoched' filesep 'RS' filesep 'sub-' subjectname '_RS_processed_data.set'],'file') > 0
%                             existsMatrix(c) = 1;
%                         end
%                     elseif strcmp(currentTask, 'MMN') % check MMN
%                         if exist([output_location filesep 'All_Epoched' filesep 'MMN' filesep 'sub-' subjectname '_MMN_processed_data.set'],'file') > 0
%                             existsMatrix(c) = 1;
%                         end
%                     elseif strcmp(currentTask, 'FACE') % check Face
%                         if exist([output_location filesep 'All_Epoched' filesep 'FACE' filesep 'sub-' subjectname '_FACE_processed_data.set'],'file') > 0
%                             existsMatrix(c) = 1;
%                         end
%                     elseif strcmp(currentTask, 'VEP') % check VEP
%                         if exist([output_location filesep 'All_Epoched' filesep 'VEP' filesep 'sub-' subjectname '_VEP_processed_data.set']) > 0
%                             existsMatrix(c) = 1;
%                         end
%                     end
%                     
%                 end
%                 
%                 if length(exist_tasks) ~= sum(existsMatrix)
%                     
%                     EEG = pop_loadset('filename', datafile_names{subject}, 'filepath', [output_location filesep 'adjust' filesep ]);
%                     
%                     id = datafile_names;
                    
            
                    
            %% STEP 12: Segment data into fixed length epochs
            EEG1 = pop_selectevent( EEG, 'type',{'DIN3', 'DIN2', 'fix+', 'stm+', 'stms', 'ch1+', 'ch2+', 'bas+'},'deleteevents','on');
            
            %Fill task variable
            for i = 1:length(EEG1.event)
                EEG1.event = EEG1.event(~strcmp({EEG1.event.type}, 'boundary'));
    %             EEG1.event(i).input_file = string(EEG1.event(i).input_file);
    %           EEG1.event(i).input_file = string(EEG1.event(i).input_file(:,2:end));
    
            end
            
            % Fill task variable
            for i = 1:length(EEG1.event)
                if contains(EEG1.event(i).input_file, 'MMN')
                     task = 'MMN';
    %                 EEG1.event(i).Task = 'MMN';
    
                elseif contains(EEG1.event(i).input_file, 'RS')
                     task = 'RS';
    %                 EEG1.event(i).Task = 'RS';
    
                elseif contains(EEG1.event(i).input_file, 'VEP')
                     task = 'VEP';
    %                 EEG1.event(i).Task = 'VEP';
    
                elseif contains(EEG1.event(i).input_file, 'FACE')
                     task = 'FACE';
    %                 EEG1.event(i).Task = 'FACE';
    
                end
                
                EEG1.event(i).Task = task;
            end
            
            all_tasks = unique({EEG1.event.Task});
            
            %for now, just assume that all of the tasks were done
            for task = all_tasks
%                 EEG=[];
                if strcmp(task, 'RS')
                    taskName = 'RS';
                    %Baseline
                    startBase = find(strcmp({EEG1.event.type}, 'bas+'));
                    if strcmp(EEG1.event(startBase+1).type, 'DIN3') %if there's a DIN3 in RS use that as the start
                        startBaseLat = (EEG1.event(startBase+1).latency)/EEG1.srate;
                    else
                        startBaseLat = (EEG1.event(startBase).latency)/EEG1.srate;
                    end
                    
                    for i =1:180
                        latency = startBaseLat + (i-1);
                        type = 'o';
                        EEG1 = pop_editeventvals(EEG1,'insert',{1 [] [] []},'changefield',{1 'type' type},'changefield',{1 'latency' latency});
                    end
                    
                    EEG = pop_selectevent( EEG1, 'type',{'o'},'deleteevents','on');
                    
                    epoch_length=[-1 1]; % define Epoch Length
                    EEG = eeg_checkset( EEG );
                    EEG = pop_epoch( EEG, {'o'}, epoch_length, 'epochinfo', 'yes');
                    EEG = pop_selectevent( EEG, 'latency','-.1 <= .1','deleteevents','on');
                    
                elseif strcmp(task, 'MMN')
                    %MMN
                    taskName = 'MMN';
                    
                    EEG = pop_selectevent( EEG1, 'Task', 'MMN','deleteevents','on'); %, 'event', [1:656, 1463:2118]
                    
                    din2s = find(strcmp({EEG.event.type}, 'DIN2'));
                    for d =1:length(din2s)
                        EEG.event(din2s(d)).Condition = EEG.event(din2s(d)-1).Condition;
                    end
                    
                    num_stm = numel(find(strcmp({EEG.event.type}, 'stms')));
                    num_din = length(din2s);
                    if num_stm  < num_din
                        error('MMN has more DIN than stimuli')
                        %                     for w = 1:length(din3s)
                        %                         if ~(strcmp({EEG.event(din3s(w)-1).type}, 'ch1+') || strcmp({EEG.event(din3s(w)-1).type}, 'ch2+'))
                        %                             EEG.event(din3s(w)).type = 'EXTRA_DIN';
                        %                         end
                        %                     end
                    end
                    
                    epoch_length=[-0.1 0.5]; % define Epoch Length
                    EEG = eeg_checkset( EEG );
                    if numel(find(strcmp({EEG.event.type}, 'DIN2'))) >0
                        EEG = pop_epoch( EEG, {'DIN2'}, epoch_length, 'epochinfo', 'yes');
                    else
                        cd(output_location)
                        fileID = fopen('MissingDIN.txt','w');
                        args.missing = fprintf(fileID,'%s %s\n',subjectname, taskName );
                        fclose(fileID);
                        EEG = pop_epoch( EEG, {'stms'}, epoch_length, 'epochinfo', 'yes');
                    end
                    EEG = pop_selectevent( EEG, 'latency','-.1 <= .1','deleteevents','on');
                    
                elseif strcmp(task, 'VEP')
                    %VEP
                    taskName = 'VEP';
                    EEG = pop_selectevent( EEG1, 'Task', 'VEP','deleteevents','on');
                    
                    din3s = find(strcmp({EEG.event.type}, 'DIN3'));
                    for d =1:length(din3s)
                        EEG.event(din3s(d)).Condition = EEG.event(din3s(d)-1).Condition;
                    end
                    epoch_length=[-0.1 0.4]; % define Epoch Length
                    EEG = eeg_checkset( EEG );
                    
                    num_stm = numel(find(strcmp({EEG.event.type}, 'ch1+')))+numel(find(strcmp({EEG.event.type}, 'ch2+')));
                    num_din = length(din3s);
                    if num_stm  < num_din
                        error('VEP has more DIN than stimuli')
                        %                     for w = 1:length(din3s)
                        %                         if ~(strcmp({EEG.event(din3s(w)-1).type}, 'ch1+') || strcmp({EEG.event(din3s(w)-1).type}, 'ch2+'))
                        %                             EEG.event(din3s(w)).type = 'EXTRA_DIN';
                        %                         end
                        %                     end
                    end
                    
                    if numel(find(strcmp({EEG.event.type}, 'DIN3'))) >0
                        EEG = pop_epoch( EEG, {'DIN3'}, epoch_length, 'epochinfo', 'yes');
                    else
                         cd(output_location)
                        fileID = fopen('MissingDIN.txt','w');
                        args.missing = fprintf(fileID,'%s %s\n',subjectname, taskName );
                        fclose(fileID);
                        EEG = pop_epoch( EEG, {'ch1+', 'ch2+'}, epoch_length, 'epochinfo', 'yes');
                    end
                    EEG = pop_selectevent( EEG, 'latency','-.1 <= .1','deleteevents','on');
                    
                elseif strcmp(task, 'FACE')
                    %Face
                    taskName = 'FACE';
                    
                    EEG = pop_selectevent( EEG1, 'Task', 'FACE','deleteevents','on');
                    dins = find(strcmp({EEG.event.type}, 'DIN3'));
                    %label Face Blocks
                    if length(dins) >= 100
                        block1 = EEG.event(1:dins(100));
                    else
                        block1 = EEG.event;
                    end
                    searchblock1_inverted = numel(find(strcmp({block1.Condition}, '2')))-1; %subtract 1 bc there is always 1 flag of each condition in the SESS rows
                    if searchblock1_inverted >=1
                        upright_condition_b1 = '1';
                        upright_condition_b2 = '4';
                    else
                        upright_condition_b1 = '4';
                        upright_condition_b2 = '1';
                    end
                    
                    for d =1:length(dins)
                        %The condition for the din is set equal to whatever the condition of preceding flag
                        EEG.event(dins(d)).Condition = EEG.event(dins(d)-1).Condition;
                        if d <=100
                            EEG.event(dins(d)).Block = 1;
                            if strcmp(EEG.event(dins(d)-1).Condition, '1')
                                EEG.event(dins(d)).Condition = upright_condition_b1;
                                EEG.event(dins(d)-1).Condition = upright_condition_b1;
                                EEG.event(dins(d)+1).Condition = upright_condition_b1;
                            end
                        else
                            EEG.event(dins(d)).Block = 2;
                            if strcmp(EEG.event(dins(d)-1).Condition, '1')
                                EEG.event(dins(d)).Condition = upright_condition_b2;
                                EEG.event(dins(d)-1).Condition = upright_condition_b2;
                                EEG.event(dins(d)-2).Condition = upright_condition_b2;
                            end
                        end
                        
                    end
                    num_stm = numel(find(strcmp({EEG.event.type}, 'stm+')));
                    num_din = length(dins);
                    if num_stm  < num_din
                        for w = 1:length(dins)
                            if ~strcmp({EEG.event(dins(w)-1).type}, 'stm+')
                                EEG.event(dins(w)).type = 'EXTRA_DIN';
                            end
                        end
                    end
                    
                    epoch_length=[-0.1 0.7]; % define Epoch Length
                    EEG = eeg_checkset( EEG );
                    if numel(find(strcmp({EEG.event.type}, 'DIN3'))) >0
                        EEG = pop_epoch( EEG, {'DIN3'}, epoch_length, 'epochinfo', 'yes');
                    else
                        cd(output_location)
                        fileID = fopen('MissingDIN.txt','w');
                        args.missing = fprintf(fileID,'%s %s\n',subjectname, taskName );
                        fclose(fileID);
                        EEG = pop_epoch( EEG, {'stm+'}, epoch_length, 'epochinfo', 'yes');
                    end
                    
                    EEG = pop_selectevent( EEG, 'latency','-.1 <= .1','deleteevents','on');
    
                end
                %total_epochs_before_artifact_rejection=EEG.trials;
                
                %% STEP 13: Remove baseline
%                 if strcmp(taskName, 'VEP')
%                     disp('Performing baseline correction...') ;
%                     EEG = pop_rmbase(EEG, [-100 0]) ;
%                 elseif strcmp(taskName, 'RS')
%                     %no baseline removal for RS
%                 else
%                     disp('Performing baseline correction...') ;
%                     EEG = pop_rmbase(EEG, [-100 0]) ;
%                     
%                 end
                
                %% STEP 14: Artifact rejection
                all_bad_epochs=0;
                voltthres_rejection = 1;
                
                if voltthres_rejection==1 % check voltage threshold rejection
                    if  args.interp_epoch==1 % check epoch level channel interpolation
%                         chans=[]; chansidx=[];chans_labels2=[];
                        chans_labels2=cell(1,EEG.nbchan);
                        for i=1:EEG.nbchan
                            chans_labels2{i}= EEG.chanlocs(i).labels;
                        end
                        [~,chansidx] = ismember(args.frontal_channels, chans_labels2);
                        frontal_channels_idx = chansidx(chansidx ~= 0);
                        badChans = zeros(EEG.nbchan, EEG.trials);
                        args.badepoch=zeros(1, EEG.trials);
                        if isempty(frontal_channels_idx)==1 % check whether there is any frontal channel in dataset to check
                            warning('No frontal channels from the list present in the data. Only epoch interpolation will be performed.');
                        else
                            % find artifaceted epochs by detecting outlier voltage in the specified channels list and remove epoch if artifacted in those channels
                            for ch =1:length(frontal_channels_idx)
                                EEG = pop_eegthresh(EEG,1, frontal_channels_idx(ch), args.volt_threshold(1), args.volt_threshold(2), EEG.xmin, EEG.xmax,0,0);
                                EEG = eeg_checkset( EEG );
                                EEG = eeg_rejsuperpose( EEG, 1, 1, 1, 1, 1, 1, 1, 1);
                                badChans(ch,:) = EEG.reject.rejglobal;
                            end
                            for ii=1:size(badChans, 2)
                                args.badepoch(ii)=sum(badChans(:,ii));
                            end
                            args.badepoch=logical(args.badepoch);
                        end
                        
%                         % If all epochs are artifacted, save the dataset and ignore rest of the preprocessing for this subject.
%                         if sum(badepoch)==EEG.trials || sum(badepoch)+1==EEG.trials
%                             all_bad_epochs=1;
%                             warning(['No usable data for datafile', datafile_names{subject}]);
%                             if output_format==1
%                                 EEG = eeg_checkset(EEG);
%                                 EEG = pop_editset(EEG, 'setname',  [datafile_names{subject} '_no_usable_data_all_bad_epoch']);
%                                 EEG = pop_saveset(EEG, 'filename', [datafile_names{subject} '_no_usable_data_all_bad_epoch.set'],'filepath', [output_location filesep 'processed_data' filesep ]); % save .set format
%                             elseif output_format==2
%                                 save([[output_location filesep 'processed_data' filesep ] strrep(datafile_names{subject}, ext, '_no_usable_data_all_bad_epochs.mat')], 'EEG'); % save .mat format
%                             end
%                         else
%                             EEG = pop_rejepoch( EEG, badepoch, 0);
%                             EEG = eeg_checkset(EEG);
%                         end
                        
%                         if all_bad_epochs==1
%                             warning('No usable data for datafile');
%                         else
%                             % Interpolate artifacted data for all reaming channels
%                             badChans = zeros(EEG.nbchan, EEG.trials);
%                             % Find artifacted epochs by detecting outlier voltage but don't remove
%                             for ch=1:EEG.nbchan
%                                 EEG = pop_eegthresh(EEG,1, ch, args.volt_threshold(1), args.volt_threshold(2), EEG.xmin, EEG.xmax,0,0);
%                                 EEG = eeg_checkset(EEG);
%                                 EEG = eeg_rejsuperpose(EEG, 1, 1, 1, 1, 1, 1, 1, 1);
%                                 badChans(ch,:) = EEG.reject.rejglobal;
%                             end
%                             tmpData = zeros(EEG.nbchan, EEG.pnts, EEG.trials);
%                             for e = 1:EEG.trials
%                                 % Initialize variables EEGe and EEGe_interp;
% %                                 EEGe = []; EEGe_interp = []; badChanNum = [];
%                                 % Select only this epoch (e)
%                                 EEGe = pop_selectevent( EEG, 'event', e, 'deleteevents', 'off', 'deleteepochs', 'on', 'invertepochs', 'off');
%                                 badChanNum = find(badChans(:,e)==1); % find which channels are bad for this epoch
%                                 EEGe_interp = eeg_interp(EEGe,badChanNum); %interpolate the bad channels for this epoch
%                                 tmpData(:,:,e) = EEGe_interp.data; % store interpolated data into matrix
%                             end
%                             EEG.data = tmpData; % now that all of the epochs have been interpolated, write the data back to the main file
%                             
%                             % If more than 10% of channels in an epoch were interpolated, reject that epoch
%                             args.badepoch=zeros(1, EEG.trials);
%                             for ei=1:EEG.trials
%                                 NumbadChan = badChans(:,ei); % find how many channels are bad in an epoch
%                                 if sum(NumbadChan) > round((10/100)*EEG.nbchan)% check if more than 10% are bad
%                                     args.badepoch (ei)= sum(NumbadChan);
%                                 end
%                             end
%                             args.badepoch=logical(args.badepoch);
%                         end
%                         % If all epochs are artifacted, save the dataset and ignore rest of the preprocessing for this subject.
%                         if sum(badepoch)==EEG.trials || sum(badepoch)+1==EEG.trials
%                             all_bad_epochs=1;
%                             warning(['No usable data for datafile', datafile_names{subject}]);
%                             if output_format==1
%                                 EEG = eeg_checkset(EEG);
%                                 EEG = pop_editset(EEG, 'setname',  [datafile_names{subject} '_no_usable_data_all_bad_epochs']);
%                                 EEG = pop_saveset(EEG, 'filename', [datafile_names{subject} '_no_usable_data_all_bad_epochs.set'],'filepath', [output_location filesep 'processed_data' filesep ]); % save .set format
%                             elseif output_format==2
%                                 save([[output_location filesep 'processed_data' filesep ] strrep(datafile_names{subject}, ext, '_no_usable_data_all_bad_epochs.mat')], 'EEG'); % save .mat format
%                             end
%                         else
%                             EEG = pop_rejepoch(EEG, badepoch, 0);
%                             EEG = eeg_checkset(EEG);
%                         end
                    else % if no epoch level channel interpolation
                        EEG = pop_eegthresh(EEG, 1, (1:EEG.nbchan), args.volt_threshold(1), args.volt_threshold(2), EEG.xmin, EEG.xmax, 0, 0);
                        EEG = eeg_checkset(EEG);
                        EEG = eeg_rejsuperpose( EEG, 1, 1, 1, 1, 1, 1, 1, 1);
                    end % end of epoch level channel interpolation if statement
                    
%                     % If all epochs are artifacted, save the dataset and ignore rest of the preprocessing for this subject.
%                     if sum(EEG.reject.rejthresh)==EEG.trials || sum(EEG.reject.rejthresh)+1==EEG.trials
%                         all_bad_epochs=1;
%                         warning(['No usable data for datafile', datafile_names{subject}]);
%                         if output_format==1
%                             EEG = eeg_checkset(EEG);
%                             EEG = pop_editset(EEG, 'setname',  [datafile_names{subject} '_no_usable_data_all_bad_epochs']);
%                             EEG = pop_saveset(EEG, 'filename', [datafile_names{subject} '_no_usable_data_all_bad_epochs.set'],'filepath', [output_location filesep 'processed_data' filesep ]); % save .set format
%                         elseif output_format==2
%                             save([[output_location filesep 'processed_data' filesep ] strrep(datafile_names{subject}, ext, '_no_usable_data_all_bad_epochs.mat')], 'EEG'); % save .mat format
%                         end
%                     else
%                         EEG = pop_rejepoch(EEG,(EEG.reject.rejthresh), 0);
%                         EEG = eeg_checkset(EEG);
%                     end
                end % end of voltage threshold rejection if statement
                
                % if all epochs are found bad during artifact rejection
                if all_bad_epochs==1
                    args.total_epochs_after_artifact_rejection=0;
                    args.total_channels_interpolated=0;
                    %continue % ignore rest of the processing and go to next datafile
                else
                    args.total_epochs_after_artifact_rejection=EEG.trials;
                end
                
                
%                 %% STEP 15: Interpolate deleted channels
%                 if args.interp_channels==1
%                     EEG = eeg_interp(EEG, channels_analysed);
%                     EEG = eeg_checkset(EEG);
%                 end
                
                
                %% STEP 16: Rereference data
                
                if args.rerefer_data==1
                    if iscell(args.reref)==1
                        reref_idx=zeros(1, length(args.reref));
                        for rr=1:length(args.reref)
                            reref_idx(rr)=find(strcmp({EEG.chanlocs.labels}, args.reref{rr}));
                        end
                        EEG = eeg_checkset(EEG);
                        EEG = pop_reref( EEG, reref_idx);
                    else
                        EEG = eeg_checkset(EEG);
                        EEG = pop_reref(EEG, args.reref);
                    end
                end
                
                %remove duplicate epochs
                EEG = pop_selectevent( EEG, 'latency','-1<=1','deleteevents','on','deleteepochs','on','invertepochs','off');
                EEG = eeg_checkset( EEG );
                
%                 %% Save processed data
%                 if output_format==1
%                     EEG = eeg_checkset(EEG);
%                     EEG = pop_editset(EEG, 'setname',  [subjectname '_processed_data']);
%                     EEG = pop_saveset(EEG, 'filename', ['sub-' subjectname '_' taskName '_processed_data.set'],'filepath', [output_location filesep 'All_Epoched' filesep taskName filesep ]); % save .set format
%                 elseif output_format==2
%                     save([[output_location filesep 'processed_data' filesep ] strrep(datafile_names{subject}, ext, '_processed_data.mat')], 'EEG'); % save .mat format
%                 end
                
            end %end epoch/artifact rejection task loop
            
            
            %% Create the report table for all the data files with relevant preprocessing outputs.
            % report_table=table(datafile_names(1:5)', reference_used_for_faster', faster_bad_channels', ica_preparation_bad_channels', length_ica_data', ...
            %     total_ICs', ICs_removed', total_epochs_before_artifact_rejection', total_epochs_after_artifact_rejection',total_channels_interpolated');
            %
            % report_table.Properties.VariableNames={'datafile_names', 'reference_used_for_faster', 'faster_bad_channels', ...
            %     'ica_preparation_bad_channels', 'length_ica_data', 'total_ICs', 'ICs_removed', 'total_epochs_before_artifact_rejection', ...
            %     'total_epochs_after_artifact_rejection', 'total_channels_interpolated'};
            % writetable(report_table, ['MADE_preprocessing_report_', datestr(now,'dd-mm-yyyy'),'.csv']);


            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end
