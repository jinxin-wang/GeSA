import os
import re
import sys
import glob
import logging
import pandas  as pd
from   pathlib import Path

def match_gender(row):
    if str(row["Sex"]).strip()[0] == "F":
        return "Female"

    elif str(row["Sex"]).strip()[0] == "M":
        return "Male"
    
    return None
            
def match_civic(row, corresp): 

    civic_set  = set()
            
    def civic_string_to_set(civic_str):
        civic_str = str(civic_str)
        return set(civic_str.split('|'))

    try : 
        if pd.notnull(row["Project_TCGA_More"]) and pd.notnull(row["MSKCC_Oncotree"]):
            tcga = row["Project_TCGA_More"]
            oncotree = row["MSKCC_Oncotree"]
            logging.info(f"TCGA: {tcga} , OncoTree: {oncotree} ")
            for civic in corresp.loc[tcga, oncotree]["Civic_Disease"]:
                if pd.notnull(civic):
                    civic_set.update(civic_string_to_set(civic))
                            
        elif pd.notnull(row["Project_TCGA_More"]):
            tcga = row["Project_TCGA_More"]
            logging.info(f"TCGA: {tcga} ")
            for civic in corresp.loc[tcga, :]["Civic_Disease"]:
                if pd.notnull(civic):
                    civic_set.update(civic_string_to_set(civic))
                
        elif pd.notnull(row["MSKCC_Oncotree"]):
            oncotree = row["MSKCC_Oncotree"]
            logging.info(f"Oncotree: {oncotree} ")
            for civic in corresp.loc[:, oncotree]["Civic_Disease"]:
                if pd.notnull(civic):
                    civic_set.update(civic_string_to_set(civic))
                            
        # elif pd.isnull(row["Project_TCGA_More"]) and pd.isnull(row["MSKCC_Oncotree"]):
        # DO NOTHING
        #     pass

    except KeyError as err: 
        patient_id = str(row["PATIENT_ID"])
        logging.debug(f"patient id: {patient_id}, error: KeyError [{err}]")
                
        if pd.notnull(row["Project_TCGA_More"]) :
            tcga     = re.split('-|_| ', str(row["Project_TCGA_More"]))[0]
            logging.debug(f"TCGA: {tcga} ")
                    
        if pd.notnull(row["MSKCC_Oncotree"]) :
            oncotree = re.split('-|_| ', str(row["MSKCC_Oncotree"]))[0]
            logging.debug(f"OncoTre: {oncotree} ")

        if pd.isnull(row["Project_TCGA_More"]) :
            tcga     = oncotree
            logging.debug(f"set oncotree to tcga: {oncotree} ")

        if pd.isnull(row["MSKCC_Oncotree"]) :
            oncotree = tcga
            logging.debug(f"set tcga to oncotree: {tcga} ")

        query_cmd = f"Project_TCGA_More.str.contains('{tcga}') and MSKCC_Oncotree.str.contains('{oncotree}') "
        logging.info(f"Query cmd: {query_cmd} ")
        for civic in corresp.query(query_cmd, engine='python')["Civic_Disease"]:
            if pd.notnull(civic):
                civic_set.update(civic_string_to_set(civic))

        if len(civic_set) == 0:
            query_cmd = f"Project_TCGA_More == '{tcga}' or MSKCC_Oncotree == '{oncotree}' "
            logging.info(f"Query cmd: {query_cmd} ")
            for civic in corresp.query(query_cmd, engine='python')["Civic_Disease"]:
                if pd.notnull(civic):
                    civic_set.update(civic_string_to_set(civic))
                        
    return "|".join(civic_set)

def match_civic2(patient_id, oncotree, tcga, corresp):

    civic_set  = set()
            
    def civic_string_to_set(civic_str):
        civic_str = str(civic_str)
        return set(civic_str.split('|'))

    try : 
        if pd.notnull(tcga) and pd.notnull(oncotree):
            logging.info(f"TCGA: {tcga} , OncoTree: {oncotree} ")
            for civic in corresp.loc[tcga, oncotree]["Civic_Disease"]:
                if pd.notnull(civic):
                    civic_set.update(civic_string_to_set(civic))
                            
        elif pd.notnull(tcga):
            logging.info(f"TCGA: {tcga} ")
            for civic in corresp.loc[tcga, :]["Civic_Disease"]:
                if pd.notnull(civic):
                    civic_set.update(civic_string_to_set(civic))
                
        elif pd.notnull(oncotree):
            logging.info(f"Oncotree: {oncotree} ")
            for civic in corresp.loc[:, oncotree]["Civic_Disease"]:
                if pd.notnull(civic):
                    civic_set.update(civic_string_to_set(civic))
                            
    except KeyError as err: 
        logging.debug(f"patient id: {patient_id}, error: KeyError [{err}]")
                
        if pd.notnull(tcga) :
            tcga     = re.split('-|_| ', str(tcga))[0]
            logging.debug(f"TCGA: {tcga} ")
                    
        if pd.notnull(oncotree) :
            oncotree = re.split('-|_| ', str(oncotree))[0]
            logging.debug(f"OncoTre: {oncotree} ")

        if pd.isnull(tcga) :
            tcga     = oncotree
            logging.debug(f"set oncotree to tcga: {oncotree} ")

        if pd.isnull(oncotree) :
            oncotree = tcga
            logging.debug(f"set tcga to oncotree: {tcga} ")

        query_cmd = f"Project_TCGA_More.str.contains('{tcga}') and MSKCC_Oncotree.str.contains('{oncotree}') "
        logging.info(f"Query cmd: {query_cmd} ")
        for civic in corresp.query(query_cmd, engine='python')["Civic_Disease"]:
            if pd.notnull(civic):
                civic_set.update(civic_string_to_set(civic))

        if len(civic_set) == 0:
            query_cmd = f"Project_TCGA_More == '{tcga}' or MSKCC_Oncotree == '{oncotree}' "
            logging.info(f"Query cmd: {query_cmd} ")
            for civic in corresp.query(query_cmd, engine='python')["Civic_Disease"]:
                if pd.notnull(civic):
                    civic_set.update(civic_string_to_set(civic))
                        
    return "|".join(civic_set)

