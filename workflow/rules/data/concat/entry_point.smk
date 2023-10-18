import os
import sys
import glob
import logging
import pandas as pd
from pathlib import Path

configfile: "workflow/config/concat.yaml"
    
def is_match(r1: str, r2: str):

    read1, read2, flag = [*r1], [*r2], True

    for c1, c2 in zip(read1, read2):
        if c1 == c2 :
            continue

        elif c1 == "1" and c2 == "2" and flag:
            ## only difference should be 1 and 2, only once 
            flag = False
        else:
            return False

    return True

def is_all_match(r1_list, r2_list):
    
    if len(r1_list) != len(r2_list):
        logging.error(f"matched list of R1 and R2 do NOT have same number of files.")
        logging.error(f"list of R1: \n%s"%("\n".join(r1_list)))
        logging.error(f"list of R2: \n%s"%("\n".join(r2_list)))

    for r1,r2 in zip(r1_list, r2_list):
        logging.info("Read 1 -- Read 2 pair:")
        logging.info("R1: %s "%(r1))
        logging.info("R2: %s "%(r2))
        
        if not is_match(r1, r2):
            logging.error(f"R1: \n%s"%("\n".join(r1_list)))
            logging.error(f"R2: \n%s"%("\n".join(r2_list)))
            raise Exception("R1 and R2 are NOT in corresponding order")
        
    return True

def do_concat(fastq_list, concat_dir, sample_id, read12):

    concat_cmd = " ".join(["cat"] + fastq_list +
                          [">", "%s/%s_%s.fastq.gz"%(concat_dir,sample_id, read12)])
    
    logging.info(f"concat %s R%s: \n%s"%(sample_id, read12, concat_cmd))
    os.system(concat_cmd)
    logging.info("concat %s R%s done."%(sample_id, read12))

def do_softlink(fastq_file, concat_dir, sample_id, read12):

    softlink_cmd = f"ln -s {fastq_file} {concat_dir}/{sample_id}_{read12}.fastq.gz"
    
    logging.info(f"softlink %s R%s: \n%s"%(sample_id, read12, softlink_cmd))
    os.system(softlink_cmd)
    logging.info("softlink %s R%s done."%(sample_id, read12))


# rule softlink_to_concat_fastq:
#     input:
#         fastq = expand(config["concat_fastq_dir"] + "/{sample}_{read}.fastq.gz", sample = SAMPLES, read = config["reads"]),
#     output:
#         targets = expand("DNA_samples/{sample}_{read}.fastq.gz", sample = SAMPLES, read = config["reads"]),
#     params:
#         queue = "shortq",
#     threads: 1
#     resources: 
#         mem_mb = 5120
#     shell:
#         "ln -s {input.fastq} DNA_samples/ ;"


samples_df = pd.read_csv(config["sample_list"], sep="\t", header=None)
SAMPLES = []

for col_idx in range(len(samples_df.columns)):
    SAMPLES = list(set(samples_df.iloc[:, col_idx].tolist() + SAMPLES))

print(config["raw_fastq_dir"])

# if config["do_concat"]:
if os.path.isfile(config["sample_sheet"]) :
    include: "concat_samplesheet.smk"
    
elif os.path.isdir(config["raw_fastq_dir"]) :
    include: "concat_src_dir.smk"
    
else:
    raise Exception("Missing rample sheet table or raw fastq directory.")
    
rule concat_targets:
    input:
        fastq = expand(config["concat_fastq_dir"] + "/{sample}_{read}.fastq.gz", sample = SAMPLES, read = config["reads"]),
