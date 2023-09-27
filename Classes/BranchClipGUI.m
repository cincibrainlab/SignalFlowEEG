function BranchClipGUI()
    % Create the main figure
    clear all;
    fig = figure('Name', 'Drag and Drop vertices', 'Position', [100, 100, 900, 600]);
    
    % Create a canvas axis for drawing vertices
    canvas = axes('Parent', fig, 'Position', [0.4, 0.1, 0.5, 0.8]);
    xlim([0, 800]);
    ylim([0, 800]);

    % Define the grid parameters
    numColumns = 4;
    numRows = 8;
    control.UI.cellWidth = 800 / numColumns;
    control.UI.cellHeight = 800 / numRows;
    
    % Initialize a cell array to store the center coordinates of each element
    control.UI.gridCenters = cell(numRows, numColumns);
    control.UI.grid = struct('Handle', [], 'location',[]);
    
    % Create the grid lines and store the center coordinates
%     hold on;
    hold off;
    for row = 1:numRows
        for col = 1:numColumns
            x = (col - 1) * control.UI.cellWidth + control.UI.cellWidth / 2;
            y = (numRows - row) * control.UI.cellHeight + control.UI.cellHeight / 2;
            
            % Draw a rectangle for each grid cell
            gridRect = rectangle('Position', [x - control.UI.cellWidth / 2, y - control.UI.cellHeight / 2, control.UI.cellWidth, control.UI.cellHeight], 'EdgeColor', 'b');
            control.UI.grid(end + 1) = struct('Handle', gridRect, 'location',[row,col]);
            % Store the center coordinates in the control.UI.gridCenters cell array
            control.UI.gridCenters{row, col} = [x, y];
            if isempty(control.UI.grid(1).location)
                control.UI.grid(1) = [];
            end
        end
    end
    
    % Create a button to create new vertices
    uicontrol('Style', 'pushbutton', 'String', 'Add', ...
        'Position', [20, 50, 120, 30], 'Callback', @createRectangle);
    % Create a button for executing in order
    uicontrol('Style', 'pushbutton', 'String', 'Execute', ...
        'Position', [20, 20, 120, 30], 'Callback', @executeDAGInTopologicalOrder);
    
    % Create a listbox for the library of MATLAB functions
    libraryBox = uicontrol('Style', 'listbox', 'Position', [20, 80, 300, 500], ...
        'Callback', @selectFunction);

    % Populate the library listbox with function names
    libraryPath = 'C:\Users\sueo8x\Documents\Github\SignalFlowEEG\Modules'; % Replace with the actual folder path
    control.data.functionNames = getFunctionList(libraryPath);
    set(libraryBox, 'String', control.data.functionNames);

    control.data.branchIndex = 1;
    
    % Initialize variables for drag-and-drop
    control.UI.dragging = false;
    control.UI.selectedObj = [];
    control.UI.selectedFunction = '';
    control.UI.sourceRectangleIndex = -1; % Store the source rectangle for arrow drawing
    control.UI.targetRectangleIndex = -1; % Store the target rectangle for arrow drawing
    

    % Initialize an array to store information about vertices
    control.DAG.UIvertices = struct('Position', [], 'Color', [], 'Handle', [], 'Text', []);
    control.DAG.UIedges = gobjects(30);
