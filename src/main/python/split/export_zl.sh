bash export_vectors_zpm.sh /data/patracdata/kraje/zl -584236.0010035008890554 -1209947.6499967132695019 -448767.1400032062083483 -1111463.9389963292051107 /home/jencek/Documents/Projekty/PCR/github/Patrac/data/zl
bash export_vectors_osm.sh -584236.0010035008890554 -1209947.6499967132695019 -448767.1400032062083483 -1111463.9389963292051107 /home/jencek/Documents/Projekty/PCR/github/Patrac/data/zl

cd /home/jencek/Documents/Projekty/PCR/github/Patrac/data/zl
mv osm_highway_track.cpg _osm_highway_track.cpg
mv osm_highway_track.dbf _osm_highway_track.dbf
mv osm_highway_track.shp _osm_highway_track.shp
mv osm_highway_track.shx _osm_highway_track.shx
ogrmerge.py -field_strategy FirstLayer -single -o lines_for_split_full.shp *.shp
mv lines_for_split_full.* /data/patracdata/kraje/zl/vektor/ZABAGED/line_x/

mkdir excluded
mv lespru.* excluded/
mv eleved.* excluded/
ogrmerge.py -field_strategy FirstLayer -single -o lines_for_split_no_lespru_eleved.shp *.shp
mv lines_for_split_no_lespru_eleved.* /data/patracdata/kraje/zl/vektor/ZABAGED/line_x/
