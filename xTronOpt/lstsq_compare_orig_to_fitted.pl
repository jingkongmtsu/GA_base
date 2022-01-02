#/bin/perl
# Prints out a statistics file that compares the original linear coefficients to
#  the theoretical stats from fitted linear coefficients and the actual calculated
#  results from those coefficients.
#
# Elaboration of command line arguments:
#  1. The original statistics file which contains the MAD and SumSqs for the original
#      linear parameters and the fitted linear coeffs. (lstsq_stats#.txt)
#  2. The file containing the results of calculations using the new/current linear coeffs (gen_stats.txt)
#  3. Which line of the results to compare with the original. (1, 2, 3, etc.)


use strict;
use warnings;

my ($orig_theoFitted_stats_file, $curr_stats_file, $set_num_for_curr);

my $num_args = $#ARGV + 1;
if($num_args == 3) 
{
	$orig_theoFitted_stats_file = $ARGV[0];
	$curr_stats_file = $ARGV[1];
	$set_num_for_curr = $ARGV[2];
	chomp($orig_theoFitted_stats_file);
	chomp($curr_stats_file);
	chomp($set_num_for_curr);
	
}
else
{
	die "lstsq_compare_orig_to_fitted.pl requires at least 3 parameters:\n1. The original statistics file 
2. The file with all the current statistics\n3. The number of which parameter set of current statistics\n";
}

my ($orig_gen_path, $curr_gen_path, $paramSet_num);
($orig_gen_path) = $orig_theoFitted_stats_file =~ m/(.*\/gen[0-9]+)\/.*/;
($curr_gen_path) = $curr_stats_file =~ m/(.*\/gen[0-9]+)\/.*/;

open CURR_STATS, "<$curr_stats_file" or die "Cannot open $curr_stats_file\n";
my $curr_stats;
for(my $i=0; $i<$set_num_for_curr; $i++)
{
	$curr_stats = <CURR_STATS>;
}
close(CURR_STATS);

open ORIG_STATS, "<$orig_theoFitted_stats_file" or die "Cannot open $orig_theoFitted_stats_file\n";
open COMPARE_STATS, ">$curr_gen_path/compare_stats_lstsq$set_num_for_curr.txt" or 
	die "Cannot open $curr_gen_path/compare_stats_lstsq$set_num_for_curr.txt\n";

for my $line (<ORIG_STATS>)
{
	print COMPARE_STATS "$line";
}
print COMPARE_STATS "fitted_calc $curr_stats";

close(COMPARE_STATS);
close(ORIG_STATS);




