% Convert Script to work with SignalFlowEEG
parseScript("HAPPE_v3_BC_W_HBCD_FACE_DIN.m","Face_DIN.m")
parseScript("HAPPE_v3_BC_W_HBCD_MMN_DIN.m","MMN_DIN.m")
parseScript("HAPPE_v3_BC_W_HBCD_RS_DIN.m","RS_DIN.m")
parseScript("HAPPE_v3_BC_W_HBCD_VEP_DIN.m","VEP_DIN.m")

parseScript("HBCD_MADE_edit1_11_2023.m","MADE.m")
parseScript("HBCD_MADE_Epoching.m","MADE_Epoching.m")
parseScript("HBCD_merge_filter_faster.m","merge_filter_faster.m")

function parseScript(script, newName)
%     % Load and Read the script file
%     fid = fopen("convertScriptHeader.m", 'r');
%     scriptHeader = textscan(fid, '%s', 'Delimiter', '\n');
%     fclose(fid);
%     HeaderScript = ['%%Header',newline];
%     for i = 1:length(scriptHeader{1})
%         line = scriptHeader{1}{i};
%         HeaderScript = [HeaderScript, line, newline];
%     end
    

%     fid = fopen("convertScriptFooter.m", 'r');
%     scriptFooter = textscan(fid, '%s', 'Delimiter', '\n');
%     fclose(fid);
%     FooterScript = ['%%Footer',newline];
%     for i = 1:length(scriptFooter{1})
%         line = scriptFooter{1}{i};
%         FooterScript = [FooterScript, line, newline];
%     end
    HeaderScript = fileread('convertScriptHeader.m');
    FooterScript = fileread('convertScriptFooter.m');

    fid = fopen(script, 'r');
    scriptData = textscan(fid, '%s', 'Delimiter', '\n');
    fclose(fid);

    % Create the new script with the specified variables at the top
    newScript = ['%%user variables', newline];
    
    % Find user-specified variables
    [userVars, userExpr, replaceScript] = findUserVars(scriptData);
    % Add user-specified variables
    indentation = '    ';
    for i = 1:length(userVars)
        newScript = [newScript,indentation,indentation,indentation, 'args.', userVars{i}, ' = ', userExpr{i},';', newline];
    end
    
    %Combine the scripts
    newScript = [HeaderScript, newScript, replaceScript,FooterScript];
    
    % Write the new script to a file, overwriting if it already exists
    fid = fopen(newName, 'w');
    fprintf(fid, '%s', newScript);
    fclose(fid);
end

function [userVars, userExpr, replaceScript] = findUserVars(scriptData)
    indentation = '    ';
    % Find user-specified variables
    userVars = {};
    userExpr = {};
    replaceScript = [indentation,indentation,indentation,'%%File has been run through SignalFLowEEG script converter',newline];
    for i = 1:length(scriptData{1})
        line = scriptData{1}{i};

        % Skip line if it starts with "%" (including preceding spaces)
        if ~isempty(regexp(line, '^\s*%', 'once'))
            replaceScript = [replaceScript, indentation,indentation,indentation,line, newline];
            continue;
        end
        
        % Search for variable assignments
        [tokens, ~] = regexp(line, '(\w+)\s*=\s*([^=;]*)', 'tokens', 'match');
        
        if ~isempty(tokens)
            var = tokens{1}{1};
            expr = tokens{1}{2};
            
            if isBasicType(expr) && ~containsFunctionOrVariable(expr) && ~any(strcmp(userVars, var))
                if isvarname(var) && ~strcmp(var, '0') && ~strcmp(var, '1') % Check for valid variable name
                    userVars{end+1} = var;
                    userExpr{end+1} = expr;
                    line = [ var, ' = ', 'args.', var,';'];
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
                    
                    if isBasicType(expr) && ~containsFunctionOrVariable(expr) && ~any(strcmp(userVars, var))
                        if isvarname(var) && ~strcmp(var, '0') && ~strcmp(var, '1') % Check for valid variable name
                            userVars{end+1} = var;
                            userExpr{end+1} = expr;
                            line = [var, ' = ', 'args.', var,';'];
                        end
                    end
                end
            end
        end
        replaceScript = [replaceScript, indentation,indentation,indentation,line, newline];
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

