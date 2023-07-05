configfile: "config/config.yaml"

include: "generate_concat_bash.smk"

rule target:
    input:
        config["concat"]["ConcatScript"],
        config["concat"]["ConcatSuccess"],

