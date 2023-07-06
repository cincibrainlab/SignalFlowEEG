% parseScript("HAPPE_v3_BC_W_HBCD_VEP_DIN.m","VEP_DIM.m")

parseScript("HBCD_MADE_edit1_11_2023.m","MADE.m")

function parseScript(script1, newName)
    % Load the script
    scriptData = readScript(script1);
    
    % Find user-specified variables
    [userVars, userExpr] = findUserVars(scriptData);
    
    % Create the new script with the specified variables at the top
    createNewScript(scriptData, userVars, userExpr, newName);
end

function scriptData = readScript(script)
    % Read the script file
    fid = fopen(script, 'r');
    scriptData = textscan(fid, '%s', 'Delimiter', '\n');
    fclose(fid);
end

function [userVars, userExpr] = findUserVars(scriptData)
    % Find user-specified variables
    userVars = {};
    userExpr = {};
    for i = 1:length(scriptData{1})
        line = scriptData{1}{i};
        [tokens, ~] = regexp(line, '(\w+)\s*=\s*([^=]*)$', 'tokens', 'match');
        if ~isempty(tokens)
            var = tokens{1}{1};
            expr = tokens{1}{2};
            if isBasicType(expr) && ~containsFunctionOrVariable(expr)
                if isvarname(var) && ~strcmp(var, '0') && ~strcmp(var, '1') % Check for valid variable name
                    userVars{end+1} = var;
                    userExpr{end+1} = expr;
                end
            end
        end
    end
end

function isBasic = isBasicType(expr)
    % Check if the expression is of basic type (int, string, long, bool)
    basicTypes = {'double', 'single', 'int8', 'uint8', 'int16', 'uint16', ...
                  'int32', 'uint32', 'int64', 'uint64', 'char', 'logical'};
    exprType = class(expr);
    isBasic = any(strcmp(basicTypes, exprType));
end

function boolOutput = containsFunctionOrVariable(expr)
    % Check if the expression contains a function call or variable
    try
        [~, ~] = evalc(expr);
        hasFunctionOrVariable = false;
    catch
        hasFunctionOrVariable = true;
    end
    % Check if the expression contains text outside of quotes
    matches = regexp(expr, '''[^'']*''', 'match');  % Find all text inside single quotes
    textInsideQuotes = '';
    if ~isempty(matches)
        textInsideQuotes = [matches{:}];  % Concatenate the matches into a single string
    end
    textInsideQuotes = regexprep(textInsideQuotes, '''[^'']*''', '');  % Remove the text inside single quotes
    hasTextOutsideQuotes = ~isempty(regexp(textInsideQuotes, '\w', 'once'));  % Check if there is any text outside of quotes
    boolOutput = hasTextOutsideQuotes || hasFunctionOrVariable;
end


function createNewScript(scriptData, userVars, userExpr, newName)
    % Sort userVars and userExpr together
    [~, sortedIndices] = sort(lower(userVars));
    userVars = userVars(sortedIndices);
    userExpr = userExpr(sortedIndices);

    % Remove duplicates from userVars and userExpr
    [uniqueVars, ~, uniqueIndices] = unique(userVars, 'stable');
    userExpr = userExpr(uniqueIndices);

    % Create the new script
    newScript = ['%%user variables', newline];
    % Add user-specified variables
    for i = 1:length(uniqueVars)
        newScript = [newScript, getUserVariableLine(scriptData, uniqueVars{i}, userExpr{i}), newline];
    end

    % Add the rest of the script
    newScript = [newScript, newline];
    for i = 1:length(scriptData{1})
        newScript = [newScript, scriptData{1}{i}, newline];
    end

    % Write the new script to a file, overwriting if it already exists
    fid = fopen(newName, 'w');
    fprintf(fid, '%s', newScript);
    fclose(fid);
end



function variableLine = getUserVariableLine(scriptData, variableName, variableExpression)
    for i = 1:length(scriptData{1})
        line = scriptData{1}{i};
        if contains(line, variableName) && ~startsWith(line, '%')
            variableLine = line;
            return;
        end
    end
    variableLine = ['% ', variableName, ' = ', variableExpression];
end