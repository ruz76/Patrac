FROM postgis/postgis:latest

RUN apt-get update && apt-get -y install gnupg software-properties-common wget && \
printf "Types: deb deb-src\nURIs: https://qgis.org/debian\nSuites: bullseye\nArchitectures: amd64\nComponents: main\nSigned-By: /etc/apt/keyrings/qgis-archive-keyring.gpg\n" > /etc/apt/sources.list.d/qgis.sources && \
mkdir -m755 -p /etc/apt/keyrings && wget -O /etc/apt/keyrings/qgis-archive-keyring.gpg https://download.qgis.org/downloads/qgis-archive-keyring.gpg && \
apt-get update && \
apt-get -y install vim gdal-bin zip qgis qgis-plugin-grass openjdk-11-jre procps

RUN addgroup --gid 1000 patrac
RUN adduser --home /home/patrac --uid 1000 --gid 1000 patrac
RUN adduser patrac sudo
