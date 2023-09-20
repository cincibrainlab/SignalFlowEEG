classdef DragAndDropGUIClass()

    properties

    methods
        function CreateGUI()
            % Create the main figure
            fig = figure('Name', 'Drag and Drop Rectangles', 'Position', [100, 100, 900, 600]);
            
            % Create a canvas axis for drawing rectangles
            canvas = axes('Parent', fig, 'Position', [0.4, 0.1, 0.5, 0.8]);
            xlim([0, 800]);
            ylim([0, 600]);
            
            % Create a button to create new rectangles
            uicontrol('Style', 'pushbutton', 'String', 'Create Rectangle', ...
                'Position', [20, 20, 120, 30], 'Callback', @createRectangle);
            
            % Create a listbox for the library of MATLAB functions
            libraryBox = uicontrol('Style', 'listbox', 'Position', [20, 80, 300, 500], ...
                'Callback', @selectFunction);
            
            % Initialize an array to store information about rectangles
            rectangles = struct('Position', [], 'Color', [], 'Handle', [], 'Text', []);
            
            % Initialize variables for drag-and-drop
            dragging = false;
            selectedObj = [];
            selectedFunction = '';
            sourceRectangle = []; % Store the source rectangle for arrow drawing
            targetRectangle = []; % Store the target rectangle for arrow drawing
            
            % Create a context menu for drawing arrows
            contextMenu = uicontextmenu(fig);
            uimenu(contextMenu, 'Label', 'Set as Source', 'Callback', @setAsSource);
            uimenu(contextMenu, 'Label', 'Set as Target', 'Callback', @setAsTarget);
            uimenu(contextMenu, 'Label', 'Draw Arrow', 'Callback', @drawArrow);
        end
        
        % Get a list of .m files in a specified folder
        function functionList = getFunctionList(folderPath)
            functionList = {};
            files = dir(fullfile(folderPath, '*.m'));
            for i = 1:numel(files)
                functionList{i} = files(i).name;
            end
        end
    
        % Populate the library listbox with function names
        libraryPath = 'C:\Users\Nate\Documents\GitHub\SignalFlowEEG\Modules'; % Replace with the actual folder path
        functionNames = getFunctionList(libraryPath);
        set(libraryBox, 'String', functionNames);
    
        % Callback function to create a new rectangle
        function createRectangle(~, ~)
            if ~isempty(selectedFunction)
                % Generate a random color for the rectangle
                color = rand(1, 3);
    
                % Create a rectangle with default position
                rectPosition = [50, 50, 200, 50];
                rect = rectangle('Position', rectPosition, 'FaceColor', color, ...
                    'EdgeColor', 'k', 'LineWidth', 1.5, 'ButtonDownFcn', @startDrag, 'UIContextMenu', contextMenu);
    
                % Create text in the middle of the rectangle with the selected function name
                textX = rectPosition(1) + 0.5 * rectPosition(3);
                textY = rectPosition(2) + 0.5 * rectPosition(4);
                textObj = text('Position', [textX, textY], 'String', selectedFunction, 'HorizontalAlignment', 'center', 'ButtonDownFcn', @startDrag, 'UIContextMenu', contextMenu);
    
                % Store rectangle information
                rectangles(end + 1) = struct('Position', rectPosition, 'Color', color, 'Handle', rect, 'Text', textObj);
            else
                msgbox('Please select a function from the library.', 'Error', 'error');
            end
        end
    
        % Callback function to start dragging a rectangle
        function startDrag(src, ~)
            selectedObj = src;
            dragging = true;
            set(fig, 'WindowButtonMotionFcn', @dragRect);
            set(fig, 'WindowButtonUpFcn', @stopDrag);
        end
        function retObj = getBase(x)
            if isa(selectedObj,'matlab.graphics.primitive.Rectangle')
                item = 'Handle';
            else
                item = 'Text';
            end
            for i = 1:numel(rectangles)
                if rectangles(i).(item) == selectedObj
                    retObj = rectangles(i);
                    return 
                end
            end
            retObj = '';
        end
        % Callback function to drag the selected rectangle
        function dragRect(~, ~)
            if dragging && ~isempty(selectedObj)
                chosenObj = getBase(selectedObj);
                currentPoint = get(canvas, 'CurrentPoint');
                newPosition = [currentPoint(1, 1) - 0.5 * chosenObj.Handle.Position(3), ...
                    currentPoint(1, 2) - 0.5 * chosenObj.Handle.Position(4), ...
                    chosenObj.Handle.Position(3), chosenObj.Handle.Position(4)];
                set(chosenObj.Handle, 'Position', newPosition);
                if ~isempty(chosenObj.Text)
                    textX = newPosition(1) + 0.5 * newPosition(3);
                    textY = newPosition(2) + 0.5 * newPosition(4);
                    set(chosenObj.Text, 'Position', [textX, textY]);
                end
            end
        end
    
        % Callback function to stop dragging
        function stopDrag(~, ~)
            dragging = false;
            set(fig, 'WindowButtonMotionFcn', []);
            set(fig, 'WindowButtonUpFcn', []);
            selectedObj = [];
        end
    
        % Callback function to select a function from the library
        function selectFunction(src, ~)
            selectedFunctionIndex = get(src, 'Value');
            selectedFunction = functionNames{selectedFunctionIndex};
        end
    
        % Callback function to set the selected rectangle as the source for drawing arrows
        function setAsSource(src, ~)
            selectedObj = src;
            if ~isempty(selectedObj) 
                selectedObj = src;
                sourceRectangle = getBase(selectedObj);
                msgbox('Rectangle set as source for arrows.', 'Info');
                
            else
                msgbox('Please select a valid source rectangle.', 'Error', 'error');
            end
            selectedObj = [];
        end
    
        % Callback function to set the selected rectangle as the target for drawing arrows
        function setAsTarget(src, ~)
            selectedObj = src;
            if ~isempty(selectedObj)             
                targetRectangle = getBase(selectedObj);
                msgbox('Rectangle set as target for arrows.', 'Info');
            else
                msgbox('Please select a valid target rectangle.', 'Error', 'error');
            end
            selectedObj = [];
        end
    
        % Callback function to draw an arrow between the source and target rectangles
        function drawArrow(src, ~)
            if isempty(sourceRectangle) || isempty(targetRectangle)
                msgbox('Please set both source and target rectangles for drawing an arrow.', 'Error', 'error');
                return;
            end
            
            % Get the positions of the source and target rectangles
            sourcePosition = sourceRectangle.Position;
            targetPosition = targetRectangle.Position;
            
            % Calculate the positions for drawing the arrow
            arrowStartX = sourcePosition(1) + 0.5 * sourcePosition(3);
            arrowStartY = sourcePosition(2) + 0.5 * sourcePosition(4);
            arrowEndX = targetPosition(1) + 0.5 * targetPosition(3);
            arrowEndY = targetPosition(2) + 0.5 * targetPosition(4);
            
            % Draw the arrow as a line with an arrowhead
            annotation('arrow', [arrowStartX, arrowEndX], [arrowStartY, arrowEndY], 'HeadLength', 10, 'HeadWidth', 10);
            
            % Clear the source and target rectangles
            sourceRectangle = [];
            targetRectangle = [];
        end


