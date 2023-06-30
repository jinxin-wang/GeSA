rule irods_meta_table:
    output:
        meta_table = config["general"]["MetaTable"],
    log:
        "logs/data_collection/irods_meta_table.log",
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

        #### exec a command which return a list of key: value pairs
        #### key is the attribute, the function return list of values
        def get_attr_values(cmd, collection, attribute):
            values = []
            cmd    = cmd%(collection, attribute)
            for line in sp.check_output(cmd, shell=True).splitlines():
                line = line.decode("utf-8").split(":")
                values.append(line[1].strip())
            return values

        #### compare two names of data file,
        #### if there is only one different character which are 1 and 2
        #### then the two files name are a pair
        def is_read_pair(str1: str, str2: str):
            ## set flag if find a different character 
            flag  = False
            str12 = ["1","2"]
            read1 = str1
            read2 = str2
            for c1, c2 in zip(str1, str2):
                if c1 != c2 :
                    ## has more than one different character
                    if flag :
                        return [False, str1, str2]

                    ## one of the different character is "1", the other is "2"
                    elif c1 in str12 and c2 in str12 :
                        flag = True
                        
                        ## if str1 is read 2 
                        if c1 == "2":
                            read1 = str2
                            read2 = str1

                    ## first different character but not "1" or "2"
                    else:
                        return [False, str1, str2]

            ## after compare the entire file names
            return [True, read1, read2]

        def build_meta_table(fname: str, files_set: set, meta_table: list, meta_info: list):
            ## match fname to the names of files
            for f in files_set:
                is_pr = is_read_pair(f,fname)
                # if match then add the pair to table and remove the matched file from files_set
                if is_pr[0]:
                    meta_table.append(is_pr[1:] + meta_info)
                    files_set.remove(f)
                    return

            ## no matched file name, wait in the queue to be matched later
            files_set.add(fname)

        ## meta table
        table = []

        for collection in get_attr_values("imeta qu -C projectName like %s | grep %s ", params.pj_name, "collection"):
            ## if an attribute has more than one value, then join the values with seperator "|"
            metas = ["|".join(get_attr_values("imeta ls -C %s %s | grep value ", collection, attribute)) for attribute in params.attrs ]
            abs_path  = ""
            base_path = ""
            files_set = set()
            for line in sp.check_output("ils -lr %s"%collection, shell=True).splitlines():
                line = line.decode("utf-8").strip()

                if line[0] == '/' and line[-1] == ':':
                    #### a folder may contain data files
                    base_path = line

                elif len(line.split('&')) > 1:
                    #### data file path
                    abs_path = base_path.replace(':','/') + line.split(' ')[-1]
                    #### if find a pair then add to table
                    build_meta_table(abs_path, files_set, table, metas)

            if len(files_set) > 0 :
                raise ValueError("Unmatched Read pairs: %s"%("\n".join(files_set)))

        ## save
        table = pd.DataFrame(table, columns = ["R1", "R2"] + params.attrs)
        table.to_csv(str(output.meta_table), sep="\t", index=False)



