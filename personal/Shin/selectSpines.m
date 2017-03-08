function selectSpines(obj,select_flag,varargin)
    
    close all
    figPref;
    set(0,'defaultaxesfontsize',10);
    set(0,'defaulttextfontsize',10);
    
    varargin2V(varargin);
    
    if ~exist('sliceNum','var')
        sliceNum = 1;
    end
    
    if ~exist('channelNum','var')
        channelNum = 1;
    end
    
    % change the paths from Orchestra to Server
    if strcmp(obj.defaultDir(1:2),'/n');
        changeAcqPath4Server(obj)
    end
    
    img = obj.meanRef([],sliceNum);
    % img = obj.motionRefImage.slice(sliceNum).img;
    img(img<0) = 0;
    img(isnan(img)) = 0;
    img = sqrt(img);
    img = adapthisteq(img/max(img(:)));
    colormap(gray)
    figure(1);
    % set(gcf,'position',[600 100 1200 1200])
    set(gcf,'position',[600 100 1000 1000])
    imagesc(img);
    drawnow;
    
    if select_flag
        k = 1;
        keyIsDown = 0;
        hasBeenSelected = zeros(size(img));
        while 1
            title('Press SPACE to choose ROI or ESC to finish','FontSize',16)
            drawnow;
            [secs, keyCode, deltaSecs] = KbWait;
            switch find(keyCode)
                case 32 % space key
                    title('Click on the image to select a spine or dendrite','FontSize',16)
                    drawnow;
                    H = impoly(gca);
                    roi(k).id = k;
                    roi(k).indBody = find(H.createMask);
                    hasBeenSelected(H.createMask) = k;
                    title('Press #1 for spine and #2 for dendrite','FontSize',16)
                    drawnow;
                    [secs, keyCode, deltaSecs] = KbWait;
                    switch find(keyCode)
                        case 49 % #1 pressed for spines
                            roi(k).group = 1;
                            roi(k).groupName = 'spine';
                        case 50 % #2 pressed for dendrites
                            roi(k).group = 2;
                            roi(k).groupName = 'dendrite';
                    end
                    k = k+1;
                case 27 % esc key
                    title('Finished selection','FontSize',16)
                    drawnow;
                    break
            end
        end
    end
    %% Memory Map Movie
    movSizes = obj.correctedMovies.slice(sliceNum).channel(channelNum).size;
    h = movSizes(1, 1);
    w = movSizes(1, 2);
    nFramesTotal = sum(movSizes(:, 3));
    
    movMap = memmapfile(obj.indexedMovie.slice(sliceNum).channel(channelNum).fileName,...
        'Format', {'int16', [nFramesTotal, h*w], 'mov'});
    % movMap2 = memmapfile(obj.indexedMovie.slice(sliceNum).channel(channelNum).fileName2,...
    %     'Format', {'int16', [h*w, nFramesTotal], 'mov'});
    
    %%% configure file name %%%
    temp = obj.indexedMovie.slice(sliceNum).channel(channelNum).fileName;
    ind = strfind(temp,'_mov');
    file_header = temp(1:ind-1);
    file_name = sprintf('%s_dFspine.mat',file_header);
    %%%%%%%%%%%%%%%%%%%%%%%%%%% 
    
    if select_flag
        num_den = length(roi);
        for k = 1:num_den
            ind = obj.mat2binInd(roi(k).indBody); %#ok<FNDSB>
            F(k,:) = mean(movMap.Data.mov(:,ind), 2)';
        end
        dF = bsxfun(@rdivide, F, nanmedian(F, 2));
        obj.roiInfo.slice(sliceNum).roi = roi;
        obj.roiInfo.slice(sliceNum).hasBeenSelected = hasBeenSelected;
        obj.save;
        save(file_name,'dF')
    else
        load(file_name)
    end
    
    roiColors = [1 0 0; 0 0 1];
    num_roi = length(obj.roiInfo.slice(sliceNum).roi);
    pick_den = strcmp({obj.roiInfo.slice(sliceNum).roi.groupName},'dendrite');
    pick_spine = strcmp({obj.roiInfo.slice(sliceNum).roi.groupName},'spine');
    for ri = 1:num_roi
        
        roiId = obj.roiInfo.slice(sliceNum).roi(ri).id;
        
        % Get mask for ROI to be drawn:
        currRoiMask = obj.roiInfo.slice(sliceNum).hasBeenSelected == roiId;

        %find edges of current roi
        [rowInd,colInd] = findEdges(currRoiMask);

        %create patch object
        roiTransp = 0.5;
        roiGroup = obj.roiInfo.slice(sliceNum).roi(ri).group;
        h = patch(rowInd,colInd,roiColors(roiGroup,:));
        set(h,'FaceAlpha', roiTransp);
        
        % Write spineId:
        switch obj.roiInfo.slice(sliceNum).roi(ri).groupName
            case 'spine'
                spineId = sum(pick_spine(1:ri));
            case 'dendrite'
                spineId = sum(pick_den(1:ri));
        end
        [rowIndAll, colIndAll] = find(currRoiMask); % Use all points to find more natural center, downweighting fine processes.
        text(mean(colIndAll), mean(rowIndAll), num2str(spineId), ...
            'verticalalignment', 'middle', 'horizontalalignment', 'center', ...
            'color', 'w', 'fontsize', 8);
    end
    
    
