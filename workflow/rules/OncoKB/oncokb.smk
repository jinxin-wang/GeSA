# https://github.com/oncokb/oncokb-annotator

'''
MafAnnotator.py
    -i <input MAF file>
    -o <output MAF file>
    [-p previous results]
    [-c <input clinical file>] 
    [-s sample list filter]
    [-t <default tumor type>]
    [-u oncokb-base-url]
    [-b oncokb api bear token]
    [-a]
    [-q query type] ~ HGVSp_Short|HGVSp|HGVSg|Genomic_Change
    [-r default reference genome] ~ GRCh37|GRCh38
'''

rule mut_oncokb_TvN:
    input:
        vcf  = "mut_vep_TvN/{tsample}_vs_{nsample}.vcf",
        oncotree_code = "",
    output:
        maf  = "mut_oncokb_TvN/{tsample}_vs_{nsample}.maf",
    log:
        "logs/mut_oncokb_TvN/{tsample}_vs_{nsample}.log" 
    conda:
        "metaprism_python"
    params:
        queue  = "shortq",
        token  = config["oncokb"]["token"],
        annotator = config["oncokb"]["maf_annotator"],
    threads: 1
    resources:
        queue  = "shortq",
        mem_mb = 8000,
    shell:
        """
        python -u {params.annotator} \
            -i ${input.vcf} \
            -o ${output.maf} \
            -t {input.oncotree_code} \
            -b ${params.token} \
            -q Genomic_Change \
            -r GRCh37 2> {log}
        """

use rule mut_oncokb_TvN as mut_oncokb_T with:
    input:
        vcf  = "mut_vep_T/{tsample}.vcf",
        oncotree_code = "",
    output:
        maf  = "mut_oncokb_T/{tsample}.maf",
    log:
        "logs/mut_oncokb_T/{tsample}.log" 


"""
CnaAnnotator.py
    -i <input CNA file>
    -o <output CNA file>
    [-p previous results]
    [-c <input clinical file>]
    [-s sample list filter]
    [-t <default tumor type>]
    [-u oncokb-base-url]
    [-b oncokb_api_bear_token]
    [-z annotate_gain_loss]
"""

rule cna_oncokb_TvN:
    input:
        vcf  = "cna_vep_TvN/{tsample}_vs_{nsample}.vcf",
        oncotree_code = "",
    output:
        maf  = "cna_oncokb_TvN/{tsample}_vs_{nsample}.maf",
    log:
        "logs/cna_oncokb_TvN/{tsample}_vs_{nsample}.log" 
    conda:
        "metaprism_python"
    params:
        queue  = "shortq",
        token  = config["oncokb"]["token"],
        annotator = config["oncokb"]["cna_annotator"],
    threads: 1
    resources:
        queue  = "shortq",
        mem_mb = 8000,
    shell:
        """
        python -u {params.annotator} \
            -i ${input.vcf} \
            -o ${output.maf} \
            -t {input.oncotree_code} \
            -b ${params.token} \
            -z 2> {log}
        """

use rule cna_oncokb_TvN as cna_oncokb_T with:
    input:
        vcf  = "cna_vep_T/{tsample}.vcf",
        oncotree_code = "",
    output:
        maf  = "cna_oncokb_T/{tsample}.maf",
    log:
        "logs/cna_oncokb_T/{tsample}.log" 
        
