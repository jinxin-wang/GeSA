rule gen_irods_sample_sheet:
    input:
        meta = config["general"]["MetaTable"],
        succ = config["irods"]["DownloadSucess"],
    output:
        sample_sheet = config["general"]["SampleSheet"],
    log:
        "logs/download/gen_irods_sample_sheet.log",
    params:
        storage_path = config["general"]["StoragePath"],
        sample_attrs = config["irods"]["SampleSheetAttrs"],
        gb_attrs     = config["irods"]["GroupByAttrs"],
        queue        = "shortq",
    threads: 1
    resources:
        mem_mb = 1024
    run:
        import pandas as pd
        from pathlib import Path

        ## replace " ", "-" by "_"
        def sf(s):
            return s.replace(' ', '_').replace('-', '_')

        def build_path(data_path: str, patientId: str, protocol: str):
            file_name = data_path.split('dataset/')[-1]
            file_path = Path(params.storage_path).joinpath(patientId).joinpath(protocol).joinpath(file_name)
            return file_path

        sample_sheet_table = []

        meta_df = pd.read_csv(str(input.meta), sep='\t', header=0)
        
        for ind, row in meta_df.iterrows():
            patientId = sf(row[params.gb_attrs[0]].split('|')[0])
            protocol  = sf(row[params.gb_attrs[1]])
            r1 = build_path(row['R1'], patientId, protocol)
            r2 = build_path(row['R2'], patientId, protocol)
            sample_sheet_table.append(list(row[params.sample_attrs]) + [r1, r2])

        ## save
        table = pd.DataFrame(sample_sheet_table, columns = list(params.sample_attrs) + ["R1", "R2"])
        table.to_csv(str(output.sample_sheet), sep="\t", index=False)

        
