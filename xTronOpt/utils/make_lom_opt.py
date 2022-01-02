import sys
from operator import itemgetter

#input varilables.
energies_fname = 'b13s_g3l.sorted_yu_combo8'
lom_in_f = 'list_of_molecules.current'
lom_out_f = 'list_of_molecules.b13s.opt'
sets_fname = 'sets_list.txt'
POS_OPT = 2

#read in the set, mol, and min energy.
def read_mols(fname) :
	rv = {}
	with open(fname) as f:
		for line in f:
			if (line[0] == '*'): continue   #skip
			words = line.split()
			if ( words[0] not in rv ):
				rv[words[0]] = {}
			rv[words[0]][words[1]] = words[POS_OPT]
			#print words[0], words[1], rv[words[0]][words[1]]
	return rv

###
# print a dict of dict
#def printdd(dd, fname):
#	f = open(fname, 'w')
#	for x in dd:
#		for y in x:
#			item = ''.join([str(z) for z in dd[x][y])
#		
#
#            f.write(str(item)+' ')
#        f.write('\n')

def main() :
	#read in the opt combo for each set/molecule
	mols = read_mols(energies_fname)
	with open(sets_fname) as sets_f:  #loop over sets.
		for set_line in sets_f:
			set_name = (set_line.split())[0]
			if ( set_name[0] == '*' ) : continue  #set skipped
			if ( set_name not in mols ) :
				print 'set ', set_name, ' not found in', energies_fname
				sys.exit()
			with open(set_name + '/' + lom_in_f) as lom_in:  #loop over lom to find formulas
				lom_out = open(set_name + '/' + lom_out_f, 'w')
				for mol_line in lom_in:
					if ( mol_line[0] == '*' ) : continue #skip 
					words = (mol_line.rstrip()).split()
					mol = words[0]
					if ( mol not in mols[set_name] ) :
						print 'molecule and set', mol, set_name, ' not found in energies file'
						sys.exit()
					combo = mols[set_name][mol].split('_')
					scf_alg = combo[0]
					xcfunc1 = combo[1]
					if ( xcfunc1 == 'lda' ): xcfunc1 = 'slater'
					line_out = '  xcfunc1 ' + xcfunc1 + '  scf_algorithm ' + scf_alg
					print >> lom_out, mol_line.rstrip() + line_out
				lom_out.close() 
	

if __name__ == '__main__':
	main()

#		nums =hh []
#		for i in range(3,7):
#			print "i = ", i
#			nums.append(float(words[i]))
#		x[words[1]] = nums
#print x
#sort a list of lists.  y is actually a sorted keys only.  But
#good enough to get the needed info from the original list.
#y = sorted(x, key = itemgetter(2)) 
#print "sorted keys ", y
#print x[y[0]]
