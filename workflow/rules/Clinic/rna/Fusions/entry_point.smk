import os.path

metaprism_config = {
    "algos": [
        "arriba",
        "fusioninspector",
        "starfusion",
    ],
    "cohort": [
        "prism",
    ],
    "data": {
        "fusion_annotator": "external/FusionAnnotator/FusionAnnotator",
        "resources": {
            "genome_lib_dir": "/mnt/beegfs/database/bioinfo/nf-core-rnafusion/1.2.0/references_downloaded/star-fusion/ctat_genome_lib_build_dir",
            "drivers": "/mnt/beegfs/pipelines/MetaPRISM_Public/data/meta-PRISM/data/resources/curated/cancer_genes_curated.tsv",
            "fusions_lists": "/mnt/beegfs/pipelines/MetaPRISM_Public/data/meta-PRISM/meta-PRISM/resources/fusions_analysis/fusions_lists",
            "gencode": "/mnt/beegfs/pipelines/MetaPRISM_Public/data/meta-PRISM/data/resources/gencode/gencode.v27.annotation.gff3.gene.tsv",
        },
    },
    "params":{
        "oncokb":{
            "code_dir": "/mnt/beegfs/pipelines/MetaPRISM_Public/code/scripts/fusions_analysis/external/oncokb-annotator/",
            "data_dir": "/mnt/beegfs/pipelines/MetaPRISM_Public/code/scripts/fusions_analysis/external/oncokb-annotator/data",
            "token": "722c8d78-b8c0-408c-9ecb-4bd51354e93a",
            "rules_clean": "/mnt/beegfs/pipelines/MetaPRISM_Public/data/meta-PRISM/data/resources/oncokb/OncoKB_Curation_And_Rules.xlsx",
        },
        "civic":{
            "code_dir": "e/mnt/beegfs/software/metaprism/wes/external/CivicAnnotator",
            "data_dir": "/mnt/beegfs/software/metaprism/wes/external/CivicAnnotator/data",
            "database": "/mnt/beegfs/pipelines/MetaPRISM_Public/data/meta-PRISM/data/resources/civic/01-Jan-2022-ClinicalEvidenceSummaries_Annotated.xlsx",
            "rules_clean": "/mnt/beegfs/pipelines/MetaPRISM_Public/data/meta-PRISM/data/resources/civic/CIViC_Curation_And_Rules_Mutation.xlsx",
        },
    },
    "curated_design": "/mnt/beegfs/pipelines/MetaPRISM_Public/data/cln_prism_in_design_curated.tsv",
    "metaprism_pipeline_prefix": "/mnt/beegfs/pipelines/MetaPRISM_Public/code/scripts/fusions_analysis",
}

SAMPLE = []

def get_fusion(wildcards, config) -> str:
    prefix = ""
    suffix = ""
    if str(wildcards.algo) == "arriba":
        prefix = "arriba"
        suffix = "_R.arriba.fusions.tsv"
    elif str(wildcards.algo) == "starfusion":
        prefix = "starfusion"
        suffix = "_R.starfusion.abridged.tsv"
    elif str(wildcards.algo) == "fusioninspector":
        prefix = "fusioninspector"
        suffix = "_R.FusionInspector.fusions.tsv"

    return f"{prefix}/{wildcards.sample}{suffix}"


wildcard_constraints:
    algo=r"|".join(config["algos"]),
    cohort=r"|".join(config["cohort"]),


rule aggregate_tables_samples:
    input:
        annotation_folder="{algo}",
        script=f"{metaprism_config['metaprism_pipeline_prefix']}/workflow/scripts/00.1_aggregate_tables_samples.py",
    conda: "metaprism_r"
    output:
        agg="fusion_annotation/{algo}/sample_aggregation.tsv",
        output_list="fusion_annotation/{algo}/sample_list.tsv",
        # agg="%s/{cohort}/rna/{algo}/{cohort}_{algo}.tsv.gz" % D_FOLDER
    params:
        output_list=lambda wildcards, output: output["output_list"],
        data_folder=lambda wildcards, input: input,
        cohort=config.get("cohort", "prism"),
    resources:
        mem_mb=16000,
        partition="shortq",
        time_min=30
    threads: 1
    log:
        "logs/aggregate_tables_samples/{algo}.log"
    shell:
        """python {input.script} \
            --cohort {params.cohort} \
            --algo_folder {wildcards.algo} \
            --data_folder {params.data_folder} \
            --output_list {output.output_list} \
            --output_agg {output.agg} &> {log}
        """


