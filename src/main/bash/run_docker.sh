docker run --name patrac-postgis -v /media/jencek/Elements/gisak:/data -e POSTGRES_PASSWORD=mysecretpassword -d ruz76-patrac-store
docker exec -ti patrac-postgis psql -U postgres
docker exec -ti patrac-postgis /bin/bash
