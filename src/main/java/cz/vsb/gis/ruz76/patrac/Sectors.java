package cz.vsb.gis.ruz76.patrac;

import com.vividsolutions.jts.geom.Geometry;
import com.vividsolutions.jts.geom.GeometryCollection;
import com.vividsolutions.jts.geom.GeometryFactory;
import com.vividsolutions.jts.geom.MultiPolygon;
import org.geotools.data.DataUtilities;
import org.geotools.data.FileDataStore;
import org.geotools.data.FileDataStoreFinder;
import org.geotools.data.collection.ListFeatureCollection;
import org.geotools.data.simple.SimpleFeatureCollection;
import org.geotools.data.simple.SimpleFeatureIterator;
import org.geotools.data.simple.SimpleFeatureSource;
import org.geotools.factory.CommonFactoryFinder;
import org.geotools.feature.simple.SimpleFeatureBuilder;
import org.opengis.feature.simple.SimpleFeature;
import org.opengis.feature.simple.SimpleFeatureType;
import org.opengis.filter.Filter;
import org.opengis.filter.FilterFactory2;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

/**
 * Created by jencek on 24.4.17.
 */
public class Sectors {
    private final String SECTORS_INPUT = "data/osm_landuse_combined_clean.shp";
    private final String BARRIERS = "data/osm_roads_selected.shp";
    private final String SECTORS_GROUPPED = "data/sectors_group.shp";
    private final String SECTORS_SPLITTED = "data/sectors_split.shp";
    private final String BARRIERS_FOR_SPLIT_LINES = "data/osm_lines.shp";

    public void splitSectors(double arealimit) throws Exception {

        List<SimpleFeature> featuresForExport = new ArrayList<>();
        FileDataStore sectors_store = FileDataStoreFinder.getDataStore(new File(SECTORS_GROUPPED));
        SimpleFeatureSource sectors = sectors_store.getFeatureSource();
        SimpleFeatureCollection sectors_fc = DataUtilities.collection(sectors.getFeatures());
        ListFeatureCollection sectors_fc_list = new ListFeatureCollection(sectors_fc);
        SimpleFeatureIterator sectors_sfi = sectors_fc_list.features();

        SimpleFeatureType TYPE = sectors_fc.getSchema(); //Typ geometrie a atributy
        SimpleFeatureBuilder featureBuilder = new SimpleFeatureBuilder(TYPE);; //Nástroj pro tvorbu geoprvků

        while (sectors_sfi.hasNext()) {
            SimpleFeature sector = sectors_sfi.next();
            MultiPolygon p = (MultiPolygon) sector.getDefaultGeometry();
            if (p.getArea() > arealimit) {
                Geometry g = PolygonTools.splitPolygon(p);
                featureBuilder.add(g);
                featureBuilder.add(sector.getAttribute("cat"));
                featureBuilder.add(1);
                SimpleFeature feature = featureBuilder.buildFeature(null);
                featuresForExport.add(feature);
            } else {
               featureBuilder.add(p);
               featureBuilder.add(sector.getAttribute("cat"));
               featureBuilder.add(0);
               SimpleFeature feature = featureBuilder.buildFeature(null);
               featuresForExport.add(feature);
            }
        }

        ListFeatureCollection featuresForExport_list = new ListFeatureCollection(TYPE, featuresForExport);
        Utils.saveFeatureCollectionToShapefile(SECTORS_SPLITTED, featuresForExport_list, TYPE);
        System.out.println("End");
    }

