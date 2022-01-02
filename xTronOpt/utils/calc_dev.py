import sys
import subprocess
from operator import itemgetter
import p

#
#get the current directory name without parent dirs.
def crntdir():
    rv = ''
    p = subprocess.Popen('pwd', shell=True, stdout=subprocess.PIPE)
    for line in p.stdout.readlines():
        rv = line.rstrip().split('/')[-1]
    return rv
#
#read in the set, mol, and min energy.
def read_energies(fnames, fout_log) :
	rv = {}
	for fname in fnames :
		with open(fname) as f:
			for line in f:
				if (line[0] == '*'): 
					print >> fout_log, 'Skip ', line
					continue   #skip
				words = line.split()
				set_name = words[0]
				if ( set_name not in rv ): rv[set_name] = {}
				mol = words[1]
				rv[set_name][mol] = float(words[p.POS_ENERGY])
				#print 'cp ' + set_name + '/' + mol + '.in ' + 'mb05_test/'
	return rv
#
#read in reference values.
def read_refs(fout_log) :
	rv = {}
	with open(p.molsets_fname) as sets_f:  #loop over sets.
		for set_line in sets_f:
			set_name = (set_line.split())[0]
			if ( set_name[0] == '*' or set_name == 'atoms' ) : 
				#fout_log.write('SKIP: set %s' % (set_name))  # alt 1
				#fout_log.write('SKIP: set {}'.format(set_name))  # alt 2	
				print >> fout_log, 'SKIP: set', set_name
				continue  #set skipped
			refs_file = p.refs_dir + '/' + set_name + '/ref_vals'
			rv[set_name] = {}
			with open(refs_file) as refs_f:
				for ref_line in refs_f:
					if (ref_line[0] == '#'): continue   #skip
					words = ref_line.split()
					rv[set_name][words[0]] = p.unit_conv*float(words[1])
					#formulas, refs are reversed from the literature for these two.
					if (set_name == 'MN_HTBH38-08' or set_name == 'MN_NHTBH38-08') :
						rv[set_name][words[0]] = -rv[set_name][words[0]]
	return rv

#
# calculate devs for one set of results.
def calc_dev(fnames, ref_vals_all, fout_log) :
	#energies indexed by molecule names.
	energies = read_energies(fnames, fout_log)
	setdevs = {}
	moldevs = {}
	molform = {}
	with open(p.molsets_fname) as sets_f:  #loop over sets.
		for set_line in sets_f:
			set_name = (set_line.split())[0]
			if ( set_name[0] == '*' or set_name == 'atoms' ) : 
				continue  #set skipped
			if ( set_name not in energies ) :
				print 'ERROR', 'set', set_name, 'not found in energy'
				sys.exit()
			set_source = (set_name.split("-"))[0]
			ref_vals = ref_vals_all[set_name]
			if set_source in ['MN', 'W4', 'MGAE109'] :
				setdevs[set_name], moldevs[set_name], molform[set_name] \
					= dev_1set_mn(set_name, energies, ref_vals, fout_log)
			elif set_source in ['GM55'] :
				setdevs[set_name], moldevs[set_name] = dev_1set_gm(set_name, 
                                        energies, ref_vals, fout_log)
			else :
				print 'ERROR : no dev_1set available'
				sys.exit()

	return setdevs, moldevs, molform



