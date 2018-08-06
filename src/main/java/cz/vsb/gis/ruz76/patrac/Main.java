package cz.vsb.gis.ruz76.patrac;

import cz.vsb.gis.ruz76.patrac.experimental.Experiments;
import cz.vsb.gis.ruz76.patrac.utils.LineTools;
import cz.vsb.gis.ruz76.patrac.utils.Utils;

/**
 * Main class.
 */
public class Main {

  /**
   * Mian method to run operations.
   *
   * @param args parameters for run
   */
  public static void main(String[] args) {
    //Radial.printSectors();
    try {
      Sectors s = new Sectors();
      if (args.length < 2) {
        showHelp(null, 0, 0);
      } else {
        System.out.println(args[0]);
        switch (args[0]) {
          case "group":
            checkNumberOfParameters(args, 11);
            s.groupSectorsInAreas(args);
            break;
          case "split":
            checkNumberOfParameters(args, 4);
            s.splitSectors(args);
            break;
          case "polygonize":
            checkNumberOfParameters(args, 4);
            s.linesToPolygons(args[1], args[2], args[3]);
            break;
          case "remove_zero_points":
            checkNumberOfParameters(args, 3);
            LineTools.removeZeroPoints(args[1], args[2]);
            break;
          case "tests":
            checkNumberOfParameters(args, 3);
            Experiments.loopSelect(args[1], args[2]);
            //Experiments.polygonize(args[0]);
            //Experiments.linesToPolygons(args[0], args[1], args[2]);
            break;
          case "recalculate":
            checkNumberOfParameters(args, 3);
            Utils.recalculateCats(args[1], args[2]);
            break;
          case "merge":
            checkNumberOfParameters(args, 4);
            Utils.addShapefileNameToAttributeType(args[1], args[2], args[3]);
            break;
          default:
            showHelp(null, 0, 0);
        }

      }
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  private static void checkNumberOfParameters(String[] args, int count) {
       if (args.length != count) {
         showHelp(args[0], count, args.length);
         System.exit(1);
       }
  }

  private static void showHelp(String mode, int expectedNumberOfParams, int providedNumberOfParams) {
    if (mode != null) {
      System.out.println("For mode: " + mode
          + " is expected number of parameters " + expectedNumberOfParams
          + " but was provided by " +  providedNumberOfParams + " count of parameters");
    }

    System.out.println("\nUsage: method params");
    System.out.println("\nMethods: merge group split remove_zero_points recalculate");
    System.out.println("\nMethod merge");
    System.out.println("Merges files into one and adds filename as attribute of the file");
    System.out.println("merge input_directory output_file template_file");
    System.out.println("\n* input_directory: path to the directory with shapefiles");
    System.out.println("* output_file: path to the output shapefile");
    System.out.println("* template_file: path to the template shapefile "
        + "it must be the same geometry as input and contains just one attribute of name TYPE and type String");
    System.out.println("\nExample: merge /data/tm/cvicne/areas/ /data/tmp/cvicne/output.shp /data/tmp/cvicne/template.shp");
    System.out.println("\nMethod group");
    System.out.println("group arealimit tolerance areamin areamax areas sectors barriers landuse groups_directory output");
    System.out.println("\n* arealimit: under this limit, areas are processed (e.q. 10 ha - 10000) in sqm");
    System.out.println("* tolerance: tolerance in meters for precision (5 meters should be OK in most cases)");
    System.out.println("* areamin: minimum size of output area in sqm ");
    System.out.println("* areamax: maximum size of output area in sqm ");
    System.out.println("* areas: path to the shapefile that contains areas in which is the region divided. "
        + "Can be just one feature, if the whole area may be processed in one loop. ");
    System.out.println("* sectors: path to the input shapefile with sectors to optimize ");
    System.out.println("* barriers: path to the shapefile with barriers. Sectors that share the barrier can not be joined");
    System.out.println("* landuse: path to the shapefile with landuse.");
    System.out.println("* groups_directory: path to the directory that contains files with extension group (e.q. 1.group).\n"
        + "The file contains names of the landuse categories (from TYPE field from landuse shapefile) that can be joined.\n"
        + "Each category is on new line.");
    System.out.println("* output: path to the output shapefile with optimized sectors.");
    System.out.println(
        "\nExample: group 100000 5 200000 500000 "
            + "/data/patracdata/kraje/hk/vektor/ZABAGED/line_x/landuse_barriers2_polygons.shp\n"
            + "/data/patracdata/kraje/hk/vektor/ZABAGED/line_x/merged_polygons.shp\n"
            + "/data/patracdata/kraje/hk/vektor/ZABAGED/line_x/landuse_barriers2.shp\n"
            + "/data/patracdata/kraje/hk/vektor/ZABAGED/landuse/landuse.shp\n"
            + "/data/patracdata/kraje/hk/vektor/ZABAGED/landuse/groups/\n"
            + "/data/patracdata/kraje/hk/vektor/ZABAGED/line_x/merged_polygons_groupped.shp");

  }
}
