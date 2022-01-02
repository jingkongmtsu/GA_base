import sys
import subprocess
from operator import itemgetter
import p

#
#get the current directory name without parent dirs.
def crntdir():
	rv = ''
	pp = subprocess.Popen('pwd', shell=True, stdout=subprocess.PIPE)
	for line in pp.stdout.readlines():
		rv = line.rstrip().split('/')[-1]
	return str(rv)

#read in the set, mol, and .
def read_moldata(fname) :
	lines_mtag = []
	iter0 = 1000000
	with open(fname) as f:
		for line in f:
			words = line.split()
			if (len(words) > 0 and words[p.POS_TAG] == 'MTAG'):
				 if words[p.POS_FUNC] == p.XCFUNC: 
					if (int(words[p.POS_ITER]) <= iter0):  #initialize
						lines_mtag = []
						iter0 = int(words[p.POS_ITER])
					lines_mtag.append(words)
		if len(lines_mtag) == 0:
			print "No MTAG or p.XCFUNC contained in", fname

def main() :
	with open(p.molsets_fname) as sets_f:  #loop over sets.
		for set_line in sets_f:
			set_name = (set_line.split())[0]
			if ( set_name[0] == '*' ) : continue  #set skipped
			#print ('{0:>30}{1:>10}{2:>10}{3:>10}'.format('Mol', 'ref', 'calc', 'dev'))
			with open(set_name + '/' + p.lom_fname) as lom_f:  #loop over lom to find formulas
				for mol_line in lom_f:
					words = (mol_line.rstrip()).split()
					if ( words[0][0] == '*') : continue #skip 
					mol = words[0]
					fmolout = set_name + '/' + mol + p.qm_postfix + '.out'
					read_moldata(fmolout)
	

if __name__ == '__main__':
	main()

