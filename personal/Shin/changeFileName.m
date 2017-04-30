function changeFileName(mouse_num,date_num)

initials = getInitials(mouse_num);
mouseID = sprintf('%s%03d',initials,mouse_num);
defaultDir = fullfile('\\research.files.med.harvard.edu\Neurobio\HarveyLab\Shin\ShinDataAll\Imaging',mouseID,num2str(date_num));

movInfo = dir(fullfile(defaultDir,'*.tif'));
for mi = 1:length(movInfo)
    movNames{mi} = movInfo(mi).name;
end

% Loop through each
k = 2;
for mi = 1:length(movInfo)
    % Get the file name (minus the extension)
    movNames{mi} = movInfo(mi).name;
    ind = strfind(movNames{mi},sprintf('FOV1_001_%03d_',k));
    if ~isempty(ind)
        newFileName = strrep(movNames{mi},sprintf('FOV1_001_%03d_',k),sprintf('FOV1_000_%03d',k));
        movefile(fullfile(defaultDir,movNames{mi}),fullfile(defaultDir,newFileName));
        k = k+1;
    end
end