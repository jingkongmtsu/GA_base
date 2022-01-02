import sys
import numpy
from numpy import *

# Assumes the first column is b and subsequent are A

def main():
	if (len(sys.argv) != 2):
		print "Requires values input file"
		exit()

	filename = sys.argv[1]

	infile = open(filename, 'r')

	#b = numpy.array([])
	#A = numpy.array([])
	b_list = []
	A_list = []

	
	for line in infile:
		linesplit = line.split()
		vals = [float(x) for x in linesplit[1:]]
		b_list.append(vals[0])
		A_list.append(vals[1:])
	b = numpy.array(b_list)
	A = numpy.array(A_list)

	AA = numpy.dot(numpy.transpose(A),A)
	Ab = numpy.dot(numpy.transpose(A),b)

	x = numpy.linalg.solve(AA, Ab)
	for i in x:
		print i,


main()
