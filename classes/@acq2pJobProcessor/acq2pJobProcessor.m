classdef acq2pJobProcessor < handle
    properties
        debug = false;
        dir
        logFileName
        currentAcq
        currentAcqFileName
        nameFunc
        mouse_num
        date_num
        mouseID
        
    end
    
    properties (Hidden = true, Access = protected)
       flagStop = false; 
    end
    
    methods
        % Constructor:
        function ajp = acq2pJobProcessor(jobDir, debug, isExitAfterOneJob, nameFunc, session_info)
            if ~exist('nameFunc','var')
                ajp.nameFunc = [];
            else
                ajp.nameFunc = nameFunc;
            end
            if ~exist('isExitAfterOneJob','var') || isempty(isExitAfterOneJob)
                isExitAfterOneJob = false;
            end
            if nargin==2
                ajp.debug = debug;
            end
            
            % Define directory names:
            ajp.dir.jobs = jobDir;
            ajp.dir.inProgress = fullfile(jobDir, 'inProgress');
            ajp.dir.done = fullfile(jobDir, 'done');
            ajp.dir.error = fullfile(jobDir, 'error');
            
            ajp.logFileName = fullfile(jobDir, 'acqJobLog.txt');
            
            ajp.mouse_num = session_info.mouse_num;
            ajp.date_num = session_info.date_num;
            ajp.mouseID = session_info.mouseID;
            ajp.dir.tiff = fullfile(jobDir,'..','..',ajp.mouseID,num2str(ajp.date_num));
            
            ajp.run(isExitAfterOneJob);            
        end
    end
end