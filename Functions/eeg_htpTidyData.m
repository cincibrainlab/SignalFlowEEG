function df = eeg_htpTidyData(EEG, varargin)
% Converts 3D EEG data into a tidy format table with channels, trials,
% samples, and values as columns.
%
% Args:
%   EEG: A struct containing EEG data, where EEG.data is a 3D matrix with
%        dimensions channel X samples X trials.
%
% Returns:
%   df: A table containing the tidy format EEG data, with columns chan,
%       trial, sample, and value.
%
% Optional Parameters:
%       'OutputFormat': 'parquet' (default) or 'csv' or 'none'
%       'OutputDir': Output directory (default: current directory)
%       'Suffix': Add suffix to the base output filename (default: '')
%
% Example:
%       eeg_htpTidyData(EEG, 'OutputFormat', 'csv', 'OutputDir', '/path/to/output', 'Suffix', 'v1')
%
% Raises:
%   Matlab:error: If the input original data does not match tidy data.

p = inputParser;
addRequired(p, 'EEG', @isstruct);
addOptional(p, 'OutputFormat', 'none');
addOptional(p, 'OutputDir', pwd, @isfolder);
addOptional(p, 'Suffix', '');
parse(p, EEG, varargin{:});

[~, filestem, ~] = fileparts(EEG.filename);
filestem = sprintf('%s_-_%s', filestem, p.Results.Suffix);
% Test if data is epoched or not
if(ndims(EEG.data) == 3), is_epoched = true;
else, is_epoched = false; end

% Get size of EEG data
[channels, samples, trials] = size(EEG.data);

% Check that input data meets the expected criteria
if is_epoched
    assert(channels > 0 && samples > 0 && trials > 0, "EEG data must have at least one channel, sample, and trial");
else
    assert(channels > 0 && samples > 0, "EEG data must have at least one channel and sample");
end

% Reshape EEG data into a 2D matrix
EEGDATA_2D = reshape(EEG.data, channels, trials*samples)';

% Create trials and samples columns
[trials_2D, samples_2D, channels_2d] = meshgrid(1:trials, 1:samples, 1:channels);
long_format = [reshape(channels_2d, [], 1) reshape(trials_2D, [], 1) reshape(samples_2D, [], 1) reshape(EEGDATA_2D, [], 1)];
idlabels = repmat({filestem}, channels*trials*samples, 1);

% Convert to table
df = array2table(long_format, 'VariableNames', {'chan','trial','sample','value'});
df.eegid = idlabels;

% add channel names
chan_labels = {EEG.chanlocs.labels};
chanidx = reshape(channels_2d, [], 1);
df.chan = chan_labels(chanidx)';

df = movevars(df, 'eegid', 'Before', 'chan');
% Sort table by chan, trial, and sample columns
df = sortrows(df, {'chan','trial','sample'}, "ascend");

% Check number of rows
assert(size(long_format, 1) == channels*samples*trials, "Number of rows is incorrect.");

% Check sample
if is_epoched
    test_chan_idx = randi([1 channels], 1, 1);
    test_chan = chan_labels{test_chan_idx};
    test_sample = randi([1 samples], 1, 1);
    test_trial = randi([1 trials], 1, 1);
    test_value = EEG.data(test_chan_idx, test_sample, test_trial);
    obs_index = strcmp(test_chan, df.chan) & df.sample == test_sample & df.trial == test_trial;
    obs_value = df.value(obs_index);
    fprintf("Function Verification:\nTesting: Chan %s, Sample %d, Trial %d\n Original value: %f, Tidy value: %f\n", ...
        test_chan, test_sample, test_trial, test_value, obs_value);
    assert(test_value == obs_value, "Error in conversion from EEG.data to Tidy Format");
else
    test_chan = randi([1 channels], 1, 1);
    test_sample = randi([1 samples], 1, 1);
    test_value = EEG.data(test_chan, test_sample);
end

    % Write output to file if requested
    if ~strcmpi(p.Results.OutputFormat, 'none')
        switch lower(p.Results.OutputFormat)
            case 'parquet'
                base_filename = fullfile(p.Results.OutputDir, [filestem '.parquet']);
                parquetwrite(base_filename, df);
            case 'csv'
                base_filename = fullfile(p.Results.OutputDir, [filestem '.csv']);
                writetable(df, base_filename);
            otherwise
                error("Unsupported output format '%s'.", p.Results.OutputFormat);
        end
    end

end

