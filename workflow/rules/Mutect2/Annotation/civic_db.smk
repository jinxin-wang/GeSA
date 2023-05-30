"""
metaprism_config should be a dict like:

{
    "ref": {
        "species": <species_name>
    },
    "params": {
        "vep": {
            "path": <path/to/vep>,
            "cache": <path/to/vep-cache>,
            "plugins_data": {
                "CADD": <path/to/vep-plugin/CADD>,
                "dbNSFP": <path/to/vep-plugin/dbNSFP>,
            }
        },
        "civic": {
            "run_per_sample": {"maf": True},
            "gene_list": <path/to/gene_list>,
            "evidences": <path/to/evidence>,
            "rules_clean": <path/to/rules_clean>,
        },
    },
    "tumor_normal_pairs": <path/to/tumor_normal_pairs.tsv>,
}
"""

# Import Yoann's work
module metaprism_annotation:
    snakefile:
        github("gustaveroussy/MetaPRISM_WES_Pipeline", path="workflow/rules/annotation.smk", branch="master")
    config:
        metaprism_config


# Use VEP annotation, since the later VCF to MAF does not work properly
# without a previous VEP annotation
use rule somatic_vep_vcf from metaprism_annotation with:
    input:
        vcf="Mutect2_TvN/{tsample}_Vs_{nsample}_twicefiltered_TvN.vcf.gz",
    output:
        vcf=temp("Vep/VCF_Annotation/{tsample}_Vs_{nsample}_twicefiltered_TvN.vcf.gz"),



# VCF to MAF conversion, now the annotation is done.
use rule somatic_vep_vcf2maf from metaprism_annotation with:
    input:
        "Vep/VCF_Annotation/{tsample}_Vs_{nsample}_twicefiltered_TvN.vcf.gz",
    output:
        temp("Vep/VCF_Annotation/{tsample}_Vs_{nsample}_twicefiltered_TvN.maf"),


# Use VEP-tab annotation, since the later VCF to TSV does not work properly
# without a previous VEP annotation
use rule somatic_vep_tab from metaprism_annotation with:
    input:
        vcf="Mutect2_TvN/{tsample}_Vs_{nsample}_twicefiltered_TvN.vcf.gz",
        cadd=metaprism_config["params"]["vep"]["plugins_data"]["CADD"],
        dbnsfp=metaprism_config["params"]["vep"]["plugins_data"]["dbNSFP"],
    output:
        vcf=temp("Vep/TAB_Annotation/{tsample}_Vs_{nsample}_twicefiltered_TvN.tsv"),


# Merge somatic VEP-Tab and VEP-MAF in a final MAF.
# This is required for ulterior annotation.
use rule somatic_maf from metaprism_annotation with:
    input:
        vep="Vep/TAB_Annotation/{tsample}_Vs_{nsample}_twicefiltered_TvN.tsv",
        maf="Vep/VCF_Annotation/{tsample}_Vs_{nsample}_twicefiltered_TvN.maf",
    output:
        temp("MAF/annotation/somatic_maf/{tsample}_Vs_{nsample}.maf"),


use rule somatic_maf_civic from metaprism_annotation with:
    input:
        table_alt="MAF/annotation/somatic_maf/{tsample}_Vs_{nsample}.maf",
        table_cln=metaprism_config["tumor_normal_pairs"],
        table_gen=metaprism_config["params"]["civic"]["gene_list"],
        civic=metaprism_config["params"]["civic"]["evidences"],
        rules=metaprism_config["params"]["civic"]["rules_clean"]
    output:
        table_pre=temp("MAF/annotation/civic_db/{tsample}_Vs_{nsample}_pre.tsv"),
        table_run=temp("MAF/annotation/civic_db/{tsample}_Vs_{nsample}_run.tsv"),
        table_pos="MAF/annotation/civic_db/{tsample}_Vs_{nsample}_pos.tsv",