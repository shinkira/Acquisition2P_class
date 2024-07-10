function runMotionCorrectionLocal

    root = 'Z:\HarveyLab\Tier1\Shin\ShinDataAll\ImagingNew\BatchAcqObj';
    
    mouse_set = [111];
    date_set = [240709];
    acq_set = {{'FOV4_00001','FOV4_00002','FOV5_00001'}};
    initials = 'SK';
    k = 1;
    for mi = 1:length(mouse_set)
        mouse_num = mouse_set(mi);
        for di = 1:length(date_set)
            date_num = date_set(di);
            n_fov = length(acq_set{di});
            for fi = 1:n_fov
                acq_name = acq_set{di}{fi};
                AcqName{k} = sprintf('%s%d_%d_%s',initials,mouse_num,date_num,acq_name);
                createAcq(mouse_num,date_num,'FOV_name',acq_name);
                k = k+1;
            end
        end
    end
    
%     AcqName{1} = 'SK111_240617_FOV3_00001';
%     AcqName{2} = 'SK111_240617_FOV3_00002';
%     AcqName{3} = 'SK111_240627_FOV5_00003';
%     AcqName{4} = 'SK111_240627_FOV4_00001';
    
    n_job = length(AcqName);
    p = gcp('nocreate');
    if isempty(p)
        parpool(n_job);
    end
    parfor i = 1:length(AcqName)
        FOV_motion_correct(root,AcqName{i})
    end

end

function FOV_motion_correct(root,acq_name)

    load(fullfile(root,[acq_name,'.mat']),acq_name);
    obj = eval(acq_name);
    obj.motionCorrect

end