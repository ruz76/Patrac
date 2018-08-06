package cz.vsb.gis.ruz76.patrac;

import com.vividsolutions.jts.geom.Geometry;
import com.vividsolutions.jts.geom.GeometryCollection;
import com.vividsolutions.jts.geom.GeometryFactory;
import com.vividsolutions.jts.geom.MultiPolygon;
import com.vividsolutions.jts.geom.Polygon;
import cz.vsb.gis.ruz76.patrac.domain.AreaRange;
import cz.vsb.gis.ruz76.patrac.inputs.SectorsInAreasInput;
import cz.vsb.gis.ruz76.patrac.outputs.SectorsInAreasOutput;
import cz.vsb.gis.ruz76.patrac.utils.PolygonTools;
import cz.vsb.gis.ruz76.patrac.utils.Utils;
import java.nio.file.Path;
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
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

/**
 * Created by jencek on 24.4.17.
 */
public class Sectors {

  public static final String OBJECT_ID = "OBJECTID";
  public static final String TYPE = "TYPE";
  public static final String THE_GEOM = "the_geom";
  private Geometry outputGeometry = null;
  private SimpleFeature sectorToRemove = null;
  private Path temporaryPath = null;

  // data with areas
  private FileDataStore areasStore = null;
  private ListFeatureCollection areasListFeatureCollection = null;

  // data with sectors
  private FileDataStore sectorsStore = null;
  private ListFeatureCollection sectorsListFeatureCollectionToBeModified = null;
  private ListFeatureCollection sectorsListFeatureCollection = null;

  // data with barriers on which can not group sectors
  private FileDataStore barriersStore = null;
  private SimpleFeatureCollection barriersSimpleFeatureCollection = null;

  // groups of groupable types
  private List<List<String>> groupsList = null;

  public Sectors() throws IOException {
    temporaryPath = Utils.createTemporaryDirectory();
  }

  /**
   * Converts line coverage to polygon coverage.
   * The algorithm is not very good. It just need to have rings for polygons ready.
   *
   * @param input input file
   * @param output output file
   * @param template template file for output
   */
  public void linesToPolygons(String input, String output, String template) {

    SimpleFeatureSource polygon_template = null;
    try {
      FileDataStore polygon_template_store = FileDataStoreFinder.getDataStore(new File(template));
      polygon_template = polygon_template_store.getFeatureSource();
      SimpleFeatureCollection polygon_template_fc = DataUtilities.collection(polygon_template.getFeatures());
      SimpleFeatureType TYPE = polygon_template_fc.getSchema();

      List<SimpleFeature> features = new ArrayList<>();
      SimpleFeatureBuilder featureBuilder = new SimpleFeatureBuilder(TYPE);

      FileDataStore sectors_store = FileDataStoreFinder.getDataStore(new File(input));
      SimpleFeatureSource sectors = sectors_store.getFeatureSource();
      SimpleFeatureCollection sectors_fc = DataUtilities.collection(sectors.getFeatures());

      Collection polys = PolygonTools.polygonize(sectors_fc);
      System.out.println(polys.size());
      Polygon[] polyArray = GeometryFactory.toPolygonArray(polys);
      for (int i = 0; i < polyArray.length; i++) {
        featureBuilder.add(polyArray[i]);
        featureBuilder.add(i);
        SimpleFeature feature = featureBuilder.buildFeature(null);
        features.add(feature);
        //System.out.println(polyArray[i].toString());
      }

      SimpleFeatureCollection features_fc = DataUtilities.collection(features);
      ListFeatureCollection features_fc_list = new ListFeatureCollection(features_fc);
      Utils.saveFeatureCollectionToShapefile(output, features_fc_list, TYPE);

    } catch (IOException e) {
      e.printStackTrace();
    }
  }

