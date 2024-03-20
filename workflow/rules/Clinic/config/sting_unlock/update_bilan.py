import re
import sys
import string
import logging
import argparse
# import numpy as np
import pandas as pd

bilan_columns=['PATIENT_ID ', 'numb_ID', 'Project_TCGA_More', 'MSKCC','*Nucleic Acid Type', '*Biopsy ID', '*Sample \nName',
               '*Tissue Type \n(eg: Root, Blood. Germ source.)', 'Batch', 'n°Histo','File name', 'NIP', 'Sex', 'Driver',
               'Traitement', 'DATE BIOPSIE','Baseline=B, Suivi=S, \nProgression=P', 'COMENTAIRES','Sample Name Alias',
               'IRODS Sample Alias', 'irods_sampleId', 'irods_patientId', 'irods_datafilePath']

def check_bilan_table(bilan_df):

    valid = True
    
    def _not_valid():
        valid = False

    def _check_enumerate_type(coln, enum_set):
        if len(set(bilan_df[coln])) != 2 :
            for idx, row in bilan_df[~bilan_df[coln].map(lambda x: x in enum_set )].iterrows():
                tt = row[coln] 
                logging.error(f"{coln} for patient {row['PATIENT_ID ']} is {tt}, not in {enum_set} ")
            _not_valid()

    # check bilan table 0: check column names :
    def _check_col_names():

        for cn in bilan_columns :
            if cn not in bilan_df.colmns:
                logging.error(f"bilan table doesn't contain the columns of {cn}")
                _not_valid()
    
    # check bilan table 1. '*Sample Name' match the pattern ?
    def _check_sample_name():
        pttn1 = re.compile("^[NT][0-9]$")
        pttn2 = re.compile("^[DR]NA[0-9]*$")
        check1_df = bilan_df[bilan_df.apply(lambda x : x['*Sample \nName'].split('_')[0] != x['PATIENT_ID ']
                                            or not pttn1.match(x['*Sample \nName'].split('_')[1])
                                            or not pttn2.match(x['*Sample \nName'].split('_')[2]), axis=1)]
        
        if len(check1_df) > 0 :
            logging.error('\t'+ check1_df.to_string().replace('\n', '\n\t'))
            _not_valid()

    # check bilan table 2. *Biopsy ID' match '*Sample Name' ?
    def _check_biopsyID_match_SampleName():
        check2_df = bilan_df[bilan_df.apply(lambda x : x['*Biopsy ID'] != '_'.join(x['*Sample \nName'].split('_')[:2]), axis=1)][['*Biopsy ID', '*Sample \nName']]
        if len(check2_df) > 0 :
            logging.error('\t'+ check2_df.to_string().replace('\n', '\n\t'))
            _not_valid()

    # check bilan table 3. NIP has empty value ? 
    def _check_NIP_has_NA():
        if bilan_df['NIP'].isna().sum() > 0 :
            logging.error(f"bilan table has empty value in the column of NIP")
            _not_valid()

    # check bilan table 4. batch is not empty and is an integer 
    def _check_batch_is_int():
        if bilan_df['Batch'].isna().sum() > 0 :
            logging.error(f"bilan table has empty value in the column of Batch")
            _not_valid()

        if bilan_df['Batch'].dtype != int :
            logging.error(f"data type of Batch in bilan table is not int. ")
            _not_valid()

    # check bilan table 5: Tissue Type ['Tumor', 'Cell blood'] 
    def _check_tissue_type():
        if bilan_df['*Tissue Type \n(eg: Root, Blood. Germ source.)'].isna().sum() > 0 :
            logging.error(f"bilan table has empty value in the column of Tissue Type")
            _not_valid()

        coln = '*Tissue Type \n(eg: Root, Blood. Germ source.)'
        enum_set = ['Tumor', 'Cell blood']
        _check_enumerate_type(coln, enum_set)

    # check bilan table 6: nHisto doesnt't has empty value 
    def _check_histo_has_NA():
        if bilan_df['n°Histo'].isna().sum() > 0 :
            logging.error(f"bilan table has empty value in the column of Histo")
            _not_valid()

    # check if DATE BIOPSIE doesn't has empty value 
    def _check_date_biopsie():
        if bilan_df['DATE BIOPSIE'].isna().sum() > 0 :
            logging.error(f"bilan table has empty value in the column of Date Biopsie")
            _not_valid()

    # check if *Nucleic Acid Type has only values of Genomic DNA and Total RNA 
    def _check_nucleic_acid_type():
        if bilan_df['*Nucleic Acid Type'].isna().sum() > 0 :
            logging.error(f"bilan table has empty value in the column of Nucleic Acid Type.")
            _not_valid()

        coln = '*Nucleic Acid Type'
        enum_set = ['Genomic DNA', 'Total RNA']
        _check_enumerate_type(coln, enum_set)

    def _is121(df, col1, col2):
        return df.groupby(col1)[col2].count().max() + df.groupby(col2)[col1].count().max() == 2

    # check if Patient_ID ~ NIP 121
    def _check_PID_121_NIP():
        for idx, grp in bilan_df.groupby('NIP'):
            if len(set(grp['PATIENT_ID '])) > 1 :
                logging.error(f"NIP {idx} corresponds to more than one patient : {set(grp['PATIENT_ID '])}")
                _not_valid()

        for idx, grp in bilan_df.groupby('PATIENT_ID '):
            if len(set(grp['NIP'])) > 1 :
                logging.error(f"Patient {idx} has more than one NIP : {set(grp['NIP'])}")
                _not_valid()

    # check if nHisto match Tissue Type
    def _check_histo_match_tissue_type():
        tt_cln = '*Tissue Type \n(eg: Root, Blood. Germ source.)'
        histo_cln = 'n°Histo'
        
        if len(set(bilan_df[bilan_df[tt_cln] == 'Cell blood'][histo_cln])) > 1:
            logging.error(f"Some tissue type of Cell blood doesn't match to histo Blood")
            _not_valid()

        if len(set(bilan_df[bilan_df[histo_cln] != 'Blood'][tt_cln])) > 1:
            logging.error(f"Some histo tumor doesn't match to tissue type of tumor")
            _not_valid()
        
    # _check_sample_name()
    # _check_biopsyID_match_SampleName()
    _check_NIP_has_NA()
    _check_batch_is_int()
    _check_tissue_type()
    _check_histo_has_NA()
    _check_date_biopsie()
    _check_nucleic_acid_type()
    _check_PID_121_NIP()
    _check_histo_match_tissue_type()
    
    if not valid: 
        raise Exception("bilan table viloate the convention. please double check the table")

