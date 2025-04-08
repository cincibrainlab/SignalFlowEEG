classdef (Abstract) SignalFlowSuperClass < handle
    %SIGNALFLOWSUPERCLASS Summary of this class goes here
    %   Detailed explanation goes here
    % TODO give more detailed explanation

    properties

        setup           % * setup options
        displayName     % * For readable names for modules 
        %TODO: Have a static assigned haschode for each module. Only in source tree. Maybe the target tree can have a hascode like (source_hashcode + number of modules in source tree). This will help in tracking the modules in the target tree.
        hashcode        % * random hash code id    
        tree            % * source, user, target
        %TODO: isValid Property is not used. Remove it
        isValid         % * function-specific technical validation 
        flowMode        % * inflow, midflow, outflow
        fname           % * flow function name
        filename        % * fullfile name
        %TODO: modfolder is not used. Remove it
        modfolder       % * subfolder of module
        isUserModule    % * base or custom module
        beginEEG        % * input dataset (mid and outflow functions)
        endEEG          % * output dataset
        fileIoVar       % * file I/O variable
        
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
            %TODO : flable and displayName are the same thing. Change evrything to one. Get rid of flabel
            obj.flowMode = in.setup.flowMode;

 %          %Set Unique Hash Value
            obj.hashcode = missing; % obj.generate_Hash();
            obj.setup = in.setup;
            obj.isUserModule = false;

        end

        %TDOO : This function is only run in one place. Remove it
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

        %TODO : This function is different but never used 
        function obj = executeFunction( obj )
            if obj.validate()
                obj.messageHandler( 'isValidated' );
                tempEEG = obj.run();
                obj = obj.cleanUpFunction(tempEEG);
            else
                obj.messageHandler( 'isNotValidated' );
            end
        end

        %TODO : Thius function is never used 
        function obj = cleanUpFunction( obj, EEG )
            if ~obj.infoMode
            obj.endEEG = EEG;
            end
        end

        %TODO : We should make a logging outside of this so if a file goes missing we know. 
        function EEG = HistoryTable ( obj, EEG, arguments)
            % Get current timestamp
            %TODO: Change all datestr to datetime
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

        %TODO : This function is never used
        function validateFlag = validate( obj )
            % Should rework to verify it is a module 
            validateFlag = eval(obj.fname);
        end

        %TODO : This function is never used
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

        %TODO: This function is never used, but probably should be
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

        %TODO : This function needs to be reworked to the hashing behavior wanted 
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

        %TODO : This function is never used and useless 
        function value = is_module_file()
            value = true;
        end

    end
end

