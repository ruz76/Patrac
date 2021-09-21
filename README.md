# Patrac Datastore Builder

This repository has two parts. 
* Application for building sectors from small polygons written in Java
* Scripts for building GRASS GIS workspace for using in qgis_patrac plugin

## Building sectors
You have to use maven and update pom.xml with current version of GeoTools library

## Building GRASS GIS workspace
You have to install GDAL and GRASS GIS

Then the scripts are started in the order how they  are named:
* 0.sh
* 1.sh
* After 1.sh the manual polygon creation has to be done. This part was not automatized yet.
* 2.sh
* 3.sh
* 4.sh
