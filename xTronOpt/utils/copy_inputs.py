with open('hf.bad') as f:
	for line in f:
		words = line.split()
		source = words[0] + '/' + words[1] + '.in' 
		target = 'HF_redo/'
		#source = '../hf_redo/HF_redo/' + words[1] + '_1.out' #for outputs.
		#target = words[0] + '/' +  words[1] + '_1.out' #for outputs.
		line_out = words[1] + ' 0'   #for lom
		print line_out 
		line_out = 'cp ' + source + ' ' + target #for inputs.
		#print line_out
		#line_out = 'mv ' + target + ' ' + target + '.old' #for saving old.

