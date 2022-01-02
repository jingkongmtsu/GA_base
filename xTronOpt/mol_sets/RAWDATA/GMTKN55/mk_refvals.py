import sys
from operator import itemgetter

#GMTKN is in kcal/mol. GAbase is in a.u.
unit_conv = 627.503
refs_file = "formulas.RSE43"
def main():
	print "xxx"
	coefs = {}
	refs = {}
	with open(refs_file) as ref_f:
		for line in ref_f:
			words = line.split()
			npc = (len(words) - 2)/2
			rnum = words[0]
			refs[rnum] = float(words[-1])/unit_conv
			coefs[rnum] = {}
			for ipc in range (0, npc):
				mol = words[ipc+1]
				coefs[rnum][mol] = float(words[npc+ipc+1])
	for rnum in refs :
		#print rnum, coefs[rnum], refs[rnum]
		print rnum, refs[rnum]

if __name__ == "__main__" :
	main()

