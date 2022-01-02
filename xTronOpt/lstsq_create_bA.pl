#/bin/perl


use strict;
use warnings;

my $all_values_file;
my $num_args = $#ARGV + 1;
if($num_args == 1)
{
	$all_values_file = $ARGV[0];
	chomp($all_values_file);
}
else
{
	die "lstsq_create_bA.pl requires the path and filename of all the values used to calculate A and b.\n";
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

open ALL_VALUES, "<$all_values_file" or die "Cannot open $all_values_file\n";
open LSTSQ_Ab, ">$output_path/lstsq_Ab$set_num.txt" or die "Cannot open $output_path/lstsq_Ab$set_num.txt\n";

for my $line (<ALL_VALUES>)
{
	if(!($line =~ m/#/))
	{
		my @line_split = split(' ', $line);
		my $b = $line_split[1] - ($line_split[7] + $line_split[8] + $line_split[9] + $line_split[10] + $line_split[11]);
		#for the 1 parameter, first parameter case.
	#	my $b = $line_split[1] - ($line_split[7] + $line_split[8] + $line_split[9] + $line_split[10] + $line_split[11] + $line_split[12] + $line_split[14] + $line_split[15]);
		$b = $line_split[5]*$b; # apply the weight

		my $A1 = $line_split[5]*$line_split[12];
		my $A2 = $line_split[5]*$line_split[13];
		my $A3 = $line_split[5]*$line_split[14];

		print LSTSQ_Ab "$line_split[0] $b $A1 $A2 $A3\n";
	}
}

close(LSTSQ_Ab);
close(ALL_VALUES);

# run python script here? yeah probably.
