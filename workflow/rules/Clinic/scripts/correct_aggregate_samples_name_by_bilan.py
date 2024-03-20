import os
import sys
import pandas as pd

sys.path.append(os.path.abspath("/mnt/beegfs/userdata/j_wang/pipelines/dna_routine_pipeline/workflow/rules/Clinic/config/scripts"))

from match import match_civic2

agg_all_df = pd.read_table("aggregated_alterations_all.tsv", sep='\t', header=0)
agg_df = pd.read_table("aggregated_alterations.tsv", sep='\t', header=0)
bilan_df = pd.read_excel("config/bilan.xlsx")

def correct_aggr_table(df, bilan_df):
    colns = df.columns.to_list()
    colns.remove('Sample_Id')
    colns.remove('Subject_Id')
    colns.remove('Tumor_Type')
    colns.remove('MSKCC_Oncotree')
    
    df["tumor_sample_alias"] = df["Sample_Id"].map(lambda x : x.split('_vs_')[0])
    ndf = df.join(bilan_df[['PATIENT_ID ', '*Biopsy ID', '*Sample \nName','Project_TCGA_More', 'MSKCC','Sample Name Alias']].set_index('Sample Name Alias'), on='tumor_sample_alias').reset_index()

    corresp_df = pd.read_excel("/mnt/beegfs/scratch/j_wang/03_Results/STING_UNLOCK/20240221_human_aggregate_batch5/workflow/resources/Table_Correspondence_Tumor_Type.xlsx")

    ndf['Civic_Disease'] = ndf.apply(lambda x : match_civic2(x['PATIENT_ID '], x['MSKCC'], x['Project_TCGA_More'], corresp_df), axis=1)
    colns = ['PATIENT_ID ', '*Biopsy ID', '*Sample \nName', 'Project_TCGA_More', 'MSKCC'] + colns
    return ndf[colns]


correct_agg_all_df = correct_aggr_table(agg_all_df, bilan_df)
correct_agg_df     = correct_aggr_table(agg_df, bilan_df)

correct_agg_all_df.to_excel("aggregated_alterations_all.xlsx", index=False)
correct_agg_df.to_excel("aggregated_alterations.xlsx", index=False)
