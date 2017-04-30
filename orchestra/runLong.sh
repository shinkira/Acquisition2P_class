#!/bin/bash

run () {
    
	inputDataName=$1
	
	bsub -J $inputDataName -q long -W 240:00 -n 1 -r -R "rusage[mem=60000]" -o logs/MC_job%J.out /opt/matlab/bin/matlab -nodisplay -r "orchestra_execution_engine_v2(\$LSB_JOBID)"
	}
	
#call arguments verbatim
$@
