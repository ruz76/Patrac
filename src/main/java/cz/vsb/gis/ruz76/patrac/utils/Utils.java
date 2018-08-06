package cz.vsb.gis.ruz76.patrac.utils;

import static java.util.stream.Collectors.toList;

import com.vividsolutions.jts.geom.Geometry;
import com.vividsolutions.jts.geom.MultiPolygon;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import org.geotools.data.DataUtilities;
import org.geotools.data.DefaultTransaction;
import org.geotools.data.FileDataStore;
import org.geotools.data.FileDataStoreFinder;
import org.geotools.data.Transaction;
import org.geotools.data.collection.ListFeatureCollection;
import org.geotools.data.shapefile.ShapefileDataStore;
import org.geotools.data.shapefile.ShapefileDataStoreFactory;
import org.geotools.data.simple.SimpleFeatureCollection;
import org.geotools.data.simple.SimpleFeatureIterator;
import org.geotools.data.simple.SimpleFeatureSource;
import org.geotools.data.simple.SimpleFeatureStore;
import org.geotools.factory.CommonFactoryFinder;
import org.geotools.feature.simple.SimpleFeatureBuilder;
import org.geotools.feature.simple.SimpleFeatureTypeBuilder;
import org.opengis.feature.simple.SimpleFeature;
import org.opengis.feature.simple.SimpleFeatureType;

import java.io.File;
import java.io.IOException;
import java.io.Serializable;
import java.net.MalformedURLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import org.opengis.filter.Filter;
import org.opengis.filter.FilterFactory2;

/**
 * Class for utils.
 */
public class Utils {

  public static final String THE_GEOM = "the_geom";
  public static final String TYPE = "TYPE";
  public static final String PATRAC = "patrac";

  /**
   * Saves the collection to yhe file.
   *
   * @param path path for shapefile
   * @param features ListFeatureCollection
   * @param type SimpleFeatureType
   * @throws MalformedURLException in a case of bas path
   * @throws IOException in a case o some problem with writing
   */
  public static void saveFeatureCollectionToShapefile(final String path, final ListFeatureCollection features, final SimpleFeatureType type)
      throws MalformedURLException, IOException {
    File newFile = new File(path);

    java.util.Map<String, Serializable> params = new HashMap<String, Serializable>();
    params.put("url", newFile.toURI().toURL());

    // creates the configuration where to save the file
    ShapefileDataStoreFactory dataStoreFactory = new ShapefileDataStoreFactory();
    ShapefileDataStore newDataStore = (ShapefileDataStore) dataStoreFactory.createNewDataStore(params);
    // sets feature type
    newDataStore.createSchema(type);
    newDataStore.forceSchemaCRS(type.getGeometryDescriptor().getCoordinateReferenceSystem());

    // starts the transaction
    Transaction transaction = new DefaultTransaction("create");
    String typeName = newDataStore.getTypeNames()[0];
    SimpleFeatureSource featureSource = newDataStore.getFeatureSource(typeName);
    SimpleFeatureStore featureStore = (SimpleFeatureStore) featureSource;
    featureStore.setTransaction(transaction);
    featureStore.addFeatures(features);
    // commits the transaction
    transaction.commit();
    transaction.close();
  }

  /**
   * Recalculates the attribute cat. Adds unique cat for each feature, starting with 0.
   * @param input file input
   * @param output file output
   * @throws IOException in a case o some problem with reading or writing
   */
  public static void recalculateCats(final String input, final String output) throws IOException {
    ListFeatureCollection inputFcList = getListFeatureCollection(input);
    SimpleFeatureIterator inputSfi = inputFcList.features();
    List<SimpleFeature> features = new ArrayList<>();

    int cat = 0;
    while (inputSfi.hasNext()) {
      SimpleFeature feature = inputSfi.next();
      feature.setAttribute("cat", cat);
      features.add(feature);
      cat++;
    }

    SimpleFeatureCollection simpleFeatureCollection = DataUtilities.collection(features);
    ListFeatureCollection listFeatureCollection = new ListFeatureCollection(simpleFeatureCollection);
    Utils.saveFeatureCollectionToShapefile(output, listFeatureCollection, inputFcList.getSchema());
  }

  /**
   * Reads all shapefiles in the directory (must be one geometry type)-
   * Merges them into one shapefile.
   * Each feature has on output just one attribute (TYPE) and it contains name of the input file.
   * Template is used to hold geometyr type and attribute type TYPE.
   *
   * @param directory directory of shapefiles
   * @param output output filename
   * @param template template filename
   * @throws IOException in a case o some problem with reading or writing
   */
  public static void addShapefileNameToAttributeType(String directory, String output, String template) throws IOException {
    // get files from directory
    List<Path> files = Files.walk(Paths.get(directory))
        .filter(s -> s.toString().endsWith(".shp"))
        .map(Path::getFileName)
        .sorted()
        .collect(toList());

    // create empty feature collection
    List<SimpleFeature> features = new ArrayList<>();

    // process each file
    for (Path path : files) {
      String input = directory + path.toString();
      addShapefileNameToAttributeType(input, features, template, path.toString());
    }

    SimpleFeatureCollection simpleFeatureCollection = DataUtilities.collection(features);
    ListFeatureCollection listFeatureCollection = new ListFeatureCollection(simpleFeatureCollection);
    Utils.saveFeatureCollectionToShapefile(output, listFeatureCollection, getSimpleFeatureType(template));
  }

