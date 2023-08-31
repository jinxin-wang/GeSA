rule aggregate_alterations_across_modalities:
    input:
        cna = "aggregate/somatic_cna/somatic_calls_union_ann.tsv.gz" ,
        fus = "fusions/tcga_annotated_filtered_union_ann.tsv.gz",
        mut = "aggregate/somatic_maf/somatic_calls_union_ann.maf.gz",
        gen        = config["data"]["resources"]["cancer_genes"],
        target_bed = config["data"]["resources"]["target_bed"],
        drug       = config["data"]["resources"]["drug"],
    conda: "metaprism_main"
    log:
        "logs/aggregate_alterations_across_modalities.log",
    output:
        best = "alterations/aggregated_alterations.tsv",
        all  = "alterations/aggregated_alterations_all.tsv",
    resources:
        queue = "shortq",
        mem_mb= 8000,
    threads: 1
    shell:
        """
        Rscript workflow/scripts/01.1_aggregate_alterations_across_modalities.R \
            --cna {input.cna} \
            --fus {input.fus} \
            --mut {input.mut} \
            --target_bed {input.target_bed} \
            --drug {input.drug} \
            --output_best {output.best} \
            --output_all {output.all} \
            --log {log}
        """



## refer to https://github.com/gustaveroussy/MetaPRISM/blob/master/scripts/pipeline_cln/workflow/rules/curate.smk
## cln_prism_in_design_curate.tsv <= 02.4_curate_cln.py 
## bio_prism_in_design_curate.tsv <= 02.3_curate_bio.py 

# rule selection_samples:
#     input:
#         ["%s/%s" % (D_FOLDER, FILEPATHS[cohort]["bio"]["in_design"]) for cohort in config["selection"]["cohorts"]],
#         ["%s/%s" % (D_FOLDER, FILEPATHS[cohort]["cln"]["in_design"]) for cohort in config["selection"]["cohorts"]],
#     output:
#         cnt="%s/selection/selection_tumor_types.tsv" % R_FOLDER,
#         sam=expand("%s/selection/selection_samples_{cohort}.tsv" % R_FOLDER, cohort=config["selection"]["cohorts"])
#     log:
#         "logs/selection_samples.log"
#     conda: "metaprism_main"
#     params:
#         cohorts = config["selection"]["cohorts"],
#         config = "config/config.yaml"
#     resources:
#         partition = "cpu_short",
#         mem_mb = 4000,
#         time = "00:15:00"
#     threads: 1
#     shell:
#         """
#         Rscript ../common/scripts/get_table_selection.R \
#             --cohorts {params.cohorts} \
#             --config {params.config} \
#             --section selection \
#             --output_cnt {output.cnt} \
#             --output_sam {output.sam} \
#             --log {log}
#         """

# rule aggregate_alterations_across_cohorts:
#     input:
#         counts = "selection/selection_tumor_types.tsv",
#         tables = "alterations/aggregated_alterations.tsv",
#     conda: "metaprism_main"
#     log:
#         "logs/aggregate_alterations_across_cohorts.log",
#     output:
#         "logs/alterations/aggregated_alterations.tsv",
#     params:
#         cohorts = config["data"]["cohorts"]
#     resources:
#         queue="shortq",
#         mem_mb=8000,
#     threads: 1
#     shell:
#         """
#         Rscript workflow/scripts/01.2_aggregate_alterations_across_cohorts.R \
#             --cohorts {params.cohorts} \
#             --counts {input.counts} \
#             --tables {input.tables} \
#             --output {output} \
#             --log {log}
#         """
