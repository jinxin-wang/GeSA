try:
    table = pd.read_table(
        config["general"]["samples"], 
        dtype=str
    ).set_index(
        ["Sample_Id"], 
        drop=False
    )
except FileNotFoundError:
    table = pandas.DataFrame()

def get_column_table_sample(wildcards, col):
    """Get the value of the column col for the sample"""
    if pandas.DataFrame().equals(table):
        return "Male"

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
                    tsample = wildcards.sample_pair.split("_vs_")[0]
                    value = table.loc[tsample, col]
    return value


rule setup_r:
    conda:
        "/mnt/beegfs/pipelines/MetaPRISM_WES_Pipeline/workflow/envs/r.yaml"
    output:
        touch("logs/setup_r.done")
    resources:
        queue="shortq",
        mem_mb=16000,
        time_min=60
    shell:
        """
        Rscript -e 'devtools::install_github("mskcc/facets-suite")'
        """


rule somatic_cnv_process_vcf:
    input:
        vcf="facets/calling/somatic_cnv_facets/{tsample}_vs_{nsample}.vcf.gz",
        rules_arm=config["params"]["cnv"]["chr_arm_rules"],
        rules_cat=config["params"]["cnv"]["cna_cat_rules"],
        env="logs/setup_r.done",
        script_path="/mnt/beegfs/pipelines/MetaPRISM_WES_Pipeline/workflow/scripts/05.2_cnv_process_vcf.R",
    output:
        arm="facets/calling/somatic_cnv_chr_arm/{tsample}_vs_{nsample}.tsv",
        sum="facets/calling/somatic_cnv_sum/{tsample}_vs_{nsample}.tsv",
        tab="facets/calling/somatic_cnv_table/{tsample}_vs_{nsample}.tsv",
    log:
        "logs/calling/somatic_cnv_process_vcf/{tsample}_vs_{nsample}.log"
    conda:
        "/mnt/beegfs/pipelines/MetaPRISM_WES_Pipeline/workflow/envs/r.yaml"
    threads: 1
    params:
        gender = lambda w: get_column_table_sample(w, "Gender"),
        threshold=config["params"]["cnv"]["calls_threshold"]
    resources:
        queue="shortq",
        mem_mb=8000,
        time_min=20
    shell:
        """
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


rule somatic_cnv_gene_calls:
    input:
        tab="facets/calling/somatic_cnv_table/{tsample}_vs_{nsample}.tsv",
        bed=config["params"]["cnv"]["bed"],
        script_path="/mnt/beegfs/pipelines/MetaPRISM_WES_Pipeline/workflow/scripts/05.3_cnv_gene_calls.py"
    output:
        "facets/calling/somatic_cnv_gene_calls/{tsample}_vs_{nsample}.tsv.gz"
    log:
        "logs/calling/somatic_cnv_gene_calls/{tsample}_vs_{nsample}.log"
    conda:
        "/mnt/beegfs/pipelines/MetaPRISM_WES_Pipeline/workflow/envs/python.yaml"
    params:
        threshold=config["params"]["cnv"]["calls_threshold"]
    threads: 1
    resources:
        queue="shortq",
        mem_mb=8000,
        time_min=20
    shell:
        """
        python -u {input.script_path} \
            --input_tab {input.tab} \
            --input_bed {input.bed} \
            --threshold {params.threshold} \
            --output {output} &> {log}
        """


rule somatic_cnv_gene_calls_filtered:
    input:
        "facets/calling/somatic_cnv_gene_calls/{tsample}_vs_{nsample}.tsv.gz"
    output:
        temp("facets/calling/somatic_cnv_gene_calls_filtered/{tsample}_vs_{nsample}.tsv.gz")
    log:
        "logs/calling/somatic_cnv_gene_calls_filtered/{tsample}_vs_{nsample}.log"
    threads: 1
    resources:
        queue="shortq",
        mem_mb=8000,
        time_min=20
    shell:
        """
        zcat {input} | grep "PASS\|Tumor_Sample_Barcode" | gzip > {output} 2> {log}
        """