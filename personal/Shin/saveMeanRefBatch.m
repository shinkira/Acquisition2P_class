function saveMeanRefBatch

    mouse_set = 101:104;
    date_set = [220411:220506];
    root = 'Z:\HarveyLab\Tier1\Shin\ShinDataAll\Imaging\';
    
    for di = 1:length(date_set)
        for mi = 1:length(mouse_set)
            mouseNum = mouse_set(mi);
            dateNum = date_set(di);
            acqName = sprintf('SK%d_%d_FOV1_00001',mouseNum,dateNum);
            file_path = fullfile(root,sprintf('\\SK%d\\%d\\%s.mat',mouseNum,dateNum,acqName));
            ssd_path = 'E:\Imaging';
            if ~exist(file_path,'file') % acq object does not exist?
                fprintf('%s does not exist. skipping.\n',acqName);
            else
                tiff_path = fullfile(ssd_path,getMouseID(mouseNum),num2str(dateNum));
                makedir(tiff_path);
                tiff_name = sprintf('%s_meanRef.tiff',acqName);
                if 0 %exist(fullfile(tiff_path,tiff_name),'file') % meanRef tiff already exists?
                    fprintf('%s already exists. skipping\n',tiff_name);
                else
                    fprintf('saving tiff for %s %d ... ',getMouseID(mouseNum),dateNum);
                    % save tiff movie from meanRef images      
                    temp = load(file_path);
                    eval(sprintf('obj = temp.%s;',acqName));
                    nSlice = 1;
                    [mov, ~] = viewAcq(obj,nSlice);
                    if size(mov,3)<100
                        warning('%s has less than 100 mean ref images',acqName)
                    end
                    tiffWrite(mov, tiff_name, tiff_path, 'int16');
                    fprintf('done.\n')                    
                end
            end
        end
    end
end
