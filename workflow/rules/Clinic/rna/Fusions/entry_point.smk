from snakemake.utils import min_version
min_version("6.0")

include: "/mnt/beegfs/userdata/j_wang/pipelines/metaprism_rnafusion_pipeline/workflow/rules/common.smk"

##### Target rules #####

def get_input_rule_all(w):
    inputs = []

    # +++++++++++++++++++++++
    #### IRODS
    # +++++++++++++++++++++++
    # inputs += expand('%s/data/fastq/{sample}_R{stream}.fastq.gz' % R_FOLDER, sample=samples,stream=streams)
    # +++++++++++++++++++++++
    # +++++++++++++++++++++++
    ### NF-CORE
    # +++++++++++++++++++++++
    # Fusions
    # inputs.append(f"{R_FOLDER}/nf-core/tools")
    # Quality controls
    inputs.append(f"{R_FOLDER}/nf-core/MultiQC")
    # Nextflow final report
    inputs.append(f"{R_FOLDER}/nf-core/Reports")
    # +++++++++++++++++++++++
    #### AGGREGATE
    # +++++++++++++++++++++++
    # inputs += expand("%s/aggregate/{algo}.tsv.gz" % R_FOLDER, algo=algos)
    # inputs.append("%s/aggregate/calls_fusions_raw_all.tsv.gz" % R_FOLDER)
    # if config["general"]["update_gene_symbols"]:
    #     inputs.append("%s/aggregate/calls_fusions_updated_symbols_all.tsv.gz" % R_FOLDER)
    # +++++++++++++++++++++++
    #### FILTER
    # +++++++++++++++++++++++
    inputs.append("%s/filter/calls_fusions_all.tsv.gz" % R_FOLDER)
    inputs.append("%s/filter/calls_fusions.tsv.gz" % R_FOLDER)
    # inputs.append("%s/filter/upset_filters_wt_breakpoints.pdf" % R_FOLDER)
    # inputs.append("%s/filter/upset_filters_wo_breakpoints.pdf" % R_FOLDER)
    # +++++++++++++++++++++++
    #### ANNOTATE
    # +++++++++++++++++++++++
    inputs.append("%s/annotate/calls_fusions_civic.tsv.gz" % R_FOLDER)
    inputs.append("%s/annotate/calls_fusions_oncokb.tsv.gz" % R_FOLDER)
    inputs.append("%s/annotate/calls_fusions_civic_oncokb.tsv.gz" % R_FOLDER)

    return inputs

rule all:
    input:
        get_input_rule_all

##### Modules #####

# include: "rules/fastq.smk"
# include: "/mnt/beegfs/userdata/j_wang/pipelines/metaprism_rnafusion_pipeline/workflow/rules/nf-core.smk"
# include: "/mnt/beegfs/userdata/j_wang/pipelines/metaprism_rnafusion_pipeline/workflow/rules/aggregate.smk"
# include: "/mnt/beegfs/userdata/j_wang/pipelines/metaprism_rnafusion_pipeline/workflow/rules/filter.smk"
# include: "/mnt/beegfs/userdata/j_wang/pipelines/metaprism_rnafusion_pipeline/workflow/rules/annotate.smk"

# include: "/mnt/beegfs/userdata/j_wang/pipelines/dna_routine_pipeline/workflow/rules/Clinic/config/conf.smk"

include: "/mnt/beegfs/userdata/j_wang/pipelines/metaprism_rnafusion_pipeline/workflow/rules/aggregate.smk"
include: "/mnt/beegfs/userdata/j_wang/pipelines/metaprism_rnafusion_pipeline/workflow/rules/filter.smk"
include: "/mnt/beegfs/userdata/j_wang/pipelines/metaprism_rnafusion_pipeline/workflow/rules/annotate.smk"

