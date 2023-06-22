function EEG = util_sfImportEegFile(varargin)
    defaultNetType      = 'undefined';

    validateFileOrFolder = @( filepath ) exist(filepath, 'file');
    % MATLAB built-in input validation
    ip = inputParser();
    addRequired(ip, 'filepath', validateFileOrFolder)
    addParameter(ip,'nettype', defaultNetType, @ischar);
    parse(ip,varargin{:});
    filepath = ip.Results.filepath;
    nettype = ip.Results.nettype;
    chanxml = 'cfg_sfEegSystems.xml';
    
    % START: Utilty code
%     %EGI128
%     filepath = 'C:\Users\Nate\Documents\VHTP_IMPORT_TESTING\128_EGI\0012_rest.raw';
%     nettype = 'EGI128';
%     ImportTestEEG = util_sfImportEegFile('C:\Users\Nate\Documents\VHTP_IMPORT_TESTING\128_EGI\0012_rest.raw','nettype','EGI128');

%     %EGI64
%     filepath = '';
%     nettype = 'EGI64';

%     %EGI32
%     filepath = 'C:\Users\Nate\Documents\VHTP_IMPORT_TESTING\32_EGI\32_rest.raw';
%     nettype = 'EGI32';
%     ImportTestEEG = util_sfImportEegFile('C:\Users\Nate\Documents\VHTP_IMPORT_TESTING\32_EGI\32_rest.raw','nettype','EGI32');

%     %NeuroNexusH32MEA
%     filepath = 'C:\Users\Nate\Documents\testImport\1-Import\11rest.edf';
%     nettype = 'NeuroNexusH32MEA';
%     ImportTestEEG = util_sfImportEegFile('C:\Users\Nate\Documents\VHTP_IMPORT_TESTING\raw_files_ForNate_3.10.2022\MEA_30_EDF\11rest.edf','nettype','NeuroNexusH32MEA');

