#!/bin/bash
# Created by Matthew Wang
##############################################################
# This script sets up the input files for all the 
#  parameter sets of a generation. It requires 3 command line args.
# 1. The population of parameter sets
# 2. The path to the directory where all input and output files for the job
#     will be stored.
# 3. The name of the script that the commands will be stored in and be run
#     at the end of this file.
# This script will then take each parameter set, set up the necessary directories,
#  secondary files, and the run script. run_pop.sh will then execute the run script.
##############################################################

# Command line argument check
if [[ $# -ne 3 ]]
then
	echo -e "\nRequires 3 input arguments!
1. Population of parameter sets file
2. Path to directory for job (gen#)
3. run_script which will be executed for job"
	echo -e "Ex: ./job_setup.sh population.txt IO_files/gen1 IO_files/gen1/job_files/run_script.sh \n"
	exit
fi

# Get command line args
param_sets_file=$1
job_path=$2
run_script=$3

# Config file
config_file="config.txt"     # search the parent directory
if [[ ! -e $config_file  ]]
then
	echo "In job_setup.sh: $config_file does not exist!"
	exit
fi

# Home path
# Reading in the config file
ga_path=$(grep "ga_path" $config_file | awk '{print $2}')
opt_scheme=$(grep "opt_scheme" $config_file | awk '{print $2}')
home_path="$ga_path/$opt_scheme"
if [[ -z $ga_path || -z $opt_scheme || -z $home_path ]]
then
	echo "ERROR: ga_path, opt_scheme, or home_path is not set in $config_file!"
	exit
fi

xTronOpt_config_file="$home_path/xTronOpt_config.txt"     # search the parent directory
if [[ ! -e $xTronOpt_config_file ]]
then
	echo "In job_setup.sh: $xTronOpt_config_file does not exist!"
	exit
fi

# Reading in the xTronOpt_config file
src=$(grep -E "^src" $xTronOpt_config_file | awk '{print $2}')
setting=""
exe=""
scratch=""
basis_data=""
if [[ -z $src ]]
then
	setting=$(grep "^setting" $xTronOpt_config_file | awk '{print $2}')
	exe=$(grep "^exe" $xTronOpt_config_file | awk '{print $2}')
	basis_data=$(grep "^basis_data" $xTronOpt_config_file | awk '{print $2}')
	scratch=$(grep "^scratch" $xTronOpt_config_file | awk '{print $2}')
else
	# The following to settings are not necessarily right.
	#	setting=$src/setting
	#	exe=$src/build/xtron.exe
	echo "In job_setup.sh: do not specify src in xTron_config for now."
	exit
fi

lom_ext=$(grep "^lom_ext" $xTronOpt_config_file | awk '{print $2}')

xcfunc1=$(grep "^xcfunc1_all" $xTronOpt_config_file | awk '{print $2}')
xcfunc2=$(grep "^xcfunc2_all" $xTronOpt_config_file | awk '{print $2}')

if [[ -z $setting || -z $exe || -z $basis_data || -z $scratch ]]
then
	echo "ERROR: setting, exe, basis_data or scratch is not set in $xTronOpt_config_file\n"
	exit
fi

# Linear parameter file. Could make this a command line arg in the future for ease of use.
#  Hardcoded for now.
linear_params_file="$home_path/linear_params.txt"
linear_params_flag=0
num_linear_params=0
if [[ -e $linear_params_file ]]
then
	linear_params_flag=1
	num_linear_params=$(wc -l $linear_params_file | awk '{print $1}')
	# Check if there are linear parameters in linear_params.txt
	if [[ $num_linear_params -gt 0 ]]
	then
		cp $linear_params_file $job_path/
	fi
fi

# This is the path to the original input files that will be altered
# with new parameters.
base_files_path="$home_path/mol_sets"
# which molecule sets to use for optimization
base_sets_file="$base_files_path/sets_list.txt"

##############################################################
# If the sub-iterations in a gen should be separated, below
# should be moved into the loop
##############################################################
# file to store scripts and config files
scripts_configs_path=$job_path/scripts_configs
mkdir -p $scripts_configs_path

# Set up directory structure for the different sets (i.e. diatomics,polyatomics)
if [[ ! -e $base_sets_file ]]
then
	echo "$base_sets_file does not exist! Please setup $base_sets_file"
	exit
fi
num_sets=$(wc -l  $base_sets_file | awk '{print $1}')
for ((i=1; i<=$num_sets; i++))
do
	mol_set=$(awk -v row_var=$i 'NR==row_var {print $1}' $base_sets_file)
	if [[ $mol_set != "*"* ]]
	then
		mkdir $job_path/$mol_set
	fi
done
##############################################################
##############################################################

# Copying the meta information for the job into the generation for later use and encapsulating
cp $xTronOpt_config_file $job_path/
cp $base_sets_file $job_path/
cp $home_path/mol_sets/template1.txt $job_path
cp $home_path/mol_sets/template2.txt $job_path

num_param_sets=$(wc -l $param_sets_file | awk '{print $1}')
# loop over each parameter set
for (( i=1; i<=$num_param_sets; i++ ))
do
	# Should we use an iter_path to self-contain everything in an iteration folder?
	#  This means that all the molecule jobs would be in each iteration folder rather
	#  than all in its molecule set folder. If so, replace $job_path with $iter_path
	#  and move all the above double hashtaged section down below.
#	iter_path=$job_path/iter$i
#	mkdir -p $iter_path
	
	# Directory for the configuration files
	config_path=$scripts_configs_path/config$i
	mkdir -p $config_path
	# copy relevant mem_infor_files and xcfunc.conf from settings to $config_path
	cp $setting/* $config_path/

	num_params=$(awk -v row_var=$i 'NR==row_var {print }' $param_sets_file | awk '{print NF}')
	if [[ $num_params -lt 2 ]]    # use 4 because first number is ID
	then
		echo "Incorrect number of number of parameters for this job. Requires at least 2."
		exit
	fi

	# Get parameters from the parameter set file and replace them in xcfunc.conf
	# NR is row number
	# get the first parameter in row $i
	param1=$(awk -v row_var=$i 'NR==row_var {print $1}' $param_sets_file)
	param2=$(awk -v row_var=$i 'NR==row_var {print $2}' $param_sets_file)
	#param3=$(awk -v row_var=$i 'NR==row_var {print $3}' $param_sets_file)

	# has linear parameters
	if [[ $linear_params_flag -eq 1 && $num_linear_params -gt 0 ]]
	then
		if [[ $num_linear_params -eq 1 ]] # use the same linear params for all nonlinear params
		then
			lin_param1=$(awk '{print $1}' $linear_params_file)
			lin_param2=$(awk '{print $2}' $linear_params_file)
			lin_param3=$(awk '{print $3}' $linear_params_file)

			sed -i -r "s/parameters      1.355  0.038  1.128/parameters      1.355  0.038 $lin_param1/" $config_path/xcfunc.conf
			perl -0777 -i -pe "s/correlation     B13COOR_OPP B13COOR_PAR  KP14C\ncorrelation_coefficients    1.0  1.0  1.0/correlation     B13COOR_OPP B13COOR_PAR  KP14C\ncorrelation_coefficients    $lin_param2  $lin_param3  1.0/is" $config_path/xcfunc.conf
		elif [[ $num_linear_params -eq $num_params ]]
		then
			lin_param1=$(awk -v row_var=$i 'NR==row_var {print $1}' $linear_params_file)
			lin_param2=$(awk -v row_var=$i 'NR==row_var {print $2}' $linear_params_file)
			lin_param3=$(awk -v row_var=$i 'NR==row_var {print $3}' $linear_params_file)

			sed -i -r "s/parameters      1.355  0.038  1.128/parameters      1.355  0.038  $lin_param1/" $config_path/xcfunc.conf
			perl -0777 -i -pe "s/correlation     B13COOR_OPP B13COOR_PAR  KP14C\ncorrelation_coefficients    1.0  1.0  1.0/correlation     B13COOR_OPP B13COOR_PAR  KP14C\ncorrelation_coefficients    $lin_param2  $lin_param3  1.0/is" $config_path/xcfunc.conf
		else
			echo "Number of linear params, $num_linear_params,  is greater than 1 but not equal to the number of nonlinear params, $num_params!"
			echo " Not using any linear params in $linear_params_file"
		fi
	fi

	# change the parameters of the input file
	sed -i -r "s/parameters      1.355  0.038/parameters      $param1  $param2/" $config_path/xcfunc.conf
	# For changing the becke05_p parameter
	#  Not sure if we're even changing the becke05_p parameter anymore
#	if [[ $num_parms -ge 4 ]]
#	then
#		# get the fourth parameter in row $i
#		param4=`awk -v row_var=$i 'NR==row_var {print $4}' $param_sets_file`
#		#sed -i -r "s/becke05_p   115.0E0/becke05_p   ${param4}/" $config_path/xcfunc.conf
#		sed -i -r "s/becke05_p   115.0E0/becke05_p   $param4/" $config_path/xcfunc.conf
#	fi

	
	echo "#!/bin/bash" > $config_path/iter$i.sh
	########## Add qsub information here if your are submitting to a queue  ########
	# XTRON_SETTINGS_FILE is where it looks for the xcfunc.conf to use which has the
	#  parameters set for this run
	# XTRON_BASIS_SET_HOME for ParamOpt branch, is where it will look for basis set files.
	# XTRON_SCRATCH_DIR is for exporting the scratch directory to correct path
	# XTRON_BASIS_FILE_DIR is for the trunk.
	echo -e "\nexport XTRON_SETTING_FILE=$config_path
export XTRON_BASIS_FILE_DIR=$basis_data  
export XTRON_SCRATCH_DIR=$scratch\n" >> $config_path/iter$i.sh
	echo -e "\nexport XTRON_SETTING_FILE=$config_path
export XTRON_BASIS_FILE_DIR=$basis_data
export XTRON_SCRATCH_DIR=$scratch\n" >> $config_path/header.sh

#For future reference.  HOME should point to $src
#export XTRON_HOME=/shared2/jkong/xtron.trunk.new
#export XTRON_SETTING_FILE=$XTRON_HOME/setting  

	# Loop for each molecules set
	for ((j=1; j<=$num_sets; j++))
	do
		mol_set=$(awk -v row_var=$j 'NR==row_var {print $1}' $base_sets_file)
		if [[ $mol_set != "*"* && ! -z $mol_set ]]
		then
			if [ -e $base_files_path/$mol_set/list_of_molecules ]
			then
				echo "WARNING: list_of_molecules exists in $mol_set"
				lom=$base_files_path/$mol_set/list_of_molecules
			elif [ -e $base_files_path/$mol_set/list_of_molecules$lom_ext ]
			then
				lom=$base_files_path/$mol_set/list_of_molecules$lom_ext
			else
				echo "No lom found for $mol_set"
				exit
			fi
			cp $lom $job_path/$mol_set/

			# Loop to construct the executable input files and the commands for the pbs job
			while read line
			do
				if [[ $line != "*"* && ! -z $line ]]
				then
					mol=$(echo "$line" | awk '{print $1}')
					if [[ ! -e $base_files_path/$mol_set/$mol.in ]]
					then
						echo "No input file for $mol"
						exit
					fi

					num_fields=$(echo $line | awk '{print NF}')
					num_fields_for_diss=0

					# creating the intput file with basis file name
					cp $base_files_path/$mol_set/$mol.in $job_path/$mol_set/${mol}_$i.in
					if [[ $mol_set == "fracspin" ]]
					then
						cat $base_files_path/$mol_set/template1.txt $base_files_path/$mol_set/${mol}.in $base_files_path/$mol_set/template2.txt \
						$base_files_path/$mol_set/${mol}.in $base_files_path/$mol_set/template3.txt \
						$base_files_path/$mol_set/${mol}.in $base_files_path/$mol_set/template4.txt >> $job_path/$mol_set/${mol}_$i.in
					else
						cat $base_files_path/template1.txt $base_files_path/$mol_set/${mol}.in $base_files_path/template2.txt >> $job_path/$mol_set/${mol}_$i.in
						num_fields_for_diss=$(echo $line | awk '{print $2}')
					fi
					
					offset=3
					#offset=$(($num_fields_for_diss+3))
					if [[ $num_fields_for_diss -ne 0 ]]
					then
						offset=$(($num_fields_for_diss*2+5))
					fi

					# changing functional information for all files information
					# THERE WILL BE A BUG HERE IF YOU TRY TO COMBINE FINE GRAIN WITH COARSE GRAIN CONTROL, THIS NEEDS TO BE FIXED AT A LATER DATE
					if [[ ! -z $xcfunc1_all ]]
					then
						sed -i -r "s/name  HF/name  $xcfunc1_all/" $job_path/$mol_set/${mol}_$i.in
					fi
					if [[ ! -z $xcfunc2_all ]]
					then
						sed -i -r "s/name  KP14/name  $xcfunc2_all/" $job_path/$mol_set/${mol}_$i.in
					fi

					for ((k=$offset; k<$num_fields; k=k+2))
					do
						option=$(echo $line | awk -v col_var=$k '{print $col_var}')
						value=$(echo $line | awk -v col_var=$(($k+1)) '{print $col_var}')
						if [[ $option == "scf_algorithm" ]]
						then
							sed -i -r "s/$option  diis/$option  $value/" $job_path/$mol_set/${mol}_$i.in
						elif [[ $option == "xcfunc1" ]]
						then
							sed -i -r "s/name  HF/name  $value/" $job_path/$mol_set/${mol}_$i.in
						elif [[ $option == "xcfunc2" ]]
						then
							sed -i -r "s/name  KP14/name  $value/" $job_path/$mol_set/${mol}_$i.in
						elif [[ $option == "alpha_frac_infor_mo_begin_index" ]]
						then
							sed -i -r "s/$option 0/$option $value/" $job_path/$mol_set/${mol}_$i.in
						elif [[ $option == "alpha_frac_infor_nmo" ]]
						then
							sed -i -r "s/$option 1/$option $value/" $job_path/$mol_set/${mol}_$i.in
						elif [[ $option == "alpha_frac_infor_scale_value" ]]
						then
							sed -i -r "s/$option 0.5/$option $value/" $job_path/$mol_set/${mol}_$i.in
						elif [[ $option == "beta_frac_infor_mo_begin_index" ]]
						then
							sed -i -r "s/$option 0/$option $value/" $job_path/$mol_set/${mol}_$i.in
						elif [[ $option == "beta_frac_infor_nmo" ]]
						then
							sed -i -r "s/$option 1/$option $value/" $job_path/$mol_set/${mol}_$i.in
						elif [[ $option == "beta_frac_infor_scale_value" ]]
						then
							sed -i -r "s/$option 0.5/$option $value/" $job_path/$mol_set/${mol}_$i.in
						elif [[ $option == "do_odd_electron" ]]
						then
							sed -i -r "s/$option false/$option true/" $job_path/$mol_set/${mol}_$i.in
						else
							echo "Unrecognized option: $option in $mol, please check spelling or code in option"
						fi

						## Can't be used unless each option is unique
						#if [[ -z $(grep -e "^$option" $job_path/$mol_set/${mol}_$i.in) || 
						#	$(grep -e "^$option" $job_path/$mol_set/${mol}_$i.in | wc -l) -gt 1 ||
						#	-z $(grep -e "^$option" $base_files_path/list_of_options) ]]
						#then
						#	echo "$option not found in template files, not found in list_of_options, or found multiple times in the template file for $mol"
						#else
						#	sed -i -r "s/$option */$option $value/" $job_path/$mol_set/${mol}_$i.in
						#fi
					done

					echo "$exe $job_path/$mol_set/${mol}_$i.in >& $job_path/$mol_set/${mol}_$i.out" >> $config_path/iter$i.sh
					echo "source $config_path/header.sh; $exe $job_path/$mol_set/${mol}_$i.in >& $job_path/$mol_set/${mol}_$i.out" >> $config_path/commands
				fi
			done < $lom
		fi
	done

	chmod 755 $config_path/iter$i.sh
	echo "$config_path/iter$i.sh" >> $run_script
	#echo "qsub $config_path/iter$i.sh" >> $run_script      # can use qsub here if we are using a queuing system
	#echo "eden $config_path/iter$i.sh" >> $run_script      # can use eden or some equivalent  here if we are using it 
	
done
