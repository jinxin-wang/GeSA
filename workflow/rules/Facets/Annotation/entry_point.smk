metaprism_config = {
    "params": {
        "cnv": {
            "chr_arm_rules": "/mnt/beegfs/database/bioinfo/metaprism/wes/resources/facets_suite/facets_suite_arm_level_rules.xlsx",
            "cna_cat_rules": "/mnt/beegfs/database/bioinfo/metaprism/wes/resources/facets_suite/facets_scna_categories_rules.xlsx",
            "calls_threshold": 10,
            "bed": "/mnt/beegfs/database/bioinfo/metaprism/wes/resources/gene_set/Homo_sapiens.GRCh37.87.gff3.gene.bed",
        },
        "civic": {
            "run_per_sample": {
                "cna": True,
            },     
            "rules_clean": "/mnt/beegfs/software/metaprism/wes/external/CivicAnnotator/data/CIViC_Curation_And_Rules_Mutation.xlsx",
            "evidences": "/mnt/beegfs/software/metaprism/wes/external/CivicAnnotator/data/01-Jan-2022-ClinicalEvidenceSummaries_Annotated.xlsx",
            "gene_list": "/mnt/beegfs/software/metaprism/wes/external/CivicAnnotator/data/01-Jan-2022-GeneSummaries.tsv",
            "code_dir": "/mnt/beegfs/software/metaprism/wes/external/CivicAnnotator",
        },
        "oncokb": {
            "run_per_sample": {"cna": True},
            "code_dir": "/mnt/beegfs/software/metaprism/wes/external/oncokb-annotator",
            "data_dir": "/mnt/beegfs/software/metaprism/wes/external/oncokb-annotator/data",
            "gene_list": "/mnt/beegfs/software/metaprism/wes/external/oncokb-annotator/data/cancerGeneList_oncokb_annotated.tsv",
            "token": "d19854fb-fa4f-43cb-bffe-02a480df0b7f",
            "rules_clean": "/mnt/beegfs/database/bioinfo/metaprism/wes/resources/oncokb/OncoKB_Curation_And_Rules.xlsx",
        },
    },
    "general": {
        "samples": "samples.tsv"
    }
}


include: "filter_cna.smk"
include: "annotate_cna.smk"