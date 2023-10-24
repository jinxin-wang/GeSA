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
        logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.INFO)

        if sys.version_info.major < 3:
            logging.warning("require python3, current python version: %d.%d.%d"%(sys.version_info[0], sys.version_info[1], sys.version_info[2]))

        for dataset in params.datasets_list:
            cmd   = f"mkdir -p {output.storage_path} ; cd {output.storage_path} ; {params.pyega} -c {params.conntions} -cf {input.config} fetch {dataset} "
            logging.info(f"executing EGA command: {cmd}")
            os.system(cmd)
