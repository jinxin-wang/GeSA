#!/bin/bash
# properties = {properties}

{exec_job}

#### In order to avoid quit the jobs without writing all the results to filesystem, 
#### it has to force cluster to dump cache to filesystem
sync ;
sync ;
sync ;
