rule ega_download_datasets:
    input:
        config = config["EGA_CONFIG_FILE"],
    output:
        storage_path = directory(config["STORAGE_PATH"]),
    params:
        pyega = config["EGA_PYEGA"],
        datasets_list = config["EGA_DATASETS"],
        connections = config["EGA_CONNECTIONS"],
    threads: 20
    resources:
        queue  = "longq",
        mem_mb = 40960,
        disk_mb  = dataset_size * 1024,
        time_min = dataset_size * 20,
    log:
        out = f"logs/data/download/ega/ega_download_datasets.log"
    run:
        for dataset in params.datasets_list:
            cmd   = f"mkdir -p {output.storage_path} ; cd {output.storage_path} ; {params.pyega} -c {params.conntions} -cf {input.config} fetch {dataset} "
            logging.info(f"executing EGA command: {cmd}")
            os.system(cmd)
