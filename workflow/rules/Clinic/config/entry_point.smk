annotation_config = {
    "general": {
        "patients": "config/patients.tsv",
        "samples" : "config/samples.tsv",
        "tumor_normal_pairs": "config/tumor_normal_pairs.tsv",
    },

    "params": {
        "civic": {
            "corr_table" : "workflow/rules/Clinic/Config/resources/Table_Correspondence_Tumor_Type.tsv",
        },
    },
}

include: "conf.smk"

rule target:
    input:
        annotation_config["general"]["samples"],
        annotation_config["general"]["tumor_normal_pairs"],
