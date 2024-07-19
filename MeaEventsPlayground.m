% run() - Process the EEG data.           
% Signal Processing Code Below
clear all;
close all;


% args.char_filepath = 'C:\Users\sueo8x\Documents\MeaTroubleshooting\';

% chirp paradigm broken electrode plugged into AI2
args.char_filepath = 'C:\Users\sueo8x\Documents\MeaTroubleshooting\allego_0__uid0718-12-47-32_data.xdat';
% looks really good

% chirp paradigm broken electrode
% args.char_filepath = 'C:\Users\sueo8x\Documents\MeaTroubleshooting\allego_0__uid0717-11-52-04_data.xdat';

% resting paradigm mouse 
% args.char_filepath = 'C:\Users\sueo8x\Documents\MeaTroubleshooting\allego_3__uid0717-12-40-42_data.xdat';

% chirp paradigm mouse 
% args.char_filepath = 'C:\Users\sueo8x\Documents\MeaTroubleshooting\allego_4__uid0717-12-43-31_data.xdat';

% 40hz assr paradigm mouse
% args.char_filepath = 'C:\Users\sueo8x\Documents\MeaTroubleshooting\allego_5__uid0717-12-46-24_data.xdat';


args.char_netType = 'MEAXDAT';

% Get the folder path, file name, and file extension
[folderPath, ~, fileExtension] = fileparts(args.char_filepath);        
% Add the folder path to the search path
addpath(folderPath);
% Load the file using pop_loadset if it has a .set extension
if strcmp(fileExtension, '.xdat')
    
    % Code for import 
    % EEG = util_htpImportAndRemapMea(args.char_filepath);
    note = @(msg) fprintf('%s: %s\n', mfilename, msg );
    dataFile = args.char_filepath;
    if ~isempty(regexp(dataFile,'xdat','match')); xdatFile = true; else; xdatFile = false; end
    
    if xdatFile
        % Xdat import code from manufacturer
        % [signalStruct,timeRange,jsonData] = xdatImport(extractBefore(dataFile,'_data'));  
        xdat_filename = extractBefore(dataFile,'_data');
        x=allegoXDatFileReaderR2018a();
        timeRange = x.getAllegoXDatTimeRange(xdat_filename);
        signalStruct.PriSigs = x.getAllegoXDatPriSigs(xdat_filename,timeRange);
        signalStruct.AuxSigs = x.getAllegoXDatAuxSigs(xdat_filename,timeRange);
        signalStruct.DinSigs = x.getAllegoXDatDinSigs(xdat_filename,timeRange);
        signalStruct.DoutSigs = x.getAllegoXDatDoutSigs(xdat_filename,timeRange);
        signalStruct.AllSigs = x.getAllegoXDatAllSigs(xdat_filename,timeRange);
        str = fileread([xdat_filename '.xdat.json']); % dedicated for reading files as text
        jsonData = jsondecode(str);

        % Assuming signalStruct.DinSigs.signals contains your data
        % Din Sigs
        % Can see lines but still messy
        % signal = signalStruct.DinSigs.signals(1,:);
        % Can see lines but still messy
        % signal = signalStruct.DinSigs.signals(2,:);
        % Dout Sigs
        % signal = signalStruct.DoutSigs.signals(1,:);
        % signal = signalStruct.DoutSigs.signals(2,:);
        % Aux sigs
        % signal = signalStruct.AuxSigs.signals(1,:);
        signal = signalStruct.AuxSigs.signals(2,:);

        signal = double(signal);
        
        % Define the sampling rate
        fs = 1000; % Hz
        
        % Generate a time vector based on the length of the signal
        t = (0:length(signal)-1) / fs;
%         t = signalStruct.AuxSigs.timeStamps;

        % Design a lowpass filter with a cutoff frequency of 100 Hz
        lowpassFilter = designfilt('lowpassiir', 'FilterOrder', 8, ...
                           'HalfPowerFrequency', 100, ...
                           'DesignMethod', 'butter', 'SampleRate', fs);

        highpassFilter = designfilt('highpassiir', 'FilterOrder', 8, ...
                            'HalfPowerFrequency', 2, ...
                            'DesignMethod', 'butter', 'SampleRate', fs);
        
        % Design notch filters for 60 Hz, 120 Hz, and 180 Hz
        notch60 = designfilt('bandstopiir', 'FilterOrder', 2, ...
                             'HalfPowerFrequency1', 59, 'HalfPowerFrequency2', 61, ...
                             'DesignMethod', 'butter', 'SampleRate', fs);
        
        notch120 = designfilt('bandstopiir', 'FilterOrder', 2, ...
                              'HalfPowerFrequency1', 119, 'HalfPowerFrequency2', 121, ...
                              'DesignMethod', 'butter', 'SampleRate', fs);
        
        notch180 = designfilt('bandstopiir', 'FilterOrder', 2, ...
                              'HalfPowerFrequency1', 179, 'HalfPowerFrequency2', 181, ...
                              'DesignMethod', 'butter', 'SampleRate', fs);
        
        % Apply the filters sequentially to the signal
        filtered_signal = filtfilt(notch60, signal);
%         filtered_signal = filtfilt(notch120, filtered_signal);
%         filtered_signal = filtfilt(notch180, filtered_signal);
        
        % lowpass
        filtered_signal = filtfilt(lowpassFilter, filtered_signal);

        % highpass
        filtered_signal = filtfilt(highpassFilter, filtered_signal);

%         % Plot the original and filtered signals
%         figure;
%         plot(t, signal);
%         xlabel('Time (seconds)');
%         ylabel('Amplitude');
%         title('Original Signal');
% %         xlim([0 20]); % Zoom in to the first 20 seconds
%         grid on;
        
        figure;
        plot(t, filtered_signal);
        xlabel('Time (seconds)');
        ylabel('Amplitude');
        title('Filtered Signal (60 Hz Notch)');
