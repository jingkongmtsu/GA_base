#!/bin/perl
# Calculates the error for one generation
# Outputs into a gen_error.txt. The format of the file is:
#  iterNum subIterNum parameter1 parameter2 .. parameterN set1{diatomics} mad mol_w_max_err max_err set2 ..    full_err
# The full error at the end is a weight average of the mean absolute deviation between the sets
# 
# Also calculates files needed for least squares fitting
#
# NEW LIST OF MOLS FILE FORMAT:
#  mol_name #_of_PAIRS weight mol_coeff coeff1 part1 [ coeff2 part2 coeff3 part3 ........ ]

use strict;
use warnings;

my ($gen_path, $ga_path);

my $num_args = $#ARGV + 1;
if($num_args != 2)
{
	die "calc_gen_error.pl: Requires two args: path to output files and config file\n";
}
else
{
	$gen_path = $ARGV[0];
	chomp($gen_path);
	$ga_path = $ARGV[1];
	chomp($ga_path);
}

# get config file parameters
my ($opt_scheme, $conversion_factor, $consistency_thres, $diff_thres, $lom_ext, $xcfunc1_all, $xcfunc2_all);
$consistency_thres = -1;    # unset value
$diff_thres = -1;    # unset value
$conversion_factor = 1.0;       # default is hartrees at 1.0
if( ! -e "$ga_path/config.txt" )
{
	die "In calc_gen_error.pl: $ga_path/config.txt does not exist!";
}
open CONFIG, "<$ga_path/config.txt" or die "Cannot open config.txt";
for my $line (<CONFIG>)
{
	my @line_split = split(' ', $line);
	if($line_split[0] eq "ga_path")
	{
		$ga_path = $line_split[1];
	}
	elsif($line_split[0] eq "opt_scheme")
	{
		$opt_scheme = $line_split[1];
	}
}
close(CONFIG);
if($ga_path eq "" or $opt_scheme eq "")
{
	die "ga_path or opt_scheme from config.txt is not set!";
} 

open CONFIG, "<$gen_path/xTronOpt_config.txt" or die "Cannot open xTronOpt_config.txt";
for my $line (<CONFIG>)
{
	my @line_split = split(' ', $line);
	if($line_split[0] eq "conversion_factor")
	{
		$conversion_factor = $line_split[1];
	}
	elsif($line_split[0] eq "consistency_thres")
	{
		$consistency_thres = $line_split[1];
	}
	elsif($line_split[0] eq "difference_thres")
	{
		$diff_thres = $line_split[1];
	}
	elsif($line_split[0] eq "lom_ext")
	{
		$lom_ext = $line_split[1];
	}
	elsif($line_split[0] eq "xcfunc1_all")
	{
		$xcfunc1_all = $line_split[1];
	}
	elsif($line_split[0] eq "xcfunc2_all")
	{
		$xcfunc2_all = $line_split[1];
	}
}
close(CONFIG);
if($consistency_thres == -1)
{
	die "consistency_thres variable not set in $ga_path/$opt_scheme/xTronOpt_config.txt\n";
}
if($diff_thres == -1)
{
	die "difference_thres variable not set in $ga_path/$opt_scheme/xTronOpt_config.txt\n";
}


# Getting the generation number
my $gen_num;
($gen_num) = $gen_path =~ m/([0-9]+$)/;
my $mol_sets_path = "$ga_path/$opt_scheme/mol_sets";   # assumes this is the mol sets path
my $err_file = "$gen_path/gen_errors.txt";
my $stat_file = "$gen_path/gen_stats.txt";

