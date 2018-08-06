package cz.vsb.gis.ruz76.patrac.utils;

import com.vividsolutions.jts.geom.Coordinate;
import com.vividsolutions.jts.geom.GeometryFactory;
import com.vividsolutions.jts.geom.LineString;
import com.vividsolutions.jts.geom.MultiLineString;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import org.geotools.data.DataUtilities;
import org.geotools.data.FileDataStore;
import org.geotools.data.FileDataStoreFinder;
import org.geotools.data.collection.ListFeatureCollection;
import org.geotools.data.simple.SimpleFeatureCollection;
import org.geotools.data.simple.SimpleFeatureIterator;
import org.geotools.data.simple.SimpleFeatureSource;
import org.geotools.feature.simple.SimpleFeatureBuilder;
import org.opengis.feature.simple.SimpleFeature;
import org.opengis.feature.simple.SimpleFeatureType;

/**
 * Class for handling lines.
 */
public class LineTools {

    /**
     * Removes points with coordinates 0,0.
     * @param input input file
     * @param output output file
     * @throws IOException in a case of erro in reading or writing files
     */
    public static void removeZeroPoints(String input, String output) throws IOException {

        List<SimpleFeature> featuresForExport = new ArrayList<>();

        ListFeatureCollection listFeatureCollection = Utils.getListFeatureCollection(input);
        SimpleFeatureIterator simpleFeatureIterator = listFeatureCollection.features();

        while (simpleFeatureIterator.hasNext()) {
            SimpleFeature feature = simpleFeatureIterator.next();
            MultiLineString l = (MultiLineString) feature.getDefaultGeometry();
            Coordinate coords[] = l.getCoordinates();
            ArrayList<Coordinate> newCoords = new ArrayList<Coordinate>();
            for (int i=0; i<coords.length; i++) {
                if (coords[i].x == 0 || coords[i].y == 0) {
                    System.out.println("Zero point, Removing ...");
                } else {
                    newCoords.add(coords[i]);
                }
            }
            GeometryFactory gf = new GeometryFactory();
            Coordinate newCoordsArray[] = newCoords.toArray(new Coordinate[newCoords.size()]);
            LineString newLine = gf.createLineString(newCoordsArray);
            feature.setDefaultGeometry(newLine);
            featuresForExport.add(feature);
        }

        SimpleFeatureType featureType = listFeatureCollection.getSchema();
        ListFeatureCollection featuresForExportList = new ListFeatureCollection(featureType, featuresForExport);
        Utils.saveFeatureCollectionToShapefile(output, featuresForExportList, featureType);
        System.out.println("End remove zero points");
    }
}
