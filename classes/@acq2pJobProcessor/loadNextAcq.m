function success = loadNextAcq(ajp)
% Checks if there are new unprocessed acq2ps in the to-be-processed folder.
ajp.dir.jobs
acqFileList = dir(fullfile(ajp.dir.jobs, '*.mat'));

% Go to next un-done job:
if isempty(acqFileList)
    success = false;
    return
end
ajp.currentAcqFileName = acqFileList(1).name;
nextAcqFile = fullfile(ajp.dir.jobs, ajp.currentAcqFileName);

% Load next acquisition:
acq = load(nextAcqFile); % Load into structure in case variable has weird name.
name = fieldnames(acq);
ajp.currentAcq = acq.(name{1});

% Change the default directory when running on Orchestra
if isunix
    ajp.currentAcq.defaultDir = changePath4Orchestra(ajp.currentAcq.defaultDir);
    for mi = 1:length(ajp.currentAcq.Movies)
        ajp.currentAcq.Movies{mi} = changePath4Orchestra(ajp.currentAcq.Movies{mi});
    end
end
    
% Move acq file right away to inProgress directory:
if ~exist(ajp.dir.inProgress, 'dir');
    mkdir(ajp.dir.inProgress);
end
movefile(nextAcqFile, fullfile(ajp.dir.inProgress, ajp.currentAcqFileName));

% Log information:
msg = sprintf('Loaded acq2p for processing and moved file to "inProgress" folder: %s', nextAcqFile);
ajp.log(msg);

success = true;

return
