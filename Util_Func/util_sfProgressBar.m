classdef util_sfProgressBar < handle
    properties (Access = private)
        ProgressFigure
        ProgressBar
        ProgressBarContainer
        ProgressText
        StartTime
        LoopSize
        elapsedTimeArray
    end
    
    methods
        function obj = util_sfProgressBar(loopSize)
            obj.LoopSize = loopSize;
            obj.StartTime = tic;
            obj.ProgressFigure = uifigure('Name', 'Progress', 'Position', [100, 100, 350, 150]);
            obj.ProgressBarContainer = uipanel(obj.ProgressFigure, 'Position', [10, 75, 330, 22], 'BackgroundColor', 'white', 'BorderType', 'none');
            obj.ProgressBar = uipanel(obj.ProgressBarContainer, 'Position', [0, 0, 0, 22], 'BackgroundColor', 'blue', 'BorderType', 'none');
            obj.ProgressText = uilabel(obj.ProgressFigure, 'Position', [10, 40, 330, 30], 'Text', 'Initializing...');
            drawnow;
        end
        
        function iter(obj, idx)
            % Check if a parallel pool is open
            pool = gcp('nocreate');
            
            % If a parallel pool is open, get the number of workers
            if ~isempty(pool)
                numWorkers = pool.NumWorkers;
            else
                numWorkers = 1;
            end

            elapsedTime = toc(obj.StartTime);
            obj.elapsedTimeArray(idx) = toc;
            avgElapsedTime = mean(obj.elapsedTimeArray);

            remainingTime = (avgElapsedTime / numWorkers) * (obj.LoopSize - idx);
            
            progress = idx / obj.LoopSize;
            obj.ProgressBar.Position = [0, 0, progress * 330, 22];
            obj.ProgressText.Text = sprintf('Elapsed Time: %s\nEstimated Time Remaining: %s', duration(0, 0, elapsedTime, 'Format', 'hh:mm:ss'), duration(0, 0, remainingTime, 'Format', 'hh:mm:ss'));
            drawnow;
        end
        
        function close(obj)
            delete(obj.ProgressFigure);
        end
    end
end








