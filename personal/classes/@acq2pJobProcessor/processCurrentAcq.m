function processCurrentAcq(ajp)
% Performs all processing of currently loaded acquisition.

%create cleanup obj
cleanupObj = onCleanup(@() moveBackToUnproc(ajp));

if ajp.debug
    ajp.log('Skipping all processing because debug mode is on.');
    return
end

%figure out pixel neighborhood
neighborhoodConstant = 1.5;
if isprop(ajp.currentAcq,'derivedData') && ~isempty(ajp.currentAcq.derivedData)...
        && isfield(ajp.currentAcq.derivedData(1),'SIData')
    if isfield(ajp.currentAcq.derivedData(1).SIData,'SI4')
        objectiveMag = 25;
        zoomFac = ajp.currentAcq.derivedData(1).SIData.SI4.scanZoomFactor;
    elseif isfield(ajp.currentAcq.derivedData(1).SIData,'SI5')
        objectiveMag = 16;
        zoomFac = ajp.currentAcq.derivedData(1).SIData.SI5.zoomFactor;
    end
    pxCovRad = round(objectiveMag*zoomFac/neighborhoodConstant);
else
    pxCovRad = [];
end

% Motion correction:
%check if motion correction already applied
if isempty(ajp.currentAcq.shifts)
    try
        ajp.log('Started motion correction.');
        ajp.currentAcq.motionCorrect([],[],ajp.nameFunc);
        ajp.saveCurrentAcq;
    catch err
        msg = sprintf('Motion correction aborted with error: %s', err.message);
        ajp.log(msg);
        printStack(ajp, err.stack);
        return % If motion correction fails, then no further processing can happen.
    end
else
    ajp.log('Motion correction already performed. Skipping...');
end

[mov, scanImageMetadata] = ajp.currentAcq.readRaw(1,'single');
[movStruct, nSlices, nChannels] = parseScanimageTiff(mov, scanImageMetadata);
for si = 1:nSlices
    for ni = 1:nChannels
        
        sliceNum = si; %Choose a slice to analyze
        channelNum = ni; %Choose the GCaMP channel
        movNums = []; %this will default to all movie files
        radiusPxCov = 11; %default, may need zoom level adjustment
        temporalBin = 8; %default (tested w/ 15-30hz imaging), may need adjustment based on frame rate
        writeDir = []; %empty defaults to the directory the object is saved in (the 'defaultDir')
        
        % Save binary movie file:
        % check if binary movie file created already
        if 1 % isempty(ajp.currentAcq.indexedMovie)
            try
                ajp.log('Started creation of binary movie file.');
                ajp.currentAcq.indexMovie(sliceNum,channelNum,writeDir);
                ajp.saveCurrentAcq;
            catch err
                msg = sprintf('Creation of binary movie file aborted with error: %s', err.message);
                ajp.log(msg);
                printStack(ajp, err.stack);
            end
        else
            ajp.log('Binary movie already created. Skipping...');
        end

        % Caclulate pixel covariance:
        %check if pixel covariance already calculated
        if 1 % isempty(ajp.currentAcq.roiInfo) ...
             %    || (~isempty(pxCovRad) && ajp.currentAcq.roiInfo.slice(1).covFile.nh ~= (2*pxCovRad + 1))
            % ROI info does not exist or a different neighborhood size was
            % requested:
            try
                ajp.log('Started pixel covariance calculation.');
                ajp.currentAcq.calcPxCov(movNums,radiusPxCov,temporalBin,sliceNum,channelNum,writeDir);
                ajp.saveCurrentAcq;
            catch err
                msg = sprintf('Pixel covariance calculation aborted with error: %s', err.message);
                ajp.log(msg);
                printStack(ajp, err.stack);
            end
        else
            ajp.log('Covariance already calculated. Skipping...');
        end
        
    end
end

% Move acqFile to done folder:
if ~exist(ajp.dir.done, 'dir');
    mkdir(ajp.dir.done);
end
movefile(fullfile(ajp.dir.inProgress, ajp.currentAcqFileName),...
    fullfile(ajp.dir.done, ajp.currentAcqFileName));

ajp.log('Done processing.');

end

function printStack(ajp, stack)
% Prints the whole error stack to log file:
for ii = 1:numel(stack)
    msg = sprintf('ERROR\t%d\t%s', stack(ii).line, stack(ii).file);
    ajp.log(msg);
end
end

function moveBackToUnproc(ajp)
%get error information
errInfo = lasterror; %#ok<LERR>
if isempty(errInfo.identifier)
    moveDest = fullfile(ajp.dir.jobs, ajp.currentAcqFileName);
else
    moveDest = fullfile(ajp.dir.error, ajp.currentAcqFileName);
end

if exist(fullfile(ajp.dir.inProgress, ajp.currentAcqFileName),'file')
    if ~exist(ajp.dir.error, 'dir');
        mkdir(ajp.dir.error);
    end
    movefile(fullfile(ajp.dir.inProgress, ajp.currentAcqFileName),...
        moveDest);
    msg = 'Exectuion terminated. Moved file to error folder.';
    ajp.log(msg);    
end
end
