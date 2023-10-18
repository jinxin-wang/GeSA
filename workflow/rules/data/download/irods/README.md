## ﻿How to create iRODS env @flamingo:

#### 1. initialise local session

iinit

enter GR account password (same as GR email, flamingo)

If it asks for remote host and irods zone then cancel (ctrl-Z)

Create local configuration file in your home
```
mkdir /home/<user@intra.igr.fr>/.irods
cp /mnt/beegfs/kdi/irods\_environmentProd.json /home/<user@intra.igr.fr>/.irods/irods\_environment.json
```

edit file

```
vi /home/<user@intra.igr.fr>/.irods/irods\_environment.json 
```

replace line: "irods\_user\_name": "G\_JULES-CLEMENT@INTRA.IGR.FR",

by "irods\_user\_name": "<USER@INTRA.IGR.FR>", USERNAME MUST BE UPPER CASE

## Basic interaction with iRODS

https://docs.irods.org/4.2.7/icommands/user/

#### 1.search for dataset
```
imeta qu -C 'patientAlias' like 'MAP228' and protocol like '%Exome%' imeta qu -C 'projectName' like 'MAPPYACTS'
```

#### 2.list metadata on dataset
```
imeta ls -C <irods absolute path> 
```
example: 
```
imeta ls -C /odin/kdi/dataset/317
```

#### 3.search for datafile
```
imeta qu -d 'projectName' like 'MAPPYACTS'
```

TIPs to display absolute path in irods as result of the query

```
imeta qu -d 'projectName' like 'MAPPYACTS'|grep -v "^\-\-\-"| awk '{if($1 =="No") {printf $0"\n"} else {printf "%s"(NR%2==0?RS:"/"),$2} }'
```

#### 4.list metadata on datafile

```
imeta ls -d <irods absolute path>![](Aspose.Words.a6cd79c6-b8bb-4a31-be0f-34e9689ed66e.015.png)
```

#### 5.browse dataset
```
ils -lr /odin/kdi/dataset/<dataset\_id>/
```

#### 6. get data
```
iget -vK <irods absolute path> <local dest> 
```
it checks automatically file md5sum after transfert

iRods works with complete file name and absolute path usage is encouraged 

##### TIPs 1 : use a file a loop over it

ils /odin/kdi/dataset/1348/archive/|grep ZEC-DI-TUMOR\* > toGet

for i in $(cat toGet); do iget -vK /odin/kdi/dataset/1348/archive/$i /mnt/beegfs/scratch/t\_kergrohen/BIOMEDE\_WGS/ ; done;

##### TIPs 2 : stream the remote file

https://docs.irods.org/4.2.7/icommands/user/#iget

If the destLocalFile is '-', the files read from the server will be written to the standard output (stdout). Similar to the UNIX 'cat' command, multiple source files can be specified.

#### 7. put data
```
iput -vK <local dest> <irods absolute path>
```

where <irods absolute path> is /odin/kdi/dataset/<dataset\_id>/{archive,work} collection that has been created it creates and checks automatically file md5sum before and after transfert

#### 8.explore remote file system:
```
iquest "%s/%s" "SELECT COLL\_NAME,DATA\_NAME WHERE DATA\_CHECKSUM like '<md5sum>'" 
```

This irods feature does not uses metadata.
