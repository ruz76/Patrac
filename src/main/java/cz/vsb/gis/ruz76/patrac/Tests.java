package cz.vsb.gis.ruz76.patrac;

import com.vividsolutions.jts.geom.Geometry;
import com.vividsolutions.jts.geom.GeometryFactory;
import com.vividsolutions.jts.geom.Polygon;
import org.geotools.data.DataUtilities;
import org.geotools.data.FileDataStore;
import org.geotools.data.FileDataStoreFinder;
import org.geotools.data.collection.ListFeatureCollection;
import org.geotools.data.simple.SimpleFeatureCollection;
import org.geotools.data.simple.SimpleFeatureSource;

import java.io.File;
import java.io.IOException;
import java.util.Collection;

/**
 * Created by jencek on 19.11.17.
 */
public class Tests {
    public static void polygonize(String path) throws IOException {
        String INPUT = path + ".shp";
        FileDataStore sectors_store = FileDataStoreFinder.getDataStore(new File(INPUT));
        SimpleFeatureSource sectors = sectors_store.getFeatureSource();
        SimpleFeatureCollection sectors_fc = DataUtilities.collection(sectors.getFeatures());
        //ListFeatureCollection sectors_fc_list = new ListFeatureCollection(sectors_fc);
        Collection polys = PolygonTools.polygonize(sectors_fc);
        System.out.println(polys.size());
        Polygon[] polyArray = GeometryFactory.toPolygonArray(polys);
        for (int i=0; i<polyArray.length; i++) {
            System.out.println(polyArray[i].toString());
        }
        //geometry.getFactory().createGeometryCollection(polyArray);
        /*while (polys.iterator().hasNext()) {
            Geometry geom = (Geometry) polys.iterator().next();
            System.out.println(geom.toString());
        }*/
    }
}
