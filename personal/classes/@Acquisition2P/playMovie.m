function playMovie(obj, movNum, rollingAve, movieType) 
    %Function to play motion-corrected movies
    
    castType = 'single';
    sliceNum = 1;
    channelNum = 1;
    mov = [];
    
    if isempty(movieType)
        movieType = 'corrected';
    end
    
    % Get file info:
%     nSlice = 1;
%     nChannel = 1;
%     movSizes = obj.correctedMovies.slice(nSlice).channel(nChannel).size;
%     h = movSizes(1, 1);
%     w = movSizes(1, 2);
%     nFrames = movSizes(:, 3);
%     nFramesTotal = sum(nFrames);
    
    temp = [];
    avemov_all = [];
    for mi = 1:length(movNum)
        fprintf('\nLoading #%d of %d movies\n',mi,length(movNum))
        switch movieType
            case 'corrected'
                mov = readCor(obj,mi,castType,sliceNum,channelNum);
                % mov = cat(3,mov,readCor(obj,mi,castType,sliceNum,channelNum));
            case 'raw'
                mov = readRaw(obj,mi,castType);
                % mov = cat(3,mov,readRaw(obj,mi,castType));
        end
        num_frame = size(mov,3);
        % pre-allocation
        avemov = zeros(h,w,num_frame,'single');
        if mi==1
            num_ave_frame = num_frame-rollingAve+1;
        else
            num_ave_frame = num_frame;
            mov = cat(3,temp,mov);
        end
        
        for fi = 1:num_ave_frame
            pick = fi:fi+rollingAve-1;
            avemov(:,:,fi) = mean(mov(:,:,pick),3);
        end
        
        avemov_all = cat(3,avemov_all,avemov(:,:,1:num_ave_frame));
        % keep the last frames to compute rolling average for the next movie.
        temp = mov(:,:,(end-rollingAve+1):end);
    end
%     num_frame = size(mov,3);
%     avemov = single(zeros(size(mov,1),size(mov,2),num_frame-rollingAve+1));
%     for fi = 1:num_frame-rollingAve+1
%         pick = fi:fi+rollingAve-1;
%         avemov(:,:,fi) = mean(mov(:,:,pick),3);
%     end
%%  
    % startMIJ;
    MIJ.createImage('result',avemov_all(:,:,1:10:end),true)
    
    return
    
    minSig = -500;
    maxSig = 1000;
    mov4save = (avemov - minSig) ./(maxSig - minSig);
    mov4save(mov4save<0) = 0;
    mov4save(mov4save>1) = 1;
    ind = strfind(obj.defaultDir,obj.initials);
    localDir = ['C:\Users\Shin\Documents\MATLAB\ShinDataAll\Imaging\',obj.defaultDir(ind:end)];
    if ~exist(localDir,'dir')
        mkdir(localDir);
    end
    v = VideoWriter([localDir,obj.acqName,'.mp4']);
    open(v)
    for i = 1:size(avemov,3)
        writeVideo(v,mov4save(:,:,i))
    end
    close(v)
%%
    implay(avemov/1e3,30)
end