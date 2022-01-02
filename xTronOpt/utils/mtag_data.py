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
def read_moldata_xtron(fname) :
	lines_mtag = []
	iter0 = 1000000
	with open(fname) as f:
		for line in f:
			words = line.split()
			if (len(words) > 0 and words[p.POS_TAG] == 'MTAG'):
				 if words[p.POS_FUNC] == p.XCFUNC: 
					if (int(words[p.POS_ITER]) <= iter0):  #initialize or restart
						lines_mtag = []
						iter0 = int(words[p.POS_ITER])
					lines_mtag.append(words)
	if len(lines_mtag) == 0:                         #there is nothing for this functional.
		print "No MTAG contained in", fname
		words = p.empty_line_mtag
		iter0 = int(words[p.POS_ITER])
		lines_mtag.append(words)
	#print lines_mtag
	energy_first = lines_mtag[0][p.POS_ENERGY_MTAG]
	energy_last = lines_mtag[-1][p.POS_ENERGY_MTAG]
	iter_lowest = int(lines_mtag[-1][p.POS_ITER_LOWEST]) - iter0  #the lowest iter relative to start.
	if ((iter_lowest + iter0) != int(lines_mtag[iter_lowest][p.POS_ITER])):   #sanity check
		print 'iter_lowest not consistent'
		exit()
	energy_lowest = lines_mtag[iter_lowest][p.POS_ENERGY_MTAG] 
	diis_last = lines_mtag[-1][p.POS_DIIS]
	diis_lowest = lines_mtag[iter_lowest][p.POS_DIIS]
	warn = 0
	if ((float(energy_last) - float(energy_lowest))) > p.consist_thresh: warn = warn + 1
	if ((float(energy_first) - float(energy_lowest))) < p.diff_thresh: warn = warn + 10
	if (iter_lowest == 0): warn = warn + 100
	rv = []
	rv.append(str(warn))       # rv[0]
	rv.append(energy_first)    # rv[1]
	rv.append(energy_last)     # rv[2]
	rv.append(energy_lowest)   # rv[3]
	rv.append(diis_last)       # rv[4]
	rv.append(diis_lowest)     # rv[5]

	nstay = 0
	nstay_max = 0
	iter_lowest_last = -1
	for i in range(0, iter_lowest):
		if ( lines_mtag[i][p.POS_ITER_LOWEST] == iter_lowest_last ):
			nstay = nstay + 1
			if nstay > nstay_max : nstay_max = nstay
		else:
			iter_lowest_last = lines_mtag[i][p.POS_ITER_LOWEST]
			nstay = 0
	
	rv.append(str(nstay_max))
	return rv

def xtron(fout):
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
					moldata = read_moldata_xtron(fmolout)
					print >> fout, set_name, mol, ' '.join([x for x in moldata])
	fout.close()

def gauss(fout):
	with open(p.qprogoutput) as qout: 
		for line in qout:
			fields = (line.split())
			#print fields
			f0split = fields[0].split('.')[1].split('/')
			set_name = f0split[2]
			mol = f0split[3]
			energy_first = '0'
			energy_last = fields[p.POS_ENERGY_MTAG] 
			energy_lowest = energy_last
			try:
				diis_lowest = fields[p.POS_DIIS]
			except IndexError:
				diis_lowest = '111'
			diis_lowest = diis_lowest.replace('D', 'E')  #1D-8 is changed to 1E-8.
			diis_last = diis_lowest
			warn = 0
			nstay = 0
			print >> fout, set_name, mol, warn, energy_first, energy_last, energy_lowest, diis_last, diis_lowest, nstay
#	fout.close()
	
def main() :
	qprog = {'xtron': xtron, 'gauss': gauss}
	fout = open(crntdir() + '.txt' + p.fout_ext, 'w')
	qprog[p.qprog](fout)


if __name__ == '__main__':
	main()