rule aggregate_tables_callers:
    input:
        agg=expand(
            "fusion_annotation/{algo}/sample_aggregation.tsv",
            algo=config["algos"]
        ),
        script=f"{metaprism_config['metaprism_pipeline_prefix']}/workflow/scripts/00.2_aggregate_tables_callers.R",
    conda: "metaprism_r"
    output:
        # "%s/{cohort}/rna/fusions/{cohort}_aggregated_callers.tsv.gz" % D_FOLDER
        agg="fusion_annotation/aggregated_callers.tsv.gz"
    params:
        algos=config["algos"],
        cohort=config.get("cohort", "prism"),
    resources:
        mem_mb=30000,
        partition="shortq",
        time_min=60
    threads: 1
    log:
        "logs/aggregate_tables_callers.log"
    shell:
        """Rscript {input.script} \
            --cohort {params.cohort} \
            --algos {params.algos} \
            --output {output.agg} \
            --log {log}"""


rule annotate_fusions_FusionAnnotator_1:
    input:
        # table="%s/{cohort}/rna/fusions/{cohort}_aggregated_callers.tsv.gz" % D_FOLDER,
        table="fusion_annotation/aggregated_callers.tsv.gz",
        script=f"{metaprism_config['metaprism_pipeline_prefix']}/workflow/scripts/00.3_annotate_fusions_FusionAnnotator_1.py",
    conda:
        "metaprism_r"
    output:
        # temp("%s/{cohort}/rna/fusions/{cohort}_aggregated_FusionAnnotator_1.tsv" % D_FOLDER)
        table="fusion_annotation/aggregated_FusionAnnotator_1.tsv"
    resources:
        mem_mb=16000,
        partition="shortq",
        time_min=60
    threads: 1
    log:
        "logs/annotate_fusions_FusionAnnotator_1.log"
    shell:
        """python {input.script} --input {input.table} \
            --output {output.table} &> {log}"""


rule annotate_fusions_FusionAnnotator_2:
    input:
        # "%s/{cohort}/rna/fusions/{cohort}_aggregated_FusionAnnotator_1.tsv" % D_FOLDER
        table="fusion_annotation/aggregated_callers.tsv.gz",
        genome_lib_dir=config["data"]["resources"]["genome_lib_dir"],
        app=config["data"]["fusion_annotator"],
    conda:
        "../envs/FusionAnnotator.yaml"
    output:
        # temp("%s/{cohort}/rna/fusions/{cohort}_aggregated_FusionAnnotator_2.tsv" % D_FOLDER)
        table="fusion_annotation/aggregated_FusionAnnotator_2.tsv"
    params:
        ""
    resources:
        mem_mb=16000,
        partition="shortq",
        time_min=60
    threads: 1
    log:
        "logs/annotate_fusions_FusionAnnotator_2.log"
    shell:
        """{input.app} --genome_lib_dir {input.genome_lib_dir} \
            --annotate {input.table} \
            --fusion_name_col Fusion_Id 1> {output.table} 2> {log}"""


