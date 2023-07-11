configfile: "config/config.yaml"

include: "irods.smk"
include: "download.smk"
include: "samples_sheet.smk"

rule target:
    input:
        config["general"]["MetaTable"],
        config["general"]["DownloadScript"],
        config["irods"]["DownloadSucess"],
        config["general"]["SampleSheet"],
