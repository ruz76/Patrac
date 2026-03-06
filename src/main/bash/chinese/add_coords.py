# Nastavení vrstev – uprav názvy podle svého projektu
points_layer = QgsProject.instance().mapLayersByName("ways_nodes")[0]
lines_layer = QgsProject.instance().mapLayersByName("ways")[0]

# Vytvoření slovníku: id_bodu -> PointXY
point_dict = {}
for f in points_layer.getFeatures():
    pt = f.geometry().asPoint()
    pid = f["source"]
    point_dict[pid] = pt

# Začít editaci
lines_layer.startEditing()

# Projdeme jen vybrané linie
for ln in lines_layer.selectedFeatures():
    src_id = ln["source"]
    tgt_id = ln["target"]

    # Najdi odpovídající body podle slovníku
    src_pt = point_dict.get(src_id, None)
    tgt_pt = point_dict.get(tgt_id, None)

    # Pokud body existují, naplň souřadnice
    attrs = {}

    if src_pt:
        attrs[lines_layer.fields().indexOf("x1")] = src_pt.x()
        attrs[lines_layer.fields().indexOf("y1")] = src_pt.y()

    if tgt_pt:
        attrs[lines_layer.fields().indexOf("x2")] = tgt_pt.x()
        attrs[lines_layer.fields().indexOf("y2")] = tgt_pt.y()

    # Aktualizace atributů
    if attrs:
        lines_layer.dataProvider().changeAttributeValues({ln.id(): attrs})

# Uložit změny
lines_layer.commitChanges()

print("Hotovo – souřadnice doplněny.")
