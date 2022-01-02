import sys

#Translate a excel sheet two columns for constructing input files.

with open('scf_kp14_144.txt') as f:
	for line in f:
		newline = line.rstrip('\n')
		words = newline.split('\t')
		#print words
		for word in words:
			sys.stdout.write(word)
			sys.stdout.write(' ')

		sys.stdout.write('\n')

		#for word in words:
		#	sys.stdout.write(word)
		#	sys.stdout.write(' ')
