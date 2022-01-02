#!/bin/bash

dup_lines=$(cat atoms/list_of_atoms diatomics/list_of_molecules polyatomics/list_of_molecules | sort -k 1 | uniq -d)
if [[ $dup_lines ]]
then
	echo "Duplicate lines found: $dup_lines"
else
	echo "No duplicates found"
fi
