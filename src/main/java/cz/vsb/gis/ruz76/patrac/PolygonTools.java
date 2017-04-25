package cz.vsb.gis.ruz76.patrac;

import com.vividsolutions.jts.geom.*;
import com.vividsolutions.jts.geom.util.LineStringExtracter;
import com.vividsolutions.jts.operation.polygonize.Polygonizer;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

/**
 * Created by jencek on 24.4.17.
 * Based on https://gis.stackexchange.com/questions/189976/jts-split-arbitrary-polygon-by-a-line
 */
public class PolygonTools {

    public static Geometry polygonize(Geometry geometry) {
        List lines = LineStringExtracter.getLines(geometry);
        Polygonizer polygonizer = new Polygonizer();
        polygonizer.add(lines);
        Collection polys = polygonizer.getPolygons();
        Polygon[] polyArray = GeometryFactory.toPolygonArray(polys);
        return geometry.getFactory().createGeometryCollection(polyArray);
    }

    public static Geometry splitPolygon(Geometry poly, Geometry line) {
        Geometry nodedLinework = poly.getBoundary().union(line);
        Geometry polys = polygonize(nodedLinework);

        // Only keep polygons which are inside the input
        List output = new ArrayList();
        for (int i = 0; i < polys.getNumGeometries(); i++) {
            Polygon candpoly = (Polygon) polys.getGeometryN(i);
            if (poly.contains(candpoly.getInteriorPoint())) {
                output.add(candpoly);
            }
        }
        return poly.getFactory().createGeometryCollection(GeometryFactory.toGeometryArray(output));
    }

    public static Geometry splitPolygon(Geometry poly) {
        int id = Math.round(poly.getCoordinates().length / 2);
        Coordinate coords[] = new Coordinate[2];
        coords[0] = poly.getCoordinates()[0];
        coords[1] = poly.getCoordinates()[id];
        GeometryFactory gf = new GeometryFactory();
        LineString splitLine = gf.createLineString(coords);
        return splitPolygon(poly, splitLine);
    }
}