%     %EDFGENERIC
%     filepath = '';
%     nettype = 'EDFGENERIC';

    
    
    filepath = fullfile(filepath);
    [~,importEEGName,~] = fileparts(filepath);
    
    
    % STEP 1: Get Net Type
    if ~exist(chanxml,'file'), error('Channel XML File is missing. Download template from GITHUB or add to path'); end
    
    netInfo = util_sfReadNetCatalog('nettype', nettype);
    
    switch nettype
        case 'EGI128'
            try EEG = pop_readegi(filepath);
            catch, error('Check if EEGLAB 2021 is installed'); end

            % modified from EEGLAB readegilocs due to fixed path bug
            locs = readlocs(netInfo.net_file);
            locs(1).type = 'FID'; locs(2).type = 'FID'; locs(3).type = 'FID';
            locs(end).type = 'REF';

            if EEG.nbchan == 256 || EEG.nbchan == 257
                if EEG.nbchan == 256
                    chaninfo.nodatchans = locs([end]);
                    locs(end) = [];
                end
            elseif mod(EEG.nbchan,2) == 0
                chaninfo.nodatchans = locs([1 2 3 end]);
                locs([1 2 3 end]) = [];
            else
                chaninfo.nodatchans = locs([1 2 3]);
                locs([1 2 3]) = [];
            end % remove reference

            chaninfo.filename = netInfo.net_file;
            EEG.chanlocs   = locs;
            EEG.urchanlocs = locs;
            EEG.chaninfo   = chaninfo;

        case 'EGI64'
            try EEG = pop_readegi(filepath);
            catch, error('Check if EEGLAB 2021 is installed'); end

            locs = readlocs(netInfo.net_file);
            locs(1).type = 'FID'; locs(2).type = 'FID'; locs(3).type = 'FID';
            %Remove just the file identifiers for non-ref datasets
            %Otherwise remove file identifiers and ref
            if mod(EEG.nbchan,2) ~= 0
                chaninfo.nodatchans = locs([1 2 3]);
                locs([1 2 3]) = [];
            else
                locs(end).type = 'REF';
                chaninfo.nodatchans = locs([1 2 3 end]);
                locs([1 2 3 end]) = [];
            end

            chaninfo.filename = netInfo.net_file;
            EEG.chanlocs = locs;
            EEG.urchanlocs = locs;
            EEG.chaninfo = chaninfo;


        case 'EGI32'
            try EEG = pop_readegi(filepath);
            catch, error('Check if EEGLAB 2021 is installed'); end

            locs = readlocs(netInfo.net_file);
            locs(1).type = 'FID'; locs(2).type = 'FID'; locs(3).type = 'FID';
            %Remove just the file identifiers for non-ref datasets
            %Otherwise remove file identifiers and ref
            if mod(EEG.nbchan,2) ~= 0
                chaninfo.nodatchans = locs([1 2 3]);
                locs([1 2 3]) = [];
            else
                locs(end).type = 'REF';
                chaninfo.nodatchans = locs([1 2 3 end]);
                locs([1 2 3 end]) = [];
            end

            chaninfo.filename = netInfo.net_file;
            EEG.chanlocs = locs;
            EEG.urchanlocs = locs;
            EEG.chaninfo = chaninfo;
            
        case 'NeuroNexusH32MEA'
            try         
                try
                    EEG = pop_biosig( fullfile(filepath) );
                catch
                    error('Biosig Toolbox Error; Check if EEGLAB >21 is installed.');
                end
                
                % Create a valid channel location structure in JSON format.
                valid_chanlocs_json = '[{"labels":"Ch 01","sph_radius":1,"sph_theta":134,"sph_phi":-11.999999999999996,"theta":-134,"radius":0.56666666666666665,"X":-0.67947841839412348,"Y":0.70362049981358643,"Z":-0.22495105434386489,"ref":"","type":"","urchan":[]},{"labels":"Ch 02","sph_radius":1,"sph_theta":153,"sph_phi":8.0000000000000018,"theta":-153,"radius":0.45555555555555555,"X":-0.88233530994415432,"Y":0.44957229540410149,"Z":0.13917310096006547,"ref":"","type":"","urchan":[]},{"labels":"Ch 03","sph_radius":1,"sph_theta":171,"sph_phi":16.000000000000004,"theta":-171,"radius":0.41111111111111109,"X":-0.949426969338986,"Y":0.15037445916777609,"Z":0.27563735581699922,"ref":"","type":"","urchan":[]},{"labels":"Ch 04","sph_radius":1,"sph_theta":123,"sph_phi":0.99999999999999645,"theta":-123,"radius":0.49444444444444446,"X":-0.544556083851976,"Y":0.83854283435573385,"Z":0.017452406437283449,"ref":"","type":"","urchan":[]},{"labels":"Ch 05","sph_radius":1,"sph_theta":135,"sph_phi":20.999999999999996,"theta":-135,"radius":0.38333333333333336,"X":-0.66014105035920045,"Y":0.66014105035920057,"Z":0.35836794954530016,"ref":"","type":"","urchan":[]},{"labels":"Ch 06","sph_radius":1,"sph_theta":163,"sph_phi":40,"theta":-163,"radius":0.27777777777777779,"X":-0.73257194423373362,"Y":0.22396971972807536,"Z":0.64278760968653925,"ref":"","type":"","urchan":[]},{"labels":"Ch 07","sph_radius":1,"sph_theta":107,"sph_phi":13.000000000000004,"theta":-107,"radius":0.42777777777777776,"X":-0.2848782368720626,"Y":0.93179472702213151,"Z":0.20791169081775929,"ref":"","type":"","urchan":[]},{"labels":"Ch 08","sph_radius":1,"sph_theta":115,"sph_phi":36,"theta":-115,"radius":0.3,"X":-0.3419053558814254,"Y":0.7332184018470006,"Z":0.57357643635104594,"ref":"","type":"","urchan":[]},{"labels":"Ch 09","sph_radius":1,"sph_theta":146,"sph_phi":62.999999999999993,"theta":-146,"radius":0.15000000000000002,"X":-0.37637518186712421,"Y":0.2538682656974926,"Z":0.88294759285892688,"ref":"","type":"","urchan":[]},{"labels":"Ch 10","sph_radius":1,"sph_theta":81,"sph_phi":27.000000000000004,"theta":-81,"radius":0.35,"X":0.1393841289587629,"Y":0.88003675533505055,"Z":0.40673664307580026,"ref":"","type":"","urchan":[]},{"labels":"Ch 11","sph_radius":1,"sph_theta":74,"sph_phi":54,"theta":-74,"radius":0.2,"X":0.16201557273012504,"Y":0.56501544846619534,"Z":0.80901699437494745,"ref":"","type":"","urchan":[]},{"labels":"Ch 12","sph_radius":1,"sph_theta":40,"sph_phi":41.000000000000007,"theta":-40,"radius":0.27222222222222214,"X":0.578141080098311,"Y":0.485117967078927,"Z":0.65605902899050739,"ref":"","type":"","urchan":[]},{"labels":"Ch 13","sph_radius":1,"sph_theta":10,"sph_phi":51,"theta":-10,"radius":0.21666666666666667,"X":0.61975960023455456,"Y":0.10928033907444426,"Z":0.77714596145697079,"ref":"","type":"","urchan":[]},{"labels":"Ch 14","sph_radius":1,"sph_theta":23,"sph_phi":17,"theta":-23,"radius":0.40555555555555556,"X":0.88028316924362582,"Y":0.37365803647709639,"Z":0.29237170472273671,"ref":"","type":"","urchan":[]},{"labels":"Ch 15","sph_radius":1,"sph_theta":6,"sph_phi":22,"theta":-6,"radius":0.37777777777777777,"X":0.92210464439862283,"Y":0.09691710348444578,"Z":0.374606593415912,"ref":"","type":"","urchan":[]},{"labels":"Ch 16","sph_radius":1,"sph_theta":-6,"sph_phi":22,"theta":6,"radius":0.37777777777777777,"X":0.92210464439862283,"Y":-0.09691710348444578,"Z":0.374606593415912,"ref":"","type":"","urchan":[]},{"labels":"Ch 17","sph_radius":1,"sph_theta":-21,"sph_phi":17,"theta":21,"radius":0.40555555555555556,"X":0.89278740193327311,"Y":-0.3427089745348918,"Z":0.29237170472273671,"ref":"","type":"","urchan":[]},{"labels":"Ch 18","sph_radius":1,"sph_theta":-10,"sph_phi":51,"theta":10,"radius":0.21666666666666667,"X":0.61975960023455456,"Y":-0.10928033907444426,"Z":0.77714596145697079,"ref":"","type":"","urchan":[]},{"labels":"Ch 19","sph_radius":1,"sph_theta":-39,"sph_phi":41.000000000000007,"theta":39,"radius":0.27222222222222214,"X":0.58651950234301287,"Y":-0.47495412815485349,"Z":0.65605902899050739,"ref":"","type":"","urchan":[]},{"labels":"Ch 20","sph_radius":1,"sph_theta":-77,"sph_phi":54,"theta":77,"radius":0.2,"X":0.1322229122309666,"Y":-0.57272035435602286,"Z":0.80901699437494745,"ref":"","type":"","urchan":[]},{"labels":"Ch 21","sph_radius":1,"sph_theta":-83,"sph_phi":24.000000000000004,"theta":83,"radius":0.36666666666666664,"X":0.11133318509365875,"Y":-0.90673602833257383,"Z":0.4539904997395468,"ref":"","type":"","urchan":[]},{"labels":"Ch 22","sph_radius":1,"sph_theta":-146,"sph_phi":62,"theta":146,"radius":0.15555555555555556,"X":-0.38920956479563679,"Y":-0.26252516629119138,"Z":0.89100652418836779,"ref":"","type":"","urchan":[]},{"labels":"Ch 23","sph_radius":1,"sph_theta":-114,"sph_phi":34.999999999999993,"theta":114,"radius":0.30555555555555558,"X":-0.3331791526627837,"Y":-0.74833262917885923,"Z":0.58778525229247314,"ref":"","type":"","urchan":[]},{"labels":"Ch 24","sph_radius":1,"sph_theta":-106,"sph_phi":11.999999999999996,"theta":106,"radius":0.43333333333333335,"X":-0.26961401826500792,"Y":-0.9402558215593757,"Z":0.22495105434386506,"ref":"","type":"","urchan":[]},{"labels":"Ch 25","sph_radius":1,"sph_theta":-162,"sph_phi":40,"theta":162,"radius":0.27777777777777779,"X":-0.72855155939999616,"Y":-0.23672075137025703,"Z":0.64278760968653925,"ref":"","type":"","urchan":[]},{"labels":"Ch 26","sph_radius":1,"sph_theta":-133,"sph_phi":20.999999999999996,"theta":133,"radius":0.38333333333333336,"X":-0.63670031985753939,"Y":-0.68277750067793253,"Z":0.35836794954530016,"ref":"","type":"","urchan":[]},{"labels":"Ch 27","sph_radius":1,"sph_theta":-121,"sph_phi":0.99999999999999645,"theta":121,"radius":0.49444444444444446,"X":-0.51495963211660256,"Y":-0.85703674997043233,"Z":0.017452406437283449,"ref":"","type":"","urchan":[]},{"labels":"Ch 28","sph_radius":1,"sph_theta":-171,"sph_phi":16.000000000000004,"theta":171,"radius":0.41111111111111109,"X":-0.949426969338986,"Y":-0.15037445916777609,"Z":0.27563735581699922,"ref":"","type":"","urchan":[]},{"labels":"Ch 29","sph_radius":1,"sph_theta":-153,"sph_phi":8.0000000000000018,"theta":153,"radius":0.45555555555555555,"X":-0.88233530994415432,"Y":-0.44957229540410149,"Z":0.13917310096006547,"ref":"","type":"","urchan":[]},{"labels":"Ch 30","sph_radius":1,"sph_theta":-132,"sph_phi":-12.999999999999993,"theta":132,"radius":0.57222222222222219,"X":-0.65198083226766412,"Y":-0.72409807174522123,"Z":-0.20791169081775929,"ref":"","type":"","urchan":[]}]';
                
                % Decode the JSON format to a MATLAB structure.
                chanlocs = jsondecode(valid_chanlocs_json)';
                
                % Reorder true channel within edf import
                tempData = EEG.data;
                for i = 1 : 31
                    % skips channel 2 (reference)
                    if i ~=2
                        chan_as_char = num2str(i);
                        fixed_chanlocsIndex = str2num( edf2meaLookupTest( chan_as_char ) );
                        EEG.data(fixed_chanlocsIndex,:) = tempData(i,:);
                    end
                end
                
                % Ceates Mapping based on Table given by Carrie Jonak (Binder Lab at UC
                % Riverside, California) March 2nd 2020
                    
                
                % Remove irrelevant channels
                if EEG.nbchan == 33
                    EEG = pop_select( EEG, 'nochannel', [31,32,33]);
                elseif EEG.nbchan == 32
                    EEG = pop_select( EEG, 'nochannel', [31,32]);
                end
                
                %Assign correct chanlocs field to EEG data
                EEG.chanlocs = chanlocs;
                
                % Check EEG data
                EEG = eeg_checkset( EEG );
            catch e
                error('MEA EDF Import Failed.')
            end

        case 'EDFGENERIC'
            try
                edfFile = fullfile(filepath);
                EEG = pop_biosig( edfFile );
            catch e
                error('EDF Import Failed.')
            end
        otherwise
            
    end

    % Populate EEG SET File
    EEG.setname = importEEGName;
    EEG.filename = importEEGName;
    EEG.subject = importEEGName;

