classdef Midflow_FixMeaXDAT < SignalFlowSuperClass
%% Disclaimer:
%  This file is part of the Cincinnati Childrens Brain Lab SignalFlowEEG Pipeline
%  
%  Please see http://github.com/cincibrainlab
%
%% Contact:
%  https://github.com/cincibrainlab/SignalFlowEEG/issues
    methods
        function obj = Midflow_FixMeaXDAT(varargin)
           
            % Define Custom Flow Function
            setup.flabel = 'Fix MEA XDAT File';
            setup.flowMode = 'midflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function sfOutput = run(obj)
            % run() - Process the EEG data.           
            EEG = obj.beginEEG;
            % Signal Processing Code Below

            args.mapping = 'hi';
            
            % Correct location : Current location
% 1, 23
% 2, 22
% 3, 30
% 4, 21
% 5, 29
% 6, 20
% 7, 28
% 8, 19
% 9, 27
% 10, 18
% 11, 26
% 12, 17
% 13, 25
% 14, 16
% 15, 24
% 16, 15
% 17, 7
% 18, 14
% 19, 6
% 20, 13
% 21, 5
% 22, 12
% 23, 4
% 24, 11
% 25, 3
% 26, 10
% 27, 2
% 28, 9
% 29, 1
% 30, 8

            
            
            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end
