import os
import re
import csv
import errno
import pandas as pd
from math import ceil 

#### define colors
OKGREEN = '\033[92m'
WARNING = '\033[93m'
FAIL    = '\033[91m'
ENDC    = '\033[0m'

print(OKGREEN + "[message] Initializing %s analysis pipeline for %s samples in %s mode"%(config["seq_type"],config["samples"], config["mode"]) + ENDC)

## Tumor vs Normal mode by default
TUMOR_ONLY = False
NORMAL_ONLY= False

## Note 1: default values for target interval
##   TARGET_INTERVAL_GATK = ""
##   TARGET_INTERVAL_BQSR = " -L 1 "

## Note 2: config["MUTECT_INTERVAL_DIR"] should not be terminated by "/"

FASTQ = []

## max sample file size
if os.path.isdir('DNA_samples'):
    max_file_size_G = max([0] + [ ceil(os.stat(f"DNA_samples/{sample_file}").st_size / 1024 / 1024 / 1024) for sample_file in os.listdir("DNA_samples") ])
    ## Get all fastq
    # FASTQ, = glob_wildcards("DNA_samples/{name}.fastq.gz")
    # print(FASTQ)


## wildcards for mutect intervals
if config["targeted_seq"] :
    mutect_intervals, = glob_wildcards(config["targeted"]["mutect_interval_dir"] + "/{interval}.bed")
else :
    mutect_intervals, = glob_wildcards(config["gatk"][config["samples"]][config["seq_type"]]["mutect_interval_dir"] + "/{interval}.bed")

TSAMPLE = []
NSAMPLE = []
SAMPLES = []

## Collecting information on files to produce
FACETS     = []
CNV_FACETS = []

ANNOVAR   = []

MUTECT2   = []

ONCOTATOR_COSMIC      = []
ONCOTATOR_EXOM_COSMIC = []

ONCOTATOR_MAF      = []
ONCOTATOR_EXOM_MAF = []

# VARIANT_CALL_TABLE = ""
VARIANT_CALL_TABLE = find_variant_call_list(config["mode"])

def find_variant_call_list(mode = config["mode"]):
    regex = re.compile(f"config/variant_call_list_{mode}.(tsv$)|(csv$)|(xlsx$)")
    for root, dirs, files in os.walk("config"):
        for fname in files:
            if regex.match(fname):
                print(f"{OKGREEN}[message] Configuration file {root}/{fname} is detected. {ENDC}")
                return f"{root}/{fname}"
    print(f"{FAIL}[error] variant call list file is not found in config directory. {ENDC}")

def read_variant_call_list(fname, names):
    suffix = fname.strip().split('.')[-1]
    if suffix == 'tsv':
        variant_df = pd.read_table(fname, names=names, sep='\t')
    elif suffix == 'csv':
        variant_df = pd.read_table(fname, names=names, sep=';')
    elif suffix == 'xlsx':
        variant_df = pd.read_excel(fname, names=names)
    else:
        raise Exception(f"Unrecognized file suffix {suffix} for the variant call table {fname}")
    
    return variant_df

