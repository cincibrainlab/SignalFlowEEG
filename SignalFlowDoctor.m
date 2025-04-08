function [results, paths]  = SignalFlowDoctor( action )
timestamp = datetime('now', 'Format', 'yyMMddHHmmss'); % timestamp
maxRetry = 5;
[note, fixnote, failednote, successnote, successpath] = sf_utilities();

if nargin < 1, action = missing;
    fprintf('\nWelcome to SignalFlowEEG! - https://github.com/cincibrainlab/SignalFlowEEG\n', timestamp);
    fprintf('SignalFlowEEG is an extensible, easy to learn framework for EEG analysis.\n');
    fprintf('================================================================\n');
    fprintf('The SignalFlowEEG Doctor verifies the installation and any necessary toolkits.\n\n');
    note('Running tests ...');
end

if ~ismissing(action)
    isValidAction =  ismember(action, ['fix_vhtp','check_vhtp','fix_eeglab', 'check_eeglab', 'check_brainstorm',... 
        'check_biosig', 'check_braph', 'check_bct', 'fix_bct', 'fix_braph', 'fix_biosig', 'fix_viewprops', 'fix_cleanrawdata', 'fix_brainstorm', ...
        'fix_firfilt', 'check_spectralevents', 'fix_spectralevents'] );
else
    action = 'default';
    isValidAction = true;
end

% MATLAB built-in input validation
if isValidAction
    switch action
        case 'default'
            checks = runChecks;
            results = checks;
        case 'autofix'
            checks = runChecks;
            autoFix(checks);
            results = checks;
        case 'fix_vhtp'
            [results, paths] = fixHandler('vhtp');
        case 'check_vhtp'
            results = checkRequirements('vhtp');
        case 'check_eeglab'
            results = checkRequirements( 'eeglab' );
        case 'check_brainstorm'
            results = checkRequirements( 'brainstorm' );
        case 'fix_eeglab'
            [results, paths] = fixHandler('eeglab');
        case 'check_biosig'
            results = checkRequirements( 'biosig' );
        case 'check_braph'
            results = checkRequirements( 'braph' );
        case 'check_bct'
            results = checkRequirements( 'bct' );
        case 'fix_biosig'
            [results, paths]  = fixHandler('biosig');
        case 'fix_bct'
            [results, paths]  = fixHandler('bct');
        case 'fix_braph'
            [results, paths]  = fixHandler('braph');
        case 'fix_viewprops'
            results = fixHandler('viewprops');
        case 'fix_cleanrawdata'
            results = fixHandler('clean_rawdata');
        case 'fix_firfilt'
            results = fixHandler('firfilt');
        case 'fix_brainstorm'
            [results, paths]  = fixHandler('brainstorm');

        case 'check_spectralevents'
            results = checkRequirements( 'spectralevents' );
        case 'fix_spectralevents'
            [results, paths]  = fixHandler('spectralevents');

        otherwise
           note('No valid action requested.')

    end
else
    note('Action keyphrase is invalid.');
end

% check SignalFlowEEG version

% check other dependencies

% checkRequirement, send to messageHandler, send to guiHandler
    function checks = runChecks()
        note('Checking major tookits ...')

        % add path to SignalFlowEEG
        [sfdir, ~, ~] = fileparts(which('SignalFlowControl.m'));
        note(sprintf('Adding SignalFlowEEG to MATLAB Path (%s)...', sfdir))
        addpath(genpath(sfdir));

        % check eeglab
        checks.eeglab = SignalFlowDoctor('check_eeglab');
        % check for brainstorm
        checks.brainstorm = SignalFlowDoctor('check_brainstorm');
        % check spectral events toolkit
        checks.spectralevents = SignalFlowDoctor('check_spectralevents');
        % check braph toolkit
        checks.braph = SignalFlowDoctor('check_braph');
        % check braph toolkit
        checks.bct = SignalFlowDoctor('check_bct');
        % check vhtp toolkit
        checks.vhtp = SignalFlowDoctor('check_vhtp');



        % eeglab dependencies
        note('Checking eeglab plugins ...')
        if checks.eeglab
            checks.biosig = checkRequirements( 'biosig' );
            checks.clean_rawdata = checkRequirements( 'clean_rawdata' );
            checks.iclabel = checkRequirements( 'iclabel' );
            checks.viewprops = checkRequirements( 'viewprops' );
            checks.firfilt = checkRequirements( 'firfilt' );
        end
        msgHandler(checks);
        total_issues = sum(~struct2array(checks));
        fprintf('\n! SignalFlowDoctor found %d issues.\n\n', total_issues);
        if total_issues == 0
            paths = generatePathNames(checks);
        else
            paths = [];
        end
    end

