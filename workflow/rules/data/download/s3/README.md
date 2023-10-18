## AWS: Amazon Web Services

[s3cmd howto](https://s3tools.org/s3cmd-howto)

[s3cmd example](http://fosshelp.blogspot.com/2013/06/how-to-use-amazon-s3-tool-s3cmd.html)


#### Show the bucket
```
$ s3cmd ls
```

#### fix bug: s3cmd line 308 and 310
change "is" to "=="

#### configuration file example, Region: eu-west-3
```
$ cat FD02_F099P01_T01_MEL_D1.conf
access_key = AKIAUAGYXRUSRYX4SCB2
secret_key = mMrfzkZuIUuAYNxduAHnyJE+h5HwN6aIcTHqOm7G
host_base  = s3-eu-west-3.amazonaws.com
host_bucket = %(bucket)s.s3-eu-west-3.amazonaws.com
```

#### List the contents of the bucket
```
$ s3cmd -c FD02_F099P01_T01_MEL_D1.conf ls s3://f22ftseuht1706/
```

#### Download the entire bucket in current directory
```
$ s3cmd -c FD02_F099P01_T01_MEL_D1.conf get s3://f22ftseuht1706/ --recursive
```