# def build_TvN_targets(tsample, nsample):
def build_TvN_targets(variant_df, tcoln, ncoln):
    # CNV_FACETS.append("cnv_facets/" + tsample + "_vs_" + nsample + ".vcf.gz",)
    CNV_FACETS = variant_df.apply(lambda x: "cnv_facets/%s_vs_%s.vcf.gz"%(x[tcoln],x[ncoln]), axis=1)
    # FACETS.append("facets/" + tsample + "_vs_" + nsample + "_facets_cval500.pdf")
    FACETS = variant_df.apply(lambda x: "facets/%s_vs_%s_facets_cval500.pdf"%(x[tcoln],x[ncoln]), axis=1)
    # MUTECT2.append("Mutect2_TvN/" + tsample + "_vs_" + nsample + "_twicefiltered_TvN.vcf.gz")
    MUTECT2= variant_df.apply(lambda x: "Mutect2_TvN/%s_vs_%s_twicefiltered_TvN.vcf.gz"%(x[tcoln],x[ncoln]), axis=1)

    if config["samples"] == "human":
        # ONCOTATOR_MAF.append("oncotator_TvN_maf/" + tsample + "_vs_" + nsample + "_TvN_selection.TCGAMAF")
        ONCOTATOR_MAF = variant_df.apply("oncotator_TvN_maf/%s_vs_%s_TvN_selection.TCGAMAF"%(x[tcoln],x[ncoln]), axis=1)
        # ONCOTATOR_COSMIC.append("oncotator_TvN_tsv_COSMIC/" + tsample + "_vs_" + nsample + "_TvN_with_COSMIC.tsv.gz")
        ONCOTATOR_COSMIC = variant_df.apply("oncotator_TvN_tsv_COSMIC/%s_vs_%s_TvN_with_COSMIC.tsv.gz"%(x[tcoln],x[ncoln]), axis=1)
        if config["seq_type"] == "WGS":
            # ONCOTATOR_EXOM_MAF.append("oncotator_TvN_maf/" + tsample + "_vs_" + nsample + "_TvN_selection.TCGAMAF.gz")
            ONCOTATOR_EXOM_MAF = variant_df.apply("oncotator_TvN_maf/%s_vs_%s_TvN_selection.TCGAMAF.gz"%(x[tcoln],x[ncoln]), axis=1)
            # ONCOTATOR_EXOM_COSMIC.append("oncotator_TvN_tsv_COSMIC_exom/" + tsample + "_vs_" + nsample + "_TvN_with_COSMIC_exom.tsv.gz")
            ONCOTATOR_EXOM_COSMIC = variant_df.apply("oncotator_TvN_tsv_COSMIC_exom/%s_vs_%s_TvN_with_COSMIC_exom.tsv.gz"%(x[tcoln],x[ncoln]), axis=1)
            
    elif config["samples"] == "mouse":
        ANNOVAR = variant_df.apply("annovar_mutect2_TvN/%s_vs_%s.avinput"%(x[tcoln],x[ncoln]), axis=1)

def build_Tp_targets(tsample, PoN):
    FACETS.append("facets_Tp/" + tsample + "_PON_" + Pon + "_facets_cval500.pdf")
    MUTECT2.append("Mutect2_Tp/" + tsample + "_PON_" + Pon + "_twicefiltered_Tp.vcf.gz")
    
    if config["samples"] == "human":
        ONCOTATOR.append("oncotator_Tp_tsv_COSMIC/" + tsample  + "_PON_" + PoN + "_Tp_with_COSMIC.tsv.gz")
        
        if config["seq_type"] == "WGS":
            ONCOTATOR_EXOM.append("oncotator_Tp_tsv_COSMIC_exom/" + tsample  + "_PON_" + PoN + "_Tp_with_COSMIC_exom.tsv.gz")
            
    elif config["samples"] == "mouse":
        ANNOVAR.append("annovar_mutect2_Tp/" + tsample + "_PON_" + PoN + ".avinput")
  

def build_TvNp_targets(tsample, nsample, PoN):
    CNV_FACETS.append("cnv_facets/" + tsample + "_vs_" + nsample + ".vcf.gz",)
    FACETS.append("facets/" + tsample + "_vs_" + nsample + "_facets_cval500.pdf")
    MUTECT2.append("Mutect2_TvNp/" + tsample + "_vs_" + nsample + "_PON_" + PoN + "_twicefiltered_TvNp.vcf.gz")

    if config["samples"] == "human": 
        ONCOTATOR.append("oncotator_TvNp_tsv_COSMIC/" + tsample + "_vs_" + nsample + "_PON_" + PoN + "_TvNp_with_COSMIC.tsv.gz")

        if config["seq_type"] == "WGS":
            ONCOTATOR_EXOM.append("oncotator_TvNp_tsv_COSMIC_exom/" + tsample + "_vs_" + nsample + "_PON_" + PoN + "_TvNp_with_COSMIC_exom.tsv.gz")

    elif config["samples"] == "mouse":
        ANNOVAR.append("annovar_mutect2_TvN_pon/" + tsample + "_vs_" + nsample + "_PON_" + PoN + + ".avinput")