end

function meachan = edf2meaLookupTest( edfchan )
            
    meaValueSet = {'1',	'2','3','4','5','6','7','8','9', ...
        '10',	'11', '12',	'13','14','15','16','17','18','19', ...
        '20','21','22','23','24','25','26','27','28','29', ...
        '30'};

    edfKeySet = {'30',	'28',	'26',	'24',	'22',	'20',	'18',	'31',	'29',	'27',	'25',	'23',	'21',	'19', ...
        '17',	'15',	'13',	'11',	'9',	'7',	'5',	'3',	'1',	'16',	'14',	'12',	'10',	'8',	'6', ...
        '4'};

    chanMap = containers.Map(edfKeySet, meaValueSet);

    meachan = chanMap( edfchan );

end


function [results] = util_sfReadNetCatalog( varargin )
    % Inputs: Common across SignalFlow functions
    defaultXmlFile = 'cfg_sfEegSystems.xml';
    defaultNetType = [];
    
    % MATLAB built-in input validation
    ip = inputParser();
    addParameter(ip, 'xmlfile', defaultXmlFile, @ischar);
    addParameter(ip, 'nettype', defaultNetType, @ischar);
    parse(ip,varargin{:});
    
    % START: Utility code
    
    try
        cfgFilename = ip.Results.xmlfile;
        xmldata = ext_xml2struct( cfgFilename );
        eegList = xmldata.list;
        eegList = {eegList.listitem{:}};
        
        for i = 1 : length( eegList )
            eegItem(i) = eegList{i};
            fn = fieldnames(eegItem(i));
            for k=1 : numel(fn)
                if isfield(eegItem(i).(fn{k}), 'Text') == 1
                    eegItem(i).(fn{k})  = eegItem(i).(fn{k}).Text;
                else
                    if strcmp(fn{k}, 'net_regions')
                        regions = fieldnames(eegItem(i).(fn{k}));
                        for l = 1 : numel( regions )
                            eegItem(i).(fn{k}).(regions{l}) = cellfun(@str2double,regexp(eegItem(i).(fn{k}).(regions{l}).Text,'\d*','Match'));
                        end
                    end
                end
            end
            elecObj(i) = sfElectrodeConfigClass;
            elecObj(i).setSystemProperties( eegItem(i) );
            str = sprintf('\tLoaded(%d): %s: %s\n', i, elecObj(i).net_name, elecObj(i).net_displayname);
            fprintf('%s', str);
            
            
        end
    catch
        error("Electrode List Import Error");
    end
    % END: Utility code
    % Outputs:
    if ~isempty(ip.Results.nettype)
        searchframe = {elecObj.net_name};
        netindex = strcmpi(ip.Results.nettype,searchframe);
        results = elecObj(netindex);
    else
        results =  elecObj;
    end