  /**
   * Adds features from input to features and sets the attribute TYPE to the type value.
   *
   * @param input inout file
   * @param features list of features
   * @param template template file with configuration
   * @param type type value to set
   * @throws IOException in a case o some problem with reading or writing
   */
  private static void addShapefileNameToAttributeType(String input, List<SimpleFeature> features, String template, String type) throws IOException {
    ListFeatureCollection inputFcList = getListFeatureCollection(input);
    SimpleFeatureIterator inputSfi = inputFcList.features();

    SimpleFeatureType sft = getSimpleFeatureType(template);
    SimpleFeatureTypeBuilder stb = new SimpleFeatureTypeBuilder();
    stb.init(sft);
    stb.setName("newFeatureType");
    SimpleFeatureType newFeatureType = stb.buildFeatureType();
    SimpleFeatureBuilder sfb = new SimpleFeatureBuilder(newFeatureType);

    while (inputSfi.hasNext()) {
      SimpleFeature feature = inputSfi.next();
      List<Object> attributes = new ArrayList<>();
      attributes.add(feature.getDefaultGeometry());
      attributes.add(type);
      SimpleFeature newFeature = sfb.buildFeature(feature.getID());
      newFeature.setAttributes(attributes);
      features.add(newFeature);
    }
  }

  /**
   * Adds landuse type to features.
   *
   * @param input input file
   * @param landuse landuse file
   * @param output output file
   * @throws IOException in a case o some problem with reading or writing
   */
  public static void addLanduseTypeToAttributeType(String input, String landuse, String output) throws IOException {
    ListFeatureCollection inputFcList = getListFeatureCollection(input);
    ListFeatureCollection landuseFcList = getListFeatureCollection(landuse);

    SimpleFeatureIterator inputSfi = inputFcList.features();

    SimpleFeatureType sft = getSimpleFeatureType(input);
    SimpleFeatureTypeBuilder stb = new SimpleFeatureTypeBuilder();
    stb.init(sft);
    stb.setName("newFeatureType");
    stb.add(TYPE, String.class);
    SimpleFeatureType newFeatureType = stb.buildFeatureType();
    SimpleFeatureBuilder sfb = new SimpleFeatureBuilder(newFeatureType);

    List<SimpleFeature> features = new ArrayList<>();

    while (inputSfi.hasNext()) {
      SimpleFeature feature = inputSfi.next();
      List<Object> attributes = feature.getAttributes();
      attributes.add(getMostPresentLanduseType(feature, landuseFcList));
      SimpleFeature newFeature = sfb.buildFeature(feature.getID());
      newFeature.setAttributes(attributes);
      features.add(newFeature);
    }

    SimpleFeatureCollection simpleFeatureCollection = DataUtilities.collection(features);
    ListFeatureCollection listFeatureCollection = new ListFeatureCollection(simpleFeatureCollection);
    Utils.saveFeatureCollectionToShapefile(output, listFeatureCollection, newFeatureType);
  }

  /**
   * Returns the most present landuse type in the sector.
   *
   * @param sector sector to evaluate
   * @return type of the most present landuse type in the sector.
   */
  private static String getMostPresentLanduseType(SimpleFeature sector, ListFeatureCollection landuseListFeatureCollection) {
    FilterFactory2 ff = CommonFactoryFinder.getFilterFactory2();
    Filter filterLanduse = ff.intersects(ff.property(THE_GEOM), ff.literal(sector.getDefaultGeometry()));
    SimpleFeatureIterator landuseSimpleFeatureIterator = landuseListFeatureCollection.subCollection(filterLanduse).features();
    double mostTypePercent = 0;
    String mostTypeName = "";
    while (landuseSimpleFeatureIterator.hasNext()) {
      SimpleFeature feature = landuseSimpleFeatureIterator.next();
      MultiPolygon multiPolygonLanduse = (MultiPolygon) feature.getDefaultGeometry();
      MultiPolygon multiPolygonSector = (MultiPolygon) sector.getDefaultGeometry();
      Geometry geomIntersection = multiPolygonLanduse.intersection(multiPolygonSector);
      double currentTypePercent = (multiPolygonSector.getArea() / geomIntersection.getArea()) * 100;
      if (currentTypePercent > mostTypePercent) {
        mostTypePercent = currentTypePercent;
        mostTypeName = feature.getAttribute(TYPE).toString();
      }
    }
    return mostTypeName;
  }

