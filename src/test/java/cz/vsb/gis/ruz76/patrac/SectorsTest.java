package cz.vsb.gis.ruz76.patrac;

import static java.util.function.Predicate.isEqual;
import static org.junit.Assert.*;

import cz.vsb.gis.ruz76.patrac.outputs.SectorsInAreasOutput;
import cz.vsb.gis.ruz76.patrac.utils.Utils;
import java.io.File;
import java.io.IOException;
import java.nio.file.Path;
import org.junit.Before;
import org.junit.Test;

public class SectorsTest {

  private static final String AREAS = "areas.shp";
  private static String areasPath = null;

  private static final String SECTORS = "sectors.shp";
  private static String sectorsPath = null;

  private static final String BARRIERS = "barriers.shp";
  private static String barriersPath = null;

  private static final String LANDUSE = "landuse.shp";
  private static String landusePath = null;

  private static final String GROUPS = "groups";
  private static String groupsPath = null;

  private static final String SECTORS_GROUPPED = "sectors_groupped.shp";
  private static String sectorsGrouppedPath = null;

  private static final String AREA_LIMIT = "100000";
  private static final String TOLERANCE = "5";
  private static final String RANGE_MIN = "200000";
  private static final String RANGE_MAX = "500000";

  private static final String METHOD_GROUP = "group";
  private static final int SIZE_OF_MODIFIED_LIST = 3;
  private static final int COUNT_OF_ITERATIONS = 1;
  private static final int COUNT_OF_MODIFIED_FEATURES = 12;

  /**
   * Load resources.
   */
  @Before
  public void setup() {
    areasPath = getFilePath(AREAS);
    sectorsPath = getFilePath(SECTORS);
    barriersPath = getFilePath(BARRIERS);
    landusePath = getFilePath(LANDUSE);
    groupsPath = getFilePath(GROUPS);
    try {
      Path path = Utils.createTemporaryDirectory();
      sectorsGrouppedPath = path + "/" + SECTORS_GROUPPED;
    } catch (IOException e) {
      e.printStackTrace();
      fail();
    }
  }

  /**
   * Tests the optimal scenario.
   * Optimization is done in SIZE_OF_MODIFIED_LIST steps. So the last iteration id is COUNT_OF_ITERATIONS.
   * The number of modified features in fist step is COUNT_OF_MODIFIED_FEATURES.
   */
  @Test
  public void groupSectorsInAreas() {
    try {
      Sectors sectors = new Sectors();
      SectorsInAreasOutput sectorsInAreasOutput = sectors.groupSectorsInAreas(getArgs());
      assertFalse(sectorsInAreasOutput.getCountOfModifiedSectors().isEmpty());
      assertEquals(sectorsInAreasOutput.getCountOfModifiedSectors().size(), SIZE_OF_MODIFIED_LIST);
      assertEquals(sectorsInAreasOutput.getNumberOfIterations(), COUNT_OF_ITERATIONS);
      assertEquals(sectorsInAreasOutput.getCountOfModifiedSectors().get(0).intValue(), COUNT_OF_MODIFIED_FEATURES);
    } catch (IOException e) {
      fail();
    } catch (Exception e) {
      fail();
    }
  }

  private String getFilePath(String filename) {
    ClassLoader classLoader = SectorsTest.class.getClassLoader();
    File file = new File(classLoader.getResource(filename).getFile());
    return file.getAbsolutePath();
  }

  private String[] getArgs() {
    String[] args = new String[11];
    args[0] = METHOD_GROUP;
    args[1] = AREA_LIMIT;
    args[2] = TOLERANCE;
    args[3] = RANGE_MIN;
    args[4] = RANGE_MAX;
    args[5] = areasPath;
    args[6] = sectorsPath;
    args[7] = barriersPath;
    args[8] = landusePath;
    args[9] = groupsPath + "/";
    args[10] = sectorsGrouppedPath;
    return args;
  }
}