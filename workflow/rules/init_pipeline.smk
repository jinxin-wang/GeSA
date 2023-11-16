import os
import csv
import errno
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

## max sample file size
if os.path.isdir('DNA_samples'):
    max_file_size_G = max([ ceil(os.stat(f"DNA_samples/{sample_file}").st_size / 1024 / 1024 / 1024) for sample_file in os.listdir("DNA_samples") ])

## wildcards for mutect intervals
mutect_intervals, = glob_wildcards(config["gatk"][config["samples"]][config["seq_type"]]["mutect_interval_dir"] + "/{interval}.bed")

## Get all fastq
FASTQ, = glob_wildcards("DNA_samples/{name}.fastq.gz")

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

VARIANT_CALL_TABLE = ""

def build_TvN_targets(tsample, nsample):
    if config["do_cnvfacet"]:
        CNV_FACETS.append("cnv_facets/" + tsample + "_Vs_" + nsample + ".vcf.gz",)
    FACETS.append("facets/" + tsample + "_Vs_" + nsample + "_facets_cval500.pdf")
    MUTECT2.append("Mutect2_TvN/" + tsample + "_Vs_" + nsample + "_twicefiltered_TvN.vcf.gz")

    if config["samples"] == "human":
        ONCOTATOR_MAF.append("oncotator_TvN_maf/" + tsample + "_Vs_" + nsample + "_TvN_selection.TCGAMAF")
        ONCOTATOR_COSMIC.append("oncotator_TvN_tsv_COSMIC/" + tsample + "_Vs_" + nsample + "_TvN_with_COSMIC.tsv.gz")
        if config["seq_type"] == "WGS":
            ONCOTATOR_EXOM_MAF.append("oncotator_TvN_maf/" + tsample + "_Vs_" + nsample + "_TvN_selection.TCGAMAF.gz")
            ONCOTATOR_EXOM_COSMIC.append("oncotator_TvN_tsv_COSMIC_exom/" + tsample + "_Vs_" + nsample + "_TvN_with_COSMIC_exom.tsv.gz")
            
    elif config["samples"] == "mouse":
        ANNOVAR.append("annovar_mutect2_TvN/" + tsample + "_Vs_" + nsample + ".avinput")

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
    if config["do_cnvfacet"]:    
        CNV_FACETS.append("cnv_facets/" + tsample + "_Vs_" + nsample + ".vcf.gz",)
    FACETS.append("facets/" + tsample + "_Vs_" + nsample + "_facets_cval500.pdf")
    MUTECT2.append("Mutect2_TvNp/" + tsample + "_Vs_" + nsample + "_PON_" + PoN + "_twicefiltered_TvNp.vcf.gz")

    if config["samples"] == "human":
        ONCOTATOR.append("oncotator_TvNp_tsv_COSMIC/" + tsample + "_Vs_" + nsample + "_PON_" + PoN + "_TvNp_with_COSMIC.tsv.gz")

        if config["seq_type"] == "WGS":
            ONCOTATOR_EXOM.append("oncotator_TvNp_tsv_COSMIC_exom/" + tsample + "_Vs_" + nsample + "_PON_" + PoN + "_TvNp_with_COSMIC_exom.tsv.gz")

    elif config["samples"] == "mouse":
        ANNOVAR.append("annovar_mutect2_TvN_pon/" + tsample + "_Vs_" + nsample + "_PON_" + PoN + + ".avinput")

def build_Tonly_targets(tsample):
    MUTECT2.append("Mutect2_T/" + tsample+ "_tumor_only_T.vcf.gz")

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
    VARIANT_CALL_TABLE = "config/variant_call_list_TvN.tsv"
    with open(VARIANT_CALL_TABLE,'r') as fd: 
        print(OKGREEN + "[message] Configuration file %s is detected. "%VARIANT_CALL_TABLE + ENDC)
        rd = csv.reader(fd, delimiter="\t", quotechar='"')
        for row in rd:
            tsample = row[0]
            nsample = row[1]
            TSAMPLE.append(tsample)
            NSAMPLE.append(nsample)
            build_TvN_targets(tsample, nsample)

if config["mode"] == "Tp":
    print(OKGREEN + "[message] Pipeline runs in Tumor vs PoN mode." + ENDC)
    VARIANT_CALL_TABLE = "config/variant_call_list_Tp.tsv"
    with open(VARIANT_CALL_TABLE,'r') as fd: 
        print(OKGREEN + "[message] Configuration file %s is detected. "%VARIANT_CALL_TABLE + ENDC)
        rd = csv.reader(fd, delimiter="\t", quotechar='"')
        for row in rd:
            tsample = row[0]
            PoN     = row[1]
            TSAMPLE.append(tsample)
            build_Tp_targets(tsample, PoN)

if config["mode"] == "TvNp":
    print(OKGREEN + "[message] Pipeline runs in Tumor vs Normal vs PoN mode." + ENDC)
    VARIANT_CALL_TABLE = "config/variant_call_list_TvNp.tsv"
    with open(VARIANT_CALL_TABLE,'r') as fd: 
        print(OKGREEN + "[message] Configuration file %s is detected. "%VARIANT_CALL_TABLE + ENDC)
        rd = csv.reader(fd, delimiter="\t", quotechar='"')
        for row in rd:
            tsample = row[0]
            nsample = row[1]
            PoN     = row[2]
            TSAMPLE.append(tsample)
            NSAMPLE.append(nsample)
            build_TvNp_targets(tsample, nsample, PoN)

if config["mode"] == "T":
    TUMOR_ONLY = True
    VARIANT_CALL_TABLE = "config/variant_call_list_T.tsv"
    print(OKGREEN + "[message] Pipeline runs in Tumor Only mode." + ENDC)
    if os.path.isfile(VARIANT_CALL_TABLE):
        print(OKGREEN + "[message] Configuration file variant_call_list_T.tsv is detected. " + ENDC)
        with open(VARIANT_CALL_TABLE,'r') as fd: 
            rd = csv.reader(fd, delimiter="\t", quotechar='"')
            for row in rd:
                tsample = row[0]
                TSAMPLE.append(tsample)
                build_Tonly_targets(tsample)
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
    VARIANT_CALL_TABLE = "config/variant_call_list_N.tsv"
    print(OKGREEN + "[message] Pipeline runs in Normal Only mode." + ENDC)
    if os.path.isfile(VARIANT_CALL_TABLE):
        print(OKGREEN + f"[message] Configuration file {VARIANT_CALL_TABLE} is detected. " + ENDC)
        with open(VARIANT_CALL_TABLE,'r') as fd: 
            rd = csv.reader(fd, delimiter="\t", quotechar='"')
            for row in rd:
                nsample = row[0]
                NSAMPLE.append(nsample)
                
SAMPLES = list(set(TSAMPLE + NSAMPLE))
