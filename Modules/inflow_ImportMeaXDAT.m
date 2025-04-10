classdef inflow_ImportMeaXDAT < SignalFlowSuperClass
%% Disclaimer:
%  This file is part of the Cincinnati Childrens Brain Lab SignalFlowEEG Pipeline
%  
%  Please see http://github.com/cincibrainlab
%
%% Contact:
%  https://github.com/cincibrainlab/SignalFlowEEG/issues
    methods
        function obj = inflow_ImportMeaXDAT(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Import MEA XDAT File';
            setup.flowMode = 'inflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function EEG = run(obj, varargin)
            % run() - Process the EEG data.           
            % Signal Processing Code Below
            args.char_filepath = obj.fileIoVar;
            
            args.char_netType = 'MEAXDAT';
            
            % Get the folder path, file name, and file extension
            [folderPath, ~, fileExtension] = fileparts(args.char_filepath);        
            % Add the folder path to the search path
            addpath(folderPath);
            % Load the file using pop_loadset if it has a .set extension
            if strcmp(fileExtension, '.xdat')
                
                % Code for import 
                note = @(msg) fprintf('%s: %s\n', mfilename, msg );
                dataFile = args.char_filepath;
                if ~endsWith(dataFile, '_data.xdat')
                    note(['Skipping file (does not end with _data.xdat): ' dataFile]);
                    EEG = []; % Return empty to indicate no processing
                    return;
                else
                    xdatFile = true;
                end
                
                if xdatFile
                    % Xdat import code from manufacturer
                    % [signalStruct,timeRange,jsonData] = xdatImport(extractBefore(dataFile,'_data'));  
                    xdat_filename = extractBefore(dataFile,'_data');
                    % x=allegoXDatFileReaderR2018a_new();
                    x=allegoXDatFileReaderR2019b();
                    % x=allegoXDatFileReaderR2018a();
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
                    % t = signalStruct.AuxSigs.timeStamps;

            
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
                    % EEG =  util_htpRemapXdatMea( EEG );
                
                    % EEG = eeg_checkset(EEG);
                    % EEG = eeg_checkchanlocs(EEG);
            
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
            [args.QADataPost] = util_GetQAData(EEG);
            % pop_eegplot(EEG, 1, 1, 1);
            EEG = obj.HistoryTable(EEG, args);
        end
    end
end
