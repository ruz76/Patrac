First ideas how to solve the split problem. 
Some of the sectors are too big to be directly used for search.
We should try to split them. 

We will work individually with each sector. Do the following operations.
* Select streams and roads that are crossing the sector
* There should be nly streams and roads that do not cross sector fully, but I saw in 
  data that this is not true. So probably first we can try to split with the lines without 
  any modification.
* The lines are as separate segments, so probably the first step before splitting may be
  joining lines that touches each other.
* What seems to be problem at the beginning is that some of the lines are touching 
  border of the sector. Those should be probably removed before processing. There
  may be problem with precision, so probably small buffer such as 0.1 m may be used.
* If we have lines cleaned and joined. We can try split.
* Than we should loop via lines and try to determined how to use it.
* Either the line is so close to two borders that there is not need to search for
  other line to join. Such line we can just extend on both ends to cross the
  border of the sector. Than we can use such extened line to split the sector.
* Or the line is quite far away from one of the borders. In that case we should find 
  closest line (or maybe more than one and create some alternatives) that crosses
  the sector border. We join those two lines and do the split.
* What is problematic is that the split will create new two (or more) polygons
  and the split with next lines should probably split those polygons instead of
  splitting original polygon. 

There should be some optimisation part, since we do not want to have not well
formed polygons. We should use simillar approach as for joining algorithm written
in Java. So the polygons should be similar to rectangle in shape as much as possible.

Algorithm
* Remove border covering lines
* Inner buffer to remove half-islands
- do 10 m, 20 m - 50 m inner buffer and if it creates more than one polygon than there is a half-islands    
* Join lines that touch
* Split
* Loop lines
  * Check if the line is close to border in both ends. 
    * If: Extend and split.
    * Else: Select closest line. Join and split.  

In the loop we have to keep collection of sectors updated and always compare
line with all polygons.

Limits
* close to border 
  * 100 m - size that dog can sniff in very good conditions, so the error should not be so big. 
    This is initial size, but if we can not split the sector with this limit, the limit
    must be extended.

The Algorithm should be run several times until we reach required output with different limits. 
All new sectors are smaller than 20 ha.

Problems after first version:
SQ74
SQ56
SQ28
SQ233 - There are some borders in OSM - landuse/farmland from LPIS

Perfect results:
NY98
NY22