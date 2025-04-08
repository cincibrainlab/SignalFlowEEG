function [results] = util_GetQAData(EEG)

fields_to_copy = {'setname', 'filename', 'filepath', 'subject', 'group', ...
                  'condition', 'session', 'comments', 'nbchan', 'trials', ...
                  'pnts', 'srate', 'xmin', 'xmax','datfile' ,'epochdescription'};

for i = 1:length(fields_to_copy)
    field_name = fields_to_copy{i};
    if isfield(EEG, field_name)
        results.(field_name) = EEG.(field_name);
    else
        results.(field_name) = [];
    end
end

% results.setname = EEG.setname;
% results.filename = EEG.filename;
% results.filepath = EEG.filepath;
% results.subject = EEG.subject;
% results.group = EEG.group;
% results.condition = EEG.condition;
% results.session = EEG.session;
% results.comments = EEG.comments;
% results.nbchan = EEG.nbchan;
% results.trials = EEG.trials;
% results.pnts = EEG.pnts;
% results.srate = EEG.srate;
% results.xmin = EEG.xmin;
% results.xmax = EEG.xmax;
% if isfield(results,'datfile')
%     results.datfile = EEG.datfile;
% else 
%     results.datfile = "";
% end
% results.epochdescription = EEG.epochdescription;
end

