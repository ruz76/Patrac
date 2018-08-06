package cz.vsb.gis.ruz76.patrac.inputs;

import cz.vsb.gis.ruz76.patrac.domain.AreaRange;

/**
 * Class to hold input parameters.
 */

public class SectorsInAreasInput {
  double areaLimit;
  double distance;
  AreaRange areaRange;
  String areasPath;
  String sectorsPath;
  String barriersPath;
  String landusePath;
  String groupsPath;
  String sectorsGrouppedPath;

  public double getAreaLimit() {
    return areaLimit;
  }

  public void setAreaLimit(double areaLimit) {
    this.areaLimit = areaLimit;
  }

  public double getDistance() {
    return distance;
  }

  public void setDistance(double distance) {
    this.distance = distance;
  }

  public AreaRange getAreaRange() {
    return areaRange;
  }

  public void setAreaRange(AreaRange areaRange) {
    this.areaRange = areaRange;
  }

  public String getAreasPath() {
    return areasPath;
  }

  public void setAreasPath(String areasPath) {
    this.areasPath = areasPath;
  }

  public String getSectorsPath() {
    return sectorsPath;
  }

  public void setSectorsPath(String sectorsPath) {
    this.sectorsPath = sectorsPath;
  }

  public String getBarriersPath() {
    return barriersPath;
  }

  public void setBarriersPath(String barriersPath) {
    this.barriersPath = barriersPath;
  }

  public String getSectorsGrouppedPath() {
    return sectorsGrouppedPath;
  }

  public void setSectorsGrouppedPath(String sectorsGrouppedPath) {
    this.sectorsGrouppedPath = sectorsGrouppedPath;
  }

  public String getLandusePath() {
    return landusePath;
  }

  public void setLandusePath(String landusePath) {
    this.landusePath = landusePath;
  }

  public String getGroupsPath() {
    return groupsPath;
  }

  public void setGroupsPath(String groupsPath) {
    this.groupsPath = groupsPath;
  }

  @Override
  public String toString() {
    return "AreaLimit: " + areaLimit + "\n"
        + "Distance: " + distance + "\n"
        + "Range.min: " + areaRange.getMin() + "\n"
        + "Range.max: " + areaRange.getMax() + "\n"
        + "AreasPath: " + areasPath + "\n"
        + "SectorsPath: " + sectorsPath + "\n"
        + "BarrierrsPath: " + barriersPath + "\n"
        + "LandusePath: " + landusePath + "\n"
        + "GroupsPath: " + groupsPath + "\n"
        + "SectorsGrouppedPath: " + sectorsGrouppedPath + "\n";
  }
}
