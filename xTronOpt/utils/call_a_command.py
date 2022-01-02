#example as how to call a line command
import subprocess

p = subprocess.Popen('ls', shell=True, stdout=subprocess.PIPE)

for line in p.stdout.readlines():
	print line

