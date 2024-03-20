import re
import sys
import string
import logging
import argparse
import pandas as pd

def main(input, output, params):

    bilan_df = pd.read_excel(input.bilan)
    
    sheet_df = pd.read_table(input.sheet, names=['sampleAlias','r1','r2','strand'], sep=',')
    variant_df = pd.read_table(input.variant, names=['tumor','normal'], sep='\t')

    alias_list = variant_df['tumor'].to_list() + variant_df['normal'].to_list() + sheet_df['sampleAlias'].to_list()

    dataset_df = bilan_df[bilan_df['Sample Name Alias'].map(lambda x: x in alias_list)][['Sample Name Alias', 'irods_datafilePath']].reset_index()

    if len(set(alias_list)) > len(dataset_df) :
        raise Exception("Missing sample alias in bilan table. ")
    
    if dataset_df['irods_datafilePath'].isna().sum() > 0 :
        raise Exception("Missing datafilePath in bilan table")
    
    dataset_df['irods_datafilePath'] = dataset_df['irods_datafilePath'].map(lambda x: list(set([p.strip() for p in x.replace("[",'').replace("]",'').replace('\'','').split(',')])))

    dataset_df = dataset_df.explode('irods_datafilePath').reset_index(drop=True).rename(columns={"Sample Name Alias":"sampleAlias","irods_datafilePath":"datafilePath"})
    dataset_df.to_csv(output.dataset, index=False, sep=';')
    
    
parser = argparse.ArgumentParser()
parser.add_argument('--bilan')
parser.add_argument('--variant')
parser.add_argument('--sheet')
parser.add_argument('--dataset')
parser.add_argument('--batch', type=int)
parser.add_argument('--out')

input  = parser.parse_args()
output = parser.parse_args()
params = parser.parse_args()
log    = parser.parse_args()

# logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.DEBUG)
logging.basicConfig(filename=log.out, level=logging.DEBUG)

logging.info(f"input.bilan: {input.bilan}")
logging.info(f"input.variant: {input.variant}")
logging.info(f"input.sheet: {input.sheet}")
logging.info(f"output.dataset: {output.dataset}")
logging.info(f"params.batch: {params.batch}")
logging.info(f"log.out: {log.out}")

main(input, output, params)

