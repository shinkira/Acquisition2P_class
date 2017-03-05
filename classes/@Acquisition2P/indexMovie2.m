function indexMovie2(obj, nSlice, nChannel, writeDir)
% Function for creating a single large binary file containing an entire
% movie for a given slice/channel, allowing rapid, indexed access to pixel
% data in specific frames.
% To access time-series data for specific pixels, use indexMovie (standard)

%% Input handling
if ~exist('writeDir','var') || isempty(writeDir)
    writeDir = obj.defaultDir;
end

if ~exist('nSlice','var') || isempty(nSlice)
    nSlice = 1;
end

if ~exist('nChannel','var') || isempty(nChannel)
    nChannel = 1;
end

%% Create new binary movie file:
thisFileName = sprintf('_slice%02.0f_chan%02.0f_mov2.bin',nSlice,nChannel);
movFileName = fullfile(writeDir,[obj.acqName, thisFileName]);

% Check if file exists and create unique name if it does:
if exist(movFileName, 'file')
    warning('File %s\nalready exists. Creating new file with different name.', thisFileName);
    thisFileName = [thisFileName(1:end-4), '_', datestr(now, 'YYMMDD_hh-mm-ss'), '.bin'];
    movFileName = fullfile(writeDir,[obj.acqName, thisFileName]);
end

fprintf('Saving file %s\n',movFileName);
fid = fopen(movFileName, 'A');

%% Write bin file in frame-major order:
fileList = sort(obj.correctedMovies.slice(nSlice).channel(nChannel).fileName);
nFiles = numel(fileList);

% Get file info:
movSizes = obj.correctedMovies.slice(nSlice).channel(nChannel).size;
h = movSizes(1, 1);
w = movSizes(1, 2);
nFrames = movSizes(:, 3);
nFramesTotal = sum(nFrames);

if ~isunix
    % Get number of strips from first movie (note: this does not work on Linux/Orchestra):
    t = Tiff(fileList{1});
    nStrips = t(1).numberOfStrips;
    t.close;
    readInStrips = 1;
elseif h==512 && w==512
    nStrips = 64; %Hard code for default movie size
    readInStrips = 0;
else
    nStrips = 1;
    warning('User needs to specify strip sizes on unix computers'),
    readInStrips = 0;
end

stripHeight = h/nStrips;
thisStrip = zeros(h, w, 'int16');
% thisStrip = zeros(stripHeight, w, nFramesTotal, 'int16');

tTotal = tic;
for iFile = 1:nFiles
    tFile = tic;
    t = Tiff(fileList{iFile});
    
    % Read current strip from all files:
    for iFrame = 1:nFrames(iFile)
        
        for iStrip = 1:nStrips
            % iFrameGlobal = sum(nFrames(1:iFile-1)) + iFrame;
%             t.setDirectory(iFrame);
            if readInStrips
                thisStrip(stripHeight*(iStrip-1)+1:stripHeight*iStrip,:) = readEncodedStrip(t,iStrip);
                % thisStrip(:,:,iFrameGlobal) = readEncodedStrip(t,iStrip);
            else
                tmpImg = t.read;
                thisStrip(:, :, iFrameGlobal) = tmpImg((1:8)+8*(iStrip-1), :);
            end
        end
        
        % Write current frame to bin file:
        thisStripBinShape = thisStrip';
        fwrite(fid, thisStripBinShape, 'int16');
        if iFrame < nFrames
            t.nextDirectory;
        end
    end
    
    t.close;
    
    % Change shape of strip such that continuous rows of pixels will be
    % written, rather than blocks of rows of length stripHeight. This means
    % that the pixel order in the binary file will be column-major (the
    % opposite of Matlab). This is caused by the fact that TIFF strips are
    % horizontal, not vertical.
    % thisStripBinShape = permute(thisStrip, [2, 1, 3]);
    % thisStripBinShape = reshape(thisStripBinShape, [], nFramesTotal);
    
    % fprintf('Writing strip %d: %1.3f\n', iStrip, toc(tWrite));
    
    if iFile==1 || ~mod(iFile, 10)
        fprintf('Finished file %d: %1.3f\n', iFile, toc(tFile));
        tFile = tic;
    end
    
end
fprintf('Done saving binary movie. Total time per TIFF file: %1.3f\n', toc(tTotal)/iFile);

fclose(fid);

% Add info to acq2p object last in case an error happens in the function:
obj.indexedMovie.slice(nSlice).channel(nChannel).fileName2 = movFileName;

obj.save;

function [h, w, nFrames] = getTiffSize(tiffObj)
tiffObj.setDirectory(1);
[h, w] = size(tiffObj.read);  

while ~tiffObj.lastDirectory
    tiffObj.nextDirectory;
end
nFrames = tiffObj.currentDirectory;
tiffObj.setDirectory(1);