rule annotate_fusions_FusionAnnotator_3:
    input:
        # fusions="%s/{cohort}/rna/fusions/{cohort}_aggregated_callers.tsv.gz" % D_FOLDER,
        fusions="fusion_annotation/aggregated_callers.tsv.gz",
        # annots="%s/{cohort}/rna/fusions/{cohort}_aggregated_FusionAnnotator_2.tsv" % D_FOLDER,
        annots="fusion_annotation/aggregated_FusionAnnotator_2.tsv",
        script=f"{metaprism_config['metaprism_pipeline_prefix']}/workflow/scripts/00.3_annotate_fusions_FusionAnnotator_3.py"
    conda:
        "metaprism_r"
    output:
        # "%s/{cohort}/rna/fusions/{cohort}_annotated_FusionAnnotator.tsv.gz" % D_FOLDER
        "fusion_annotation/aggregated_FusionAnnotator.tsv",
    resources:
        mem_mb=16000,
        partition="shortq",
        time_min=60
    threads: 1
    log:
        "logs/annotate_fusions_FusionAnnotator_3.log"
    shell:
        """python {input.script} --input_fusions {input.fusions} \
            --input_annots {input.annots} \
            --output {output} &> {log}"""


rule annotate_fusions_custom:
    input:
        # fusions="%s/{cohort}/rna/fusions/{cohort}_annotated_FusionAnnotator.tsv.gz" % D_FOLDER,
        fusions="fusion_annotation/aggregated_FusionAnnotator.tsv",
        drivers=config["data"]["resources"]["drivers"],
        gencode=config["data"]["resources"]["gencode"],
        fusions_lists=config["data"]["resources"]["fusions_lists"],
        script=f"{metaprism_config['metaprism_pipeline_prefix']}/workflow/scripts/00.4_annotate_fusions_custom.R",
    conda:
        "metaprism_r"
    output:
        # "%s/{cohort}/rna/fusions/{cohort}_annotated.tsv.gz" % D_FOLDER
        "fusion_annotation/annotate_fusions_custom.tsv",
    resources:
        mem_mb=8000,
        partition="shortq",
        time_min=15
    threads: 1
    log:
        "logs/annotate_fusions_custom.log"
    shell:
        """Rscript {input.script} \
            --input {input.fusions} \
            --fusions_lists {input.fusions_lists} \
            --gencode {input.gencode} \
            --drivers {input.drivers} \
            --output {output} \
            --log {log}"""


rule filter_fusions:
    input:
        # "%s/{cohort}/rna/fusions/{cohort}_annotated.tsv.gz" % D_FOLDER
        fusion="fusion_annotation/annotate_fusions_custom.tsv",
        script=f"{metaprism_config['metaprism_pipeline_prefix']}/workflow/scripts/00.7_filter_fusions.py",
    conda:
        "metaprism_r"
    output:
        # fus_filters="%s/{cohort}/rna/fusions/{cohort}_filters.tsv.gz" % D_FOLDER,
        fus_filters="fusion_annotation/filters.tsv.gz",
        # fus="%s/{cohort}/rna/fusions/{cohort}_annotated_filtered.tsv.gz" % D_FOLDER,
        fus="fusion_annotation/annotated_filtered.tsv.gz",
        # sam="%s/{cohort}/rna/fusions/sample_list.tsv" % D_FOLDER
        sam="fusion_annotation/sample_list.tsv",
    resources:
        mem_mb=4000,
        partition="shortq",
        time_min=30
    threads: 1
    params:
        cohort=config.get("cohort", "prism"),
    log:
        "logs/filter_fusions.log"
    shell:
        """python {input.script} \
            --cohort {params.cohort} \
            --input {input.fusion} \
            --output_sam {output.sam} \
            --output_fus_filters {output.fus_filters} \
            --output_fus {output.fus} &> {log}
        """