  /**
   * Splits polygons.
   *
   * @param args parameters
   * @throws Exception in a case of reading or writing
   */
  public void splitSectors(String[] args) throws IOException {

    double arealimit = Double.parseDouble(args[1]);
    String sectorsInputPath = args[2];
    String sectorsSplittedPath = args[3];

    List<SimpleFeature> featuresForExport = new ArrayList<>();
    FileDataStore sectors_store = FileDataStoreFinder.getDataStore(new File(sectorsInputPath));
    SimpleFeatureSource sectors = sectors_store.getFeatureSource();
    SimpleFeatureCollection sectors_fc = DataUtilities.collection(sectors.getFeatures());
    ListFeatureCollection sectors_fc_list = new ListFeatureCollection(sectors_fc);
    SimpleFeatureIterator sectors_sfi = sectors_fc_list.features();

    SimpleFeatureType TYPE = sectors_fc.getSchema(); //Typ geometrie a atributy
    SimpleFeatureBuilder featureBuilder = new SimpleFeatureBuilder(TYPE);
    ; //Nástroj pro tvorbu geoprvků

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
    Utils.saveFeatureCollectionToShapefile(sectorsSplittedPath, featuresForExport_list, TYPE);
    System.out.println("End");
  }

  /**
   * Groups sectors in areas. Whole region is divided into areas. Each area is processed individually.
   * The process should be faster. There will be less objects in the collection, but I am not sure. Maybe not.
   *
   * @param args arguments for process
   * @throws Exception in a case of problems with reading or writing
   */
  public SectorsInAreasOutput groupSectorsInAreas(String[] args) throws Exception {
    // set input parameters
    SectorsInAreasInput sectorsInAreasInput = new SectorsInAreasInput();
    sectorsInAreasInput.setAreaLimit(Double.parseDouble(args[1]));
    sectorsInAreasInput.setDistance(Double.parseDouble(args[2]));
    sectorsInAreasInput.setAreaRange(new AreaRange(Double.parseDouble(args[3]), Double.parseDouble(args[4])));
    sectorsInAreasInput.setAreasPath(args[5]);
    sectorsInAreasInput.setSectorsPath(args[6]);
    sectorsInAreasInput.setBarriersPath(args[7]);
    sectorsInAreasInput.setLandusePath(args[8]);
    sectorsInAreasInput.setGroupsPath(args[9]);
    sectorsInAreasInput.setSectorsGrouppedPath(args[10]);

    System.out.println(sectorsInAreasInput);

    groupsList = Utils.getGroups(sectorsInAreasInput.getGroupsPath());
    System.out.println("Preparing landuse data ...");
    Utils.addLanduseTypeToAttributeType(sectorsInAreasInput.getSectorsPath(), sectorsInAreasInput.getLandusePath(), temporaryPath + "/sectors.shp");

    int iterCount = 0;
    boolean modified;

    // start iteration with input
    printIteraceInfo(iterCount);
    sectorsInAreasInput.setSectorsPath(temporaryPath + "/sectors.shp");
    sectorsInAreasInput.setSectorsGrouppedPath(temporaryPath + "/out" + iterCount + ".shp");

    SectorsInAreasOutput sectorsInAreasOutput = new SectorsInAreasOutput();
    List<Integer> countOfModifiedSectors =  sectorsInAreasOutput.getCountOfModifiedSectors();

    modified = groupSectorsInAreas(sectorsInAreasInput, countOfModifiedSectors);

    // do iterations in temporary files
    do {
      sectorsInAreasInput.setSectorsPath(temporaryPath + "/out" + iterCount + ".shp");
      sectorsInAreasInput.setSectorsGrouppedPath(temporaryPath + "/out" + ++iterCount + ".shp");
      modified = groupSectorsInAreas(sectorsInAreasInput, countOfModifiedSectors);
      printIteraceInfo(iterCount);
    } while (iterCount < 5 && modified);

    // finish iteration with final output
    sectorsInAreasInput.setSectorsPath(temporaryPath + "/out" + iterCount + ".shp");
    sectorsInAreasInput.setSectorsGrouppedPath(args[10]);
    modified = groupSectorsInAreas(sectorsInAreasInput, countOfModifiedSectors);

    System.out.println("\n######################");
    System.out.println("End. Modified: " + modified + ". Count of iterations: " + iterCount);

    sectorsInAreasOutput.setNumberOfIterations(iterCount);

    return sectorsInAreasOutput;
  }

