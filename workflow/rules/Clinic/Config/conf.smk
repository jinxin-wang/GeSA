def write_tsv(data, path, header):
    import pandas as pd
    df = pd.DataFrame(data)
    df.to_csv(path, sep='\t', header = header, index = False)

rule match_civic_disease:
    input:
        patient_table = annotation_config["general"]["patients"],
    output:
        pairs_table   = annotation_config["general"]["tumor_normal_pairs"],
    log:
        "logs/conf/match_civic_disease.log",
    params:
        corr_table = annotation_config["params"]["civic"]["corr_table"],
    threads: 1
    resources:
        queue = "shortq",
        mem_mb= 4000,
    run:
        import re
        import pandas as pd

        def match_gender(row):
            if str(row["Sex"]).strip()[0] == "F":
                return "Female"

            elif str(row["Sex"]).strip()[0] == "M":
                return "Male"

            return None
            
        def match_civic(row): 

            def civic_string_to_set(civic_str):
                civic_str = str(civic_str)
                return set(civic_str.split('|'))

            civic_set  = set()

            try : 
                if pd.isnull(row["Project_TCGA_More"]) and pd.isnull(row["MSKCC_Oncotree"]):
                    # DO NOTHING
                    pass

                elif pd.notnull(row["Project_TCGA_More"]) and pd.notnull(row["MSKCC_Oncotree"]):
                    for civic in corresp.loc[row["Project_TCGA_More"], row["MSKCC_Oncotree"]]["Civic_Disease"]:
                        if pd.notnull(civic):
                            civic_set.update(civic_string_to_set(civic))

                elif pd.notnull(row["Project_TCGA_More"]):
                    for civic in corresp.loc[row["Project_TCGA_More"], :]["Civic_Disease"]:
                        if pd.notnull(civic):
                            civic_set.update(civic_string_to_set(civic))

                else:
                    for civic in corresp.loc[:, row["MSKCC_Oncotree"]]["Civic_Disease"]:
                        if pd.notnull(civic):
                            civic_set.update(civic_string_to_set(civic))

            except KeyError as err: 
        
                # print("[Debug] patient id: %s, error: %s"%(patient_id, err))
                
                if pd.notnull(row["Project_TCGA_More"]) :
                    tcga     = re.split('-|_| ', str(row["Project_TCGA_More"]))[0]
                    
                if pd.notnull(row["MSKCC_Oncotree"]) :
                    oncotree = re.split('-|_| ', str(row["MSKCC_Oncotree"]))[0]

                if pd.isnull(row["Project_TCGA_More"]) :
                    # print("[info] set oncotree to tcga: " + oncotree)
                    tcga     = oncotree

                if pd.isnull(row["MSKCC_Oncotree"]) :
                    # print("[info] set tcga to oncotree: " + tcga)
                    oncotree = tcga

                for civic in corresp.query('Project_TCGA_More.str.contains("%s") and MSKCC_Oncotree.str.contains("%s")'%(tcga,oncotree),engine='python')["Civic_Disease"]:
                    if pd.notnull(civic):
                        civic_set.update(civic_string_to_set(civic))

            return "|".join(civic_set)
        
        # corresp = pd.read_excel(params.corr_table, header = 0)
        corresp = pd.read_csv(params.corr_table, sep='\t', header=0).set_index(['Project_TCGA_More', 'MSKCC_Oncotree'])
        
        # the column names for the patient_table is : 
        # PATIENT_ID, Project_TCGA_More, MSKCC_Oncotree, Sex
        patient = pd.read_csv(input.patient_table, sep='\t', header = 0)
        patient = patient.reset_index()
        
        # the column names for the pairs_table is : 
        # Subject_Id, Sample_Id, DNA_T, DNA_N, DNA_P, Project_TCGA_More, MSKCC_Oncotree, Civic_Disease, Gender
        pairs   = []
        
        subject_ids = abs(patient["PATIENT_ID"].map(hash))

        for index, row in patient.iterrows():

            subject_id = str(subject_ids[index])
            patient_id = str(row["PATIENT_ID"])
            dna_t      = "%s_T"%patient_id
            dna_n      = "%s_N"%patient_id
            dna_p      = "%s_T_vs_%s_N"%(patient_id,patient_id)
            civic_codes= match_civic(row)
            tcga       = str(row["Project_TCGA_More"])
            oncokb     = str(row["MSKCC_Oncotree"])
            gender     = match_gender(row)

            pairs.append([subject_id, patient_id, dna_t, dna_n, dna_p, tcga, oncokb, civic_codes, gender])
        
        write_tsv(data = pairs, path = output.pairs_table, 
                header = ["Subject_Id", "Sample_Id", "DNA_T", "DNA_N", "DNA_P", "Project_TCGA_More", "MSKCC_Oncotree", "Civic_Disease", "Gender"])


rule extract_samples_table:
    input:
        pairs_table  = annotation_config["general"]["tumor_normal_pairs"]
    output:
        sample_table = annotation_config["general"]["samples"]
    log:
        "logs/conf/extract_samples_table.log"
    threads: 1
    resources:
        queue = "shortq",
        mem_mb= 4000,
    run:
        import pandas as pd

        pairs_df = pd.read_csv(input.pairs_table, sep='\t').reset_index()
        samples  = []
        
        for index, row in pairs_df.iterrows():
            samples.append([row["DNA_N"], "DNA_N", "OK", row["Project_TCGA_More"], row["MSKCC_Oncotree"], row["Civic_Disease"], row["Gender"]])
            samples.append([row["DNA_T"], "DNA_T", "OK", row["Project_TCGA_More"], row["MSKCC_Oncotree"], row["Civic_Disease"], row["Gender"]])
    
        write_tsv(data = samples, path = output.sample_table, 
            header = ["Sample_Id","Sample_Type","IRODS_Status","Project_TCGA_More","MSKCC_Oncotree","Civic_Disease","Gender"]) 
