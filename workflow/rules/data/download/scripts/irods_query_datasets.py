import os
import sys
import string
import logging
import argparse
import pandas as pd

sys.path.append(os.path.abspath("/mnt/beegfs/userdata/j_wang/pipelines/dna_routine_pipeline/workflow/rules/data/download/scripts"))

from libIRODS import * 

def main(input, output, params):
    logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.INFO)

    if sys.version_info.major < 3:
        logging.warning("require python3, current python version: %d.%d.%d"%(sys.version_info[0], sys.version_info[1], sys.version_info[2]))

    bilan = str(input.ibilan)
    exten = bilan.strip().split(".")[-1]
    bilan_df  = None

    if exten == "tsv" :
        logging.info(f"identify the format of input file is tsv: {input.ibilan}")
        bilan_df = pd.read_table(bilan, sep="\t")

    elif exten == "csv" : 
        logging.info(f"identify the format of input file is csv: {input.ibilan}")
        bilan_df = pd.read_table(bilan, sep=";")

    else:
        logging.warning(f"Unable to identify the format of input file: {input.ibilan}")
        raise Exception(f"Unable to identify the format of input file: {input.ibilan}")

    bilan_df[COLUMN_DATASETS] = [ set([]) for i in range(len(bilan_df.index)) ]

    for project_name in params.project_names:
        if len(project_name.strip()) > 0 :
            bilan_df = query_by_key(df = bilan_df, pname  = project_name,
                                    df_key = params.bilan_query_key,
                                    ds_key = params.dataset_query_key)


        if len(project_name.strip()) > 0 and len(params.bilan_cquery_keys) > 0 and len(params.dataset_cquery_keys) > 0 :
            bilan_df = query_by_keys(df = bilan_df, pname  = project_name,
                                              df_key = params.bilan_query_key,
                                              ds_key = params.dataset_query_key,
                                              df_gp_keys = params.bilan_cquery_keys,
                                              ds_gp_keys = params.dataset_cquery_keys)

    bilan_df[COLUMN_DATASETS] = bilan_df[COLUMN_DATASETS].map(lambda x: SEP_DATASETS.join(x))
    bilan_df.to_csv(output.obilan, sep="\t", index=False)

 # input:
 #     ibilan = config["iRODS_sample_bilan"],
 # output:
 #     obilan = "config/datasets_query_bilan.tsv",
 # params:
 #     project_names  = config["PROJECT_NAMES"],
 #     bilan_query_key  = config["iRODS_BILAN_QUERY_KEY"],
 #     dataset_query_key= config["iRODS_DATASET_QUERY_KEY"],
 #     bilan_cquery_keys   = config["iRODS_bilan_cquery_keys"],
 #     dataset_cquery_keys = config["iRODS_dataset_cquery_keys"],

parser = argparse.ArgumentParser(description='inputs from the rule')
parser.add_argument('--ibilan')
parser.add_argument('--obilan')
parser.add_argument('--project_names')
parser.add_argument('--bilan_query_key')
parser.add_argument('--dataset_query_key')
parser.add_argument('--bilan_cquery_keys')
parser.add_argument('--dataset_cquery_keys')

# log.out
parser.add_argument('--out')

input  = parser.parse_args()
output = parser.parse_args()
params = parser.parse_args()
log    = parser.parse_args()

if sys.version_info.major < 3:
    logging.warning(f"require python3, current python version: {sys.version_info[0]}.{sys.version_info[1]}.{sys.version_info[2]}")
        
# logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.DEBUG)
logging.basicConfig(filename=log.out, level=logging.DEBUG)

logging.info(f"input.meta: {input.ibilan}")

logging.info(f"output.path: {output.obilan}")

logging.info(f"params.project_names: {params.project_names}")
logging.info(f"params.bilan_query_key: {params.bilan_query_key}")
logging.info(f"params.dataset_query_key: {params.dataset_query_key}")
logging.info(f"params.bilan_cquery_keys: {params.bilan_cquery_keys}")
logging.info(f"params.dataset_cquery_keys: {params.dataset_cquery_keys}")

logging.info(f"log.out: {log.out}")

main(input, output, params)