% === CHECK DEPENDENCIES FUNCTIONS
    function results = checkRequirements( action )
        switch action
            case 'eeglab'
                results = checkCommand( 'eeglab nogui' );
            case 'brainstorm'
                results = checkScriptName( 'brainstorm' );
            case 'spectralevents'
                results = checkScriptName( 'spectralevents' );
            case 'braph'
                results =  checkScriptName( 'braph' );
            case 'bct'
                results =  checkScriptName( 'eigenvector_centrality_und.m' );
            case 'vhtp'
                results =  checkScriptName( 'htpAnalysisClass.m' );
            otherwise
                results = checkEeglabPlugin(action);
        end
    end
    function [isScriptValid, pathname] = checkScriptName( command )
            note(sprintf('Locating script %s ...', command));
            if exist(command,'file') == 2
                isScriptValid = true;
                 pathname = fileparts(which(command));
            else
                isScriptValid = false;
            end
    end
    function isCommandValid = checkCommand( command )
        try
            note(sprintf('Trying %s ...', command));
            evalc(command);
            isCommandValid = true;
        catch
            isCommandValid = false;
        end
    end
    function isPluginAvailable = checkEeglabPlugin( name_of_plugin )
        try 
            PLUGINLIST = evalin('base', 'PLUGINLIST'); % check current EEGLAB plugins
            isPluginAvailable = any(strcmpi(name_of_plugin, {PLUGINLIST.plugin}));
        catch 
            isPluginAvailable = false;
        end
    end
    function [results, plugin_path] = fixHandler( action )
        switch action
            case {'eeglab', 'brainstorm', 'spectralevents'}
                [results, plugin_path]  = addMatlabPath( action );
            case {'braph', 'bct', 'vhtp'}
                [results, plugin_path]  = addMatlabPathWithSubfolders( action );
            otherwise
                results = downloadEegLabPlugin( action );
        end

    end

    function [results, plugin_path] = addMatlabPathWithSubfolders( action )

         ToolIsAvailable = checkRequirements( action );
        try_matlab_path = missing;
        retryNum = 0;
        while ToolIsAvailable == false && retryNum < maxRetry
            try
                if ~ismissing(try_matlab_path), 
                    addpath(genpath(fullfile(try_matlab_path))); 
                    % addpath(genpath(fullfile(try_matlab_path))); 

                end
                assert(checkRequirements( action ) );
                ToolIsAvailable = true;
                successnote( action );
                results = ToolIsAvailable;
                plugin_path = try_matlab_path;
            catch
                if ~ismissing(try_matlab_path), rmpath(try_matlab_path); end
                try_matlab_path = uigetdir([], ...
                    sprintf('Choose %s directory or hit Cancel.', action));
                if try_matlab_path == false
                    failednote([action ': No directory selected.']);
                    switch action
                        otherwise
                    end
                    results = ToolIsAvailable;
                    break;
                end
            end
            retryNum = retryNum + 1;
        end
        results = ToolIsAvailable;


    end

    function [results, plugin_path] = addMatlabPath( action )

        ToolIsAvailable = checkRequirements( action );
        try_matlab_path = missing;
        retryNum = 0;
        while ToolIsAvailable == false && retryNum < maxRetry
            try
                if ~ismissing(try_matlab_path), 
                    addpath(fullfile(try_matlab_path)); 
                    % addpath(genpath(fullfile(try_matlab_path))); 

                end
                assert(checkRequirements( action ) );
                ToolIsAvailable = true;
                successnote( action );
                results = ToolIsAvailable;
                plugin_path = try_matlab_path;
            catch
                if ~ismissing(try_matlab_path), rmpath(try_matlab_path); end
                try_matlab_path = uigetdir([], ...
                    sprintf('Choose %s directory or hit Cancel.', action));
                if try_matlab_path == false
                    plugin_path = [];

                    failednote([action ': No directory selected.']);
                    switch action
                        case 'eeglab'
                            note('Install from https://eeglab.org/download/')
                        case 'brainstorm'
                            note('Install from https://neuroimage.usc.edu/brainstorm/Installation');
                        case 'spectralevents'
                            note('Install from https://github.com/jonescompneurolab/SpectralEvents')
                    end
                    results = ToolIsAvailable;
                    break;
                end
            end
            retryNum = retryNum + 1;
        end
        results = ToolIsAvailable;


    end

    function res = downloadGitHubRepository( action )
        switch action
            case 'spectralevents'
                zip = 'https://github.com/jonescompneurolab/SpectralEvents/archive/refs/heads/master.zip';
                name = 'SpectralEvents';
            otherwise
                note('Github repository not configured. Please see SignalFlowDoctor code.');
        end


    end

    function res = downloadEegLabPlugin( action )
        %TODO: Double check autodownload for all of these work as expected
        switch action
            case 'clean_rawdata'
                zip = 'http://sccn.ucsd.edu/eeglab/plugins/clean_rawdata2.7.zip';
                name = 'clean_rawdata';
                version = '2.7';
                pluginsize = 1.5;
            case 'biosig'
                zip = 'http://sccn.ucsd.edu/eeglab/plugins/BIOSIG3.8.1.zip';
                name = 'Biosig';
                version = '3.8.1';
                pluginsize = 4.3000;
            case 'iclabel'
                name = 'ICLabel';
            case 'viewprops'
                zip = 'http://sccn.ucsd.edu/eeglab/plugins/Viewprops1.5.4.zip';
                name = 'viewprops';
                version = '1.5.4';
                pluginsize = .19;
            case 'firfilt'
                zip =  'http://sccn.ucsd.edu/eeglab/plugins/firfilt2.4.zip';
                name = 'firfilt';
                version = '2.4';
                pluginsize = 42.7;
        end
        ToolIsAvailable = checkRequirements(action);
        retryNum = 0;
        while ToolIsAvailable == false && retryNum < maxRetry
            try
                assert(ToolIsAvailable);
                ToolIsAvailable = true;
            catch
                try
                    note(sprintf('Attemping EEGLAB Plugin Download of %s by name.', action ));
                    plugin_askinstall(name, 'sopen', true);
                    % assert(res);
                    % eeglab nogui;
                    checkRequirements('eeglab');
                    ToolIsAvailable = checkRequirements(action);
                    assert( ToolIsAvailable );
                    successnote(action);
                    res = ToolIsAvailable;
                    paths = [];
                catch
                    try
                        note(sprintf('Failed by name %s, trying more details.', action ));
                        plugin_install(zip, name, version, pluginsize, 1);
                    catch
                        failednote(action);
                        warning(sprintf(['%s Toolbox autoinstall failure. ...' ...
                            ' Please add through EEGLAB and restart.'], upper(action)));
                        res = false;

                        break;
                    end

                end
                retryNum = retryNum + 1;
            end
        end


    end

    % === Message Handlers
    %     Display success/fail output to the user
    function msgHandler( checks )
        check_fields = fieldnames(checks);
        for i = 1 : numel(check_fields)
            current_field = check_fields{i};
            check_now = checks.(current_field);
            if check_now
                successnote(current_field);
            else
                failednote(current_field);
                cmd = fixCommands(current_field);
                fixnote(cmd);
            end
        end
    end

    % === Fix Handlers
    %     Display 'fix' command to user
    function str = fixCommands( action )
        try
            switch action
                otherwise
                    str = sprintf( 'SignalFlowDoctor(''fix_%s'')', action);
            end
        catch
            note('FixCommands: Action not found.')
        end
    end

    function paths = generatePathNames( checks )
    check_fields = fieldnames(checks);
        for i = 1 : numel(check_fields)
            current_field = check_fields{i};
            check_now = checks.(current_field);
            lookup_field = missing;
            if check_now
                switch current_field
                    case 'biosig'
                        lookup_field = 'biosig';
                        script_name = 'biosig_installer.m';
                    case 'bct'
                        lookup_field = 'bct';
                        script_name = 'eigenvector_centrality_und';
                    case 'viewprops'
                    otherwise
                        lookup_field = current_field;
                        script_name = current_field;
                end
                if ~ismissing(lookup_field)
                  paths.([lookup_field '_dir']) = fileparts(which(script_name));
                         % checkScriptName( script_name );
                         
                    successpath(sprintf('%s_dir = %s', lookup_field, paths.([lookup_field '_dir'])));
                end
            else
                failednote(current_field);
                cmd = fixCommands(current_field);
                fixnote(cmd);
            end
        end

    end

% === UTILITIES ADDIN: 2/2 ================================================
    function [note, fixnote, failednote, successnote, successpath] = sf_utilities()
        note        = @(msg) fprintf('%s: %s\n', mfilename, msg );
        fixnote        = @(msg) fprintf('%s: \tFix command: %s\n', mfilename, msg );
        failednote = @(msg) fprintf('%s: [N] FAILED: %s\n', mfilename, upper(msg) );
        successnote = @(msg) fprintf('%s:[Y] SUCCESS: %s\n', mfilename, upper(msg) );
        successpath = @(msg) fprintf('%s:[Y] Path: %s;\n', mfilename, msg );

    end

% === UTILITIES ADDIN: 2/2 ================================================

end