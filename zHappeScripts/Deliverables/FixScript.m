parseScript("HAPPE_v3_BC_W_HBCD_VEP_DIN.m","VEP_DIM.m")

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
        
        % Search for variable assignments
        [tokens, ~] = regexp(line, '(\w+)\s*=\s*([^=;]*)', 'tokens', 'match');
        
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
        
        % Search for variables after semicolon (;)
        semicolonIdx = strfind(line, ';');
        
        if ~isempty(semicolonIdx)
            semicolonIdx = semicolonIdx(1); % Consider only the first semicolon
            
            if semicolonIdx < length(line)
                remainingLine = line(semicolonIdx+1:end);
                [tokens, ~] = regexp(remainingLine, '(\w+)\s*=\s*([^;]*)', 'tokens', 'match');
                
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
    
    boolOutput = hasFunctionOrVariable;
end

function createNewScript(scriptData, userVars, userExpr, newName)

    % Remove duplicates from userVars and userExpr
    uniqueVars = {};
    uniqueExpr = {};
    for i = 1:length(userVars)
        var = userVars{i};
        expr = userExpr{i};
        if ~any(strcmp(uniqueVars, var))
            uniqueVars{end+1} = var;
            uniqueExpr{end+1} = expr;
        end
    end

    % Create the new script
    newScript = ['%%user variables', newline];
    % Add user-specified variables
    for i = 1:length(uniqueVars)
        newScript = [newScript, 'args.', uniqueVars{i}, ' = ', uniqueExpr{i},';', newline];
    end

    % Replace variable assignments
    replacedVars = {}; % Track the replaced variables
    for i = 1:length(scriptData{1})
        line = scriptData{1}{i};
        
        % Search for variable assignments
        [tokens, matches] = regexp(line, '(\w+)\s*=\s*([^=;]*)', 'tokens', 'match');
        
        if ~isempty(matches)
            for j = 1:length(tokens)
                var = tokens{j}{1};
                expr = tokens{j}{2};
                
                if any(strcmp(uniqueVars, var)) && ~any(strcmp(replacedVars, var))
                    line = regexprep(line, ['\b', expr, '\b'], ['args.', var]);
                    replacedVars{end+1} = var; % Add the replaced variable to the list
                    break;
                end
            end
        end
        
        newScript = [newScript, line, newline];
    end

    % Write the new script to a file, overwriting if it already exists
    fid = fopen(newName, 'w');
    fprintf(fid, '%s', newScript);
    fclose(fid);
end




