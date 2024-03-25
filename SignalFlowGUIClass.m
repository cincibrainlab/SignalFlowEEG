classdef SignalFlowGUIClass
    %SIGNALFLOWGUI Summary of this class goes here
    %   Detailed explanation goes here
    % TODO: Add description of the class
    properties
        %TODO , comment with uses of each property
        SelectedModule
        sfControl
        spectraFig
        guisetup

        msgListener

    end

    methods
        %TODO, useless constructor
        function obj = SignalFlowGUIClass()
        end

        function updateTextbox( obj, app )
            str = obj.sfControl.proj.last_message;
            source =  sprintf('<html><body style="background-color: white; font-family: Arial, Helvetica, sans-serif;"">%s</body></html>', str);
            app.SetupHtmlArea.HTMLSource = source;
            app.BuilderHtmlArea.HTMLSource = source;
            app.ExecuteHtmlArea.HTMLSource = source;
            app.BrowseHtmlArea.HTMLSource = source;
        end

        function obj = Startup(obj,app)

            % assign GUI to base workspace
            assignin('base', 'sfapp', app);

            % start sf controller
            obj.sfControl = SignalFlowControl();
            obj.msgListener = addlistener(obj.sfControl, 'msgEvent', @(~,~) obj.updateTextbox(app));
            obj.sfControl.Startup;

            app.SignalFlowVersionLabel.Text = obj.sfControl.setup.sfversion_label;

            % Create a progress dialog
            app.progressDialog = uiprogressdlg(app.SignalFlowEEGUIFigure, 'Title', 'Loading App', ...
                'Message', 'Please wait...', 'Cancelable', 'off', ...
                'Indeterminate', 'on');

            % Initialize the progress value
            app.progress = 0;
            obj.guisetup.isLoading = true;

            while obj.guisetup.isLoading

                % Fake loading, just to mess with the user's head
                app.progress = .5;
                app.progressDialog.Value = app.progress;
                app.progressDialog.Message = sprintf('Loading Startup functions... (%.0f%%)', app.progress * 100);


                % Load Modules
                obj.refreshTrees(app);
                obj.reloadPlugins(app)
                obj.reloadCustomPaths(app);
                obj.guisetup.isLoading = false;

                app.progress = 1;
                app.progressDialog.Value = app.progress;
                app.progressDialog.Message = sprintf('Loading Startup functions... (%.0f%%)', app.progress * 100);
            end
            pause(1);
            close(app.progressDialog);
        end

        %TODO, make this into search box 
        function obj = FilterViewByFlowType( obj, app)
            if  isempty(app.BuilderModuleFilterDropDown.Items)

                filter_options = obj.sfControl.module.filter_flowTypes;
                app.BuilderModuleFilterDropDown.Items = filter_options;
                %  app.BuilderModuleFilterDropDown.Value = filter_options{end};
            end
            flowTypeDropDownValue = app.BuilderModuleFilterDropDown.Value;
            obj.sfControl.setModuleViewMode(flowTypeDropDownValue);
        end

        function buttonEnableCheck(obj, app)
            selectedTabTitle = app.TabGroup.SelectedTab.Title;

            switch selectedTabTitle
                case 'Setup'
                    % No changes here
                case 'Builder'
                    setBuilderButtonStates(obj, app);
                case 'Execute'
                    setExecuteButtonStates(obj, app);
                case 'Browse'
                    setBrowseButtonStates(obj, app);
            end

            function setBuilderButtonStates(obj, app)
                try
                    parentModule = obj.SelectedModule.Parent;
                    isSourceTree = (parentModule == app.SourceTree || parentModule == app.UserSourceTree);
                    isTargetTree = (parentModule == app.TargetTree);

                    setButtonEnableState(app, {'AddFunctionButton'}, isSourceTree);
                    setButtonEnableState(app, {'DeleteFunctionButton'}, isTargetTree);
                catch
                    setButtonEnableState(app, {'AddFunctionButton', 'DeleteFunctionButton', 'OutputFolderTagDropDown','ModuleNameEditField', 'DefaultButton', 'UpdateButton'}, false);
                end
            end

            function setExecuteButtonStates(obj, app)
                executeSetFileButtons = {'OpeninEEGLABButton', 'PlotDataButton', 'ViewChannelSpectraButton', 'ViewElectrodeMapButton'};
                executeImportFolderButtons = {'ExecuteLoopButton', 'ExecuteParallelButton'};

                try
                    moduleText = obj.SelectedModule.Text;
                    parentModuleText = obj.SelectedModule.Parent.Text;
                    [~, ~, ext] = fileparts(moduleText);

                    hasSetExtension = contains(moduleText, '.set');
                    hasimportExtension = any(strcmp(ext, {'.set', '.raw', '.xdat', '.edf'}));
                    isInImportFolder = contains(parentModuleText, 'Import');

                    app.ExecuteFileButton.Enable = (hasimportExtension) && isInImportFolder;

                    setButtonEnableState(app, executeSetFileButtons, hasSetExtension);
                catch
                    setButtonEnableState(app, [executeSetFileButtons, {'ExecuteFileButton'}], false);
                end

                hasImportPath = isfield(obj.sfControl.proj, 'path_import') && ~isempty(obj.sfControl.proj.path_import);
                hasImportModule = ~isempty(obj.sfControl.module.TargetModuleArray) && strcmp(obj.sfControl.module.TargetModuleArray{1, 1}.flowMode,'inflow') && hasImportPath;
                setButtonEnableState(app, executeImportFolderButtons, hasImportModule);
                try
                    if ~isempty(obj.SelectedModule.NodeData)
                        app.OpenExportFolderButton.Enable = true;
                    else
                        app.OpenExportFolderButton.Enable = false;
                    end
                catch
                    app.OpenExportFolderButton.Enable = false;
                end
            end

            function setBrowseButtonStates(obj, app)
                executeSetFileButtons = {'ButtonBrowseSpectra', 'ButtonBrowseElectrode', 'ButtonBrowsePlot', 'ButtonBrowseEeglab'};
                try
                    moduleText = obj.SelectedModule.Text;
                    hasSetExtension = contains(moduleText, '.set');

                    setButtonEnableState(app, executeSetFileButtons, hasSetExtension);
                catch
                    setButtonEnableState(app, [executeSetFileButtons, {'ExecuteFileButton'}], false);
                end

                try
                    if ~isempty(obj.SelectedModule.NodeData)
                        app.OpenSelectedFolderButton.Enable = true;
                    else
                        app.OpenSelectedFolderButton.Enable = false;
                    end
                catch
                    app.OpenSelectedFolderButton.Enable = false;
                end
            end

            function setButtonEnableState(app, buttonNames, enableStates)
                if isscalar(enableStates)
                    enableStates = repmat(enableStates, size(buttonNames));
                end

                for idx = 1:numel(buttonNames)
                    app.(buttonNames{idx}).Enable = enableStates(idx);
                end
            end
        end

        function obj = resetPipeline( obj, app)
            app.AddFunctionButton.Enable = false;
            app.DeleteFunctionButton.Enable = false;
            app.OutputFolderTagDropDown.Enable = false;
            app.ModuleNameEditField.Enable = false;
            app.DefaultButton.Enable = false;
            app.UpdateButton.Enable = false;
            obj.sfControl.Modules_ResetTargetArray();
            obj.refreshTargetTree(app)
        end

        function refreshSetupFileListTree(obj, app)
            delete(app.SetupFileListTree.Children);

            labelStruct = obj.sfControl.Project_GetFolderLabels;
            % Find the index of the 'path_results' label in the labelStruct array.
            for i =1 : numel(labelStruct)
                if ~ismissing(labelStruct(i).folder)
                    module = uitreenode(app.SetupFileListTree, 'Text', sprintf("%s: %s", labelStruct(i).tag, obj.sfControl.proj.(labelStruct(i).tag)));
                    createFileModules(obj.sfControl.proj.(labelStruct(i).tag), module);
                end
            end

            %TODO duplicate function, merge them 
            function createFileModules(folderPath, parentModule)

                folderContents = dir(folderPath);

                for c = 1:numel(folderContents)
                    entry = folderContents(c);

                    if strcmp(entry.name, '.') || strcmp(entry.name, '..')
                        continue;
                    end

                    [~, ~, ext] = fileparts(entry.name);

                    if any(strcmp(ext, {'.set', '.raw', '.xdat', '.edf', '.parquet', '.csv'})) %TODO add all file extensions
                        fileModule = uitreenode(parentModule, 'Text', entry.name,'NodeData', fullfile(entry.folder,filesep,entry.name));
                    end
                end

                expand(app.SetupFileListTree, 'all');
            end
        end

        function refreshSourceTree(obj, app)
            % Refresh Source Tree
            delete(app.SourceTree.Children);

            obj.sfControl.module.GenericTree = app.SourceTree;
            obj.sfControl.module.GenericTreeModules = obj.sfControl.module.SourceModuleArray;
            n = numel(obj.sfControl.module.GenericTreeModules);

            if n > 0
                obj.addModulesToSourceTree();
            end

            expand(app.SourceTree, 'all');
        end

        function obj = addModulesToSourceTree( obj )

            GenericTree =  obj.sfControl.module.GenericTree;
            GenericTreeModules =  obj.sfControl.module.GenericTreeModules;
            n = numel(obj.sfControl.module.GenericTreeModules);

            arrayfun(@(i) uitreenode(GenericTree, ...
                'Text', strcat(GenericTreeModules{i}.displayName, ' (', GenericTreeModules{i}.hashcode, ')'), ...
                'NodeData',obj.sfControl.module.GenericTreeModules{i}.hashcode), 1:n, 'UniformOutput', false);

            obj.sfControl.module.GenericTree = [];
            obj.sfControl.module.GenericTreeModules = [];
        end

        function refreshUserModuleFiles(obj, app)
           % obj.sfControl.Module_RefreshUserModuleFiles();
            obj.sfControl.Modules_LoadAvailable();
            obj.refreshTrees(app);
        end

        function refreshUserModuleTree(obj, app) %obj.module.UserModuleArray
            % Refresh Source Tree
            delete(app.UserSourceTree.Children);
            obj.sfControl.module.GenericTree = app.UserSourceTree;
            obj.sfControl.module.GenericTreeModules = obj.sfControl.module.UserModuleArray;
            n = numel(obj.sfControl.module.UserModuleArray);

            if n > 0
                obj.addModulesToSourceTree();
            end

            expand(app.UserSourceTree, 'all');
        end

        function refreshTargetTree(obj,app)
            % Refresh Target Tree
            delete(app.TargetTree.Children);
            obj.sfControl.module.GenericTree = app.TargetTree;
            obj.sfControl.module.GenericTreeModules = obj.sfControl.module.TargetModuleArray;
            n = numel(obj.sfControl.module.TargetModuleArray);

            if n > 0
                obj.addModulesToSourceTree();
            end

            expand(app.TargetTree,'all')
        end

        function refreshSExecuteWorkflowTree(obj, app)
            % Refresh Target Tree
            delete(app.ExecuteWorkflowTree.Children);
            obj.sfControl.module.GenericTree = app.ExecuteWorkflowTree;
            obj.sfControl.module.GenericTreeModules = obj.sfControl.module.TargetModuleArray;
            n = numel(obj.sfControl.module.TargetModuleArray);

            if n > 0
                obj.addModulesToSourceTree();
            end

            expand(app.ExecuteWorkflowTree,'all')
        end

        function refreshExecuteTree(obj, app)
            % Refresh Execute Tree
            delete(app.ExecuteTree.Children);

            n = length(obj.sfControl.module.TargetModuleArray);

            if isfield(obj.sfControl.proj, 'path_import')
                if ~ismissing(obj.sfControl.proj.path_import)
                    addpath(obj.sfControl.proj.path_import);
                end
            end
            if ~ismissing(obj.sfControl.proj.path_results)
                addpath(obj.sfControl.proj.path_results);
            end
            for i = 1:n
                currentTargetModule = obj.sfControl.module.TargetModuleArray{i};
                moduleText = strcat(currentTargetModule.displayName, ' (', currentTargetModule.hashcode, ')');

                labelStruct = obj.sfControl.Project_GetFolderLabels;
                % Find the index of the 'path_results' label in the labelStruct array.
                pathResults = strcmp({labelStruct.folder}, currentTargetModule.fileIoVar);

                if contains(currentTargetModule.fname, 'inflow')
                    module = uitreenode(app.ExecuteTree, 'Text', strcat(moduleText,' Folder Tag: [',labelStruct(pathResults).tag,']'));
                    if isfield(obj.sfControl.proj, 'path_import') && ~isempty(obj.sfControl.proj.path_import)
                        createFileModules(obj.sfControl.proj.path_import, module);
                    end
                end

                if contains(currentTargetModule.fname, 'outflow')
                    module = uitreenode(app.ExecuteTree, 'Text', strcat(moduleText,' Folder Tag: [',labelStruct(pathResults).tag,']'), 'NodeData', currentTargetModule.fileIoVar);
                    if isfield(obj.sfControl.proj, 'path_results') && ~isempty(obj.sfControl.proj.path_results)
                        createFileModules(obj.sfControl.proj.path_results, module);
                    end
                end
            end

            expand(app.ExecuteTree, 'all');

            %TODO duplicate function, merge them
            function createFileModules(folderPath, parentModule)

                if ismissing(folderPath)
                    obj.sfControl.msgWarning('Import folder not found. Are project folders assigned?');
                    return;
                else
                    folderContents = dir(folderPath);
                end

                for c = 1:numel(folderContents)
                    entry = folderContents(c);

                    if strcmp(entry.name, '.') || strcmp(entry.name, '..')
                        continue;
                    end

                    [~, ~, ext] = fileparts(entry.name);

                    if any(strcmp(ext, {'.set', '.raw', '.xdat', '.edf', '.parquet', '.csv'})) %TODO add all file extensions
                        fileModule = uitreenode(parentModule, 'Text', entry.name,'NodeData', fullfile(entry.folder,filesep,entry.name));
                    end
                end
            end
        end

        function refreshTrees(obj,app)
            obj.buttonEnableCheck(app)
            obj.FilterViewByFlowType(app)
            obj.refreshSetupFileListTree(app)
            obj.refreshExecuteTree(app)
            obj.refreshSExecuteWorkflowTree(app)
            obj.refreshSourceTree(app)
            obj.refreshUserModuleTree(app)
            obj.refreshTargetTree(app)
        end

        function TabChanged(obj, app)
            selectedTabTitle = app.TabGroup.SelectedTab.Title;

            switch selectedTabTitle
                case 'Setup'
                    obj.refreshSetupFileListTree(app);

                case 'Builder'
                    app.AddFunctionButton.Enable = false;
                    app.DeleteFunctionButton.Enable = false;
                    app.OutputFolderTagDropDown.Enable = false;
                    app.ModuleNameEditField.Enable = false;
                    app.DefaultButton.Enable = false;
                    app.UpdateButton.Enable = false;

                    obj.refreshSourceTree(app);
                    obj.refreshUserModuleTree(app);
                    obj.refreshTargetTree(app);

                case 'Execute'
                    app.OpeninEEGLABButton.Enable = false;
                    app.PlotDataButton.Enable = false;
                    app.ViewChannelSpectraButton.Enable = false;
                    app.ViewElectrodeMapButton.Enable = false;
                    app.ExecuteFileButton.Enable = false;
                    app.OpenExportFolderButton.Enable = false;

                    executeImportFolderButtons = {'ExecuteLoopButton', 'ExecuteParallelButton'};
                    hasImportPath = isfield(obj.sfControl.proj, 'path_import') && ~isempty(obj.sfControl.proj.path_import);
                    hasImportModule = ~isempty(obj.sfControl.module.TargetModuleArray) && strcmp(obj.sfControl.module.TargetModuleArray{1, 1}.flowMode,'inflow') && hasImportPath;

                    for c = 1:numel(executeImportFolderButtons)
                        app.(executeImportFolderButtons{c}).Enable = hasImportModule;
                    end

                    obj.refreshExecuteTree(app);
                    obj.refreshSExecuteWorkflowTree(app)

                case 'Browse'
                    app.ButtonBrowseSpectra.Enable = false;
                    app.ButtonBrowseElectrode.Enable = false;
                    app.ButtonBrowsePlot.Enable = false;
                    app.ButtonBrowseEeglab.Enable = false;
                    app.OpenSelectedFolderButton.Enable = false;
                    obj.refreshBrowseFileCatalog(app);
            end
        end

        %TODO, make logger class and all try catck blocks can be merged into one
        function obj = setupEditProjectInformationSave(obj,app)
            try
                obj.sfControl.proj.name = app.TitleEditField.Value;
                obj.sfControl.msgSuccess('Project name has been sucessfully saved')
            catch error
                obj.sfControl.msgWarning('Project name failed to save')
                obj.sfControl.msgError(strcat('SignalFlowGUIClass: setupEditProjectInformationSave, Error:',obj.sfControl.Util_PrintFormattedError(error)));
            end
            try
                obj.sfControl.proj.desc = app.DescriptionEditField.Value;
                obj.sfControl.msgSuccess('Project description has been sucessfully saved')
            catch error
                obj.sfControl.msgWarning('Project description failed to save')
                obj.sfControl.msgError(strcat('SignalFlowGUIClass: setupEditProjectInformationSave, Error:',obj.sfControl.Util_PrintFormattedError(error)));
            end
            try
                obj.sfControl.proj.author = app.AuthorEditField.Value;
                obj.sfControl.msgSuccess('Project author has been sucessfully saved')
            catch error
                obj.sfControl.msgWarning('Project author failed to save')
                obj.sfControl.msgError(strcat('SignalFlowGUIClass: setupEditProjectInformationSave, Error:',obj.sfControl.Util_PrintFormattedError(error)));
            end
        end

        %TODO, make logger class. all try catck blocks can be merged into one
        function obj = setupEditProjectInformationLoad(obj,app)
            try
                if ~ismissing(obj.sfControl.proj.name)
                    app.TitleEditField.Value = obj.sfControl.proj.name;
                    obj.sfControl.msgSuccess('Project name has been sucessfully loaded')
                else
                    obj.sfControl.msgWarning('Project name is missing')
                end
            catch error
                obj.sfControl.msgWarning('Project name failed to load')
                obj.sfControl.msgError(strcat('SignalFlowGUIClass: setupEditProjectInformationLoad, Error:',obj.sfControl.Util_PrintFormattedError(error)));
            end
            try
                if ~ismissing(obj.sfControl.proj.name)
                    app.DescriptionEditField.Value = obj.sfControl.proj.desc;
                    obj.sfControl.msgSuccess('Project description has been sucessfully loaded')
                else
                    obj.sfControl.msgWarning('Project description is missing')
                end
            catch error
                obj.sfControl.msgWarning('Project description failed to load')
                obj.sfControl.msgError(strcat('SignalFlowGUIClass: setupEditProjectInformationLoad, Error:',obj.sfControl.Util_PrintFormattedError(error)));
            end
            try
                if ~ismissing(obj.sfControl.proj.name)
                    app.AuthorEditField.Value = obj.sfControl.proj.author;
                    obj.sfControl.msgSuccess('Project author has been sucessfully loaded')
                else
                    obj.sfControl.msgWarning('Project author is missing')
                end
            catch error
                obj.sfControl.msgWarning('Project author failed to load')
                obj.sfControl.msgError(strcat('SignalFlowGUIClass: setupEditProjectInformationLoad, Error:',obj.sfControl.Util_PrintFormattedError(error)));
            end
        end

        function obj = refreshBrowseFileCatalog(obj, app)

            % Find the folder corresponding to the target tag
            tagMatch = strcmp({obj.sfControl.Project_GetFolderLabels.tag}, app.DropDownFolderPicker.Value);
            tagIndex = find(tagMatch, 1); % Find the index of the first match
            tmpArray = obj.sfControl.Project_GetFolderLabels;
            starting_folder = tmpArray(tagIndex).folder; % Access the folder field at the found index

            obj.updateUITreeWithFolder(app, app.BrowseFileCatalog, starting_folder);

        end

        function updateUITreeWithFolder(obj, app, uitree, folderPath)
            if ismissing(folderPath)
                obj.sfControl.msgWarning('Folder path is missing. Please provide a valid folder path.');
                return
            end

            % Update UITree with files and subfolders from a given folder path
            delete(uitree.Children);

            % Get folder name and create a root node with the folder name
            [~, folderName, ~] = fileparts(folderPath);
            rootNode = uitreenode(uitree, 'Text', folderName, 'NodeData', folderPath);

            % Call the helper function to populate the UITree
            populateTree(rootNode, folderPath);

            % Expand only the root node
            expand(rootNode);

            function populateTree(parentNode, currentFolderPath)
                % Update UITree with files and subfolders from a given folder path

                folderContents = dir(currentFolderPath);

                for c = 1:numel(folderContents)
                    entry = folderContents(c);

                    if strcmp(entry.name, '.') || strcmp(entry.name, '..')
                        continue;
                    end

                    if entry.isdir
                        % If entry is a directory, create a folder node and recursively add its contents
                        folderNode = uitreenode(parentNode, 'Text', entry.name, 'NodeData', fullfile(entry.folder,filesep,entry.name));
                        subFolderPath = fullfile(currentFolderPath, entry.name);
                        populateTree(folderNode, subFolderPath);
                    else
                        % If entry is a file, create a file node with metadata
                        createFileModules(parentNode, entry.name, currentFolderPath);
                    end
                end
            end

            function createFileModules(parentModule, fileName, folderPath)
                [~, ~, ext] = fileparts(fileName);

                if any(strcmp(ext, {'.set', '.raw', '.xdat', '.edf', '.parquet', '.csv'})) %TODO add all file extensions
                    fileModule = uitreenode(parentModule, 'Text', fileName,'NodeData', fullfile(folderPath,filesep,fileName));
                end
            end
        end

        function shutdown(obj,app)
            delete(app)
            % clear all - keep workspace intact on app shutdown
        end

        function forceshutdown(obj,app)
            set(0,'ShowHiddenHandles','on')
            delete(get(0,'Children'))
        end
        

        function checkAutoSaveModuleAndPath(obj, app)
            % Check if the text of obj.SelectedModule contains 'auto save'
            if contains(lower(obj.SelectedModule.Text), 'auto save')
                % Check if TargetModuleArray contains at least one element
                if isempty(obj.sfControl.module.TargetModuleArray)
                    uialert(app.SignalFlowEEGUIFigure, 'Failed to add the Auto Save module. Please ensure that there is at least one module.', 'Error', 'Icon', 'error');
                    error('Failed to add the Auto Save module. Please ensure that there is at least one module.');
                end
        
                % Find the index of 'path_autosave' label in the labelStruct array.
                labelStruct = obj.sfControl.Project_GetFolderLabels;
                pathAutoSave = strcmp({labelStruct.tag}, 'path_autosave');
        
                % Check if 'path_autosave' label is missing
                if ismissing(labelStruct(pathAutoSave).folder)
                    uialert(app.SignalFlowEEGUIFigure, 'Failed to add the Auto Save module. Please set the folder for Auto Save in the setup tab.', 'Error', 'Icon', 'error');
                    error('Failed to add the Auto Save module. Please set the folder for Auto Save.');
                end

            end
        end



        function obj = addModule(obj,app)
            try
                hash = obj.SelectedModule.NodeData;
                checkAutoSaveModuleAndPath(obj, app);
                obj.sfControl = obj.sfControl.copyObjectByHash(hash);

                if strcmp(obj.sfControl.module.TargetModuleArray{end}.fname,'outflow_AutoSave')
                    labelStruct = obj.sfControl.Project_GetFolderLabels;
                    % Find the index of the 'path_results' label in the labelStruct array.
                    pathAutoSave = strcmp({labelStruct.tag}, 'path_autosave');
                    % Set the output directory of the last TargetModule to the folder corresponding to the 'path_results' label.
                    if ~ismissing(labelStruct(pathAutoSave).folder)
                        obj.sfControl.module.TargetModuleArray{end}.fileIoVar = labelStruct(pathAutoSave).folder;
                    end
                elseif strcmp(obj.sfControl.module.TargetModuleArray{end}.flowMode,'outflow') && isempty(obj.sfControl.module.TargetModuleArray{end}.fileIoVar)
                    labelStruct = obj.sfControl.Project_GetFolderLabels;
                    % Find the index of the 'path_results' label in the labelStruct array.
                    pathResults = strcmp({labelStruct.tag}, 'path_results');
                    % Set the output directory of the last TargetModule to the folder corresponding to the 'path_results' label.
                    if ~ismissing(labelStruct(pathResults).folder)
                        obj.sfControl.module.TargetModuleArray{end}.fileIoVar = labelStruct(pathResults).folder;
                    end
                elseif strcmp(obj.sfControl.module.TargetModuleArray{end}.flowMode,'inflow')
                    labelStruct = obj.sfControl.Project_GetFolderLabels;
                    % Find the index of the 'path_results' label in the labelStruct array.
                    pathResults = strcmp({labelStruct.tag}, 'path_import');
                    % Set the output directory of the last TargetModule to the folder corresponding to the 'path_results' label.
                    if ~ismissing(labelStruct(pathResults).folder)
                        obj.sfControl.module.TargetModuleArray{end}.fileIoVar = labelStruct(pathResults).folder;
                    end
                end
                obj.refreshTargetTree(app);
            catch error
                obj.sfControl.msgError(strcat('SignalFlowGUIClass: addModule, Error:',obj.sfControl.Util_PrintFormattedError(error)));
                return
            end
        end

        function obj = deleteModule(obj,app)
            try
                hash = obj.SelectedModule.NodeData;
                obj.sfControl = obj.sfControl.deleteObjectByHash(hash);
                obj.refreshTargetTree(app);
            catch error
                obj.sfControl.msgError(strcat('SignalFlowGUIClass: deleteModule, Error:',obj.sfControl.Util_PrintFormattedError(error)));
                return
            end
        end

        function obj = moveModuleUp(obj,app)
            try 
                % Get the currently selected module
                tempSelectedModule = obj.SelectedModule;

                if isempty(tempSelectedModule) || isempty(tempSelectedModule.Parent)
                    return;
                end

                parentModule = tempSelectedModule.Parent;
                siblings = parentModule.Children;
                moduleIndex = find(siblings == tempSelectedModule);
                newIndex = moduleIndex - 1;

                hash = tempSelectedModule.NodeData;
                obj.sfControl = obj.sfControl.reorderObjectArrayByHash(hash, newIndex);

                obj.refreshTargetTree(app);
            catch error
                obj.sfControl.msgError(strcat('SignalFlowGUIClass: moveModuleUp, Error:',obj.sfControl.Util_PrintFormattedError(error)));
                return
            end
        end

        function obj = moveModuleDown(obj,app)
            try
                % Get the currently selected module
                tempSelectedModule = obj.SelectedModule;

                if isempty(tempSelectedModule) || isempty(tempSelectedModule.Parent)
                    return;
                end

                parentModule = tempSelectedModule.Parent;
                siblings = parentModule.Children;
                moduleIndex = find(siblings == tempSelectedModule);
                newIndex = moduleIndex + 1;

                hash = tempSelectedModule.NodeData;
                obj.sfControl = obj.sfControl.reorderObjectArrayByHash(hash, newIndex);
                obj.refreshTargetTree(app);
            catch error
                obj.sfControl.msgError(strcat('SignalFlowGUIClass: moveModuleDown, Error:',obj.sfControl.Util_PrintFormattedError(error)));
                return
            end
        end

        function obj = treeSelect(obj,tree,app)
            % obj.CreateHashLibrary(app);
            obj.SelectedModule = tree.SelectedNodes;
            %Checks if NodeData is Module (with hash) or file viewer (with file io location) 
            if isfolder(obj.SelectedModule.NodeData) || isfile(obj.SelectedModule.NodeData) % file viewer (with file io location) 
                %
                disp('')
            elseif length(obj.SelectedModule.NodeData) == 6 % Module (with hash)
                HashTable = obj.sfControl.module.HashLibrary;
                obj.sfControl.module.CurrentModuleHash = obj.SelectedModule.NodeData;
                obj.sfControl.module.CurrentModuleInfo = HashTable(strcmp(HashTable.hashcode, obj.SelectedModule.NodeData), :);
                try
                    obj.showCode(app);
                catch error
                    obj.sfControl.msgError(strcat('SignalFlowGUIClass: treeSelect, Error:',obj.sfControl.Util_PrintFormattedError(error)));
                end
                obj.moduleChangePropertiesLoad(app,tree.SelectedNodes);
            else
                obj.sfControl.msgWarning('Unknown data in SelectedModule.NodeData');
            end
            obj.buttonEnableCheck(app)
        end

        function obj = moduleChangePropertiesConfirm(obj, app)
            hash = obj.SelectedModule.NodeData;
            targetModuleArray = obj.sfControl.module.TargetModuleArray;
            targetModuleIndex = [];

            for i = 1:length(targetModuleArray)
                if strcmp(targetModuleArray{i}.hashcode, hash)
                    targetModuleIndex = i;
                    break;
                end
            end

            if ~isempty(targetModuleIndex)
                targetModule = targetModuleArray{targetModuleIndex};
                targetModule.displayName = app.ModuleNameEditField.Value;
                if strcmp(targetModule.flowMode, 'outflow')
                    labelStruct = obj.sfControl.Project_GetFolderLabels;
                    folderLabelIndex = strcmp({labelStruct.tag}, app.OutputFolderTagDropDown.Value);
                    targetModule.fileIoVar = labelStruct(folderLabelIndex).folder;
                end
            end
            obj.refreshTargetTree(app)
        end

        function obj = moduleChangePropertiesDefault(obj, app)
            hash = obj.SelectedModule.NodeData;
            targetModuleArray = obj.sfControl.module.TargetModuleArray;
            targetModuleIndex = [];

            for i = 1:length(targetModuleArray)
                if strcmp(targetModuleArray{i}.hashcode, hash)
                    targetModuleIndex = i;
                    break;
                end
            end

            if ~isempty(targetModuleIndex)
                targetModule = targetModuleArray{targetModuleIndex};
                targetModule.displayName = targetModule.setup.flabel;
                app.ModuleNameEditField.Value = targetModule.setup.flabel;
                if strcmp(targetModule.flowMode, 'outflow')
                    labelStruct = obj.sfControl.Project_GetFolderLabels;
                    folderLabelIndex = strcmp({labelStruct.tag}, 'path_results');

                    if any(folderLabelIndex)
                        app.OutputFolderTagDropDown.Value = 'path_results';
                        targetModule.fileIoVar = labelStruct(folderLabelIndex).folder;
                    end
                end
            end
            obj.refreshTargetTree(app)
        end

        function obj = moduleChangePropertiesLoad(obj, app,SelectedModule)
            try
                labelStruct = obj.sfControl.Project_GetFolderLabels;
                labelStructCellArray = {};
                for t =1:numel(labelStruct)
                    labelStructCellArray{t} = labelStruct(t).tag;
                end
                app.OutputFolderTagDropDown.Items = labelStructCellArray;


                %tempSelectedModuleText = split(SelectedModule.Text,'(');
                % hash = split(tempSelectedModuleText{2},')');
                hash = SelectedModule.NodeData;
                found = false;
                for i = 1:length(obj.sfControl.module.TargetModuleArray)
                    if strcmp(obj.sfControl.module.TargetModuleArray{i}.hashcode, hash)
                        found = true;
                        break;
                    end
                end
                if found
                    app.ModuleNameEditField.Value = obj.sfControl.module.TargetModuleArray{i}.displayName;
                    app.ModuleNameEditField.Enable = true;
                    app.DefaultButton.Enable = true;
                    app.UpdateButton.Enable = true;

                    if strcmp(obj.sfControl.module.TargetModuleArray{i}.fname,'outflow_AutoSave')
                        app.OutputFolderTagDropDown.Enable = false;
                        app.ModuleNameEditField.Enable = false;
                        app.DefaultButton.Enable = false;
                        app.UpdateButton.Enable = false;
                        app.OutputFolderTagDropDown.Value = 'path_autosave';
                    elseif strcmp(obj.sfControl.module.TargetModuleArray{i}.flowMode,'outflow')
                        app.OutputFolderTagDropDown.Enable = true;
                        for x =1:numel(labelStruct)
                            if strcmp(labelStruct(x).folder, obj.sfControl.module.TargetModuleArray{i}.fileIoVar)
                                app.OutputFolderTagDropDown.Value = labelStruct(x).tag;
                                return
                            else
                                app.OutputFolderTagDropDown.Value = 'path_results';
                            end
                        end
                    else
                        app.OutputFolderTagDropDown.Enable = false;

                    end
                else
                    app.ModuleNameEditField.Enable = false;
                    app.DefaultButton.Enable = false;
                    app.UpdateButton.Enable = false;
                end
            catch
                app.OutputFolderTagDropDown.Enable = false;
                app.ModuleNameEditField.Enable = false;
                app.DefaultButton.Enable = false;
                app.UpdateButton.Enable = false;
            end
        end

        function obj = showCode(obj,app)

            % Load PrismJS library
            prismCss = fileread('prism.css');
            prismJs = fileread('prism.js');

            moduleFile = obj.sfControl.module.CurrentModuleInfo.filename{1};

            labelText = fileread(moduleFile);

            % Format code snippet
            codeSnippetHTML = sprintf('<pre><code class="language-matlab">%s</code></pre>', labelText);

            % Create the HTML content
            htmlContent = sprintf('<html><head><style>%s</style><script>%s</script></head><body>%s<script>Prism.highlightAll();</script></body></html>', prismCss, prismJs, codeSnippetHTML);

            % Set the HTML content in the UIHTML component
            % app.ViewCode.HTMLSource = htmlContent;

            %obj.sfControl.module.current_module_html = htmlContent;
            %obj.sfControl.module.current_module_filename = moduleFile;
            %obj.sfControl.module.CurrentModuleHtml = htmlContent;
            obj.sfControl.module.CurrentModuleInfo.htmlContent = htmlContent;


        end

        function obj = ViewModuleCodeButtonPushed(obj, app)

            try
                htmlContent = obj.sfControl.module.CurrentModuleInfo.htmlContent;
                % Create a new figure and UIHTML component
                newFigure = uifigure('Name', 'Code Viewer', 'Position', [200 200 800 600]);
                newUIHTML = uihtml(newFigure, 'Position', [10 10 800 600]);

                % Set the HTML content in the new UIHTML component
                newUIHTML.HTMLSource = htmlContent;

            catch
                obj.sfControl.msgWarning('Please select a module to edit.')
            end

        end

        function obj = loadProject(obj,app)
            while ~isempty(app.TargetTree.Children)
                delete(app.TargetTree.Children(1));
            end
            % Get the user's documents directory
            userDocs = fullfile(getenv('USERPROFILE'), 'Documents');
            % Open file explorer in the documents directory and allow user to select a JSON file
            [file, path] = uigetfile(fullfile(userDocs, '*.json'), 'Select JSON file');
            if isequal(file, 0)
                disp('User selected Cancel');
            else
                fullPath = fullfile(path, file);
                disp(['User selected: ', fullPath]);
                obj.sfControl = obj.sfControl.Project_Load(fullPath);
            end
            obj.refreshTrees(app);
            obj.setupEditProjectInformationLoad(app);
            obj.reloadPlugins(app);
            obj.reloadCustomPaths(app);

            labelStruct = obj.sfControl.Project_GetFolderLabels;
            % Find the index of the 'path_results' label in the labelStruct array.
            pathResults = strcmp({labelStruct.tag}, 'path_results');
            pathImport = strcmp({labelStruct.tag}, 'path_import');
            % Set the output directory of the last TargetModule to the folder corresponding to the 'path_results' label.
            obj.sfControl.proj.path_import = labelStruct(pathImport).folder;
            obj.sfControl.proj.path_results = labelStruct(pathResults).folder;
         
            n = length(obj.sfControl.module.TargetModuleArray);
            for i = 1:n
                currentTargetModule = obj.sfControl.module.TargetModuleArray{i};

                if contains(currentTargetModule.flowMode, 'inflow')
                    if isfield(obj.sfControl.proj, 'path_import') && ~isempty(obj.sfControl.proj.path_import)
                        obj.sfControl.module.TargetModuleArray{i}.fileIoVar = obj.sfControl.proj.path_import;
                    end
                end

                if contains(currentTargetModule.flowMode, 'outflow')
                    if isfield(obj.sfControl.proj, 'path_results') && ~isempty(obj.sfControl.proj.path_results)
                        obj.sfControl.module.TargetModuleArray{i}.fileIoVar = obj.sfControl.proj.path_results;
                    end
                end
            end

        end

        function obj = saveProject(obj,app)
            if isempty(obj.sfControl.proj.name)
                obj = obj.saveAsProject(app);
            else
                try
                    obj.sfControl.Project_Save();
                catch
                    obj = obj.saveAsProject(app);
                end
            end
        end

        %TODO: Make an actual good looking GUI. Have never moved beyond my dev one 
        function obj = saveAsProject(obj,app)
            % Create the figure
            fig = figure('Name', 'Save File', 'NumberTitle', 'off', ...
                'Position', [300, 300, 400, 250], 'MenuBar', 'none');

            spacing = 45;

            % Add a button to select the folder
            uicontrol(fig, 'Style', 'pushbutton', 'String', 'Select Folder', ...
                'Position', [100, 250 - (1) * spacing, 150, 20], 'Callback', @selectFolder);

            % Create a label for the option
            uicontrol(fig, 'Style', 'text', 'String', 'Directory:', ...
                'HorizontalAlignment', 'left', ...
                'Position', [20, 250 - (2) * spacing, 150, 20]);

            % Add a label to display the selected folder
            folderLabel = uicontrol(fig, 'Style', 'text', 'String', '', ...
                'HorizontalAlignment', 'left', ...
                'Position', [180, 250 - (2) * spacing, 150, 20]);

            % Create a label for the option
            uicontrol(fig, 'Style', 'text', 'String', 'FileName:', ...
                'HorizontalAlignment', 'left', ...
                'Position', [20, 250 - (3) * spacing, 150, 20]);

            % Add a text box to input the filename
            fileNameEditField = uicontrol(fig, 'Style', 'edit', 'Position', [180, 250 - (3) * spacing, 150, 20]);

            % Add a button to save the file
            saveButton = uicontrol(fig, 'Style', 'pushbutton', 'String', 'Save', ...
                'Position', [50, 50, 100, 30], 'Enable', 'off', 'Callback', @(src, event) saveButtonPushed(obj, src, event));

            % Callback function for the Select Folder button
            function selectFolder(src, event)
                selectedFolder = uigetdir(fullfile(getenv('USERPROFILE'), 'Documents'), 'Select a folder');
                if selectedFolder ~= 0
                    folderLabel.String = selectedFolder;
                    saveButton.Enable = 'on';
                end
            end

            % Callback function for the Save button
            function obj = saveButtonPushed(obj,src, event)
                obj.sfControl = obj.sfControl.Project_SaveAs(folderLabel.String,fileNameEditField.String);
                close(fig);
            end
        end

        function openInputFolder(obj,app)
            obj.openFolder(obj.sfControl.proj.path_import);
        end

        function openExportFolder(obj,app)
            tempFileSelected = obj.SelectedModule;
            obj.openFolder(tempFileSelected.NodeData);
        end
        function openContainingFolder(obj,app)
            tempModuleSelected = obj.SelectedModule;
            obj.openFolder(tempModuleSelected.NodeData);
        end

        function openInEEGLAB(obj,app)
            % Opens File in EEGLAB
            tempFileSelected = obj.SelectedModule;
            try
                assignin('base', 'EEG', pop_loadset( tempFileSelected.NodeData ));
                eeglab redraw;
            catch error
                warning('Unable to load file in EEGLAB.');
                obj.sfControl.msgError(strcat('SignalFlowGUIClass: openInEEGLAB, Error:',obj.sfControl.Util_PrintFormattedError(error)));
                return
            end
        end

        function plotData(obj,app)
            % Plots data using pop_eegplot()
            tempFileSelected = obj.SelectedModule;
            try
                pop_eegplot( pop_loadset( tempFileSelected.NodeData ), 1, 0, 1);
            catch error
                warning('Unable to Plot Data in EEGLAB.');
                obj.sfControl.msgError(strcat('SignalFlowGUIClass: plotData, Error:',obj.sfControl.Util_PrintFormattedError(error)));
                return
            end
        end

        function viewElectrodeMap(obj,app)
            tempFileSelected = obj.SelectedModule;
            try
                % load file
                viewElectrodeMapEEG = pop_loadset( tempFileSelected.NodeData );
                % Check if channel locations are present
                if isempty(viewElectrodeMapEEG.chanlocs)
                    warning('No channel locations found in the dataset.');
                else
                    % Plot channel locations
                    figure;
                    topoplot([], viewElectrodeMapEEG.chanlocs, 'style', 'blank', 'electrodes', 'labelpoint', 'chaninfo', viewElectrodeMapEEG.chaninfo);
                    title('Channel Locations');
                end
            catch error
                warning('Unable to Plot Data in EEGLAB.');
                obj.sfControl.msgError(strcat('SignalFlowGUIClass: viewElectrodeMap, Error:',obj.sfControl.Util_PrintFormattedError(error)));
                return
            end
        end

        function obj = viewChannelSpectra(obj,app)
            tempFileSelected = obj.SelectedModule;
            try
                % Deletes previous figure, to fix EEGLAB bug
                try
                    close(obj.spectraFig)
                catch
                    disp('')
                end
                % load file
                viewChannelSpectraEEG = pop_loadset( tempFileSelected.NodeData );
                % EEGLAB function for loading channel spectra
                pop_spectopo(viewChannelSpectraEEG, 1, [], 'EEG', 'percent', 100, 'freqrange', [1 80]);
                %gets figure created, so that it can be dleted to fix EEGLAB bug
                obj.spectraFig = get(groot, 'CurrentFigure');
            catch error
                warning('Unable to Plot Data in EEGLAB.');
                obj.sfControl.msgError(strcat('SignalFlowGUIClass: viewChannelSpectra, Error:',obj.sfControl.Util_PrintFormattedError(error)));
                return
            end
        end

        function obj = ExecuteLoop(obj,app)
            obj.sfControl.Project_Execute()
            obj.refreshExecuteTree(app);
        end

        function obj = ExecuteParallel(obj,app)
            obj.sfControl.Project_ExecuteParallel()
            obj.refreshExecuteTree(app);
        end

        function obj = ExecuteFile(obj,app)
            tempFileSelected = obj.SelectedModule;
            filename = tempFileSelected.Text;
            obj.sfControl.Project_SingleFileExecute(filename)
            obj.refreshExecuteTree(app);
        end

        % TODO: Put this in functions . THis does nothing 
        function obj = BrowseHandler( obj, app, action, value )

            if nargin < 4
                value = missing;
            end

            if isempty(app.BrowseFileCatalog.SelectedNodes.NodeData)
                obj.sfControl.msgWarning('No file selected for action.')
            end

            switch action
                case 'OpenInEeglab'
                    obj.openInEEGLAB(app);
                case 'PlotTimeSeries'
                    obj.plotData(app);
                case 'OpenFolder'
                    obj.openContainingFolder(app);
                case 'PlotSpectrogram'
                    obj.viewChannelSpectra(app);
                case 'ViewChannel'
                    obj.viewElectrodeMap(app);
                otherwise
            end
        end

        function obj = ResetFoldersButtonPushed(obj, app)

            % check out sfc object
            labelStruct = obj.sfControl.Project_GetFolderLabels;


            % generate save file names
            for i = 1 : numel(labelStruct)
                % Save the plugin path in a .mat file
                [sfdir,~,~] = fileparts(which('SignalFlowControl.m'));
                pathsMats{i} = [sfdir filesep() 'UserSavedFolders' filesep() labelStruct(i).tag,'_sfSavedFolder.mat'];
                if isfile(pathsMats{i})
                    delete(pathsMats{i});
                end
            end

            obj.sfControl.Project_ResetFolders;
            obj.reloadCustomPaths(app);

        end

        function obj = ResetToolboxesButtonPushed(obj, app)
            pluginStatus= SignalFlowDoctor();
            pluginNames = fieldnames(pluginStatus);
            for i = 1 : numel(pluginNames)
                % Save the plugin path in a .mat file
                [sfdir,~,~] = fileparts(which('SignalFlowControl.m'));
                pluginMats{i} = [sfdir filesep() 'Plugins' filesep() pluginNames{i},'_sfPlugin.mat'];
                pluginExists(i) = isfile(pluginMats{i});
                if pluginExists(i)
                    load(pluginMats{i})
                    if isfolder(saveDir.pluginPath)
                        if saveDir.addSubPlugins
                            rmpath(genpath(saveDir.pluginPath));
                        else
                            rmpath(saveDir.pluginPath);
                        end
                    end
                    delete(pluginMats{i});
                end
            end
            obj.reloadPlugins(app);
        end

        % TODO: THis is the lamps placement issues. we need to rework almost entire gui to completely gety rid of bug 
        % TODO: The only way is to pre-place the lamps and then just make them visible or invisible.
        function [obj,app] = reloadCustomPaths(obj, app)
            for i = 1:numel(app.PathButtons)
                delete(app.PathButtons{i})
                delete(app.PathLamps{i})
            end

            % check out sfc object
            labelStruct = obj.sfControl.Project_GetFolderLabels;

            % generate save file names
            for i = 1 : numel(labelStruct)
                % Save the plugin path in a .mat file
                [sfdir,~,~] = fileparts(which('SignalFlowControl.m'));
                pathsMats{i} = [sfdir filesep() 'UserSavedFolders' filesep() labelStruct(i).tag,'_sfSavedFolder.mat'];
                if isfile(pathsMats{i})
                    load(pathsMats{i})
                    addpath(directoryPath);
                    obj.sfControl.proj.(labelStruct(i).tag) = directoryPath;
                end
            end

            % retrieve paths
            labelStruct = obj.sfControl.Project_GetFolderLabels;

            % Assuming the element's position vector is [left bottom width height]
            elementPosition = app.PathSetupPanel.Position;
            
            % Calculate the top position
            topPosition = elementPosition(2) + elementPosition(4);

            % Conditional Plugin Button Label
            fi = @(varargin)varargin{length(varargin)-varargin{1}};

            % Hardcoded buttons sizes
            ButtonXLeft = elementPosition(1) + 40;
            LampXLeft = elementPosition(1) + 12;
            buttonWidth = 180;
            buttonHeight = 22;
            buttonSpacing = 10;
            lampWidthHeight = 20;

            % Check status of button
            for i = 1 : numel({labelStruct.tag})
                % Create a button/lamp if needed
                app.PathButtons{i} = uibutton(app.SetupTab, 'state');
                app.PathButtons{i}.HorizontalAlignment = 'left';

                app.PathLamps{i} = uilamp(app.SetupTab);
                % Calculate the button's bottom position for vertical stacking
                bottomPosition = topPosition - (i) * (buttonHeight + buttonSpacing);

                % Set the button's position
                app.PathButtons{i}.Position = [ButtonXLeft, bottomPosition, buttonWidth, buttonHeight];
                % Create a lamp UI element
                app.PathLamps{i}.Position = [LampXLeft, bottomPosition + (buttonHeight - lampWidthHeight) / 2, lampWidthHeight, lampWidthHeight];

            end

            for i = 1 : numel({labelStruct.tag})

                if ismissing(labelStruct(i).folder)
                    labelStruct(i).folderStatus = false;
                else
                    labelStruct(i).folderStatus = true;
                end

            end


            for i = 1 :  numel({labelStruct.tag})

                folder_label = labelStruct(i).tag;
                folder_path = labelStruct(i).folder;
                folder_lamp = labelStruct(i).folderStatus;

                prefix = fi(folder_lamp,'Found: ', 'Click to Fix: ');
                label = [upper(folder_label(1)) lower(folder_label(2:end))];

                app.PathButtons{i}.Text = sprintf('%s %s', prefix, label);
                app.PathButtons{i}.Value = folder_lamp;
                app.PathButtons{i}.Tag = folder_label;

                % Set the button's callback function
                app.PathButtons{i}.ValueChangedFcn = @(src, event)obj.pathFixCallback(app, src, event, i);

                % Set the lamp's color based on a condition
                cond = logical(folder_lamp); % Replace with your condition
                if cond
                    app.PathLamps{i}.Color = 'green';
                else
                    app.PathLamps{i}.Color = 'red';
                end
            end

            obj.refreshSetupFileListTree(app);

            app.DropDownFolderPicker.Items = {obj.sfControl.Project_GetFolderLabels.tag};

        end

        function htmlOutput = consoleOutputToHtml(obj, cprintfCommand)
            % Redirect the MATLAB console output to a string using evalc
            consoleOutput = evalc(cprintfCommand);

            % Replace special characters in the console output with their HTML entity counterparts
            %   consoleOutput = strrep(consoleOutput, '&', '&amp;');
            %   consoleOutput = strrep(consoleOutput, '<', '&lt;');
            %   consoleOutput = strrep(consoleOutput, '>', '&gt;');

            % Wrap the modified console output in a <pre> tag to maintain the original formatting
            htmlOutput = ['<html><body>' consoleOutput '</body></html>'];

            % Set the HTML content of the UIHTML element
            % app.UIHTMLComponent.HTML = htmlOutput;
        end

        function [obj,app] = reloadPlugins(obj,app)

            pluginStatus= SignalFlowDoctor();
            pluginNames = fieldnames(pluginStatus);

            % generate save file names
            for i = 1 : numel(pluginNames)
                % Save the plugin path in a .mat file
                [sfdir,~,~] = fileparts(which('SignalFlowControl.m'));
                pluginMats{i} = [sfdir filesep() 'Plugins' filesep() pluginNames{i},'_sfPlugin.mat'];
                pluginExists(i) = isfile(pluginMats{i});

                if pluginExists(i)
                    load(pluginMats{i})
                    if isfolder(saveDir.pluginPath)
                        if saveDir.addSubPlugins
                            addpath(genpath(saveDir.pluginPath));
                        else
                            addpath(saveDir.pluginPath);
                        end
                    end
                end
            end

            pluginStatus= SignalFlowDoctor();

            % Assuming the element's position vector is [left bottom width height]
            elementPosition = app.PluginSetupPanel.Position;
            
            % Calculate the top position
            topPosition = elementPosition(2) + elementPosition(4);

            % Conditional Plugin Button Label
            fi = @(varargin)varargin{length(varargin)-varargin{1}};

            % Hardcoded buttons sizes
            ButtonXLeft = elementPosition(1) + 40;
            LampXLeft = elementPosition(1) + 12;
            buttonWidth = 180;
            buttonHeight = 22;
            buttonSpacing = 10;
            lampWidthHeight = 20;

            % Check status of button
            if numel(app.PluginButtons) == 0
                for i = 1 : numel(pluginNames)
                    % Create a button/lamp if needed
                    app.PluginButtons{i} = uibutton(app.SetupTab, 'state');
                    app.PluginButtons{i}.HorizontalAlignment = 'left';

                    app.PluginLamps{i} = uilamp(app.SetupTab);
                    % Calculate the button's bottom position for vertical stacking
                    bottomPosition = topPosition - (i) * (buttonHeight + buttonSpacing);

                    % Set the button's position
                    app.PluginButtons{i}.Position = [ButtonXLeft, bottomPosition, buttonWidth, buttonHeight];
                    % Create a lamp UI element
                    app.PluginLamps{i}.Position = [LampXLeft, bottomPosition + (buttonHeight - lampWidthHeight) / 2, lampWidthHeight, lampWidthHeight];

                end
            end

            for i = 1 :  numel(pluginNames)

                prefix = fi(pluginStatus.( pluginNames{i}),'Found: ', 'Click to Fix: ');

                label = [upper(pluginNames{i}(1)) lower(pluginNames{i}(2:end))];
                app.PluginButtons{i}.Text = sprintf('%s %s', prefix, label);
                app.PluginButtons{i}.Value = logical(pluginStatus.(pluginNames{i}));
                app.PluginButtons{i}.Tag = pluginNames{i};

                % Set the button's callback function
                app.PluginButtons{i}.ValueChangedFcn = @(src, event)obj.pluginFixCallback(app, src, event, i);

                % Set the lamp's color based on a condition
                cond = logical(pluginStatus.(pluginNames{i})); % Replace with your condition
                if cond
                    app.PluginLamps{i}.Color = 'green';
                else
                    app.PluginLamps{i}.Color = 'red';
                end
            end
        end

        function  [obj,app] =  pathFixCallback(obj, app, src, event, i)

            labelStruct = obj.sfControl.Project_GetFolderLabels;

            sfdir = obj.sfControl.setup.sfdir;

            % user can select a path or cancel, if they cancel the loop is
            % broken but the path is still assigned missing
            % directoryPath = uigetdir(fullfile(getenv('USERPROFILE'), 'Documents'),'Select the Folder your plug-in is in:');

            if ispc
                % Windows
                directoryPath = uigetdir(fullfile(getenv('USERPROFILE'), 'Documents'), 'Select the Folder your plug-in is in:');
            elseif ismac
                % macOS
                directoryPath = uigetdir(fullfile(getenv('HOME'), 'Documents'), 'Select the Folder your plug-in is in:');
            else
                % Linux (and other Unix-like systems)
                directoryPath = uigetdir(fullfile(getenv('HOME'), 'Documents'), 'Select the Folder your plug-in is in:');
            end


            if directoryPath == 0
                obj.sfControl.proj.(labelStruct(i).tag) = missing;
            else
                obj.sfControl.proj.(labelStruct(i).tag) = directoryPath;
            end

            % Check if directory exists
            UserSavedFolders = fullfile(sfdir,'UserSavedFolders');
            if ~exist(UserSavedFolders, 'dir')
                % If directory does not exist, create it
                mkdir(UserSavedFolders);
            end

            % if the user selects a directory, it is first checked for eing
            % a directory and then stored into the functions
            if exist(directoryPath,"dir")
                [sfdir,~,~] = fileparts(which('SignalFlowControl.m'));
                save([sfdir filesep() 'UserSavedFolders' filesep() src.Tag,'_sfSavedFolder.mat'],'directoryPath');
            end

            obj.reloadCustomPaths(app)

        end

        function [obj,app] = pluginFixCallback(obj, app, src, event, i)
            if event.Value

                fix_code = sprintf('fix_%s', src.Tag);

                [res, paths] = SignalFlowDoctor(fix_code);

                pluginPath = missing;
                try
                    if isfolder(paths)
                        pluginPath = paths;
                    end
                catch
                    obj.msgWarning(strcat('Invalid Path:', src.Tag));
                end

                if ~ismissing(pluginPath)

                    saveDir = struct();
                    saveDir.pluginPath = pluginPath;

                    switch src.Tag
                        case {'eeglab', 'brainstorm', 'spectralevents'}
                            saveDir.addSubPlugins = false;
                        case {'braph', 'bct'}
                            saveDir.addSubPlugins = true;
                        otherwise
                            saveDir.addSubPlugins = true;
                    end
                    % Save the plugin path in a .mat file
                    [sfdir,~,~] = fileparts(which('SignalFlowControl.m'));
                    save([sfdir filesep() 'Plugins' filesep() src.Tag,'_sfPlugin.mat'],'saveDir');

                end

                obj.reloadPlugins(app);

            end
        end

        function obj = AddCustomFolderButtonPushed(obj,app)
            % Create the figure
            fig = figure('Name', 'Directory Selector', 'NumberTitle', 'off', ...
                'Position', [300, 300, 400, 200], 'MenuBar', 'none');

            % Directory selection button
            dir_button = uicontrol('Style', 'pushbutton', 'String', 'Select Directory', ...
                'Position', [20, 120, 150, 40], 'Callback', @select_directory_callback);

            % Directory path display
            dir_display = uicontrol('Style', 'text', 'String', 'No directory selected', ...
                'Position', [180, 130, 200, 20]);

            % Text input for tag
            tag_input = uicontrol('Style', 'edit', 'Position', [20, 70, 150, 30], 'String', '');

            % Tag input label
            tag_label = uicontrol('Style', 'text', 'Position', [20, 100, 150, 20], ...
                'String', 'Enter a tag:', 'HorizontalAlignment', 'left');

            % Confirmation button
            confirm_button = uicontrol('Style', 'pushbutton', 'String', 'Confirm', ...
                'Position', [250, 20, 100, 40], 'Callback', @confirm_callback);

            % Callback function for directory selection button
            function select_directory_callback(src, event)
                folder_path = uigetdir(fullfile(getenv('USERPROFILE'), 'Documents'), 'Select a folder');
                if folder_path ~= 0
                    set(dir_display, 'String', folder_path);
                end
            end

            % Callback function for confirmation button
            function confirm_callback(src, event)
                selected_directory = get(dir_display, 'String');
                input_tag = get(tag_input, 'String');

                if strcmp(selected_directory, 'No directory selected') || isempty(input_tag)
                    msgbox('Please select a directory and enter a tag.', 'Error', 'error');
                else
                    obj.sfControl.Project_AssignCustomFolder(selected_directory, input_tag)
                    obj.reloadCustomPaths(app);
                    close(fig);
                end
            end
        end
    end
    methods (Static)
        function openFolder(filename)
            try
                os = computer;
                if isfile(filename)
                    [folderName, ~, ~] = fileparts(filename);
                else
                    folderName = filename;
                end
                if isfolder(folderName)
                    switch os
                        case 'PCWIN'
                            winopen(folderName);
                        case 'PCWIN64'
                            winopen(folderName);
                        case {'GLNXA64', 'GLNX86'}
                            system(['xdg-open ', folderName]);
                        case {'MACI64', 'MACI'}
                            system(['open ', folderName]);
                        otherwise
                            obj.sfControl.msgWarning('Unsupported operating system');
                    end
                end
            catch error
                obj.sfControl.msgError(strcat('SignalFlowGUIClass: openFolder, Error:',obj.sfControl.Util_PrintFormattedError(error)));
                return
            end
        end
        

    end
end