    public void groupSectors(double arealimit, double distance, AreaRange arearange) throws Exception {
        FilterFactory2 ff = CommonFactoryFinder.getFilterFactory2();

        FileDataStore sectors_store = FileDataStoreFinder.getDataStore(new File(SECTORS_INPUT));
        SimpleFeatureSource sectors = sectors_store.getFeatureSource();
        FileDataStore barriers_store = FileDataStoreFinder.getDataStore(new File(BARRIERS));
        SimpleFeatureSource barriers = barriers_store.getFeatureSource();

        SimpleFeatureCollection sectors_fc = DataUtilities.collection(sectors.getFeatures());
        SimpleFeatureCollection barriers_fc = DataUtilities.collection(barriers.getFeatures());

        ListFeatureCollection sectors_fc_list = new ListFeatureCollection(sectors_fc);
        ListFeatureCollection sectors_fc_list2 = new ListFeatureCollection(sectors_fc);

        SimpleFeatureIterator sectors_sfi = sectors_fc_list2.features();
        ArrayList<String> modified_sectors = new ArrayList();

        //List<SimpleFeature> featuresout = new ArrayList<>();

        //Loop to all sectors
        while (sectors_sfi.hasNext()) {
            SimpleFeature sector = sectors_sfi.next();

            MultiPolygon p = (MultiPolygon) sector.getDefaultGeometry();
            //System.out.println(p.getArea());
            //Gets only polygons under limited area

            if (p.getArea() < arealimit && !modified_sectors.contains(sector.getAttribute("cat").toString())) {

                System.out.println("---- " + sector.getAttribute("cat") + " ----");
                Geometry sector_buffer = ((MultiPolygon) sector.getDefaultGeometry()).buffer(distance);

                Filter filter = ff.touches(ff.property("the_geom"), ff.literal(sector.getDefaultGeometry()));
                SimpleFeatureIterator sectors_nei_sfi = sectors_fc_list.subCollection(filter).features();
                //bw.write("S;" + sector.getDefaultGeometry() + "\n");

                Geometry geomout = (Geometry) sector.getDefaultGeometry();
                SimpleFeature sector_to_remove = null;
                //Loops sectors that surrounds processed sector
                while (sectors_nei_sfi.hasNext()) {
                    SimpleFeature sector_nei = sectors_nei_sfi.next();
                    System.out.println(sector_nei.getAttribute("cat"));

                    //Creates intersection between buffer around processed sector and processed surounding sector
                    Geometry sector_nei_buffer = ((MultiPolygon) sector_nei.getDefaultGeometry()).buffer(distance);
                    Geometry buffer_intersection = sector_nei_buffer.intersection(sector_buffer);

                    Filter filterbarriers = ff.intersects(ff.property("the_geom"), ff.literal(buffer_intersection));
                    SimpleFeatureIterator barriers_sfi = barriers_fc.subCollection(filterbarriers).features();
                    //System.out.println("barriers between surrounding sector and sector");
                    //Loops barriers that are in intersections between two sectors
                    boolean isbarrier = false;
                    while (barriers_sfi.hasNext()) {
                        SimpleFeature barrier = barriers_sfi.next();
                        Geometry barrier_intersection = buffer_intersection.intersection((Geometry) barrier.getDefaultGeometry());
                        //If the perimeter of the intersection of sectors is up to 10 times bigger than barrier that is in intersection
                        //then the barrier is probably along the whole intersection
                        //difficult to determine limit, but 10 seems to be good
                        //will do some tests on real data later
                        if ((buffer_intersection.getLength() / barrier_intersection.getLength()) < 10) { //10 is Experimental
                            System.out.println("Probably barrier along shared border between " + sector.getAttribute("cat") + " and " + sector_nei.getAttribute("cat"));
                            isbarrier = true;
                        }
                        System.out.println("barrier id: " + barrier.getAttribute("osm_id") + " Length: " + barrier_intersection.getLength() + " From: " + buffer_intersection.getLength());
                    }
                    if (!isbarrier) {
                        GeometryFactory factory = new GeometryFactory();
                        ArrayList c = new ArrayList();
                        c.add(sector_nei.getDefaultGeometry());
                        c.add(sector.getDefaultGeometry());
                        GeometryCollection gc = (GeometryCollection) factory.buildGeometry(c);
                        Geometry union = gc.union();
                        if (arearange.getFit(union.getArea()) >= arearange.getFit(geomout.getArea())) {
                            geomout = union;
                            sector_to_remove = sector_nei;
                        }
                    }
                }
                if (sector_to_remove != null) {
                    sectors_fc_list.remove(sector);
                    sectors_fc_list.remove(sector_to_remove);
                    modified_sectors.add(sector_to_remove.getAttribute("cat").toString());
                }

                sector.setDefaultGeometry(geomout);
                sectors_fc_list.add(sector);

            }
        }
        Utils.saveFeatureCollectionToShapefile(SECTORS_GROUPPED, sectors_fc_list, sectors_fc_list.getSchema());
        System.out.println("End");
    }
}
