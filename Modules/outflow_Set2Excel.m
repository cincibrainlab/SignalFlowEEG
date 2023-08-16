classdef outflow_Set2Excel < SignalFlowSuperClass
% Description: A class for processing EEG data and organizing it in a tidy format.
% ShortTitle: SET to Tidy
% Category: Export
% Tags: Export
%   This class inherits from SignalFlowSuperClass and provides
%   functionality to process EEG data and store it in a tidy table.
%   It accepts three inputs: EEG data, an optional options structure,
%   and an optional guiMode boolean.
%
%% Syntax:
%   obj = outflow_Set2Tidy(varargin)
%
%% Function Specific Inputs:
%   'char_OutputFormat' - Charachter array containing the format Tidy Table will be stored in
%                  default: 'parquet'
%
%   'char_Suffix' - Charachter array
%                  default: ''
%
%% Disclaimer:
%  This file is part of the Cincinnati Childrens Brain Lab SignalFlowEEG Pipeline
%  
%  Please see http://github.com/cincibrainlab
%
%% Contact:
%  https://github.com/cincibrainlab/SignalFlowEEG/issues
    
    methods
        function obj = outflow_Set2Excel(varargin)

            % Define Custom Flow Function
            setup.flabel = 'SET to Excel';
            setup.flowMode = 'outflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function sfOutput = run(obj)
            % run() - Process the EEG data.
            EEG = obj.beginEEG;
            [args.QADataPre] = util_GetQAData(EEG);
            % Signal Processing Code Below
            
            args.char_OutputDir = obj.fileIoVar;
            args.char_Filename = 'A00_ANALYSIS_study';
            args.char_OutputFormat = '.xlsx';

            if isfolder(args.char_OutputDir)
                wholeFilePath = fullfile(args.char_OutputDir,strcat(args.char_Filename,args.char_OutputFormat));
            end

            if exist(wholeFilePath,"file")
                try
                    table_data = readtable(wholeFilePath);
                    disp('Data successfully read into a table.');
                catch
                    error('Error reading data from the CSV file. Please check the file path and format.');
                end
            else 
                ColumnHeaders = {'Timestamp', 'preprocessed_by',	'last_step_applied','raw_filename',	'pathway',	'study_title','net_nbchan_orig', 'net_nbchan_post',	'chans_removed', 'filt_bandlow', 'filt_bandhigh', 'filt_lowcutoff',	'filt_highcutoff', 'original_sampling_rate_raw', 'resampling_rate',	'xmax_raw',	'xmax_post', 'xmax_percent', 'xmax_epoch', 'epoch_length', 'epoch_limits', 'epoch_trials', 'epoch_badtrials', 'epoch_badid', 'final_epoch_count', 'dataRank', 'num_interp_chans', 'icaweights',	'removed_components', 'events_dins', 'EEGLAB Version', 'VHTP Version','SignalFlow Version'};
                table_data = array2table(ColumnHeaders,'VariableNames', ColumnHeaders);
                table_data(1,:)= [];
            end

            Timestamp= LookupInHistoryTable("timestamp","last");
            preprocessed_by='';%TODO
        	last_step_applied= LookupInHistoryTable('scriptname','last');
            raw_filename= LookupInHistoryTable('eegid','last');
        	pathway = LookupInHistoryTable('char_filepath','last');
        	study_title='';%TODO
            net_nbchan_orig= LookupInHistoryTable('QADataPre','first').nbchan;
            net_nbchan_post= LookupInHistoryTable('QADataPre','last').nbchan;
        	chans_removed= LookupInHistoryTable_results('proc_badchans');           
            filt_bandlow= LookupInHistoryTable_results('notchcutoff'); 
            try
                filt_bandlow= filt_bandlow(1);
            catch
                filt_bandlow= '';
            end
            filt_bandhigh= LookupInHistoryTable_results('notchcutoff'); 
            try
                filt_bandhigh= filt_bandhigh(2);
            catch
                filt_bandhigh= '';
            end
            filt_lowcutoff= LookupInHistoryTable('num_lowpassfilt','all');
        	filt_highcutoff= LookupInHistoryTable('num_highpassfilt','all');
            original_sampling_rate_raw=LookupInHistoryTable('QADataPre','first').srate;
            resampling_rate= LookupInHistoryTable('num_srate','all');
        	xmax_raw= LookupInHistoryTable('QADataPre','first').xmax;
        	xmax_post= LookupInHistoryTable('QADataPre','last').xmax;
            xmax_percent= LookupInHistoryTable('QADataPre','last').xmax / LookupInHistoryTable('QADataPre','first').xmax * 100;
            xmax_epoch= LookupInHistoryTable_results('proc_xmax_epoch');
            epoch_length= LookupInHistoryTable_results('epochlength');
            epoch_limits= LookupInHistoryTable_results('epochlimits');
            epoch_trials= LookupInHistoryTable_results('trials');
            epoch_badtrials= LookupInHistoryTable_results('epoch_badtrials');
            epoch_badid= LookupInHistoryTable_results('epoch_badid');
            final_epoch_count= LookupInHistoryTable_results('epoch_trials');
            dataRank= LookupInHistoryTable_results('dataRank');
            num_interp_chans= LookupInHistoryTable('QADataPre','first').nbchan - LookupInHistoryTable_results('nbchan_post');
            icaweights=~isempty(EEG.icaweights);
            removed_components= LookupInHistoryTable_results('proc_removeComps');
            if ~isempty(EEG.urevent)
                events_dins=struct2table(EEG.urevent); 
                events_dins=unique(events_dins.type); events_dins=strjoin(events_dins,', ');
            else
                events_dins='';
            end 
            EEGLAB_Version= eeg_getversion;
            VHTP_Version=util_GetGitCommitVersion( 'htpDoctor.m' );
            SignalFlow_Version=util_GetGitCommitVersion( 'SignalFlowControl.m' );
            
            new_row_data = {Timestamp, preprocessed_by,	last_step_applied,raw_filename,	pathway,	study_title,net_nbchan_orig, net_nbchan_post,	chans_removed, filt_bandlow, filt_bandhigh, filt_lowcutoff,	filt_highcutoff, original_sampling_rate_raw, resampling_rate,	xmax_raw,	xmax_post, xmax_percent, xmax_epoch, epoch_length, epoch_limits, epoch_trials, epoch_badtrials, epoch_badid, final_epoch_count, dataRank, num_interp_chans, icaweights,	removed_components, events_dins, EEGLAB_Version, VHTP_Version,SignalFlow_Version};

            new_row_table = cell2table(new_row_data, 'VariableNames', table_data.Properties.VariableNames);
            % Append the new row table to the original table_data
            if size(table_data,1) > 1
                for col = 1:width(table_data)
                    if isnumeric(table_data{1, col}) || islogical(table_data{1, col})
                        table_data.(col) = cellstr(num2str(table_data{:, col}));
                    end
                end
            end
            % Convert all data types to cell arrays of strings in new_row_table
            for col = 1:width(new_row_table)
                if isnumeric(new_row_table{1, col}) || islogical(new_row_table{1, col})
                    new_row_table.(col) = cellstr(num2str(new_row_table{:, col}));
                end
            end
            table_data = [table_data; new_row_table];
            
            % 'Timestamp', 'preprocessed_by',	'last_step_applied','raw_filename',	'pathway',	'study_title','net_nbchan_orig', 'net_nbchan_post',	'chans_removed', 'filt_bandlow', 'filt_bandhigh', 'filt_lowcutoff',	'filt_highcutoff', 'original_sampling_rate_raw', 'resampling_rate',	'xmax_raw',	'xmax_post', 'xmax_percent', 'xmax_epoch', 'epoch_length', 'epoch_limits', 'epoch_trials', 'epoch_badtrials', 'epoch_badid', 'final_epoch_count', 'dataRank', 'num_interp_chans', 'icaweights',	'removed_components', 'events_dins', 'EEGLAB Version', 'VHTP Version','SignalFlow Version'
            % Write output to file if requested
            if strcmpi(args.char_OutputFormat,'.xlsx')
