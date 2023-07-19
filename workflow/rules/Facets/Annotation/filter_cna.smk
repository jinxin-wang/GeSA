import pandas

try:
    table = pandas.read_table(
        metaprism_config["general"]["samples"], 
        dtype = str
    ).set_index(
        ["Sample_Id"], 
        drop = False
    )
except FileNotFoundError:
    table = pandas.DataFrame()

def get_column_table_sample(wildcards, col):
    """Get the value of the column col for the sample"""
    if pandas.DataFrame().equals(table):
        return "Female"

    try:
        value = table.loc[wildcards.sample, col]
    except AttributeError:
        try:
            value = table.loc[wildcards.tsample, col]
        except AttributeError:
            try:
                value = table.loc[wildcards.nsample, col]
            except AttributeError:
                if wildcards.sample_pair=="all_samples":
                    value = ""
                else:
                    tsample = wildcards.sample_pair.split("_Vs_")[0]
                    value = table.loc[tsample, col]
    return value

## OK
#rule setup_r:
#    conda:
#        "/mnt/beegfs/pipelines/MetaPRISM_WES_Pipeline/workflow/envs/r.yaml"
#    output:
#        touch("logs/setup_r.done")
#    resources:
#        queue = "shortq",
#        mem_mb = 16000,
#        time_min = 60
#    shell:
#        """
#        Rscript -e 'devtools::install_github("mskcc/facets-suite")'
#        """

## OK
rule somatic_cnv_process_vcf:
    input:
        vcf = "cnv_facets_tumorOnly/{tsample}_Vs_unmatchedNormal.vcf.gz",
        rules_arm = metaprism_config["params"]["cnv"]["chr_arm_rules"],
        rules_cat = metaprism_config["params"]["cnv"]["cna_cat_rules"],
        # env = "logs/setup_r.done",
        script_path = "workflow/scripts/cnv_process_vcf.R",
    output:
        arm = "facets/calling/somatic_cnv_chr_arm/{tsample}_Vs_unmatchedNormal.tsv",
        sum = "facets/calling/somatic_cnv_sum/{tsample}_Vs_unmatchedNormal.tsv",
        tab = "facets/calling/somatic_cnv_table/{tsample}_Vs_unmatchedNormal.tsv",
    log:
        "logs/calling/somatic_cnv_process_vcf/{tsample}_Vs_unmatchedNormal.tsv.log"
    # conda:
        # "/mnt/beegfs/pipelines/MetaPRISM_WES_Pipeline/workflow/envs/r.yaml"
    threads: 1
    params:
        gender = lambda w: get_column_table_sample(w, "Gender"),
        threshold = metaprism_config["params"]["cnv"]["calls_threshold"]
    resources:
        queue = "shortq",
        mem_mb = 8000,
        time_min = 20
    shell:
        """
        conda run -n metaprism_r \
        Rscript {input.script_path} \
            --input_vcf {input.vcf} \
            --gender {params.gender} \
            --rules_arm {input.rules_arm} \
            --rules_cat {input.rules_cat} \
            --threshold {params.threshold} \
            --output_arm {output.arm} \
            --output_sum {output.sum} \
            --output_tab {output.tab} \
            --log {log}
        """

# OK
rule somatic_cnv_gene_calls:
    input:
        tab = "facets/calling/somatic_cnv_table/{tsample}_Vs_unmatchedNormal.tsv",
        bed = metaprism_config["params"]["cnv"]["bed"],
        script_path = "workflow/scripts/cnv_gene_calls.py"
    output:
        "facets/calling/somatic_cnv_gene_calls/{tsample}_Vs_unmatchedNormal.tsv.gz"
    log:
        "logs/calling/somatic_cnv_gene_calls/{tsample}_Vs_unmatchedNormal.tsv.log"
    # conda:
        # "/mnt/beegfs/pipelines/MetaPRISM_WES_Pipeline/workflow/envs/python.yaml"
        # "metaprism_py"
    params:
        threshold = metaprism_config["params"]["cnv"]["calls_threshold"]
    threads: 1
    resources:
        queue = "shortq",
        mem_mb = 8000,
        time_min = 20
    shell:
        """
        conda run -n metaprism_py \
        python -u {input.script_path} \
            --input_tab {input.tab} \
            --input_bed {input.bed} \
            --threshold {params.threshold} \
            --output {output} &> {log}
        """

# OK
rule somatic_cnv_gene_calls_filtered:
    input:
        "facets/calling/somatic_cnv_gene_calls/{tsample}_Vs_unmatchedNormal.tsv.gz"
    output:
        temp("facets/calling/somatic_cnv_gene_calls_filtered/{tsample}_Vs_unmatchedNormal.tsv.gz")
    log:
        "logs/calling/somatic_cnv_gene_calls_filtered/{tsample}_Vs_unmatchedNormal.log"
    threads: 1
    resources:
        queue = "shortq",
        mem_mb = 8000,
        time_min = 20
    shell:
        """
        zcat {input} | grep "PASS\|Tumor_Sample_Barcode" | gzip > {output} 2> {log}
        """