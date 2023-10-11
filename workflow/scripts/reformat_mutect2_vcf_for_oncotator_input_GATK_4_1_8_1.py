# Mutect2 new format separate AS_FilterStatus with |, which is not recognised by oncotator
# By replacing '|' with ',' oncotator work. so we do that with this script
# To run :
# python reformat_mutect2_vcf_for_oncotator_input_GATK_4_1_8_1.py input.vcf.gz output.vcf.gz
import sys
import gzip
INPUT_FILE = gzip.open(sys.argv[1],'rb')
OUTPUT_FILE =  gzip.open(sys.argv[2],'wb')

variant_table = []
for x in INPUT_FILE:
    if x[0]=='#':
        OUTPUT_FILE.write(x)
    elif 'AS_FilterStatus=' in x:
        line = x.split('AS_FilterStatus=')[0] + 'AS_FilterStatus=' + x.split('AS_FilterStatus=')[1].split(';')[0].replace('|',',') + ';' + ';'.join(x.split('AS_FilterStatus')[1].split(';')[1:])
        if line not in variant_table:
            variant_table.append(line)
    else:
        variant_table.append(x)

for line in variant_table:
    OUTPUT_FILE.write(line)
    
INPUT_FILE.close()
OUTPUT_FILE.close()