  /** Prints information about iteration.
   *
   * @param iterCount iteration position
   */
  private void printIteraceInfo(int iterCount) {
    System.out.println("\n######################");
    System.out.println("Iteration: " + iterCount);
    System.out.println("######################");
  }

  /**
   * Groups sectors. Returns true if any sector has been modified.
   *
   * @param inputParametes input params {@link SectorsInAreasInput}
   * @return true if any sector was modified
   * @throws Exception in a case of problems with reading or writing
   */
  private boolean groupSectorsInAreas(SectorsInAreasInput inputParametes, List<Integer> countOfModifiedSectors)
      throws Exception {
    System.out.println();

    // opens necessary files
    openStores(inputParametes);

    // identification if any sector has been modified
    int numberOfModifiedFeaturesInAllAreas = 0;

    SimpleFeatureIterator areasSimpleFeatureIterator = areasListFeatureCollection.features();
    FilterFactory2 ff = CommonFactoryFinder.getFilterFactory2();
    // loop all areas
    while (areasSimpleFeatureIterator.hasNext()) {
      SimpleFeature area = areasSimpleFeatureIterator.next();
      System.out.println("");
      System.out.println("*** AREA: " + area.getAttribute(OBJECT_ID) + " ***");

      // set filter for the area
      Filter filter = ff.intersects(ff.property(THE_GEOM), ff.literal(area.getDefaultGeometry()));

      // count feature sin the area
      int countOfFeatures = Utils.getCount(sectorsListFeatureCollection, filter);
      System.out.println("Features count: " + countOfFeatures);

      // select only sectors in the current area
      SimpleFeatureIterator sectorsSimpleFeatureIterator = sectorsListFeatureCollection.subCollection(filter).features();

      // identifiers of sectors that has been modified
      ArrayList<String> modifiedSectors = new ArrayList();
      int numberOfModifiedFeatures = 0;
      int position = 0;
      int percent = 10;
      while (sectorsSimpleFeatureIterator.hasNext()) {
        SimpleFeature sector = sectorsSimpleFeatureIterator.next();
        MultiPolygon p = (MultiPolygon) sector.getDefaultGeometry();
        position++;
        if (getPercent(position, countOfFeatures) >= percent) {
          Utils.showProgress((int) getPercent(position, countOfFeatures));
          percent+=10;
        }
        if (p.getArea() < inputParametes.getAreaLimit()) {
          if (!modifiedSectors.contains(sector.getAttribute(OBJECT_ID).toString())) {
            if (processSurroundingSectors(sector, inputParametes, modifiedSectors)) {
              numberOfModifiedFeatures++;
            }
          }
        }
      }

      System.out.println("Modified features count: " + numberOfModifiedFeatures);
      numberOfModifiedFeaturesInAllAreas += numberOfModifiedFeatures;
    }

    saveAndDisposeStores(inputParametes.getSectorsGrouppedPath());
    countOfModifiedSectors.add(numberOfModifiedFeaturesInAllAreas);
    return numberOfModifiedFeaturesInAllAreas > 0;
  }

  /**
   * Returns percent of processed features;
   * @param position
   * @param countOfFeatures
   * @return
   */
  private double getPercent(int position, int countOfFeatures) {
    return ((double) position / (double) countOfFeatures) * 100;
  }

  /**
   * Opens necessary files for process.
   *
   * @param inputParametes input parameters
   * @throws IOException in a case of error of reading
   */

  private void openStores(SectorsInAreasInput inputParametes) throws IOException {
    // data with areas
    areasStore = FileDataStoreFinder.getDataStore(new File(inputParametes.getAreasPath()));
    areasListFeatureCollection = Utils.getListFeatureCollection(areasStore);

    // data with sectors
    sectorsStore = FileDataStoreFinder.getDataStore(new File(inputParametes.getSectorsPath()));
    sectorsListFeatureCollectionToBeModified = Utils.getListFeatureCollection(sectorsStore);
    sectorsListFeatureCollection = Utils.getListFeatureCollection(sectorsStore);

    // data with barriers on which can not group sectors
    barriersStore = FileDataStoreFinder.getDataStore(new File(inputParametes.getBarriersPath()));
    barriersSimpleFeatureCollection = Utils.getSimpleFeatureCollection(barriersStore);
    ;
  }

