# Rathaus

`assets/images/city_hall_112px.png`: das alte Rathaus mit Uhrturm, Treppengiebeln, Kupferhaube und Arkaden. 112 × 112 px, also 7 × 7 Felder zu 16 px wie die Kenney-Kacheln. Es liegt über dem ganzen Grundstück (die Straße nimmt die erste Zeile und Spalte), die Tür sitzt in der Mittelspalte der untersten Reihe, wo `KenneyCityRenderer.isDoor` sie erwartet.

Eigene Arbeit (Projektlizenz). `draw_city_hall.py` erzeugt das Bild neu:

    python3 draw_city_hall.py city_hall_112px.png city_hall_preview_6x.png
