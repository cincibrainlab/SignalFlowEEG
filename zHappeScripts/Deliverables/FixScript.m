% Here is a MATLAB function that parses for user-specified variables 
% and variables that have not been specified in the provided script:

parseScript("HAPPE_v3_BC_W_HBCD_VEP_DIN.m","VEP_DIM.m")

parseScript("HBCD_MADE_edit1_11_2023.m","MADE.m")

function parseScript(script1,newName)
    % Load the scripts
    script1Data = readScript(script1);
%     script2Data = readScript(script2);
%     script3Data = readScript(script3);
    
    % Find user-specified variables
    userVars = findUserVars(script1Data);
    
    % Find variables that have not been specified
    newVars = findNewVars(script1Data);
    
    
    % Create the new script with the specified variables at the top
%     createNewScript(script1Data, userVars, newVars, script2Data, script3Data);
    createNewScript(script1Data, userVars, newVars,newName);
end

function scriptData = readScript(script)
    % Read the script file
    fid = fopen(script, 'r');
    scriptData = textscan(fid, '%s', 'Delimiter', '\n');
    fclose(fid);
end

function userVars = findUserVars(scriptData)
    % Find user-specified variables
    userVars = {};
    userVarPattern = '(\w+)\s*=\s*([^=]*)$';
    for i = 1:length(scriptData{1})
        line = scriptData{1}{i};
        matches = regexp(line, userVarPattern, 'tokens');
        if ~isempty(matches)
            var = matches{1}{1};
            expr = matches{1}{2};
            if ~contains(expr, '+') && ~contains(expr, '-') && ~contains(expr, '*') && ~contains(expr, '/') && ~contains(expr, '^')
                InFileFlag = false;
                if contains(expr,'.')
                    InFileFlag = true;
                end
                if (ismember(var,userVars))
                    InFileFlag = true;
                end
                if InFileFlag == false
                    userVars{end+1} = var;
                end
            end
        end
    end
end


function newVars = findNewVars(scriptData)
    % Find variables that have not been specified in the script
    newVars = {};
    varPattern = '^\s*(\w+)\s*=\s*';
    vars = {};
    for i = 1:length(scriptData{1})
        line = scriptData{1}{i};
        matches = regexp(line, varPattern, 'tokens');
        if ~isempty(matches)
            var = matches{1}{1};
            vars{end+1} = var;
        end
    end

    for i = 1:length(scriptData{1})
        line = scriptData{1}{i};
        if isempty(line)
            continue;
        end
        if line(1) == '%' || line(1) == ' '
            continue;
        end
        matches = regexp(line, '(\w+)', 'match');
        if ~isempty(matches)
            for j = 1:length(matches)
                var = matches{j};
                if ~ismember(var, vars) && ~ismember(var, newVars)
                    if isVariableDefinedBefore(scriptData, i, var)
                        newVars{end+1} = var;
                    end
                end
            end
        end
    end
end

function isDefined = isVariableDefinedBefore(scriptData, currentIndex, var)
    isDefined = false;
    for i = currentIndex-1:-1:1
        line = scriptData{1}{i};
        if isempty(line)
            continue;
        end
        if line(1) == '%' || line(1) == ' '
            continue;
        end
        if contains(line, [var '='])
            isDefined = true;
            break;
        end
    end
end


function createNewScript(scriptData, userVars, newVars,newName)
    % Create the new script
    newScript = [];
    newScript = [newScript, newline,'%%user variables',newline];
    % Add user-specified variables
    for i = 1:length(userVars)
        newScript = [newScript, sprintf('%s = "TODO Please Provide"\n', userVars{i})];
    end
    newScript = [newScript, newline,'%%new variables',newline];
    % Add new variables
    for i = 1:length(newVars)
        newScript = [newScript, sprintf('%s = "TODO Please Provide"\n', newVars{i})];
    end
    
    % Add the rest of the script
    newScript = [newScript, newline];
    for i = 1:length(scriptData{1})
        newScript = [newScript, scriptData{1}{i}, newline];
    end

    % Write the new script to a file
    fid = fopen(newName, 'w');
    fprintf(fid, newScript);
    fclose(fid);
end