function calcPxCov(obj, movNums, radiusPxCov, temporalBin, sliceNum, channelNum, writeDir)
% calcPxCov(obj, movNums, radiusPxCov, temporalBin, sliceNum, channelNum,
% writeDir) Function to calculate all pixel-pixel covariances within a
% square neighborhood around each pixel. Size of the neighborhood is
% radiusPxCov pixels in all directions around the center pixel.
%
% movNums - vector-list of movie numbers to use for calculation. defaults
% to 1:length(fileName)
%
% radiusPxCov - radius in pixels around each pixel to include in covariance
% calculation, defaults to 11 (despite the term "radius", the
% neighborhood will be square, with an edge length of radius*2+1).
%
% temporalBin - Factor by which movie is binned temporally to facilitate
% covariance computation, defaults to 8
%
% writeDir - Directory in which pixel covariance information will be saved,
% defaults to obj.defaultDir

%% Input handling / Error Checking
if ~exist('sliceNum','var') || isempty(sliceNum)
    sliceNum = 1;
end
if ~exist('channelNum','var') || isempty(channelNum)
    channelNum = 1;
end
if ~exist('movNums','var') || isempty(movNums)
    movNums = 1:length(obj.correctedMovies.slice(sliceNum).channel(channelNum).fileName);
end
if ~exist('radiusPxCov','var') || isempty(radiusPxCov)
    radiusPxCov = 11;
end 
if ~exist('temporalBin','var') || isempty(temporalBin)
    temporalBin = 8;
end 
if ~exist('writeDir','var') || isempty(writeDir)
    writeDir = obj.defaultDir;
end 

%% Loop over movies to get covariance matrix
nMovies = numel(movNums);
for m = 1:nMovies
    fprintf('\nProcessing movie %03.0f of %03.0f.\n',find(movNums==m),length(movNums));
    loopTime = tic;
    
    %Load movie:
    if exist('parallelIo', 'var')
        % A parallelIo object was created in a previous iteration, so we
        % can simply retrieve the pre-loaded movie:
        fprintf('Retrieving pre-loaded movie %1.0f of %1.0f...\n',m,nMovies)
        [~, mov] = fetchNext(parallelIo);
        delete(parallelIo); % Delete data on parallel worker.
    else
        % No parallelIo exists, so this is either the first movie or
        % pre-loading is switched off, so we load the movie conventionally.
        fprintf('\nLoading movie %1.0f of %1.0f\n',m,nMovies)
        ticLoad = tic;
        mov = obj.readCor(m, 'single');
        fprintf('Done loading (%1.0f s).\n', toc(ticLoad));
    end
    
    % Start parallel I/O job: This loads the mov for the next iteration:
    if m < nMovies
        parallelIo = parfeval(@obj.readCor, 1, m+1, 'single', [], [], false);
    end
    
    % Bin temporally using reshape and sum, and center data
    mov = mov(:,:,1:end-rem(end, temporalBin)); % Deal with movies that are not evenly divisible.
    movSize = size(mov);
    [h, w, z] = size(mov);
    z = z/temporalBin;
    mov = squeeze(sum(reshape(mov,movSize(1)*movSize(2),temporalBin,movSize(3)/temporalBin),2));
    mov = bsxfun(@minus,mov,mean(mov,2));
    
    if m == 1
        nPix = w*h;

        % Neighborhood is square, and the edge length must be odd:
        nh = 2*round(radiusPxCov)+1;

        % Create an adjacency matrix for the first pixel. An adjacency
        % matrix is an nPixel-by-nPixel matrix that is 1 if pixel i and j
        % are within a neighborhood (i.e. we need to calculate their
        % covariance), and 0 elsewhere. In our case, this matrix has a
        % characterisitic pattern with sparse bands that run parallel to
        % the diagonal. Because nPix-by-nPix is large, we simply assemble a
        % list of linear indices:

        % ...Make list of diagonals in adjacency matrix that are 1,
        % following the convention of spdiags();
        diags = bsxfun(@plus, (-nh+1:nh-1)', 0:h:h*(nh-1));
        diags = diags(:)';
        diags(diags<0) = [];
        nDiags = numel(diags);

        % Calculate covariance:
        pixCov = zeros(nPix, nDiags, 'single');
    end
    
    nChunks = 50; % Should be a few times the number of parallel workers.
    pixList = 1:nPix-diags(end);
    pixListChunked = mat2cell(pixList, 1, chunkSize(numel(pixList), nChunks));
    for ch = 1:nChunks
       pxHere = pixListChunked{ch};
       nPixHere = numel(pxHere);
       movHere = mov(pxHere(1):pxHere(end)+diags(end), :); % Each worker gets only the pixels it needs.
       future(ch) = parfeval(@calcPxCovChunk, 1, movHere, nPixHere, diags); %#ok<AGROW>
    end
    
    % Retrieve data:
    for ii = 1:nChunks
       [ch, pixCovChunk] = fetchNext(future);
       pxHere = pixListChunked{ch};
       pixCov(pxHere, :) = pixCov(pxHere, :) + pixCovChunk/z;
    end
    
    fprintf('Last movie took %3f seconds to process.\n', toc(loopTime));
end


% Shift into SPDIAGS format:
for ii = 1:nDiags
    pixCov(:, ii) = circshift(pixCov(:, ii), diags(ii));
end

%Correct covariance by number of movies summed
pixCov = pixCov / length(movNums);

%% Write results to disk
display('-----------------Saving Results-----------------')
covFileName = fullfile(writeDir,[obj.acqName '_pixCovFile.bin']);

% Write binary file to disk:
fileID = fopen(covFileName,'w');
fwrite(fileID, pixCov, 'single');
fclose(fileID);

% Save metadata in acq2p:
obj.roiInfo.slice(sliceNum).covFile.fileName = covFileName;
obj.roiInfo.slice(sliceNum).covFile.nh = nh;
obj.roiInfo.slice(sliceNum).covFile.nPix = nPix;
obj.roiInfo.slice(sliceNum).covFile.nDiags = nDiags;
obj.roiInfo.slice(sliceNum).covFile.diags = diags;
obj.roiInfo.slice(sliceNum).covFile.channelNum = channelNum;
obj.roiInfo.slice(sliceNum).covFile.temporalBin = temporalBin;
obj.roiInfo.slice(sliceNum).covFile.activityImg = calcActivityOverviewImg(pixCov, diags, h, w);
end

function pixCov = calcPxCovChunk(mov, nPix, diags)
pixCov = zeros(nPix, numel(diags), 'single');
for px = 1:nPix
    pixCov(px, :) = (mov(px, :)*mov(px+diags, :)');
end
end