rule oncokb_preprocess:
    input:
        # fus="%s/{cohort}/rna/fusions/{cohort}_annotated_filtered.tsv.gz" % D_FOLDER,
        # sam="%s/{cohort}/rna/fusions/sample_list.tsv" % D_FOLDER,
        fus="fusion_annotation/annotated_filtered.tsv.gz",
        sam="fusion_annotation/sample_list.tsv",
        # bio="%s/{cohort}/clinical/curated/bio_{cohort}_in_design_curated.tsv" % D_FOLDER # TODO: Find origin
        bio=config["curated_design"],
        script=f"{metaprism_config['metaprism_pipeline_prefix']}/workflow/scripts/00.8.1_oncokb_preprocess.py",
    output:
        # temp(directory("%s/{cohort}/rna/fusions/oncokb_pre" % D_FOLDER))
        temp(expand("fusion_annotation/oncokb_pre/{sample}.tsv", sample=SAMPLE))
    log:
        "logs/oncokb_preprocess.log"
    conda:
        "metaprism_r"
    threads: 1
    resources:
        queue="shortq",
        mem_mb=4000,
        time_min=10
    params:
        out_dir=lambda wildcards, output: os.path.dirname(output[0])
    shell:
        """
        python {input.script} \
            --table_fus {input.fus} \
            --table_sam {input.sam} \
            --table_bio {input.bio} \
            --output {params.out_dir} &> {log}
        """


rule oncokb_annotate:
    input:
        # "%s/{cohort}/rna/fusions/oncokb_pre/{sample}.tsv" % D_FOLDER
        fusions="fusion_annotation/oncokb_pre/{sample}.tsv",
        code_dir=config["params"]["oncokb"]["code_dir"],
    output:
        # temp("%s/{cohort}/rna/fusions/oncokb/{sample}.tsv" % D_FOLDER)
        "fusion_annotation/oncokb/{sample}.tsv",
    log:
        "logs/oncokb_annotate/{sample}.log"
    conda:
        "metaprism_r"
    params:
        token=config["params"]["oncokb"]["token"],
        tumor_type=get_tumor_type_mskcc_oncotree
    threads: 1
    resources:
        queue="shortq",
        mem_mb=1000,
        time_min=10
    shell:
        """
        python {input.code_dir}/FusionAnnotator.py \
            -i {input.fusions} \
            -b {params.token} \
            -t {params.tumor_type} \
            -o {output} &> {log}
        """


rule oncokb_postprocess:
    input:
        # fus="%s/{cohort}/rna/fusions/{cohort}_annotated_filtered.tsv.gz" % D_FOLDER,
        # sam="%s/{cohort}/rna/fusions/sample_list.tsv" % D_FOLDER,
        fus="fusion_annotation/annotated_filtered.tsv.gz",
        sam="fusion_annotation/sample_list.tsv",
        # bio="%s/{cohort}/clinical/curated/bio_{cohort}_in_design_curated.tsv" % D_FOLDER,
        bio=config["curated_design"],
        okb=oncokb_postprocess_input,
        script=f"{metaprism_config['metaprism_pipeline_prefix']}/workflow/scripts/00.8.2_oncokb_postprocess.py"
    output:
        # "%s/{cohort}/rna/fusions/{cohort}_annotated_filtered_oncokb.tsv.gz" % D_FOLDER
        "fusion_annotation/annotated_filtered_oncokb.tsv.gz"
    log:
        "logs/oncokb_postprocess.log"
    conda:
        "metaprism_r"
    threads: 1
    resources:
        queue="shortq",
        mem_mb=4000,
        time_min=10
    shell:
        """
        python {input.script} \
            --table_fus {input.fus} \
            --table_sam {input.sam} \
            --table_bio {input.bio} \
            --oncokb {input.okb} \
            --output {output} &> {log}
        """


checkpoint civic_preprocess:
    input:
        #  fus="%s/{cohort}/rna/fusions/{cohort}_annotated_filtered.tsv.gz" % D_FOLDER,
        #  sam="%s/{cohort}/rna/fusions/sample_list.tsv" % D_FOLDER,
        #  bio="%s/{cohort}/clinical/curated/bio_{cohort}_in_design_curated.tsv" % D_FOLDER
        fus="fusion_annotation/annotated_filtered.tsv.gz",
        sam="fusion_annotation/sample_list.tsv",
        bio=config["curated_design"],
        script=f"{metaprism_config['metaprism_pipeline_prefix']}/workflow/scripts/00.9.1_civic_preprocess.py",
    output:
        temp(expand("fusion_annotation/civic_pre/{sample}.tsv", sample=SAMPLE))
    log:
        "logs/civic_preprocess.log"
    conda:
        "metaprism_r"
    threads: 1
    resources:
        queue="shortq",
        mem_mb=4000,
        time_min=20
    params:
        out_dir=lambda wildcards, output: os.path.dirname(output[0])
    shell:
        """
        python {input.script} \
            --table_fus {input.fus} \
            --table_sam {input.sam} \
            --table_bio {input.bio} \
            --output {params.out_dir} &> {log}
        """


