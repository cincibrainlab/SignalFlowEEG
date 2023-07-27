function [results] = util_GetQAData(EEG)
results.setname = EEG.setname;
results.filename = EEG.filename;
results.filepath = EEG.filepath;
results.subject = EEG.subject;
results.group = EEG.group;
results.condition = EEG.condition;
results.session = EEG.session;
results.comments = EEG.comments;
results.nbchan = EEG.nbchan;
results.trials = EEG.trials;
results.pnts = EEG.pnts;
results.srate = EEG.srate;
results.xmin = EEG.xmin;
results.xmax = EEG.xmax;
results.datfile = EEG.datfile;
results.epochdescription = EEG.epochdescription;
end

