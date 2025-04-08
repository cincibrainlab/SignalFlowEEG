classdef convertScriptHeader < SignalFlowSuperClass
    methods
        function obj = convertScriptHeader(varargin)          
            % Define Custom Flow Function
            setup.flabel = 'Hbcd';
            setup.flowMode = 'midflow';

            % Construction Function
            obj = obj@SignalFlowSuperClass(setup, varargin{:});
        end

        function sfOutput = run(obj)
            % run() - Process the EEG data.           
            EEG = obj.beginEEG;
            % Signal Processing Code Below