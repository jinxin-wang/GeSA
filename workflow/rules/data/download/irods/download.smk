from datetime import datetime

COLUMN_DATASETS = "datasets" 
SEP_DATASETS    = "|"        

def query_datasets(index, conditions):
    meta_qu_cmd = f"imeta qu -C {conditions} | grep collection "
    logging.info(f"Query meta informations of sample No.{index} : {meta_qu_cmd}")
    collections = os.popen(meta_qu_cmd).read()
    logging.info(f"Recieve: {collections}")
    return collections

def query_by_key(df, df_key, ds_key, pname):
    for idx, row in df.iterrows():
        bilan_key   = row[df_key]
        conditions  = f" projectName like {pname} and {ds_key} like {bilan_key} "
        collections = query_datasets(index = idx, conditions = conditions)
        datasets    = set([ c.split(":")[-1].strip() for c in collections.split("\n") if len(c.strip()) > 0 ])
        df.at[idx, COLUMN_DATASETS] = df.at[idx, COLUMN_DATASETS] | datasets
    return df

def query_by_keys(df, df_key, ds_key, df_gp_keys, ds_gp_keys, pname):
    for idx, row in df.iterrows():
        bilan_gp_keys= row[df_gp_keys]
        conditions   = " ".join([ f" and {dk} like {bk} " for dk, bk in zip(ds_gp_keys, bilan_gp_keys) ])
        conditions   = f" projectName like {pname} " + conditions
        collections  = query_datasets(index = idx, conditions = conditions)
        datasets     = set([ c.split(":")[-1].strip() for c in collections.split("\n") if len(c.strip()) > 0 ])
        df.at[idx, COLUMN_DATASETS] = df.at[idx, COLUMN_DATASETS] | datasets
    return df

def download_to_dir(irods_abs_path, save_to_dir):
    logging.info(f"download to directory: {save_to_dir}")
    os.system(f"mkdir -p {save_to_dir}")
    dataset_id = irods_abs_path.split("/")[-1]
    target_path= Path(save_to_dir).joinpath(dataset_id)
    if not target_path.is_dir() or not any(target_path.iterdir()):
        download_cmd = f"iget -rvK '{irods_abs_path}' '{save_to_dir}'"
        logging.info(f"Download command: {download_cmd}")
        os.system(download_cmd)
    else:
        logging.info(f"{irods_abs_path} had already been downloaded to {save_to_dir}.")

def download_datasets(datasets, save_to_dir):
    if len(datasets) > 0 :
        for irods_abs_path in datasets :
            download_to_dir(irods_abs_path, save_to_dir)

def download_by_key(df, df_key, ds_key, pname, spath):
    for idx, row in df.iterrows():
        bilan_key   = row[df_key]
        conditions  = f" projectName like {pname} and {ds_key} like {bilan_key} "
        collections = query_datasets(index = idx, conditions = conditions)
        datasets    = [ c.split(":")[-1].strip() for c in collections.split("\n") if len(c.strip()) > 0 ]
        save_to_dir = Path(f"{str(spath)}/{bilan_key}")
        download_datasets(datasets  = datasets, save_to_dir = save_to_dir)

def download_by_keys(df, df_key, ds_key, df_gp_keys, ds_gp_keys, pname, spath):
    for idx, row in df.iterrows():
        bilan_gp_keys= row[df_gp_keys]
        conditions   = " ".join([ f" and {dk} like {bk} " for dk, bk in zip(ds_gp_keys, bilan_gp_keys) ])
        conditions   = f" projectName like {pname} " + conditions
        collections  = query_datasets(index = idx, conditions = conditions)
        datasets     = [ c.split(":")[-1].strip() for c in collections.split("\n") if len(c.strip()) > 0 ]
        save_to_dir  = Path(f"{str(spath)}/{row[df_key]}")
        download_datasets(datasets = datasets, save_to_dir = save_to_dir)


if os.path.isfile(config["iRODS_datasets_metadata"]):
    rule irods_metadata_download:
        input:
            meta = config["iRODS_datasets_metadata"],
        output:
            storage_path = directory(config["STORAGE_PATH"]),
        params:
            metadata_sid = config["iRODS_METADATA_SAMPLE_ID"],
            metadata_path= config["iRODS_METADATA_PATH"],
        threads: 1
        resources:
            queue  = "shortq",
            mem_mb = 10240,
            disk_mb  = dataset_size * 1024,
            time_min = dataset_size,
        log:
            out = "logs/data/download/irods/irods_metadata_download.log"
        benchmark:
            "logs/benchmark/data/download/irods/irods_metadata_download.tsv"
        run:
            logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.INFO)

            if sys.version_info.major < 3:
                logging.warning("require python3, current python version: %d.%d.%d"%(sys.version_info[0], sys.version_info[1], sys.version_info[2]))

            exten = str(input.meta).strip().split(".")[-1]
            meta_df = None
            
            dtypes = {COLUMN_DATASETS: str}

            if exten == "tsv" : 
                logging.info(f"identify the format of input file is tsv: {input.meta}")
                meta_df = pd.read_table(input.meta, sep="\t", dtype=dtypes, keep_default_na=False)
            elif exten == "csv" : 
                logging.info(f"identify the format of input file is csv: {input.meta}")
                meta_df = pd.read_table(input.meta, sep=";",  dtype=dtypes, keep_default_na=False)
            else:
                logging.warning(f"Unable to identify the format of input file: {input.meta}")
                raise Exception(f"Unable to identify the format of input file: {input.meta}")

            for idx, row in meta_df.iterrows():
                logging.info(f"sample id: {row[str(params.metadata_sid)]}")
                save_to_dir = Path(output.storage_path).joinpath(row[str(params.metadata_sid)])
                logging.info(f"saving to dir {save_to_dir}")
                download_to_dir(row[params.metadata_path], save_to_dir)


