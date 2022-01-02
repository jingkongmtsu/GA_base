#!/bin/bash

for x in `ls *.in`; do
   infile=$x
   outfile=`echo $infile | sed 's/\.in/\.log/'`
   cp $infile $outfile
done
