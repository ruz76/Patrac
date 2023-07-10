
docker run --name patrac-postgis -v /data:/data -e POSTGRES_PASSWORD=mysecretpassword -d ruz76-patrac-store
docker run --name patrac-postgis -v /media/jencek/Elements1/gisak:/data -e POSTGRES_PASSWORD=mysecretpassword -d ruz76-patrac-store
docker exec -ti patrac-postgis psql -U postgres
docker exec -ti patrac-postgis /bin/bash

#docker exec -e uid=$(id -u) -e gid=$(id -g) -ti patrac-postgis /bin/bash
#docker run --name patrac-postgis -e uid=$(id -u) -e gid=$(id -g) -v /media/jencek/Elements1/gisak:/data -e POSTGRES_PASSWORD=mysecretpassword -d ruz76-patrac-stor

# clean volumes
docker volume prune
