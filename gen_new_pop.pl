#!/bin/perl
# This script generates a new population. It requires 3 or 4 parameters, two of which
#  are input parameters and 1 to specify the output. The 4th parameter is optional and
#  specifies the previous population and it's fitness/error. This is then used to do
#  the crossover step of a genetic algorithm.
# Cmd line args:
#	1. Population size
#	2. Parameter file
#	3. File to put the new population into
#	4. (Optional) Previous population file
# Output:
#	New population inside the (3.)

use strict;
use warnings;

my ($pop_size, $param_file, @para_min, @para_max, $pop_prev_file, $pop_new_file, @para_type);
my $gen_flag = 0; # 0 for completely new population, 1 for using a pre-existing population

my $num_args = $#ARGV + 1;
if($num_args == 3)
{
	print "You used 3 arguments, creating a new population\n";
	$gen_flag = 0;
	$pop_size = int($ARGV[0]);
	$param_file = $ARGV[1];
	$pop_new_file = $ARGV[2];
	chomp($pop_new_file);
}
elsif($num_args == 4)
{
	print "You used 4 arguments, creating a new population using previous population\n";
	$gen_flag = 1;
	$pop_size = int($ARGV[0]);
	$param_file = $ARGV[1];
	$pop_new_file = $ARGV[2];
	$pop_prev_file = $ARGV[3];
	chomp($pop_prev_file);
}
else
{
	die "\nERROR: Requires either 3 or 4 parameters:\n1. Initial population size\n2. Parameter file
3. File to store the new population\n(4. Previous population file to use for seeding)\n";
}
my $num_params = 0;

# Open the parameters file and read in the parameters into array
open PARAM_FILE, "<$param_file" or die "Can't open parameter file $param_file\n";
my $line = <PARAM_FILE>;
chomp($line);
$num_params = int($line);

for(my $i=0; $i<$num_params; $i++)
{
	$line = <PARAM_FILE>;
	my @params = split(" ", $line);
	# set the parameter bounds from the parameter input file
	$para_min[$i] = $params[0];
	$para_max[$i] = $params[1];
	if($params[2] =~ m/d/)
	{
		$para_type[$i] = $params[2];
	}
	elsif($params[2] =~ m/f/)
	{
		$para_type[$i] = $params[2];
	}
	else
	{
		die "Invalid parameter type\n";
	}
	
}
close(PARAM_FILE);


my $num_new = 1;
my $new_param_str = "";
# the parameters for the previous population and hash for the previous population as a string for easy searching
my (@prev_pop_params, %prev_params);
# opening the file for the new population
open NEW_POP, ">$pop_new_file" or die "Can't not open new population file $pop_new_file\n";

