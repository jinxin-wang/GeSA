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

    exten = str(input.meta).strip().split(".")[-1]
    meta_df = None

    dtypes = {COLUMN_DATASETS: str}

    if exten == "tsv" : 
        logging.info(f"identify the format of input file is tsv: {input.meta}")
        meta_df = pd.read_table(input.meta, sep="\t", dtype=dtypes, keep_default_na=False)
    elif exten == "csv" : 
        logging.info(f"identify the format of input file is csv: {input.meta}")
        meta_df = pd.read_table(input.meta, sep=";",  dtype=dtypes, keep_default_na=False)
    elif exten == "xlsx"
        logging.info(f"identify the format of input file is excel: {input.meta}")
        meta_df = pd.read_excel(input.meta)
    else:
        logging.warning(f"Unable to identify the format of input file: {input.meta}")
        raise Exception(f"Unable to identify the format of input file: {input.meta}")

    for idx, row in meta_df.iterrows():
        logging.info(f"sample id: {row[str(params.sid)]}")
        save_to_dir = Path(output.opath).joinpath(row[str(params.sid)])
        logging.info(f"saving to dir {save_to_dir}")
        download_to_dir(row[params.cpath], save_to_dir)

parser = argparse.ArgumentParser(description='inputs from the rule')
parser.add_argument('--meta')
parser.add_argument('--opath')
parser.add_argument('--sid')
parser.add_argument('--cpath') 

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

logging.info(f"input.meta: {input.meta}")

logging.info(f"output.path: {output.opath}")

logging.info(f"params.sid: {params.sid}")
logging.info(f"params.path: {params.cpath}")
logging.info(f"log.out: {log.out}")

main(input, output, params)
