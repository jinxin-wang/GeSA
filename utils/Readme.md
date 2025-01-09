#### Please add the following line into your .bashrc :
```
PATH=$PATH:$HOME/bin
```

#### Then execute the following commands, then you are able to call the pipeline assistant in anywhere : 
```
mkdir -p ~/bin ;
ln -s /mnt/beegfs/userdata/j_wang/pipelines/dna_routine_pipeline/utils/pipeline_assistant.sh ~/bin/routine_pipeline_assistant ;
```

#### Adapters for the project STING UNLOCK

```
$ pwd
/mnt/beegfs/userdata/j_wang/pipelines/dna_routine_pipeline/utils/sting_unlock
$ ls 
01_run_config.sh  sting_unlock_aggr_results.sh  sting_unlock_common.sh  sting_unlock_rna_analysis.sh
```
01_run_config.sh is a script to start a short pipeline in order to generate all the necessary configuration files. 

sting_unlock_aggr_results.sh aggregates all the results of DNA and RNA analysis. 
