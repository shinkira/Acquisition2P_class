function changeFileName(varargin)

varargin2V(varargin);
if exist('initials','var') && exist('mouseID','var') && exist('date_num','var')
    defaultDir = fullfile('Z:\HarveyLab\Shin\ShinDataAll\Imaging',[initials,sprintf('%03d',mouseID)],num2str(date_num));
else
    return
end

movInfo = dir(fullfile(defaultDir,'*.tif'));
for mi = 1:length(movInfo)
    movNames{mi} = movInfo(mi).name;
end

% Loop through each
for mi = 1:length(movInfo)
    % Get the file name (minus the extension)
    movNames{mi} = movInfo(mi).name;
    ind = strfind(movNames{mi},'FOV1_overview_002');
    if ~isempty(ind)
        newFileName = strrep(movNames{mi},'FOV1_overview_002','FOV1_001');
        movefile(fullfile(defaultDir,movNames{mi}),fullfile(defaultDir,newFileName));
    end
end