# generate new columns in bilan table :
# 1. *Sample \nName 
# 2. *Biopsy ID
# 3. Sample Name Alias - naming the samples in pipeline analysis, will be replaced by '*Sample \n Name' after all
def update_sample_name_alias(bilan_df):
    # NIP is the unique reference for patient,
    # NOIGR is used as UUID for patient
    bilan_df['Alias:NOIGR']  = bilan_df['NIP'].map(lambda x: x.strip().replace('-','').replace(' ', ''))
    bilan_df['Tissue Alias'] = bilan_df['*Tissue Type \n(eg: Root, Blood. Germ source.)'].map(lambda x: 'T' if x == 'Tumor' else 'N')
    bilan_df['Nucleic Acid Type Alias'] = bilan_df['*Nucleic Acid Type'].map(lambda x: x.split(' ')[-1])
    
    bilan_df['Resent'] = 0
    bilan_df['Biopsy_Num'] = 0

    # for each patient 
    for noigr_idx, noigr_grp in bilan_df.groupby('Alias:NOIGR'):
        # for each type of sample: Tumor, Normal, RNAseq
        for type_idx, type_grp in noigr_grp.groupby(['*Nucleic Acid Type', '*Tissue Type \n(eg: Root, Blood. Germ source.)']):
            # number of biopsy refer to the number of tumor, normal and rna
            # the order of tumor relate to the order of time 
            biopsy_list = list(set(type_grp['DATE BIOPSIE']))
            biopsy_list.sort() # order by increase
            biopsy_num_dict = { biopsy_list[i]: i+1 for i in range(len(biopsy_list)) }

            # for each biopsy
            for biopsy_idx, biopsy_grp in type_grp.groupby('DATE BIOPSIE'):
                biopsy_num = biopsy_num_dict[biopsy_idx]
                for resent_idx in range(len(biopsy_grp.index)) :
                    # resent will be different within a same DATE BIOPSIE
                    bilan_df.at[biopsy_grp.index[resent_idx], 'Resent'] = resent_idx + 1
                    # biopsy number refer to different DATE BIOPSIE
                    bilan_df.at[biopsy_grp.index[resent_idx], 'Biopsy_Num'] = biopsy_num

    bilan_df['Resent'] = bilan_df['Resent'].map(lambda x : x if x > 1 else '')

    bilan_df['*Sample \nName'] = bilan_df.apply(lambda x: f"{x['PATIENT_ID ']}_{x['Tissue Alias']}{x['Biopsy_Num']}_{x['Nucleic Acid Type Alias']}{x['Resent']}", axis=1)
    bilan_df['*Biopsy ID']     = bilan_df.apply(lambda x: f"{x['PATIENT_ID ']}_{x['Tissue Alias']}{x['Biopsy_Num']}", axis=1)

    bilan_df['Sample Type Alias'] = bilan_df.apply(lambda x: 'R' if x['*Nucleic Acid Type'] == 'Total RNA' else x['Tissue Alias'], axis = 1)
    bilan_df['Biopsy Num Alias'] = bilan_df.apply(lambda x : '' if x['Biopsy_Num'] == 1 and x['Resent'] == '' else string.ascii_uppercase[x['Biopsy_Num']-1], axis=1)
    bilan_df['Sample Name Alias'] = bilan_df.apply(lambda x : f"{x['PATIENT_ID '].replace(' ','').replace('-','').replace('_','')}{x['Biopsy Num Alias']}{x['Resent']}_{x['Sample Type Alias']}", axis = 1)

    return bilan_df[bilan_columns]