# If statement for using the previous population file for crossover
if($gen_flag == 1 and -e $pop_prev_file)
{
	open POP_FILE, "<$pop_prev_file" or die "Can't open previous population file: $pop_prev_file\n";
	
	my ($line, $i);
	my $total_pop = 0;
	# iterate over the file and store contents for crossover and duplicate checking
	foreach $line (<POP_FILE>)
	{
		chomp($line);
		if($line !~ /^#/)    # for comments
		{	
			my @param_line = split(" ", $line);
			my $tmp_num_params = @param_line; 
			if($tmp_num_params < $num_params+3)	# Error checking, +3 for gen number, iteration number, and error at least
			{
				die "Possible error in $pop_prev_file. Less parameters than number of parameters in $param_file: $num_params!\n";
			}
			if($total_pop < $pop_size)
			{
				# save the top population for crossover
				for(my $j=0; $j<$num_params; $j++)     # last column is error
				{
					$prev_pop_params[$total_pop][$j] = $param_line[$j+2]; # first and second column are gen number and iter number 
				}
			}
			# create a parameter line and add it to hash for easy searching
			my $param_line = join(" ", @param_line[2 .. $num_params+1]);
			if( exists $prev_params{$param_line} )
			{
				print "Possible error in $pop_prev_file, parameter set $param_line already exists!\n";
			}
			else
			{
				$prev_params{$param_line} = 0;
			}
			$total_pop = $total_pop + 1;
		}
	}
	
	close(POP_FILE);

	# Check to see if the total previous population is greater than 1 and 
	#  the required population size is greater than 1. Cannot do crossover otherwise.
	if($total_pop > 1 && $pop_size > 1) # cannot do crossover with 0 or 1 total population or population size 1 or less
	{
		# prev_pop_params now has the previous population. Compute the next generation
		# calculte the number of crossovers to be done
		my $numCross = &calcCrossNum($pop_size);
		print "Number of crossovers: $numCross\n";
		for(my $i=0; $i < $numCross; $i++)
		{
			# choose 2 random sets from population
			my $index1 = int($pop_size*rand());
			my $index2 = int($pop_size*rand());
			# check for duplication
			while($index1 == $index2)
			{
				$index2 = int($pop_size*rand());
			}
			# calculate which dimension to cross
			my $cross_dim = int(($num_params-1)*rand()) + 1;
			my $j;
			
			$new_param_str = "$prev_pop_params[$index1][0]";
			# do the crossover for first child
			for($j=1; $j<$cross_dim; $j++)
			{
				$new_param_str = "$new_param_str $prev_pop_params[$index1][$j]";
			}
			for($j=$cross_dim; $j<$num_params; $j++)
			{
				$new_param_str = "$new_param_str $prev_pop_params[$index2][$j]";
			}
			# figure out if first child already exists in searched space
			if(! exists $prev_params{$new_param_str})
			{
				print NEW_POP "$new_param_str\n";
				$prev_params{$new_param_str} = 0;
				$num_new++;
			}
			$new_param_str = "$prev_pop_params[$index2][0]";
			# do the crossover for second child
			for($j=1; $j<$cross_dim; $j++)
			{
				$new_param_str = "$new_param_str $prev_pop_params[$index2][$j]";
			}
			for($j=$cross_dim; $j<$num_params; $j++)
			{
				$new_param_str = "$new_param_str $prev_pop_params[$index1][$j]";
			}
			# figure out if second child already exists in searched space
			if(! exists $prev_params{$new_param_str})
			{
				print NEW_POP "$new_param_str\n";
				$prev_params{$new_param_str} = 0;
				$num_new++;
			}
		}

		# slight perturbation code:
		my $numPerturb = int(rand()*$pop_size/3.0) + 1;
		for(my $i=0; $i < $numPerturb; $i++)
		{
			#my $popPerturb = int(rand()*$pop_size);
			my $popPerturb = $i;
			my @temp_params;
			for(my $j=0; $j < $num_params; $j++)  # copy over the parameters
			{
				$temp_params[$j] = $prev_pop_params[$popPerturb][$j];
			}

			my $numParaShift = int(rand()*$num_params/2.0)+1; # shift from 1 to half of the parameters
			for(my $j=0; $j < $numParaShift; $j++)
			{
				my $paraShift = int($num_params*rand());
				# shift between -0.5 to 0.5 times range/10.0 around parameter
				my $shift_val = ($para_max[$paraShift]-$para_min[$paraShift])/10.0*(rand() - 0.5);
				$shift_val = int(sprintf("%.5f", $shift_val));
				if($temp_params[$paraShift] + $shift_val < $para_max[$paraShift] and $temp_params[$paraShift] + $shift_val > $para_min[$paraShift])
				{
					$temp_params[$paraShift] = $temp_params[$paraShift] + $shift_val;
				}
			}
			$new_param_str = "$temp_params[0]";
			for(my $j=1; $j < $num_params; $j++)
			{
				$new_param_str = "$new_param_str $temp_params[$j]";
			}
			if(! exists $prev_params{$new_param_str})
			{
				print NEW_POP "$new_param_str\n";
				$prev_params{$new_param_str} = 0;
				$num_new++;
			}
		}
	}
}
elsif($gen_flag == 1 and (! -e $pop_prev_file))
{
	print "$pop_prev_file does not exist! Cannot use previous population.\n";
}

#my $mutate_prob = 0.4;
while($num_new <= $pop_size)
{
###### For mutation - Kind of obsolete with way of doing crossover
#	my $prob = rand();
#	if($prob < $mutate_prob)
#	{
#		# calculate a new organism
#		for(my $j=0; $j<$num_params; $j++)
#		{
#			my $val = ($para_max[$j]-$para_min[$j])*rand() + $para_min[$j];
#			if($para_type[$j] =~ m/d/)
#			{
#				$val = int($val);
#			}
#
#			print NEW_POP "$val ";
#		}
#		print NEW_POP "\n";
#
#	}
###########
	my $val = ($para_max[0]-$para_min[0])*rand() + $para_min[0];
	$new_param_str = sprintf("%.5f", $val);
	# calculate a new organism
	for(my $j=1; $j<$num_params; $j++)
	{
		my $val = ($para_max[$j]-$para_min[$j])*rand() + $para_min[$j];
		if($para_type[$j] =~ m/d/)
		{
			$val = int($val);
		}
		if($para_type[$j] =~ m/f/)
		{
			$val = sprintf("%.5f", $val);
		}
		$new_param_str = "$new_param_str $val";
	}
	# figure out if randomly generated parameter set is a duplicate (low chance i know, just paranoid)
	if(! exists $prev_params{$new_param_str})
	{
		print NEW_POP "$new_param_str\n";
		$prev_params{$new_param_str} = 0;
		$num_new++;
	}
}


close(NEW_POP);
print "\nDone creating new population.\n";

# subroutine to calculate how many crossovers to do
# can change cross_rate for more or less crossovers
# smaller is more crossovers, larger is less
# follows an exponential curve rather than linear
sub calcCrossNum
{
	my $pop_size = shift;
	my $cross_rate = 3.0;   # 2.0 - comes out roughly a 4th

	my $random = rand();
	my $n = int($pop_size/$cross_rate*exp(-$random));
	return $n;
}

