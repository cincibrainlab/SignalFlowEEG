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
            args.char_OutputFormat = '.csv';

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
            filt_bandlow=''; %LookupInHistoryTable('num_lowpassfilt','all');%TODO
            filt_bandhigh=''; %LookupInHistoryTable('num_highpassfilt','all');%TODO
            filt_lowcutoff= LookupInHistoryTable_results('lowcutoff');
        	filt_highcutoff= LookupInHistoryTable_results('highcutoff');
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
            events_dins=struct2table(EEG.urevent); events_dins=unique(events_dins.type);
            events_dins=strjoin(events_dins,', ');
            EEGLAB_Version='';%TODO
            VHTP_Version='';%TODO
            SignalFlow_Version='';%TODO
            
            new_row_data = {Timestamp, preprocessed_by,	last_step_applied,raw_filename,	pathway,	study_title,net_nbchan_orig, net_nbchan_post,	chans_removed, filt_bandlow, filt_bandhigh, filt_lowcutoff,	filt_highcutoff, original_sampling_rate_raw, resampling_rate,	xmax_raw,	xmax_post, xmax_percent, xmax_epoch, epoch_length, epoch_limits, epoch_trials, epoch_badtrials, epoch_badid, final_epoch_count, dataRank, num_interp_chans, icaweights,	removed_components, events_dins, EEGLAB_Version, VHTP_Version,SignalFlow_Version};

            new_row_table = cell2table(new_row_data, 'VariableNames', table_data.Properties.VariableNames);
            % Append the new row table to the original table_data
            table_data = [table_data; new_row_table];
            
            % 'Timestamp', 'preprocessed_by',	'last_step_applied','raw_filename',	'pathway',	'study_title','net_nbchan_orig', 'net_nbchan_post',	'chans_removed', 'filt_bandlow', 'filt_bandhigh', 'filt_lowcutoff',	'filt_highcutoff', 'original_sampling_rate_raw', 'resampling_rate',	'xmax_raw',	'xmax_post', 'xmax_percent', 'xmax_epoch', 'epoch_length', 'epoch_limits', 'epoch_trials', 'epoch_badtrials', 'epoch_badid', 'final_epoch_count', 'dataRank', 'num_interp_chans', 'icaweights',	'removed_components', 'events_dins', 'EEGLAB Version', 'VHTP Version','SignalFlow Version'
            % Write output to file if requested
            if strcmpi(args.char_OutputFormat,'.csv')
                writetable(table_data, wholeFilePath);
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
                        values_combined = strjoin(cellstr(values_with_desired_key), ', ');
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