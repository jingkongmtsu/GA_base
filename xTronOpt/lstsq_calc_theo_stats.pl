#/bin/perl
# Prints out a statistics file that compares the original linear coefficients to
#  the new stats using fitted linear coefficients from least square fitting.
#
# Requires 3 parameters:
#  1. File with necessary values (all_values#.txt)
#  2. File with the stats of original coefficients (gen_stats.txt)
#  3. File with least squares fitted coefficients (lstsq_fitted_coeffs#.txt/lstsq_coeffs#.txt)

use strict;
use warnings;

my ($all_values_file, $lstsq_coeffs_file, $orig_stats_file, $stats_output_file);
my $num_args = $#ARGV + 1;
if($num_args == 3) 
{
	$all_values_file = $ARGV[0];
	$orig_stats_file = $ARGV[1];
	$lstsq_coeffs_file = $ARGV[2];
	chomp($all_values_file);
	chomp($orig_stats_file);
	chomp($lstsq_coeffs_file);
}
else
{
	die "lstsq_calc_theo_stats.pl requires at least 3 parameters:\n1. File with all necessary values
2. File with statistics of original coefficients\n3. Least squares fitted coeffs file\n";
}

my ($output_path, $set_num);
$output_path = "";
# Assumes $all_values_file is of the format /path/to/file/filename#.txt
#  with the number being the id and no other numbers following it
if($all_values_file =~ m/\//)
{
	($output_path, $set_num) = $all_values_file =~ m/(.*)\/.*?([0-9]+)/;
}
else
{
	($set_num) = $all_values_file =~ m/([0-9]+)/;
}
# Set the name for the output file of the statistics for the orig and lstsq theoretical fitted coeffs
$stats_output_file = "$output_path/lstsq_stats$set_num.txt";

# Read in the fitted coeffs
open FITTED_COEFFS, "<$lstsq_coeffs_file", or die "Cannot open $lstsq_coeffs_file\n";
my $line = <FITTED_COEFFS>;
my @lstsq_coeffs = split(' ', $line);
close(FITTED_COEFFS);

my ($mad, $sumSqs, $mol_weight_total);
$mad = $sumSqs = $mol_weight_total = 0;

# Loop through and calculate stats with fitted coeffs
open ALL_VALUES, "<$all_values_file" or die "Cannot open $all_values_file\n";
for $line (<ALL_VALUES>)
{
	if(!($line =~ m/#/))
	{
		my @line_split = split(' ', $line);

		my $dev = $line_split[1] - ($line_split[7] + $line_split[8] + $line_split[9] + $line_split[10] + 
			$line_split[11] + $lstsq_coeffs[0]*$line_split[12] + $lstsq_coeffs[1]*$line_split[13] + 
			$lstsq_coeffs[2]*$line_split[14]);

		#for the 1 parameter, first parameter case.
	#	my $dev = $line_split[1] - ($line_split[7] + $line_split[8] + $line_split[9] + $line_split[10] + 
	#		$line_split[11] + $lstsq_coeffs[0]*$line_split[12] + $line_split[13] + $line_split[14]);

		$mol_weight_total = $mol_weight_total + $line_split[5];
		$mad = $mad + $line_split[5]*abs($dev);
		$sumSqs = $sumSqs + ($line_split[5]*$dev)**2;
	}
}
close(ALL_VALUES);

$mad = $mad/$mol_weight_total;

# open the orig coeffs and statistics file
open ORIG_FILE, "<$orig_stats_file" or die "Cannot open $orig_stats_file\n";
for(my $i=0; $i<$set_num; $i++)
{
	$line = <ORIG_FILE>;
}
close(ORIG_FILE);

my @line_split = split(" ", $line);

# write it to the output file
open STATS_FILE, ">$stats_output_file", or die "Cannot open $stats_output_file\n";
print STATS_FILE "orig  $line";
print STATS_FILE "fitted_theo  $line_split[0]  $line_split[1]  $line_split[2]  $line_split[3]  $lstsq_coeffs[0]  $lstsq_coeffs[1]  $lstsq_coeffs[2]  $mad  $sumSqs\n";
close(STATS_FILE);


