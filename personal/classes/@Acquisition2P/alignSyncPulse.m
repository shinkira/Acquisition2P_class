function alignSyncPulse(obj,varargin)

% Align Virmen and ScanImage sync pulses

varargin2V(varargin);

if ~exist('sliceNum','var')
    sliceNum = 1;
end

if ~exist('channelNum','var')
    channelNum = 1;
end

roiGroups = [1:20];

chunk_size = 1e6;

% this part is redundant with SC2Pinit
ind = strfind(obj.defaultDir,'Imaging');
obj.initials = obj.defaultDir(ind+8:ind+9);
obj.mouseNum = str2double(obj.defaultDir(ind+10:ind+12));
obj.recDate = obj.defaultDir(ind+14:ind+19);

temp = userpath;
matlab_dir = temp(1:end-1);
FOV_num = str2double(obj.acqName(4));

% im_date_short = [im_date(1:2),im_date(4:5),im_date(7:8)];
mat_file_name = sprintf('%s%s%03d\\%s%03d_%s','Z:\HarveyLab\Tier1\Shin\ShinDataAll\Current Mice\',obj.initials,obj.mouseNum,obj.initials,obj.mouseNum,obj.recDate);
if 1 % FOV_num==1
    mat_file_name = [mat_file_name,'.mat'];
else
    mat_file_name = [mat_file_name,'_',num2str(FOV_num-1),'.mat'];
end
load(mat_file_name);
m_time_stamp = data(1,:);

switch vr.computerID
    case 3
        MatlabPulseMode = 'analog';
    case 4
        MatlabPulseMode = 'digital';
end

if 0
    % adjust the analysis window if necessary
    pick_t = [0.25e5:4e5];
    wsData = wsData(pick_t,:);
end

if ~isempty(obj.correctedMovies)
    movSizes = obj.correctedMovies.slice(sliceNum).channel(channelNum).size;
    nFramesTotal = sum(movSizes(:, 3));
else
    nFramesTotal = 1e5; % default num of frames
end

switch MatlabPulseMode
    case 'analog'
        samp_rate = 1e3;
        file_name = [obj.defaultDir,obj.acqName,'.h5'];
        zeroInd = strfind(file_name,'0000');
        file_name = [file_name(1:zeroInd-1),file_name(zeroInd+1:end)];
        wsData = h5read(file_name,'/sweep_0001/analogScans');
        % wsData = h5read(file_name,'/trial_0001/analogScans');

        % si_time_stamp = find(diff(wsData(:,4)')>7800)*1e3/samp_rate; % scan image pulse
        SIsig = wsData(:,4)';
        temp = SIsig>7800;
        SI_sig_rise = find(diff(temp)==1)+1;
        SI_sig_fall = find(diff(temp)==-1)+1;
        
%         if length(si_time_stamp)~=nFramesTotal
%             warning('The number of frames and sync-pulses did not match.')
%             si_time_stamp = si_time_stamp(1:nFramesTotal);
%         end

        NIsig = double(wsData(:,5))'*0.15/462.7; % matlab pulse -- convert to voltage
        N = length(NIsig);
        num_chunk = ceil(N/chunk_size);

        n = length(m_time_stamp);
        sig_rise = nan(1,n);
        sig_fall = nan(1,n);
        sig_rise_t = nan(1,n);
        amp = nan(1,n);

        sig_fall_temp = 0;
        split_flag = 0;
        chunk_end = 0;

        x = [[0,0,NIsig(1,1:end-2)];NIsig(1,:)];
        dx = diff(x,1,1);
        threshold = 0.07;
        rise_all = find(dx>threshold);
        fall_all = find(dx<-threshold);
        m = 1;
        y = nan(1,1e5);
        j = 1;
        k = 1;
        for i = 1:num_chunk
            chunk_end(i+1) = chunk_end(i) + chunk_size;
            a = rise_all(find(rise_all<=chunk_end(i+1)+1,1,'last'));
            b = fall_all(find(fall_all<=chunk_end(i+1),1,'last'));
            while isempty(a) || a>b || b-a<2
                chunk_end(i+1) = chunk_end(i+1) + chunk_size;
                a = rise_all(find(rise_all<=chunk_end(i+1)+1,1,'last'));
                b = fall_all(find(fall_all<=chunk_end(i+1),1,'last'));
            end

            if chunk_end(i+1)>N
                sig = NIsig(chunk_end(i)+1:end);
            else
                sig = NIsig(chunk_end(i)+1:chunk_end(i+1));
            end

            x = [[0,0,sig(1:end-2)];sig];
            dx = diff(x,1,1);
            rise = find(dx>threshold);
            fall = find(dx<-threshold);
            sig_fall_temp = 0;

            while 1
                sig_rise_temp = rise(find(rise>sig_fall_temp,1,'first'));

                if k==1
                    sig_rise_temp = rise(find(rise>sig_rise_temp+1,1,'first'));
                end
                if isempty(sig_rise_temp)
                    break
                end
                sig_fall_temp = fall(find(fall>sig_rise_temp,1,'first'));
                if isempty(sig_fall_temp)
                    error('sig_fall_temp should not be empty!!')
                end

                sig_rise_temp2 = rise(find(rise>sig_fall_temp,1,'first'));
                if isempty(sig_rise_temp2)
                    sig_rise_temp2 = sig_fall_temp + 10;
                end

                if sig_fall_temp - sig_rise_temp < 2
                         % transient artifact (spike) at the baseline
                    if  sig(sig_fall_temp+2) - sig(sig_rise_temp-2) < 0.01
                        continue
                    else % transient artifact (spike) at the pulse onset
                        sig_fall_temp = fall(find(fall>sig_fall_temp+1,1,'first'));
                    end
                end
                    % transient artifact (dip) on the pulse. Look for the next fall.
                    % Be aware!! there is a slight chance that the dip could 
                    % occurs at the end of chunks.
                if sig_rise_temp2 - sig_fall_temp < 2
                    sig_fall_temp = fall(find(fall>sig_fall_temp+1,1,'first'));
                end

                sig_rise(k) = sig_rise_temp + chunk_end(i);
                sig_fall(k) = sig_fall_temp + chunk_end(i);
                sig_rise_t(k) = (sig_rise(k) - sig_rise(1))/30e3;
                amp(k) = mean(sig(sig_rise_temp+1:sig_fall_temp));

                if mod(k,1e4)==0
                    fprintf('%d pulses detected\n',k)
                end
                j = j+1;
                k = k+1;
            end
        end
        NI_time_stamp = (sig_rise' - sig_rise(1));
        % i_time_stamp = (sig_rise' - sig_rise(1))/samp_rate;
        num_pulse = find(isfinite(amp),1,'last');
        
        if num_pulse == length(m_time_stamp)
            fprintf('All Virmen pulses were detected!\n')
        elseif num_pulse < length(m_time_stamp)
            warning('Some of Virmen sync pulses were not detected');
        end
        
        data = data(:,1:num_pulse);
        
    case 'digital'
        % detecting MATLAB sync pulses
        file_name = sprintf('%s%s%03d\\%s\\%s_0001.h5','Z:\HarveyLab\Tier2\Shin\ShinDataAll\Imaging\',obj.initials,obj.mouseNum,obj.recDate,obj.acqName(1:4));
        if exist(file_name,'file')
            a = ws.loadDataFile(file_name);
            samp_rate = 2e3;
            for i = 1:length(a.header.Acquisition.ActiveChannelNames)
                pick_NI(i) = ~isempty(strfind(a.header.Acquisition.ActiveChannelNames{i},'VirmenSync'));
                pick_SI(i) = ~isempty(strfind(a.header.Acquisition.ActiveChannelNames{i},'ScanImageSync'));
            end
            % detecting Virmen sync pulses
            NIsig = a.sweep_0001.analogScans(:,pick_NI);
            % detecting ScanImage sync pulses
            SIsig = a.sweep_0001.analogScans(:,pick_SI);
        end

        % file_name = dir(sprintf('%s%s%03d\\%s\\%s_syncData*.mat','Z:\HarveyLab\Tier2\Shin\ShinDataAll\Imaging\',obj.initials,obj.mouseNum,obj.recDate,obj.acqName(1:4)));
        file_name = dir(sprintf('%s%s%03d\\%s\\%s_syncData*.mat','Z:\HarveyLab\Tier2\Shin\ShinDataAll\Imaging\',obj.initials,obj.mouseNum,obj.recDate,'FOV1'));
        if ~isempty(file_name)
            file_name = sprintf('%s%s%03d\\%s\\%s','Z:\HarveyLab\Tier2\Shin\ShinDataAll\Imaging\',obj.initials,obj.mouseNum,obj.recDate,file_name.name);
            if exist(file_name,'file')
                temp = load(file_name);
                if isfield(temp,'sync')
                    s = temp.sync;
                else
                    s = temp.s;
                end
                num_channel = length(s.chNames);
                samp_rate = s.prop.snDataLogProperties.Rate;
                for i = 1:num_channel
                    pick_NI(i) = ~isempty(strfind(s.chNames{i},'VirmenSync'));
                    pick_SI(i) = ~isempty(strfind(s.chNames{i},'ScanImageSync'));
                end
                % detecting Virmen sync pulses
                NIsig = s.ch(:,pick_NI);
                % detecting ScanImage sync pulses
                SIsig = s.ch(:,pick_SI);
            end
        end
        temp = NIsig>2.5;
        NI_sig_rise = find(diff(temp)==1)+1;
        NI_sig_fall = find(diff(temp)==-1)+1;
        
        temp = SIsig>2.5;
        SI_sig_rise = find(diff(temp)==1)+1;
        SI_sig_fall = find(diff(temp)==-1)+1;
        % si_time_stamp = find(diff(SIsig)>2.6)*1e3/samp_rate; % scan image pulse
        
        if NI_sig_rise(1) < NI_sig_fall(1)
            rise_first = true;
            NI_time_stamp = sort([NI_sig_rise;NI_sig_fall]);
        else
            rise_first = false;
            % This indicates (i) successful reset OR (ii) failed reset 
            if length(NI_sig_rise)+length(NI_sig_fall) == length(m_time_stamp)+1
                % case (i): successful reset, the first sig_fall occurred before
                % the 1st Virmen iteration.
                NI_time_stamp = sort([NI_sig_rise;NI_sig_fall]);
                NI_time_stamp = NI_time_stamp(2:end);

            elseif length(NI_sig_rise)+length(NI_sig_fall) == length(m_time_stamp)-1
                % case (ii): failed reset, the first sig_fall occurred at the end
                % of the 2nd Virmen iteration.
                NI_time_stamp = sort([NI_sig_rise;NI_sig_fall]);
                data = data(:,2:end);
            end
        end

        if (length(NI_sig_rise) + length(NI_sig_fall)) < length(m_time_stamp)
            warning('Some of Virmen sync pulses were not detected');
        end
end

if length(SI_sig_rise) > nFramesTotal
    warning('The number of ScanImage sync pulses exceeds the saved number of image frames');
    init_ind  = find(diff(SI_sig_rise)>40e-3*samp_rate)+1;
    init_ind = [1,init_ind',length(SI_sig_rise)+1];
    k = 1;
    minBlockSize = 1e4;
    for i = 1:length(init_ind)-1
        pick = init_ind(i):init_ind(i+1)-1;
        if length(init_ind(i):init_ind(i+1)-1) >= minBlockSize;
            blockFrames{k} = pick;
            k = k+1;
        end
    end
    block_ind = uiSelectBlock(SIsig(1:1e3:end),blockFrames);
    pick = blockFrames{block_ind};
    SI_sig_rise = SI_sig_rise(pick);
end

%%%%%%%%%%% change the file path of bin files for dF extraction %%%%%%%%%%%
if 1
    server_dir = 'Z:\HarveyLab\Tier2\Shin\ShinDataAll\';
    temp = obj.roiInfo.slice(sliceNum).covFile.fileName;
    ind = strfind(temp,'Imaging');
    obj.roiInfo.slice(sliceNum).covFile.fileName = [server_dir,temp(ind:end)];

    temp = obj.indexedMovie.slice(sliceNum).channel(channelNum).fileName;
    ind = strfind(temp,'Imaging');
    obj.indexedMovie.slice(sliceNum).channel(channelNum).fileName = [server_dir,temp(ind:end)];

    if ~isfield(obj.roiInfo.slice(sliceNum).roi,'groupName')
        [dF,traces,rawF,roiList] = extractROIsBin(obj,roiGroups,sliceNum,channelNum); %#ok<ASGLU>
    else
        %%% configure file name %%%
        temp = obj.indexedMovie.slice(sliceNum).channel(channelNum).fileName;
        ind = strfind(temp,'_mov');
        file_header = temp(1:ind-1);
        file_name = sprintf('%s_dFspine.mat',file_header);
        %%%%%%%%%%%%%%%%%%%%%%%%%%% 
        load(file_name)
        dF = [dFden;dFsub];
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if iscolumn(NI_time_stamp)
    NI_time_stamp = NI_time_stamp';
end
if iscolumn(SI_sig_rise)
    SI_sig_rise = SI_sig_rise';
end

% convert time-stamp indices to ms
NI_time_stamp_ms = NI_time_stamp*1e3/samp_rate;
SI_time_stamp_ms = SI_sig_rise*1e3/samp_rate;

% select time-stamps for the corresponding slice
nSlices = length(obj.correctedMovies.slice);
totalFrames = 0;
for si = 1:nSlices
    movSizes = obj.correctedMovies.slice(si).channel(1).size;
    totalFrames = totalFrames + sum(movSizes(:,3));
end
SI_time_stamp_ms = SI_time_stamp_ms(sliceNum:nSlices:totalFrames);

if 0
    % include only after the initiation of Virmen
    ind = find(SI_time_stamp_ms>NI_time_stamp_ms(1),1,'first');
    SI_time_stamp_ms = SI_time_stamp_ms(ind:end);
    dF = dF(:,ind:end);
    if exist('rawF','var')
        rawF = rawF(:,ind:end);
    end
    fprintf('First %d frames are not included in the analysis.\n',ind-1)
end
    
for i = 1:size(data,1)
    temp = interp1(NI_time_stamp_ms,data(i,:),SI_time_stamp_ms);
    interpData(i,:) = temp;
end

TM = [SI_time_stamp_ms;interpData];
% FOV1_001_Slice03_Channel01_File001
save_name = sprintf('%s_Slice%02d_Channel%02d_sessionData.mat',obj.acqName,sliceNum,channelNum);
save([obj.defaultDir,save_name],'TM','dF');
if exist('roiList','var')
    save([obj.defaultDir,save_name],'roiList','-append');
end

obj.save;
temp = obj.defaultDir;

% configure file destinations
ind = strfind(obj.defaultDir,obj.initials);
localDirHD1 = ['C:\Users\Shin\Documents\MATLAB\ShinDataAll\Imaging\',obj.defaultDir(ind:end)];
localDirHD2 = ['C:\Users\Shin\Documents\MATLAB\ShinData\Imaging\',obj.defaultDir(ind:end)];
% copy across computers
if ~exist(localDirHD1,'dir')
    mkdir(localDirHD1);
end
if ~exist(localDirHD2,'dir')
    mkdir(localDirHD2);
end
copyfile([obj.defaultDir,save_name],[localDirHD1,save_name]);
copyfile([obj.defaultDir,save_name],[localDirHD2,save_name]);
obj.defaultDir = localDirHD1;
obj.save;
obj.defaultDir = localDirHD2;
obj.save;
obj.defaultDir = temp;
obj.save;
