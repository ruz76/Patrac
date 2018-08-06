package cz.vsb.gis.ruz76.patrac.domain;

/**
 * Class for holding information about limits for area of sector.
 */
public class AreaRange {

  private double min;
  private double max;

  public AreaRange(double min, double max) {
    this.min = min;
    this.max = max;
  }

  public double getMin() {
    return min;
  }

  public void setMin(double min) {
    this.min = min;
  }

  public double getMax() {
    return max;
  }

  public void setMax(double max) {
    this.max = max;
  }

  private double getCenter() {
    return min + ((max - min) / 2);
  }

  private double getRange() {
    return max - min;
  }

  /**
   * Returns 0 if the area is out of limits.
   * Is bigger or smaller.
   * Returns value that shows how close is to the center of the range.
   *
   * @param value area
   * @return value that shows how close is to the center of the range or zero in a case that is out of range.
   */
  public double getFit(double value) {
    // the condition: if the area is bigger than max or smaller than min then there is not fit
    //if (value < min || value > max ) return 0;
    // the condition: if the area is bigger than max then there is not fit
    if (value > max) {
      return 0;
    }
    double diff = Math.abs(getCenter() - value);
    return diff;
  }
}