def build_Tonly_targets(tsample):
    MUTECT2.append(f"Mutect2_T/{tsample}_tumor_only_twicefiltered_T.vcf.gz")
    # MUTECT2.append("Mutect2_T/" + tsample+ "_tumor_only_T.vcf.gz")

    if config["samples"] == "human":
        ONCOTATOR_COSMIC.append("oncotator_T_tsv_COSMIC/" + tsample + "_tumor_only_T_with_COSMIC.tsv.gz")
        ONCOTATOR_MAF.append("oncotator_T_maf/" + tsample + "_tumor_only_T_selection.TCGAMAF.gz")

        if config["seq_type"] == "WGS":
            ONCOTATOR_EXOM_COSMIC.append("oncotator_T_tsv_COSMIC_exom/" + tsample + "_tumor_only_T_with_COSMIC_exom.tsv.gz")
            ONCOTATOR_EXOM_MAF.append("oncotator_T_maf_exom/" + tsample + "_tumor_only_T_selection_exom.TCGAMAF.gz")
            
    elif config["samples"] == "mouse":
        ANNOVAR.append("annovar_mutect2_T/" + tsample  + ".avinput")

if config["mode"] == "TvN": 
    print(OKGREEN + "[message] Pipeline runs in Tumor vs Normal mode." + ENDC)
    variant_df = read_variant_call_list(VARIANT_CALL_TABLE, ['tumor', 'normal'])
    TSAMPLE = variant_df['tumor'].to_list()
    NSAMPLE = variant_df['normal'].to_list()
    build_TvN_targets(variant_df, 'tumor', 'normal')

if config["mode"] == "Tp":
    print(OKGREEN + "[message] Pipeline runs in Tumor vs PoN mode." + ENDC)
    # VARIANT_CALL_TABLE = "config/variant_call_list_Tp.tsv"
    variant_df = read_variant_call_list(VARIANT_CALL_TABLE, ['tumor', 'PoN'])
    TSAMPLE = variant_df['tumor'].to_list()
    PoN     = variant_df['PoN'].to_list()
    build_Tp_targets(variant_df, 'tumor', 'PoN')

if config["mode"] == "TvNp":
    print(OKGREEN + "[message] Pipeline runs in Tumor vs Normal vs PoN mode." + ENDC)
    # VARIANT_CALL_TABLE = "config/variant_call_list_TvNp.tsv"
    variant_df = read_variant_call_list(VARIANT_CALL_TABLE, ['tumor', 'normal', 'PoN'])
    TSAMPLE = variant_df['tumor'].to_list()
    NSAMPLE = variant_df['normal'].to_list()
    PoN     = variant_df['PoN'].to_list()
    build_TvNp_targets(variant_df, 'tumor', 'normal', 'PoN')

if config["mode"] == "T":
    TUMOR_ONLY = True
    print(OKGREEN + "[message] Pipeline runs in Tumor Only mode." + ENDC)
    # VARIANT_CALL_TABLE = "config/variant_call_list_T.tsv"
    variant_df = read_variant_call_list(VARIANT_CALL_TABLE, ['tumor'])
    TSAMPLE = variant_df['tumor'].to_list()
    build_Tonly_targets(variant_df, 'tumor')

    else: 
        print(OKGREEN + "[message] No configuration file is detected." + ENDC)
        if os.path.isdir("DNA_samples"):
            print(OKGREEN + "[message] Samples in the directory DNA_samples will be used as Tumor samples." + ENDC)
            TSAMPLE, PAIRED = glob_wildcards("DNA_samples/{tsample,.+}_{paired,[012]}.fastq.gz")
        elif os.path.isdir("bam"):
            print(OKGREEN + "[message] Samples in the directory bam will be used as Tumor samples." + ENDC)
            TSAMPLE, = glob_wildcards("bam/{tsample,.+}.nodup.recal.bam")
        for tsample in TSAMPLE:
            build_Tonly_targets(tsample)

if config["mode"] == "N":
    NORMAL_ONLY = True
    # VARIANT_CALL_TABLE = "config/variant_call_list_N.tsv"
    print(OKGREEN + "[message] Pipeline runs in Normal Only mode." + ENDC)
    variant_df = read_variant_call_list(VARIANT_CALL_TABLE, ['normal'])
    NSAMPLE = variant_df['normal'].to_list()
                
SAMPLES = list(set(TSAMPLE + NSAMPLE))

# FASTQ = expand("DNA_samples/{sample}_{reads}.fastq.gz", sample=SAMPLES, reads=['1','2'] config["paired"] == True else ['0'])
# print(FASTQ)
