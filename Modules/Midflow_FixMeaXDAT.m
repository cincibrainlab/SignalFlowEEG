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
            [args.QADataPre] = util_GetQAData(EEG);
            % Signal Processing Code Below
            
            % Dictionary for correct mappings 
            args.myDict = containers.Map();
            % Current location : Correct location 
            args.myDict(1)  = 29;
            args.myDict(2)  = 27;
            args.myDict(3)  = 25;
            args.myDict(4)  = 23;
            args.myDict(5)  = 21;
            args.myDict(6)  = 19;
            args.myDict(7)  = 17;
            args.myDict(8)  = 30;
            args.myDict(9)  = 28;
            args.myDict(10) = 26;
            args.myDict(11) = 24;
            args.myDict(12) = 22;
            args.myDict(13) = 20;
            args.myDict(14) = 18;
            args.myDict(15) = 16;
            args.myDict(16) = 14;
            args.myDict(17) = 12;
            args.myDict(18) = 10;
            args.myDict(19) = 8;
            args.myDict(20) = 6;
            args.myDict(21) = 4;
            args.myDict(22) = 2;
            args.myDict(23) = 1;
            args.myDict(24) = 15;
            args.myDict(25) = 13;
            args.myDict(26) = 11;
            args.myDict(27) = 9;
            args.myDict(28) = 7;
            args.myDict(29) = 5;
            args.myDict(30) = 3;

            %Remapping the data to correct locations 
            EEG.data

            % Create a temporary cell array to hold the reordered values
            reorderedArray = cell(size(originalArray));
            
            % Reorder the values based on the mapping
            for currentIdx = 1:numel(EEG.data)
                correctIdx = mapping(currentIdx);
                reorderedArray{correctIdx} = EEG.data{currentIdx};
            end
            
            %Parameters and run history is stored in EEG.etc.SignalFlow.History field in EEG structure
            [args.QADataPost] = util_GetQAData(EEG);
            EEG = obj.HistoryTable(EEG, args);

            sfOutput = EEG;
        end
    end
end
