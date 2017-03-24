function orchestra_execution_engine_v2(jobId, jobIndex)
% orchestra_execution_engine_v1(jobId, jobIndex) runs jobs on orchestra.
%
% The input data must be saved as a pair of a .mat file and an .m file
% containing the input data and the function to run on it. The .mat file
% must have the same name as LSB_JOBNAME. The .m-file name must be
% identical to the substring up to the first underscore of the .mat file
% name. For example, if the input data is glm_mouse3.mat, then the
% processing function must be glm.m.
%
% The processing function in the .m file must accept exactly three inputs:
%
% jobIndex - the index of the current job in array jobs.
%
% inputDataFilePath - path to a mat file from which the processing function
%                     should load its input data.
%
% outputDataFilePath - path to a mat file to which the processing function
%                      should save its output data.
%
% The loading and saving itself is handled by the processing function so
% that it can be flexibly determined as necessary.

if nargin<2
    jobIndex = nan;
end

%% Get input data name:
% inputName = strtok(getenv('LSB_JOBNAME'), '[');
inputName = 'runMotionCorrectionOrchestra';

%% Set path:
[orchestraBaseDir, ~, ~] = fileparts(which(mfilename));
addpath(genpath(fullfile(orchestraBaseDir, 'Imaging', 'helperFunctions')));
addpath(genpath(fullfile(orchestraBaseDir, 'Imaging', 'Acquisition2P_class')));
% addpath(genpath(fullfile(orchestraBaseDir, 'Imaging', 'Motion_Correction')));
% addpath(genpath(fullfile(orchestraBaseDir, 'Imaging', 'HarveyLab_helperFunctions')));
% addpath(genpath(fullfile(orchestraBaseDir, 'Imaging', 'analysis')));
% addpath(genpath(fullfile(orchestraBaseDir, 'Imaging', 'imageProcessing')));
% addpath(genpath(fullfile(orchestraBaseDir, 'Imaging', 'glmnet')));
% addpath(genpath(fullfile(orchestraBaseDir, 'Imaging', 'sparseBayes')));

% Code files controling job execution are stored in the INPUT folder, so
% add that too:
addpath(genpath(fullfile(orchestraBaseDir, 'input')));

%% Get directories:
% Input path:
inputDataDir = fullfile(orchestraBaseDir, 'input');
inputDataFilePath = fullfile(inputDataDir, [inputName '.mat']);

% Output path:
outputDataFolderName = sprintf('%d_%s', jobId, inputName);
outputDataFileName = sprintf('%s_jobIndex%04.0f.mat', inputName, jobIndex);
saveDir = fullfile(orchestraBaseDir, 'output', outputDataFolderName);
if ~exist(saveDir, 'dir')
    mkdir(saveDir)
end
outputDataFilePath = fullfile(saveDir, outputDataFileName);

%% Perform processing:
% The name of the processing function .m-file must be identical to the
% substring up to the first underscore of the input data file name. For
% example, if the input data is glm_mouse3.mat, then the processing
% function must be glm.m.
procFunName = strtok(inputName, '_');
procFun = str2func(procFunName);

% fid = fopen('test_output.txt', 'w');
% fprintf(fid, '%s\t%s\n', procFunName);
% fclose(fid);

procFun(jobIndex, inputDataFilePath, outputDataFilePath);