# docker-postgis
This image need the source files for the Oracle Instant Client in this directory!

You may find the download Web Site for Linux x86-64 here:
http://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html
But consider that the location may change over the time,
you have to register yourself for a login and
must Accept the Licence Agreement before you can download the files.

The image pkorduan/postgis require the following files.
oracle-instantclient12.1-basic-12.1.0.2.0-1.x86_64.rpm
oracle-instantclient12.1-sqlplus-12.1.0.2.0-1.x86_64.rpm
oracle-instantclient12.1-jdbc-12.1.0.2.0-1.x86_64.rpm
oracle-instantclient12.1-devel-12.1.0.2.0-1.x86_64.rpm

Ensure that the oracle major version here 12.1 and the oracle version here 12.1.0.2.0-1
match the values of ENV variables ORACLE_MAJOR and ORACLE_VERSION
defined in the Dockerfile for the building process.