%         xlim([0 20]); % Zoom in to the first 20 seconds
        grid on;
        
%         % Generate the spectrogram of the filtered signal
%         figure;
%         spectrogram(filtered_signal, 256, 250, 256, fs, 'yaxis');
%         title('Spectrogram of the Filtered Signal');
%         xlabel('Time (seconds)');
%         ylabel('Frequency (Hz)');
%         colorbar;

        % --------------------------------------------------------------------
        stage1_map = readtable("MouseEEGv2H32_Import_Stage1.csv");
        stage2_map = readtable("MouseEEGv2H32_Import_Stage2.csv");
    
        EEG = eeg_emptyset;
        EEG.data = signalStruct.PriSigs.signals; % 32 Channels X N samples
        % EEG.event 
    
        % Please Check TODO
        [~,name,~] = fileparts(dataFile);
        EEG.setname = strcat(name,'.set');
        EEG.subject = strcat(name,'.set');
        EEG.filename = strcat(name,'.set');
    
        EEG.pnts = jsonData.status.num_smpl;
        EEG.nbchan = jsonData.status.signals.pri;
        EEG.srate = jsonData.status.samp_freq;
        EEG.x_min = timeRange(1);
        EEG.x_max = timeRange(2);
    
        EEG.pnts = size(EEG.data,2);
        EEG.nbchan = size(EEG.data,1);
    
        for i = 1 : numel(jsonData.sapiens_base.biointerface_map.chan_type)
            current_type = jsonData.sapiens_base.biointerface_map.chan_type(i);
            if strcmp(current_type{1}, 'ai0')
                EEG.chanlocs(i).labels = jsonData.sapiens_base.biointerface_map.chan_name{i};
            end
        end
        EEG = eeg_checkchanlocs(EEG);
        EEG = eeg_checkset(EEG);
    
        EEG = pop_select(EEG, 'nochannel', [2, 32]);
    
    
        % start index at one, not zero
        getChanName = @(T, og_name) T.mea_formatted_name(strcmp(T.og_amplifier_pin, og_name));
    
        % temporary use of old coordinates
        try
            load('mea3d.mat', 'chanlocs');
        catch
            error('mea3d.mat file missing');
        end
            
        EtoCh = @(E) sprintf('Ch %02d', str2double(E(2:end)));
        getIdx = @( key ) find(strcmp({chanlocs.labels}, EtoCh(key)));
    
        note('Load unordered chanlocs.')
    
        for i = 1 : numel(EEG.chanlocs)
            EEG.chanlocs(i).urchan = EEG.chanlocs(i).labels;
            EEG.chanlocs(i).labels = char(getChanName(stage2_map,  EEG.chanlocs(i).urchan));
            EEG.chanlocs(i).type = "EEG";
            EEG.chanlocs(i).ref = '';
    
            j = getIdx(EEG.chanlocs(i).labels);
    
            EEG.chanlocs(i).X = chanlocs(j).X;
            EEG.chanlocs(i).Y = chanlocs(j).Y*-1;
            EEG.chanlocs(i).Z = chanlocs(j).Z;
        end
        % Remap Channel Locations
        EEG =  util_htpRemapXdatMea( EEG );
    
        EEG = eeg_checkset(EEG);
        EEG = eeg_checkchanlocs(EEG);

    end
    
    if ~xdatFile  % EDF workflow
        if EEG.nbchan == 33
            EEG = pop_select( EEG, 'nochannel', [2,32,33]);
        elseif EEG.nbchan == 32
            EEG = pop_select( EEG, 'nochannel', [2,32]);
        end
    
        note('Remove irrelevant channels (reference and Piezo).')
        
        try
            load('mea3d.mat', 'chanlocs');
        catch
            error('mea3d.mat file missing');
        end
    
        note('Load unordered chanlocs.')
        
        if xdatFile
            searchSubstring = 'E%d';
        else
            searchSubstring = 'Chan %d'; 
        end
    
        note('Look up correct channel order. Create new ordered index.')
        
        chanlocs = chanlocs(new_chanlocs_index);
        
        note('Reorder channel map.')
        
        % chanlocs(31) = [];
        EEG.chanlocs = chanlocs;
        EEG = eeg_checkset( EEG );
    
    end
    
    note('Assign chanlocs to imported EDF and check set.')

else 
    EEG = [];
end

data = filtered_signal;
time = 0:length(data)-1;
% time = signalStruct.AuxSigs.timeStamps;
 
% Parameters
threshold = 300.0;  % Voltage threshold for detecting events (adjust as needed)
min_duration = 200;  % length to ignore events after threshold is exceeded (samples)
 
% Find events
events = [];
in_event = false;
 
for i = 1:length(time)
    amplitude = data(i);
    if abs(amplitude) >= threshold && ~in_event
        event_start = time(i);
        in_event = true;
    elseif abs(amplitude) < threshold && in_event
        event_duration = time(i) - event_start;
        if event_duration >= min_duration
            events(end+1).latency = event_start;
            events(end).duration = event_duration;
            in_event = false;
        end
    end
end
 
 
% Add events to the EEG structure
for i = 1:length(events)
    EEG.event(end+1).type = 'TTL_pulse';
    EEG.event(end).latency = events(i).latency;  % Convert to samples
    EEG.event(end).duration = events(i).duration;  % Convert to samples
end
 
% Sort events by latency
EEG = eeg_checkset(EEG, 'eventconsistency');
 
% Save the updated EEG dataset
pop_saveset(EEG, 'filename', 'updated_eeglab_file.set');

pop_eegplot(EEG, 1, 1, 1);



