#deviation for one subset for GMTKN style formulas.
#moldevs are indexed by the leading column of ref_vals, which 
#is the reaction number.
def dev_1set_gm(set_name, energies, ref_vals, fout_log) :
	#return values
	setdevs = []
	moldevs = {}
	#local variables.
	mud = 0
	msd = 0
	max_mol = ''
	max_dev = 0
	mol_ntot = 0
	#loop over lom to find formulas
	with open(p.refs_dir + '/' + set_name + '/' + 'formulas') as lom_f:  
		for mol_line in lom_f:
			words = (mol_line.rstrip()).split()
			rnum = words[0]  #rnum is actually a string type!
			if ( rnum[0] == '*') : 
				print >> fout_log, 'SKIP: reaction', set_name, rnum
				continue 
			if ( rnum not in ref_vals ) :
				print 'ERROR', fname, set_name, mol, 'not in ref_vals'
				sys.exit()
			npc = (len(words) - 2)/2
			skip=False
			calc = 0
			for ipc in range (0, npc):
				mol = words[ipc+1]
				if mol not in energies[set_name] :
					print >> fout_log, 'SKIP reaction:', rnum, \
                                                'for missing ', set_name + '/' + mol
					skip=True
					break
				coef = float(words[npc+ipc+1])
				calc += coef*energies[set_name][mol]
			if skip : continue
			calc = p.unit_conv*calc
			dev = calc - ref_vals[rnum]  #unit conversion was done for both.
			if ( abs(dev) > abs(max_dev) ) :
				max_dev = dev
				max_mol = mol
			moldevs[rnum] = []
			moldevs[rnum].append(calc)
			moldevs[rnum].append(dev)
			msd = msd + dev
			mud = mud + abs(dev)
			mol_ntot = mol_ntot + 1
	msd = msd/mol_ntot 
	mud = mud/mol_ntot 
	setdevs = []
	setdevs.append(mud)
	setdevs.append(msd/mud)
	setdevs.append(max_dev)
	setdevs.append(max_mol)

	return setdevs, moldevs



#deviation for one subset for GMTKN style formulas.
#moldevs are indexed by the leading column of lom, which 
#is a molecule name.
def dev_1set_mn(set_name, energies, ref_vals, fout_log) :
	#return values
	setdevs = []
	moldevs = {}
	molform = {}
	#local variables.
	mud = 0
	msd = 0
	max_mol = ''
	max_dev = 0
	mol_ntot = 0
	#collects skipped molecules. The assumption is that molecules 
	#without formulas listed first in lom.
	mols_skip = []  
	#loop over lom to find formulas
	with open(p.refs_dir + '/' + set_name + '/' + p.lom_fname) as lom_f:  
		for mol_line in lom_f:
			words = (mol_line.rstrip()).split()
			mol = words[0]
			if ( mol[0] == '*') : 
				mols_skip.append(mol[1:])
				print >> fout_log, 'SKIP:', set_name + '/' + mol
				continue 
			if ( words[p.POS_NPC] == '0' ) : continue #skip not a formula.
			if ( mol not in energies[set_name] ) :
				print >> fout_log, 'SKIP:', p.lom_fname, set_name, mol, 'not in energies'
				continue
			npc = int(words[p.POS_NPC])  #a formula found.
			if (npc > 4) :
				print >> fout_log, 'npc ', npc, ' > 4'
				sys.exit()
			coef = {}
			for ipc in range (0, npc): 
				coef[words[5 + ipc*2]] = float(words[4 + ipc*2])
			energy_prods = 0
			skip = False
			molform[mol] = []
			for prod in coef:
				if ( prod in mols_skip ) :
					print >> fout_log, 'SKIP: reaction ', set_name + '/' + mol, \
							'missing', prod
					skip = True
					break
				energy_prod = 0.0
				if ( prod in energies[set_name] ) : 
					energy_prod = energies[set_name][prod]
				elif (prod in energies['atoms'] ) :
					energy_prod = energies['atoms'][prod]
				else:
					print >> fout_log, 'SKIP: Prod ', prod, 'cannot be found in',\
                                                set_name, 'or atoms'
					skip = True
					break
				if skip : continue
				energy_prods += coef[prod]*energy_prod
				molform[mol].append([prod,coef[prod]])
			for ipc in range(npc,4) :
				molform[mol].append(['x',0])
			calc = p.unit_conv*(energy_prods - energies[set_name][mol])
			if (set_name == 'MN_HTBH38-08' or set_name == 'MN_NHTBH38-08') : 
				calc = -calc
			if ( mol not in ref_vals ):
				print 'ERROR', set_name, mol, 'not in ref_vals'
				sys.exit()
			dev = calc - ref_vals[mol]  #unit conversion was done for both.
			#formulas, refs are reversed from the literature for these two.
			if ( abs(dev) > abs(max_dev) ) :
				max_dev = dev
				max_mol = mol
			moldevs[mol] = []
			moldevs[mol].append(calc)     #[0] calculated, [1] dev
			moldevs[mol].append(dev)
			msd = msd + dev
			mud = mud + abs(dev)
			mol_ntot = mol_ntot + 1
	msd = msd/mol_ntot 
	mud = mud/mol_ntot 
	setdevs = []
	setdevs.append(mud)
	setdevs.append(msd/mud)
	setdevs.append(max_dev)
	setdevs.append(max_mol)

	return setdevs, moldevs, molform
	
