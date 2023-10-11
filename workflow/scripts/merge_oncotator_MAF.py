import subprocess
import os
import sys

MAF_LIST = open(sys.argv[1], 'r')
merge_oncotator = sys.argv[2]

MERGE_ONCOTATOR = open(sys.argv[2], 'w')
cpt = 0
for file in MAF_LIST:
	FILE = open(file.strip(), 'r')
	if cpt == 0 :
		lines = ''
		for line in FILE:
			lines = lines + line
			last_line = line
		if last_line.split('\t')[0] != 'Hugo_Symbol':
			cpt = 1
			MERGE_ONCOTATOR.write(lines)
	else:
		for line in FILE:
			info = line.split('\t')
			if ((not ( line[0]=='#')) and (not (info[0]=='Hugo_Symbol'))):
				MERGE_ONCOTATOR.write(line)
	FILE.close()

MAF_LIST.close()
MERGE_ONCOTATOR.close()
