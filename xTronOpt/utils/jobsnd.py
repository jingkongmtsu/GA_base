import sys

folder = 'scripts_configs/'
jobs_all = []
with open (folder + 'commands') as all_f:
	for line in all_f:
		line_split0 = line.rstrip().split()
		line_split1 = line_split0[-1].split('/')
		jobs_all.append(line_split1[-2:])
jobs_subd = {}
with open (folder + 'commands_submitted') as subd_f:
	for line in subd_f:
		line_split0 = line.rstrip().split()
		line_split1 = line_split0[-1].split('/')
		molset = line_split1[-2]
		if ( molset not in jobs_subd ):
			jobs_subd[molset] = {}
		mol = line_split1[-1]
		jobs_subd[molset][mol] = line_split0[1]
jobs_done = []
with open (folder + 'commands_done') as done_f:
	for line in done_f:
		jobs_done.append(int(line.split()[0]))
jobs_running = []
jobs_waiting = []
for i in range(0, len(jobs_all)):
	if i+1 not in jobs_done:
		molset = jobs_all[i][0]
		mol = jobs_all[i][1]
		if ( (molset in jobs_subd) and (mol in jobs_subd[molset]) ) :
			jobs_running.append(molset + '/' + mol + ' ' + jobs_subd[molset][mol])
		else:
			jobs_waiting.append(molset + '/' + mol)
num_done = len(jobs_done)
print 'Jobs done:', num_done
print 'Jobs running:', len(jobs_running)
for x in jobs_running: print x
num_wait = len(jobs_waiting)
print 'Jobs waiting:', num_wait
if ( num_wait < 20 ): 
	for x in jobs_waiting: print x


