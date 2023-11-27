# Take a gzipped pileup file and a .tsv files from oncotator reformat (/data/ipadioleau/code/oncotator_extract_information_from_MAF_tumor_Vs_normal.py)
# Add strand coverage of variant and reference allele to the tsv file
import sys
from collections import Counter
import gzip
import io

# MPILEUP = gzip.open(sys.argv[1], 'rb')
ONCOTATOR_FILE = open(sys.argv[2], 'r')
COMPLETED_ONCOTATOR_FILES = open(sys.argv[3], 'w')

# A function that return a dictionnary with all alternatives count on forward and reverse strand
def return_alternativ_count(seq):
	nucleotides_list = {}
	acceptable = ['A', 'a', 'C', 'c', 'G', 'g', 'T', 't', '+', '-', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0']
	getsize = 0
	indel = []
	tmp_size = []
	size = 0
	for nuc in seq:
		# skip all non informative value
		if nuc in acceptable:
			# If there is an indel set getsize to 1 so we get it's size next turn
			if (nuc=='+' or nuc=='-'):
				getsize = 1
				# if previous variant was a indel, save information
				if indel != []:
					indel_seq = ''.join(indel)
					indel = []
					if not indel_seq.upper() in nucleotides_list:
						nucleotides_list[indel_seq.upper()] = [0,0]
					if indel_seq.isupper():
						nucleotides_list[indel_seq.upper()][0] += 1
					else:
						nucleotides_list[indel_seq.upper()][1] += 1
				signe = nuc
			# Get indel size
			elif getsize == 1:
				if nuc.isdigit() :
					tmp_size.append(nuc)
				else:
					if tmp_size == []:
						indel.append(signe + nuc)
					else:
						size = int(''.join(tmp_size)) - 1
						tmp_size = []
						getsize = 0
						indel.append(signe + nuc)
			# If we are processing an indel, get next nucleotide
			elif size > 0 :
				indel.append(nuc)
				size -= 1
			# Save count for each alternative in a dictionary
			else:
				if indel != []:
					indel_seq = ''.join(indel)
					indel = []
					signe=''
					if not indel_seq.upper() in nucleotides_list:
						nucleotides_list[indel_seq.upper()] = [0,0]
					if indel_seq.isupper():
						nucleotides_list[indel_seq.upper()][0] += 1
					else:
						nucleotides_list[indel_seq.upper()][1] += 1
				if  not nuc.isdigit():
					if not nuc.upper() in nucleotides_list:
						nucleotides_list[nuc.upper()] = [0,0]
					if nuc.isupper() :
						nucleotides_list[nuc.upper()][0] += 1
					else:
						nucleotides_list[nuc.upper()][1] += 1
	if indel != []:
		indel_seq = ''.join(indel)
		indel = []
		if not indel_seq.upper() in nucleotides_list:
			nucleotides_list[indel_seq.upper()] = [0,0]
		if indel_seq.isupper():
			nucleotides_list[indel_seq.upper()][0] += 1
		else:
			nucleotides_list[indel_seq.upper()][1] += 1
	return(nucleotides_list)

variant_dict = {}
with io.TextIOWrapper(io.BufferedReader(gzip.open(sys.argv[1]))) as MPILEUP:
	for line in MPILEUP:
		info = line.split('\t')
		nucleotides = Counter(info[4])
		ref_forward = '0'
		ref_reverse = '0'
		if '.' in nucleotides:
			ref_forward = str(nucleotides['.'])
		if ',' in nucleotides:
			ref_reverse = str(nucleotides[','])
		alternativ = return_alternativ_count(info[4])
		for alt in alternativ:
			if alt[0] == '-' :
				info[1] = str(int(info[1]) + 1)
			chr_pos = info[0] + '_' + info[1]
			if chr_pos in variant_dict:
				variant_dict[chr_pos][alt] = [alternativ[alt][0],alternativ[alt][1], ref_forward, ref_reverse]
			else:
				variant_dict[chr_pos] = {}
				variant_dict[chr_pos][alt] = [alternativ[alt][0],alternativ[alt][1], ref_forward, ref_reverse]
			if alt[0] == '-' :
				info[1] = str(int(info[1]) - 1)
			#OUTFILE.write(info[0] + '\t' + info[1] + '\t' + info[2] + '\t' + alt + '\t' + ref_forward + '\t' + ref_reverse + '\t' + str(alternativ[alt][0]) + '\t' + str(alternativ[alt][1]) + '\n')
			#print(info[0] + '\t' + info[1] + '\t' + info[2] + '\t' + alt + '\t' + ref_forward + '\t' + ref_reverse + '\t' + str(alternativ[alt][0]) + '\t' + str(alternativ[alt][1]) + '\n')
	
	  
#####
header = ONCOTATOR_FILE.readline().strip('\n')
COMPLETED_ONCOTATOR_FILES.write(header + '\tt_alt_forward_strand\tt_alt_reverse_strand\tt_ref_forward_strand\tt_ref_reverse_strand\n')
header_info = header.split('\t')
Variant_Type_index = header_info.index('Variant_Type')
Tumor_Seq_Allele2_index = header_info.index('Tumor_Seq_Allele2')

Start_position_index = header_info.index('Start_position')
Chromosome_index = header_info.index('Chromosome')
Tumor_Seq_Allele1_index = header_info.index('Tumor_Seq_Allele1')

for line in ONCOTATOR_FILE:
	info = line.strip().split('\t')
	chr_pos = info[Chromosome_index] + '_' + info[Start_position_index]
	variant_counts = [9999999999,9999999999, 9999999999, 9999999999]
	# My variant checker script do not detect DNP or TNP
	# To report DNP/TNP counts we report the minimum counts per strand for all alternatives nucleotides composing the variant
	if info[Variant_Type_index] == 'DNP' or info[Variant_Type_index] == 'TNP' :
		nucleotides = info[Tumor_Seq_Allele2_index]
		#print(nucleotides)
		tmp_pos = int(info[Start_position_index])
		for tmp_nuc in nucleotides:
			tmp_chr_pos = info[Chromosome_index] + '_' + str(tmp_pos)
			if (tmp_chr_pos in variant_dict) and (tmp_nuc in variant_dict[tmp_chr_pos]):
				if (int(variant_dict[tmp_chr_pos][tmp_nuc][0]) < variant_counts[0]):
					variant_counts[0] = int(variant_dict[tmp_chr_pos][tmp_nuc][0])
				if (int(variant_dict[tmp_chr_pos][tmp_nuc][1]) < variant_counts[1]):
					variant_counts[1] = int(variant_dict[tmp_chr_pos][tmp_nuc][1])
				if (int(variant_dict[tmp_chr_pos][tmp_nuc][2]) < variant_counts[2]):
					variant_counts[2] = int(variant_dict[tmp_chr_pos][tmp_nuc][2])
				if (int(variant_dict[tmp_chr_pos][tmp_nuc][3]) < variant_counts[3]):
					variant_counts[3] = int(variant_dict[tmp_chr_pos][tmp_nuc][3])
			tmp_pos += 1
	elif info[Variant_Type_index] == 'DEL' or info[Variant_Type_index] == 'ONP' :
		seq = '-' + info[Tumor_Seq_Allele1_index]
		if (chr_pos in variant_dict) and (seq in variant_dict[chr_pos]):
			if (int(variant_dict[chr_pos][seq][0]) < variant_counts[0]):
				variant_counts[0] = variant_dict[chr_pos][seq][0]
			if (int(variant_dict[chr_pos][seq][1]) < variant_counts[1]):
				variant_counts[1] = variant_dict[chr_pos][seq][1]
			if (int(variant_dict[chr_pos][seq][2]) < variant_counts[2]):
				variant_counts[2] = variant_dict[chr_pos][seq][2]
			if (int(variant_dict[chr_pos][seq][3]) < variant_counts[3]):
				variant_counts[3] = variant_dict[chr_pos][seq][3]
	elif info[Variant_Type_index] == 'INS' :
		seq = '+' + info[Tumor_Seq_Allele2_index]
		if (chr_pos in variant_dict) and (seq in variant_dict[chr_pos]):
			if (int(variant_dict[chr_pos][seq][0]) < variant_counts[0]):
				variant_counts[0] = variant_dict[chr_pos][seq][0]
			if (int(variant_dict[chr_pos][seq][1]) < variant_counts[1]):
				variant_counts[1] = variant_dict[chr_pos][seq][1]
			if (int(variant_dict[chr_pos][seq][2]) < variant_counts[2]):
				variant_counts[2] = variant_dict[chr_pos][seq][2]
			if (int(variant_dict[chr_pos][seq][3]) < variant_counts[3]):
				variant_counts[3] = variant_dict[chr_pos][seq][3]
	else:
		seq = info[Tumor_Seq_Allele2_index]
		if (chr_pos in variant_dict) and (seq in variant_dict[chr_pos]):
			if (int(variant_dict[chr_pos][seq][0]) < variant_counts[0]):
				variant_counts[0] = variant_dict[chr_pos][seq][0]
			if (int(variant_dict[chr_pos][seq][1]) < variant_counts[1]):
				variant_counts[1] = variant_dict[chr_pos][seq][1]
			if (int(variant_dict[chr_pos][seq][2]) < variant_counts[2]):
				variant_counts[2] = variant_dict[chr_pos][seq][2]
			if (int(variant_dict[chr_pos][seq][3]) < variant_counts[3]):
				variant_counts[3] = variant_dict[chr_pos][seq][3]
	if variant_counts[0] == 9999999999 and variant_counts[1] == 9999999999:
		if variant_counts[2] == 9999999999 :
			variant_counts[2] = 0
		if variant_counts[3] == 9999999999 :
			variant_counts[3] = 0
		variant_counts = ['0','0', str(variant_counts[2]), str(variant_counts[3])]
			
	COMPLETED_ONCOTATOR_FILES.write(line.strip('\n') + '\t' + str(variant_counts[0]) + '\t' + str(variant_counts[1]) + '\t' + str(variant_counts[2]) + '\t' + str(variant_counts[3]) + '\n')
	
COMPLETED_ONCOTATOR_FILES.close()
ONCOTATOR_FILE.close()
MPILEUP.close()
	