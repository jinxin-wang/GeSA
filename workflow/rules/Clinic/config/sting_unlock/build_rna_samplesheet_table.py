import re
import sys
import string
import logging
import argparse
import pandas as pd

def main(input, output, params):

    bilan_df = pd.read_excel(input.bilan)
    bilan_df = bilan_df[(bilan_df['Batch'] == params.batch) & (bilan_df['*Nucleic Acid Type'] == 'Total RNA') ]
    logging.info(bilan_df)

    rna_samplesheet = bilan_df['Sample Name Alias'].map(lambda x: [x,f"results/data/fastq/{x}_1.fastq.gz",f"results/data/fastq/{x}_2.fastq.gz","forward"]).to_list()

    rna_samplesheet_df = pd.DataFrame(rna_samplesheet, columns=['sampleAlias', 'r1', 'r2', 'strand'])

    join_df = rna_samplesheet_df.join(bilan_df[['Sample Name Alias','irods_datafilePath']].set_index('Sample Name Alias'), on='sampleAlias').reset_index()

    if join_df['irods_datafilePath'].isna().sum() > 0 :
        for idx,row in join_df[join_df['irods_datafilePath'].isna()].iterrows():
            logging.error(f"Sample {idx} doesn't have any information about datafilePath in iRODS. Please check.")
        raise Exception("Missing value in the column of irods_datafilePath")

    rna_samplesheet_df.to_csv(output.sheet, header=None, index=False, sep=',')

parser = argparse.ArgumentParser(description='inputs from the rule')
parser.add_argument('--bilan')
parser.add_argument('--batch', type=int)
parser.add_argument('--sheet')
parser.add_argument('--out')

input  = parser.parse_args()
output = parser.parse_args()
params = parser.parse_args()
log    = parser.parse_args()

# logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.DEBUG)
logging.basicConfig(filename=log.out, level=logging.DEBUG)

logging.info(f"input.bilan: {input.bilan}")
logging.info(f"params.batch: {params.batch}")
logging.info(f"output.sheet: {output.sheet}")
logging.info(f"log: {log.out}")

main(input, output, params)

