package cz.vsb.gis.ruz76.patrac;

import com.vividsolutions.jts.geom.Coordinate;
import com.vividsolutions.jts.geom.GeometryFactory;
import com.vividsolutions.jts.geom.Polygon;

import com.vividsolutions.jts.geom.util.AffineTransformation;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;

/**
 * Created by jencek on 27.2.17.
 */
public class Radial {
    /* Function should divide circle to equal 360 sectors, each for one degree of circular sector.
     * There is one logical error in the code.
     * Try to run the code and open result sectors.csv in QGIS with EPSG:4326.
     * Correct the error.
     */
    static void printSectors() {
        /*
        final double RADIUS = 15000;
        final double CENTER_X = 599490;
        final double CENTER_Y = 4920855;
        */

        final double RADIUS = 10;
        final double CENTER_X = 0;
        final double CENTER_Y = 0;

        double tan_alpha = Math.tan(Math.toRadians(1));
        /* Radius of the circle in map units */
        double dy = RADIUS;
        double dx = tan_alpha * dy;

        Coordinate[] coords = new Coordinate[4];
        coords[0] = new Coordinate(0, 0);
        coords[1] = new Coordinate(0, dy);
        coords[2] = new Coordinate(dx, dy);
        coords[3] = new Coordinate(0, 0);
        GeometryFactory geometryFactory = new GeometryFactory();
        Polygon polygonFromCoordinates = geometryFactory.createPolygon(coords);
        System.out.println("Template sector: " + polygonFromCoordinates);

        try (BufferedWriter bw = new BufferedWriter(new FileWriter("sectors.csv"))) {

            for (int i = 0; i < 360; i++) {
                AffineTransformation at = new AffineTransformation();
                at.rotate(Math.toRadians(i));
                at.translate(CENTER_X, CENTER_Y);
                polygonFromCoordinates = (Polygon) at.transform(polygonFromCoordinates);
                bw.write(polygonFromCoordinates + ";" + i + "\n");
            }

            bw.close();

        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}