#### 03 Login to EGA FTP server

The first way, line by line

```
$ lftp
lftp :~> set ftp:ssl-allow no
lftp :~> lftp ftp.ega.ebi.ac.uk
lftp ftp.ega.ebi.ac.uk:~> user ega-box-898
Password:
55CZEu4j
```

The second way, all in a single line

```
$ lftp
lftp :~> set ftp:ssl-allow no; open -u ega-box-2196,zt6eJy3E ftp.ega.ebi.ac.uk;
```

#### 04 upload a file to EGA FTP server

```
lftp :~> put -c local_file -o remote_file
```

