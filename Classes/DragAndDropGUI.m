function DragAndDropGUI()
    % Create the main figure
    fig = figure('Name', 'Drag and Drop vertices', 'Position', [100, 100, 900, 600]);
    
    % Create a canvas axis for drawing vertices
    canvas = axes('Parent', fig, 'Position', [0.4, 0.1, 0.5, 0.8]);
    xlim([0, 800]);
    ylim([0, 600]);
    
    % Create a button to create new vertices
    uicontrol('Style', 'pushbutton', 'String', 'Create Rectangle', ...
        'Position', [20, 50, 120, 30], 'Callback', @createRectangle);
    % Create a button for executing in order
    uicontrol('Style', 'pushbutton', 'String', 'Execute', ...
        'Position', [20, 20, 120, 30], 'Callback', @executeDAGInTopologicalOrder);
    
    % Create a listbox for the library of MATLAB functions
    libraryBox = uicontrol('Style', 'listbox', 'Position', [20, 80, 300, 500], ...
        'Callback', @selectFunction);

    % Populate the library listbox with function names
    libraryPath = 'C:\Users\Nate\Documents\GitHub\SignalFlowEEG\Modules'; % Replace with the actual folder path
    control.data.functionNames = getFunctionList(libraryPath);
    set(libraryBox, 'String', control.data.functionNames);
    
    % Initialize variables for drag-and-drop
    control.UI.dragging = false;
    control.UI.selectedObj = [];
    control.UI.selectedFunction = '';
    control.UI.sourceRectangleIndex = -1; % Store the source rectangle for arrow drawing
    control.UI.targetRectangleIndex = -1; % Store the target rectangle for arrow drawing
    

    % Initialize an array to store information about vertices
    control.DAG.vertices = struct('Position', [], 'Color', [], 'Handle', [], 'Text', []);
    control.DAG.UIedges = gobjects(30);
    control.DAG.edges = zeros(30);
    
    % Create a context menu for drawing arrows
    contextMenu = uicontextmenu(fig);
    uimenu(contextMenu, 'Label', 'Set as Source', 'Callback', @setAsSource);
    uimenu(contextMenu, 'Label', 'Set as Target', 'Callback', @setAsTarget);
    uimenu(contextMenu, 'Label', 'Draw Arrow', 'Callback', @drawArrow);

    setappdata(fig,'control',control)

    function executeDAGInTopologicalOrder(~,~)
        functions = control.data.functionNames;
        adjMatrix = control.DAG.edges;
        % Check if the graph is a DAG.
        isDAG = isDirectedAcyclicGraph(adjMatrix);
        if ~isDAG
            disp('The graph has cycles and cannot be executed in topological order.');
            return;
        end
        
        % Perform topological sorting.
        topologicalOrder = topologicalSort(adjMatrix);
        
        % Execute functions in topological order.
        for node = topologicalOrder
            % Execute the function associated with the current node.
            disp(['Executing function for node ', num2str(node)]);
            functions{node}(); % Call the function.
        end
    end
    
    function topologicalOrder = topologicalSort(adjMatrix)
        numNodes = size(adjMatrix, 1);
        inDegree = sum(adjMatrix, 1);
        queue = [];
        topologicalOrder = [];
        
        % Initialize queue with nodes having no incoming edges.
        for node = 1:numNodes
            if inDegree(node) == 0
                queue = [queue, node];
            end
        end
        
        while ~isempty(queue)
            node = queue(1);
            queue(1) = [];
            topologicalOrder = [topologicalOrder, node];
            
            % Update in-degrees of adjacent nodes.
            neighbors = find(adjMatrix(node, :) == 1);
            for i = 1:length(neighbors)
                neighbor = neighbors(i);
                inDegree(neighbor) = inDegree(neighbor) - 1;
                if inDegree(neighbor) == 0
                    queue = [queue, neighbor];
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
    
    % Callback function to create a new rectangle
    function createRectangle(~, ~)
        control = getappdata(fig,'control');
        if ~isempty(control.UI.selectedFunction)
            % Generate a random color for the rectangle
            color = rand(1, 3);
    
            % Create a rectangle with default position
            rectPosition = [50, 50, 200, 50];
            rect = rectangle('Position', rectPosition, 'FaceColor', color, ...
                'EdgeColor', 'k', 'LineWidth', 1.5, 'ButtonDownFcn', @startDrag, 'ContextMenu', contextMenu);
    
            % Create text in the middle of the rectangle with the selected function name
            textX = rectPosition(1) + 0.5 * rectPosition(3);
            textY = rectPosition(2) + 0.5 * rectPosition(4);
            textObj = text('Position', [textX, textY], 'String', control.UI.selectedFunction, 'HorizontalAlignment', 'center', 'ButtonDownFcn', @startDrag, 'ContextMenu', contextMenu);
    
            % Store rectangle information
            control.DAG.vertices(end + 1) = struct('Position', rectPosition, 'Color', color, 'Handle', rect, 'Text', textObj);
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
        for i = 1:numel(control.DAG.vertices)
            if control.DAG.vertices(i).(item) == fig.CurrentObject
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
            chosenObj = control.DAG.vertices(chosenObjIndex);            
            currentPoint = get(canvas, 'CurrentPoint');
            newPosition = [currentPoint(1, 1) - 0.5 * chosenObj.Handle.Position(3), ...
                currentPoint(1, 2) - 0.5 * chosenObj.Handle.Position(4), ...
                chosenObj.Handle.Position(3), chosenObj.Handle.Position(4)];
            set(chosenObj.Handle, 'Position', newPosition);
            control.DAG.vertices(chosenObjIndex).Position = newPosition;
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
        tempEdges = control.DAG.edges;
        tempEdges(control.UI.sourceRectangleIndex,control.UI.targetRectangleIndex) = 1;
        isDAG = isDirectedAcyclicGraph(tempEdges);
        if isDAG
            control.DAG.edges(control.UI.sourceRectangleIndex,control.UI.targetRectangleIndex) = 1;
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
                sourcePosition = control.DAG.vertices(movedVerticeIndex).Position;
                targetPosition = control.DAG.vertices(t).Position;

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
                sourcePosition = control.DAG.vertices(j).Position;
                targetPosition = control.DAG.vertices(movedVerticeIndex).Position;

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
                neighbors = find(adjMatrix(node, :) == 1);
                for x = 1:length(neighbors)
                    n = neighbors(x);
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