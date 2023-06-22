% Hi Ernie,
% 
% It was really great to see all of the work you guys have been doing with the preprocessing setup and visualization tools. Very impressive!
% 
% As discussed, I have a attached a set of scripts that we are using to preprocess HBCD data using the MADE pipeline.
% 
% The main script is HBCD_MADE_edit1_11_2023 which calls the other matlab scripts before and after ICA.
% 
% The write_ExistTasksmat script saves out a .mat file to a Task_completed folder, indicating which tasks were completed for each infant.
% 
% Of note, so far we have not been using parfor loops for ICA for example which would speed up the preprocessing. Is this something you have been using?
% 
% I am not sure where the most updated versions of the HAPPE scripts are. 
% 
% Hi Martin. If you could send these on to Ernie that would be great, thank you.
% 
% Ernie if you have any questions please feel free to get in touch anytime.
% 
% Thanks again
% 
% BW
% Marco

% Order should be the following 
% inflow_HappeMergeSet, should be run completely seperate. Need to edit
% execute so it run on entire folder 

% inflow_ImportSet
% Module for performing 1 Hz highpass
% Module for creating 1 second epochs
% Module for Find artifaceted epochs by detecting outlier voltage
% Module for Find artifaceted epochs by using thresholding of frequencies in the data.
% Module for
% Module for
% Module for
% Module for
% Module for
% Module for
% Module for


