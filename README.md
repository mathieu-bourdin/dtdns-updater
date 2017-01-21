# dtdns-updater

This shell script to notifies DtDNS service of IP updates.

Very easy to use, in-script™ configuration has two entries:

```
FULL_HOSTNAME='myhost.darktech.org'
DTDNS_PASSWORD='mypassword'
```

Because the password is part of the config, file owner should be the only one
allowed to read/write/execute this script so don't forget to
`chmod 700 ./dtdns-updater.sh`

