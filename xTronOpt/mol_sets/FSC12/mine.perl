#!/usr/bin/perl
use strict;
my $head="%mem=4GB\n%nprocshared=4\n";
my $meth0="def2TZVP SCF(Fermi,XQC) \n";
my %mon=(
'H'=>"H 0.0 0.0 0.0\n",
'Li'=>"Li 0.0 0.0 0.0\n",
'Na'=>"Na 0.0 0.0 0.0\n",
'K'=>"K 0.0 0.0 0.0\n",
#'Ag'=>"Ag 0.0 0.0 0.0\n",
#'Au'=>"Au 0.0 0.0 0.0\n",
#'F'=>"F 0.0 0.0 0.0\n",
#'Cl'=>"Cl 0.0 0.0 0.0\n",
#'Br'=>"Br 0.0 0.0 0.0\n",
'CH3'=>" 6 0.000000    0.000000  0.000000
1 0.000000    1.079115  0.000000
1 0.934541   -0.539558  0.000000
1 -0.934541   -0.539558  0.000000  \n",
'SiH3'=>" 1 0.000000    1.466844    0.000000
1 -1.270325   -0.733422    0.000000
1 1.270325   -0.733422    0.000000
14 0.000000    0.000000    0.000000 \n",
'NH2'=>" 1 0.806201   -0.496504   0.000000
1 -0.806201   -0.496504   0.000000
7 0.000000    0.141858   0.000000 \n",
'PH2'=>" 1 -1.021700   -0.874470 0.000000
1 1.021700   -0.874470 0.000000
15 0.000000    0.116596 0.000000    \n",
'OH'=>"1 0.000000   -0.868203   0.000000
8 0.000000    0.108525   0.000000 \n",
'SH'=>"1 0.000000   -1.267835 0.000000
16   0.000000    0.079240 0.000000   \n",
);
my %meths=(
'HF'=>"#P HF",
);


while(my($mt,$meth)=each(%meths)){
while(my($gt,$geom)=each(%mon)){
        my $name="$gt";
        open F, ">$name-m.in";
        print F "%molecule\n";
        print F "0 2\n$geom";
        print F "%end\n";
        close(F);
        open F, ">$name-mp.in";
        print F "%molecule\n";
        print F "1 1\n$geom";
        print F "%end\n";
        close(F);
        open F, ">$name-mpt.in";
        print F "%molecule\n";
        print F "1 3\n$geom";
        print F "%end\n";
        close(F);
        my $geom2="";
        foreach my $line(split(/\n/,$geom)){
                $line=~s/^ *//;
                my ($at,$x,$y,$z)=split(/ +/,$line);
                $geom2=$geom2.sprintf("%4s %12.6f %12.6f %12.6f \n",$at,$x,$y,$z+1000.);
        }
        open F, ">$name-d.in";
        print F "%molecule\n";
        print F "0 1\n$geom$geom2";
        print F "%end\n";
        close(F);
        open F, ">$name-dp.in";
        print F "%molecule\n";
        print F "1 2\n$geom$geom2";
        print F "%end\n";
        close(F);
				print "$name-m 0\n";
				print "$name-mp 0\n";
				print "$name-mpt 0\n";
				print "$name-d 0\n";
				print "$name-dp 0\n";
}}


