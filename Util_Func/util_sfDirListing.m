function [results] = util_sfDirListing( filepath, varargin )
% Description:
% ShortTitle: Directory Listing 
% Category: Utility
% Tags:
%
%% Syntax:
%   [results] = util_sfDirListing( filepath, varargin )
%
%% Require Inputs:
%   filepath       - directory to get file list OR filename
%          
%% Function Specific Inputs:
%   'ext'          - specify file extenstion
%                  default: []
%
%   'keyword'      - keyword search
%                  default: []
%
%   'notKeyword'   - 
%                  default: false
%
%   'subdirOn'     - (true/false) search subdirectories
%                  default: false
%
%% Outputs:
%   [results]      - variable outputs
%
%% Disclaimer:
%  This file is part of the Cincinnati Childrens Brain Lab SignalFlowEEG Pipeline
%  
%  Please see http://github.com/cincibrainlab
%
%% Contact:
%  https://github.com/cincibrainlab/SignalFlowEEG/issues

timestamp    = datestr(now,'yymmddHHMMSS');  % timestamp
functionstamp = mfilename; % function name for logging/output

% Inputs: Function Specific

% Inputs: Common across SignalFlow functions
defaultExt = [];
defaultKeyword = [];
defaultSubDirOn = false;
defaultNotKeyword = false;

validateExt = @( ext ) ischar( ext ) & all(ismember(ext(1), '.'));

% MATLAB built-in input validation
ip = inputParser();   
addRequired(ip, 'filepath', @isfolder)
addParameter(ip,'ext', defaultExt, validateExt)
addParameter(ip,'keyword', defaultKeyword, @ischar)
addParameter(ip,'notKeyword', defaultNotKeyword, @mustBeNumericOrLogical)
addParameter(ip,'subdirOn', defaultSubDirOn, @mustBeNumericOrLogical)
parse(ip,filepath,varargin{:});

% START: Utilty code

if ip.Results.subdirOn, filepath = fullfile(filepath, '**/'); end
 
dirdump = dir(filepath);
results = dirdump(~cellfun('isempty', {dirdump.date}));

try
filelist = cell2table([{results([results.isdir] == false).folder}' {results([results.isdir] == false).name}'], ...
    'VariableNames', {'filepath','filename'});
catch
    results = []; % fixed for truly empty directory
    return;
end
if ~isempty(ip.Results.ext)
    filelist = filelist(contains(filelist.filename,ip.Results.ext),:);
end

if ~isempty(ip.Results.keyword)
    if ~ip.Results.notKeyword
        filelist = filelist(contains(filelist.filename,ip.Results.keyword),:);
    else
        filelist = filelist(~contains(filelist.filename,ip.Results.keyword),:);
    end
end

% END: Utility code

% QI Table
qi_table = cell2table({functionstamp, timestamp}, 'VariableNames',...
 {'scriptname','timestamp'});

% Outputs: 
results = filelist;


end