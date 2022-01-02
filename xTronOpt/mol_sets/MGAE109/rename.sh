#!/bin/bash

for x in `ls *.com`; do
   infile=$x
   outfile=`echo $infile | sed 's/\.com/\.in/'`
   cp $infile $outfile
done
