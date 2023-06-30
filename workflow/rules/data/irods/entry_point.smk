configfile: "config/config.yaml"

include: "irods.smk"
include: "download.smk"

rule target:
    input:
        config["general"]["MetaTable"],
        config["general"]["DownloadScript"],
        "conf/download_success"
