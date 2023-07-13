classdef Inflow_ImportMeaXDAT < SignalFlowSuperClass
%% Disclaimer:
%  This file is part of the Cincinnati Childrens Brain Lab SignalFlowEEG Pipeline
%  
%  Please see http://github.com/cincibrainlab
%
%% Contact:
%  https://github.com/cincibrainlab/SignalFlowEEG/issues
    methods
        function obj = Inflow_ImportMeaXDAT(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Import MEA XDAT File';
            setup.flowMode = 'inflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function EEG = run(obj)
            % run() - Process the EEG data.           
            % Signal Processing Code Below
            args.char_filepath = obj.fileIoVar;
            args.char_netType = 'EGI32';

            % Get the folder path, file name, and file extension
            [folderPath, ~, fileExtension] = fileparts(args.char_filepath);        
            % Add the folder path to the search path
            addpath(folderPath);
            try
                xdatfile = obj.fileIoVar;
                EEG = eeg_emptyset;
                EEG.filename = xdatfile;
                [signalStruct,timeRange,jsonData] = xdatImport(extractBefore(xdatfile,'_data'));
                
                            
                %EEG.data = double(signalStruct.PriSigs.signals);
                EEG.data = signalStruct.PriSigs.signals;
                EEG.pnts = size(EEG.data,2);
                EEG.nbchan = size(EEG.data,1);
                EEG.srate = jsonData.status.samp_freq;
                EEG.x_min = timeRange(1);
                EEG.x_max = timeRange(2);
                clear signalStruct;
                clear timeRange;
                
                EEG = eeg_checkset(EEG);
                %EEG = eeg_checkchanlocs(EEG);
                EEG = pop_select( EEG, 'nochannel', [31,32]);
                for i = 1 : EEG.nbchan
                    
                    EEG.chanlocs( i ).labels = jsonData.sapiens_base.biointerface_map.ntv_chan_name(i);
                    EEG.chanlocs( i ).type = 'EEG';
                    EEG.chanlocs( i ).urchan = jsonData.sapiens_base.biointerface_map.ntv_chan_idx(i);
                
                end
%                 EEG = eeg_checkchanlocs(EEG);
%                 try
%                 load(o.net_file, 'chanlocs');
%                 catch
%                    o.msgout('mea3d.mat file missing', 'proc_error'); 
%                 end
%                 clear jsonData;
%                 chanlocs(31) = [];
                %EEG = pop_select( EEG, 'nochannel', [2,32]);
                for i = 1 : numel(chanlocs)
                    
                    EEG.chanlocs(i).theta       = jsonData.sapiens_base.biointerface_map
                    EEG.chanlocs(i).radius      = jsonData.sapiens_base.biointerface_map
                    EEG.chanlocs(i).X           = jsonData.sapiens_base.biointerface_map.site_ctr_x ./ 1000;
                    EEG.chanlocs(i).Y           = jsonData.sapiens_base.biointerface_map.site_ctr_y ./ 1000;
                    EEG.chanlocs(i).Z           = jsonData.sapiens_base.biointerface_map.site_ctr_z ./ 1000;
                    EEG.chanlocs(i).sph_theta   = jsonData.sapiens_base.biointerface_map
                    EEG.chanlocs(i).sph_phi     = jsonData.sapiens_base.biointerface_map
                    EEG.chanlocs(i).sph_radius  = jsonData.sapiens_base.biointerface_map 

                    EEG.chanlocs(i).theta       = chanlocs(i).theta;
                    EEG.chanlocs(i).radius      = chanlocs(i).radius;
                    EEG.chanlocs(i).X           = chanlocs(i).X;
                    EEG.chanlocs(i).Y           = chanlocs(i).Y; 
                    EEG.chanlocs(i).Z           = chanlocs(i).Z;
                    EEG.chanlocs(i).sph_theta   = chanlocs(i).sph_theta;
                    EEG.chanlocs(i).sph_phi     = chanlocs(i).sph_phi;
                    EEG.chanlocs(i).sph_radius  = chanlocs(i).sph_radius;               
           
                end
                
                o.EEG = eeg_checkset( EEG );
                o.EEG = eeg_checkchanlocs(EEG);
                
                               
                o.EEG.filename = datafile;
                o.EEG.chaninfo.filename = 'meachanlocs.mat';
                o.EEG = eeg_checkset(o.EEG);
                o.net_nbchan_orig = o.EEG.nbchan;
                o.proc_sRate_raw = o.EEG.srate;
                o.proc_xmax_raw = o.EEG.xmax;
           
            catch e
                throw(e);
            end

%             % Load the file using pop_loadset if it has a .set extension
%             if strcmp(fileExtension, '.raw')
%                 EEG = util_sfImportEegFile(args.char_filepath,'nettype',args.char_netType);
%                 %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
%                 EEG = obj.HistoryTable(EEG, args);
%             else 
%                 EEG = [];
%             end
        end
    end
end
