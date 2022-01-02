#!/usr/bin/perl
use strict; 
my $a2k=627.5095;

# Hash of reference atomization energies , "Ref1" with spin-orbit coupling subtracted off 
my %ref=(
'CH'=>84.23,
'CH2_3B1'=>190.75,
'CH2_1A1'=>181.46,
'CH3'=>307.88,
'CH4'=>420.43,
'NH'=>83.1,
'NH2'=>182.59,
'NH3'=>298.02,
'OH'=>107.22,
'H2O'=>232.98,
'HF'=>141.63,
'SiH2_1A1'=>152.22,
'SiH2_3B1'=>131.48,
'SiH3'=>228.01,
'SiH4'=>324.95,
'PH2'=>153.2,
'PH3'=>242.27,
'H2S'=>183.91,
'HCl'=>107.5,
'C2H2'=>405.53,
'C2H4'=>563.69,
'C2H6'=>712.98,
'CN'=>181.36,
'HCN'=>313.43,
'CO'=>259.74,
'HCO'=>279.43,
'H2CO'=>374.67,
'CH3OH'=>513.54,
'N2'=>228.48,
'NH2NH2'=>438.6,
'NO'=>152.75,
'O2'=>120.83,
'H2O2'=>269.03,
'F2'=>39.03,
'CO2'=>390.16,
'Si2'=>76.38,
'P2'=>117.59,
'S2'=>104.25,
'Cl2'=>59.75,
'SiO'=>193.06,
'SC'=>171.76,
'SO'=>126.48,
'ClO'=>65.45,
'ClF'=>62.79,
'Si2H6'=>535.89,
'CH3Cl'=>396.44,
'CH3SH'=>474.49,
'HOCl'=>166.24,
'SO2'=>260.63,
'AlCl3'=>312.64,
'AlF3'=>430.95,
'BCl3'=>325.45,
'BF3'=>470.96,
'C2Cl4'=>469.82,
'C2F4'=>591.06,
'C3H4_pro'=>705.06,
'C4H4O'=>994.33,
'C4H4S'=>963.65,
'C4H5N'=>1071.93,
'C4H6_tra'=>1012.73,
'C4H6_yne'=>1004.49,
'C5H5N'=>1238.14,
'CCH'=>265.31,
'CCl4'=>316.19,
'CF3CN'=>641.17,
'CF4'=>477.93,
'CH2OH'=>410.08,
'CH3CN'=>616.02,
'CH3NH2'=>582.31,
'CH3NO2'=>601.82,
'CHCl3'=>345.79,
'CHF3'=>458.73,
'ClF3'=>127.31,
'H2'=>109.49,
'CH2CH'=>446.09,
'HCOOCH3'=>785.9,
'HCOOH'=>501.53,
'NF3'=>205.67,
'PF3'=>365.01,
'SH'=>87,
'SiCl4'=>388.73,
'SiF4'=>576.3,
'C2H5'=>603.93,
'C4H6_bic'=>987.56,
'C4H6_cyc'=>1001.97,
'HCOCOH'=>633.99,
'CH3CHO'=>677.44,
'C2H4O'=>651.11,
'C2H5O'=>699.05,
'CH3OCH3'=>798.46,
'CH3CH2OH'=>810.77,
'C3H4_all'=>703.47,
'C3H4_cyc'=>683.01,
'CH3COOH'=>803.68,
'CH3COCH3'=>978.46,
'C3H6'=>853.68,
'CH3CHCH2'=>860.88,
'C3H8'=>1007.14,
'C2H5OCH3'=>1095.62,
'C4H10_iso'=>1303.4,
'C4H10_anti'=>1301.68,
'C4H8_cyc'=>1149.37,
'C4H8_iso'=>1158.97,
'C5H8_spi'=>1284.73,
'C6H6'=>1368.1,
'CH3CO'=>581.99,
'CH3CHCH3'=>901.02,
'C4H9_t'=>1199.7,
'CH2CO'=>532.73
);

#jk
foreach my $key (keys %ref) { print sprintf("%12s %12.2f\n", $key, $ref{$key}); }

# Read all energies 
my %Es=(); my $NEs=0;
foreach my $f (<*log>){
	my $tag=$f;$tag=~s/.log//;chomp($tag);
	#my @temp=split(/ +/,`grep "SCF Done" $f|awk "{print \\\$5}" |tr "\n" " "`);
	#$Es{$tag}=\@temp;
	$Es{$tag}=0;
	#$NEs=scalar(@temp);
	$NEs=1;
}

# Assemble atomization energies and errros 
my @DEerrs=0.0x$NEs;
my @DEabs=0.0x$NEs;
my @DErms=0.0x$NEs;
#print "Molecule CalcType DEref DE Stoichiometry \n";
while(my ($name,$DEref) = each(%ref)){ 

	print sprintf("%12s ",$name);
	# Evaluate stoichiometry 
	my $sst = $name;$sst=~s/_.*//; 
	my @ss=split(/(?=[A-Z])/,$sst);
	#print "@ss";
	my @ats=(); 

	my %numElems=();

	#print "@ss";
	#print printf("  size of ss %3d ", scalar(@ss));

	foreach my $a(@ss){
		#print sprintf("%12s ",$a);
		if($a=~m/[0-9]+/){
			my $aa=$a;$aa=~s/[0-9]+//; 
			#print sprintf("aa=%3s ",$aa);
			my $an=$a;$an=~s/[a-zA-Z]+//; 
			#print sprintf("an=%3d ",$an);
			$numElems{$aa}=$numElems{$aa}+$an;
			foreach my $i(1..$an){push(@ats,$aa);}
		}
		else{$numElems{$a}=$numElems{$a}+1; push(@ats,$a);}
	}

	my @ky = keys %numElems;
	my $kysize = @ky;
	#jk
	print "$kysize 1 1";
	foreach my $key (keys %numElems) { print sprintf(" %1d %1s", $numElems{$key}, $key); }

	#print "@ats";
	foreach my $iE(0..$NEs-1){
#my @temp=@{$Es{$name} }; 
#		my $DE=-$temp[$iE];
		foreach my $a(@ats){
			#	my @temp=@{$Es{$a} }; 
			#$DE+=$temp[$iE];
			#		print sprintf("%3d ",$a);
		}
		#jk
		print "\n";
		#		$DE *=$a2k;
		#		print sprintf("%12s %3d %9.2f %9.2f %9.2f ",$name,$iE,$DEref,$DE,abs($DEref-$DE));
		#foreach my $a(@ats){print "$a ";}
		#print "\n";
		#$DEerrs[$iE] += $DE-$DEref;
		#$DEabs[$iE] += abs($DE-$DEref);
		#$DErms[$iE] += ($DE-$DEref)**2.
	}
}

# Summary output
#print "# CalcType  ME MAE RMSD \n";
#foreach my $iE(0..$NEs-1){print sprintf("%2d %7.1f %7.1f %7.1f \n",$iE,$DEerrs[$iE]/109.,$DEabs[$iE]/109.,($DErms[$iE]/109.)**0.5);}
