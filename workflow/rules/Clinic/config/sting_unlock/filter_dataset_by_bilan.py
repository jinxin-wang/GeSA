import re
import sys
import string
import logging
import argparse
import pandas as pd

def main(input, output, params):

    bilan_df   = pd.read_excel(input.bilan)
    # bilan_df   = pd.read_table(input.bilan, sep='\t', header=0)
    dataset_df = pd.read_table(input.dataset, header=0, sep=';')

    # generate the set of NIP in bilan table in current batch 
    # NIP_set    = set(bilan_df[bilan_df["Batch"] == params.batch]["NIP"].map(lambda x : x.strip().replace(' ','').replace('-','')))

    # keep the samples in dataset matched NIP
    # dataset_df = dataset_df[dataset_df['Alias:NOIGR'].map(lambda x: x in NIP_set)].reset_index(drop=True)

    # keep only vivo samples, exclude vitro samples 'cell line'
    dataset_df = dataset_df[dataset_df['sampleType'].map(lambda x: x in ['healthy', 'tumor'])].reset_index()

    # drop 'Alias:STING sample number' is empty
    dataset_df = dataset_df[~dataset_df['Alias:STING sample number'].isna()].reset_index()

    logging.info(dataset_df)
    
    #### check if the samples in the current batch are all matched
    dataset_pivot = dataset_df.pivot_table(values='datafilePath', index=['Alias:STING sample number', 'sampleId', 'patientId'], aggfunc=list).reset_index()
    logging.info(dataset_pivot)
    
    #  keep only the new received sample 
    dataset_aggr_df = dataset_pivot.groupby('Alias:STING sample number').agg({'sampleId':'max', 'datafilePath': lambda x: x}).reset_index()
    logging.info(dataset_aggr_df)
    
    #  match by bilan table ~ 'IRODS Sample Alias'
    joined_df = bilan_df[bilan_df['Batch']==params.batch].join(dataset_aggr_df.set_index('Alias:STING sample number'), on='IRODS Sample Alias')
    # joined_df = bilan_df[bilan_df['Alias:NOIGR'].map(lambda x: x in NIP_set)].join(dataset_aggr_df.set_index('Alias:STING sample number'), on='IRODS Sample Alias')
    logging.info(joined_df)
    
    if sum(joined_df['sampleId'].isna()) > 0 :
        for sn in joined_df[joined_df['sampleId'].isna()]['*Sample \nName']:
            logging.error(f"The sample {sn} is not found in iRODS dataset table {input.dataset}.")
        raise Exception(f"Samples are missing in IRODS dataset.")

    sampleId_list = list(joined_df['sampleId'])

    logging.info(sampleId_list)
    
    # check if every tumor/normal has a paris :
    for idx, patient_gr in bilan_df[bilan_df['Batch']==params.batch].groupby('PATIENT_ID '):
        # find a normal sample in the dataset table if there is no cell blood sample. 
        if sum(patient_gr['*Tissue Type \n(eg: Root, Blood. Germ source.)'] == 'Cell blood') == 0 :
            logging.warning(f"Patient {idx} has no blood sample as control. ")
            sampleIds = set(dataset_df[(dataset_df['Alias:STING inclusion number'] == idx) & (dataset_df['sampleType'] == 'healthy')]['sampleId'])
            if len(sampleIds) > 0 :
                # take the new one
                logging.info(f"choose {max(sampleIds)} among {sampleIds} as Cell blood sample for patient {idx}.")
                sampleId_list.append(max(sampleIds))
            else:
                logging.error(f"The normal sample for patient {idx} is missing in the iRODS dataset table. ")
                raise Exception(f"Normal samples are missing in IRODS dataset.")

        # find a normal sample in the dataset table if there is no cell blood sample. 
        if sum(patient_gr['*Tissue Type \n(eg: Root, Blood. Germ source.)'] == 'Tumor') == 0 :
            logging.warning(f"Patient {idx} has no tumor sample as test. ")
            sampleIds = set(dataset_df[(dataset_df['Alias:STING inclusion number'] == idx) & (dataset_df['sampleType'] == 'tumor') & (dataset_df['biologicalCategory'] == 'genomics') ]['sampleId'])
            if len(sampleIds) > 0 :
                # take the new one
                logging.info(f"choose {max(sampleIds)} among {sampleIds} as tumor sample for patient {idx}.")
                sampleId_list.append(max(sampleIds))
            else:
                logging.error(f"The tumor sample for patient {idx} is missing in the iRODS dataset table. ")
                raise Exception(f"tumor samples are missing in IRODS dataset.")

    matched_df = dataset_df[dataset_df['sampleId'].map(lambda x : x in sampleId_list)].reset_index(drop=True)
    logging.info(matched_df)

    alias_dict = { row['IRODS Sample Alias']:row['Sample Name Alias'] for idx,row in bilan_df.iterrows() }
    logging.info(alias_dict)
    
    matched_df['sampleAlias'] = matched_df['Alias:STING sample number'].map(lambda x : alias_dict[x])
    logging.info(matched_df)
    
    if sum(matched_df['sampleAlias'].isna()) > 0 :
        for idx, row in matched_df[matched_df['sampleAlias'].isna()].iterrows():
            logging.error(f"{row['IRODS Sample Alias']} is not able to match a sample name alias.")
        raise Exception("Missing sample name alias")

    # save the table
    matched_df.to_csv(output.filtered_dataset,  sep=';', index=False)

parser = argparse.ArgumentParser()
parser.add_argument('--bilan')
parser.add_argument('--dataset')
parser.add_argument('--filtered_dataset')
parser.add_argument('--batch', type=int)
parser.add_argument('--out')

input  = parser.parse_args()
output = parser.parse_args()
params = parser.parse_args()
log    = parser.parse_args()

# logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.DEBUG)
logging.basicConfig(filename=log.out, level=logging.DEBUG)

logging.info(f"input.bilan: {input.bilan}")
logging.info(f"input.dataset: {input.dataset}")
logging.info(f"output.filtered_dataset: {output.filtered_dataset}")
logging.info(f"params.batch: {params.batch}")
logging.info(f"log.out: {log.out}")

main(input, output, params)