%                 fid = fopen(wholeFilePath, 'w');
%                 if fid == -1
%                     error('Cannot open file for writing: %s', filename);
%                 end
%                 % Write data rows
%                 for row = 1:size(table_data, 1)
%                         for column = 1:size(table_data, 2)
%                             fprintf(fid, '%s,', table_data(row, column)); % Adjust data access as needed
%                         end
%                     fprintf(fid, '\n');
%                 end
%                 fclose(fid);
%                 table_data = table2array(table_data);
%                 writecell(table_data, wholeFilePath)
                writetable(table_data, wholeFilePath,"AutoFitWidth",false);
            elseif strcmpi(args.char_OutputFormat,'.parquet')
                parquetwrite(wholeFilePath, table_data);
            else 
                error("Unsupported output format '%s'.", args.char_OutputFormat);
            end
            

            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            [args.QADataPost] = util_GetQAData(EEG);
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
            function values_combined = LookupInHistoryTable(desired_key, option)
                % Convert option to lowercase to make it case-insensitive
                option = lower(option);
            
                % Find rows with the desired key in the 'Key' column
                rows_with_desired_key = strcmp(EEG.etc.SignalFlow.History.Key, desired_key);
            
                % Extract the corresponding values from the 'Value' column
                values_with_desired_key = EEG.etc.SignalFlow.History.Value(rows_with_desired_key);
            
                % Check if any rows were found with the desired key
                if any(rows_with_desired_key)
                    % Check the provided option
                    if strcmp(option, 'all')
                        % Join all values with commas
                        for i=1:length(values_with_desired_key)
                            if i == 1
                                values_combined = values_with_desired_key{i};
                            else
                                values_combined = strcat(num2str(values_combined),', ', num2str(values_with_desired_key{i}));
                            end
%                         values_combined = strjoin(cellstr(num2str(values_with_desired_key)), ', ');
                        end
                    elseif strcmp(option, 'last')
                        % Return the last value
                        values_combined = values_with_desired_key{end};
                    elseif strcmp(option, 'first')
                        % Return the first value
                        values_combined = values_with_desired_key{1};
                        
                    else
                        error('Invalid option. Use either ''all'' or ''last''.');
                    end
                else
                    % Return an empty string if the key is not found
                    values_combined = '';
                end
            end

            function values_combined = LookupInHistoryTable_results(desired_result)
                % Convert option to lowercase to make it case-insensitive
                values_combined = '';
                desired_key = 'results';
            
                % Find rows with the desired key in the 'Key' column
                rows_with_desired_key = strcmp(EEG.etc.SignalFlow.History.Key, desired_key);
            
                % Extract the corresponding values from the 'Value' column
                values_with_desired_key = EEG.etc.SignalFlow.History.Value(rows_with_desired_key);
            
                % Check if any rows were found with the desired key
                for i=1:length(values_with_desired_key)
                    if isfield(values_with_desired_key{i},(desired_result))
                        if strcmp(values_combined, '')
                            values_combined = values_with_desired_key{i}.(desired_result);
                        else 
                            values_combined = strjoin(values_with_desired_key{i}.(desired_result), ', ');
                        end
                    end
                    
                end
            end

        end
    end
end