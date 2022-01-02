#!/bin/bash

scripts[0]='jobsnd.py'
scripts[1]='mtag_check.py'
scripts[2]='mtag_data.py'
scripts[3]='post_process.py'
scripts[4]='calc_dev.py'
scripts[5]='min_mix.py'

#declare -a scripts=("copy_inputs.py" "jobsnd.py" "calc_dev.py" "make_lom.py" "post_process.py")

py='/usr/bin/python'

utils=$(git rev-parse --show-toplevel)/xTronOpt/utils
export PYTHONPATH=$(pwd):$utils:$PYTHONPATH

if [ $# -eq 0 ]; then
	for((i = 0; i < ${#scripts[@]}; i++))
	do
		echo $i ${scripts[$i]}
	done
	printf "Your pick: "
	read xv
	echo your pick is ${scripts[$xv]}
	$py $utils/${scripts[$xv]}
elif [ $# -eq 1 ]; then
	if [ $1 == 'all'  ]; then
		for((i = 1; i < ${#scripts[@]} - 2; i++))
		do
			echo running ${scripts[$i]}
			$py $utils/${scripts[$i]}
		done
	else
		echo running ${scripts[$1]}
		$py $utils/${scripts[$1]}
	fi
fi
