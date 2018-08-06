package cz.vsb.gis.ruz76.patrac.experimental;

import com.vividsolutions.jts.geom.GeometryFactory;
import com.vividsolutions.jts.geom.Polygon;
import cz.vsb.gis.ruz76.patrac.utils.PolygonTools;
import cz.vsb.gis.ruz76.patrac.utils.Utils;
import java.io.IOException;
import java.util.Collection;
import org.geotools.data.collection.ListFeatureCollection;
import org.geotools.data.simple.SimpleFeatureCollection;
import org.geotools.data.simple.SimpleFeatureIterator;
import org.geotools.factory.CommonFactoryFinder;
import org.opengis.feature.simple.SimpleFeature;
import org.opengis.filter.Filter;
import org.opengis.filter.FilterFactory2;

/**
 * Some experimental tests.
 */
public class Experiments {

  /**
   * Prints polygons from line input.
   *
   * @param path line input
   * @throws IOException in a case of error of reading
   */
  public static void polygonize(final String path) throws IOException {
    SimpleFeatureCollection simpleFeatureCollection = Utils.getSimpleFeatureCollection(path);
    Collection polys = PolygonTools.polygonize(simpleFeatureCollection);
    System.out.println(polys.size());
    Polygon[] polyArray = GeometryFactory.toPolygonArray(polys);
    for (int i = 0; i < polyArray.length; i++) {
      System.out.println(polyArray[i].toString());
    }
  }

  /**
   * Prints count of sectors for each area.
   *
   * @param areasPath areas file
   * @param sectorsPath sectors file
   * @throws Exception in a case of error of reading
   */
  public static void loopSelect(final String areasPath, final String sectorsPath) throws IOException {
    FilterFactory2 ff = CommonFactoryFinder.getFilterFactory2();
    ListFeatureCollection areasFcList = Utils.getListFeatureCollection(areasPath);
    ListFeatureCollection sectorsFcList = Utils.getListFeatureCollection(sectorsPath);

    SimpleFeatureIterator areasSimpleFeatureIterator = areasFcList.features();

    while (areasSimpleFeatureIterator.hasNext()) {
      SimpleFeature area = areasSimpleFeatureIterator.next();
      System.out.println("---- " + area.getAttribute("OBJECT_ID") + " ----");
      Filter filter = ff.intersects(ff.property("the_geom"), ff.literal(area.getDefaultGeometry()));
      SimpleFeatureIterator sectorsSimpleFeatureIterator = sectorsFcList.subCollection(filter).features();
      int count = 0;
      while (sectorsSimpleFeatureIterator.hasNext()) {
        SimpleFeature sector = sectorsSimpleFeatureIterator.next();
        count++;
      }
      System.out.println("COUNT: " + count);
    }
  }
}