  /**
   * Returns ListFeatureCollection from input file.
   * @param input input file
   * @return ListFeatureCollection from input file
   * @throws IOException in a case o some problem with reading or writing
   */
  public static ListFeatureCollection getListFeatureCollection(String input) throws IOException {
    FileDataStore fileDataStore = FileDataStoreFinder.getDataStore(new File(input));
    return getListFeatureCollection(fileDataStore);
  }

  /**
   * Returns ListFeatureCollection from input FileDataStore.
   * @param fileDataStore input FileDataStore
   * @return ListFeatureCollection from input file
   * @throws IOException in a case o some problem with reading or writing
   */
  public static ListFeatureCollection getListFeatureCollection(FileDataStore fileDataStore) throws IOException {
    SimpleFeatureSource simpleFeatureSource = fileDataStore.getFeatureSource();
    SimpleFeatureCollection simpleFeatureCollection = DataUtilities.collection(simpleFeatureSource.getFeatures());
    ListFeatureCollection listFeatureCollection = new ListFeatureCollection(simpleFeatureCollection);
    return listFeatureCollection;
  }

  /**
   * Returns SimpleFeatureCollection of the input.
   * @param input input file
   * @return SimpleFeatureCollection of the input
   * @throws IOException in a case o some problem with reading
   */
  public static SimpleFeatureCollection getSimpleFeatureCollection(String input) throws IOException {
    FileDataStore fileDataStore = FileDataStoreFinder.getDataStore(new File(input));
    return getSimpleFeatureCollection(fileDataStore);
  }

  /**
   * Returns SimpleFeatureCollection of the input FileDataStore.
   * @param fileDataStore FileDataStore
   * @return SimpleFeatureCollection of the input FileDataStore
   * @throws IOException in a case o some problem with reading
   */
  public static SimpleFeatureCollection getSimpleFeatureCollection(FileDataStore fileDataStore) throws IOException {
    SimpleFeatureSource simpleFeatureSource = fileDataStore.getFeatureSource();
    SimpleFeatureCollection simpleFeatureCollection = DataUtilities.collection(simpleFeatureSource.getFeatures());
    return simpleFeatureCollection;
  }

  /**
   * Returns SimpleFeatureType of the input file.
   * @param input input file
   * @return SimpleFeatureType of the input file
   * @throws IOException in a case o some problem with reading
   */
  private static SimpleFeatureType getSimpleFeatureType(String input) throws IOException {
    FileDataStore fileDataStore = FileDataStoreFinder.getDataStore(new File(input));
    SimpleFeatureSource inputFs = fileDataStore.getFeatureSource();
    return inputFs.getSchema();
  }

  /**
   * Returns number of features in collection.
   * The collection can be filtere with filter.
   * If the filter is null, number of all features is returned.
   *
   * @param listFeatureCollection feature collection to count
   * @param filter filter to apply
   * @return count of features
   */
  public static int getCount(ListFeatureCollection listFeatureCollection, Filter filter) {
    SimpleFeatureIterator sectorsSimpleFeatureIterator = null;
    if (filter != null) {
      sectorsSimpleFeatureIterator = listFeatureCollection.subCollection(filter).features();
    } else {
      sectorsSimpleFeatureIterator = listFeatureCollection.features();
    }
    int count = 0;
    if (sectorsSimpleFeatureIterator != null) {
      while (sectorsSimpleFeatureIterator.hasNext()) {
        sectorsSimpleFeatureIterator.next();
        count++;
      }
    }
    return count;
  }

  /**
   * Prints progress.
   *
   * @param percent percent to show
   * @throws IOException in a case of system out error
   */
  public static void showProgress(double percent) throws IOException {
    System.out.println(percent + " %");
    /*String anim= "|/-\\";
    String data = "\r" + anim.charAt((int) percent % anim.length()) + " " + percent;
    System.out.write(data.getBytes());*/
  }

  /**
   * Return groups of groupable landuse types.
   *
   * @param directory directory with configuration files
   * @return groups of groupable landuse types
   * @throws IOException in a case of error of reading
   */
  public static List<List<String>> getGroups(String directory) throws IOException {

    // get files from direcotry
    List<Path> files = Files.walk(Paths.get(directory))
        .filter(s -> s.toString().endsWith(".group"))
        .map(Path::getFileName)
        .sorted()
        .collect(toList());

    List<List<String>> groups = new ArrayList<>();

    // process each file
    for (Path path : files) {
      String input = directory + path.toString();
      Stream<String> stream = Files.lines(Paths.get(input));
      List<String> list = stream.collect(Collectors.toList());
      groups.add(list);
    }

    return groups;
  }

  /**
   * Return true if all items are in one of the groups.
   *
   * @param groups
   * @param items
   * @return
   */
  public static boolean areTypesInOneOfTheGroup(List<List<String>> groups, List<String> items) {
    for (List<String> group : groups) {
      if (group.containsAll(items)) {
        return true;
      }
    }
    return false;
  }

  public static Path createTemporaryDirectory() throws IOException {
    return Files.createTempDirectory(PATRAC);
  }
}
