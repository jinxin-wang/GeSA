import sys
import os 

MUTATION_FILE = open(sys.argv[1], 'r')
OUT_FILE = open(sys.argv[2], 'w')

COSMIC_MUTATION = open('/mnt/beegfs/userdata/a_ivashkin/references/genome_data/cosmic/CosmicMutant_count.tsv', 'r')
ONCOGENES = open('/mnt/beegfs/userdata/a_ivashkin/references/genome_data/cosmic/cancer_gene_census_hg19_oncogene_IDs.tsv', 'r')
TUMORSUPRESSOR = open('/mnt/beegfs/userdata/a_ivashkin/references/genome_data/cosmic/cancer_gene_census_hg19_tumor_supressor_genes_IDs.tsv', 'r')

good_variant_classification_TSG = ['In_Frame_Del', 'In_Frame_Ins', 'Missense_Mutation', 'Nonsense_Mutation', 'Splice_Site']

cosmic_dict = {}
headrer = COSMIC_MUTATION.readline()
for line in COSMIC_MUTATION:
    info = line.strip('\n').split('\t')
    #Chromosome      Start   End     Variant_Type  Gene_IDs     Primary_site    Cosmic_Count_Total      Cosmic_Count_skin   Cosmic_Count_blood_cancer        Cosmic_Count_gastro_intestinal  Cosmic_Count_lung       Cosmic_Count_liver      Cosmic_Count_breast     Cosmic_Count_reproductive       Cosmic_Count_cns     Cosmic_Count_soft_tissue        Cosmic_Count_kidney     Cosmic_Count_urin_billary       Cosmic_Count_bone       Cosmic_Count_pancreas   Cosmic_Count_thyroid
    ID = info[0] + '_' + info[1] + '_' + info[2] + '_' + info[3]
    cosmic_dict[ID] = info[5:]

COSMIC_MUTATION.close()

oncogenes = []
for line in ONCOGENES:
    oncogenes.append(line.strip())
ONCOGENES.close()

tumor_supressor_genes = []
for line in TUMORSUPRESSOR:
    tumor_supressor_genes.append(line.strip())
TUMORSUPRESSOR.close()

mutFile_header= MUTATION_FILE.readline()
mutFile_header_list = mutFile_header.strip().split('\t')
mutFile_chr_idx = mutFile_header_list.index('Chromosome')
mutFile_SP_idx = mutFile_header_list.index('Start_position')
mutFile_EP_idx = mutFile_header_list.index('End_position')
mutFile_NSB_idx = mutFile_header_list.index('Matched_Norm_Sample_Barcode')
mutFile_VC_idx = mutFile_header_list.index('Variant_Classification')
mutFile_VT_idx = mutFile_header_list.index('Variant_Type')
mutFile_J_idx = mutFile_header_list.index('jugement')
mutFile_cosmic_idx = mutFile_header_list.index('COSMIC_n_overlapping_mutations')
mutFile_HS_idx = mutFile_header_list.index('Hugo_Symbol')

OUT_FILE.write(mutFile_header.strip() + '\tPrimary_site\tOncogene\tTumor_Supressor_Gene\tCosmic_Count_Total\tCosmic_Count_skin\tCosmic_Count_blood_cancer\tCosmic_Count_gastro_intestinal\tCosmic_Count_lung\tCosmic_Count_liver\tCosmic_Count_breast\tCosmic_Count_reproductive\tCosmic_Count_cns\tCosmic_Count_soft_tissue\tCosmic_Count_kidney\tCosmic_Count_urin_billary\tCosmic_Count_bone\tCosmic_Count_pancreas\tCosmic_Count_thyroid\n')
    
for line in MUTATION_FILE:
    info = line.strip().split('\t')
    ID = info[mutFile_chr_idx] + '_' + info[mutFile_SP_idx] + '_' + info[mutFile_EP_idx] + '_' + info[mutFile_VT_idx]
    oncogene = 'FALSE'
    TSG = 'FALSE'
    if info[mutFile_HS_idx] in oncogenes:
        oncogene = 'TRUE'
    if info[mutFile_HS_idx] in tumor_supressor_genes:
        TSG = 'TRUE'
    if ID in cosmic_dict:
        info.append(cosmic_dict[ID][0] + '\t' + oncogene + '\t' + TSG + '\t' + '\t'.join(cosmic_dict[ID][1:]))        
    else:
        info.append('\t' + oncogene + '\t' + TSG )
        info.append('\t'*14)
    OUT_FILE.write('\t'.join(info) + '\n')

OUT_FILE.close()
MUTATION_FILE.close()
