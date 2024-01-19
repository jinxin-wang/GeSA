import os
import re
import sys
import glob
import logging
import pandas  as pd
from   pathlib import Path

annotation_config = {
    "all_sample_dir": "",
    "general": {
        "patients": "config/patients.tsv",
        "dna_samples" : "config/dna_samples.tsv",
        "rna_samples" : "config/rna_samples.tsv",
        "agg_sample"  : "config/clinic.tsv",
        "tumor_normal_pairs": "config/tumor_normal_pairs.tsv",
    },

    "params": {
        "civic": {
            "corr_table" : "workflow/resources/Table_Correspondence_Tumor_Type.tsv",
        },
    },
}

include: "conf.smk"

rule target:
    input:
        annotation_config["general"]["tumor_normal_pairs"],
        annotation_config["general"]["dna_samples"],
        annotation_config["general"]["rna_samples"],
