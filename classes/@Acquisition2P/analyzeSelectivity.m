function analyzeSelectivity(obj)

% Evaluates the orientation selectivity of ROI

close all

% temp = userpath;
% matlab_dir = temp(1:end-1);
% initials = 'SK';
% data_dir = sprintf('%s\\ShinData\\Imaging\\%s%03d\\%s\\',matlab_dir,initials,mouseID,date_num);

temp = userpath;
matlab_dir = [temp(1:end-1),filesep];
ind = strfind(obj.defaultDir,obj.initials);
localDirHD1 = [matlab_dir,'ShinDataAll\Imaging\',obj.defaultDir(ind:end)];
localDirHD2 = [matlab_dir,'ShinData\Imaging\',obj.defaultDir(ind:end)];
if ispc
    localDirHD2 = strrep(localDirHD2,'/','\');
else
    localDirHD2 = strrep(localDirHD2,'\','/');
end
load([localDirHD2,obj.acqName,'_sessionData.mat']);
fig = 1;

% TM
% 1: WaveSurfer time stamp
% 2: MATLAB time stamp
% 3: Stim ON/OFF
% 4: Motion direction
% 5: Spatial frequency (cycle per deg)
% 6: Temporal frequency (cycles per sec)
% 7: Stim phase
% 8: center X pos
% 9: center Y pos
% 10: Stim horizontal size
% 11: Stim vertical size
% 12: Trial number

ws_ts = TM(1,:);
stim_on = TM(3,:);
direction = TM(4,:);
stim_on(isnan(stim_on)) = 0;
stim_on_ind = find(diff(stim_on)>0.1);
stim_off_ind = find(diff(stim_on)<-0.1);

stim_on_ind = stim_on_ind([1,find(diff(stim_on_ind)>1)+1])+2;
stim_off_ind = stim_off_ind([1,find(diff(stim_off_ind)>1)+1])+2;

num_roi = size(dF,1);

for i = 1:length(stim_off_ind)
    % pick = stim_on_ind(i):stim_off_ind(i);
    pick = stim_on_ind(i)+15:stim_on_ind(i)+75; % 0.5-2.5s after onset
    trial_direction(i) = round(mean(direction(pick)));
    trial_dF(:,i) = mean(dF(:,pick),2);
end

dir_set = 45*(0:7);
for di = 1:length(dir_set);
    pick = trial_direction==dir_set(di);
    dir_dF_mean(:,di) = nanmean(trial_dF(:,pick),2);
    dir_dF_se(:,di) = nanse(trial_dF(:,pick),[],2);
end

figure(fig); hold on
for ri = 1:num_roi
    subplot(4,4,ri); hold on
    errorbar(dir_set,dir_dF_mean(ri,:),dir_dF_se(ri,:))
    % errorbar(repmat(dir_set,1,num_roi),dir_dF_mean',dir_dF_se')
    xlim([-10 325])
end
set(gcf,'position',[100 100 1200 800])
fig = fig+1;


roi_per_fig = 5;
num_fig = ceil(num_roi/roi_per_fig);

% color setting
co = colormap(jet(8))*0.8;
set(groot,'defaultAxesColorOrder',co)

for fi = 1:num_fig
    figure(fig+fi-1)
    set(gcf,'position',[100 100 1200 1200])
    for i = 1:roi_per_fig
        ri = roi_per_fig * (fi-1) + i;
        if ri>num_roi
            continue
        end
        subplot(ceil(roi_per_fig/1),1,i); hold on
        plot(ws_ts,stim_on,'k-')
        plot(ws_ts,dF(ri,:),'b-')
        
        for i = 1:length(stim_off_ind)
            dir_ind = round(trial_direction(i)/45)+1;
            plot(ws_ts(stim_on_ind(i)),-1,'o','color',co(dir_ind,:),'MarkerFaceColor',co(dir_ind,:));
        end
        
        % ylim([0 2])
        % errorbar(repmat(dir_set,1,num_roi),dir_dF_mean',dir_dF_se')
    end
end

return
