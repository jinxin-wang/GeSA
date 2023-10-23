import pandas as pd

configfile: "workflow/rules/Clinic/cna/config/config.yaml"

df = pd.read_csv("config/variant_call_list_TvN.tsv", sep="\t", header=None)

tsamples = df[0].tolist()
nsamples = df[1].tolist()

include: "annotate.smk"

rule target:
    input:
        "aggregate/somatic_cna/somatic_calls_union_ann.tsv.gz" ,
