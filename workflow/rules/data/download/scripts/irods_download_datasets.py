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

    bilan = str(input.bilan)
    exten = bilan.strip().split(".")[-1]
    bilan_df  = None

    dtypes = {COLUMN_DATASETS: str}

    if exten == "tsv" : 
        logging.info(f"identify the format of input file is tsv: {input.bilan}")
        bilan_df = pd.read_table(bilan, sep="\t", dtype=dtypes, keep_default_na=False)
    elif exten == "csv" : 
        logging.info(f"identify the format of input file is csv: {input.bilan}")
        bilan_df = pd.read_table(bilan, sep=",",  dtype=dtypes, keep_default_na=False)
    else:
        logging.warning(f"Unable to identify the format of input file: {input.bilan}")
        raise Exception(f"Unable to identify the format of input file: {input.bilan}")

    bilan_df[COLUMN_DATASETS] = bilan_df[COLUMN_DATASETS].map(lambda x: x.strip().split(SEP_DATASETS) if len(x) > 0 else [])
    logging.debug(f"{bilan_df[COLUMN_DATASETS]}")

    for idx, row in bilan_df.iterrows():
        save_to_dir = Path(f"{str(output.path)}/{row[params.qkey]}")
        download_datasets(datasets = row[COLUMN_DATASETS], save_to_dir = save_to_dir)


# input:
#     bilan = "config/datasets_query_bilan.tsv",
# output:
#     path = directory(config["STORAGE_PATH"]),
# params:
#     qkey = config["iRODS_BILAN_QUERY_KEY"],

parser = argparse.ArgumentParser(description='inputs from the rule')
parser.add_argument('--bilan')
parser.add_argument('--path')
parser.add_argument('--qkey')

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

logging.info(f"input.bilan: {input.bilan}")

logging.info(f"output.path: {output.path}")

logging.info(f"params.qkey: {params.qkey}")
logging.info(f"log.out: {log.out}")

main(input, output, params)
