#!/bin/bash
# Can either take a specific generation number in io_path to calculate the error
#  for or will iterate through all the generations in IO_files
# Will call calc_gen_error.sh or user specified script to create gen_errors.txt
#  in the specified generation folder. It will then add these to the all_pop
#  file which will store all the errors. Sort is called to keep lowest errors at
#  the top. THE ONLY STIPULATION IS THAT CALC_GEN_ERROR WILL CREATE A GEN_ERRORS.TXT
############################################
# Home path

ga_path=$(git rev-parse --show-toplevel)

config_file=$ga_path/"config.txt"

if [[ ! -e $config_file ]]
then
	echo "In run_pop.sh: $config_file does not exist!"
	exit
fi

# Home path
opt_scheme=$(grep "opt_scheme" $config_file | awk '{print $2}')
home_path="$ga_path/$opt_scheme"
if [[ -z $ga_path || -z $opt_scheme || -z $home_path ]]
then
	echo "ERROR: home_path, ga_path, or opt_scheme is not set in err_calc.sh!"
	exit
fi

# Where inputs and outputs are
io_path="$home_path/IO_files"

# The population files
all_pop="$home_path/pop_all.txt"
all_pop_sorted="$home_path/pop_all_sorted.txt"

if [[ "$#" -eq 1 ]]
then
	#use the following line instead of above for a specific generation.
	perl $home_path/calc_gen_error.pl $io_path/$1 $ga_path
else
	for i in $io_path/gen*
	do
		if [ ! -e $i/gen_errors.txt ]
		then
			echo "Calculating error for $i"
			# Script to calculate the error for a specific generation below
			# Can be shell or perl script or anything else
			#$home_path/calc_gen_error.sh $i 		
			perl $home_path/calc_gen_error.pl $i $ga_path
			cat $i/gen_errors.txt $all_pop > $home_path/temp
			mv $home_path/temp $all_pop
#		else
#			echo -e "gen_errors.txt alread exists in $i.
#Please remove if you would like to recalculate error\n"
		fi
	done

	# sort by the last column
	num_cols=$(head -n 1 $all_pop | awk '{printf NF}')
	sort -g -k$num_cols $all_pop > $home_path/temp
	cat $home_path/pop_label.txt $home_path/temp > $all_pop_sorted
	rm $home_path/temp
#	echo -e "Finished calculating error\n"
fi