elif os.path.isfile(config["iRODS_sample_bilan"]):
    rule irods_query_datasets:
        input:
            bilan = config["iRODS_sample_bilan"],
        output:
            bilan = "config/datasets_query_bilan.tsv",
        params:
            project_names  = config["PROJECT_NAMES"],
            bilan_query_key  = config["iRODS_BILAN_QUERY_KEY"],
            dataset_query_key= config["iRODS_DATASET_QUERY_KEY"],
            bilan_cquery_keys   = config["iRODS_bilan_cquery_keys"],
            dataset_cquery_keys = config["iRODS_dataset_cquery_keys"],
        threads: 1
        resources:
            queue  = "shortq",
            mem_mb = 10240,
        log:
            out = "logs/data/download/irods/irods_query_datasets.log"
        benchmark:
            "logs/benchmark/data/download/irods/irods_query_datasets.tsv"
        run:
            logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.INFO)

            if sys.version_info.major < 3:
                logging.warning("require python3, current python version: %d.%d.%d"%(sys.version_info[0], sys.version_info[1], sys.version_info[2]))

            bilan = str(input.bilan)
            exten = bilan.strip().split(".")[-1]
            bilan_df  = None

            if exten == "tsv" :
                logging.info(f"identify the format of input file is tsv: {input.bilan}")
                bilan_df = pd.read_table(bilan, sep="\t")
                
            elif exten == "csv" : 
                logging.info(f"identify the format of input file is csv: {input.bilan}")
                bilan_df = pd.read_table(bilan, sep=";")
                
            else:
                logging.warning(f"Unable to identify the format of input file: {input.bilan}")
                raise Exception(f"Unable to identify the format of input file: {input.bilan}")

            bilan_df[COLUMN_DATASETS] = [ set([]) for i in range(len(bilan_df.index)) ]

            for project_name in params.project_names:
                if len(project_name.strip()) > 0 :
                    bilan_df = query_by_key(df = bilan_df, pname  = project_name,
                                            df_key = params.bilan_query_key,
                                            ds_key = params.dataset_query_key)


                if len(project_name.strip()) > 0 and len(params.bilan_cquery_keys) > 0 and len(params.dataset_cquery_keys) > 0 :
                    bilan_df = query_by_keys(df = bilan_df, pname  = project_name,
                                                      df_key = params.bilan_query_key,
                                                      ds_key = params.dataset_query_key,
                                                      df_gp_keys = params.bilan_cquery_keys,
                                                      ds_gp_keys = params.dataset_cquery_keys)

            bilan_df[COLUMN_DATASETS] = bilan_df[COLUMN_DATASETS].map(lambda x: SEP_DATASETS.join(x))
            bilan_df.to_csv(output.bilan, sep="\t", index=False)

    rule irods_download_datasets:
        input:
            bilan = "config/datasets_query_bilan.tsv",
        output:
            storage_path = directory(config["STORAGE_PATH"]),
        params:
            bilan_query_key = config["iRODS_BILAN_QUERY_KEY"],
        threads: 1
        resources:
            queue  = "shortq",
            mem_mb = 10240,
            disk_mb  = dataset_size * 1024,
            time_min = dataset_size,
        log:
            out = "logs/data/download/irods/irods_download_datasets.log"
        benchmark:
            "logs/benchmark/data/download/irods/irods_download_datasets.tsv"
        run:
            logging.basicConfig(filename=log.out, encoding='utf-8', level=logging.INFO)
            
            if sys.version_info.major < 3:
                logging.warning("require python3, current python version: %d.%d.%d"%(sys.version_info[0], sys.version_info[1], sys.version_info[2]))

            bilan = str(input.bilan)
            exten = bilan.strip().split(".")[-1]
            bilan_df  = None

            dtypes = {COLUMN_DATASETS: str}

            if exten == "tsv" : 
                logging.info(f"identify the format of input file is tsv: {input.bilan}")
                bilan_df = pd.read_table(bilan, sep="\t", dtype=dtypes, keep_default_na=False)
            elif exten == "csv" : 
                logging.info(f"identify the format of input file is csv: {input.bilan}")
                bilan_df = pd.read_table(bilan, sep=",",  dtype=dtypes, keep_default_na=False)
            else:
                logging.warning(f"Unable to identify the format of input file: {input.bilan}")
                raise Exception(f"Unable to identify the format of input file: {input.bilan}")

            bilan_df[COLUMN_DATASETS] = bilan_df[COLUMN_DATASETS].map(lambda x: x.strip().split(SEP_DATASETS) if len(x) > 0 else [])
            logging.debug(f"{bilan_df[COLUMN_DATASETS]}")

            for idx, row in bilan_df.iterrows():
                save_to_dir = Path(f"{str(output.storage_path)}/{row[params.bilan_query_key]}")
                download_datasets(datasets = row[COLUMN_DATASETS], save_to_dir = save_to_dir)