rule civic_annotate:
    input:
        # "%s/{cohort}/rna/fusions/civic_pre/{sample}.tsv" % D_FOLDER
        fusion="fusion_annotation/civic_pre/{sample}.tsv"
        code_dir=config["params"]["civic"]["code_dir"],
        civic=config["params"]["civic"]["database"],
        rules=config["params"]["civic"]["rules_clean"],
    output:
        # "%s/{cohort}/rna/fusions/civic/{sample}.tsv" % D_FOLDER
        "fusion_annotation/civic/{sample}.tsv"
    log:
        "logs/civic_annotate/{sample}.log"
    conda:
        "metaprism_r"
    params:
        tumor_type=get_tumor_type_civic
    threads: 1
    resources:
        queue="shortq",
        mem_mb=1000,
        time_min=10
    shell:
        """
        python {input.code_dir}/civic_annotator.py \
            --input {input.fusion} \
            --civic {input.civic} \
            --rules {input.rules} \
            --category fus \
            --tumor_types "{params.tumor_type}" \
            --output {output} &> {log}
        """


rule civic_postprocess:
    input:
        # fus="%s/{cohort}/rna/fusions/{cohort}_annotated_filtered.tsv.gz" % D_FOLDER,
        # sam="%s/{cohort}/rna/fusions/sample_list.tsv" % D_FOLDER,
        # bio="%s/{cohort}/clinical/curated/bio_{cohort}_in_design_curated.tsv" % D_FOLDER,
        fus="fusion_annotation/annotated_filtered.tsv.gz",
        sam="fusion_annotation/sample_list.tsv",
        bio=config["curated_design"],
        civ=civic_postprocess_input,
        script=f"{metaprism_config['metaprism_pipeline_prefix']}/workflow/scripts/00.9.2_civic_postprocess.py",
    output:
        # "%s/{cohort}/rna/fusions/{cohort}_annotated_filtered_civic.tsv.gz" % D_FOLDER
        "fusion_annotation/annotated_filtered_civic.tsv.gz"
    log:
        "logs/civic_postprocess.log"
    conda:
        "metaprism_r"
    threads: 1
    resources:
        queue="shortq",
        mem_mb=4000,
        time_min=20
    shell:
        """
        python {input.script} \
            --table_fus {input.fus} \
            --table_sam {input.sam} \
            --table_bio {input.bio} \
            --civic {input.civ} \
            --output {output} &> {log}
        """


rule union_ann:
    # input:
    #     civ="%s/{cohort}/rna/fusions/{cohort}_annotated_filtered_civic.tsv.gz" % D_FOLDER,
    #     okb="%s/{cohort}/rna/fusions/{cohort}_annotated_filtered_oncokb.tsv.gz" % D_FOLDER,
    input:
        civ="fusion_annotation/annotated_filtered_civic.tsv.gz",
        okb="fusion_annotation/annotated_filtered_oncokb.tsv.gz",
        script=f"{metaprism_config['metaprism_pipeline_prefix']}/workflow/scripts/00.10_concatenate_fus_annotations.py",
    output:
        # "%s/{cohort}/rna/fusions/{cohort}_annotated_filtered_union_ann.tsv.gz" % D_FOLDER
        "fusion_annotation/annotated_filtered_union_ann.tsv.gz"
    log:
        "logs/union_ann.log"
    conda:
        "metaprism_r"
    threads: 1
    resources:
        queue="shortq",
        mem_mb=4000,
        time_min=20
    shell:
        """
        python {input.script} \
            --civ {input.civ} \
            --okb {input.okb} \
            --output {output} &> {log}
        """
