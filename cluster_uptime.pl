#!/usr/bin/perl
#use strict;
#use warnings;

my $filename = "hosts";
my $fh;
my $host;
my $mycmd;
my $out;

open($fh, '<', $filename) or die "can't open file '$filename' $!";

while($host = <$fh>)
{
        chomp($host);
        $mycmd =  "ssh " . $host . " 'hostname && uptime'";
        $out = `$mycmd`;
        #$out = system($mycmd);
        print $out;
}

close($fh);