# read in the set names and the weights
my (%sets_weights, %sets_num_mols, @sets_list);
#open SET_LIST, "<$mol_sets_path/sets_list.txt" or die "Cannot open set list from $mol_sets_path/sets_list.txt\n";
open SET_LIST, "<$gen_path/sets_list.txt" or die "Cannot open set list from $gen_path/sets_list.txt\n";
for my $line (<SET_LIST>)
{
	chomp($line);
	# does contains a * which means to calculate that set
	if(index($line, "*") == -1)
	{
		my @line_split = split(" ", $line);
		$sets_weights{$line_split[0]} = $line_split[1]; # key is the set name, value is the weight
		push(@sets_list, $line_split[0]);
		my ($lom);
		if ( -e "$gen_path/$line_split[0]/list_of_molecules" )
		{
			$lom = "$gen_path/$line_split[0]/list_of_molecules";
		}
		elsif ( -e "$gen_path/$line_split[0]/list_of_molecules$lom_ext" )
		{
			$lom = "$gen_path/$line_split[0]/list_of_molecules$lom_ext";
		}
		else
		{
			die "$gen_path/$line_split[0]/list_of_molecules does not exist!";
		}
		$sets_num_mols{$line_split[0]} = `grep -v "*" $lom | grep -P '\\S' | wc -l`;	
	
		# Using the old format of pulling from mols sets for list of molecules rather than the generation
		#if( ! -e "$mol_sets_path/$line_split[0]/list_of_molecules" )
		#{
		#	die "$mol_sets_path/$line_split[0]/list_of_molecules does not exist!";
		#}
		#$sets_num_mols{$line_split[0]} = `grep -v "*" $mol_sets_path/$line_split[0]/list_of_molecules | grep -P '\S' | wc -l`;	
		chomp($sets_num_mols{$line_split[0]});
	}
}
close(SET_LIST);
#for my $key(keys %sets_num_mols)
#{
#	print "$key -> $sets_num_mols{$key}\n";
#}
# number of sets
my $num_sets = keys %sets_weights;

# parameter sets(nonlinear)
my ($num_param_sets, @param_sets);
open POP, "<$gen_path/population.txt" or die "Can't open population file $gen_path/population.txt\n";
$num_param_sets = 0;
for my $line (<POP>)
{
	chomp($line);
	push(@param_sets, $line);
	$num_param_sets++;
}

my $num_linear_param_sets = 0;
my @linear_params;
# parameter sets(linear)
if( -e "$gen_path/linear_params.txt" )
{
	open LINEAR_PARAMS, "<$gen_path/linear_params.txt" or die "Can't open linear parameters file $gen_path/linear_params.txt\n";
	for my $line (<LINEAR_PARAMS>)
	{
		chomp($line);
		push(@linear_params, $line);
		$num_linear_param_sets++;
	}
}

open ERR_FILE, ">$err_file", or die "Cannot open error file $err_file\n";
open STAT_FILE, ">$stat_file", or die "Cannot open error file $stat_file\n";

