#!/bin/bash

subset='RSE43'  #subset = 'dd' won't work
outdir="GM55-$subset"
lom="$outdir/list_of_molecules.current"
cmfile=CHARGE_MULTIPLICITY_"$subset".txt

declare -A cm   #number indexed array. String index seems impossible.
declare -A cm_mol 
i=0
while read aline; do  #reading lines from a file.
	#mol=`cut -d' ' -f1 <<< $aline`   #chopping a line.
	cm_mol[$i]=`cut -d' ' -f1 <<< $aline`  #add a new element.
	charge=`cut -d' ' -f2 <<< $aline`
	multip=`cut -d' ' -f3 <<< $aline`
	cm[$i]="$charge $multip   "   #changing an array element 
	#echo $mol $charge $multip
	((i++))
done < $cmfile

#for loop with a string index from a command output and use of a varible.
rm -f $lom
i=0
for mol in `find $subset -maxdepth 1 -type d -exec basename {} \; |grep -v $subset | sort`; do
	if [[ ${cm_mol[$i]} != $mol ]] ; then
		echo charge/multiplicity and struc not match  ${cm_mol[$i]}  $mol
		exit
	fi
	echo $mol 0 >> $lom
	#get the content of an array element.  '>' overrites.
	in_file="$outdir/${mol}.in"    #single quote does not work.
	echo "%molecule" >  $in_file
	echo ${cm[$i]} >> $in_file 
	# starting from line 3. '>>' appends.
	tail -n +3 $subset/$mol/struc.xyz >> $in_file
	echo "%end" >> $in_file	
	((i++))
done

