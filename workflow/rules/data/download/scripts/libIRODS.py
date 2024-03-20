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
        download_cmd = f"iget -rvK {irods_abs_path} {save_to_dir}"
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