%%  
    nBack = 100;
    nForward = 200;
    
    if exist('B','var')
        B_def = B;
    else
        B_def = [];
    end
    
    B = uiSelectThreshold(B_def);
    
    % smooth with box car filter
    kernel_length = 100;
    bin_size = 6;
    kernel = zeros(1,kernel_length);
    kernel(kernel_length/2-bin_size/2+1:kernel_length/2+bin_size/2) = 1/bin_size;
    figure;
    for i = 1:size(dF,1)
        temp = conv(dF(i,:),kernel);
        temp = temp(kernel_length/2:end-kernel_length/2);
        dFs(i,:) = temp;
    end
    
    % substitute dF with its smoothed trace dFs
    dF = dFs;
    
    dFden = mean(dF(pick_den,:),1);
    dFspine = dF(pick_spine,:);
    t_above = dFden>B;
    t_rise_temp = find(diff(t_above)==1);
    t_fall_temp = find(diff(t_above)==-1);
    bAP_flag = ~isempty(t_rise_temp) && ~isempty(t_fall_temp);
    if bAP_flag
        if t_rise_temp(1) > t_fall_temp(1)
            t_fall_temp = t_fall_temp(2:end);
        end
        if length(t_rise_temp) > length(t_fall_temp)
            t_rise_temp = t_rise_temp(1:end-1);
        end
        pick = diff([t_rise_temp;t_fall_temp],[],1) > 20;
        t_rise = t_rise_temp(pick);
        t_fall = t_fall_temp(pick);

        % Method 1: supress bAP
        dFsub = dFspine;
        if 0
            for i = 1:length(t_rise)
                if t_rise(i)>nBack % && all(temp(t(i)+1:t(i)+30))
                    dFsub(:,t_rise(i)-nBack:t_fall(i)) = nan;
                else
                    dFsub(:,1:t_fall(i)) = nan;
                end
                if t_fall(i)<=nFramesTotal-nForward % && all(temp(t(i)+1:t(i)+30))
                    dFsub(:,t_fall(i):t_fall(i)+nForward) = nan;
                else
                    dFsub(:,t_fall(i):end) = nan;
                end
            end
        else
        % Method 2: Subtract scaled bAP (dFden) from spine signals (dFspine)
            for i = 1:sum(pick_spine)
                [b,dev,stat] = glmfit(dFden(t_above)',dFspine(i,t_above)','normal');
                % dFden_t_above = zeros(1,length(dFden));
                % dFden_t_above(t_above) = b(1) + b(2)*dFden(t_above);
                % dFsub(i,:) = dFspine(i,:) - dFden_t_above;
                dFsub(i,:) = dFspine(i,:) - (b(1) + b(2)*dFden);
            end
        end
    else
        dFsub = dFspine;
    end
    num_spine = sum(pick_spine);
    ind_spine = find(pick_spine);
    figure(2)
    n_per_fig = 5;
    for si = 1:num_spine
        fig_num = ceil(si/n_per_fig)+2;
        row_num = mod(si-1,n_per_fig)+1;
        figure(fig_num);
        set(gcf,'position',[100 100 2000 1200]);
        subplot(n_per_fig+1,1,row_num); hold on
        % plot(dF(ind_spine(si),:),'b-');
        
        
        
%         subplot(n_per_fig+1,1,row_num+1); hold on
%         plot(t_rise,B*ones(1,length(t_rise)),'ro')
%         plot(t_fall,B*ones(1,length(t_fall)),'bo')
        
        plot(dFsub(si,:),'r-');
        ylim_temp = get(gca,'Ylim');
        ylim([-10 10]);
        % ylim([0 ylim_temp(2)]);
        
        set(gca,'XMinorTick','on','XTick',0:1e4:nFramesTotal,'TickDir','out');
        title(sprintf('Spine #%d',si));
        xlim([1.3,1.475]*1e5)
        % add dendrite signal at the bottom
        if row_num==n_per_fig || si==num_spine
            subplot(n_per_fig+1,1,n_per_fig+1); hold on
            plot(dF(pick_den,:),'b-');
            if bAP_flag
                plot(t_rise,B*ones(1,length(t_rise)),'ro')
                plot(t_fall,B*ones(1,length(t_fall)),'bo')
            end
            ylim_temp = get(gca,'Ylim');
            % ylim([0 ylim_temp(2)]);
            xlim([1.3,1.475]*1e5)
            ylim([0 30]);
            title('Dendrite')
        end
    end
    
    save(file_name,'dFden','dFspine','dFsub','B','-append')
 %% 
    if 0
        t_pick = 8.5e4:9.8e4;
        dFpick = [dF(4,t_pick);dFsub([1,2,3],t_pick)];
        dFs = nan(size(dFpick));
        
        % smooth with box car filter
        kernel_length = 100;
        bin_size = 6;
        kernel = zeros(1,kernel_length);
        kernel(kernel_length/2-bin_size/2+1:kernel_length/2+bin_size/2) = 1/bin_size;
        figure;
        for i = 1:size(dFpick,1)
            temp = conv(dFpick(i,:),kernel);
            temp = temp(kernel_length/2:end-kernel_length/2);
            dFs(i,:) = temp;
            subplot(4,1,i)
            plot(dFs(i,:))
            xlim([1,length(t_pick)])
            y_mean = nanmean(dFs(i,:));
            %ylim([y_mean-3,y_mean+17])
            set(gca,'box','off')
        end
    end
           
            
 %%   
    return
end

function [row,col] = findEdges(image)
    %findEdges.m Finds contours of binary array
    %
    %INPUTS 
    %image - binary image 
    %
    %OUTPUTS
    %row - column vector of row coordinates
    %col - column vector of col coordinates
    %
    %ASM 10/13

    %find element to start search
    [rowInd, colInd] = find(image > 0,1,'first');

    %perform search
    B = bwtraceboundary(image,[rowInd,colInd],'NE');

    %get row and col
    row = B(:,2);
    col = B(:,1);
end