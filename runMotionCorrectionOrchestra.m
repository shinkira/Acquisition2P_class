function runMotionCorrectionOrchestra(~, ~, ~)

%% Get directory:
[orchestraBaseDir, ~, ~] = fileparts(which('orchestra_execution_engine_v2'));
jobsToDo = fullfile(orchestraBaseDir, 'acqsToProcess');

% If we're on Orchestra, start parallel pool with correct
% settings:
% if isunix && ~isempty(gcp('nocreate'))
%     ClusterInfo.setWallTime('10:00');
%     ClusterInfo.setMemUsage('12000')
%     ClusterInfo.setQueueName('mpi')
%     parpool(12)
% end

%% Run AJP:
shouldContinue = false;
acq2pJobProcessor(jobsToDo, [], shouldContinue);
