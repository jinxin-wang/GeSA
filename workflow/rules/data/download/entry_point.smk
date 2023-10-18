import os
import sys
import glob
import logging
import pandas as pd
from   pathlib import Path

# The European Genome-phenome Archive (EGA) 
EGA   = "EGA"

# Integrated Rule-Oriented Data System (iRODS)
IRODS = "iRODS"

# Amazon Simple Storage Service
AMAZON= "S3"

# BGI Genomics, GeneAn
# https://genean-static-master.oss-cn-shenzhen.aliyuncs.com/ff-en.tar.gz
# https://genean-static-master.oss-cn-shenzhen.aliyuncs.com/ff-cn.tar.gz
BGI="GeneAn"

# FTP Server
FTP="ftp"

# backup storage on cluster, such as glustergv0, isilon
STORAGE="backup"

configfile: "workflow/config/download.yaml", 

if   config["DATABASE"] == IRODS:
    include: "irods/download.smk"
elif config["DATABASE"] == AMAZON:
    include: "s3/download.smk"
elif config["DATABASE"] == EGA:
    include: "ega/download.smk"
elif config["DATABASE"] == BGI:
    include: "genean/download.smk"
elif config["DATABASE"] == FTP:
    include: "ftp/download.smk"
# elif config["DATABASE"] == STORAGE:
#     include: "cluster/download.smk"
    
rule download_targets:
    input:
        row_data = config["STORAGE_PATH"]
