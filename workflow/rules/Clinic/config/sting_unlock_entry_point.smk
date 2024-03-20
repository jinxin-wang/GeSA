import os
import re
import sys
import glob
import logging
import pandas  as pd
from   pathlib import Path

## "general" adapt Yoann's pipeline setting
annotation_config = {
    "batch_num" : 16,
    "bilan_table": "/mnt/nfs01/home/j_wang@intra.igr.fr/download/Bilan_Unlock_Seq_Anal_SERGEY3.xlsx",
    "dataset_table": "/mnt/nfs01/home/j_wang@intra.igr.fr/download/dataset.STINGUNLOCK_batch16.metadata_20240201172831.csv",
    "bilan_rebuild": "config/bilan.xlsx",
    "rebuild_dataset_table": "config/dataset.csv",
    "variant_call_table": "config/variant_call_list_TvN.tsv",
    "rna_samplesheet": "config/samplesheet.csv",

    "general": {
        "agg_sample"  : "config/clinic.tsv",
        "dna_samples" : "config/dna_samples.tsv",
        "rna_samples" : "config/rna_samples.tsv",
        "tumor_normal_pairs": "config/tumor_normal_pairs.tsv",
    },

    "params": {
        "civic": {
            "corr_table" : "workflow/resources/Table_Correspondence_Tumor_Type.tsv",
        },
    },
}

include: "sting_unlock.smk"
include: "conf2.smk"

rule target:
    input:
        annotation_config["bilan_rebuild"],
        annotation_config["dataset_table"],
        annotation_config["rebuild_dataset_table"],
        annotation_config["variant_call_table"],
        annotation_config["rna_samplesheet"],
        annotation_config["general"]["tumor_normal_pairs"],
        annotation_config["general"]["agg_sample"],
        annotation_config["general"]["dna_samples"],
        annotation_config["general"]["rna_samples"],
