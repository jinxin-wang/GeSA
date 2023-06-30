configfile: "config/config.yaml"

include: "irods.smk"

rule target:
    input:
        config["general"]["MetaTable"]
