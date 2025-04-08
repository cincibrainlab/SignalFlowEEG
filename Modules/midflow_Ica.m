classdef midflow_Ica < SignalFlowSuperClass
% Description: Perform Independent Component Analysis on data
% ShortTitle: Independent Component Analysis
% Category: Preprocessing
% Tags: Artifact
%
%% Syntax:
%   obj = midflow_Ica(varargin)
%
%% Function Specific Inputs:
%   'char_method'  - Text representing method utilized for ICA
%               default: 'runica' e.g. {'binica', cudaica', 'runica'}
%
%   'num_rank' - Number representing the data rank of input data
%            default: getrank(double(EEG.data))
%
%            getrank is local function to obtain effective rank of data.
%
%   'char_icadir' - Directory to store weight-related output files generated during ICA
%              default: fullfile(pwd,'icaweights')
%
%% Disclaimer:
%  This file is part of the Cincinnati Childrens Brain Lab SignalFlowEEG Pipeline
%  
%  Please see http://github.com/cincibrainlab
%
%% Contact:
%  https://github.com/cincibrainlab/SignalFlowEEG/issues
    methods
        function obj = midflow_Ica(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Independent Component Analysis';
            setup.flowMode = 'midflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function sfOutput = run(obj, varargin)
            % run() - Process the EEG data.           
            EEG = obj.beginEEG;
            [args.QADataPre] = util_GetQAData(EEG);
            % Signal Processing Code Below

            
            args.char_method = 'runica';
            % If you want ICA to run faster download our binaries
            % https://github.com/cincibrainlab/Binica 
            % and use:
            % args.char_method = 'binica';

            if ndims(EEG.data) == 3
                disp('Warning: Data converted to continuous for ICA.')
                rankEEG = eeg_htpEegEpoch2Cont( EEG );
            else
                rankEEG = EEG;
            end
            % You can override the rank by removing the getrank() function
            % and making it the rank you want 
            args.num_rank = getrank(double(rankEEG.data));
            args.char_icadir = fullfile(pwd,'icaweights');

            [EEG,args.results] = eeg_htpEegIcaEeglab(EEG,'method', args.char_method, 'rank', args.num_rank,...
                'icadir',args.char_icadir);
            
            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            [args.QADataPost] = util_GetQAData(EEG);
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;

            function tmprank2 = getrank(tmpdata)
                tmprank = rank(tmpdata);
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %Here: alternate computation of the rank by Sven Hoffman
                covarianceMatrix = cov(tmpdata', 1);
                [E, D] = eig (covarianceMatrix);
                rankTolerance = 1e-6; % Per Makoto Miyakoshi recommendation for potential stability
                tmprank2=sum (diag (D) > rankTolerance);
                if tmprank ~= tmprank2
                    fprintf('Warning: fixing rank computation inconsistency (%d vs %d) most likely because running under Linux 64-bit Matlab\n', tmprank, tmprank2);
                    %tmprank2 = max(tmprank, tmprank2);
                    tmprank2 = min(tmprank, tmprank2);
                end
            end
        end
    end
end

