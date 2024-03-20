import re
import sys
import string
import logging
import argparse
import pandas as pd

def main(input, output, params, log):

    bilan_df = pd.read_excel(input.bilan)
    # bilan_df   = pd.read_table(input.bilan, sep='\t', header=0)
    logging.info(bilan_df)

    patients_df = bilan_df[bilan_df["Batch"] == params.batch].pivot_table(values=['Project_TCGA_More', 'MSKCC', 'Sex'], index='PATIENT_ID ', aggfunc=lambda x: list(set(x))[0]).reset_index()
    patients_df = patients_df.rename(columns={'PATIENT_ID ': 'PATIENT_ID', 'MSKCC': 'MSKCC_Oncotree'})

    logging.info(patients_df)

    patients_df.to_csv(output.patient, index=False, sep='\t')

parser  = argparse.ArgumentParser(description='inputs from the rule')
parser.add_argument('--bilan')
parser.add_argument('--patient')
parser.add_argument('--batch', type=int)
parser.add_argument('--out')

input  = parser.parse_args()
output = parser.parse_args()
params = parser.parse_args()
log    = parser.parse_args()

# logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.DEBUG)
logging.basicConfig(filename=log.out, level=logging.DEBUG)

logging.info(f"input.bilan: {input.bilan}")
logging.info(f"output.patient: {output.patient}")
logging.info(f"params.batch: {params.batch}")
logging.info(f"log: {log.out}")

main(input, output, params, log)

