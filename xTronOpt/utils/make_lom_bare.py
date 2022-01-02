import sys

#Translate a excel sheet two columns for constructing input files.

with open('kp14_allsets_184_list.txt') as f:
	for line in f:
		newline = line.rstrip('\n')
		words = newline.split('\t')
		sys.stdout.write(words[1])
		sys.stdout.write(' 0\n')

		#for word in words:
		#	sys.stdout.write(word)
		#	sys.stdout.write(' ')