% function DragAndDropGUI()
%     % Create the main figure
%     fig = figure('Name', 'Drag and Drop Rectangles', 'Position', [100, 100, 900, 600]);
%     
%     % Create a canvas axis for drawing rectangles
%     canvas = axes('Parent', fig, 'Position', [0.4, 0.1, 0.5, 0.8]);
%     xlim([0, 800]);
%     ylim([0, 600]);
%     
%     % Create a button to create new rectangles
%     uicontrol('Style', 'pushbutton', 'String', 'Create Rectangle', ...
%         'Position', [20, 20, 120, 30], 'Callback', @createRectangle);
%     
%     % Create a listbox for the library of MATLAB functions
%     libraryBox = uicontrol('Style', 'listbox', 'Position', [20, 80, 300, 500], ...
%         'Callback', @selectFunction);
%     
%     % Initialize an array to store information about rectangles
%     rectangles = struct('Position', [], 'Color', [], 'Handle', [], 'Text', []);
%     
%     % Initialize variables for drag-and-drop
%     dragging = false;
%     selectedObj = [];
%     selectedFunction = '';
%     
%     % Get a list of .m files in a specified folder
%     function functionList = getFunctionList(folderPath)
%         functionList = {};
%         files = dir(fullfile(folderPath, '*.m'));
%         for i = 1:numel(files)
%             functionList{i} = files(i).name;
%         end
%     end
% 
%     % Populate the library listbox with function names
%     libraryPath = 'C:\Users\Nate\Documents\GitHub\SignalFlowEEG\Modules'; % Replace with the actual folder path
%     functionNames = getFunctionList(libraryPath);
%     set(libraryBox, 'String', functionNames);
% 
%     % Callback function to create a new rectangle
%     function createRectangle(~, ~)
%         if ~isempty(selectedFunction)
%             % Generate a random color for the rectangle
%             color = rand(1, 3);
% 
%             % Create a rectangle with default position
%             rect = rectangle(canvas, 'Position', [50, 50, 200, 50], 'FaceColor', color, ...
%                 'EdgeColor', 'k', 'LineWidth', 1.5, 'ButtonDownFcn', @startDrag);
% 
%             % Create text in the middle of the rectangle with the selected function name
%             textX = 100; % X position for the text
%             textY = 75; % Y position for the text
%             textObj = text('Position', [textX, textY], 'String', selectedFunction, 'HorizontalAlignment', 'center', 'ButtonDownFcn', @startDrag);
% 
%             % Store rectangle information
%             rectangles(end + 1) = struct('Position', [50, 50, 200, 50], 'Color', color, 'Handle', rect, 'Text', textObj);
%         else
%             msgbox('Please select a function from the library.', 'Error', 'error');
%         end
%     end
% 
%     % Callback function to start dragging a rectangle
%     function startDrag(src, ~)
%         selectedObj = src;
%         dragging = true;
%         set(fig, 'WindowButtonMotionFcn', @dragRect);
%         set(fig, 'WindowButtonUpFcn', @stopDrag);
%     end
% 
%     % Callback function to drag the selected rectangle
%     function dragRect(~, ~)
%         if dragging && ~isempty(selectedObj)
%             if isa(selectedObj,'matlab.graphics.primitive.Rectangle')
%                 item = 'Handle';
%             else
%                 item = 'Text';
%             end
%             for i = 1:numel(rectangles)
%                 if rectangles(i).(item) == selectedObj
%                     Chosentext = rectangles(i).Text;
%                     chosenObj.Handle = rectangles(i).Handle;
%                 end
%             end
%             currentPoint = get(canvas, 'CurrentPoint');
%             newPosition = [currentPoint(1, 1) - 0.5 * ChosenRect.Position(3), ...
%                 currentPoint(1, 2) - 0.5 * ChosenRect.Position(4), ...
%                 ChosenRect.Position(3), ChosenRect.Position(4)];
%             set(ChosenRect, 'Position', newPosition);
%             if ~isempty(Chosentext)
%                 textX = newPosition(1) + 0.5 * newPosition(3);
%                 textY = newPosition(2) + 0.5 * newPosition(4);
%                 set(Chosentext, 'Position', [textX, textY]);
%             end
%         end
%     end
% 
%     % Callback function to stop dragging
%     function stopDrag(~, ~)
%         dragging = false;
%         set(fig, 'WindowButtonMotionFcn', []);
%         set(fig, 'WindowButtonUpFcn', []);
%         selectedObj = [];
%     end
% 
%     % Callback function to select a function from the library
%     function selectFunction(src, ~)
%         selectedFunctionIndex = get(src, 'Value');
%         selectedFunction = functionNames{selectedFunctionIndex};
%     end
% end
