#!/usr/bin/perl

use strict;
use warnings;
use threads;
use threads::shared;

my ($scripts_dir, $line);
my $num_args = $#ARGV + 1;
if($num_args == 1)
{
	$scripts_dir = $ARGV[0];
	chomp($scripts_dir);
	if( ! -d $scripts_dir or ! -e "$scripts_dir/commands" )
	{
		die "Error in _, directory $scripts_dir does not exist or $scripts_dir/commands";
	}
}
else
{
	die "Error in _, requires command line arg of path to directory with commands and other necessary files";
}

#if( -e "$scripts_dir/header.sh" )
#{
#	`$scripts_dir/header.sh`;
#}
my @hostnames;
if( -e "hostnames" )
{
	open HOSTS, "< hostnames" or die "Cannot open hostsnames\n";
	for $line (<HOSTS>)
	{
		chomp($line);
		push(@hostnames, $line);
	}
	close(HOSTS);
}
else
{
	die "No hostnames file";
}

my $num_hosts = @hostnames;

my (@cmds, $index, $num_cmds) :shared;
$index = 0;
open CMDS, "< $scripts_dir/commands" or die "Cannot open $scripts_dir/commands\n";
for $line (<CMDS>)
{
	chomp($line);
	push(@cmds, $line);
}
close(CMDS);
$num_cmds = @cmds;

open CMDS_DONE, "> $scripts_dir/commands_done" or die "Cannot open $scripts_dir/commands_done\n";
open CMDS_SUBMITTED, "> $scripts_dir/commands_submitted" or die "Cannot open $scripts_dir/commands_submitted\n";

my ($t, @thrds);
for(my $i=0; $i<$num_hosts; $i++)
{
	$t = threads->new(\&execute_command, $i, $hostnames[$i]);
	push(@thrds, $t);
}
print "Created threads successfully\n";
foreach(@thrds)
{
	my $num = $_->join;
	print "Done with thread $num\n";
}
close(CMDS_DONE);
close(CMDS_SUBMITTED);


sub execute_command
{
	my $thrdid = $_[0];
	my $my_host = $_[1];
	my ($cmd, $my_index, $stdout, $start, $end, $diff);
	while($index < $num_cmds)
	{
		{
		lock($index);
		$my_index = $index;
		$cmd = $cmds[$index];
		$index++;
		}

		my $line_done = $my_index + 1;

		$start = time();
		print CMDS_SUBMITTED "$line_done  $my_host  $cmd\n";

		$stdout = `ssh $my_host '$cmd'`;

#		if( -e "$scripts_dir/header.sh" )
#		{
#			$stdout = `ssh $my_host 'source $scripts_dir/header.sh; $cmd'`;
#		}
#		else
#		{
#			$stdout = `ssh $my_host '$cmd'`;
#		}
		$end = time();
		print "$stdout , $my_host , $cmd\n";
		$diff = $end - $start;
		print CMDS_DONE "$line_done  $diff  $my_host\n";
	}
	return $my_host;
}
