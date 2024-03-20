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

    alias_list = sheet_df['sampleAlias'].to_list()
    bilan_df   = bilan_df[bilan_df['Sample Name Alias'].map(lambda x: x in alias_list)].reset_index()

    # dataset_pivot = dataset_df.pivot_table(values='datafilePath', index=['sampleAlias', 'sampleId', 'patientId'], aggfunc=list).reset_index()
    # logging.debug(dataset_pivot)
    
    # join_df = bilan_df[bilan_df['*Nucleic Acid Type'] == 'Total RNA'].join(dataset_pivot.set_index('sampleAlias'), on = 'Sample Name Alias').reset_index()
    # join_df = join_df[~join_df['sampleId'].isna()].reset_index()

    logging.debug(bilan_df)
    
    sample_table = []
    for sample_id, rna_gr in bilan_df.groupby('Sample Name Alias'):
        patient_id = set(rna_gr["PATIENT_ID "]).pop()
        subject_id = patient_id
        tcga       = set(rna_gr["Project_TCGA_More"]).pop()
        oncokb     = set(rna_gr["MSKCC"]).pop()
        gender     = match_gender2(set(rna_gr["Sex"]).pop())
        civic_codes= match_civic2(patient_id, oncokb, tcga, corr_df)
        fq1        = f"results/data/fastq/{patient_id}_1.fastq.gz"
        fq2        = f"results/data/fastq/{patient_id}_2.fastq.gz"        
        sample_table.append([subject_id, sample_id, sample_id, sample_id, fq1, fq2, "OK", tcga, oncokb, civic_codes, gender])

    pd.DataFrame(sample_table).to_csv(output.sample_table, sep='\t', index=False,
        header = ["Subject_Id", "Sample_Id", "Sample_Id_Long", "Sample_Id_RNA_T", "FASTQ_1_Name", "FASTQ_2_Name", "IRODS_Status", "Project_TCGA_More", "MSKCC_Oncotree", "Civic_Disease", "Gender"])

parser = argparse.ArgumentParser(description='inputs from the rule')
parser.add_argument('--bilan')
parser.add_argument('--sheet')
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
logging.info(f"output.rebuild: {output.sample_table}")
logging.info(f"params.batch: {params.batch}")
logging.info(f"params.corr_table: {params.corr_table}")
logging.info(f"log.out: {log.out}")

main(input, output, params)
