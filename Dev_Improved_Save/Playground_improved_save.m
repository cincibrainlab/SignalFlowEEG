% import sfapp.sfgClass;
% import sfapp.sfgClass.sfControl;

% Save is in sfapp.sfgClass  
% Specify the path to your JSON file
originalJsonFilePath = 'Playground_improved_save.json';
newJsonFilePath = 'Playground_improved_save2.json';

fakeApp = sfapp.sfgClass.sfControl;
fakeApp.proj.name = 'Test App';
fakeApp.proj.desc = 'This is a test app';
fakeApp.proj.author = 'Test Author';

% test save
saveApp(fakeApp, newJsonFilePath);

% test load
fakeApp2 = loadApp(newJsonFilePath);

disp(['Name: ', fakeApp2.name]);
disp(['Description: ', fakeApp2.desc]);
disp(['Author: ', fakeApp2.author]);
% disp(['Module 1: ', fakeApp2.module.TargetModuleArray{1}.displayName]);
% disp(['Module 2: ', fakeApp2.module.TargetModuleArray{2}.displayName]);
% disp(['Module 3: ', fakeApp2.module.TargetModuleArray{3}.displayName]);
% disp(['Module 4: ', fakeApp2.module.TargetModuleArray{4}.displayName]);

fakeApp2 = loadApp(originalJsonFilePath);
disp(['Name: ', fakeApp2.name]);
disp(['Description: ', fakeApp2.desc]);
disp(['Author: ', fakeApp2.author]);
% disp(['Module 1: ', fakeApp2.module.TargetModuleArray{1}.displayName]);
% disp(['Module 2: ', fakeApp2.module.TargetModuleArray{2}.displayName]);
% disp(['Module 3: ', fakeApp2.module.TargetModuleArray{3}.displayName]);
% disp(['Module 4: ', fakeApp2.module.TargetModuleArray{4}.displayName]);

% fake functiions to save and load the fake app
function saveApp(fakeApp, jsonFilePath)
    jsonData = transformToJsonData(fakeApp);
    saveJSONData(jsonFilePath, jsonData);
end

function fakeApp2 = loadApp(jsonFilePath)
    jsonData = loadJSONData(jsonFilePath);
    fakeApp2 =  setLoadData(jsonData);
end

% functions needed for save
function saveJSONData(jsonFilePath, jsonData) 
    try
        % Convert the JSON data to a string
        jsonString = jsonencode(jsonData,PrettyPrint=true);
    
        % Write the string to a file
        fid = fopen(jsonFilePath, 'w');
        if fid == -1
            error('Cannot create JSON file');
        end
        fwrite(fid, jsonString, 'char');
        fclose(fid);
    catch e
        % Handle any errors that may occur during writing
        disp('Error writing JSON to file');
        disp(e);
    end
end

function jsonData = transformToJsonData(fakeApp)
    jsonData = struct;

    % get proj info
    jsonData.proj = struct;
    jsonData.proj.name = fakeApp.proj.name;
    jsonData.proj.description = fakeApp.proj.desc;
    jsonData.proj.author = fakeApp.proj.author;
    % get proj path tags from the app
    for y=1:length(fieldnames(fakeApp.proj))
            
        % for each field in fakeApp.module.TargetModuleArray(x) that have 'fileIO' in the name
        currentFields = fieldnames(fakeApp.proj);
        if contains(currentFields{y}, 'path_')
            jsonData.proj.pathTags.(currentFields{y}) = fakeApp.proj.(currentFields{y});
        end
    end

    % get module info
    jsonData.TargetModuleArray = struct;
    for x=1:length(fakeApp.module.TargetModuleArray)
        % displayName
        jsonData.TargetModuleArray(x).displayName = fakeApp.module.TargetModuleArray{x}.displayName;
        % defauleHash
        % jsonData.TargetModuleArray(x).defauleHash = fakeApp.module.TargetModuleArray(x).defauleHash;
        % fname
        jsonData.TargetModuleArray(x).fname = fakeApp.module.TargetModuleArray{x}.fname;
        % isUserModule
        jsonData.TargetModuleArray(x).isUserModule = fakeApp.module.TargetModuleArray{x}.isUserModule;
        %fileSaveVars
        jsonData.TargetModuleArray(x).fileSaveVars = struct;
        % for each field in fakeApp.module.TargetModuleArray(x) that have 'fileIO' in the name

        for y=1:length(fieldnames(fakeApp.module.TargetModuleArray{x}))
            
            % for each field in fakeApp.module.TargetModuleArray(x) that have 'fileIO' in the name
            currentFields = fieldnames(fakeApp.module.TargetModuleArray{x});
            if contains(currentFields{y}, 'fileIo')
                jsonData.TargetModuleArray(x).fileSaveVars.(currentFields{y}) = fakeApp.module.TargetModuleArray{x}.(currentFields{y});
            end
            
            
        end

    end
end


% currentFieldName = fieldnames(fakeApp.module.TargetModuleArray{x}(y));
% if contains(fieldnames(currentFieldName, 'fileIo'))
%     jsonData.TargetModuleArray(x).fileSaveVars.(fieldnames(fakeApp.module.TargetModuleArray{x}(y))) = fakeApp.module.TargetModuleArray(x).(fieldnames(fakeApp.module.TargetModuleArray{x}(y)));
% end

% functions needed for load
function jsonData = loadJSONData(jsonFilePath) 
    try
        % Read the JSON file using jsondecode
        jsonData = jsondecode(fileread(jsonFilePath));
    
        % Display the decoded JSON data
        disp('Decoded JSON Data:');
        disp(jsonData);
    
        % Access specific fields in the JSON data as needed
        % For example, if your JSON has a field named 'name'
        if isfield(jsonData, 'proj')
            disp(['Name: ', jsonData.proj.name]);
            disp(['Description: ', jsonData.proj.description]);
            disp(['Author: ', jsonData.proj.author]);
        end
    catch e
        % Handle any errors that may occur during reading or decoding
        disp('Error reading or decoding the JSON file.');
        disp(e)
    end
end

function fakeApp = setLoadData(jsonData, fakeApp)
    % Set the data from the JSON file to the fake app
    fakeApp.name = jsonData.proj.name;
    fakeApp.desc = jsonData.proj.description;
    fakeApp.author = jsonData.proj.author;

    %TODO set the module data
    % % do opposite of save 
    % for x=1:length(jsonData.TargetModuleArray)
    %     module_name = ['fmodule_', num2str(x)];
    %     fakeApp.module.TargetModuleArray{x}.displayName = jsonData.TargetModuleArray(x).(module_name).displayName;
    %     fakeApp.module.TargetModuleArray{x}.fname = jsonData.TargetModuleArray(x).(module_name).fname;
    %     fakeApp.module.TargetModuleArray{x}.isUserModule = jsonData.TargetModuleArray(x).(module_name).isUserModule;
    %     %fileSaveVars
    %     for y=1:length(fieldnames(jsonData.TargetModuleArray(x).(module_name).fileSaveVars))
    %         currentFieldName = fieldnames(jsonData.TargetModuleArray(x).(module_name).fileSaveVars);
    %         fakeApp.module.TargetModuleArray{x}.(currentFieldName{y}) = jsonData.TargetModuleArray(x).(module_name).fileSaveVars.(currentFieldName{y});
    %     end
    % end
end

% I want to implement defualt hashes, I think that will cause less bugs 

% I also need to implement and save commit hash, user should be notified if
% not same commit. A choice doesn't necessarily need to be made but we
% could give option to switch to that commit 