end

function [ s ] = ext_xml2struct( file )
%Convert xml file into a MATLAB structure
% [ s ] = xml2struct( file )
%
% A file containing:
% <XMLname attrib1="Some value">
%   <Element>Some text</Element>
%   <DifferentElement attrib2="2">Some more text</Element>
%   <DifferentElement attrib3="2" attrib4="1">Even more text</DifferentElement>
% </XMLname>
%
% Will produce:
% s.XMLname.Attributes.attrib1 = "Some value";
% s.XMLname.Element.Text = "Some text";
% s.XMLname.DifferentElement{1}.Attributes.attrib2 = "2";
% s.XMLname.DifferentElement{1}.Text = "Some more text";
% s.XMLname.DifferentElement{2}.Attributes.attrib3 = "2";
% s.XMLname.DifferentElement{2}.Attributes.attrib4 = "1";
% s.XMLname.DifferentElement{2}.Text = "Even more text";
%
% Please note that the following characters are substituted
% '-' by '_dash_', ':' by '_colon_' and '.' by '_dot_'
%
% Written by W. Falkena, ASTI, TUDelft, 21-08-2010
% Attribute parsing speed increased by 40% by A. Wanner, 14-6-2011
% Added CDATA support by I. Smirnov, 20-3-2012
%
% Modified by X. Mo, University of Wisconsin, 12-5-2012

