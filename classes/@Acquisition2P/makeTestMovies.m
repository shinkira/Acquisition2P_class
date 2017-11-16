function makeTestMovies(obj)
    
    mov_set = 10:10:100;
    for mi = 1:length(obj.Movies)
        obj.Movies{mi} = changePath4Server(obj.Movies{mi});
    end
    obj.defaultDir = changePath4Server(obj.defaultDir);
    
    for mi = 1:length(mov_set)
        [mov, scanImageMetadata] = obj.readRaw(mov_set(mi),'single');
        testMovFileName = strrep(obj.Movies{mi},'FOV1','TEST');
        [pathstr,name,~] = fileparts(testMovFileName);
        tiffWrite(mov(:,:,1:100), name, pathstr, 'int16');
    end
end


%  initials = getInitials(mouse_num);
%     mouseID = sprintf('%s%03d',initials,mouse_num);
%     
%     if ismember(mouse_num,[22,23,35])
%         FOV_list = {'FOV1_00001'};
%     else
%         FOV_list = {'FOV1_001'};
%     end
%     
%     if ispc
%         defaultDir = sprintf('\\\\research.files.med.harvard.edu\\neurobio\\HarveyLab\\Tier2\\Shin\\ShinDataAll\\Imaging\\%s%03d\\%06d\\',...
%             initials,mouse_num,date_num);
%     else
%         defaultDir = sprintf('/Volumes/Neurobio/HarveyLab/Shin/ShinDataAll/Imaging/%s%03d/%06d/',...
%             initials,mouse_num,date_num);
%     end
%     FOV_name = [mouseID,'_',num2str(date_num),'_',FOV_list];