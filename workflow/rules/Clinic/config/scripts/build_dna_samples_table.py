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
    variant_df = pd.read_table(input.variant, names=['tumor','normal'], sep='\t')

    alias_list = variant_df['tumor'].to_list() + variant_df['normal'].to_list()
    bilan_df   = bilan_df[bilan_df['Sample Name Alias'].map(lambda x: x in alias_list)].reset_index()

    logging.debug(bilan_df)
    
    sample_table = []
    for idx, patient_gr in bilan_df.groupby('PATIENT_ID '):
        patient_id = str(idx)
        subject_id = patient_id
        tcga        = set(patient_gr["Project_TCGA_More"]).pop()
        oncokb      = set(patient_gr["MSKCC"]).pop()
        gender      = match_gender2(set(patient_gr["Sex"]).pop())
        civic_codes = match_civic2(patient_id, oncokb, tcga, corr_df)

        sid_dna_t  = []
        sid_dna_n  = []
        patient_gr['Sample Name Alias'].map(lambda x : sid_dna_t.append(x) if x[-1] == 'T' else sid_dna_n.append(x))
        
        for t in sid_dna_t :
            sample_table.append([subject_id, t, "DNA_T", "OK", tcga, oncokb, civic_codes, gender])
            
        for n in sid_dna_n :
            sample_table.append([subject_id, n, "DNA_N", "OK", tcga, oncokb, civic_codes, gender])

    pd.DataFrame(sample_table).to_csv(output.sample_table, sep='\t', index=False,
            header = ["Subject_Id", "Sample_Id","Sample_Type","IRODS_Status","Project_TCGA_More","MSKCC_Oncotree","Civic_Disease","Gender"])

parser = argparse.ArgumentParser(description='inputs from the rule')
parser.add_argument('--bilan')
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
logging.info(f"input.variant: {input.variant}")
logging.info(f"output.rebuild: {output.sample_table}")
logging.info(f"params.batch: {params.batch}")
logging.info(f"params.corr_table: {params.corr_table}")
logging.info(f"log.out: {log.out}")

main(input, output, params)
