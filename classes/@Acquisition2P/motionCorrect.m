function motionCorrect(obj,writeDir,motionCorrectionFunction,namingFunction,varargin)
%Wrapper function managing motion correction of an acquisition object
%
%motionCorrect(obj,writeDir,motionCorrectionFunction,namingFunction)
%
%writeDir is an optional argument specifying location to write motion
%   corrected data to, defaults to obj.defaultDir\Corrected
%motionCorrectionFunction is a handle to a motion correction function,
%   and is optional only if acquisition already has a function handle
%   assigned to motionCorectionFunction field. If argument is provided,
%   function handle overwrites field in acq obj.
%namingFunction is a handle to a function for naming. If empty, uses
%   default naming function which is a local function of motionCorrect.
%   All naming functions must take in the following arguments (in
%   order): obj.acqName, nSlice, nChannel, movNum.

%% Error checking and input handling
if ~exist('motionCorrectionFunction', 'var')
    motionCorrectionFunction = [];
end

if nargin < 4 || isempty(namingFunction)
    namingFunction = @defaultNamingFunction;
end

if isempty(motionCorrectionFunction) && isempty(obj.motionCorrectionFunction)
    error('Function for correction not provided as argument or specified in acquisition object');
elseif isempty(motionCorrectionFunction)
    %If no argument but field present for object, use that function
    motionCorrectionFunction = obj.motionCorrectionFunction;
else
    %If using argument provided, assign to obj field
    obj.motionCorrectionFunction = motionCorrectionFunction;
end

motionCorrectionFunctionName = func2str(motionCorrectionFunction);
fprintf('\nMotion-correction function: %s\n',motionCorrectionFunctionName)

if isempty(obj.acqName)
    error('Acquisition Name Unspecified'),
end

if ~exist('writeDir', 'var') || isempty(writeDir) %Use Corrected in Default Directory if non specified
    if isempty(obj.defaultDir)
        error('Default Directory unspecified'),
    else
        writeDir = [obj.defaultDir,'Corrected'];
    end
end

if isempty(obj.defaultDir)
    obj.defaultDir = writeDir;
end

if isempty(obj.motionRefMovNum)
    if length(obj.Movies)==1
        obj.motionRefMovNum = 1;
    else
        error('Motion Correction Reference not identified');
    end
end

if ~isempty(varargin)
    ajp = varargin{1};
end

%%%%%% LEGACY PART (commented out by SK 17/03/08) %%%%%% 
% Collecting movie info
% [nSlices, nChannels] = collectMovieInfo(movNum);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Load movies and motion correct
%Calculate Number of movies and arrange processing order so that
%reference is first
nMovies = length(obj.Movies);
if isempty(obj.motionRefMovNum)
    obj.motionRefMovNum = floor(nMovies/2);
end
movieOrder = 1:nMovies;
movieOrder([1 obj.motionRefMovNum]) = [obj.motionRefMovNum 1];

%Load movies one at a time in order, apply correction, and save as
%split files (slice and channel)
for movNum = movieOrder
    
    % check motion correction has been done already
    if obj.motionCorrectionDone(movNum)
        fprintf('\nSkipping motion correction:\n#%03d has been motion-corrected already\n',movNum)
        continue
    end
    
    fprintf('\nLoading Movie #%03.0f of #%03.0f\n',movNum,nMovies),
    [mov, scanImageMetadata] = obj.readRaw(movNum,'single');
    if obj.binFactor > 1
        mov = binSpatial(mov, obj.binFactor);
    end
    
    % Apply line shift:
    fprintf('Line Shift Correcting Movie #%03.0f of #%03.0f\n', movNum, nMovies),
    mov = correctLineShift(mov);
    try
        [movStruct, nSlices, nChannels] = parseScanimageTiff(mov, scanImageMetadata, movNum);
    catch
        error('parseScanimageTiff failed to parse metadata'),
    end
    clear mov
    
    % Find motion:
    fprintf('Identifying Motion Correction for Movie #%03.0f of #%03.0f\n', movNum, nMovies),
    obj.motionCorrectionFunction(obj, movStruct, scanImageMetadata, movNum, 'identify');
    
    % Apply motion correction and write separate file for each
    % slice\channel:
    fprintf('Applying Motion Correction for Movie #%03.0f of #%03.0f\n', movNum, nMovies),
    
    switch motionCorrectionFunctionName
        case 'withinFile_fullFrame_fft'
            [obj, movStruct] = obj.motionCorrectionFunction(obj, movStruct, scanImageMetadata, movNum, 'apply');
        case 'withinFile_withinFrame_lucasKanade'
            movStruct = obj.motionCorrectionFunction(obj, movStruct, scanImageMetadata, movNum, 'apply');
    end
    
    for nSlice = 1:nSlices
        for nChannel = 1:nChannels            
            % Create movie fileName and save in acq object
            movFileName = feval(namingFunction,obj.acqName, nSlice, nChannel, movNum);
            obj.correctedMovies.slice(nSlice).channel(nChannel).fileName{movNum} = fullfile(writeDir,movFileName);
            % Determine 3D-size of movie and store w/ fileNames
            obj.correctedMovies.slice(nSlice).channel(nChannel).size(movNum,:) = ...
                size(movStruct.slice(nSlice).channel(nChannel).mov);            
            % Write corrected movie to disk
            fprintf('Writing Movie #%03.0f of #%03.0f\n',movNum,nMovies),
            
            count = 0;
            err_count = 0;
            while count == err_count && count<10
                count = count + 1;
                try
                    tiffWrite(movStruct.slice(nSlice).channel(nChannel).mov, movFileName, writeDir, 'int16');
                catch
                    % Sometimes, disk access fails due to intermittent
                    % network problem. In that case, wait and re-try once:
                    err_count = err_count + 1;
                    fprintf('tiffWrite Error %d\n',err_count)
                    pause(60);
                    % tiffWrite(movStruct.slice(nSlice).channel(nChannel).mov, movFileName, writeDir, 'int16');
                end
            end
        end
    end
    obj.motionCorrectionDone(movNum) = true;
    % save after each file so that motion correction resumes from the interrupted file
    ajp.saveCurrentAcq;
end

if all(obj.motionCorrectionDone)
    % Store SI metadata in acq object
    obj.metaDataSI = scanImageMetadata;

    %Assign acquisition to a variable with its own name, and write to same
    %directory. Need to ensure that it is a valid variable name:
    if verLessThan('matlab', 'R2014a')
        acqVarName = genvarname(obj.acqName);
        eval([acqVarName ' = obj;'])
    else
        acqVarName = matlab.lang.makeValidName(obj.acqName);
        eval([acqVarName ' = obj;'])
    end

    save(fullfile(obj.defaultDir, acqVarName), acqVarName)

    display('Motion Correction Completed!')

end
end

function movFileName = defaultNamingFunction(acqName, nSlice, nChannel, movNum)

movFileName = sprintf('%s_Slice%02.0f_Channel%02.0f_File%03.0f.tif',...
    acqName, nSlice, nChannel, movNum);
end