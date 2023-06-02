rule somatic_cna_civic:
    input:
        table_alt="facets/calling/somatic_cnv_gene_calls_filtered/{tsample}_vs_{nsample}.tsv.gz",
        table_cln="metaprism_config/tumor_normal_pairs.tsv",
        table_gen=metaprism_config["params"]["civic"]["gene_list"],
        civic=metaprism_config["params"]["civic"]["evidences"],
        rules=metaprism_config["params"]["civic"]["rules_clean"],
        script_path="/mnt/beegfs/pipelines/MetaPRISM_WES_Pipeline/workflow/scripts/04.3_civic_annotate.sh"
    output:
        table_pre=temp("civic/annotation/somatic_cna_civic/{tsample}_vs_{nsample}_pre.tsv"),
        table_run=temp("civic/annotation/somatic_cna_civic/{tsample}_vs_{nsample}_run.tsv"),
        table_pos="civic/annotation/somatic_cna_civic/{tsample}_vs_{nsample}.tsv",
    log:
        "logs/annotation/somatic_cna_civic/{tsample}_vs_{nsample}.log"
    conda:
        "/mnt/beegfs/pipelines/MetaPRISM_WES_Pipeline/workflow/envs/python.yaml"
    params:
        code_dir=metaprism_config["params"]["civic"]["code_dir"],
        category="cna",
        a_option=lambda wildcards, input: "-a %s" % input.table_alt
    threads: 1
    resources:
        queue="shortq",
        mem_mb=4000,
        time_min=20
    shell:
        """
        bash {input.script_path} \
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

rule somatic_cna_oncokb:
    input:
        table_alt="facets/calling/somatic_cnv_gene_calls_filtered/{tsample}_vs_{nsample}.tsv.gz",
        table_cln="metaprism_config/tumor_normal_pairs.tsv",
        table_gen=metaprism_config["params"]["oncokb"]["gene_list"],
        rules=metaprism_config["params"]["oncokb"]["rules_clean"],
        script_path="/mnt/beegfs/pipelines/MetaPRISM_WES_Pipeline/workflow/scripts/04.3_oncokb_annotate.sh"
    output:
        table_alt_pre=temp("oncokb/annotation/somatic_cna_oncokb/{tsample}_vs_{nsample}_alt_pre.tsv"),
        table_cln_pre=temp("oncokb/annotation/somatic_cna_oncokb/{tsample}_vs_{nsample}_cln_pre.tsv"),
        table_run=temp("oncokb/annotation/somatic_cna_oncokb/{tsample}_vs_{nsample}_run.tsv"),
        table_pos="oncokb/annotation/somatic_cna_oncokb/{tsample}_vs_{nsample}.tsv",
    log:
        "logs/annotation/somatic_cna_oncokb/{tsample}_vs_{nsample}.log"
    conda:
        "/mnt/beegfs/pipelines/MetaPRISM_WES_Pipeline/workflow/envs/python.yaml"
    params:
        token=metaprism_config["params"]["oncokb"]["token"],
        code_dir=metaprism_config["params"]["oncokb"]["code_dir"],
        category="cna",
        a_option=lambda wildcards, input: "-a %s" % input.table_alt
    threads: 1
    resources:
        queue="shortq",
        mem_mb=4000,
        time_min=20
    shell:
        """
        bash {input.script_path} \
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