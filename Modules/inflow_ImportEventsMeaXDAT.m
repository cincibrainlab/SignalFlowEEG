classdef inflow_ImportEventsMeaXDAT < SignalFlowSuperClass
%% Disclaimer:
%  This file is part of the Cincinnati Childrens Brain Lab SignalFlowEEG Pipeline
%  
%  Please see http://github.com/cincibrainlab
%
%% Contact:
%  https://github.com/cincibrainlab/SignalFlowEEG/issues
    methods
        function obj = inflow_ImportEventsMeaXDAT(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Import Events MEA XDAT File';
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
                % EEG = util_htpImportAndRemapMea(args.char_filepath);
                note = @(msg) fprintf('%s: %s\n', mfilename, msg );
                dataFile = args.char_filepath;
                if ~isempty(regexp(dataFile,'xdat','match')); xdatFile = true; else; xdatFile = false; end
                
                if xdatFile
                    try 
                        % Xdat import code from manufacturer
                        % [signalStruct,timeRange,jsonData] = xdatImport(extractBefore(dataFile,'_data'));  
                        xdat_filename = extractBefore(dataFile,'_data');
                        x=allegoXDatFileReaderR2018a();
                        timeRange = x.getAllegoXDatTimeRange(xdat_filename);
                        signalStruct.PriSigs = x.getAllegoXDatPriSigs(xdat_filename,timeRange);
                        % signalStruct.AuxSigs = x.getAllegoXDatAuxSigs(xdat_filename,timeRange);
                        signalStruct.DinSigs = x.getAllegoXDatDinSigs(xdat_filename,timeRange);
                        % signalStruct.DoutSigs = x.getAllegoXDatDoutSigs(xdat_filename,timeRange);
                        signalStruct.AllSigs = x.getAllegoXDatAllSigs(xdat_filename,timeRange);
                        str = fileread([xdat_filename '.xdat.json']); % dedicated for reading files as text
                        jsonData = jsondecode(str);
                        clear x;
                        clear str;
                         

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
                        getX = @(T, mea_formatted_name) T.site_ctr_x(strcmp(T.mea_formatted_name, mea_formatted_name));
                        getY = @(T, mea_formatted_name) T.site_ctr_y(strcmp(T.mea_formatted_name, mea_formatted_name));
                        getZ = @(T, mea_formatted_name) T.site_ctr_z(strcmp(T.mea_formatted_name, mea_formatted_name));
                
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
                
                            %EEG.chanlocs(i).sph_radius = chanlocs(j).sph_radius;
                            %EEG.chanlocs(i).sph_theta = chanlocs(j).sph_theta;
                            %EEG.chanlocs(i).sph_phi = chanlocs(j).sph_phi;
                            %EEG.chanlocs(i).theta = chanlocs(j).theta;
                            %EEG.chanlocs(i).radius = chanlocs(j).radius;
                            EEG.chanlocs(i).X = chanlocs(j).X;
                            EEG.chanlocs(i).Y = chanlocs(j).Y*-1;
                            EEG.chanlocs(i).Z = chanlocs(j).Z;
                %             EEG.chanlocs(i).X = getY(stage2_map, EEG.chanlocs(i).labels);
                %             EEG.chanlocs(i).Y = getX(stage2_map, EEG.chanlocs(i).labels);
                %             EEG.chanlocs(i).Z = getZ(stage2_map, EEG.chanlocs(i).labels);
                            %disp(EEG.chanlocs(i).labels);
                        end
                        % Remap Channel Locations
                        EEG =  util_htpRemapXdatMea( EEG );
                
                        EEG = eeg_checkset(EEG);
                        EEG = eeg_checkchanlocs(EEG);
                    catch E
                        disp(EEG.setname);
                        error('Check if EEGLAB is installed'); 
                    end
                else
                    try 
                        EEG = pop_biosig( dataFile );
                        note('Import EDF.')
                    catch E
                        error('Check if EEGLAB is installed'); 
                    end
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
                
                    % for i = 1 : EEG.nbchan
                    %     if xdatFile
                    % 
                    %         fixed_chanlocs{i} = xdat2meaLookup( num2str( ...
                    %             sscanf(EEG.chanlocs(i).labels, searchSubstring) ) );
                    %     else
                    %         fixed_chanlocs{i} = edf2meaLookup( num2str( ...
                    %             sscanf(EEG.chanlocs(i).labels, searchSubstring) ) );
                    %     end
                    % 
                    %     new_chanlocs_index(i) = find(strcmp( fixed_chanlocs{i}, {chanlocs.labels} ));
                    % end
                
                    note('Look up correct channel order. Create new ordered index.')
                
                    chanlocs = chanlocs(new_chanlocs_index);
                
                    note('Reorder channel map.')
                
                    % chanlocs(31) = [];
                    EEG.chanlocs = chanlocs;
                    EEG = eeg_checkset( EEG );
                
                end
                
                note('Assign chanlocs to imported EDF and check set.')
                
                    
                    

                %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
                EEG = obj.HistoryTable(EEG, args);

            else 
                EEG = [];
            end
            [args.QADataPost] = util_GetQAData(EEG);
            EEG = obj.HistoryTable(EEG, args);
        end
    end
end



function meachan = edf2meaLookup( edfchan )
                        
    meaValueSet = {'Ch 01',	'Ch 02',	'Ch 03',	'Ch 04',	'Ch 05',	'Ch 06',	'Ch 07',	'Ch 08',	'Ch 09', ...
        'Ch 10',	'Ch 11', 'Ch 12',	'Ch 13',	'Ch 14',	'Ch 15',	'Ch 16',	'Ch 17',	'Ch 18',	'Ch 19', ...
        'Ch 20',    'Ch 21',	'Ch 22',	'Ch 23',	'Ch 24',	'Ch 25',	'Ch 26',	'Ch 27',	'Ch 28',	'Ch 29', ...
        'Ch 30'};

    edfKeySet = {'30',	'28',	'26',	'24',	'22',	'20',	'18',	'31',	'29',	'27',	'25',	'23',	'21',	'19', ...
        '17',	'15',	'13',	'11',	'9',	'7',	'5',	'3',	'1',	'16',	'14',	'12',	'10',	'8',	'6', ...
        '4'};

    chanMap = containers.Map(edfKeySet, meaValueSet);

    meachan = chanMap( edfchan );

end

function meachan = xdat2meaLookup(xdatchan)
    meaValueSet = {'Ch 01',	'Ch 02',	'Ch 03',	'Ch 04',	'Ch 05',	'Ch 06',	'Ch 07',	'Ch 08',	'Ch 09', ...
        'Ch 10',	'Ch 11', 'Ch 12',	'Ch 13',	'Ch 14',	'Ch 15',	'Ch 16',	'Ch 17',	'Ch 18',	'Ch 19', ...
        'Ch 20',    'Ch 21',	'Ch 22',	'Ch 23',	'Ch 24',	'Ch 25',	'Ch 26',	'Ch 27',	'Ch 28',	'Ch 29', ...
        'Ch 30'};

    xdatKeySet = {'30',	'28',	'26',	'24',	'22',	'20',	'18',	'31',	'29',	'27',	'25',	'23',	'21',	'19', ...
        '17',	'15',	'13',	'11',	'9',	'7',	'5',	'3',	'1',	'16',	'14',	'12',	'10',	'8',	'6', ...
        '4'};

    chanMap = containers.Map(xdatKeySet, meaValueSet);

    meachan = chanMap( xdatchan );
end



