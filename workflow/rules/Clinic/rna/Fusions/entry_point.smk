import os.path
import os
import pandas

from pathlib import Path

metaprism_config = {
    "algos": [
        "Arriba",
        # "fusioninspector",
        "Fusioncatcher",
        "Star-Fusion",
        "EricScript",
        "Pizzly",
        "Squid",
    ],
    "cohort": ["prism"],
    "data": {
        "fusion_annotator": "/mnt/beegfs/pipelines/MetaPRISM_Public/code/scripts/fusions_analysis/external/FusionAnnotator/FusionAnnotator",
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

clinical_df = pandas.read_csv(
    metaprism_config["curated_design"],
    sep="\t",
    header=0,
    index_col=0
)[["Project_TCGA_More", "MSKCC_Oncotree", "Civic_Disease"]]

def get_column_table_sample(wildcards, col, table=clinical_df):
    """Get the value of the column col for the sample"""
    value = table.loc[wildcards.sample, col]
    return value


def get_tumor_type_mskcc_oncotree(wildcards):
    """Get the tumor type MSKCC oncotree of the sample"""
    return get_column_table_sample(wildcards, "MSKCC_Oncotree")


def get_tumor_type_civic(wildcards):
    """Get the tumor type Civic_Disease of the sample"""
    return get_column_table_sample(wildcards, "Civic_Disease")

def get_samples_from_arriba(prefix: str = "arriba", suffix: str = ".arriba.fusions.tsv"):
    path_list = Path(prefix).glob(f"*.{suffix}")
    return [s[len(prefix):len(suffix)] for s in path_list]

SAMPLE = get_samples_from_arriba()

wildcard_constraints:
    algo=r"|".join(metaprism_config["algos"]),
    cohort=r"|".join(metaprism_config["cohort"]),


rule target:
    input:
        expand(
            "fusion_annotation/{cohort}/annotated_filtered_union_ann.tsv.gz",
            cohort=metaprism_config["cohort"],
        )


rule soft_link:
    input:
        "results/tools/{algo}",
    output:
        directory("{cohort}/rna/{algo}"),
    threads: 1
    resources:
        mem_mb=512,
        partition="shortq",
        time_min=2,
    log:
        "logs/soft_link/{algo}.{cohort}.log"
    params:
        ln="--symbolic --force --relative --verbose",
        find="-type d",
        mk="--parents --verbose",
    conda:
        "metaprism_r"
    shell:
        'mkdir {params.mk} {output} > {log} 2>&1 && '
        'find {input} {params.find} 2>> {log} | while read SAMPLE_DIR; do '
        'ln {params.ln} "${{SAMPLE_DIR}}" "{output}/$(basename ${{SAMPLE_DIR}})-ARN" >> {log} 2>&1 ; '
        'done'


rule aggregate_tables_samples:
    input:
        annotation_folder="{cohort}/rna/{algo}",
        script=f"{metaprism_config['metaprism_pipeline_prefix']}/workflow/scripts/00.1_aggregate_tables_samples.py",
    conda: 
        "metaprism_r"
    output:
        agg="fusion_annotation/{cohort}/{algo}/sample_aggregation.tsv.gz",
        output_list="fusion_annotation/{cohort}/{algo}/sample_list.tsv",
        # agg="%s/{cohort}/rna/{algo}/{cohort}_{algo}.tsv.gz" % D_FOLDER
    params:
        output_list=lambda wildcards, output: output["output_list"],
        cohort=lambda wildcards: wildcards.cohort,
        data_dir=os.getcwd(),
    resources:
        mem_mb=16000,
        partition="shortq",
        time_min=30
    threads: 1
    log:
        "logs/aggregate_tables_samples/{algo}.{cohort}.log"
    shell:
        """python {input.script} \
            --cohort {wildcards.cohort} \
            --algo_folder {wildcards.algo} \
            --data_folder {params.data_dir} \
            --output_list {output.output_list} \
            --output_agg {output.agg} &> {log}
        """


rule aggregate_tables_callers:
    input:
        agg=expand(
            "fusion_annotation/{cohort}/{algo}/sample_aggregation.tsv.gz",
            algo=metaprism_config["algos"],
            allow_missing=True
        ),
        script=f"{metaprism_config['metaprism_pipeline_prefix']}/workflow/scripts/00.2_aggregate_tables_callers.R",
        gencode='/mnt/beegfs/database/bioinfo/Meta-Prism/gencode.v27.annotation.gff3.gene.tsv',
        hgnc="/mnt/beegfs/database/bioinfo/Meta-Prism/hgnc_all_symbols_03012022.tsv",
    conda: 
        "metaprism_r"
    output:
        # "%s/{cohort}/rna/fusions/{cohort}_aggregated_callers.tsv.gz" % D_FOLDER
        agg="fusion_annotation/{cohort}/aggregated_callers.tsv.gz"
    params:
        algos=metaprism_config["algos"],
    resources:
        mem_mb=30000,
        partition="shortq",
        time_min=60
    threads: 1
    log:
        inner="logs/aggregate_tables_callers/{cohort}.log",
        cmd="logs/aggregate_tables_callers/{cohort}.cmd.log",
    shell:
        """Rscript {input.script} \
            --cohort {wildcards.cohort} \
            --algos {params.algos} \
            --output {output.agg} \
            --gencode {input.gencode} \
            --hgnc {input.hgnc} \
            --log {log.inner} > {log.cmd} 2>&1 """


rule annotate_fusions_FusionAnnotator_1:
    input:
        # table="%s/{cohort}/rna/fusions/{cohort}_aggregated_callers.tsv.gz" % D_FOLDER,
        table="fusion_annotation/{cohort}/aggregated_callers.tsv.gz",
        script=f"{metaprism_config['metaprism_pipeline_prefix']}/workflow/scripts/00.3_annotate_fusions_FusionAnnotator_1.py",
    conda:
        "metaprism_r"
    output:
        # temp("%s/{cohort}/rna/fusions/{cohort}_aggregated_FusionAnnotator_1.tsv" % D_FOLDER)
        table="fusion_annotation/{cohort}/aggregated_FusionAnnotator_1.tsv"
    resources:
        mem_mb=16000,
        partition="shortq",
        time_min=60
    threads: 1
    log:
        "logs/annotate_fusions_FusionAnnotator_1/{cohort}.log"
    shell:
        """python {input.script} --input {input.table} \
            --output {output.table} &> {log}"""


rule annotate_fusions_FusionAnnotator_2:
    input:
        # "%s/{cohort}/rna/fusions/{cohort}_aggregated_FusionAnnotator_1.tsv" % D_FOLDER
        table="fusion_annotation/{cohort}/aggregated_FusionAnnotator_1.tsv",
        genome_lib_dir=metaprism_config["data"]["resources"]["genome_lib_dir"],
        app=metaprism_config["data"]["fusion_annotator"],
    conda:
        "metaprism_r"
    output:
        # temp("%s/{cohort}/rna/fusions/{cohort}_aggregated_FusionAnnotator_2.tsv" % D_FOLDER)
        table="fusion_annotation/{cohort}/aggregated_FusionAnnotator_2.tsv"
    params:
        ""
    resources:
        mem_mb=16000,
        partition="shortq",
        time_min=60
    threads: 1
    log:
        "logs/annotate_fusions_FusionAnnotator_2/{cohort}.log"
    shell:
        """{input.app} --genome_lib_dir {input.genome_lib_dir} \
            --annotate {input.table} \
            --fusion_name_col Fusion_Id 1> {output.table} 2> {log}"""


rule annotate_fusions_FusionAnnotator_3:
    input:
        # fusions="%s/{cohort}/rna/fusions/{cohort}_aggregated_callers.tsv.gz" % D_FOLDER,
        fusions="fusion_annotation/{cohort}/aggregated_callers.tsv.gz",
        # annots="%s/{cohort}/rna/fusions/{cohort}_aggregated_FusionAnnotator_2.tsv" % D_FOLDER,
        annots="fusion_annotation/{cohort}/aggregated_FusionAnnotator_2.tsv",
        script=f"{metaprism_config['metaprism_pipeline_prefix']}/workflow/scripts/00.3_annotate_fusions_FusionAnnotator_3.py"
    conda:
        "metaprism_r"
    output:
        # "%s/{cohort}/rna/fusions/{cohort}_annotated_FusionAnnotator.tsv.gz" % D_FOLDER
        "fusion_annotation/{cohort}/aggregated_FusionAnnotator.tsv",
    resources:
        mem_mb=16000,
        partition="shortq",
        time_min=60
    threads: 1
    log:
        "logs/annotate_fusions_FusionAnnotator_3/{cohort}.log"
    shell:
        """python {input.script} --input_fusions {input.fusions} \
            --input_annots {input.annots} \
            --output {output} &> {log}"""


rule annotate_fusions_custom:
    input:
        # fusions="%s/{cohort}/rna/fusions/{cohort}_annotated_FusionAnnotator.tsv.gz" % D_FOLDER,
        fusions="fusion_annotation/{cohort}/aggregated_FusionAnnotator.tsv",
        drivers=metaprism_config["data"]["resources"]["drivers"],
        gencode=metaprism_config["data"]["resources"]["gencode"],
        fusions_lists=metaprism_config["data"]["resources"]["fusions_lists"],
        script=f"{metaprism_config['metaprism_pipeline_prefix']}/workflow/scripts/00.4_annotate_fusions_custom.R",
    conda:
        "metaprism_r"
    output:
        # "%s/{cohort}/rna/fusions/{cohort}_annotated.tsv.gz" % D_FOLDER
        "fusion_annotation/{cohort}/annotate_fusions_custom.tsv",
    resources:
        mem_mb=8000,
        partition="shortq",
        time_min=15
    threads: 1
    log:
        "logs/annotate_fusions_custom/{cohort}.log"
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
        fusion="fusion_annotation/{cohort}/annotate_fusions_custom.tsv",
        script=f"{metaprism_config['metaprism_pipeline_prefix']}/workflow/scripts/00.7_filter_fusions.py",
    conda:
        "metaprism_r"
    output:
        # fus_filters="%s/{cohort}/rna/fusions/{cohort}_filters.tsv.gz" % D_FOLDER,
        fus_filters="fusion_annotation/{cohort}/filters.tsv.gz",
        # fus="%s/{cohort}/rna/fusions/{cohort}_annotated_filtered.tsv.gz" % D_FOLDER,
        fus="fusion_annotation/{cohort}/annotated_filtered.tsv.gz",
        # sam="%s/{cohort}/rna/fusions/sample_list.tsv" % D_FOLDER
        sam="fusion_annotation/{cohort}/sample_list.tsv",
    resources:
        mem_mb=4000,
        partition="shortq",
        time_min=30
    threads: 1
    log:
        "logs/filter_fusions/{cohort}.log"
    shell:
        """python {input.script} \
            --cohort {wildcards.cohort} \
            --input {input.fusion} \
            --output_sam {output.sam} \
            --output_fus_filters {output.fus_filters} \
            --output_fus {output.fus} &> {log}
        """


rule oncokb_preprocess:
    input:
        # fus="%s/{cohort}/rna/fusions/{cohort}_annotated_filtered.tsv.gz" % D_FOLDER,
        # sam="%s/{cohort}/rna/fusions/sample_list.tsv" % D_FOLDER,
        fus="fusion_annotation/{cohort}/annotated_filtered.tsv.gz",
        sam="fusion_annotation/{cohort}/sample_list.tsv",
        # bio="%s/{cohort}/clinical/curated/bio_{cohort}_in_design_curated.tsv" % D_FOLDER # TODO: Find origin
        bio=metaprism_config["curated_design"],
        script=f"{metaprism_config['metaprism_pipeline_prefix']}/workflow/scripts/00.8.1_oncokb_preprocess.py",
    output:
        # temp(directory("%s/{cohort}/rna/fusions/oncokb_pre" % D_FOLDER))
        temp(expand("fusion_annotation/{cohort}/oncokb_pre/{sample}.tsv", sample=SAMPLE))
    log:
        "logs/oncokb_preprocess/{cohort}.log"
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
        fusions="fusion_annotation/{cohort}/oncokb_pre/{sample}.tsv",
        code_dir=metaprism_config["params"]["oncokb"]["code_dir"],
    output:
        # temp("%s/{cohort}/rna/fusions/oncokb/{sample}.tsv" % D_FOLDER)
        "fusion_annotation/{cohort}/oncokb/{sample}.tsv",
    log:
        "logs/oncokb_annotate/{sample}.{cohort}.log"
    conda:
        "metaprism_r"
    params:
        token=metaprism_config["params"]["oncokb"]["token"],
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
        fus="fusion_annotation/{cohort}/annotated_filtered.tsv.gz",
        sam="fusion_annotation/{cohort}/sample_list.tsv",
        # bio="%s/{cohort}/clinical/curated/bio_{cohort}_in_design_curated.tsv" % D_FOLDER,
        bio=metaprism_config["curated_design"],
        okb=expand("fusion_annotation/{cohort}/oncokb/{sample}.tsv", sample=SAMPLE, allow_missing=True),
        script=f"{metaprism_config['metaprism_pipeline_prefix']}/workflow/scripts/00.8.2_oncokb_postprocess.py"
    output:
        # "%s/{cohort}/rna/fusions/{cohort}_annotated_filtered_oncokb.tsv.gz" % D_FOLDER
        "fusion_annotation/{cohort}/annotated_filtered_oncokb.tsv.gz"
    log:
        "logs/oncokb_postprocess/{cohort}.log"
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
        fus="fusion_annotation/{cohort}/annotated_filtered.tsv.gz",
        sam="fusion_annotation/{cohort}/sample_list.tsv",
        bio=metaprism_config["curated_design"],
        script=f"{metaprism_config['metaprism_pipeline_prefix']}/workflow/scripts/00.9.1_civic_preprocess.py",
    output:
        temp(expand("fusion_annotation/{cohort}/civic_pre/{sample}.tsv", sample=SAMPLE))
    log:
        "logs/civic_preprocess/{cohort}.log"
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
        fusion="fusion_annotation/{cohort}/civic_pre/{sample}.tsv",
        code_dir=metaprism_config["params"]["civic"]["code_dir"],
        civic=metaprism_config["params"]["civic"]["database"],
        rules=metaprism_config["params"]["civic"]["rules_clean"],
    output:
        # "%s/{cohort}/rna/fusions/civic/{sample}.tsv" % D_FOLDER
        "fusion_annotation/{cohort}/civic/{sample}.tsv"
    log:
        "logs/civic_annotate/{sample}.{cohort}.log"
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
        fus="fusion_annotation/{cohort}/annotated_filtered.tsv.gz",
        sam="fusion_annotation/{cohort}/sample_list.tsv",
        bio=metaprism_config["curated_design"],
        civ=expand(
            "fusion_annotation/{cohort}/civic_pre/{sample}.tsv", sample=SAMPLE, allow_missing=True
        ),
        script=f"{metaprism_config['metaprism_pipeline_prefix']}/workflow/scripts/00.9.2_civic_postprocess.py",
    output:
        # "%s/{cohort}/rna/fusions/{cohort}_annotated_filtered_civic.tsv.gz" % D_FOLDER
        "fusion_annotation/{cohort}/annotated_filtered_civic.tsv.gz"
    log:
        "logs/civic_postprocess/{cohort}.log"
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
        civ="fusion_annotation/{cohort}/annotated_filtered_civic.tsv.gz",
        okb="fusion_annotation/{cohort}/annotated_filtered_oncokb.tsv.gz",
        script=f"{metaprism_config['metaprism_pipeline_prefix']}/workflow/scripts/00.10_concatenate_fus_annotations.py",
    output:
        # "%s/{cohort}/rna/fusions/{cohort}_annotated_filtered_union_ann.tsv.gz" % D_FOLDER
        "fusion_annotation/{cohort}/annotated_filtered_union_ann.tsv.gz"
    log:
        "logs/union_ann/{cohort}.log"
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
