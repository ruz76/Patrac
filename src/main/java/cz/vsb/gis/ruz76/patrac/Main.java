package cz.vsb.gis.ruz76.patrac;

/**
 * Created by jencek on 27.2.17.
 */
public class Main {
    public static void main(String[] args) {
        Radial.printSectors();
        Sectors s = new Sectors();
        try {
            //s.groupSectors(100000, 5, new AreaRange(200000, 500000));
            s.splitSectors(500000);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
