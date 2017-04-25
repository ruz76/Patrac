package cz.vsb.gis.ruz76.patrac;

import org.geotools.data.DefaultTransaction;
import org.geotools.data.Transaction;
import org.geotools.data.collection.ListFeatureCollection;
import org.geotools.data.shapefile.ShapefileDataStore;
import org.geotools.data.shapefile.ShapefileDataStoreFactory;
import org.geotools.data.simple.SimpleFeatureSource;
import org.geotools.data.simple.SimpleFeatureStore;
import org.opengis.feature.simple.SimpleFeatureType;

import java.io.File;
import java.io.IOException;
import java.io.Serializable;
import java.net.MalformedURLException;
import java.util.HashMap;

/**
 * Created by jencek on 24.4.17.
 */
public class Utils {
    public static void saveFeatureCollectionToShapefile(String path, ListFeatureCollection features, SimpleFeatureType TYPE) throws MalformedURLException, IOException {
        File newFile = new File(path);

        java.util.Map<String, Serializable> params = new HashMap<String, Serializable>();
        params.put("url", newFile.toURI().toURL());

        ShapefileDataStoreFactory dataStoreFactory = new ShapefileDataStoreFactory();

        ShapefileDataStore newDataStore = (ShapefileDataStore) dataStoreFactory.createNewDataStore(params);

        newDataStore.createSchema(TYPE);
        newDataStore.forceSchemaCRS(TYPE.getGeometryDescriptor().getCoordinateReferenceSystem());

        Transaction transaction = new DefaultTransaction("create");

        String typeName = newDataStore.getTypeNames()[0];
        SimpleFeatureSource featureSource = newDataStore.getFeatureSource(typeName);
        SimpleFeatureStore featureStore = (SimpleFeatureStore) featureSource;
        featureStore.setTransaction(transaction);
        featureStore.addFeatures(features);
        transaction.commit();
        transaction.close();
    }
}
