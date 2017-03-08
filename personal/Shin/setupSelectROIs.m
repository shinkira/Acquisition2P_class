clear

temp = userpath;
matlab_dir = temp(1:end-1);
prompt = {'Enter the mouse number:','Enter the date:','Enter FOV','Enter the initials:'};
dlg_title = 'Mouse info';
num_lines = 1;
def = {'37','160411','FOV2','SK'};
mouseInfo = inputdlg(prompt,dlg_title,num_lines,def);
mouseNum = str2double(mouseInfo{1});
im_date = mouseInfo{2};
varName = mouseInfo{3};
initials = mouseInfo{4};
mov_dir = sprintf('%s\\ShinDataAll\\Imaging\\%s%03d\\%s\\',matlab_dir,initials,mouseNum,im_date);
load([mov_dir,varName]);
eval(['FOV = ',varName,';']); 

sliceNum = 1; %Choose a slice to analyze
channelNum = 1; %Choose the GCaMP channel
movNums = []; %this will default to all movie files
radiusPxCov = 11; %default, may need zoom level adjustment
temporalBin = 8; %default (tested w/ 15-30hz imaging), may need adjustment based on frame rate
writeDir = []; %empty defaults to the directory the object is saved in (the 'defaultDir')

img = FOV.meanRef;
img(img<0) = 0;
img(isnan(img)) = 0;
img = sqrt(img);
img = adapthisteq(img/max(img(:)));

% An alternative is to use an 'activity overview image', which has been
% precalculated in the calcPxCov call. This image highlights pixels which
% share strong correlations with neighboring pixels, and can be used
% independently or shared with an anatomical image, e.g.
sliceNum = 1;
actImg = FOV.roiInfo.slice(sliceNum).covFile.activityImg;
% img = img/2 + actImg/2;

% Note that the reference image is only used for display purposes, and has no impact
% on the segmentation algorithm itself.

% Now start the ROI selection GUI. This tool is complex enough to have its
% own tutorial, located in the same folder as this file. Again, all
% arguments are optional, provided here just for clarity.
smoothWindow = 15; % Gaussian window with std = smoothWin/5, for displaying traces
excludeFrames = []; %List of frames that need to be excluded, e.g. if they contain artifacts
FOV.selectROIs(img,sliceNum,channelNum,smoothWindow,excludeFrames);