  /**
   * Saves output to the file and disposes stores.
   * Disposing stores is necessary, there are some violations if the dispose is ommitted.
   *
   * @param outputPath file output
   * @throws IOException in a case of error in writing
   */
  private void saveAndDisposeStores(String outputPath) throws IOException {
    Utils.saveFeatureCollectionToShapefile(outputPath, sectorsListFeatureCollectionToBeModified, sectorsListFeatureCollectionToBeModified.getSchema());
    areasStore.dispose();
    sectorsStore.dispose();
    barriersStore.dispose();
  }

  /**
   * Process surrounding sectors.
   * If any of the surrounding sectors is suitable to be groupped with the current sector,
   * the input sector is groupped with it.
   * List of modifiedSectors is
   *
   * @param sector curroent sector
   * @param inputParameters input parameters
   * @param modifiedSectors list of modified sectors ids
   *
   * @return true if the sector was modified
   */
  private boolean processSurroundingSectors(SimpleFeature sector, SectorsInAreasInput inputParameters, ArrayList<String> modifiedSectors) {
    FilterFactory2 ff = CommonFactoryFinder.getFilterFactory2();

    // creates buffer around the sector
    // the buffer is used to detect if there is barrier along the sectors borders
    Geometry sectorBuffer = ((MultiPolygon) sector.getDefaultGeometry()).buffer(inputParameters.getDistance());

    Filter filter = ff.touches(ff.property(THE_GEOM), ff.literal(sector.getDefaultGeometry()));
    SimpleFeatureIterator surroundingSectorsSimpleFeatureIterator = sectorsListFeatureCollectionToBeModified.subCollection(filter).features();

    outputGeometry = (Geometry) sector.getDefaultGeometry();
    sectorToRemove = null;
    double sharedBorderLength = 0;

    // The loop can take some time. SO we show dots to inform user thata there is some progress.
    //System.out.print(".");

    //Loops sectors that surrounds processed sector
    while (surroundingSectorsSimpleFeatureIterator.hasNext()) {
      SimpleFeature surroundingSector = surroundingSectorsSimpleFeatureIterator.next();
      Geometry surroundingSectorBuffer = ((MultiPolygon) surroundingSector.getDefaultGeometry()).buffer(inputParameters.getDistance());
      // Intersection is created on buffers. There can be problems with precision, so the buffer is necessary.
      Geometry intersectionOfSectorAndSurroundigSector = surroundingSectorBuffer.intersection(sectorBuffer);

      boolean isBarrier = isBarier(intersectionOfSectorAndSurroundigSector);
      boolean areOfGroupableTypes = areOfGroupableTypes(sector, surroundingSector);

      // the condition: there is not a barrier between sectors, the sectors has landuse type in the same group
      if (!isBarrier && areOfGroupableTypes) {
        sharedBorderLength = unionSectors(sector, surroundingSector, inputParameters.getAreaRange(), sharedBorderLength);
      }
    }

    if (sectorToRemove != null) {
      removeSectors(modifiedSectors, sector);
      return true;
    }

    return false;
  }

  /**
   * Returns true if there is a barrier in the area of intersection of two sectors.
   * @param intersectionOfSectorAndSurroundigSector intersection area where to search for barrier
   * @return true if there is a barrier in the area of intersection of two sectors.
   */
  private boolean isBarier(Geometry intersectionOfSectorAndSurroundigSector) {
    boolean isBarrier = false;
    FilterFactory2 ff = CommonFactoryFinder.getFilterFactory2();
    for (int igeom = 0; igeom < intersectionOfSectorAndSurroundigSector.getNumGeometries(); igeom++) {

      Filter filterBarriers = ff.intersects(ff.property(THE_GEOM), ff.literal(intersectionOfSectorAndSurroundigSector.getGeometryN(igeom)));
      SimpleFeatureIterator barriers_sfi = barriersSimpleFeatureCollection.subCollection(filterBarriers).features();
      //System.out.println("barriers between surrounding sector and sector");
      //Loops barriers that are in intersections between two sectors

      while (barriers_sfi.hasNext()) {
        SimpleFeature barrier = barriers_sfi.next();
        Geometry barrier_intersection = intersectionOfSectorAndSurroundigSector.intersection((Geometry) barrier.getDefaultGeometry());
        //If the perimeter of the intersection of sectors is up to 10 times bigger than barrier that is in intersection
        //then the barrier is probably along the whole intersection
        //difficult to determine limit, but 10 seems to be good
        //will do some tests on real data later
        if ((intersectionOfSectorAndSurroundigSector.getLength() / barrier_intersection.getLength()) < 10) { //10 is Experimental
          isBarrier = true;
        }
      }
    }
    return isBarrier;
  }

