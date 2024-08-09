import re
import sys
import string
import logging
import argparse
import pandas as pd

def main(input, output, params):

    bilan_df   = pd.read_excel(input.bilan)
    dataset_df = pd.read_table(input.dataset, header=0, sep=';')

    dataset_df = dataset_df[(dataset_df['biologicalApplication'] == 'raw genomics') | (dataset_df['biologicalCategory'] == 'genomics')]

    logging.info(dataset_df)

    dataset_pivot = dataset_df.pivot_table(values='datafilePath', index=['Alias:STING sample number'], aggfunc=list)

    logging.info(dataset_pivot)

    joined_df  = bilan_df[bilan_df['Batch'] == params.batch].join(dataset_pivot, on='IRODS Sample Alias')
    logging.info(joined_df)

    genomic_df = joined_df[(~joined_df['irods_datafilePath'].isna()|~joined_df['datafilePath'].isna()) & (joined_df['*Nucleic Acid Type'] == 'Genomic DNA') ]

    logging.info(genomic_df)
    
    variant_call_table = []
    for idx, patient_gr in genomic_df.groupby('PATIENT_ID '):
        logging.info(f"PATIENT_ID: {idx}")
        normal = patient_gr['*Tissue Type \n(eg: Root, Blood. Germ source.)'] == 'Cell blood'
        tumor  = patient_gr['*Tissue Type \n(eg: Root, Blood. Germ source.)'] == 'Tumor'
        
        logging.info(f"normal: {patient_gr[normal]['*Biopsy ID']}")
        logging.info(f"tumor: {patient_gr[tumor]['*Biopsy ID']}")

        if sum(normal) == 0:
            logging.warning(f"{idx} doesn't have a normal sample. ")
            ns = bilan_df[(bilan_df['PATIENT_ID ']==idx) & (bilan_df['*Nucleic Acid Type']=='Genomic DNA') & (bilan_df['*Tissue Type \n(eg: Root, Blood. Germ source.)'] == 'Cell blood')].index
            n  = bilan_df.at[max(ns),'Sample Name Alias']
            for t in patient_gr[tumor]['Sample Name Alias']:
                logging.warning(f"Patient {idx}: set {t} ~ {n} as a pair, please check if it is correct.")
                variant_call_table.append([t,n])
                
        elif sum(tumor) == 0:
            logging.warning(f"{idx} doesn't have a tumor sample. ")
            ts = bilan_df[(bilan_df['PATIENT_ID ']==idx) & (bilan_df['*Nucleic Acid Type']=='Genomic DNA') & (bilan_df['*Tissue Type \n(eg: Root, Blood. Germ source.)'] == 'Tumor')].index
            t  = bilan_df.at[max(ns),'Sample Name Alias']
            for n in patient_gr[tumor]['Sample Name Alias']:
                logging.warning(f"Patient {idx}: set {t} ~ {n} as a pair, please check if it is correct.")
                variant_call_table.append([t,n])

        elif sum(normal) == sum(tumor) :
            for p in list(zip(patient_gr[tumor]['Sample Name Alias'],list(patient_gr[normal]['Sample Name Alias']))):
                variant_call_table.append([p[0],p[1]])

        else :
            logging.warning(f"{idx} has more than one normal sample, but not sure about the pairs, please check the variant call table and choose the correct one. ")
            normals = '/'.join(list(patient_gr[normal]['Sample Name Alias']))
            for t in patient_gr[tumor]['Sample Name Alias']:
                variant_call_table.append([t,normals])                    

    pd.DataFrame(variant_call_table).to_csv(output.variant, header=None, index=False, sep='\t')


parser = argparse.ArgumentParser(description='inputs from the rule')
parser.add_argument('--bilan')
parser.add_argument('--dataset')
parser.add_argument('--batch', type=int)
parser.add_argument('--variant')
parser.add_argument('--out')

input  = parser.parse_args()
output = parser.parse_args()
params = parser.parse_args()
log    = parser.parse_args()

# logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.DEBUG)
logging.basicConfig(filename=log.out, level=logging.DEBUG)

logging.info(f"input.bilan: {input.bilan}")
logging.info(f"input.dataset: {input.dataset}")
logging.info(f"params.batch: {params.batch}")
logging.info(f"output.variant: {output.variant}")
logging.info(f"log: {log.out}")

main(input, output, params)

