function runMotionCorrectionOrchestra(~, ~, ~, session_info)

%% Get directory:
[orchestraBaseDir, ~, ~] = fileparts(which('orchestra_execution_engine_v2'));

jobsToDo = fullfile('~', 'acqsToProcess');

% If we're on Orchestra, start parallel pool with correct
% settings:
% if isunix && ~isempty(gcp('nocreate'))
%     ClusterInfo.setWallTime('10:00');
%     ClusterInfo.setMemUsage('12000')
%     ClusterInfo.setQueueName('mpi')
%     parpool(12)
% end

%% Run AJP:
isExitAfterOneJob = true;
acq2pJobProcessor(jobsToDo, [], isExitAfterOneJob, [], session_info);
