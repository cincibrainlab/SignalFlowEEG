function hash = utilGetGitCommitVersion( filename )
%utilGetGitCommitVersion Performs a system call to `git hash-object` and returnd
%the hash value.
    directory = fileparts(which(filename));
    filename = fullfile(directory,filename);
%     command = [ 'git hash-object -- ' filename ];
    command = [' git rev-parse HEAD']
    [status,hash] = system(command);
    if( status ~= 0 )
        error('Unable to get hash from file.');
    end
end