%     control.DAG.adjacency_matrix = zeros(30);
    control.DAG.adjacency_matrix = {};
    control.DAG.vertex_list = [];
    
    % Create a context menu for drawing arrows
    contextMenu = uicontextmenu(fig);
    uimenu(contextMenu, 'Label', 'Set as Source', 'Callback', @setAsSource);
    uimenu(contextMenu, 'Label', 'Set as Target', 'Callback', @setAsTarget);
    uimenu(contextMenu, 'Label', 'Draw Arrow', 'Callback', @drawArrow);

    setappdata(fig,'control',control)

    function executeDAGInTopologicalOrder(~,~)
        adjMatrix = control.DAG.adjacency_matrix;
        % Check if the graph is a DAG.
        isDAG = isDirectedAcyclicGraph(adjMatrix);
        if ~isDAG
            disp('The graph has cycles and cannot be executed in topological order.');
            return;
        end
        
        % Perform topological sorting.
        topologicalOrder = topologicalSort();

        importDir = 'C:\Users\sueo8x\Documents\raw_files_ForNate_3.10.2022\128_EGI_SET\';
        importFile = '0012_rest.set';
        importPath = [importDir importFile];
        outputDir = 'C:\Users\sueo8x\Documents\SignalFlowEEGDevSavesDELETELATER';
        % Get the current directory and all its subfolders
        currentPath = genpath(pwd); % pwd gets the current directory
        
        % Add the current directory and its subfolders to the MATLAB path
        addpath('C:\Users\sueo8x\Documents\eeglab2022.1')
        eeglab nogui;
        addpath(currentPath);
        addpath(importDir)
        addpath(outputDir)

        for k =1 : length(topologicalOrder) 
            tempModuleName = split(control.DAG.UIvertices(k).Text.String,'.',1);
            ExecutionList{k} = feval(tempModuleName{1, 1});
        end
        
        singleFileExecute(importPath,outputDir,ExecutionList,topologicalOrder);

        function childModules = findChildModules(moduleIndex)
            % Find all modules that are children of the module at moduleIndex.
        
            % Initialize an empty list to store child modules.
            childModules = [];
        
            % Iterate through the modules in the adjacency matrix.
            for i = 1:size(control.DAG.adjacency_matrix, 2)
                if control.DAG.adjacency_matrix{moduleIndex, i} == 1
                    % Module at index i is a child of the module at moduleIndex.
                    childModules = [childModules, i];
                end
            end
        end


        function singleFileExecute(importFile, pathResults, ExecutionList, topologicalOrder)
            % Create a cell array to store data queues for each module.
            moduleQueues = cell(1, length(ExecutionList));
            
            % Extract the file extension from the given input file.
            [~, ~, fileExtension] = fileparts(importFile);
            
            % Define an array of valid file extensions that the function can process.
            validExtensions = {'.set', '.raw', '.edf'};
            
            % Check if the file extension of the input file is within the valid extensions.
            if ismember(fileExtension, validExtensions)
                % Initialize the input file path for the first TargetModule.
                ExecutionList{1}.fileIoVar = importFile;
                
                % Check if the input file exists and update the boolValidImportFile flag.
                boolValidImportFile = exist(ExecutionList{1}.fileIoVar, 'file') == 2;
                
                % If both the input file and output directory are valid, execute the pipeline.
                if boolValidImportFile
                    % Run the first TargetModule.
                    EEG = ExecutionList{1}.run();
                    ExecutionList{1}.endEEG = EEG;
                    
                    % Initialize queues for child modules.
                    for childModuleIndexSetup = findChildModules(1)
                        moduleQueues{childModuleIndexSetup} = {EEG};
                    end
                    
                    if ~isempty(EEG)
                        % Iterate through the rest of the TargetModuleArray and execute each module.
                        for i = 2:length(ExecutionList)
                            disp(['Executing node: (', topologicalOrder(i), ') Name: ', control.DAG.UIvertices(topologicalOrder(i)).Text.String]);
                            if strcmp(ExecutionList{i}.flowMode, 'outflow')
                                ExecutionList{i}.fileIoVar = pathResults;
                            end
                            for j = 1:length(moduleQueues{i})
                                EEG = moduleQueues{i}{j};
                                control.data.branchIndex = control.data.branchIndex + 1;
                                EEG.setname = [EEG.setname '_' num2str(control.data.branchIndex)];
                                EEG.filename = [EEG.setname '.set'];
                                ExecutionList{i}.beginEEG = EEG;
                                EEG = ExecutionList{i}.run();
                                ExecutionList{i}.endEEG = EEG;
                                % Iterate through child modules and propagate data.
                                for childModuleIndex = findChildModules(i)                   
                                    % Add EEG data to the queue of the next child module.
                                    moduleQueues{childModuleIndex} = [moduleQueues{childModuleIndex}, {EEG}];
                                end
                            end                          
                        end
                    end
                end
            end
        end
    end

    % Get a list of .m files in a specified folder
    function functionList = getFunctionList(folderPath)
        functionList = {};
        files = dir(fullfile(folderPath, '*.m'));
        for i = 1:numel(files)
            functionList{i} = files(i).name;
        end
    end

    function addVertex()
        N = length(control.DAG.vertex_list) + 1;
        control.DAG.vertex_list = [control.DAG.vertex_list, N];
        control.DAG.adjacency_matrix{N, N} = 0;
        control.DAG.adjacency_matrix = replaceEmptyWithZeros(control.DAG.adjacency_matrix);
    end

    function adjacency_matrix = replaceEmptyWithZeros(adjacency_matrix)
        % Find empty cells in the adjacency matrix and replace them with zeros
        for i = 1:numel(adjacency_matrix)
            if isempty(adjacency_matrix{i})
                adjacency_matrix{i} = 0;
            end
        end
    end

    
    function tempAdjMatrix = addEdge(tempAdjMatrix,u, v)
        if ismember(u, control.DAG.vertex_list) && ismember(v, control.DAG.vertex_list)
            tempAdjMatrix{u, v} = 1;
        else
            error('Vertices u and/or v do not exist.');
        end
    end

    % Not finished 
