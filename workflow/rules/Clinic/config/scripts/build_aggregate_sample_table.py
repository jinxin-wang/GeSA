import re
import sys
import string
import logging
import argparse
import pandas as pd

from match import match_civic2, match_gender2

def main(input, output, params):
        
    corr_df = pd.read_csv(params.corr_table, sep='\t', header=0).set_index(['Project_TCGA_More', 'MSKCC_Oncotree'])
    logging.debug(corr_df)

    bilan_df = pd.read_excel(input.bilan)
    sheet_df = pd.read_table(input.sheet, names=['sampleAlias','r1','r2','strand'], sep=',')
    variant_df = pd.read_table(input.variant, names=['tumor','normal'], sep='\t')

    sample_table = []

    for i,row in variant_df.iterrows():
        tumor = variant_df.at[i,'tumor']
        normal= variant_df.at[i,'normal']
        tidx  = bilan_df[bilan_df['Sample Name Alias'] == tumor].index.to_list()[-1]
        patient_id = bilan_df.at[tidx, 'PATIENT_ID ']
        subject_id = patient_id

        tcga        = bilan_df.at[tidx, "Project_TCGA_More"]
        oncokb      = bilan_df.at[tidx, "MSKCC"]
        gender      = match_gender2(bilan_df.at[tidx, "Sex"])
        civic_codes = match_civic2(patient_id, oncokb, tcga, corr_df)

        ridx = bilan_df[(bilan_df['PATIENT_ID '] == patient_id) & (bilan_df['Sample Name Alias'].map(lambda x : x in sheet_df['sampleAlias'].to_list()))].index.to_list()
        rna_t= [bilan_df.at[i,'Sample Name Alias'] for i in ridx]
        if len(ridx) > 1:
            logging.warning(f"Patient {patient_id} has more than one rna sample {rna_t} for the analysis, please check. ")

        sample_type= '|'.join([tumor] + [normal] + rna_t)

        sample_table.append([subject_id, sample_type, normal, tumor, '|'.join(rna_t), tcga, oncokb, civic_codes, gender])
        
    pd.DataFrame(sample_table).to_csv(output.sample_table, sep='\t', index=False,
           header = ["Subject_Id", "Sample_Type", "Sample_Id_DNA_N", "Sample_Id_DNA_T", "Sample_Id_RNA_T", "Project_TCGA_More", "MSKCC_Oncotree", "Civic_Disease", "Gender"])

parser = argparse.ArgumentParser(description='inputs from the rule')
parser.add_argument('--bilan')
parser.add_argument('--sheet')
parser.add_argument('--variant')
parser.add_argument('--sample_table')
parser.add_argument('--batch', type=int) # not actually used
parser.add_argument('--corr_table')
parser.add_argument('--out')

input  = parser.parse_args()
output = parser.parse_args()
params = parser.parse_args()
log    = parser.parse_args()

if sys.version_info.major < 3:
    logging.warning(f"require python3, current python version: {sys.version_info[0]}.{sys.version_info[1]}.{sys.version_info[2]}")
        
# logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.DEBUG)
logging.basicConfig(filename=log.out, level=logging.DEBUG)

logging.info(f"input.bilan: {input.bilan}")
logging.info(f"input.sheet: {input.sheet}")
logging.info(f"input.variant: {input.variant}")
logging.info(f"output.rebuild: {output.sample_table}")
logging.info(f"params.batch: {params.batch}")
logging.info(f"params.corr_table: {params.corr_table}")
logging.info(f"log.out: {log.out}")

main(input, output, params)
