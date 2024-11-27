function SK2Pinit(obj)
%Example of an Acq2P Initialization Function. Allows user selection of
%movies to form acquisition, sorts alphabetically, assigns an acquisition
%name and default directory, and assigns the object to a workspace variable
%named after the acquisition name

%Initialize user selection of multiple tif files
space_ind = strfind(obj.acqName,'_');
movie_header = obj.acqName(space_ind(2)+1:end);
movInfo = dir(fullfile(obj.defaultDir,[movie_header,'*.tif']));
% movInfo = dir([obj.defaultDir,obj.acqName,'*.tif']);
for mi = 1:length(movInfo)
    movNames{mi} = movInfo(mi).name;
end
% [movNames, movPath] = uigetfile('Z:\HarveyLab\Tier2\Shin\ShinDataAll\Imaging\*.tif','MultiSelect','on');
% [movNames, movPath] = uigetfile('E:\Imaging\*.tif','MultiSelect','on');

% test

%Do not include the overview image 
k = 1;
for mi = 1:length(movNames) 
    if isempty(strfind(movNames{mi},'overview')) % && isempty(strfind(movNames{mi},'00005'));
        temp{k} = movNames{mi};
        k = k+1;
    end
end

%sort movie order alphabetically for consistent results
movNames = sort(temp);

%Attempt to automatically name acquisition from movie filename, raise
%warning and create generic name otherwise
if isempty(obj.acqName)
    try
        acqNameInd = find(movNames{1} == '_',1,'last');
        obj.acqName = movNames{1}(1:acqNameInd-1);
    catch
        obj.acqName = sprintf('%s_%.0f',date,now);
        warning('Automatic Name Generation Failed, using date_time')
    end
end

ind = strfind(obj.defaultDir,'Imaging');
ind = ind+3;
obj.initials = obj.defaultDir(ind+8:ind+9);
obj.mouseNum = str2double(obj.defaultDir(ind+10:ind+12));
obj.recDate = obj.defaultDir(ind+14:ind+19);

%Attempt to add each selected movie to acquisition in order
for nMov = 1:length(movNames)
    obj.addMovie(fullfile(obj.defaultDir,movNames{nMov}));
end

%Automatically fill in fields for motion correction
obj.motionRefMovNum = floor(nMov/2);
obj.motionRefChannel = 1;
obj.binFactor = 1;

% Default motion correction function
obj.motionCorrectionFunction = @lucasKanade_plus_nonrigid.m;
obj.motionCorrectionDone = false(1,length(movNames));

% Customized motion correction function
computerName = getComputerName;
switch computerName
    case 'shin-pc'
        obj.motionCorrectionFunction = @lucasKanade_plus_nonrigid;
        % obj.motionCorrectionFunction = @withinFile_fullFrame_fft;
        % obj.motionCorrectionFunction = @lucasKanade_affineReg;
    case 'harveylab41223' 
        obj.motionCorrectionFunction = @lucasKanade_plus_nonrigid;
end

%Assign acquisition object to acquisition name variable in workspace
assignin('base',obj.acqName,obj);

%Notify user of success
fprintf('Successfully added %03.0f movies to acquisition: %s\n',length(movNames),obj.acqName),
