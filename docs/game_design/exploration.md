# Erkundung: Distrikte & Gebäude-Innenräume

Umsetzung: #182. Verwandt: #18 (Sprite-Tiles), #13 (Asset-Management), #128 (OpenStreetMap), #166 (vorgebaute Maps). Werte sind Startwerte.

---

## 1. Problem

Die Stadt zu erkunden macht wenig Spaß: Es fehlt Grafik, und alle Häuser sind gleich. Es gibt keinen Grund, abseits der Missionsziele durch die Stadt zu laufen.

## 2. Ist-Stand

- Die Stadt wird prozedural aus einem Seed erzeugt (Distrikte, Straßen, Grundstücke, Spezialgebäude über `SpecialBuildingRegistry`). Der Seed wird seit #177 auch wirklich verwendet.
- Gebäude haben Typ, Bewohner (`BuildingModel.residents`), Glaube und Interaktionszähler; Aktionen laufen über ein Menü (`BuildingInteriorOverlay`), es gibt **keinen begehbaren Innenraum**.

## 3. Distrikt-Identität

- Jeder Distrikttyp hat eine eigene **Farbpalette, Gebäude-Mischung, Bodentextur/Sprite-Set** und Straßenschilder; ein Blick genügt zur Orientierung.
- **Wahrzeichen** je Stadtteil (Kirche, Stadion, Rathaus …) sind aus der Ferne erkennbar (Markierung im Kompass/Minimap #146).
- Häuser derselben Kategorie unterscheiden sich in Größe, Farbe, Details (seed-basiert), damit "alle Häuser gleich" entfällt.
- Grafik-Pipeline: #18/#13.

## 4. Prozedurale Innenräume

Beim Betreten (Klingeln/Eintreten) wird ein **Innenraum seed-basiert** erzeugt (deterministisch: gleicher Seed + `buildingId` → gleicher Raum) und **erst dann** — nie für die ganze Stadt.

- **Layout:** Anzahl Räume nach Haustyp/Größe; Einfamilienhaus wenige Räume, Apartment mehrere Wohnungen.
- **Bewohner:** Die Bewohner des `BuildingModel` stehen in den Räumen; Bedürfnis-Hinweise (#171) sind dort ablesbar.
- **Fundstücke:** Objekte mit kleiner Belohnung (Insight, Material, Hinweis auf ein Gebetsanliegen), **Obergrenze je Gebäude**, damit es kein Grind wird. Bereits Gefundenes wird im Gebäudezustand gespeichert.
- **Verknüpfung:** Räume können die Aktionen aus `building_actions.md` kontextuell anbieten (z. B. Bibellesen am Küchentisch).
- **Kirchen/Öffentliche Gebäude:** eigene, feste Raumvorlagen.

## 5. Reihenfolge

1. Distrikt-Identität mit Platzhalter-Sprites (billig, sofort sichtbar).
2. Innenraum für **einen** Gebäudetyp (Einfamilienhaus) als Vertical Slice.
3. Weitere Typen, Fundstücke, Hinweise; später OSM/vorgebaute Städte (#128, #166).

## 6. Akzeptanz

Siehe #182: ≥ 3 unterscheidbare Distrikttypen; ≥ 1 begehbarer, seed-basierter Innenraum; Belohnung gedeckelt; Determinismus; Erzeugung erst beim Betreten.
