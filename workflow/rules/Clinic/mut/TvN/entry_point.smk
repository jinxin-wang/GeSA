import pandas as pd

configfile: "workflow/rules/Clinic/mut/TvN/config/config.yaml"

df = pd.read_csv("config/variant_call_list_TvN.tsv", sep="\t", header=None)

tsamples = df[0].tolist()
nsamples = df[1].tolist()

include: "annotate.smk"

rule target:
    input:
        "aggregate/somatic_maf/somatic_calls_union_ann_prefinal.maf.gz",
        "aggregate/somatic_maf/somatic_calls.maf.gz",

