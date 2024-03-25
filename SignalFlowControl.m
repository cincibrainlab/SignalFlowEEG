classdef SignalFlowControl < handle

    properties
        cfg = struct(); % internal class states
        setup = struct(); % environmental structure
        module = struct(); % module structure
        proj = struct(); % project structure
        util = struct(); % utility function handles
    end
    events
        msgEvent
    end
    methods
        %TDDO: Pretty sure this is uesless, double check then remove
        function obj = SignalFlowControl()
        end
        function obj = Startup( obj )
            %TODO: in Setup_AddPaths, autoload default projects dir 
            obj.Setup_AddPaths();

            obj.Setup_Messages();

            obj.Setup_DisplayVersion();

            obj.update_Git_Pull();

            obj.Setup_UtilityFunctions();
            
            obj.ModuleHandler('Initialize');
            obj.ProjectHandler('Initialize');


        end

        function update_Git_Pull ( obj )
            % Automatic Git Fetch and Pull

            % Define your Git repository path
            repositoryPath = obj.setup.sfdir;
            obj.msgSuccess(sprintf(''));
            
            % Run Git fetch
            system(['git -C "', repositoryPath, '" fetch --all']);
            
            % Check if there are new changes
            [~, result] = system(['git -C "', repositoryPath, '" status -uno']);
            if contains(result, 'diverged') || contains(result,'behind')
                response = input('Do you want to pull new changes? This will remove all local changes. (yes/no): ', 's');
                if strcmpi(response, 'yes')
                    % Run Git pull
                    system(['git reset --hard origin/main && git -C "', repositoryPath, '" pull --recurse-submodules']);
                    disp('New changes pulled successfully.');
                else
                    obj.msgSuccess(sprintf('No changes pulled.'));
                end
            else
                obj.msgSuccess(sprintf('No new changes found.'));
            end
        end

        function obj = Setup_AddPaths( obj )
          
            % Essential MATLAB Path Setup
            disp('Adding SignalFlow to MATLAB Path') %TODO: make new logger class type it out 
            try
                [obj.setup.sfdir, ~, ~] = fileparts(which(mfilename));
                addpath(genpath(obj.setup.sfdir));

                module_subfolders = {'Modules', 'UserModules'};

                % store path names
                obj.setup.sfdir             = obj.setup.sfdir;
                obj.setup.sfmoduledir         = fullfile(obj.setup.sfdir, module_subfolders{1});
                obj.setup.sfusermoduledir     = fullfile(obj.setup.sfdir, module_subfolders{2});   
            catch error
                obj.msgError(strcat('SignalFlowControl: Setup_AddPaths, Error:',obj.Util_PrintFormattedError(error)));
                return
            end
        end

        %TODO: Delete , this will be handled by the logger class
        function obj = Setup_Messages( obj )

            obj.proj.last_message = '';

        end

        % TODO: use logger class 
        function obj = Setup_DisplayVersion(obj)
            
            obj.setup.sfversion = '23.1';
            obj.setup.sfversion_label = sprintf('Version %s',  obj.setup.sfversion);

            obj.msgHeader(sprintf('SignalFlow %s', obj.setup.sfversion_label));
            obj.msgSuccess(sprintf('SignalFlow Folder: %s', obj.setup.sfdir));

        end

        function obj = Setup_UtilityFunctions(obj)

            obj.util.add_path_without_subfolders = @(filepath) addpath(fullfile(filepath));
            obj.util.add_path_with_subfolders = @(filepath) addpath(genpath(fullfile(filepath)));

        end

        function obj = Modules_ResetTargetArray( obj )
            obj.ModuleHandler('Modules_ResetTargetArray');
        end

        %TODO: THis will need to work with new hash system 
        function obj = Modules_AssignUniqueHashToMissing( obj )

            no_source = numel( obj.module.OriginalSourceModuleArray );
            no_user = numel(  obj.module.OriginalUserModuleArray );
            no_target = numel(  obj.module.TargetModuleArray );

            for i = 1 : no_source
                currentModule = obj.module.OriginalSourceModuleArray{i};
                hashcode = currentModule.hashcode;
                if ismissing(hashcode)
                    obj.module.OriginalSourceModuleArray{i}.tree = 'Source';
                    obj.module.OriginalSourceModuleArray{i}.hashcode = obj.generate_Hash();
                end

            end

            for i = 1 : no_user
                currentModule = obj.module.OriginalUserModuleArray{i};
                hashcode = currentModule.hashcode;
                if ismissing(hashcode)
                    obj.module.OriginalUserModuleArray{i}.tree = 'User';
                    obj.module.OriginalUserModuleArray{i}.hashcode = obj.generate_Hash();
                end
            end

            for i = 1 : no_target
                currentModule = obj.module.TargetModuleArray{i};
                hashcode = currentModule.hashcode;
                if ismissing(hashcode)
                    obj.module.TargetModuleArray{i}.tree = 'Target';
                    obj.module.TargetModuleArray{i}.hashcode = obj.generate_Hash();
                end
            end

            AllModuleArray = [ obj.module.OriginalSourceModuleArray obj.module.OriginalUserModuleArray obj.module.TargetModuleArray];

            obj.module.HashLibrary = [...
                cellfun(@(x) x.fname, AllModuleArray, 'UniformOutput', false)' ...
                cellfun(@(x) x.tree, AllModuleArray, 'UniformOutput', false)' ...
                cellfun(@(x) x.hashcode, AllModuleArray, 'UniformOutput', false)' ...
                cellfun(@(x) x.flowMode, AllModuleArray, 'UniformOutput', false)' ...
                cellfun(@(x) x.modfolder, AllModuleArray, 'UniformOutput', false)' ...
                cellfun(@(x) x.filename, AllModuleArray, 'UniformOutput', false)' ...
                 AllModuleArray'];

            obj.module.HashLibrary = cell2table( obj.module.HashLibrary , ...
                "VariableNames",{'fname','tree', 'hashcode', 'flowMode', 'modfolder', 'filename', 'class'});

            flowTypes = unique(obj.module.HashLibrary.flowMode);

          %  filtByFlowMode = @( flowMode ) obj.module.HashLibrary(strcmp(obj.module.HashLibrary.flowMode, flowMode), :);
            indexByFlowMode = @( flowMode ) strcmp(obj.module.HashLibrary.flowMode, flowMode);
          
           obj.module.filter_flowTypes = [flowTypes ; 'all'];

            % create filtered Modules
            for i = 1 : numel( obj.module.filter_flowTypes )
                currentFlowMode = obj.module.filter_flowTypes{i};

                if strcmp(currentFlowMode, 'all')
                    obj.module.filtered.(currentFlowMode) = true(height(obj.module.HashLibrary),1);
                else
                    obj.module.filtered.(currentFlowMode) = indexByFlowMode(currentFlowMode);
                end
            end

            refreshstr = sprintf('Module Refresh: Base %d | User %d | Pipeline %d', ...
                no_source, no_user, no_target);
            obj.msgIndent(refreshstr);
        
        end

        function obj = setModuleViewMode( obj, flowMode )

            view_index =  obj.module.filtered.(flowMode);
            hashlibrary = obj.module.HashLibrary(view_index, :);

            % Find the module groups based on the 'tree' column
            [groupingVariable, foundGroup] = findgroups(hashlibrary.tree);

            % check if either array is blank
            missingGroup = setdiff({'Source','User'}, foundGroup);

            % Define a function to gather colums
            collectRows = @(rows) {rows};

            % Apply the function to each group of rows in the 'Value' column
            moduleClasses = splitapply(collectRows, hashlibrary.class, groupingVariable);

            for i = 1 : numel(foundGroup)
                id = foundGroup{i};
                ModuleArray = moduleClasses{i}';
                switch id
                    case 'Source'
                        obj.module.SourceModuleArray = ModuleArray;
                    case 'User'
                        obj.module.UserModuleArray = ModuleArray;
                    case 'Target'
                end
            end
            for i = 1 : numel(missingGroup)
                id = missingGroup{i};
                switch id
                    case 'Source'
                        obj.module.SourceModuleArray = [];
                    case 'User'
                        obj.module.UserModuleArray = [];
                    case 'Target'
                end
            end
        end
        
        function obj = Modules_DisplayAvailable(obj)
            % Description: Displays the list of available modules.
            obj.ModuleHandler('Modules_DisplayAvailable');
        end

        function res = Modules_DisplayCount(obj)
            % Description: Returns the number of available modules.
            obj.ModuleHandler('checkNumberOfModules');
            res = obj.module.numOfModules;
        end

        function obj = Modules_LoadAvailable(obj)
            % Description: Displays the list of available modules.
            obj.ModuleHandler('Modules_LoadAvailable');
        end

        function obj = copyObjectByHash(obj, hash)
            % Description: Copies an object with the specified display name.
            obj.module.selectedHash = hash;
            obj.ModuleHandler('copyObjectByHash');
        end

        function obj = copyObjectByFuncName(obj, FuncName)
            % Description: Copies an object with the specified display name.
            obj.module.selectedFuncName = FuncName;
            obj.ModuleHandler('copyObjectByFuncName');
        end

        function obj = deleteObjectByHash(obj, hash)
            % Description: Deletes an object with the specified display name.
            obj.module.selectedHash = hash;
            obj.ModuleHandler('deleteObjectByHash');
        end
        
        function obj = setOutputDirectoryByHash(obj, hash,folder_tag)
            % Description: Deletes an object with the specified display name.
            obj.module.selectedHash = hash;
            OutputDir = obj.proj.(folder_tag);
            obj.ModuleHandler('setOutputDirectoryByHash',OutputDir);
        end

        function obj = reorderObjectArrayByHash(obj, hash, newIndex)
            % Description: Reorders an object array with the specified display name and new index.
            obj.module.selectedHash = hash;
            obj.ModuleHandler('reorderObjectArrayByHash', newIndex);
        end

        % Project Functions
        function obj = Project_AssignCustomFolder(obj, custom_path, tag)
            % Description: Assigns a subfolder to the project.

            % Create a string to use as a key in the obj.proj object
            folder_tag = sprintf('path_%s', tag);

            % Print a message to the console using the msgHeader method of the obj object
            obj.msgHeader('Project: Assign Tag to Custom Folder');

            % Create a formatted string for output to the console
            str = sprintf('<strong>%-*s</strong> | %-*s', 15, folder_tag, 30, custom_path);

            % Print the formatted string to the console using the msgIndent method of the obj object
            obj.msgIndent(str);

            % Check if the custom_path exists on the file system using the isfolder function
            if isfolder(custom_path)
                % If the custom_path exists, add it to the obj.proj object using the folder_tag key
                obj.proj.(folder_tag) = custom_path;
            else
                % If the custom_path doesn't exist, print an error message to the console using the msgError method of the obj object
                obj.msgError('Folder not found. Check path name.');
            end

            % Call the Project_CreateSubfolder function with the folder_tag value as an argument (this line is currently commented out)
            %obj.ProjectHandler('Project_CreateSubfolder', obj.proj.(folder_tag));
        end

        function obj = Project_ShowAllFileLists(obj)
            obj.ProjectHandler('Project_ShowAllFileLists');
        end

        function obj = Project_AssignImportFolder(obj, folder_path)
            % Description: Assigns an import folder.
            obj.ProjectHandler('Project_AssignImportFolder', folder_path);
        end

        function obj = Project_AssignTempFolder(obj, folder_path)
            % Description: Assigns an import folder.
            obj.ProjectHandler('Project_AssignTempFolder', folder_path);
        end

        function obj = Project_AssignResultsFolder(obj, folder_path)
            % Description: Assigns an import folder.
            obj.ProjectHandler('Project_AssignResultsFolder', folder_path);
        end

        function obj = Project_ResetFolders(obj)
            % Description: Assigns an import folder.
            obj.ProjectHandler('Project_ResetFolders');
        end

        function labelStruct = Project_GetFolderLabels( obj )

           [~, labelStruct] = obj.ProjectHandler('Project_GetFolderLabels');

        end

        function obj = Project_ListFolders(obj)
            % Description: Prints out the path fields of the custom project folders.
            obj.ProjectHandler('Project_ListFolders');

        end

        function obj = Project_UnassignFolders(obj)
            % Description: Clears the custom project folders.
            obj.ProjectHandler('Project_UnassignFolders');
        end

        function obj = Project_CreateImportFileList(obj, ext)
            % Description: Create file list from import directory
            if nargin < 2
                ext = '.set';
            end

            obj.ProjectHandler('Project_CreateImportFileList', ext);

        end

        function obj = Project_BrowseFilesystemAndCopyPathToClipboard(obj, rootdir)

            if nargin < 2
                rootdir = obj.setup.sfdir;
            end

            obj.ProjectHandler('Project_BrowseFilesystemAndCopyPathToClipboard', rootdir);
        end

        function str = Project_GetPathByTag(obj, folder_tag)
            % This function retrieves a folder path from a project structure based on a given tag.

            % Check if the target field name exists in the project structure
            if ~isfield(obj.proj, folder_tag)
                obj.msgError('Fieldname not found in the project structure.');
            end

            % Return the corresponding folder path
            str = obj.proj.(folder_tag);
        end

        % TODO: This is not used and should be removed
        function obj = Setup_DisplayMethods(obj)
            % This function displays the methods of an object by category, including setup, project, modules, and util.

            disp('Setup methods:');
            obj.regexpMethods('^Setup')
            disp('Project methods:');
            obj.regexpMethods('^Project')
            disp('Modules methods:');
            obj.regexpMethods('^Module')
            disp('Util methods:');
            obj.regexpMethods('^Util')

        end

        % TODO: This is not used and should be removed
        function regexpMethods(obj, pattern)
            % This function displays the methods of an object that match a regular expression pattern.

            allMethods = methods(obj);
            matchingMethods = allMethods(~cellfun(@isempty, regexp(allMethods, pattern)));
            disp(matchingMethods);

        end

        % TODO: This is not used and should be removed
        function obj = Project_CreateSubfolder(obj, rootfolder, newsubfolder)
            obj.msgHeader('Create New Project Folder');

            if nargin < 2
                obj.msgError('No folder input provided.')
                return;
            end

            if nargin < 3
                newpath = rootfolder;
                obj.msgWarning('No subfolder provided, will create root directory.')
                obj.ProjectHandler('Project_CreateSubfolder', newpath);
            else
                newpath = fullfile(rootfolder, newsubfolder);
                obj.ProjectHandler('Project_CreateSubfolder', newpath);
            end

        end

        function obj = Project_CreateImportFileListWithSubfolders(obj, ext)
            % Description: Create file list from import directory
            if nargin < 2
                ext = '.set';
            end

            obj.ProjectHandler('Project_CreateImportFileListWithSubfolders', ext);

        end

        function obj = Project_CreateCustomFileList(obj, path_custom)
            % Description: Create file list from import directory
            obj.ProjectHandler('Project_CreateCustomFileList', path_custom);

        end

        function obj = Project_CreateCustomFileListWithSubfolders(obj, path_custom)
            % Description: Create file list from import directory
            obj.ProjectHandler('Project_CreateCustomFileListWithSubfolders', path_custom);

        end

        function obj = Project_SaveAs(obj, outputDir, projName)
            % Description: Saves the project with a new name and output directory.
            obj.proj.output_dir = outputDir;
            obj.proj.name = matlab.lang.makeValidName(projName);
            obj.proj.save_file = fullfile(obj.proj.output_dir, strcat(obj.proj.name,'.json'));
            obj.saveApp(obj.proj.save_file)
        end

        function obj = Project_Save(obj)
            % Description: Saves the project. 
            %Todo: Add a check to see if the project has been saved before.
            %todo: make less redundant if saved already
            obj.proj.output_dir = outputDir;
            obj.proj.name = matlab.lang.makeValidName(projName);
            obj.proj.save_file = fullfile(obj.proj.output_dir, strcat(obj.proj.name,'.json'));
            obj.saveApp(obj.proj.save_file)
        end

        function obj = Project_Load(obj, inputFilename)
            % Description: Loads a project from a file.
            obj.proj.load_file = inputFilename;
            obj.Setup_AddPaths();
            obj.Setup_Messages();
            obj.Setup_DisplayVersion();
            obj.Setup_UtilityFunctions();
            obj.loadApp(inputFilename)
        end

        function obj = Project_SetName(obj, name)
            % Description: Sets the name of the project.
            obj.ProjectHandler('Project_SetName', name);
        end

        function obj = Project_SetAuthor(obj, author)
            % Description: Sets the author of the project.
            obj.ProjectHandler('Project_SetAuthor', author);
        end

        function obj = Project_SetDescription(obj, desc)
            % Description: Sets the description of the project.
            obj.ProjectHandler('Project_SetDescription', desc);
        end
        
        function obj = Project_SingleFileExecute(obj, filename)
            % Description: Execute the pipeline for single file.
            obj.ProjectHandler('Project_SingleFileExecute', filename)
        end

        function obj = Project_Execute(obj)
            % Description: Executes the project.
            obj.ProjectHandler('Project_Execute');
        end

        % TODO: Useless delete this 
        function obj = Project_BatchExecute(obj)

        end

        function obj = Project_ExecuteParallel(obj)
            % Description: Executes the project in parallel.
            obj.ProjectHandler('Project_ExecuteParallel');
        end

        % TODO: MAke this into a the functions that are called by the project handler
        function obj = ModuleHandler(obj, action, value)
            if nargin < 2
                value = missing;
            end

            refreshModuleTable = true;

            switch (action)

                case 'Initialize'
                    obj.module.TargetModuleArray = cell(1, 0);
                    obj.module.OriginalModuleArrayPopulated = false;
                    obj.ModuleHandler('Modules_LoadAvailable');
                    refreshModuleTable = false;

                case 'Modules_AssignToOriginalArray'
                    obj.msgIndent('Scanning available Base and User Modules.');
                    obj.module.OriginalSourceModuleArray = obj.module.TempSourceModuleArray;
                    obj.module.OriginalUserModuleArray = obj.module.TempUserModuleArray;
                    obj.module.OriginalModuleArray = obj.module.TempModuleList;
                    obj.module.OriginalModuleArrayPopulated = true;

                case 'Modules_AssignToUpdatedArray'
                    obj.msgIndent('Updating Module List');
                    obj.module.UpdatedSourceModuleArray = obj.module.TempSourceModuleArray;
                    obj.module.UpdatedUserModuleArray = obj.module.TempUserModuleArray;
                    obj.module.UpdatedModuleArray = obj.module.TempModuleList;

                case 'Modules_ReconcileOriginalAndUpdatedArrays'

                    fnames.('original') = cellfun(@(x) x.fname, obj.module.OriginalModuleArray, 'UniformOutput', false);
                    fnames.('updated') = cellfun(@(x) x.fname, obj.module.UpdatedModuleArray, 'UniformOutput', false);

                    hashcode.('original') = cellfun(@(x) x.hashcode, obj.module.OriginalModuleArray, 'UniformOutput', false);
                    hashcode.('updated') = cellfun(@(x) x.hashcode, obj.module.UpdatedModuleArray, 'UniformOutput', false);

                    diff = struct();
                    [diff.('lostmodules'), idx.('lostmodules')] = setdiff(fnames.('original') , fnames.('updated') ); % missing modules
                    [diff.('newmodules'), idx.('newmodules')] = setdiff( fnames.('updated') , fnames.('original') );  % added modules

                    total.('lostmodules') = numel(diff.('lostmodules'));
                    total.('newmodules') = numel(diff.('newmodules'));

                    if total.('lostmodules') == 0
                        obj.msgIndent('No deleted modules detected.');
                    else
                        obj.msgIndent(sprintf('%d modules removed.', total.('lostmodules')));
                    end

                    if total.('newmodules') == 0
                        obj.msgIndent('No new modules detected.');
                    else
                        obj.msgIndent(sprintf('%d new modules detected.', total.('newmodules')));
                        for mi = 1 : total.('newmodules')
                            % add module to User Module Array
                            module_script = diff.('newmodules'){mi};
                            obj.module.OriginalUserModuleArray{end+1} = eval(module_script);
                            obj.module.OriginalModuleArray{end+1} = eval(module_script);
                        end
                    end

                    obj.Modules_AssignUniqueHashToMissing;


                case 'Modules_LoadAvailable'
                    obj.msgHeader('Find and Load Available FlowFunction Modules');
                 
                    obj.module.TempSourceModuleArray = cell(1, 0);
                    obj.module.TempUserModuleArray = cell(1,0);

                    module_subfolders = {'Modules', 'UserModules'};
                   
                    for mi = 1 : numel(module_subfolders)
                        current_module_folder = fullfile(obj.setup.sfdir, module_subfolders{mi});
                        isValidFolder = isfolder(current_module_folder);
                        switch isValidFolder
                            case 0
                                msg = sprintf('%s folder not found. Check SignalFlow Paths', current_module_folder );
                                obj.msgFail(msg);
                            case 1
                                moduleList.(module_subfolders{mi}) = obj.getAllMFiles(current_module_folder);
                                module_total = size( moduleList.(module_subfolders{mi}), 1);
                                msg = sprintf('%s folder present with %d files.', module_subfolders{mi}, module_total);
                                obj.msgSuccess(msg);
                        end
                    end

                    module_source = fieldnames(moduleList);
                    for mi = 1 : numel(module_source)
                        module_current = module_source{mi};
                        module_list = moduleList.(module_current);

                        for si = 1 : size(module_list,1)

                           [~, module_script] =  fileparts(module_list{si});
                           module_cmd = sprintf('%s.is_module_file()', module_script);

                           try
                               is_valid_module = eval(module_cmd);
                           catch err
                               is_valid_module = false;
                               obj.msgWarning(obj.Util_PrintFormattedError(err));
                           end

                           if is_valid_module
                               switch module_current
                                   case 'Modules'
                                       obj.module.TempSourceModuleArray{end + 1} = eval(module_script);

                                   case 'UserModules'
                                       obj.module.TempUserModuleArray{end + 1} = eval(module_script);
                               end
                           else
                               obj.msgFail(sprintf('Invalid Module File | %s\n', module_script));
                           end
                        end
                    end
                    
                    obj.module.TempModuleList = [obj.module.TempSourceModuleArray  obj.module.TempUserModuleArray];

                    if ~obj.module.OriginalModuleArrayPopulated
                        obj.ModuleHandler('Modules_AssignToOriginalArray');
                    else
                        obj.ModuleHandler('Modules_AssignToUpdatedArray');
                        obj.ModuleHandler('Modules_ReconcileOriginalAndUpdatedArrays');
                    end

                    refreshModuleTable = false;

                case 'checkNumberOfModules'
                    try
                        obj.module.numOfModules = numel(obj.module.OriginalSourceModuleArray) + numel(obj.module.OriginalUserModuleArray);
                    catch error
                        obj.module.numOfModules = 0;
                        obj.msgError(strcat('SignalFlowControl: checkNumberOfModules, Error:',obj.Util_PrintFormattedError(error)));
                    end

                case 'Modules_DisplayAvailable'
                    % Define the width of each column
                    name_width = 35;
                    desc_width = 30;

                    fprintf('\n<strong>%-*s</strong>| ', name_width, 'FlowFunction');
                    fprintf('%-*s\n', desc_width, 'Description');
                    fprintf('<strong>%-*s</strong>| ', name_width, '-----------');
                    fprintf('%-*s\n', desc_width, '------------');

                    for i = 1:length(obj.module.SourceModuleArray)
                        % Print the name column
                        fprintf('<strong>%-*s</strong>| ', name_width, obj.module.SourceModuleArray{i}.fname);
                        fprintf('%-*s\n', desc_width, obj.module.SourceModuleArray{i}.displayName);
                    end

                    for i = 1:length(obj.module.UserModuleArray)
                        % Print the name column
                        fprintf('<strong>%-*s</strong>| ', name_width, obj.module.UserModuleArray{i}.fname);
                        fprintf('%-*s\n', desc_width, obj.module.UserModuleArray{i}.displayName);
                    end

                    fprintf('\n<strong>%-*s</strong>\n\n', name_width, 'Usage: [SignalFlow Object].[flowfunction(arguments)]');

                case 'copyObjectByFuncName'
                    FuncName = obj.module.selectedFuncName;

                    HashTable = obj.module.HashLibrary;
                    
                    NewTargetModuleInfo =HashTable(strcmp(HashTable.tree,'Source'), :);
                    NewTargetModuleInfo =NewTargetModuleInfo(strcmp(NewTargetModuleInfo.fname,FuncName), :);
                    if isempty(NewTargetModuleInfo)
                        NewTargetModuleInfo =HashTable(strcmp(HashTable.tree,'User'), :);
                        NewTargetModuleInfo =NewTargetModuleInfo(strcmp(NewTargetModuleInfo.fname,FuncName), :);
                    end
                    
                    if strcmp(NewTargetModuleInfo.flowMode, 'inflow')
                        isNewModuleInflow = true;
                    else
                        isNewModuleInflow = false;
                    end

                    % query the current target tree
                    TargetModuleInfo = HashTable(strcmp(HashTable.tree,'Target'), :);
                    if ~isempty(TargetModuleInfo) && isNewModuleInflow
                        TargetModuleInflowInfo = TargetModuleInfo(strcmp(TargetModuleInfo.flowMode{1}, 'inflow'),:);
                        target_inflow_num = height(TargetModuleInflowInfo);
                    else
                        target_inflow_num = 0;  % no inflow conflict
                    end

                    if target_inflow_num < 1
                        module_to_be_added =  feval(NewTargetModuleInfo.fname{1});
                        obj.module.TargetModuleArray{end + 1} = module_to_be_added;
                        obj.Modules_AssignUniqueHashToMissing();
                    else
                        obj.msgWarning('Adding more than one input module to the current pipeline is not permitted.');
                    end

                    HashTable = obj.module.HashLibrary;

                    % query the current target tree
                    TargetModuleInfoNew = HashTable(strcmp(HashTable.tree,'Target'), :);

                    if size(TargetModuleInfoNew,1) == (size(TargetModuleInfo,1) + 1)
                        str = sprintf('Success: added %s (%s) to Pipeline Builder.', TargetModuleInfoNew.fname{end}, TargetModuleInfoNew.hashcode{end});
                        obj.msgIndent(str);
                    else
                        str = sprintf('Module was not added to Pipeline Builder.');
                        obj.msgWarning(str);
                    end

                case 'Modules_ResetTargetArray'
                    obj.module.TargetModuleArray = cell(1, 0);

                case 'copyObjectByHash'
                    hash = obj.module.selectedHash;

                    HashTable = obj.module.HashLibrary;

                    NewTargetModuleInfo = ...
                        HashTable(strcmp(HashTable.hashcode,hash), :);

                    if strcmp(NewTargetModuleInfo.flowMode, 'inflow')
                        isNewModuleInflow = true;
                    else
                        isNewModuleInflow = false;
                    end

                    % query the current target tree
                    TargetModuleInfo = HashTable(strcmp(HashTable.tree,'Target'), :);
                    if ~isempty(TargetModuleInfo) && isNewModuleInflow
                        TargetModuleInflowInfo = TargetModuleInfo(strcmp(TargetModuleInfo.flowMode{1}, 'inflow'),:);
                        target_inflow_num = height(TargetModuleInflowInfo);
                    else
                        target_inflow_num = 0;  % no inflow conflict
                    end

                    if target_inflow_num < 1
                        module_to_be_added =  feval(NewTargetModuleInfo.fname{1});
                        obj.module.TargetModuleArray{end + 1} = module_to_be_added;
                        obj.Modules_AssignUniqueHashToMissing();
                    else
                        obj.msgWarning('Adding more than one input module to the current pipeline is not permitted.');
                    end

                    HashTable = obj.module.HashLibrary;

                    % query the current target tree
                    TargetModuleInfoNew = HashTable(strcmp(HashTable.tree,'Target'), :);

                    if size(TargetModuleInfoNew,1) == (size(TargetModuleInfo,1) + 1)
                        str = sprintf('Success: added %s (%s) to Pipeline Builder.', TargetModuleInfoNew.fname{end}, TargetModuleInfoNew.hashcode{end});
                        obj.msgIndent(str);
                    else
                        str = sprintf('Module was not added to Pipeline Builder.');
                        obj.msgWarning(str);
                    end

                case 'deleteObjectByHash'
                    hash = obj.module.selectedHash;
                    found = false;

                    for i = 1:length(obj.module.TargetModuleArray)

                        if strcmp(obj.module.TargetModuleArray{i}.hashcode, hash)
                            found = true;
                            break;
                        end

                    end

                    if found
                        obj.module.TargetModuleArray = [obj.module.TargetModuleArray(1:i - 1), obj.module.TargetModuleArray(i + 1:end)];
                        obj.msgSuccess(strcat('Object deleted from the target array. hashcode:', hash));
                    else
                        obj.msgWarning(strcat('Object not found in the target array. hashcode:', hash));
                    end

                case 'setOutputDirectoryByHash'
                    hash = obj.module.selectedHash;
                    found = false;

                    for i = 1:length(obj.module.TargetModuleArray)

                        if strcmp(obj.module.TargetModuleArray{i}.hashcode, hash)
                            found = true;
                            break;
                        end

                    end

                    if found
                        obj.module.TargetModuleArray{i}.fileIoVar = value;
                    else
                        obj.msgWarning(strcat('Object not found in the target array. hashcode:', hash));
                    end

                case 'reorderObjectArrayByHash'
                    hash = obj.module.selectedHash;
                    newIndex = value;
                    % Find the index of the object in the array
                    objIndex = -1;

                    for i = 1:length(obj.module.TargetModuleArray)

                        if strcmp(obj.module.TargetModuleArray{i}.hashcode, hash)
                            objIndex = i;
                            break;
                        end

                    end

                    % If the object is not found in the array, display an error message
                    if objIndex == -1
                        obj.msgWarning('Object not found in the target array');
                        return;
                    end

                    % Check if newIndex is greater than the length of the array
                    if newIndex > length(obj.module.TargetModuleArray)
                        newIndex = length(obj.module.TargetModuleArray);
                    end

                    % Remove the object from its current position
                    tempObj = obj.module.TargetModuleArray{objIndex};
                    obj.module.TargetModuleArray = [obj.module.TargetModuleArray(1:objIndex - 1), obj.module.TargetModuleArray(objIndex + 1:end)];

                    % Insert the object at the new position, shifting other elements down
                    obj.module.TargetModuleArray = [obj.module.TargetModuleArray(1:newIndex - 1), {tempObj}, obj.module.TargetModuleArray(newIndex:end)];

                otherwise
                    obj.msgWarning(strcat('Invalid action:', action))
            end

            if refreshModuleTable
              %  obj.Modules_LoadAvailable;
                obj.Modules_AssignUniqueHashToMissing;
            end
        end

        %TODO: Delete this and put into functions 
        function [obj, result] = ProjectHandler(obj, action, value)

            if nargin < 2
                value = missing;
            end

            result = missing;

            switch (action)

                case 'Initialize'

                    % Initialize the project metadata properties to "missing".

                    obj.proj.name = missing;
                    obj.proj.desc = missing;
                    obj.proj.author = missing;

                    obj.ProjectHandler('Project_InitializeFolders');
                
                case 'Project_InitializeFolders'

                    obj.proj.path_autosave = missing;
                    obj.proj.path_import = missing;
                    obj.proj.path_temp = missing;
                    obj.proj.path_results = missing;
                
                case 'Project_CreateSubfolder'

                    % Check if subfolder already exists in root directory.
                    subfolderPath = value;

                    if exist(subfolderPath, 'dir') == 7
                        obj.msgWarning(sprintf('Subfolder already exists: %s', subfolderPath));
                        return;
                    else
                        % Create subfolder in root directory.
                        mkdir(subfolderPath)
                    end

                case 'Project_AssignImportFolder'
                    % Check if subfolder already exists in root directory.
                    obj.msgHeader('Assign Import Folder:');

                    folderPath = value;

                    if exist(folderPath, 'dir') == 7
                        obj.proj.path_import = value;
                        obj.msgIndent(sprintf('Path: %s', value));
                        obj.msgIndent(sprintf('Available via tag <strong>path_import</strong>'));
                        return;
                    else
                        obj.msgWarning(strcat('Folder not found:', folderPath));
                    end


                case 'Project_AssignResultsFolder'
                    % Check if subfolder already exists in root directory.
                    obj.msgHeader('Assign Main Results Folder:');

                    folderPath = value;

                    if exist(folderPath, 'dir') == 7
                        obj.proj.path_results = value;
                        obj.msgIndent(sprintf('Path: %s', value));
                        obj.msgIndent(sprintf('Available via tag <strong>path_results</strong>'));
                        return;
                    else
                        obj.msgWarning(strcat('Folder not found:', folderPath));
                    end

                case 'Project_AssignTempFolder'
                    % Check if subfolder already exists in root directory.
                    obj.msgHeader('Assign Temporary Folder:');

                    folderPath = value;

                    if exist(folderPath, 'dir') == 7
                        obj.proj.path_temp = value;
                        obj.msgIndent(sprintf('Path: %s', value));
                        obj.msgIndent(sprintf('Available via tag <strong>path_temp</strong>'));
                        return;
                    else
                        obj.msgWarning(strcat('Folder not found:', folderPath));
                    end
                    
                case 'Project_GetFolderLabels'
                    fields = fieldnames(obj.proj);
                    count = false;

                    pathcount = 1;
                    folderLabelStruct = [];

                    for i = 1:numel(fields)

                        if (ischar(obj.proj.(fields{i})) || ismissing(obj.proj.(fields{i})))  && contains(fields{i}, 'path')
                            folderLabelStruct(pathcount).tag = fields{i};
                            folderLabelStruct(pathcount).folder = obj.proj.(fields{i});
                            % obj.msgIndent(sprintf('<strong>%s:</strong> %s', fields{i}, obj.proj.(fields{i})));
                            count = true;
                            pathcount = pathcount + 1;
                        end

                    end

                    if ~count
                        obj.msgWarning('No Project Folders Available');
                    end

                    result = folderLabelStruct;

                case 'Project_ListFolders'
                    obj.msgHeader('List of User-Defined Project Paths:');
                    fields = fieldnames(obj.proj);
                    count = false;

                    for i = 1:numel(fields)

                        if ischar(obj.proj.(fields{i})) && contains(fields{i}, 'path')
                            obj.msgIndent(sprintf('<strong>%s:</strong> %s', fields{i}, obj.proj.(fields{i})));
                            count = true;
                        end

                    end

                    if ~count
                        obj.msgWarning('No Project Folders Available');
                    end

                case 'Project_UnassignFolders'

                    obj.msgHeader(' User-Defined Project Folder Reset.');
                    fields = fieldnames(obj.proj);
                    count = false;

                    for i = 1:numel(fields)

                        if ischar(obj.proj.(fields{i})) && contains(fields{i}, 'path')
                            obj.msgIndent(sprintf('%s: %s (Removed)', fields{i}, obj.proj.(fields{i})));
                            obj.proj = rmfield(obj.proj, fields{i});
                            count = true;
                        end

                    end

                    if ~count
                     %   obj.msgIndent('No Project Folders Available.');
                    end

                case 'Project_ResetFolders'
                    obj.msgHeader('Reset Project Folders');
                    obj.ProjectHandler('Project_InitializeFolders');

                case 'Project_SetName'
                    obj.proj.name = value;

                case 'Project_SetAuthor'
                    obj.proj.author = value;

                case 'Project_SetDescription'
                    obj.proj.desc = value;

                case 'Project_CreateImportFileList'
                    obj.msgHeader('Create Import FileList from Path')

                    ext = value;
                    obj.proj.filelist_import = util_sfDirListing(obj.proj.path_import, ...
                        'ext', ext);
                    obj.msgIndent(sprintf('<strong>filelist_import</strong> created from %s', obj.proj.path_import));
                    obj.ProjectHandler('Project_CountFileList', obj.proj.filelist_import);

                case 'Project_CreateImportFileListWithSubfolders'
                    obj.msgHeader('Create Import FileList from Path (including Subfolders)');

                    ext = value;
                    obj.proj.filelist_import = util_sfDirListing(obj.proj.path_import, ...
                        'ext', ext, 'subdirOn', true);
                    obj.msgIndent(sprintf('<strong>filelist_import</strong> created from %s', obj.proj.path_import));
                    obj.ProjectHandler('Project_CountFileList', obj.proj.filelist_import);

                case 'Project_CreateCustomFileList'
                    obj.msgHeader('Create Custom FileList of *.SET from Path');
                    path_custom = value;
                    file_custom = sprintf('filelist_%s', path_custom);
                    obj.proj.(file_custom) = util_sfDirListing(obj.proj.(path_custom), 'ext', '.set');
                    obj.msgIndent(sprintf('<strong>%s</strong> created from %s', file_custom, obj.proj.path_import));
                    obj.ProjectHandler('Project_CountFileList', obj.proj.(file_custom));

                case 'Project_CreateCustomFileListWithSubfolders'
                    obj.msgHeader('Create Custom FileList of *.SET from Path (including Subfolders)');
                    path_custom = value;
                    file_custom = sprintf('filelist_%s', path_custom);
                    obj.proj.(file_custom) = util_sfDirListing(obj.proj.(path_custom), 'ext', '.set', 'subdirOn', true);
                    obj.msgIndent(sprintf('<strong>%s</strong> created from %s', file_custom, obj.proj.path_import));
                    obj.ProjectHandler('Project_CountFileList', obj.proj.(file_custom));

                case 'Project_CountFileList'
                    filelist = value;

                    if isempty(filelist)
                        file_count = 0;
                    else
                        file_count = size(filelist, 1);
                    end

                    obj.msgIndent(sprintf('%d Files Found.', file_count));

                case 'Project_ShowAllFileLists'
                    obj.msgHeader('List all SignalFlowEEG FileLists:');
                    fields = fieldnames(obj.proj);
                    count = false;

                    for i = 1:numel(fields)
                        if contains(fields{i}, 'filelist')
                            filelist_count = size(obj.proj.(fields{i}), 1);
                            obj.msgIndent(sprintf('<strong>%s:</strong> %d files', fields{i}, filelist_count));
                            count = true;
                        end
                    end

                    if ~count
                        obj.msgWarning('No Files Available');
                    end

                case 'Project_BrowseFilesystemAndCopyPathToClipboard'
                    rootdir = value;

                    if isfolder(rootdir)
                        % Browse file system and copy selected folder path to clipboard
                        obj.msgHeader('Browse and Select Folder and Copy to Clipboard')
                        [foldername] = uigetdir(rootdir, 'Select a folder');

                        if isequal(foldername, 0)
                            obj.msgWarning('User pressed cancel');
                        else
                            folderpath = foldername;
                            obj.msgIndent(['Selected folder: ', folderpath]);
                            clipboard('copy', folderpath);
                            obj.msgIndent('Folder path copied to clipboard');
                            obj.msgIndent('<strong>Usage:</strong> sfObject.Project_AssignCustomFolder(''<PATH_NAME>'', ''<TAG>'');');
                        end

                    else
                        obj.msgError('Starting folder not found.');
                    end
                
                case 'Project_SingleFileExecute'
                    success = obj.clearAutoSaveFolder();
                    if ~success
                        return; 
                    end
                    filename = value;
                    filename = strcat(obj.proj.path_import, filesep, filename);

                    if exist(filename, 'file') == 2
                        obj.singleFileExecute(filename)
                    end
            

                case 'Project_Execute'
                    success = obj.clearAutoSaveFolder();
                    if ~success
                        return; 
                    end

                    importDir = obj.proj.path_import;
                    dirContents = dir(importDir);
                    dirContents = dirContents(~[dirContents.isdir]);
                    
                    validExt = {'.set', '.raw', '.edf'};
                    x = 1;

                    while x <= length(dirContents)
                        importFile = fullfile(dirContents(x).folder, dirContents(x).name);
                        [~, ~, fileExt] = fileparts(importFile);
                        if ismember(fileExt, validExt)
                            x = x + 1;  % Move on to the next entry if the file extension is valid
                        else
                            dirContents(x) = [];  % Remove the entry if the file extension is not valid
                        end
                    end
                    
%                     pb = util_sfProgressBar(length(dirContents));

                    for x = 1:length(dirContents)                 
                        obj.singleFileExecute(strcat(dirContents(x).folder, filesep, dirContents(x).name));
%                         pb.iter(x);
                    end
%                     pb.close();
%                     delete(pb);

                case 'Project_ExecuteParallel'
                    success = obj.clearAutoSaveFolder();
                    if ~success
                        return; 
                    end
                    importDir = obj.proj.path_import;
                    dirContents = dir(importDir);
                    dirContents = dirContents(~[dirContents.isdir]);
                    
                    validExt = {'.set', '.raw', '.edf'};
                    x = 1;

                    while x <= length(dirContents)
                        importFile = fullfile(dirContents(x).folder, dirContents(x).name);
                        [~, ~, fileExt] = fileparts(importFile);
                        if ismember(fileExt, validExt)
                            x = x + 1;  % Move on to the next entry if the file extension is valid
                        else
                            dirContents(x) = [];  % Remove the entry if the file extension is not valid
                        end
                    end
                    
                    % Create the progress bar object
%                     pb = util_sfProgressBar(length(dirContents));
                    
                    % Create a DataQueue object
                    dq = parallel.pool.DataQueue;
                    
                    % Set up the afterEach function to update the progress bar
                    idx = 1;
%                     afterEach(dq, @(~) pb.iter(idx))

                    parfor x = 1:length(dirContents)                 
                        obj.singleFileExecute(strcat(dirContents(x).folder, filesep, dirContents(x).name));
                        % Send data to the DataQueue
                        send(dq, x);
                        
                        % Update the index for the afterEach function
                        idx = idx + 1;
                    end

                    % Close the progress bar figure when the loop is done
%                     pb.close();
%                     delete(pb);

                otherwise
                    obj.msgWarning(strcat('Invalid action:', action))
            end
        end

        % TODO: Not used delete this
        function EEGCell = Project_ImportFileList(obj, method)

            fl = obj.proj.filelist_import;
            fl.fullname = fullfile(fl.filepath, fl.filename);
            fl_length = size(fl, 1);

            filelist = fl.fullname;
            EEGCell = cell(fl_length, 1);

            parfor i = 1:fl_length

                filename = filelist{i};
                EEG = obj.importHelper(method, filename);
                EEGCell{i} = EEG;

            end

        end

        % TODO: Not used delete this
        function EEGCell = Project_AnalyzeFileList(obj, method, filelist_tag)
            obj.msgHeader('Run Signal Analysis on Filelist by Tag');
            obj.msgIndent(sprintf('Function: <strong>%s,</strong>', method));

            % validate filelist_tag
            proj_fields = fields(obj.proj);
            filelist_indexes = contains(proj_fields,'filelist');

            if contains(proj_fields(filelist_indexes), filelist_tag)
                fl = obj.proj.(filelist_tag);
                filelist_count = size(fl, 1);
                obj.msgIndent(sprintf('<strong>%s</strong> filelist is valid with %d files.', filelist_tag,filelist_count));
            else
                obj.msgError('FileList Tag Not Found. Available Filelists.')
                obj.Project_ShowAllFileLists;
            end

            % validate method/function name
            % TBD

            fl.fullname = fullfile(fl.filepath, fl.filename);
            fl_length = size(fl, 1);

            filelist = fl.fullname;
            EEGCell = cell(fl_length, 1);

            for i = 1:fl_length

                filename = filelist{i};
                EEG = obj.analysisHelper(method, filename);
                EEGCell{i} = EEG;

            end

        end

        % TODO: Not used delete this
        function obj = Project_EegExportSet(obj, EEGCell, Project_Folder)
            obj.msgHeader('| Export EEG to Project Folder As SET\n');

            % Input parser
            p = inputParser;
            addRequired(p, 'EEGCell', @(x) iscell(x));
            addRequired(p, 'Project_Folder', @(x) ischar(x));
            parse(p, EEGCell, Project_Folder);
            p = p.Results;

            EEGCell = p.EEGCell;

            try
                Project_Folder = obj.proj.(p.Project_Folder);
            catch
                obj.msgWarning(sprintf('  <strong>%s</strong> is not a designated Project Folder.\n', p.Project_Folder));
                obj.msgWarning(sprintf('  Use <strong>Project_AssignCustomFolder</strong> or choose from below:\n\n', p.Project_Folder));
                obj.Project_ListFolders;
                return;
            end

            EEGCell_length = numel(EEGCell);

            for i = 1:EEGCell_length

                EEG = EEGCell{i};
                filename = EEG.filename;

                try
                    pop_saveset(EEG, 'filename', filename, 'filepath', Project_Folder);
                    fprintf('Success: <strong>%s</strong>\n', filename);
                catch
                    msg = sprintf("saving <strong>%s</strong>", filename);
                    obj.msgWarning(msg);
                end

            end

        end
        
        function success = clearAutoSaveFolder(obj)
            try
                % Get folder labels
                labelStruct = obj.Project_GetFolderLabels;
        
                % Find the pathAutoSave folder
                pathAutoSaveTag = 'path_autosave';
                pathAutoSaveFolder = find(strcmp({labelStruct.tag}, pathAutoSaveTag), 1);
        
                % Check if pathAutoSave folder is not empty
                if ~isempty(dir(labelStruct(pathAutoSaveFolder).folder))
                    % Folder is not empty, prompt user
                    choice = questdlg("Please note that the autosave folder is not empty. Are you sure you want to proceed and potentially overwrite existing files? If you prefer a different folder, please create it and associate it with 'path_autosave' in the setup tab", ...
                                        'Warning', 'Proceed', 'Cancel', 'Cancel');
        
                    % Handle user choice
                    if strcmp(choice, 'Proceed')
                        % Empty the folder
                        rmdir(labelStruct(pathAutoSaveFolder).folder, 's');
                        % Recreate the folder
                        mkdir(labelStruct(pathAutoSaveFolder).folder);
                    else
                        % Exit the function without further processing
                        success = false;
                        return;
                    end
                end
                % Operation completed successfully
                success = true;
            catch
                % Error occurred during the operation
                success = false;
            end
        end


        function obj = singleFileExecute(obj, importFile)
            %TODO Logging needs to be implemented
            % The main issue with this is SO mant conditions and if else statements. This is not a good practice.
            % This function is responsible for executing a single file based on the input file's
            % extension, and running the pipeline defined by the TargetModuleArray.
            % We should seperate the conditions and if else statements into different functions and call them from here.
            % This will make the code more readable and maintainable.
            %TODO: RIp this code apart and make it more readable and maintainable.

            % This function is responsible for executing a single file based on the input file's
            % extension, and running the pipeline defined by the TargetModuleArray.
        
            % Extract the file extension from the given input file.
            [~, ~, fileExtension] = fileparts(importFile);
            % Define an array of valid file extensions that the function can process.
            validExtensions = {'.set', '.raw', '.edf'};
            labelStruct = obj.Project_GetFolderLabels;


            % Check if the file extension of the input file is within the valid extensions.
            if ismember(fileExtension, validExtensions)
                % Set the input file path for the first TargetModule.
                obj.module.TargetModuleArray{1}.fileIoVar = importFile;
                % Check if the input file exists and update the boolValidImportFile flag.
                boolValidImportFile = exist(obj.module.TargetModuleArray{1}.fileIoVar, 'file') == 2;               
                % If both the input file and output directory are valid, execute the pipeline.
                if boolValidImportFile
                    % Run the first TargetModule.
                    EEG = obj.module.TargetModuleArray{1}.run(); 
                    obj.module.TargetModuleArray{1}.endEEG = EEG;
                    if ~isempty(EEG)
                        % Iterate through the rest of the TargetModuleArray and execute each module.
                        for i = 2:length(obj.module.TargetModuleArray)
                            if strcmp(obj.module.TargetModuleArray{i}.flowMode, 'outflow')
                                
                                pathInTag = any(strcmp({labelStruct.folder}, obj.module.TargetModuleArray{i}.fileIoVar));                            
                                if ~pathInTag
                                    pathResultsIdx = find(strcmp({labelStruct.tag}, 'path_results'), 1);
                            
                                    if ~isempty(pathResultsIdx) && ~isempty(labelStruct(pathResultsIdx).folder)
                                        obj.module.TargetModuleArray{i}.fileIoVar = labelStruct(pathResultsIdx).folder;
                                    end
                                end
                            end
                            obj.module.TargetModuleArray{i}.beginEEG = EEG;
                            if strcmp(obj.module.TargetModuleArray{i}.fname,'outflow_AutoSave')
                                EEG = obj.module.TargetModuleArray{i}.run(obj.module.TargetModuleArray{i-1}, i);
                            else
                                EEG = obj.module.TargetModuleArray{i}.run();
                            end
                            obj.module.TargetModuleArray{i}.endEEG = EEG;
                        end
                    end
                end        
            end
        end



        % TODO: maybe not used, double check and delete if not used
        function Setup_StoreCustomPaths(obj, path)
            % Add a path to the MATLAB path

            % Validate path
            validateattributes(path, {'char'}, {'nonempty'}, 'Setup_AddPath', 'path');
            assert(isfolder(path), 'Path must be a folder.');
            % Log a custom path in the environment variables

            % Generate valid MATLAB filename stem
            [~, folderName] = fileparts(path);
            validFolderName = matlab.lang.makeValidName(folderName);

            % Store path in setup property
            obj.setup.paths_user.(validFolderName) = path;
        end

        % TODO: not used, delete
        function Setup_PrintCustomPaths(obj)
            % Print the setup property as a table

            % Convert struct to table
            setupTable = struct2table(obj.setup.paths_user);

            % Extract variable names and values
            varNames = setupTable.Properties.VariableNames;
            varValues = table2cell(setupTable);

            % Create new table with variable names and values
            setupTable_long = table(varNames', varValues', 'VariableNames', {'Custom Path', 'Value'});

            % Print table
            obj.msgHeader('User added MATLAB paths');
            disp(setupTable_long);
        end

        % TODO: maybe not used, double check and delete if not used
        function Project_CheckMissing(obj)
            % Validate the project metadata and report any missing or invalid fields.
            obj.proj.detailsAreComplete = false;

            obj.msgHeader('Set Project Details:');

            % Check project name
            if ismissing(obj.proj.name)
                obj.msgWarning('Project Name: missing');
            else
                obj.msgIndent(sprintf('Project Name: %s', obj.proj.name));
                obj.proj.detailsAreComplete = true;
            end

            % Check project author
            if ismissing(obj.proj.author)
                obj.msgWarning('Project Author: missing');
            else
                fprintf('  Project Author: %s\n', obj.proj.author);
                obj.proj.detailsAreComplete = true;
            end

            % Check project description
            if ismissing(obj.proj.desc)
                obj.msgWarning('Project Description: missing');
            else
                fprintf('  Project Description: %s\n', obj.proj.desc);
                obj.proj.detailsAreComplete = true;
            end

        end

        function fileList = getAllMFiles(obj, folder)
            moduleFileList = util_sfDirListing(folder, 'ext', '.m', 'subDirOn', true);
            if ~isempty(moduleFileList)
                moduleFileList.fullfile = fullfile(moduleFileList.filepath, moduleFileList.filename);
                fileList = moduleFileList.fullfile;

            else
                obj.msgWarning('No user modules found.');
                fileList = [];
            end
        end

        %TODO: All of these should be removed and changes with logger class. These are faulty abd error prone.
        function str = msgHeader(obj, str)
            cprintf('*Blue', '\n| %s\n', str);
       
            str = sprintf('<font color="blue"><br><strong>%s | %s</strong></font>',obj.lead_message(), str) ;
            obj.proj.last_message =  [str obj.proj.last_message];
            notify(obj, 'msgEvent');
         %   obj.consoleOutputToHtml('cprintf(''*blue'', ''| %s\n'', str)'');');
        end

        function msgWarning(obj, str)
            cprintf('*[255, 140, 0]', '[Warning: %s]\n', str);
            str = sprintf('<font color="#FF8C00"><br><strong>%s * Warning: %s<strong></font>',obj.lead_message(),  str) ;
            obj.proj.last_message =  [str obj.proj.last_message];
            notify(obj, 'msgEvent');
        end

        function msgError(obj, str)
            cprintf('*red', '[Error: %s]\n', str);
            str = sprintf('<font color="red"><br><strong>%s * Error: %s</strong></font>',obj.lead_message(), str) ;
            obj.proj.last_message =  [str obj.proj.last_message];
            notify(obj, 'msgEvent');
        end

        function msgIndent(obj, str)
            fprintf('  %s\n', str);
            str = sprintf('<font color="black"><br>%s | %s</font>',obj.lead_message(), str) ;
            obj.proj.last_message =  [str obj.proj.last_message];
            notify(obj, 'msgEvent');
        end

        function msgSuccess(obj, str)
            if nargin < 2
                str = '';
            else
            end
            cprintf('*green', sprintf('  Success: %s\n', str));
            str = sprintf('<font color="green"><br><strong>%s | Pass: </strong></font><font color="black">%s</font>',obj.lead_message(),str) ;
            obj.proj.last_message =  [str obj.proj.last_message];
            notify(obj, 'msgEvent');
        end

        function msgFail(obj, str)
            if nargin < 2
                str = '';
            else
            end
            cprintf('*red', sprintf('  Fail: %s\n', str));
            str = sprintf('<font color="red"><br><strong>%s * Fail: </strong></font><font color="black">%s</font>',obj.lead_message(),str) ;
            obj.proj.last_message =  [str obj.proj.last_message];
            notify(obj, 'msgEvent');
        end

        function html_str = msgHtmlLog( obj )
            html_str =   obj.proj.last_message;
        end
        function obj = msgHtmlLogClear( obj )
              obj.proj.last_message = '';
        end

        function obj = consoleOutputToHtml(obj, msg)
            % Redirect the MATLAB console output to a string using evalc
            consoleOutput = evalc(msg);

            % Replace special characters in the console output with their HTML entity counterparts
            %   consoleOutput = strrep(consoleOutput, '&', '&amp;');
            %   consoleOutput = strrep(consoleOutput, '<', '&lt;');
            %   consoleOutput = strrep(consoleOutput, '>', '&gt;');

            % Wrap the modified console output in a <pre> tag to maintain the original formatting
            htmlOutput = ['<html><body>' consoleOutput '</body></html>'];

            % Set the HTML content of the UIHTML element
            % app.UIHTMLComponent.HTML = htmlOutput;
            obj.proj.CurrentConsoleMessage = htmlOutput;
        end

        function saveApp(obj, jsonFilePath)
            jsonData = transformToJsonData(obj);
            obj.saveJSONData(jsonFilePath, jsonData);
        end
        
        function obj = loadApp(obj,jsonFilePath)
            jsonData = obj.loadJSONData(jsonFilePath);
            obj =  obj.setLoadData(jsonData);
        end
        
        % functions needed for save
        function saveJSONData(~,jsonFilePath, jsonData) 
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
        
        function jsonData = transformToJsonData(obj)
            jsonData = struct;
        
            % get proj info
            jsonData.proj = struct;
            jsonData.proj.name = obj.proj.name;
            jsonData.proj.description = obj.proj.desc;
            jsonData.proj.author = obj.proj.author;
            % get proj path tags from the app
            for y=1:length(fieldnames(obj.proj))
                    
                % for each field that have 'fileIO' in the name
                currentFields = fieldnames(obj.proj);
                if contains(currentFields{y}, 'path_')
                    jsonData.proj.pathTags.(currentFields{y}) = obj.proj.(currentFields{y});
                end
            end
        
            % get module info
            jsonData.TargetModuleArray = struct;
            for x=1:length(obj.module.TargetModuleArray)
                % displayName
                jsonData.TargetModuleArray(x).displayName = obj.module.TargetModuleArray{x}.displayName;
                % defauleHash
                % jsonData.TargetModuleArray(x).defauleHash = App.module.TargetModuleArray(x).defauleHash;
                % fname
                jsonData.TargetModuleArray(x).fname = obj.module.TargetModuleArray{x}.fname;
                % isUserModule
                jsonData.TargetModuleArray(x).isUserModule = obj.module.TargetModuleArray{x}.isUserModule;
                %fileSaveVars
                jsonData.TargetModuleArray(x).fileSaveVars = struct;
                % for each field that have 'fileIO' in the name
        
                for y=1:length(fieldnames(obj.module.TargetModuleArray{x}))
                    
                    % for each field that have 'fileIO' in the name
                    currentFields = fieldnames(obj.module.TargetModuleArray{x});
                    if contains(currentFields{y}, 'fileIo')
                        jsonData.TargetModuleArray(x).fileSaveVars.(currentFields{y}) = obj.module.TargetModuleArray{x}.(currentFields{y});
                    end
                    
                    
                end
        
            end
        end
        
        
        % functions needed for load
        function jsonData = loadJSONData(~,jsonFilePath) 
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
        
        function obj = setLoadData(obj,jsonData)
            % Set the data from the JSON file to the app
            if isempty(jsonData.proj.name)
                jsonData.proj.name = missing;
            end
            if isempty(jsonData.proj.description)
                jsonData.proj.description = missing;
            end
            if isempty(jsonData.proj.author)
                jsonData.proj.author = missing;
            end
            obj.proj.name = jsonData.proj.name;
            obj.proj.desc = jsonData.proj.description;
            obj.proj.author = jsonData.proj.author;

            % set the path tags
            %  for each field in jsonData.proj.pathTags
            currentFields = fieldnames(jsonData.proj.pathTags);
            for y=1:length(fieldnames(jsonData.proj.pathTags))
                % Set the path tags from the JSON file to the app
                if isempty(jsonData.proj.pathTags.(currentFields{y}))
                    jsonData.proj.pathTags.(currentFields{y}) = missing;
                end
                obj.proj.(currentFields{y}) = jsonData.proj.pathTags.(currentFields{y});
            end

            % set the module data
            for x=1:length(jsonData.TargetModuleArray)
                %  Initialize the module data by function 
                % TODO maybe change to hash once we have default one 
                obj.module.selectedFuncName = jsonData.TargetModuleArray(x).fname;
                obj.ModuleHandler('copyObjectByFuncName');
                obj.module.TargetModuleArray{x}.displayName = jsonData.TargetModuleArray(x).displayName;
                obj.module.TargetModuleArray{x}.fname = jsonData.TargetModuleArray(x).fname;
                obj.module.TargetModuleArray{x}.isUserModule = jsonData.TargetModuleArray(x).isUserModule;
                %fileSaveVars
                currentFieldNames = fieldnames(jsonData.TargetModuleArray(x).fileSaveVars);
                for y=1:length(fieldnames(jsonData.TargetModuleArray(x).fileSaveVars))
                    obj.module.TargetModuleArray{x}.(currentFieldNames{y}) = jsonData.TargetModuleArray(x).fileSaveVars.(currentFieldNames{y});
                end
            end
        end
    end

    methods (Static)
        % TODO: move to logger class
        function msg = Util_PrintFormattedError( err )
            msg = getReport(err, 'basic');
            msg = regexprep(msg, {'\n\s*', '\n\n+'}, {' ', '\n'});
            msg = regexprep(msg, '<a.*?>|</a>', '');
        end

        % TODO: move to logger class
        function msg = lead_message() 
            msg = datestr(now, 'yyyy/mm/dd HH:MM:SS');
        end

        % TODO: This is a duplicate of the function in the super class 
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

        % TODO: not used, delete
        function EEG = importHelper(method, filename)

            opts = struct();
            EEG = struct();
            opts.(method).rawfile = filename;
            importModule = feval(method, EEG, opts);
            %EEG = importModule.validate();
            EEG = importModule.run();

        end

        % TODO: not used, delete
        function EEG = analysisHelper(method, filename)

            opts = struct();
            EEG = struct();
            opts.(method).rawfile = filename;

            EEG = pop_loadset(filename);

            Module = feval(method, EEG, opts);
            EEG = Module.run();

        end

        % TODO: move to logger class
        function msg(str, formatcode)
            % Check if the formatting code was provided
            if nargin < 2
                formatcode = missing; % If not, set it to 'missing'
            end

            % Check if the formatting code is missing
            if ismissing(formatcode)
                fprintf('%s\n', str); % If so, print the string using fprintf
            else
                cprintf(formatcode, '%s\n', str); % If not, print the string with the specified color or formatting using cprintf
            end
        end
    end
end
