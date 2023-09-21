configfile: "config/config.yaml"

include: "aggregate.smk"

rule target:
    input:
        best = "results/alterations/aggregated_alterations.tsv",
        all  = "results/alterations/aggregated_alterations_all.tsv",

