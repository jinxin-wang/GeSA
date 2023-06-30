rule irods_meta_table:
    output:
        meta_table = config["general"]["MetaTable"],
    log:
        "logs/data_collection/irods_meta_table.log"
    params:
        pj_name = config["general"]["ProjectName"],
        attrs   = config["irods"]["attributes"],
        pwd     = config["irods"]["pwd"],
        queue  = "shortq",
    threads : 1
    resources:
        mem_mb = 5120,
    run:
        import pandas as pd
        import subprocess as sp

        #### login iRODs
        sp.run(["iinit", params.pwd])
        
        def get_attr_values(cmd, collection, attribute):
            values = []
            cmd    = cmd%(collection, attribute)
            for line in sp.check_output(cmd, shell=True).splitlines():
                line = line.decode("utf-8").split(":")
                values.append(line[1].strip())
            return values

        table = []

        for collection in get_attr_values("imeta qu -C projectName like %s | grep %s ", params.pj_name, "collection"):
            metas = ["|".join(get_attr_values("imeta ls -C %s %s | grep value ", collection, attribute)) for attribute in params.attrs ]
            abs_path  = ""
            base_path = ""
            for line in sp.check_output("ils -lr %s"%collection, shell=True).splitlines():
                line = line.decode("utf-8").strip()

                if line[0] == '/' and line[-1] == ':':
                    #### a folder may contain data files
                    base_path = line

                elif len(line.split('&')) > 1:
                    #### data file path
                    abs_path = base_path.replace(':','/') + line.split(' ')[-1]
                    table.append([abs_path] + metas)


        table = pd.DataFrame(table, columns = ["datafilePath"] + params.attrs)
        table.to_csv(str(output.meta_table), sep="\t", index=False)