def update_dateset_to_bilan(dataset_df, bilan_df):
    dataset_pt = dataset_df[~dataset_df['Alias:STING sample number'].isna()].pivot_table(values='datafilePath', index=['patientId','sampleId','Alias:STING sample number'], aggfunc=lambda x: ','.join(x)).reset_index()
    join_df = bilan_df.join(dataset_pt.set_index('Alias:STING sample number'), on='IRODS Sample Alias')
    
    bilan_df['irods_datafilePath'] = join_df['irods_datafilePath'].combine_first(join_df['datafilePath'])
    bilan_df['irods_patientId'] = join_df['irods_patientId'].combine_first(join_df['patientId'])
    bilan_df['irods_sampleId']  = join_df['irods_sampleId'].combine_first(join_df['sampleId'])

    return bilan_df

def main(input, output, params):
    
    bilan_df   = pd.read_excel(input.bilan)
    dataset_df = pd.read_table(input.dataset, sep=';', header=0)

    strip_cols = ['PATIENT_ID ', 'Project_TCGA_More', 'MSKCC','*Nucleic Acid Type', '*Biopsy ID', '*Sample \nName',
                  '*Tissue Type \n(eg: Root, Blood. Germ source.)', 'NIP', 'Sex', 'Baseline=B, Suivi=S, \nProgression=P']

    # strip all columns of type string
    for cln in strip_cols:
        bilan_df[cln] = bilan_df[cln].map(lambda x : x.strip())

    if 'irods_datafilePath' not in bilan_df.columns:
        bilan_df['irods_datafilePath'] = float('nan')
        
    if 'irods_patientId' not in bilan_df.columns:
        bilan_df['irods_patientId']    = float('nan')
        
    if 'irods_sampleId' not in bilan_df.columns:
        bilan_df['irods_sampleId']     = float('nan')
        
    # check if the table meet the convention or has any error
    logging.info("Starting to check the table : {input.bilan}")
    check_bilan_table(bilan_df)
    logging.info("{input.bilan} is checked. Everything is fine.")

    # update '*Biopsy ID', '*Sample \nName' and 'Sample Name Alias'
    logging.info("building new columns of Sample Name Alias")
    bilan_df = update_sample_name_alias(bilan_df)

    # update irods_patientId, irods_sampleId, irods_datafilePath
    bilan_df = update_dateset_to_bilan(dataset_df, bilan_df)
    
    # save bilan table to excel
    logging.info("Saving to excel file : {output.rebuild}")
    # bilan_df.to_csv(output.rebuild, sep='\t', index=False)
    bilan_df.to_excel(output.rebuild, index=False)

parser = argparse.ArgumentParser(description='inputs from the rule')
parser.add_argument('--bilan')
parser.add_argument('--dataset')
parser.add_argument('--rebuild')
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
logging.info(f"output.rebuild: {output.rebuild}")
logging.info(f"params.batch: {params.batch}")
logging.info(f"log.out: {log.out}")

main(input, output, params)
