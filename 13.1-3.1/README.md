# pkoduan/postgis

This image based on postgres:13.1

We install additional locale de_DE set spezific Environment variables and bash settings and installed the following packages
  alien
  apt-utils
  build-essential
  libaio1
  libaio-dev
  locales
  locales-all
  ntp
  postgresql-13-postgis-3
  postgresql-13-pgrouting
  postgresql-13-mysql-fdw
  postgis
  vim
  wget

## Usage

In order to run a basic container capable of serving a PostGIS-enabled database,
start a container as follows:

    docker run --name some-postgis -e POSTGRES_PASSWORD=mysecretpassword -d pkorduan/postgis:13.1-3.1

For more detailed instructions about how to start and control your Postgres
container, see the documentation for the `postgres` image
[here](https://registry.hub.docker.com/_/postgres/).

Once you have started a database container, you can then connect to the
database as follows:

    docker run -it --link some-postgis:postgres --rm postgres \
        sh -c 'exec psql -h "$POSTGRES_PORT_5432_TCP_ADDR" -p "$POSTGRES_PORT_5432_TCP_PORT" -U postgres'

See [the PostGIS documentation](http://postgis.net/docs/postgis_installation.html#create_new_db_extensions)
for more details on your options for creating and using a spatially-enabled database.