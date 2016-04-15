# docker-postgis
This Docker image extends mdillon/postgis with oracle_fdw extension.

This Docker image extends mdillon/postgis with oracle_fdw extension.

This images extends the mdillon/postgis image with the ability to use the PostgreSQL Extension oracle_fdw. oracle_fdw is a Foreign Data Wrapper that let appear tables of an Oracle database as tables in PostgreSQL. Read more here https://github.com/laurenz/oracle_fdw.
## Build the image
Clone the repository with the Dockerfile from: https://github.com/pkorduan/docker-postgis.git
oracle_fdw need the oracle instant client. To install the client inside the image during the build process it is necessary to have downloaded the resources before into the folder oracle below the Dockerfile you will build. Read the instruction in oracle/README.md which files you need. After downloading the right files into the oracle folder run the build in the directory of the Dockerfile:
``docker build -t pkorduan/postgis:9.4 ./9.4``
# Run the image
``docker run -p 5432:5432 -d pkorduan/postgis:9.4``

# Access to an Oracle Database
You can test the connection to a running Oracle Database within this image by linking a container into the postgis container.
Run the oracle container:
``docker run -p 
  docker run --name $ORACLE_CONTAINER_NAME \
    -h ${SERVER_NAME}_$ORACLE_CONTAINER_NAME-container \
    -v $ORACLE_DATA_DIR:/opt/oracle/data_dir \
    -p 8081:8081 \
    -d $ORACLE_IMAGE``