%     function deleteVertex(u)
%         if ismember(u, control.DAG.vertex_list)
%             control.DAG.vertex_list(control.DAG.vertex_list == u) = [];
%             control.DAG.adjacency_matrix(u, :) = [];
%             control.DAG.adjacency_matrix(:, u) = [];
%         else
%             error('Vertex u does not exist.');
%         end
%     end
    
    function sorted_vertices = topologicalSort()
        G = digraph(cell2mat(control.DAG.adjacency_matrix));
        sorted_vertices = toposort(G);
    end

    
    % Callback function to create a new rectangle
    function createRectangle(~, ~)
        control = getappdata(fig,'control');
        if ~isempty(control.UI.selectedFunction)
            % Generate a random color for the rectangle
            color = rand(1, 3);
    
            % Create a rectangle with default position
            rectPosition = [50, 50, 200, 50];
            rect = rectangle('Position', rectPosition, 'FaceColor', color, ...
                'EdgeColor', 'k', 'LineWidth', 1.5, 'ButtonDownFcn', @startDrag, 'ContextMenu', contextMenu,'Parent',canvas);
    
            % Create text in the middle of the rectangle with the selected function name
            textX = rectPosition(1) + 0.5 * rectPosition(3);
            textY = rectPosition(2) + 0.5 * rectPosition(4);
            textObj = text('Position', [textX, textY], 'String', control.UI.selectedFunction, 'HorizontalAlignment', 'center', 'ButtonDownFcn', @startDrag, 'ContextMenu', contextMenu,'Parent',canvas);
    
            % Store rectangle information
            addVertex()
            control.DAG.UIvertices(end + 1) = struct('Position', rectPosition, 'Color', color, 'Handle', rect, 'Text', textObj);
            % Check if it's the first iteration and the values are empty, then remove the entry
            if isempty(control.DAG.UIvertices(1).Position) && isempty(control.DAG.UIvertices(1).Color) && ...
               isempty(control.DAG.UIvertices(1).Handle) && isempty(control.DAG.UIvertices(1).Text)
                control.DAG.UIvertices(1) = [];
            end
        else
            msgbox('Please select a function from the library.', 'Error', 'error');
        end
        setappdata(fig,'control',control)
    end
    
    % Callback function to start dragging a rectangle
    function startDrag(src, ~)
        control = getappdata(fig,'control');
        control.UI.selectedObj = src;
        control.UI.dragging = true;
        set(fig, 'WindowButtonMotionFcn', @dragRect);
        set(fig, 'WindowButtonUpFcn', @stopDrag);
        setappdata(fig,'control',control)
    end
    
    function retObj = getBaseIndex(x)
        control = getappdata(fig,'control');
        if isa(x,'matlab.graphics.primitive.Rectangle')
            item = 'Handle';
        else
            item = 'Text';
        end
        for i = 1:numel(control.DAG.UIvertices)
            if control.DAG.UIvertices(i).(item) == fig.CurrentObject
                retObj = i;
                return 
            end
        end
        retObj = '';
        setappdata(fig,'control',control)
    end
    % Callback function to drag the selected rectangle
    function dragRect(~, ~)
        control = getappdata(fig,'control');
        if control.UI.dragging && ~isempty(control.UI.selectedObj)
            chosenObjIndex = getBaseIndex(control.UI.selectedObj);
            chosenObj = control.DAG.UIvertices(chosenObjIndex);            
            currentPoint = get(canvas, 'CurrentPoint');
            newPosition = [currentPoint(1, 1) - 0.5 * chosenObj.Handle.Position(3), ...
                currentPoint(1, 2) - 0.5 * chosenObj.Handle.Position(4), ...
                chosenObj.Handle.Position(3), ...
                chosenObj.Handle.Position(4)];
            set(chosenObj.Handle, 'Position', newPosition);
            control.DAG.UIvertices(chosenObjIndex).Position = newPosition;
            updateArrows(chosenObjIndex)
            if ~isempty(chosenObj.Text)
                textX = newPosition(1) + 0.5 * newPosition(3);
                textY = newPosition(2) + 0.5 * newPosition(4);
                set(chosenObj.Text, 'Position', [textX, textY]);
            end
        end
        setappdata(fig,'control',control)
    end
    
    % Callback function to stop dragging
    function stopDrag(~, ~)
        control = getappdata(fig,'control');
        control.UI.dragging = false;
        set(fig, 'WindowButtonMotionFcn', []);
        set(fig, 'WindowButtonUpFcn', []);

        % Snap to nearest grid point 

        chosenObjIndex = getBaseIndex(control.UI.selectedObj);
        chosenObj = control.DAG.UIvertices(chosenObjIndex);            
        currentPoint = get(canvas, 'CurrentPoint');


        ClosestColumnCenterDifference = inf;
        ClosestColumnIndex = 0;
        Goal = currentPoint(1, 1);
        
        for j = 1:size(control.UI.gridCenters, 2)
            columnCenter = control.UI.gridCenters{1, j}(1);
            centerDifference = abs(Goal - columnCenter);
            
            if centerDifference < ClosestColumnCenterDifference
                ClosestColumnCenterDifference = centerDifference;
                ClosestColumnIndex = j;
            end
        end
        
        ClosestRowCenterDifference = inf;
        ClosestRowIndex = 0;
        currentY = currentPoint(1, 2);
        
        for i = 1:size(control.UI.gridCenters, 1)
            rowCenter = control.UI.gridCenters{i, ClosestColumnIndex}(2);
            centerDifference = abs(currentY - rowCenter);
            
            if centerDifference < ClosestRowCenterDifference
                ClosestRowCenterDifference = centerDifference;
                ClosestRowIndex = i;
            end
        end
        
        for v = 1:size(control.UI.grid, 2)
            tempList = [ClosestRowIndex, ClosestColumnIndex];
            
            if isequal(tempList, control.UI.grid(v).location)
                gridPos = control.UI.grid(v).Handle.Position;
                set(chosenObj.Handle, 'Position', gridPos);
                control.DAG.UIvertices(chosenObjIndex).Position = gridPos;
                
                if ~isempty(chosenObj.Text)
                    textX = gridPos(1) + 0.5 * gridPos(3);
                    textY = gridPos(2) + 0.5 * gridPos(4);
                    set(chosenObj.Text, 'Position', [textX, textY]);
                end
                return
            end
        end
        control.UI.selectedObj = [];
        setappdata(fig,'control',control)
    end
    
    % Callback function to select a function from the library
    function selectFunction(src, ~)
        control = getappdata(fig,'control');
        selectedFunctionIndex = get(src, 'Value');
        control.UI.selectedFunction = control.data.functionNames{selectedFunctionIndex};
        setappdata(fig,'control',control)
    end
    
    % Callback function to set the selected rectangle as the source for drawing arrows
    function setAsSource(src, ~)
        control = getappdata(fig,'control');
        control.UI.selectedObj = src;
        if ~isempty(control.UI.selectedObj) 
            chosenObjIndex = getBaseIndex(fig.CurrentObject);
            control.UI.sourceRectangleIndex = chosenObjIndex; 
            disp('Rectangle set as source for arrows.');
            
        else
            disp('Please select a valid source rectangle.');
        end
        control.UI.selectedObj = [];
        setappdata(fig,'control',control)
    end
    
    % Callback function to set the selected rectangle as the target for drawing arrows
    function setAsTarget(src, ~)
        control = getappdata(fig,'control');
        control.UI.selectedObj = src;
        if ~isempty(control.UI.selectedObj)  
            chosenObjIndex = getBaseIndex(fig.CurrentObject);
            control.UI.targetRectangleIndex = chosenObjIndex; 
            disp('Rectangle set as target for arrows.');
        else
            disp('Please select a valid target rectangle.');
        end
        control.UI.selectedObj = [];
        setappdata(fig,'control',control)
    end
        
    % Callback function to draw an arrow between the source and target vertices
    function drawArrow(src, ~)
        control = getappdata(fig,'control');
        if isempty(control.UI.sourceRectangleIndex) || isempty(control.UI.targetRectangleIndex)
            disp('Please set both source and target vertices for drawing an arrow.');
            return;
        end        
        tempEdges = addEdge(control.DAG.adjacency_matrix,control.UI.sourceRectangleIndex,control.UI.targetRectangleIndex);
        isDAG = isDirectedAcyclicGraph(tempEdges);
        if isDAG
            control.DAG.adjacency_matrix = addEdge(control.DAG.adjacency_matrix,control.UI.sourceRectangleIndex,control.UI.targetRectangleIndex);
            % Draw the arrow as a line with an arrowhead
            control.DAG.UIedges(control.UI.sourceRectangleIndex,control.UI.targetRectangleIndex) = annotation('arrow', 'HeadLength', 10, 'HeadWidth', 10,Parent=canvas);
            
            updateArrows(control.UI.sourceRectangleIndex)
            updateArrows(control.UI.targetRectangleIndex)
            % Clear the source and target vertices
    %         control.UI.sourceRectangleIndex = [];
    %         control.UI.targetRectangleIndex = [];
        end
        setappdata(fig,'control',control)
    end

    function updateArrows(movedVerticeIndex)
        for t = 1 : size(control.DAG.UIedges,2) %If Source
            if isa(control.DAG.UIedges(movedVerticeIndex,t),'matlab.graphics.shape.Arrow')
                sourcePosition = control.DAG.UIvertices(movedVerticeIndex).Position;
                targetPosition = control.DAG.UIvertices(t).Position;

                % Calculate the positions for drawing the arrow
                arrowStartX = (sourcePosition(1) + 0.5 * sourcePosition(3));
                arrowStartY = (sourcePosition(2));
                arrowEndX = (targetPosition(1) + 0.5 * targetPosition(3));
                arrowEndY = (targetPosition(2) + targetPosition(4));
        
                control.DAG.UIedges(movedVerticeIndex,t).X = [arrowStartX, arrowEndX];
                control.DAG.UIedges(movedVerticeIndex,t).Y = [arrowStartY, arrowEndY];
            end
        end
        for j = 1 : size(control.DAG.UIedges,1) %If Target
            if isa(control.DAG.UIedges(j,movedVerticeIndex),'matlab.graphics.shape.Arrow')
                sourcePosition = control.DAG.UIvertices(j).Position;
                targetPosition = control.DAG.UIvertices(movedVerticeIndex).Position;

                % Calculate the positions for drawing the arrow
                arrowStartX = (sourcePosition(1) + 0.5 * sourcePosition(3));
                arrowStartY = (sourcePosition(2));
                arrowEndX = (targetPosition(1) + 0.5 * targetPosition(3));
                arrowEndY = (targetPosition(2) + targetPosition(4));
        
                control.DAG.UIedges(j,movedVerticeIndex).X = [arrowStartX, arrowEndX];
                control.DAG.UIedges(j,movedVerticeIndex).Y = [arrowStartY, arrowEndY];
            end
        end 
    end
    function isDAG = isDirectedAcyclicGraph(adjMatrix)
        % Check if the adjacency matrix represents a DAG.
        numNodes = size(adjMatrix, 1);
        
        % Initialize a visited array and a recursion stack.
        visited = zeros(1, numNodes);
        recStack = zeros(1, numNodes);
        
        % Helper function for DFS traversal.
        function result = isCyclic(node)
            if visited(node) == 0
                visited(node) = 1;
                recStack(node) = 1;
        
                % Recur for all neighbors.
                neighbors = find(cell2mat(adjMatrix(node, :)) == 1);
                for c = 1:length(neighbors)
                    n = neighbors(c);
                    if visited(n) == 0 && isCyclic(n)
                        result = true;
                        return;
                    elseif recStack(n) == 1
                        result = true;
                        return;
                    end
                end
            end
            recStack(node) = 0;
            result = false;
        end

    
        % Perform a DFS traversal on each unvisited node.
        for i = 1:numNodes
            if visited(i) == 0
                if isCyclic(i)
                    isDAG = false;
                    return; % Graph has a cycle.
                end
            end
        end
        
        isDAG = true; % No cycles found; it's a DAG.
    end
end