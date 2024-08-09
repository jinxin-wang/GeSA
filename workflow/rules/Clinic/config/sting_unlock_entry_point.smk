import os
import re
import sys
import glob
import logging
import pandas  as pd
from   pathlib import Path

## "general" adapt Yoann's pipeline setting
annotation_config = {
    "batch_num" : 20,
    "bilan_table":   "/home/j_wang@intra.igr.fr/sting_docs/bilan.xlsx",
    "dataset_table": "/home/j_wang@intra.igr.fr/sting_docs/metadata_batch6_2.csv",
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