  /**
   * Groups two sectors if the resulting area is in limits.
   * If the new sector is better for group than previous:.
   * sets outputGeometry
   * sets sectorToRemove
   * returns updated sharedBorderLength
   * else returns input sharedBorderLength
   *
   * @param sector processed sector
   * @param surroundingSector sector to add to processed sector (group with)
   * @param areaRange areaRange to fit
   * @param sharedBorderLength sharedBorderLength from previous
   * @return updated sharedBorderLength
   */
  private double unionSectors(SimpleFeature sector, SimpleFeature surroundingSector,
      AreaRange areaRange, double sharedBorderLength) {
    GeometryFactory factory = new GeometryFactory();
    ArrayList c = new ArrayList();
    c.add(surroundingSector.getDefaultGeometry());
    c.add(sector.getDefaultGeometry());
    GeometryCollection gc = (GeometryCollection) factory.buildGeometry(c);
    Geometry union = gc.union();

    // the condition: the area must be inside the limits and better fitted to the limits than current outputGeometry
    if ((areaRange.getFit(union.getArea()) != 0)
        && (areaRange.getFit(union.getArea()) <= areaRange.getFit(outputGeometry.getArea()))) {
      // calculate shared border length
      double currentSharedBorderLength = ((MultiPolygon) surroundingSector.getDefaultGeometry()).intersection((MultiPolygon) sector.getDefaultGeometry()).getLength();
      // the condition: the shared border length must be bigger than previously computed shared border
      if (currentSharedBorderLength > sharedBorderLength) {
        // update sharedBorderLength
        sharedBorderLength = currentSharedBorderLength;
        // update outputGeometry with new geometry
        outputGeometry = union;
        // update sector that should be removed
        sectorToRemove = surroundingSector;
      }
    }
    return sharedBorderLength;
  }

  /**
   * Removes sector and sectorToRemove from listFeatureCollection.
   *
   * @param modifiedSectors isd of modified sectors
   * @param sector processed sector
   */
  private void removeSectors(ArrayList<String> modifiedSectors, SimpleFeature sector) {
    // removes the sectorToRemove from the collection
    // adds sectorToRemove id to the modified sectors list ids
    sectorsListFeatureCollectionToBeModified.remove(sectorToRemove);
    modifiedSectors.add(sectorToRemove.getAttribute(OBJECT_ID).toString());

    // removes the processed sector from the collection
    sectorsListFeatureCollectionToBeModified.remove(sector);

    // changes the geometry of th eprocessed sector to the new geometry that is output of union operation
    sector.setDefaultGeometry(outputGeometry);
    // adds processed sector back to the collection, but with modified geometry
    sectorsListFeatureCollectionToBeModified.add(sector);
  }

  /**
   * We can group just some types of areas types. Such as forest with forest or stream with lake,
   * but not for example meadow with forest. The rules should be in the configuration file.
   *
   * @param sector
   * @param sectorToAdd
   * @return true if the most area of both sectors is from the groupable types on the landuse
   */
  private boolean areOfGroupableTypes(SimpleFeature sector, SimpleFeature sectorToAdd) {
    List<String> items = new ArrayList<>();
    items.add(sector.getAttribute(TYPE).toString());
    items.add(sectorToAdd.getAttribute(TYPE).toString());

    return Utils.areTypesInOneOfTheGroup(groupsList, items);
  }
}