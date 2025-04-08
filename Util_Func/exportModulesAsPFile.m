function exportModulesAsPFile(exportFileList, outputDir)
    OutputFullPath = [outputDir '\PFiles'];
    % Create the output directory if it doesn't exist
    if ~exist(OutputFullPath, 'dir')
        mkdir(OutputFullPath);
    end
    
    for i = 1:numel(exportFileList)
        % Get the full path of the source .m file
        fileToConvert = fullfile(exportFileList(i).folder,exportFileList(i).name);
        
        % Copy the .m file to the output directory
        copyfile(fileToConvert, OutputFullPath);
        [~, fileName, ext] = fileparts(fileToConvert);
        tempFullPath = fullfile(OutputFullPath, [fileName ext]);
        pcode(tempFullPath, '-inplace');
        % Delete the original .m file
        delete(tempFullPath);
    end
end