include: ""
include: "annotate_variants.smk"

metaprism_config = {
    "ref": {
        "species": "homo_sapiens",
    },
    "params": {
        "gatk": {
            "BaseRecalibrator": {
                "known_sites": "/mnt/beegfs/database/bioinfo/metaprism/wes/resources/b37_gatk/af-only-gnomad.raw.sites.b37.vcf.gz",
            },
        },
        "civic": {
            "run_per_sample": {
                "maf": True,  
                "cna": True
            },     
            "rules_clean": "/mnt/beegfs/software/metaprism/wes/external/CivicAnnotator/data/CIViC_Curation_And_Rules_Mutation.xlsx",
            "evidences": "/mnt/beegfs/software/metaprism/wes/external/CivicAnnotator/data/01-Jan-2022-ClinicalEvidenceSummaries_Annotated.xlsx",
            "gene_list": "/mnt/beegfs/software/metaprism/wes/external/CivicAnnotator/data/01-Jan-2022-GeneSummaries.tsv",
            "code_dir": "/mnt/beegfs/software/metaprism/wes/external/CivicAnnotator",
        },
        "vcf2maf": {
            "path": "/mnt/beegfs/software/metaprism/wes/external/vcf2maf",
        },
        "vep": {
            "fasta": "homo_sapiens/104_GRCh37/Homo_sapiens.GRCh37.75.dna.primary_assembly.fa",
            "path": "/mnt/beegfs/software/metaprism/wes/external/vep",
            "cache": "/mnt/beegfs/software/metaprism/wes/external/vep/cache",
            "plugins_data": {
                "CADD": [
                    "/mnt/beegfs/software/metaprism/wes/external/vep/cache/Plugins/whole_genome_SNVs_1.6_grch37.tsv.gz",
                    "/mnt/beegfs/software/metaprism/wes/external/vep/cache/Plugins/InDels_1.6_grch37.tsv.gz",
                ],
                "dbNSFP": [
                    "/mnt/beegfs/software/metaprism/wes/external/vep/cache/Plugins/dbNSFP4.1a_grch37.gz",
                ],
            },
            "dbnsfp": [
                "SIFT_score",
                "SIFT_pred",
                "Polyphen2_HVAR_score",
                "Polyphen2_HVAR_pred",
                "CADD_raw_hg19",
                "DEOGEN2_score",
                "REVEL_score",
                "VEST4_score",
                "FATHMM_score",
                "fathmm-MKL_coding_score",
                "MutationAssessor_score",
                "MutationAssessor_pred",
                "MutationTaster_score",
                "MutationTaster_pred",
                "PROVEAN_score",
                "GERP++_RS"
                "clinvar_id",
                "clinvar_clnsig",
                "Ensembl_proteinid",
                "Ensembl_transcriptid",
            ]
        },
    },
    "tumor_normal_pairs": "config/tumor_normal_pairs.tsv",
}

rule target:
    input:
        "MAF/annotation/civic_db/ST4080_T_Vs_ST4080_N_pos.tsv"