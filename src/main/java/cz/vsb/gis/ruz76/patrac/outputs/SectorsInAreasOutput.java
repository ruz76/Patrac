package cz.vsb.gis.ruz76.patrac.outputs;

import java.util.ArrayList;
import java.util.List;

/**
 * Class to hold output results.
 */

public class SectorsInAreasOutput {
  List<Integer> countOfModifiedSectors;
  int numberOfIterations;

  public List<Integer> getCountOfModifiedSectors() {
    if (countOfModifiedSectors == null) {
      countOfModifiedSectors = new ArrayList<>();
    }
    return countOfModifiedSectors;
  }

  public int getNumberOfIterations() {
      return numberOfIterations;
  }

  public void setNumberOfIterations(int numberOfIterations) {
    this.numberOfIterations = numberOfIterations;
  }
}
