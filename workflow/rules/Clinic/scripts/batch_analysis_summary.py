import os
import re
import sys
import argparse
import pandas as pd

def match_normal(sample_names):
    parttern = re.compile("^([A-Z0-9-_]+)+N[0-9]_DNA[0-9]*$")
    for s in sample_names:
        if parttern.match(s):
            return 'done'
    return ''

def match_tumor(sample_names):
    parttern = re.compile("^([A-Z0-9-_]+)+T[0-9]_DNA[0-9]*$")
    for s in sample_names:
        if parttern.match(s):
            return 'done'
    return ''
def match_rna(sample_names):
    parttern = re.compile("^([A-Z0-9-_]+)+T[0-9]_RNA[0-9]*$")
    for s in sample_names:
        if parttern.match(s):
            return 'done'
    return ''

def match_biopsy_id(biopsy_ids):
    parttern = re.compile("^([A-Z0-9-_]+)+\_T[0-9]*$")
    for s in biopsy_ids:
        if parttern.match(s):
            return s

def match_cna(alt_ctgs):
    for c in ['Amplification', 'Deletion']:
        if c in alt_ctgs:
            return 'yes'
    return ''

def match_mut(alt_ctgs):
    for c in [ 'Del', 'Fusion', 'Ins', 'Mut']:
        if c in alt_ctgs:
            return 'yes'
    return ''

def match_fus(alt_ctgs):
    for c in ['Fusion']:
        if c in alt_ctgs:
            return 'yes'
    return ''

# parser = argparse.ArgumentParser()
# parser.add_argument('--bilan')
# parser.add_argument()

bilan_fn = "config/bilan.xlsx"
muts_fn  = "aggregated_alterations.xlsx"
summary_fn = "batch_analysis_summary.tsv"

bilan_df = pd.read_excel(bilan_fn)
muts_df = pd.read_excel(muts_fn)

analysis_table = []

for k, grp in bilan_df[bilan_df['Batch'].map(lambda x: x in [17,18])].groupby(['PATIENT_ID ','Project_TCGA_More', 'MSKCC', 'Batch']):
    sample_names = grp['*Sample \nName'].tolist()
    biopsy_names = grp['*Biopsy ID'].tolist()
    analysis_table.append([*k,match_biopsy_id(biopsy_names),match_normal(sample_names),match_tumor(sample_names),match_rna(sample_names)])

analysis_df = pd.DataFrame(analysis_table, columns=['PID','TCGA','MSK','Batch','Sample','DNA_T','DNA_N', 'RNA'])
    
find_alt_table = []

for k, grp in muts_df[['*Biopsy ID', 'Alteration_Category']].groupby('*Biopsy ID'):
    alt_ctgs = grp['Alteration_Category'].tolist()
    # k = '_'.join(k.split('_')[:-1])
    find_alt_table.append([k, match_fus(alt_ctgs), match_cna(alt_ctgs), match_mut(alt_ctgs)])

find_alt_df = pd.DataFrame(find_alt_table, columns=['Sample', 'Driver_fusion','Driver_SCNA','Driver_Mut'])

final_table = analysis_df.join(find_alt_df.set_index('Sample'), on='Sample', how = 'left').fillna('')
final_table['No_drivers'] = final_table.apply(lambda x: 'yes' if 'yes' not in set(x[['Driver_fusion','Driver_SCNA','Driver_Mut']]) else '' , axis=1)

final_table.to_csv(summary_fn, sep='\t', index=False)
