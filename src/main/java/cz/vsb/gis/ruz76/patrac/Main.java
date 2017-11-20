package cz.vsb.gis.ruz76.patrac;

/**
 * Created by jencek on 27.2.17.
 */
public class Main {
    public static void main(String[] args) {
        //Radial.printSectors();
        Sectors s = new Sectors();
        try {
            if (args.length < 3) {
                if (args.length == 1) {
                    Tests.polygonize(args[0]);
                } else {
                    System.out.println("Usage: method params");
                    System.out.println("Example: group arealimit tolerance areamin areamax input.shp output.shp barriers.shp");
                    System.out.println("Example: group 100000 5 200000 500000 data/osm_landuse_combined_clean.shp data/sectors_group.shp data/osm_roads_selected.shp");
                    System.out.println("Example: split arealimit areamin areamax input.shp output.shp split.shp");
                    System.out.println("Example: group 500000 5 200000 500000 data/sectors_group.shp data/sectors_split.shp data/osm_paths.shp");
                }
            } else {
                System.out.println(args[0]);
                if (args[0].equalsIgnoreCase("group")) {
                    s.BARRIERS = args[7];
                    s.SECTORS_INPUT = args[5];
                    s.SECTORS_GROUPPED = args[6];
                    s.groupSectors(Double.parseDouble(args[1]), Double.parseDouble(args[2]), new AreaRange(Double.parseDouble(args[3]), Double.parseDouble(args[4])));
                }
                if (args[0].equalsIgnoreCase("split")) {
                    s.SECTORS_INPUT = args[4];
                    s.SECTORS_SPLITTED = args[5];
                    s.BARRIERS_FOR_SPLIT_LINES = args[6];
                    s.splitSectors(Double.parseDouble(args[1]));
                }
            }
            //s.groupSectors(100000, 5, new AreaRange(200000, 500000));
            //s.splitSectors(500000);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