for(my $i=1; $i<=$num_param_sets; $i++)
{
	# hash to store the atom and other energies
	my (%piece_SCF_e, %piece_optLSF, %piece_core_e, %piece_nucRep_e, %piece_coulomb_e, %piece_exchange_e, %piece_last_e, %piece_diis, %inconsistent, %cycle0, %diff_thres);

	open ALL_FILE, ">$gen_path/all_values$i.txt", or die "Cannot open all values file $gen_path/all_values$i.txt\n";
	print ALL_FILE "#mol_name exp_diss_e diss_SCF_e dev_err mol_diis mol_weight mol_SCF_e diss_core_e diss_nucRep_e diss_coulomb_e diss_exchange_e diss_x0 diss_x1 diss_x2 diss_x3\n";

	my $scftxt = $gen_path."/".(split(/\//, $gen_path))[-1].".txt";
	open SCF_ANALYSIS, ">$scftxt", or die "Cannot open scf analysis file\n";
	#start the full error string and full err value and weight
	my $full_str = "$gen_num $i $param_sets[$i-1]";
	my $full_stat_str = "$gen_num $i $param_sets[$i-1]";
	if($num_linear_param_sets != 0)
	{
		if($num_linear_param_sets == 1)
		{
			$full_str = "$full_str $linear_params[0]";
			$full_stat_str = "$full_stat_str $linear_params[0]";
		}
		elsif($num_linear_param_sets == $num_param_sets) 
		{
			$full_stat_str = "$full_stat_str $linear_params[$i-1]";
		}
		elsif($num_linear_param_sets != $num_param_sets) 
		{
			print "Possible error: num_params_sets, $num_param_sets, is not equal to num_linear_param_sets, $num_linear_param_sets\n";
		}
	}

	my ($set_weighted_mad, $set_weight_total, $all_mol_weighted_mad, $all_mol_weight_total, $sumSqs);
	my ($num_cols, @line_split, $lowest_iter_num, @files);
	$set_weighted_mad = $set_weight_total = $all_mol_weighted_mad = $all_mol_weight_total = $sumSqs = 0;

	my $set_key;
	# loop to calculate the error for each set, diatomic, polyatomic
	foreach $set_key (@sets_list)
	{
		print "$set_key working\n";
		my ($mol_weight_total, $abs_dev_total, $abs_perc_dev_total, $max_err, $max_molecule);
		$mol_weight_total = $abs_dev_total = $abs_perc_dev_total = $max_err = 0;
		$max_molecule = "";
		
		# get the output file for each set
		@files = <$gen_path/$set_key/*_$i.out>;
		my $num_files = @files;
		#if($num_files < $sets_num_mols{$set_key})
		#{
		#	print "Number of molecules in $set_key, $sets_num_mols{$set_key}, is greater than number of output files, $num_files, for gen $gen_num iter $i!\n";
		#	exit;
		#}

		# open the list of molecules and REF file for each set
		my ($lom);
		if ( -e "$gen_path/$set_key/list_of_molecules" )
		{
			$lom = "$gen_path/$set_key/list_of_molecules";
		}
		elsif ( -e "$gen_path/$set_key/list_of_molecules$lom_ext" )
		{
			$lom = "$gen_path/$set_key/list_of_molecules$lom_ext";
		}
		else
		{
			die "$gen_path/$set_key/list_of_molecules does not exist!";
		}
		open MOL_LIST, "<$lom", or die "Cannot open list_of_molecules for $set_key\n";

		# open the deviation file for the set
		open SET_ERROR, ">$gen_path/$set_key\_dev$i", or die "Cannot open error dev file for $set_key\n";
		printf SET_ERROR "%-12s %-8s %-8s %-4s\n", "Molecule","Ref","Calc","Dev";


		my %ref_diss_vals;
		if($set_key ne "atoms")
		{
			open REF, "<$mol_sets_path/$set_key/ref_vals", or die "Cannot open REF file for $set_key\n";
			# Read in the REF values
			for my $line (<REF>)
			{
				if(index($line, "#") == -1)
				{
					my @line_split = split(" ", $line);
					$ref_diss_vals{$line_split[0]} = $line_split[1];
				}
			}
			close(REF);
		}
		#for my $key (keys %ref_diss_vals)
		#{
		#	print "$key -> $ref_diss_vals{$key}\n";
		#}

		# Loop over each molecules and calculate the error
		for my $line (<MOL_LIST>)
		{
			my ($mol_SCF_e, @mol_optLSF, $mol_core_e, $mol_nucRep_e, $mol_coulomb_e, $mol_exchange_e, $mol_diis, $mol_last_e);
			my ($diss_SCF_e, $diss_core_e, $diss_nucRep_e, $diss_coulomb_e, $diss_exchange_e);

			my $mol_weight; 
			# check if it needs a skip
			if(index($line, "*") == -1)
			{
				my ($line_split, $line_size, $block, $mol_name, $mol_file, $num_calc_fields, $converged, $lowest_iter_num, $xcfunc2);
				@line_split = split(" ", $line);
				# the molecule name, weight, and formula from the list_of_molecules file
				$line_size = scalar(@line_split);
				$mol_name = $line_split[0];
				$mol_file = "$gen_path/$set_key/$mol_name\_$i.out";
				$num_calc_fields = $line_split[1];
				($xcfunc2) = $line =~ m/xcfunc2\s+(.*?)\s+/;
				if(!defined($xcfunc2))
				{
					$xcfunc2 = $xcfunc2_all;
				}
				$converged = 1;

				if($set_key eq "fracspin")
				{
					$mol_weight = $line_split[1];

					my ($rohf_SCF_e, @rohf_optLSF, $rohf_core_e, $rohf_nucRep_e, $rohf_coulomb_e, $rohf_exchange_e);
					my ($frac_SCF_e, @frac_optLSF, $frac_core_e, $frac_nucRep_e, $frac_coulomb_e, $frac_exchange_e, $frac_diis);
					
					$block = `tail -n 20 $mol_file`;
					($frac_SCF_e) = $block =~ m/.*converge.*?(-?[0-9]+\.[0-9]+)/;
					($frac_core_e) = $block =~ m/.*core.*?(-?[0-9]+\.[0-9]+)/;
					($frac_nucRep_e) = $block =~ m/.*NucRepulsion.*?(-?[0-9]+\.[0-9]+)/;
					($frac_coulomb_e) = $block =~ m/.*Coulomb.*?(-?[0-9]+\.[0-9]+)/;
					($frac_exchange_e) = $block =~ m/.*Exchange.*?(-?[0-9]+\.[0-9]+)/;
					($frac_diis) = $block =~ m/.*DIIS.*?([0-9]+\.[0-9]+)/;
					(my $param_line) = $block =~ m/(ParamOptLSF.*end)/;
					my @param_split = split(' ', $param_line);
					@frac_optLSF = @param_split[1 .. $#param_split-1];
					$num_cols = @param_split;
					$num_cols = $num_cols - 2; # get rid of the paramOptLSF and the end keywords
					if($block =~ m/(failed to converge)/)
					{
						$converged = 0;
					}
					
					$block = `grep -B 20 "FOURTH SCF" $mol_file`;
					($rohf_SCF_e) = $block =~ m/.*converge.*?(-?[0-9]+\.[0-9]+)/;
					($rohf_core_e) = $block =~ m/.*core.*?(-?[0-9]+\.[0-9]+)/;
					($rohf_nucRep_e) = $block =~ m/.*NucRepulsion.*?(-?[0-9]+\.[0-9]+)/;
					($rohf_coulomb_e) = $block =~ m/.*Coulomb.*?(-?[0-9]+\.[0-9]+)/;
					($rohf_exchange_e) = $block =~ m/.*Exchange.*?(-?[0-9]+\.[0-9]+)/;
					($param_line) = $block =~ m/(ParamOptLSF.*end)/;
					@param_split = split(' ', $param_line);
					@rohf_optLSF = @param_split[1 .. $#param_split-1];

					$diss_SCF_e = $conversion_factor*($rohf_SCF_e - $frac_SCF_e);
					$diss_core_e = $conversion_factor*($rohf_core_e - $frac_core_e);
					$diss_nucRep_e = $conversion_factor*($rohf_nucRep_e - $frac_nucRep_e);
					$diss_coulomb_e = $conversion_factor*($rohf_coulomb_e - $frac_coulomb_e);
					$diss_exchange_e = $conversion_factor*($rohf_exchange_e - $frac_exchange_e);
					my $dev_err = $diss_SCF_e; # error between the calculated and the reference
					print ALL_FILE "$mol_name 0 $diss_SCF_e $dev_err $frac_diis $mol_weight $frac_SCF_e $diss_core_e $diss_nucRep_e $diss_coulomb_e $diss_exchange_e ";
					for(my $j=0; $j<$num_cols; $j++)
					{
						my $diss_optLSF = $conversion_factor*($rohf_optLSF[$j] - $frac_optLSF[$j]);
						print ALL_FILE "$diss_optLSF ";
					}
					print ALL_FILE "\n";

					# add to sum/total error
					$abs_dev_total = $abs_dev_total + $mol_weight*abs($dev_err);

					$all_mol_weighted_mad = $all_mol_weighted_mad + $mol_weight*abs($dev_err);
					$sumSqs = $sumSqs + $mol_weight*($dev_err**2);

					$mol_weight_total = $mol_weight_total + $mol_weight;
					$all_mol_weight_total = $all_mol_weight_total + $mol_weight;

					if(abs($dev_err) > abs($max_err))
					{
						$max_err = $dev_err;
						$max_molecule = $mol_name;
					}

					printf SET_ERROR "%-10s %8.4f %8.4f %8.4f    ",$mol_name,0.0,$diss_SCF_e,$dev_err;
					# Print to deviation files
					if($converged == 0)
					{
						printf SET_ERROR "not_converged\n", 
					}
					else
					{
						printf SET_ERROR "converged\n";
					}

				}
				else
				{
					my $do_paramOptLSF = 1;
					my $inconsistent_flag = 0;
					my $diff_thres_flag = 0;
					my $cycle0_flag = 0;
					my $mol_cycle0_e = 0;
					my $warn_str = "";
					######################################################
					# Get relevant data for calculating error
					#  get calculated molecule energy from software
					$block = `tail -n 20 $mol_file`;
					#tmp change for merged trunk. jk
					#$block = `tail -n 15 $mol_file`;

					($mol_SCF_e) = $block =~ m/.*lowest energy.*?(-?[0-9]+\.[0-9]+)/;
					($mol_last_e) = $block =~ m/.*converge.*?(-?[0-9]+\.[0-9]+)/;
					if($block =~ m/(failed to converge)/)
					{
						$converged = 0;
					}

					# get the iteration number with the lowest energy
					($lowest_iter_num) = $block =~ m/scf index is ([0-9]+)/;
					$mol_cycle0_e = `grep "$xcfunc2 iter is: 0," $mol_file | tail -n 1 | awk '{print \$NF}'`;


					print 'mol_cycle0_e is ', $mol_cycle0_e;

					chomp($mol_cycle0_e);

					# NEED TO ADD ADDITIONAL CODE TO ONLY ACT ON SECOND HALF OF OUTPUT FILE IN CASE XCFUNC1 AND XCFUNC2 ARE THE SAME
					#  THIS CODE CAN CAUSE VALUES TO BE PULLED FROM THE FIRST PART OF THE JOB AND NOT THE SECOND
					$block = `grep -B 5 -A 7 "$xcfunc2 iter is: $lowest_iter_num," $mol_file`;
					#tmp change for merged trunk. jk
					#$block = `grep -B 2 -A 3 "$xcfunc2 iter is: $lowest_iter_num," $mol_file`;

					($mol_core_e) = $block =~ m/.*core.*?(-?[0-9]+\.[0-9]+)/;
					($mol_nucRep_e) = $block =~ m/.*NucRepulsion.*?(-?[0-9]+\.[0-9]+)/;
					($mol_coulomb_e) = $block =~ m/.*Coulomb.*?(-?[0-9]+\.[0-9]+)/;
					($mol_exchange_e) = $block =~ m/.*Exchange.*?(-?[0-9]+\.[0-9]+)/;
					($mol_diis) = $block =~ m/.*DIIS.*?([0-9]+\.[0-9]+.*)/;

					my @param_split;
					(my $param_line) = $block =~ m/(ParamOptLSF.*end)/;
					if(defined($param_line))
					{
						@param_split = split(' ', $param_line);
						@mol_optLSF = @param_split[1 .. $#param_split-1];
						$num_cols = @param_split;
						$num_cols = $num_cols - 2; # get rid of the paramOptLSF and the end keywords
					}
					else
					{
						$do_paramOptLSF = 0;
					}
					######################################################
					if($lowest_iter_num == 0)
					{
						$cycle0_flag = 100;
						#if($set_key ne "atoms")
						#{
						#	$cycle0{$mol_name} = 100;
						#}
					}
					if(abs($mol_SCF_e-$mol_last_e) > $consistency_thres)
					{
						$inconsistent_flag = 1;
						#if($set_key ne "atoms")
						#{
						#	$inconsistent{$mol_name} = 1;
						#}
					}
					if(abs($mol_SCF_e - $mol_cycle0_e) < $diff_thres)
					{
						$diff_thres_flag = 10;
						#if($set_key ne "atoms")
						#{
						#	$diff_thres{$mol_name} = 10;
						#}
					}
					$cycle0{$mol_name} = $cycle0_flag;
					$inconsistent{$mol_name} = $inconsistent_flag;
					$diff_thres{$mol_name} = $diff_thres_flag;
					my $warn_temp = $cycle0_flag + $inconsistent_flag + $diff_thres_flag; 
					$warn_str = "$warn_temp";
					
					print SCF_ANALYSIS "$set_key $mol_name $warn_str $mol_cycle0_e $mol_last_e $mol_SCF_e $mol_diis\n";


					if(exists $piece_SCF_e{$mol_name})
					{
						print "WARNING. In calc_gen_error.pl, $mol_name already exists in hash piece_SCF_e. Overwritting value.\n";
					}

					$piece_SCF_e{$mol_name} = $mol_SCF_e; 
					$piece_nucRep_e{$mol_name} = $mol_nucRep_e;
					$piece_coulomb_e{$mol_name} = $mol_coulomb_e;
					$piece_exchange_e{$mol_name} = $mol_exchange_e;
					$piece_core_e{$mol_name} = $mol_core_e;
					$piece_diis{$mol_name} = $mol_diis;
					if($do_paramOptLSF ==  1)
					{
						$piece_optLSF{$mol_name} = [@param_split[1 .. $#param_split-1]];
					}

					if($num_calc_fields == 0)
					{
						print "Number of fields is 0, skipping calculation for $mol_name.\n";
					}
					elsif(! exists $ref_diss_vals{$mol_name})
					{
						print "$mol_name does not exist in REF file $mol_sets_path/$set_key/ref_vals\n";
					}
					else
					{	
						$mol_weight = $line_split[2];
						my $ref_diss_e = $conversion_factor*$ref_diss_vals{$mol_name}; # the value for the reference energy
						my $diis_str = "$mol_diis";
						my $mol_coeff = $line_split[3];

						my ($sum_piece_SCF_e, $sum_piece_core_e, $sum_piece_nucRep_e, $sum_piece_coulomb_e, $sum_piece_exchange_e, @sum_piece_optLSF);
						
						if($do_paramOptLSF ==  1)
						{
							for(my $j=0; $j<$num_cols; $j++)
							{
								push(@sum_piece_optLSF, 0);
							}
						}
						$sum_piece_SCF_e = $sum_piece_core_e = $sum_piece_nucRep_e = $sum_piece_coulomb_e = $sum_piece_exchange_e = 0;

						# calculate fragment energy sum using formula
						for(my $j=4; $j<4+2*$num_calc_fields; $j=$j+2)   # add 2 to skip molecule name and weight and num_calc_fields
						{
							my $num_of_piece = $line_split[$j];
							my $fragment_piece = $line_split[$j+1];
							my $frag_warn_code = $inconsistent{$fragment_piece} + $cycle0{$fragment_piece} + $diff_thres{$fragment_piece};
							$warn_str = "$warn_str\_$frag_warn_code";
							#if(exists $inconsistent{$fragment_piece})
							#{
							#	$inconsistent_flag = 1;
							#}
							#if(exists $cycle0{$fragment_piece})
							#{
							#	$cycle0_flag = 100;
							#}
							#if(exists $diff_thres{$fragment_piece})
							#{
							#	$diff_thres_flag = 10;
							#}

							if(exists $piece_SCF_e{$fragment_piece} and defined($piece_SCF_e{$fragment_piece})) # will have to add fragments here for the future
							{
								$sum_piece_SCF_e = $sum_piece_SCF_e + $num_of_piece*$piece_SCF_e{$fragment_piece};
								$sum_piece_core_e = $sum_piece_core_e + $num_of_piece*$piece_core_e{$fragment_piece};
								$sum_piece_nucRep_e = $sum_piece_nucRep_e + $num_of_piece*$piece_nucRep_e{$fragment_piece};
								$sum_piece_coulomb_e = $sum_piece_coulomb_e + $num_of_piece*$piece_coulomb_e{$fragment_piece};
								$sum_piece_exchange_e = $sum_piece_exchange_e + $num_of_piece*$piece_exchange_e{$fragment_piece};
								$diis_str = "$diis_str $piece_diis{$fragment_piece}";
								if($do_paramOptLSF == 1)
								{
									for(my $k=0; $k<$num_cols; $k++)
									{
										$sum_piece_optLSF[$k] = $sum_piece_optLSF[$k] + $num_of_piece*$piece_optLSF{$fragment_piece}[$k];
									}
								}
							}
							else
							{
								print "ERROR, $fragment_piece for $mol_name either does not exist or has not been calculated yet!\n";
							}
						}
						# Take the difference between the fragment energies and the molecule energy
						$diss_SCF_e = $conversion_factor*($sum_piece_SCF_e - $mol_coeff*$mol_SCF_e); # calculated disassociation energy
						$diss_core_e = $conversion_factor*($sum_piece_core_e - $mol_coeff*$mol_core_e);
						$diss_nucRep_e = $conversion_factor*($sum_piece_nucRep_e - $mol_coeff*$mol_nucRep_e);
						$diss_coulomb_e = $conversion_factor*($sum_piece_coulomb_e - $mol_coeff*$mol_coulomb_e);
						$diss_exchange_e = $conversion_factor*($sum_piece_exchange_e - $mol_coeff*$mol_exchange_e);
						my $dev_err = $ref_diss_e - $diss_SCF_e; # error between the calculated and the reference
						print ALL_FILE "$mol_name $ref_diss_e $diss_SCF_e $dev_err $mol_diis $mol_weight $mol_SCF_e $diss_core_e $diss_nucRep_e $diss_coulomb_e $diss_exchange_e ";
						if($do_paramOptLSF == 1)
						{
							for(my $j=0; $j<$num_cols; $j++)
							{
								my $diss_optLSF = $conversion_factor*($sum_piece_optLSF[$j] - $mol_optLSF[$j]);
								print ALL_FILE "$diss_optLSF ";
							}
						}
						else
						{
							for(my $j=0; $j<$num_cols; $j++)
							{
								print ALL_FILE "0 ";
							}
						}
						print ALL_FILE "\n";

						# add to sum/total error
						$abs_dev_total = $abs_dev_total + $mol_weight*abs($dev_err);
						$abs_perc_dev_total = $abs_perc_dev_total + $mol_weight*abs($dev_err/$ref_diss_e);

						$all_mol_weighted_mad = $all_mol_weighted_mad + $mol_weight*abs($dev_err);
						$sumSqs = $sumSqs + $mol_weight*($dev_err**2);

						$mol_weight_total = $mol_weight_total + $mol_weight;
						$all_mol_weight_total = $all_mol_weight_total + $mol_weight;

						if(abs($dev_err) > abs($max_err))
						{
							$max_err = $dev_err;
							$max_molecule = $mol_name;
						}

						printf SET_ERROR "%-10s %8.4f %8.4f %8.4f    ",$mol_name,$ref_diss_e,$diss_SCF_e,$dev_err;
						# Print to deviation files
						if($converged == 0)
						{
							printf SET_ERROR "not_converged ";
						}
						else
						{
							printf SET_ERROR "converged ";
						}

						#100 is lowest == 0, 10 is lowest-cycle0 < diff_thres, 1 is lowest-last < consis_thres
						my $warn_code = $cycle0_flag + $inconsistent_flag + $diff_thres_flag; 
						print SET_ERROR "warning_$warn_str $diis_str\n";
					}
					if($set_key eq "atoms") # exception for atoms to be printed
					{
						printf SET_ERROR "%-10s %8.4f %8.4f %8.4f    ",$mol_name,0.0,$mol_SCF_e,0.0;
						if($converged == 0)
						{
							printf SET_ERROR "not_converged ";
						}
						else
						{
							printf SET_ERROR "converged ";
						}
						my $warn_code = $cycle0_flag + $inconsistent_flag + $diff_thres_flag; 
						print SET_ERROR "warning_code_$warn_code $mol_diis\n";
					}
				}
			}
		}
		if($set_key ne "atoms")
		{
			my $mad = $abs_dev_total/$mol_weight_total;
			$abs_perc_dev_total = $abs_perc_dev_total/$mol_weight_total;

			print SET_ERROR "             MAD      MAPD         (relative to Ref)\n";
			printf SET_ERROR "%-7s %10.5f %10.5f\n", "Calc",$mad,$abs_perc_dev_total;
			#tmp change for merged trunk. jk
			#printf SET_ERROR "%10s %10s %10.5f %10.5f\n", "SetMAD", $set_key,$mad,$abs_perc_dev_total;
			print SET_ERROR "\nConversion factor: $conversion_factor\n\n";
			close(SET_ERROR);
			close(MOL_LIST);

			# calcualte the full error of all sets
			$set_weighted_mad = $set_weighted_mad + $sets_weights{$set_key}*$mad;
			$set_weight_total = $set_weight_total + $sets_weights{$set_key}; # save the weight for normalization
			$full_str = "$full_str $set_key $mad $max_err $max_molecule";	# append to the string
		}

		# print the list_of_molecules
		`cat $lom $gen_path/scripts_configs/config$i/xcfunc.conf >> $gen_path/$set_key\_dev$i`;
	}
	$all_mol_weighted_mad = $all_mol_weighted_mad/$all_mol_weight_total;    # to get total weighted mad of all molecules
	#$sumSqs = $sumSqs/$all_mol_weight_total;   may be unnecessary
	print STAT_FILE "$full_stat_str $all_mol_weighted_mad $sumSqs\n";
	$set_weighted_mad = $set_weighted_mad/$set_weight_total;
	$full_str = "$full_str $set_weighted_mad\n";
	print ERR_FILE "$full_str";
	close(ALL_FILE);
	close(SCF_ANALYSIS);
}

close(STAT_FILE);
close(ERR_FILE);

