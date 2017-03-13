function runMotionCorrectionOrchestra(~, ~, ~)

%% Get directory:
[orchestraBaseDir, ~, ~] = fileparts(which('orchestra_execution_engine_v2'));
jobsToDo = fullfile(orchestraBaseDir, 'acqsToProcess');

if 0
    %% Set up parallel pool:
    ClusterInfo.setWallTime('240:00'); % 20 hour
    ClusterInfo.setMemUsage('2000')
    ClusterInfo.setQueueName('mpi')
    parpool(6)
end

%% Run AJP:
shouldContinue = false;
acq2pJobProcessor(jobsToDo, [], shouldContinue);
