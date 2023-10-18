import subprocess

rule bgi_genean_download_datasets:
    output:
        storage_path = directory(config["STORAGE_PATH"]),
    params:
        ferry  = config["BGI_APP"],
        user   = config["BGI_USERNAME"],
        passwd = config["BGI_PASSWORD"],
        dataset= config["BGI_dataset"],
        cpath  = config["BGI_CLOUDPATH"],
    threads: 4
    resources:
        queue  = "longq",
        mem_mb = 10240,
    log:
        out = f"logs/download/genean/bgi_genean_download_datasets.log"
    run:
        if sys.version_info.major < 3:
            logging.warning("require python3, current python version: %d.%d.%d"%(sys.version_info[0], sys.version_info[1], sys.version_info[2]))

        logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.INFO)

        logging.info(f"logging genean: {params.s3cmd} login {params.user}")
        
        login_sp  = subprocess.Popen([str(params.s3cmd), 'login', str(params.user)],
                        stdin = subprocess.PIPE, stdout = subprocess.PIPE, text = True)

        logging.info(f"entering password")
        
        stdout, stderr = login_sp.communicate(input=str(params.passwd))

        logging.info(stdout)
        
        if (len(stderr.strip()) > 0) :
            logging.error(stderr)
            raise Exception("BGI GeneAn login failed.")
        
        mkdir_cmd = f"mkdir -p {output.storage_path} "
        download_cmd = f"{params.s3cmd} download {params.dataset} {params.cpath} {output.storage_path} "
        logging.info(f"executing S3 command: {mkdir_cmd} ; {download_cmd} ")
        os.system(f"{mkdir_cmd} ; {download_cmd} ")
