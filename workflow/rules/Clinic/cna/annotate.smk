import pandas as pd

samples_df = pd.read_csv(config["general"]["samples"], dtype=str, sep="\t").set_index(["Sample_Id"])

# Process VCF file
rule somatic_cnv_process_vcf:
    input:
        vcf="cnv_facets/{tsample}_vs_{nsample}.vcf.gz",
        rules_arm=config["params"]["cnv"]["chr_arm_rules"],
        rules_cat=config["params"]["cnv"]["cna_cat_rules"],
    output:
        arm="calling/somatic_cnv_chr_arm/{tsample}_vs_{nsample}.tsv" ,
        sum="calling/somatic_cnv_sum/{tsample}_vs_{nsample}.tsv" ,
        tab="calling/somatic_cnv_table/{tsample}_vs_{nsample}.tsv" ,
    log:
        "calling/somatic_cnv_process_vcf/{tsample}_vs_{nsample}.log"
    conda:
        "metaprism_r"
    threads: 1
    params:
        gender = lambda w: samples_df.loc[w.tsample, "Gender"],
        threshold=config["params"]["cnv"]["calls_threshold"],
    resources:
        queue="shortq",
        mem_mb=8000,
        time_min=20
    shell:
        """
        Rscript workflow/rules/Clinic/Cnv_Annotation/scripts/05.2_cnv_process_vcf.R \
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

# Convert table with cnv at segments to cnv at genes using bedtools
rule somatic_cnv_gene_calls:
    input:
        tab="calling/somatic_cnv_table/{tsample}_vs_{nsample}.tsv",
        bed=config["params"]["cnv"]["bed"]
    output:
        "calling/somatic_cnv_gene_calls/{tsample}_vs_{nsample}.tsv.gz" ,
    log:
        "calling/somatic_cnv_gene_calls/{tsample}_vs_{nsample}.log" 
    conda:
        "metaprism_python"
    params:
        threshold=config["params"]["cnv"]["calls_threshold"]
    threads: 1
    resources:
        queue="shortq",
        mem_mb=8000,
        time_min=20
    shell:
        """
        python -u workflow/rules/Clinic/Cnv_Annotation/scripts/05.3_cnv_gene_calls.py \
            --input_tab {input.tab} \
            --input_bed {input.bed} \
            --threshold {params.threshold} \
            --output {output} &> {log}
        """

# Make a table of filter cnv calls per gene
rule somatic_cnv_gene_calls_filtered:
    input:
        "calling/somatic_cnv_gene_calls/{tsample}_vs_{nsample}.tsv.gz" ,
    output:
        "calling/somatic_cnv_gene_calls_filtered/{tsample}_vs_{nsample}.tsv.gz",
    log:
        "calling/somatic_cnv_gene_calls_filtered/{tsample}_vs_{nsample}.log" 
    threads: 1
    resources:
        queue="shortq",
        mem_mb=8000,
        time_min=20
    shell:
        """
        zcat {input} | grep "PASS\|Tumor_Sample_Barcode" | gzip > {output} 2> {log}
        """

####
#### Copy number variants ####
####

# Annnotate SCNAs using (in-house) civic annotator
# prepare a table for each pair tsample_vs_nsample
rule somatic_cna_civic:
    input:
        table_alt="calling/somatic_cnv_gene_calls_filtered/{tsample}_vs_{nsample}.tsv.gz",
        table_cln=config["general"]["tumor_normal_pairs"],
        table_gen=config["params"]["civic"]["gene_list"],
        civic=config["params"]["civic"]["evidences"],
        rules=config["params"]["civic"]["rules_clean"],
    output:
        table_pre = "annotation/somatic_cna_civic/{tsample}_vs_{nsample}_pre.tsv",
        table_run = "annotation/somatic_cna_civic/{tsample}_vs_{nsample}_run.tsv",
        table_pos = "annotation/somatic_cna_civic/{tsample}_vs_{nsample}.tsv",
    params:
        code_dir=config["params"]["civic"]["code_dir"],
        category="cna",
        a_option=lambda wildcards, input: "-a %s" % input.table_alt
    log:
        "logs/annotation/somatic_cna_civic/{tsample}_vs_{nsample}.log" 
    conda:
        "metaprism_python"
    resources:
        queue="shortq",
        mem_mb=24000,
    threads: 1
    shell:
        """
        bash workflow/rules/Clinic/Cnv_Annotation/scripts/04.3_civic_annotate.sh \
            {params.a_option} \
            -b {input.table_cln} \
            -c {input.table_gen} \
            -d {output.table_pre} \
            -e {output.table_run} \
            -f {output.table_pos} \
            -m {params.code_dir} \
            -n {input.civic} \
            -o {input.rules} \
            -t {params.category} \
            -l {log}
        """

# prepare a table for each pair tsample_vs_nsample
rule somatic_cna_oncokb:
    input:
        table_alt="calling/somatic_cnv_gene_calls_filtered/{tsample}_vs_{nsample}.tsv.gz",
        table_cln=config["general"]["tumor_normal_pairs"],
        table_gen=config["params"]["oncokb"]["gene_list"],
        rules=config["params"]["oncokb"]["rules_clean"]
    output:
        table_alt_pre = "annotation/somatic_cna_oncokb/{tsample}_vs_{nsample}_alt_pre.tsv",
        table_cln_pre = "annotation/somatic_cna_oncokb/{tsample}_vs_{nsample}_cln_pre.tsv",
        table_run     = "annotation/somatic_cna_oncokb/{tsample}_vs_{nsample}_run.tsv",
        table_pos     = "annotation/somatic_cna_oncokb/{tsample}_vs_{nsample}.tsv",
    params:
        token=config["params"]["oncokb"]["token"],
        code_dir=config["params"]["oncokb"]["code_dir"],
        category="cna",
        a_option=lambda wildcards, input: "-a %s" % input.table_alt
    log:
        "logs/annotation/somatic_cna_oncokb/{tsample}_vs_{nsample}.log" 
    conda:
        "metaprism_python"
    threads: 1
    resources:
        queue="shortq",
        mem_mb=4000,
    shell:
        """
        bash workflow/rules/Clinic/Cnv_Annotation/scripts/04.3_oncokb_annotate.sh \
            {params.a_option} \
            -b {input.table_cln} \
            -c {input.table_gen} \
            -d {output.table_alt_pre} \
            -g {output.table_cln_pre} \
            -e {output.table_run} \
            -f {output.table_pos} \
            -k {params.token} \
            -m {params.code_dir} \
            -o {input.rules} \
            -t {params.category} \
            -l {log}
        """

# Aggregate all somatic civic-annotated MAF tables.
rule somatic_cna_civic_aggregate:
    input:
        expand("annotation/somatic_cna_civic/{tsample}_vs_{nsample}.tsv", zip, tsample=tsamples, nsample=nsamples),
    output:
        "aggregate/somatic_cna/somatic_calls_civic.tsv.gz" ,
    conda:
        "metaprism_python"
    log:
        "aggregate/somatic_cna/somatic_cna_civic_aggregate.log" 
    threads: 1
    resources:
        queue="shortq",
        mem_mb=16000,
        time_min=60
    shell:
        """
        python -u workflow/rules/Clinic/Cnv_Annotation/scripts/06.1_concatenate_tables.py \
            --files {input} \
            --output {output} &> {log}
        """

rule somatic_cna_oncokb_aggregate:
    input:
        expand("annotation/somatic_cna_oncokb/{tsample}_vs_{nsample}.tsv", zip, tsample=tsamples, nsample=nsamples),
    output:
        "aggregate/somatic_cna/somatic_calls_oncokb.tsv.gz" ,
    conda:
        "metaprism_python"
    log:
        "aggregate/somatic_cna/somatic_cna_oncokb_aggregate.log" 
    threads: 1
    resources:
        queue="shortq",
        mem_mb=16000,
        time_min=60
    shell:
        """
        python -u workflow/rules/Clinic/Cnv_Annotation/scripts/06.1_concatenate_tables.py \
            --files {input} \
            --output {output} &> {log}
        """

# Aggregate oncokb and civic mutation annotations.
rule somatic_cna_union_ann:
    input:
        civ="aggregate/somatic_cna/somatic_calls_civic.tsv.gz" ,
        okb="aggregate/somatic_cna/somatic_calls_oncokb.tsv.gz" ,
    output:
        "aggregate/somatic_cna/somatic_calls_union_ann.tsv.gz" ,
    conda:
        "metaprism_python"
    log:
        "aggregate/somatic_cna/somatic_cna_union_ann.log" 
    resources:
        queue="shortq",
        mem_mb=8000,
        time="00:15:00"
    threads: 1
    shell:
        """
        python -u workflow/rules/Clinic/Cnv_Annotation/scripts/06.2_concatenate_annotations.py \
            --civ {input.civ} \
            --okb {input.okb} \
            --cat cna \
            --output {output} &> {log}
        """
