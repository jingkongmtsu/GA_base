import sys
import subprocess
from operator import itemgetter
import p

#add '111' into missing fields typically
#minimum energy and diis error.  
#also word 'matches' coming from err_calc script
#due to failing to catch 0th cycle energy.

#sort the final results by the POS_SORT

#POS_SORT = 6

#
#get the current directory name without parent dirs.
def crntdir():
    rv = ''
    p = subprocess.Popen('pwd', shell=True, stdout=subprocess.PIPE)
    for line in p.stdout.readlines():
        rv = line.rstrip().split('/')[-1]
    return rv


def main():
	fname = crntdir() + '.txt' 
	foutname = crntdir() + '_post.txt' + p.fout_ext
	lines_out = []
	fout = open(foutname, 'w')
	with open(fname) as f:
		for line in f:
			newline = line.rstrip()
			words = newline.split()
			words_len = len(words)
			if  words_len < 8 : 
				for i in range(words_len, 8):
					words.append('111')
			if words[3] == 'matches': 
				words[3] = '111'
			lines_out.append(words)
	lines_out_sorted = sorted(lines_out, key = lambda x: float(x[p.POS_SORT]), reverse=True)
	for x in lines_out_sorted:
		print >> fout, ('{0:>20}{1:>30}{2:5d}{3:20.8f}{4:20.8f}{5:20.8f}{6:20.8f}{7:20.8f}{8:>5d}'.\
						format(x[0], x[1], int(x[2]), float(x[3]), float(x[4]), float(x[5]), float(x[6]), float(x[7]), int(x[8])))
	fout.close()

	
if __name__	== "__main__":
	main()