if (nargin < 1)
    clc;
    help ext_xml2struct
    return
end

if isa(file, 'org.apache.xerces.dom.DeferredDocumentImpl') || isa(file, 'org.apache.xerces.dom.DeferredElementImpl')
    % input is a java xml object
    xDoc = file;
else
    %check for existance
    if (exist(file,'file') == 0)
        %Perhaps the xml extension was omitted from the file name. Add the
        %extension and try again.
        if (~contains(file,'.xml'))
            file = [file '.xml'];
        end
        
        if (exist(file,'file') == 0)
            error(['The file ' file ' could not be found']);
        end
    end
    %read the xml file
    xDoc = xmlread(file);
end

%parse xDoc into a MATLAB structure
s = parseChildModules(xDoc);

end

% ----- Subfunction parseChildModules -----
function [children,ptext,textflag] = parseChildModules(theModule)
    % Recurse over module children.
    children = struct;
    ptext = struct; textflag = 'Text';
    if hasChildModules(theModule)
        childModules = getChildModules(theModule);
        numChildModules = getLength(childModules);
        
        for count = 1:numChildModules
            theChild = item(childModules,count-1);
            [text,name,attr,childs,textflag] = getNodeData(theChild);
            
            if (~strcmp(name,'#text') && ~strcmp(name,'#comment') && ~strcmp(name,'#cdata_dash_section'))
                %XML allows the same elements to be defined multiple times,
                %put each in a different cell
                if (isfield(children,name))
                    if (~iscell(children.(name)))
                        %put existsing element into cell format
                        children.(name) = {children.(name)};
                    end
                    index = length(children.(name))+1;
                    %add new element
                    children.(name){index} = childs;
                    if(~isempty(fieldnames(text)))
                        children.(name){index} = text;
                    end
                    if(~isempty(attr))
                        children.(name){index}.('Attributes') = attr;
                    end
                else
                    %add previously unknown (new) element to the structure
                    children.(name) = childs;
                    if(~isempty(text) && ~isempty(fieldnames(text)))
                        children.(name) = text;
                    end
                    if(~isempty(attr))
                        children.(name).('Attributes') = attr;
                    end
                end
            else
                ptextflag = 'Text';
                if (strcmp(name, '#cdata_dash_section'))
                    ptextflag = 'CDATA';
                elseif (strcmp(name, '#comment'))
                    ptextflag = 'Comment';
                end
                
                %this is the text in an element (i.e., the parentModule)
                if (~isempty(regexprep(text.(textflag),'[\s]*','')))
                    if (~isfield(ptext,ptextflag) || isempty(ptext.(ptextflag)))
                        ptext.(ptextflag) = text.(textflag);
                    else                       
                        %just append the text
                        ptext.(ptextflag) = [ptext.(ptextflag) text.(textflag)];
                    end
                end
            end
            
        end
    end
