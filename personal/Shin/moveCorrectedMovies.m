function moveCorrectedMovies

    % Move corrected movies from folders with a date name (eg 240617) to subfolders with a FOV name (e.g. 240617/FOV1_00001)
    % This structure helps Suite2P to find tiff files easily
    
    
    mouse_set = [111];
    
    if 0
        date_set = [240613,240617];
        acq_set = {{'FOV3_00001','FOV3_00002'},{'FOV3_00001','FOV3_00002'}};
    else
        date_set = [240626];
        acq_set = {{'FOV4_00001'}};
    end
    
    initials = 'SK';
    k = 1;
    for mi = 1:length(mouse_set)
        mouse_num = mouse_set(mi);
        for di = 1:length(date_set)
            date_num = date_set(di);
            n_fov = length(acq_set{di});
            for fi = 1:n_fov
                acq_name = acq_set{di}{fi};
                moveFiles(mouse_num,date_num,acq_name);
                k = k+1;
            end
        end
    end

end


function moveFiles(mouse_num, date_num, acq_name)

    data_dir = sprintf('Z:\\HarveyLab\\Tier1\\Shin\\ShinDataAll\\ImagingNew\\SK%d\\%d\\Corrected',mouse_num, date_num);
    data_subdir = fullfile(data_dir,acq_name);
    initials = 'SK';
    file_name = sprintf('%s%d_%d_%s_*.tif', initials, mouse_num, date_num, acq_name);
    d = dir(fullfile(data_dir,file_name));
    
    if isempty(d)
        fprintf('No files found...\n')
        return
    else
        makedir(data_subdir);
    end
    
    for i = 1:length(d)
        f_name = d(i).name;
        path_from = fullfile(data_dir,f_name);
        path_to   = fullfile(data_subdir,f_name);
        [STATUS,MESSAGE,MESSAGEID] = movefile(path_from,path_to);
        if STATUS
            fprintf('Moved %s\n',f_name)
        else
            error('Failed to move %s\n',f_name)
        end
    end
end