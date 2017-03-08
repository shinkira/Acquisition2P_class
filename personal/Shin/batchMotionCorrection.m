 function batchMotionCorrection(varargin)

varargin2V(varargin);

% identify the running computer (Orchestra clusters?)

if exist('initials','var') && exist('mouseID','var') && exist('date_num','var')
    getComputerName
    defaultDir = ['Z:\HarveyLab\Shin\ShinDataAll\Imaging\',initials,sprintf('%03d',mouseID),filesep,num2str(date_num),filesep];
else
    error('Essential variables are missing!')
    % movDir = uigetdir('Z:\HarveyLab\Shin\ShinDataAll\Imaging\');
    % defaultDir = [movDir,filesep];
end

if ~exist('FOV_list','var')
    % If FOV is not specified, apply motion correction to all FOVs
    a = dir([defaultDir,'FOV*.tif']);
    for i = 1:length(a)
        space_ind = strfind(a(i).name,'_');
        FOV{i} = a(i).name(1:space_ind(2)-1);
    end
    FOV_list = unique(FOV);
end

for fi = 1:length(FOV_list)

    if iscell(FOV_list)
        FOV_name = [initials,sprintf('%03d',mouseID),'_',num2str(date_num),'_',FOV_list{fi}];
    elseif ischar(FOV_list)
        FOV_name = [initials,sprintf('%03d',mouseID),'_',num2str(date_num),'_',FOV_list];
    else
        error('FOV_list must be a Cell')
    end
    
    % create obj
    obj = Acquisition2P([FOV_name],@SK2Pinit,defaultDir);
    obj.save
    return
    
    % overwrite motion correction function
    if exist('motionCorrectionFunction','var')
        obj.motionCorrectionFunction = motionCorrectionFunction;
    end

    % apply motion correction
    obj.motionCorrect;
    
    if obj.motionCorrectionDone
        
        [mov, scanImageMetadata] = obj.readRaw(1,'single');
        [movStruct, nSlices, nChannels] = parseScanimageTiff(mov, scanImageMetadata);
        
        for si = 1:nSlices
            for ni = 1:nChannels
                sliceNum = si; %Choose a slice to analyze
                channelNum = ni; %Choose the GCaMP channel
                movNums = []; %this will default to all movie files
                radiusPxCov = 11; %default, may need zoom level adjustment
                temporalBin = 8; %default (tested w/ 15-30hz imaging), may need adjustment based on frame rate
                writeDir = []; %empty defaults to the directory the object is saved in (the 'defaultDir')

                obj.calcPxCov(movNums,radiusPxCov,temporalBin,sliceNum,channelNum,writeDir);
                obj.save;
                obj.indexMovie(sliceNum,channelNum,writeDir);
                obj.save;
                %%% Customized motion correction function %%%
                computerName = getComputerName;
                switch computerName
                    case 'shin-pc'
                        % obj.indexMovie2(sliceNum,channelNum,writeDir);
                    case 'harveylab41223' 
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                obj.save
            end
        end
    end        
end

end


%         % copy auxiliary auxiliary files to the local HD
%         sourceDir = obj.defaultDir;
%         files2local = dir([sourceDir,obj.acqName,'*.h5']);
%         files2local = [files2local;dir([sourceDir,obj.acqName,'*.bin'])];
%         files2server = dir([sourceDir,'Corrected',filesep,obj.acqName,'*.tif']);
%         
%         configure file destinations
%         ind = strfind(obj.defaultDir,obj.initials);
%         localDir = ['C:\Users\Shin\Documents\MATLAB\ShinDataAll\Imaging\',obj.defaultDir(ind:end)];
%         serverDir = ['Z:\HarveyLab\Shin\ShinDataAll\Imaging\',obj.defaultDir(ind:end)];
%         
%         if ~exist([localDir,'Corrected'],'dir')
%             mkdir([localDir,'Corrected']);
%         end
%         for i = 1:length(files2local)
%             copyfile([sourceDir,files2local(i).name],[localDir,files2local(i).name])
%         end
%         
%         if 0 % skip this if motion correction is applied to files on the server
%             copy motion-corrected movies to the server
%             if ~exist([serverDir,'Corrected'],'dir')
%                 mkdir([serverDir,'Corrected']);
%             end
%             for i = 1:length(files2server)
%                 copyfile([sourceDir,'Corrected',filesep,files2server(i).name],[serverDir,'Corrected',filesep,files2server(i).name])
%             end
%         end