# Patrac Datastore Builder

## Support
Výstupy vznikly v rámci projektu číslo VI20172020088 „Využití vyspělých technologií a čichových schopností psů pro zvýšení efektivity vyhledávání pohřešovaných osob v terénu“
(dále jen „projekt Pátrač“), který byl řešen v období 2017 až 2021
s finanční podporou Ministerstva vnitra ČR z programu bezpečnostního výzkumu.

## Description
This repository has two parts. 
* Application for building sectors from small polygons written in Java
* Scripts for building GRASS GIS workspace for using in qgis_patrac plugin

## Building sectors
You have to use maven and update pom.xml with current version of GeoTools library

## Building GRASS GIS workspace
You have to install GDAL and GRASS GIS

Then the scripts are started with process.sh script.

The Docker version of the script has been tested on KA region only. 
Wait until the ST region is tested.

The scripts expect exact structure of the data:

* /data/patracdata - root directory
* /data/patracdata/postupy/2022 - root directory with the scripts same as in the repository
* /data/patracdata/kraje - root directory where kraj is stored
* /data/patracdata/adm - dumps of nu3 regions and dmr4g_index
* /data/patracdata/dmr_4g - dmr 4g files in directories - same structure as PCR exported
* /data/patracdata/dump - PostGIS dump in the structure of PCR

