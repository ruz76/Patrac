FROM postgis/postgis:latest

RUN apt-get update && apt-get -y install gnupg software-properties-common wget && \
wget -qO - https://qgis.org/downloads/qgis-2021.gpg.key | gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/qgis-archive.gpg --import && \
chmod a+r /etc/apt/trusted.gpg.d/qgis-archive.gpg && \
add-apt-repository -y "deb https://qgis.org/ubuntu $(lsb_release -c -s) main" && \
apt-get -y install vim gdal-bin zip qgis qgis-plugin-grass openjdk-11-jre procps