end
    
% ----- Subfunction getNodeData -----
function [text,name,attr,childs,textflag] = getNodeData(theModule)
    % Create structure of module info.
    
    %make sure name is allowed as structure name
    name = toCharArray(getModuleName(theModule))';
    name = strrep(name, '-', '_dash_');
    name = strrep(name, ':', '_colon_');
    name = strrep(name, '.', '_dot_');
    
    attr = parseAttributes(theModule);
    if (isempty(fieldnames(attr)))
        attr = [];
    end
    
    %parse child modules
    [childs,text,textflag] = parseChildModules(theModule);
    
    if (isempty(fieldnames(childs)) && isempty(fieldnames(text)))
        %get the data of any childless modules
        text.(textflag) = toCharArray(getTextContent(theModule))';
    end 
end
    
% ----- Subfunction parseAttributes -----
function attributes = parseAttributes(theModule)
    % Create attributes structure.
    
    attributes = struct;
    if hasAttributes(theModule)
        theAttributes = getAttributes(theModule);
        numAttributes = getLength(theAttributes);
        
        for count = 1:numAttributes            
            %Suggestion of Adrian Wanner
            str = toCharArray(toString(item(theAttributes,count-1)))';
            k = strfind(str,'=');
            attr_name = str(1:(k(1)-1));
            attr_name = strrep(attr_name, '-', '_dash_');
            attr_name = strrep(attr_name, ':', '_colon_');
            attr_name = strrep(attr_name, '.', '_dot_');
            attributes.(attr_name) = str((k(1)+2):(end-1));
        end
    end
end
