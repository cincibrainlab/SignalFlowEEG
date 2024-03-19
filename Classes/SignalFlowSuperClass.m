classdef (Abstract) SignalFlowSuperClass < handle
    %SIGNALFLOWSUPERCLASS Summary of this class goes here
    %   Detailed explanation goes here

    properties

        setup           % * setup options
        displayName     % * For readable names for modules 
        hashcode        % * random hash code id    
        tree            % * source, user, target
        isValid         % * function-specific technical validation
        flowMode        % * inflow, midflow, outflow
        fname           % * flow function name
        filename        % * fullfile name
        modfolder       % * subfolder of module
        isUserModule    % * base or custom module
        beginEEG        % * input dataset (mid and outflow functions)
        endEEG          % * output dataset
        fileIoVar
        moduleArray     % * store the whole moduleArray
        currentIndex    % * store the current index
        
        
    end

    methods
        function obj = SignalFlowSuperClass( setup, varargin )
            %SIGNALFLOWSUPERCLASS Construct an instance of this class

            % Extract flow function name
            obj.fname = class(obj);
            obj.filename = which(obj.fname);
            [folder, ~] = fileparts(obj.filename);
            [~, obj.modfolder] = fileparts(folder);
                        
            % Input parser
            p = inputParser;
            addRequired(p, 'setup', @(x) isstruct(x));
            addOptional(p, 'EEG', struct(), @(x) isstruct(x));
            parse(p, setup, varargin{:});
            in = p.Results;

            obj.beginEEG = in.EEG;
            obj.displayName = in.setup.flabel;
            obj.flowMode = in.setup.flowMode;

 %          %Set Unique Hash Value
            obj.hashcode = missing; % obj.generate_Hash();
            obj.setup = in.setup;
            obj.isUserModule = false;

        end

        function str = messageHandler( obj, action )
            % outputs string for GUI or Shell
            % logs to tidytable

            switch(action)
                case 'isValidated'
                    str = sprintf('Validate | Function Inputs are Valid');
                case 'isNotValidated'
                    str = sprintf('Validate | Function Inputs are NOT Valid');
                case 'ActivateModule'
                    str = sprintf('  Activate Module | %s', obj.fname);

                otherwise

            end
        end

        function obj = executeFunction( obj )
            if obj.validate()
                obj.messageHandler( 'isValidated' );
                tempEEG = obj.run();
                obj = obj.cleanUpFunction(tempEEG);
            else
                obj.messageHandler( 'isNotValidated' );
            end
        end

        function obj = cleanUpFunction( obj, EEG )
            if ~obj.infoMode
            obj.endEEG = EEG;
            end
        end

        function EEG = HistoryTable ( obj, EEG, arguments)
            % Get current timestamp
            timestamp = datestr(now, 'mm-dd-yyyy HH:MM:SS.FFF');
            % Create quality index cell array
            data = {obj.fname,'scriptname', obj.fname, EEG.filename;
                    obj.fname,'ModuleHash', obj.hashcode, EEG.filename;
                    obj.fname,'eegid', EEG.filename, EEG.filename;                
                    obj.fname,'timestamp', timestamp, EEG.filename};
            tempCellArray = data;

            % Get fieldnames and values from both structs
            oldFieldNames = fieldnames(arguments);
            % Combine fieldnames and values
            for j =1:numel(oldFieldNames)
                newRow = {obj.fname, oldFieldNames{j}, arguments.(oldFieldNames{j}), EEG.filename};
                tempCellArray = [tempCellArray; newRow];
            end
            historyTable = cell2table(tempCellArray, "VariableNames", {'FlowFunction', 'Key', 'Value', 'FileName'});

            % Add quality index table to EEG data structure
            if isfield(EEG.etc,'SignalFlow') && isfield(EEG.etc.SignalFlow,'History')
                EEG.etc.SignalFlow.History = [EEG.etc.SignalFlow.History; historyTable];
            else
                EEG.etc.SignalFlow.History = historyTable;
            end
            
            % Check that qi_table field was successfully added
            historyTableNotField = ~isfield(EEG.etc.SignalFlow,'History');
            if historyTableNotField
                error("Failed to add historyTable");
            end
        end

        function validateFlag = validate( obj )
            % Should rework to verify it is a module 
            validateFlag = eval(obj.fname);
        end

        function test( obj ) % Tests the algorithm using test data.
            try
                tempEEG = obj.beginEEG;
                TestEEG = pop_loadset('example_data_128.set');
                obj.beginEEG = TestEEG;
                testOutput = obj.run();
                disp(testOutput);
                obj.beginEEG = tempEEG;
                disp('Module is executing properly');
            catch error
                disp(error)
                disp('Module is not executing properly');
            end
        end

        function help( obj ) % Displays a help message explaining the function's purpose and usage.
            fprintf('\n%s (SignalFlow Help)\n', upper(obj.fname));
            % Open the file
            file = fopen(strcat(obj.fname,'.m'), 'r');
            if file ~= -1 
                % Initialize a counter for lines without a '%' symbol
                non_comment_lines = 0;
                
                % Read the file line by line
                while ~feof(file)
                    line = fgets(file);
                    
                    % Check if the line is a comment
                    if startsWith(strtrim(line), '%')
                        % Remove the comment symbol, trim whitespace, and print the line
                        disp(strtrim(line(2:end)));
                    else
                        % Increment the counter for lines without a '%' symbol
                        non_comment_lines = non_comment_lines + 1;
                        
                        % Stop at the second non-comment line
                        if non_comment_lines == 2
                            break;
                        end
                    end
                end
                
                % Close the file
                fclose(file);
            end
        end
    end

    methods (Abstract)        
        EEG = run( obj, varargin ); % Runs the signal processing algorithm.
    end

    methods (Static)

        function hash = generate_Hash()
            % Get the current time in milliseconds
            timestamp = round(posixtime(datetime('now')) * 1000);
            % Generate a random number between 1 and 1000
            randomNumber = randi([1, 1000]);
            % Convert the timestamp and random number to base 36 strings
            timestampBase36 = dec2base(timestamp, 36);
            randomNumberBase36 = dec2base(randomNumber, 36);
            % Concatenate the two base 36 strings
            combinedString = strcat(timestampBase36, randomNumberBase36);
            % Shuffle the characters in the combined string
            shuffledString = combinedString(randperm(length(combinedString)));
            % Take the first 6 characters of the shuffled string as the short hash
            hash = shuffledString(1:6);
        end

        function value = is_module_file()
            value = true;
        end

    end
end

