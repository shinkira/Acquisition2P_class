#!/bin/bash

run () {
    
	inputDataName=$1
	
	bsub -J $inputDataName -q medium -W 120:00 -n 1 -r -R "rusage[mem=30000]" -o logs/MC_job%J.out /opt/matlab/bin/matlab -nodisplay -r "orchestra_execution_engine_v2(\$LSB_JOBID)"
	}
	
#call arguments verbatim
$@
