#

## Suspicious
AH58

# New apprcoah from 2023-03-02

## prepare

cd patracdata/osm
wget https://download.geofabrik.de/europe/czech-republic-latest.osm.pbf
cd split
echo ka > KRAJ.id
echo nu33051 > KRAJ_ID.id
su patrac -c 'bash prepare.sh'
bash runTasks.sh

Do not split plygons. But do same as for building them but with lines extended by 50 m.

```bash
date
WD=/home/jencek/Documents/Projekty/PCR/github/Patrac/data/to_split_10
DD=/data/patracdata/kraje/zl
rm $WD/outputs/*
python3 process.py $WD $DD 0
python3 process.py $WD $DD 1
python3 process.py $WD $DD 2
python3 process.py $WD $DD 3
date
```

## maybe enhancement
HS182, JT93 - half island
AH19, BM1, CJ46, DE51, DF174, DN70, EO152, FN127, BI137, EN151 - close distance
AK3, CE92, CL31, GB58 - priority - more rounds
- No pruseky, no elved for first round
DE132, EM123, BI6, BI69, EM123 - rotation or close distance clean - 20 m

## Suspicious
BH3, BI69, CM13, DF84, DG214, DK127, DK51, DL5, DM110, EN151, EN209, EN86, EQ128, EQ183, EQ210, FA1, FK107, FL1, GG21, GG189, GS50, DM110, JD78 - Missing data
CK119, DB6, ER7, FI30, HB237, DD46, DN70 - not existing in ZPM

## No problems
BH3, CM13, DD46, DF84, DG214, DK127, DK51, DL5, DN110, EN151, EN209, EQ128, EQ183, EQ210, FA1, FL1, FK107, FI30, FL1, GG21, GS50, DM110, JD78 - Missing data
CK119, DN70, ER7, FI30, DD46, DN70 - not existing in ZPM

## Problems
HB237 - fixed by two rounds
EN86 - fixed by snap on 1 m - but produces some errors in other situations, so maybe run at the end
DB6 - now is OK
EH144, EH144 - no geometry - Topology exception - should be fixed by fixing geometries
FL36 - very special case


# Deprecated
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

Problems after second version:
DL17
DL25
DN70
EL216
FD174 - why the cable was not taken?
FO18
FR15 - why it did not take the path on west
GM146
GO57
GP208 - why the two paths were not used in 59 area
GP45
GR2
HF1
HF61
ID114
ID133
IE3
IN181
JD186
JD78
JF100 - why it does not take types in account
KE82
KF7
KQ187

Small problems:
DM110
DM18
DN68
FN27
HR33
HS104 - OSM
IE110
JE173 - why it does not take the path that is longer than water
KN59 - why so strange shape

20-25 ha:
CD105
CM53
EB44

20-25 ha, but fair:
CL160
CL190
EO155
FD46
GO27

Perfect results:
NY98
NY22
DD46
EM123
FE30
FL207
FL161
FN199
GO71
GP116
IS110
IS164
JE113
KM5 - Na Pološtině
KN24
KN27


Nothing cutted:
EB56
EK215
EQ228

Shifted line:
EE8
FN45

River:
EH144

Problems after third version:
FL207 - should be splitted - need to find joins to another lines
CL190
DM110
DN70
EM123
GP45
HR33
HS104
IS110
KE82
NY98
