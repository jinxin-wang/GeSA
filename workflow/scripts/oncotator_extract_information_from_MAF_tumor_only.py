import sys
from Bio.Seq import Seq

## exemple command
## for i in *tumor*annotated.TCGAMAF; do python /home/ipadioleau/code/oncotator_extract_information_from_MAF_tumor_only.py $i ${i%%_annotated_Tp.TCGAMAF*}_selection.TCGAMAF ${i%%_annotated_Tp.TCGAMAF*}_selection.tsv; done

#MAF_FILE = open(sys.argv[1], 'r', encoding = "ISO-8859-1")
MAF_FILE = open(sys.argv[1], 'r')
MAF_SUMMARY = open(sys.argv[2], 'w')
MAF_TSV  = open(sys.argv[3], 'w')
column_selection = ['Hugo_Symbol', 'Other_Transcripts', 'HGNC_Ensembl Gene ID', 'Annotation_Transcript', 'Chromosome', 'Start_position', 'End_position', 'Transcript_Strand','Variant_Classification', 'Variant_Type','Reference_Allele', 'Tumor_Seq_Allele1', 'Tumor_Seq_Allele2', 'Tumor_Sample_Barcode', 'Matched_Norm_Sample_Barcode', 'dbSNP_RS', 'dbSNP_Val_Status', 'cDNA_Change', 'Protein_Change', 'UniProt_AApos','ref_context', 'dbNSFP_MutationTaster_pred', 'dbNSFP_Polyphen2_HDIV_pred', 'ExAC_AN_Adj', 'ExAC_AN', 'ExAC_AC_Adj', 'ExAC_AC_Het', 'ExAC_AC_Hom', 'ExAC_AF','DrugBank', 'alt_allele_seen', 'clustered_events','germline_risk','panel_of_normals','str_contraction', 'multiallelic', 't_lod_fstar', 'n_lod','genotype' , 'COSMIC_n_overlapping_mutations']

#'QSS','i_t_ALT_F1R2', 'i_t_ALT_F2R1', 'i_t_REF_F1R2', 'i_t_REF_F2R1', 'n_alt_count', 'n_ref_count', 'n_QSS','i_n_ALT_F1R2', 'i_n_ALT_F2R1', 'i_n_REF_F1R2', 'i_n_REF_F2R1', 'judgement','alt_allele_in_normal','homologous_mapping_event','multi_event_alt_allele_in_normal','triallelic_site'

##########
#### Separate F1R2 ref and alt
column_selection_require_processing = ['F1R2', 'F2R1', 't_alt_count', 't_ref_count', 'tumor_f']
created_info_list =['t_ref_F1R2', 't_alt_F1R2', 't_ref_F2R1', 't_alt_F2R1', 't_t_ref_count', 't_t_alt_count', 't_tumor_f', 'jugement']
created_info ={'t_ref_F1R2':'', 't_alt_F1R2':'', 't_ref_F2R1':'', 't_alt_F2R1':'', 't_t_ref_count':'', 't_t_alt_count':'', 't_tumor_f':'', 'jugement':''}

## One function to parse line of tumor sample, return created_info table with new information
def parse_tumor(column_info,column_selection_require_processing_index,column_selection_index,created_info,alt):
    if column_info.count('FAIL')>=1:
        created_info['jugement'] = 'FAIL'
    else:
        created_info['jugement'] = 'PASS'
    F1R2_info = column_info[column_selection_require_processing_index[0]].split('|')[0].split(',')
    F2R1_info = column_info[column_selection_require_processing_index[1]].split('|')[0].split(',')
    created_info['t_t_alt_count'] = column_info[column_selection_require_processing_index[2]].split('|')[0]
    created_info['t_t_ref_count'] = column_info[column_selection_require_processing_index[3]].split('|')[0]
    created_info['t_tumor_f'] = column_info[column_selection_require_processing_index[4]].split('|')[0]
    created_info['t_ref_F1R2'] = F1R2_info[0]
    created_info['t_alt_F1R2'] = F1R2_info[alt]
    created_info['t_ref_F2R1'] = F2R1_info[0]
    created_info['t_alt_F2R1'] = F2R1_info[alt]
    return created_info

