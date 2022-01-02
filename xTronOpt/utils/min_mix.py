import sys
from operator import itemgetter
import p

#Find the mininum of minimum energies of different
#sets and sort them by diis error.  Can be easily
#modifed to do other searching and sorting.

###
# print a list
def printalist(alist, fname):
    f = open(fname, 'w')
    for x in alist: 
        for item in x:
            f.write(str(item)+' ')
        f.write('\n')

###
#get minima based on 2 criteria. 
def minima_l2(some_dict, diff_thresh):
	positions = [] # output variable
	min_value0 = float("inf")
	min_value1 = float("inf")
	for k in some_dict:
		v0 = some_dict[k][0]
		v1 = some_dict[k][1]
		if (abs(v0 - min_value0) <= diff_thresh): #about equal
			if ( v1 < min_value1 ): #takes smaller 2nd criterion.
				min_value0 = v0
				min_value1 = v1
				positions.insert(0, k)  #the head of the list.
			else:
				positions.append(k)
		if v0 < (min_value0 - diff_thresh):  #a new low
			min_value0 = v0
			min_value1 = v1
			positions = [] # reset
			positions.append(k)

	return positions

### Unused
#get minima from a dict list.
def minima_l(some_dict, diff_thresh):
	positions = [] # output variable
	min_value = float("inf")
	for k in some_dict:
		v = some_dict[k]
		if (abs(v-min_value) <= diff_thresh):
			positions.append(k)
			min_value = min(v, min_value)
		if v < (min_value - diff_thresh):
			min_value = v
			positions = [] # output variable
			positions.append(k)

	return min_value, positions

### Unused
#get minima from a dict list of lists.
def minima_ll(some_dict, elm, diff_thresh):
	positions = [] # output variable
	min_value = float("inf")
	for k in some_dict:
		v = some_dict[k][elm]
		if (abs(v-min_value) <= diff_thresh):
			positions.append(k)
			min_value = min(v, min_value)
		if v < (min_value - diff_thresh):
			min_value = v
			positions = [] # output variable
			positions.append(k)

	return min_value, positions

###
#Read from a file a list of energies, and put them in a dict
#list of number lists. start from the warning code.
def read_energies(fname):
	rv = {}
	with open(fname) as f:
		for line in f:
			newline = line.rstrip()
			words = newline.split()
			if ( len(words) != 9 ) : 
				print 'Incorrect number of fields in file', fname, ' in line \n', newline
				sys.exit()
			molset = words[0]
			if ( molset not in rv ): rv[molset] = {}
			num = []
			num.append(int(words[2]))   #warning code
			for i in range(3,7):        #0th, final and min energies.
				num.append(float(words[i]))
			mol = words[1]
			if mol in rv[molset]:
				print 'Mol', mol, 'is duplicated in set', molset
				sys.exit()
			rv[molset][mol] = num
	return rv

###
def main():
	pos_sort = p.POS_MIX_SORT;
	pos_min = p.POS_MIX_MIN; 
	output = p.scfset_common + 'mix'
	moldata = {}  #all the data together, indexd by scfset and molecule.
	for scfset in p.scfset_names:
		scfset_fullname = p.scfset_common + scfset
		scfset_file = '../' + scfset_fullname + '/' + scfset_fullname + '_post.txt' 
		moldata[scfset] = read_energies(scfset_file)
	#data for mixed case only to be printed out for comparison. indexed by mol.
	#moldata_mix = read_energies('kp14_allsets_g3l_mix_b3lyp_post.txt')
	energies_unsorted = []
	with open(p.molsets_fname) as sets_f:
		for set_line in sets_f:
			molset = (set_line.split())[0]
			if ( molset[0] == '*') :
				print 'SKIP: set', molset
				continue  #set skipped
			with open(p.refs_dir + '/' + molset + '/' + p.lom_fname) as lom_f:
				for mol_line in lom_f:
					mol = (mol_line.rstrip()).split()[0]
					if ( mol[0] == '*') :
						print 'SKIP: mol ', molset + '/' + mol
						continue
					min_energies = {}               #min energy and diis error for sorting.
					min_line_out = []               #print out for this mol.
					for scfset in p.scfset_names: 
						min_energies[scfset] = []
						if (molset in moldata[scfset]) and (mol in moldata[scfset][molset]) : 
							min_energies[scfset].append(moldata[scfset][molset][mol][pos_min])
							min_energies[scfset].append(moldata[scfset][molset][mol][pos_sort])
						else:
							print 'ERROR: set', molset, 'molecule ', mol, 'is missing in post set', scfset
							sys.exit()
						#append the data from all scfsets to the end.
						min_line_out.append('|' + scfset)
						min_line_out.append(moldata[scfset][molset][mol][0])  #the code
						min_line_out.extend(min_energies[scfset])     #min energy and diis error.
						min_scfsets = minima_l2(min_energies, p.diff_thresh)
					#output
					the_min_scfset = min_scfsets[0]  #the first one gives the optimal value.
					#format: molset, mol, 'xx', best combo, warn_code, min energy, diis error, 
					#data from other combos. 'xx' is for spacing filling so that calc_dev
					#can be used for this and single outputs from mtag_data and post_process.
					line_out = [molset, mol, 'xx', the_min_scfset, \
								moldata[the_min_scfset][molset][mol][0], \
								moldata[the_min_scfset][molset][mol][pos_min], \
								moldata[the_min_scfset][molset][mol][pos_sort]]
					line_out.extend(min_line_out)
					line_out.append('|')
					#scfsets that give about the same min energy. 
					s = ' '.join([x for x in min_scfsets]) 
					line_out.append(s)
					energies_unsorted.append(line_out)
	POS_SORT_FINAL = 6  #the energies are sorted by this position (min_diis)
	energies_sorted = sorted(energies_unsorted, key = lambda x: x[POS_SORT_FINAL], reverse=True)
	printalist(energies_sorted, output)
    
if __name__	== "__main__":
	main()


