rule target:
    input:
        best = "alterations/aggregated_alterations.tsv",
        all  = "alterations/aggregated_alterations_all.tsv",

include: "aggregate.smk"
