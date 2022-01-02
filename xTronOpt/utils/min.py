import sys
from operator import itemgetter


#Find the mininum of minimum energies of different
#sets and sort them by diis error.  Can be easily
#modifed to do other searching and sorting.

###
#read in parameters
def read_params(fname):
	emptyline = ['#', ' ', '\n', '\t']
	params = {}
	with open (fname) as f:
		for line in f:
			newline = line.rstrip()
			if len(newline) == 0 or newline[0] in emptyline: 
				continue
			words = newline.split()
			params[words[0]] = words[1:]
	#now collect all the terms.
	return params['output'][0], float(params['diff_thresh'][0]), \
			params['scfset_common'][0], \
			params['scfset_names'], params['master_l'][0], \
			int(params['POS_SORT'][0]), int(params['POS_MIN'][0])

###
# print a list
def printalist(alist, fname):
    f = open(fname, 'w')
    for x in alist: 
        for item in x:
            f.write(str(item)+' ')
        f.write('\n')

###
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

###
#get minima from a dict list of lists.
def minima_l2(some_dict, elm, diff_thresh):
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
#list of number lists.  Skip an entry if it does not have
#enough numbers.
def read_energies(fname):
	rv = {}
	with open(fname) as f:
		for line in f:
			newline = line.rstrip()
			words = newline.split()
			#print 'len(words) ', len(words)
			if ( len(words) != 9 ) : continue
			num = []
			for i in range(3,7):
				num.append(float(words[i]))
			rv[words[1]] = num
	return rv

###
def main():
    output, diff_thresh, scfset_common, scfset_names, master_l, POS_SORT, POS_MIN \
    = read_params(sys.argv[1])
    moldata = {}  #all the data together
    for scfset in scfset_names:
        scfset_file = scfset_common + scfset + '_post' + '.txt' 
        moldata[scfset] = read_energies(scfset_file)
	energies_unsorted = []
    with open (master_l) as f:
        for line in f:
            words = line.split()
            mol = words[1]
            min_energies = {}
            for scfset in scfset_names:
                if mol in moldata[scfset] : 
                    min_energies[scfset] = moldata[scfset][mol][POS_MIN]
            min_energy, min_molset_names = minima_l(min_energies, diff_thresh)
            #output
            s = ' '.join([x for x in min_molset_names])  
            #print moldata[scfset][mol]
            line_out = [words[0], mol, min_energy, moldata[scfset][mol][POS_SORT], s]
            energies_unsorted.append(line_out)
    energies_sorted = sorted(energies_unsorted, key = lambda x: x[3], reverse=True)
    printalist(energies_sorted, output)
    
	
if __name__	== "__main__":
	main()


