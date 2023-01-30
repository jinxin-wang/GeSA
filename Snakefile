import os

if config["TARGET_INTERVAL"]!="":
    TARGET_INTERVAL_GATK = " -L " + config["TARGET_INTERVAL"]
    TARGET_INTERVAL_BQSR = TARGET_INTERVAL_GATK

else :
    TARGET_INTERVAL_GATK = ""
    TARGET_INTERVAL_BQSR = " -L 1 "

if config["MUTECT_INTERVAL_DIR"][-1] == '/':
    config["MUTECT_INTERVAL_DIR"] = config["MUTECT_INTERVAL_DIR"][:-1]

mutect_intervals, = glob_wildcards(config["MUTECT_INTERVAL_DIR"] + "/{interval}.bed")

## Collecting information on files to produce

SAMPLES = []

if os.path.isfile("variant_call_list.tsv") :
    with open("variant_call_list.tsv",'r')  as SAMPLE_INPUT_LIST: 
        MUTECT2_SAMPLES = []
        MUTECT2_FOR_PON_SAMPLES = []
        FACETS_SAMPLES = []
        CNV_FACETS_SAMPLES = []
        ONCOTATOR_SAMPLES = []
        ONCOTATOR_EXOM_SAMPLES = []
        TSAMPLE = []
        NSAMPLE = []
        for line in SAMPLE_INPUT_LIST :
            tmp = line.strip().split('\t')
            if len(tmp)==2:
                tsample = tmp[0]
                nsample = tmp[1]
                TSAMPLE.append(tsample)
                NSAMPLE.append(nsample)
                FACETS_SAMPLES.append("facets/" + tsample + "_Vs_" + nsample + "_facets_cval500.pdf")
                CNV_FACETS_SAMPLES.append("cnv_facets/" + tsample + "_Vs_" + nsample + ".vcf.gz")
                ONCOTATOR_SAMPLES.append("oncotator_TvN_tsv_COSMIC/" + tsample + "_Vs_" + nsample + "_TvN_with_COSMIC.tsv")
                ONCOTATOR_EXOM_SAMPLES.append("oncotator_TvN_tsv_COSMIC_exom/" + tsample + "_Vs_" + nsample + "_TvN_with_COSMIC_exom.tsv")
                MUTECT2_SAMPLES.append("Mutect2_TvN/" + tsample + "_Vs_" + nsample + "_twicefiltered_TvN.vcf.gz")

## Get all fastq
FASTQ_SAMPLES = glob_wildcards("DNA_samples/{name}.fastq.gz")
        
rule all:
    input:
        expand('bam/{sample}.nodup.recal.bam', sample =  NSAMPLE + TSAMPLE),
        expand('fastq_QC_raw/{sample}_fastqc.html', sample = FASTQ_SAMPLES.name if config["tools"]["fastqc"] else []),
        expand('fastq_QC_clean/clean_{sample}_fastqc.html', sample =  FASTQ_SAMPLES.name if config["tools"]["fastqc"] else []),
        expand('{sample}', sample = FACETS_SAMPLES if config["tools"]["facets"] else []),
        expand('{sample}', sample = CNV_FACETS_SAMPLES if config["tools"]["cnv_facets"] else []),
        expand('mapping_QC/HsMetrics/{sample}_HsMetrics.tsv', sample = TSAMPLE + NSAMPLE if config["tools"]["hsmetrics"] else []),
        expand("mapping_QC/flagstat/{sample}_flagstat.txt", sample = TSAMPLE + NSAMPLE if config["tools"]["flagstat"] else []),
        expand("mapping_QC/mosdepth/{sample}.mosdepth.global.dist.txt", sample = TSAMPLE + NSAMPLE if config["tools"]["mosdepth"] else []),
        expand("BQSR/{sample}_BQSR_report.pdf", sample = TSAMPLE + NSAMPLE if config["tools"]["bqsr"] else []),
        expand("haplotype_caller/{sample}_germline_variants.vcf.gz", sample = NSAMPLE if config["tools"]["haplotype"] else []),
        expand("annovar/{sample}.avinput", sample = NSAMPLE + TSAMPLE if config["tools"]["annovar"] else []),
        expand("{sample}", sample = MUTECT2_SAMPLES if config["tools"]["mutect2"]["samples"] else []),
        expand("{sample}", sample = ONCOTATOR_SAMPLES if config["tools"]["mutect2"]["oncotator"] else []),
        expand("{sample}", sample = ONCOTATOR_EXOM_SAMPLES if config["tools"]["mutect2"]["oncotator_exom"] else []),
        expand("{sample}", sample = MUTECT2_FOR_PON_SAMPLES if config["tools"]["mutect2_pon"]["samples"] else []),

include: "modules/Fastp/main.smk"
include: "modules/Bam/main.smk"

if config["tools"]["fastqc"]:
    include: "modules/Fastqc/main.smk"

if config["tools"]["facets"]:
    include: "modules/Facets/main.smk"

if config["tools"]["cnv_facets"]:
    include: "modules/Facets/main.smk"

if config["tools"]["hsmetrics"]:
    include: "modules/HsMetrics/main.smk"

if config["tools"]["bqsr"]:
    include: "modules/BQSR/main.smk"

if config["tools"]["haplotype"]:
    include: "modules/HaplotypeCaller/main.smk"

if config["tools"]["mosdepth"]:
    include: "modules/Msodepth/main.smk"

if config["tools"]["flagstat"]:
    include: "modules/Flagstat/main.smk"

if config["tools"]["mutect2"]["samples"]:
    include: "modules/Mutect2/Std/main.smk"

if config["tools"]["mutect2_pon"]["samples"]:
    include: "modules/Mutect2/Pon/main.smk"

if config["tools"]["mutect2_tumor_only"]["samples"]:
    include: "modules/Mutect2/TumorOnly/main.smk"

if config["tools"]["mutect2_tumor_only_pon"]["samples"]:
    include: "modules/Mutect2/TumorOnlyPon/main.smk"