def main():
	if ( len(p.methods_results) == 0 ):
		fnl = crntdir().split('_')[0]
		p.methods_results.append([fnl, crntdir() + '_post.txt'])
	fout = open(crntdir() + '.dev.' + p.fout_ext + str(p.format_out), 'w')
        #print out crucial part of the input.
        print >> fout, 'refs_dir = ', p.refs_dir
        print >> fout, 'lom_fname = ', p.lom_fname
        print >> fout, 'molsets_fname = ', p.molsets_fname

	fout_log = open(crntdir() + '.dev.log', 'w')
	ref_vals = read_refs(fout_log)
	#see dev_1set return values for more details.
	setdevs = {} #[method][set][mud, msd/mud, maxdev, maxmol]
	moldevs = {} #[method][set][mol][calc, dev]
	molform = {} #[set][mol][1:4[mol,coef]]
	#fmt# corresponds to the p.format_out.  
	#fmt0 : %msd, mud, for mol sets; ref, calc, dev for molecules.
	#fmt1 : mud, max_dev, max_mol for sets only.
	#fmt2 : devs for one set.
	#fmt3 : ref, calc for one set.
	#fmt4 : relative msd for sets only.
	#fmt7 : output for autoRE (reaction energy calc)
	#_0 is for the first set of columns, _1 is for each molecule.
	fmt0_0 = '{0:<12}{1:<14}{2:>10.3f}'    #setname, mol, ref_vals
	fmt0_0title = '{0:<12}{1:<14}{2:>10}'  #have to be in sync with fmt0_0
	fmt0_1_num =  ' {0:>10.3f}'              #dev
	fmt0_1_mol =  ' {0:>10}'              #not used.
	fmt0_1title = ' {0:>10}'      #have to be in sync with fmt0_1

	#simple output.  Sets errors only.
	fmt1_0 = '{0:<11}'
	fmt1_0title = '{0:<11}'  #have to be in sync with fmt1_0
	fmt1_1 = fmt0_1_num      #'{0:>10.3f}'
	fmt1_1title = fmt0_1title   #'{0:>10}'      #have to be in sync with fmt1_1

	#not used. simple output.  Errors for one set.
	fmt2_0 = '{0:<21}'
	fmt2_0title = '{0:<21}'  #have to be in sync with fmt2_0
	fmt2_1 = '{0:>10.3f}'
	fmt2_1title = '{0:>10}'      #have to be in sync with fmt1_1

	#Not used. simple output.  calculated for one set.
	fmt3_0 = '{0:<21}{1:>10.3f}'    #mol, ref.
	fmt3_0title = '{0:<21}{1:>10}'  #have to be in sync with fmt2_0
	fmt3_1 = '{0:>10.3f}'           #dev
	fmt3_1title = '{0:>10}'      #have to be in sync with fmt1_1

	#Not used. simple output.  Sets relative MSD only.
	fmt4_0 = '{0:<11}'
	fmt4_0title = '{0:<11}'  #have to be in sync with fmt4_0
	fmt4_1 = '{0:>10.3f}'
	fmt4_1title = '{0:>10}'      #have to be in sync with fmt4_1

	#gabage. simple output. same format as fmt1, calculated values instead of deviations.
	fmt5_0 = '{0:<11}'
	fmt5_0title = '{0:<11}'  #have to be in sync with fmt5_0
	fmt5_1 = fmt0_1_num      #'{0:>10.3f}'
	fmt5_1title = fmt0_1title   #'{0:>10}'      #have to be in sync with fmt5_1

	fmt7_0_mol = '{0:<21}'   #mol
	fmt7_0_prod = '{0:>2}'
	fmt7_0_coef = '{0:>3d}'  #coef
	fmt7_1_num =  ' {0:>10.3f}'    #calc value for each mol.

	#Title row
	line_o0 = fmt0_0title.format('SET', 'MOL', 'REF');
	line_o1 = fmt1_0title.format('SET');
	line_o2 = fmt2_0title.format('MOL');
	line_o3 = fmt3_0title.format('MOL', 'REF');
	line_o4 = fmt4_0title.format('SET');
	line_o5 = fmt1_0title.format('SET');
	for method in p.methods_results:
		mn = method[0]  #method name. molform is being repeated.
		setdevs[mn], moldevs[mn], molform = calc_dev(method[1:], ref_vals, fout_log)
		line_o0 = line_o0 + fmt0_1title.format(method[0])
		line_o1 = line_o1 + fmt1_1title.format(method[0])
		line_o2 = line_o2 + fmt2_1title.format(method[0])
		line_o3 = line_o3 + fmt3_1title.format(method[0])
		line_o4 = line_o4 + fmt4_1title.format(method[0])
		line_o5 = line_o5 + fmt5_1title.format(method[0])
		#no title line for fmt7 for now.
	line_o0 = line_o0 + fmt0_1title.format('Best') + fmt0_1title.format('Worst')
	line_o1 = line_o1 + fmt0_1title.format('Best') + fmt0_1title.format('Worst')
	if ( p.format_out == 0 or p.format_out == 6): print >> fout, line_o0   #title line
	if ( p.format_out == 1 ): print >> fout, line_o1   #title line
	if ( p.format_out == 2 ): print >> fout, line_o2   #title line
	if ( p.format_out == 3 ): print >> fout, line_o3   #title line
	if ( p.format_out == 4 ): print >> fout, line_o4   #title line
	if ( p.format_out == 5 ): print >> fout, line_o5   #title line
	if ( p.format_out == 0 or p.format_out == 6 ): print >> fout             #divider between title and set sections.
	#Set deviations.
	with open(p.molsets_fname) as molsets_f:  #loop over sets.
		for molset_line in molsets_f:
			molset = (molset_line.split())[0]
			if ( molset[0] == '*' or molset == 'atoms' ) : continue  #set skipped
			line_o0_mud = fmt0_0.format(molset[3:14], 'MUD', 0)  #molset must be in sync with mol_line below.
			line_o0_msd = fmt0_0.format('', 'MSD%', 0)  #molset must be in sync with mol_line below.
			line_o0_maxdev = fmt0_0.format('', 'MaxD', 0)  #molset must be in sync with mol_line below.
			line_o0_maxmol = fmt0_0.format('', 'maxmol', 0)  #molset must be in sync with mol_line below.
			line_o1 = fmt1_0.format(molset[3:14])  #molset must be in sync with mol_line below.
			line_o4 = fmt4_0.format(molset[3:14])  #molset must be in sync with mol_line below.
			line_o5 = fmt5_0.format(molset[3:14])  #molset must be in sync with mol_line below.
			#no set stats for fmt7 for now.
			best = 10000
			best_set = ''
			worst = 0
			worst_set = ''
			for method in p.methods_results:
				this_mud = setdevs[method[0]][molset][0]
				if ( this_mud < best ) :
					best = this_mud
					best_set = method[0]
				if ( this_mud > worst ) :
					worst = this_mud
					worst_set = method[0]
				line_o0_mud = line_o0_mud + fmt0_1_num.format(setdevs[method[0]][molset][0])
				line_o0_msd = line_o0_msd + fmt0_1_num.format(setdevs[method[0]][molset][1])
				line_o0_maxdev = line_o0_maxdev + fmt0_1_num.format(setdevs[method[0]][molset][2])
				line_o0_maxmol = line_o0_maxmol + fmt0_1_mol.format(setdevs[method[0]][molset][3][0:8])
				line_o1 = line_o1 + fmt1_1.format(setdevs[method[0]][molset][0])
				line_o4 = line_o4 + fmt4_1.format(setdevs[method[0]][molset][0])
				line_o5 = line_o5 + fmt5_1.format(setdevs[method[0]][molset][0])
			line_o0_mud = line_o0_mud + fmt0_1title.format(best_set) + fmt0_1title.format(worst_set)
			line_o1 = line_o1 + fmt1_1title.format(best_set) + fmt1_1title.format(worst_set)
			line_o5 = line_o5 + fmt5_1title.format(best_set) + fmt5_1title.format(worst_set)
			if ( p.format_out == 0 or p.format_out == 6 ): 
				print >> fout, line_o0_mud
				print >> fout, line_o0_msd
				print >> fout, line_o0_maxdev
				#print >> fout, line_o0_maxmol
			if ( p.format_out == 1 ): print >> fout, line_o1
			if ( p.format_out == 4 ): print >> fout, line_o4
			if ( p.format_out == 5 ): print >> fout, line_o5
	#Mol deviations.
	if ( p.format_out == 0 or p.format_out == 6 ): print >> fout              #divider between sets and mols.
	with open(p.molsets_fname) as molsets_f:  #loop over sets.
		for molset_line in molsets_f:
			molset = (molset_line.split())[0]
			if ( molset[0] == '*' or molset == 'atoms' ) : continue  #set skipped