def get_context_right(column_info, context_idx):
    context_info = []
    pyrimidine = ['C','T']
    purine = ['A','G']
    base = purine + pyrimidine
    rev_comp = 'FALSE'
    ref_al = column_info[context_idx[0]]
    tum_al_1 = column_info[context_idx[1]]
    tum_al_2 = column_info[context_idx[2]]
    ref_cont = column_info[context_idx[3]]
    if (len(ref_al) == 1) and (ref_al in pyrimidine) and (tum_al_2 in base):
        sign_cont = ref_cont[9:12].upper()
        sign_info = sign_cont + '_' + ref_al + '>' + tum_al_2
    elif (len(ref_al) == 1) and (ref_al in purine) and (tum_al_2 in base):
        rev_comp = 'TRUE'
        sign_cont = str(Seq(ref_cont[9:12]).reverse_complement()).upper()
        ref_al_rc = str(Seq(ref_al).reverse_complement())
        tum_al_2_rc = str(Seq(tum_al_2).reverse_complement())
        sign_info = sign_cont + '_' + ref_al_rc + '>' + tum_al_2_rc
    else:
        sign_cont = '-'
        sign_info = '-'
        rev_comp = '-'
    context_info.extend([sign_cont,sign_info,rev_comp])
    return context_info

column_selected = 0
column_selection_index = []
column_selection_require_processing_index = []
skipped_variant = 0
multi_alt = 0

for line in MAF_FILE:
    if line[0] == '#':
        MAF_SUMMARY.write(line)
    elif column_selected == 0:
        MAF_SUMMARY.write('## After column selection\n')
        column_info = line.strip().split('\t')
        for title in column_selection:
            if title in column_info:
                column_selection_index.append(column_info.index(title))
        for title in column_selection_require_processing:
            column_selection_require_processing_index.append(column_info.index(title))
        genotype_index = column_info.index("genotype")
        t_lod_fstar_idx = column_info.index("t_lod_fstar")
        context_idx = []
        context_idx.append(column_info.index("Reference_Allele"))
        context_idx.append(column_info.index("Tumor_Seq_Allele1"))
        context_idx.append(column_info.index("Tumor_Seq_Allele2"))
        context_idx.append(column_info.index("ref_context"))
        Matched_Norm_Sample_Barcode_index = column_info.index("Matched_Norm_Sample_Barcode")
        Tumor_Sample_Barcode_index = column_info.index("Tumor_Sample_Barcode")
        column_selected = 1
        newline = ''
        for index in column_selection_index:
            newline = newline + column_info[index] + '\t'
        for title in created_info_list:
            newline = newline + title + '\t'
        newline = newline + 'context\tsignature_context\tReverse_complement\t'
        MAF_SUMMARY.write(newline.strip() + '\n')
        MAF_TSV.write(newline.strip() + '\n')
    else:
        column_info = line.strip().split('\t')
        if multi_alt == 0 :
            if (column_info[genotype_index] == '1|0') or (column_info[genotype_index] == '0|1'):
                reinitiation = 1
            else:
                reinitiation = len(column_info[genotype_index].split('|')[0].split('/'))-1
        if multi_alt == reinitiation :
            multi_alt = 0
            if (column_info[genotype_index] == '1|0') or (column_info[genotype_index] == '0|1'):
                reinitiation = 1
            else:
                reinitiation = len(column_info[genotype_index].split('|')[0].split('/'))-1
        multi_alt += 1
        created_info = parse_tumor(column_info,column_selection_require_processing_index,column_selection_index,created_info,multi_alt)
        context_info = get_context_right(column_info, context_idx)
        column_info[Tumor_Sample_Barcode_index] = column_info[Matched_Norm_Sample_Barcode_index]
        column_info[Matched_Norm_Sample_Barcode_index] = 'NA'
        newline = ''
        for index in column_selection_index:
            if (index == t_lod_fstar_idx) or (index == genotype_index):
                column_info[index] = column_info[index].split('|')[0]
            newline = newline + column_info[index] + '\t'
        for title in created_info_list:
            newline = newline + created_info[title] + '\t'
        for info in context_info:
            newline = newline + info + '\t'
        MAF_SUMMARY.write(newline.strip() + '\n')
        MAF_TSV.write(newline.strip() + '\n')
            


MAF_FILE.close()
MAF_SUMMARY.close()
MAF_TSV.close()

