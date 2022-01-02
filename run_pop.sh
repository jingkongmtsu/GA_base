#!/bin/bash
# Created by Matthew Wang
##############################################################
# - This is the main driver file for the Genetic algorithm
#   for running jobs using input parameters 
# - This script does:
#	1. Set up necesary directories
#	2. Goes through each line of the population, grabs
#		the parameters and calls another script
#		(placeholder called job_setup.sh) 
#		to set up input files
#	3. Constructs a job commands txt file for execution
#		Ex. exe test.in test.out
#	4. Runs the jobs/commands. Commands in run_script.sh to
#		be executed in current env or in commands to be
#		used in other scripts.
# - Ex: ./run_pop.sh pop_init.txt
#
#
# - job_setup.sh is a placeholder for a script that must take at minimum
# 	1. A file with the parameter sets to use for that run
#	2. The path to the current generation for program use purposes
#	3. The run script which is the script which will run the commands
#	
#	Any further arguments needed can be added to the line that calls
#	run script and modified in the run script. These 3 arguments are the
#	3 I've deemed necessary so far.
#
# 	The setup script will then populate the run script with any necessary
#	set up or env variables for the executable. It will also do any set up
#	necessary for the job into the iteration path directory. All executable
#	calls will go into the $run_script .
##############################################################

# Command line argument check

if [[ $# < 1 ]]
then
	echo -e "run_pop.sh requires input argument for population of parameters!"
	echo -e "Ex: ./run_pop.sh pop.txt\n"
	exit
fi


# The file with the population parameters
pop_file=$1

# Config file
config_file="config.txt"
if [[ ! -e $config_file ]]
then
	echo "In run_pop.sh: $config_file does not exist!"
	exit
fi

# Home path
ga_path=$(grep "ga_path" $config_file | awk '{print $2}')
opt_scheme=$(grep "opt_scheme" $config_file | awk '{print $2}')
home_path="$ga_path/$opt_scheme"
if [[ -z $ga_path || -z $opt_scheme || -z $home_path ]]
then
	echo "ERROR: home_path, ga_path, or opt_scheme is not set in run_pop.sh!"
	exit
fi

# Where inputs and outputs will go
io_path="$home_path/IO_files"

# This is where the inputs and outputs of the new generation will go
gen_num=$2
gen_path="$io_path/$gen_num"

if [ -z "$gen_num" ] 
then
	gen_num=1
	gen_path="$io_path/gen$gen_num"
	while [ -d $gen_path ]
	do
		gen_num=$(($gen_num+1))
		gen_path="$io_path/gen$gen_num"
	done
fi

echo "Generation $gen_num"

# Job scripts path, can make job path to be separate from the generation directory
#  This directory should contain scripts and files necessary for the whole job.
job_path="$gen_path/job_files"

#set up directories
if [ -d "$gen_path" ]
then
	echo "$gen_path already exists!"
	exit
fi

mkdir -p $gen_path
mkdir -p $job_path

# copy the generation parameter information into the folder
cp $pop_file $gen_path/population.txt

# Create run script
run_script="$job_path/run_script.sh"
#job_commands="$job_path/job_commands.txt"
echo -e "#!/bin/bash\n\ndate\n" > $run_script

# call script that creates the input files and sets up necessary folders for the specific job
$home_path/job_setup.sh $pop_file $gen_path $run_script 

echo -e "echo \"Done with generation $gen_num\"" >> $run_script

echo -e "\ndate\n" >> $run_script

# calculate difference
date1=`date "+%d %H %M %S"`

num_sets=$(wc -l $pop_file | awk '{print $1}')
for (( i=1; i<=$num_sets; i++ ))
do
       cat $gen_path/scripts_configs/config$i/commands >> $gen_path/scripts_configs/commands
done

echo "Ready to run jobs"

####################################
# One of the below must be chosen!
####################################
## This is used to run on all roughshod nodes. Specific to roughshod or some other beowulf cluster
perl multi_node_run.pl $gen_path/scripts_configs

## The cmds below run the run script in the current environment
#chmod 755 $run_script
#echo "Running"
#$run_script

date2=`date "+%d %H %M %S"`
timeDiff=`echo "$date1 $date2" | awk '{printf "%f", (\
$5-$1)*24.0 + $6-$2 + \
($7-$3)/60.0 + ($8-$4)/(60.0*60.0)}'`
echo "$date1"
echo "$date2"
echo "Time job took to complete:  $timeDiff hrs"
echo "Finished with generation $gen_num"