#			with open(p.refs_dir + '/' + molset + '/' + p.lom_fname) as lom_f:
#				for mol_line in lom_f:
#					words = (mol_line.rstrip()).split()
#					if ( words[0][0] == '*' or words[p.POS_NPC] == '0' ) : continue #skip 
#					mol = words[0]
			#Trust that all methods have the same mols.
                        #method[0] is the name of the method, method[1] is the results file.
			for mol in moldevs[method[0]][molset] :  
					#line_o0_calc = fmt0_0.format(molset[3:14], mol[0:24], ref_vals[molset][mol])  #mol_line.
					line_o0_dev = fmt0_0.format(molset[3:14], mol[0:13], ref_vals[molset][mol])  #mol_line.
					line_o6_cal = fmt0_0.format(molset[3:14], mol[0:13], ref_vals[molset][mol])  #mol_line.
					line_o2 = fmt2_0.format(mol[0:21])  #mol_line.
					line_o3 = fmt3_0.format(mol[0:21], ref_vals[molset][mol])  #mol_line.
					line_o7 = fmt7_0_mol.format(mol[0:21])
					#list of products.
					line_o7 = line_o7 + ' '.join(fmt7_0_prod.format(p[0]) for p in molform[molset][mol])
					#list of coefficients.
					line_o7 = line_o7 + ' '.join(fmt7_0_coef.format(int(p[1])) for p in molform[molset][mol])
					line_o7 = line_o7 + fmt7_1_num.format(ref_vals[molset][mol])  #list of coefficients.

					for method in p.methods_results:
						#line_o0_calc = line_o0_calc + ' |{0:>10.3f}{1:>10.3f}'.format(moldevs[method[0]][molset][mol][0])
						line_o0_dev = line_o0_dev + fmt0_1_num.format(moldevs[method[0]][molset][mol][1])
						line_o2 = line_o2 + '{0:>10.3f}'.format(moldevs[method[0]][molset][mol][1])
						line_o3 = line_o3 + '{0:>10.3f}'.format(moldevs[method[0]][molset][mol][0])
						line_o6_cal = line_o6_cal + fmt0_1_num.format(moldevs[method[0]][molset][mol][0])
						line_o7 = line_o7 + fmt7_1_num.format(moldevs[method[0]][molset][mol][0])  #mol calc
					if ( p.format_out == 0 ): print >> fout, line_o0_dev
					if ( p.format_out == 2 ): print >> fout, line_o2
					if ( p.format_out == 3 ): print >> fout, line_o3
					if ( p.format_out == 6 ): print >> fout, line_o6_cal
					if ( p.format_out == 7 ): print >> fout, line_o7
	fout.close()
	fout_log.close()


if __name__ == '__main__':
	main()


