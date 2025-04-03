### Tabelle `geraet`

- `id`: Primärschlüssel
- `fahrzeugid`: Das Fahrzeug, dem das Gerät ursprünglich zugewiesen war. 
  Dies ist nicht die tatsächliche Nutzung: Die aktuelle und historische Nutzung ist in `geraet_installation` gespeichert.
  
   ...  


### Tabelle `geraet_installation`

Die zentrale Beziehungstabelle, die dokumentiert, wann welches Gerät in welchem Fahrzeug eingebaut war oder ist.

 

✅ Dadurch ergibt sich **keine Änderung am Datenmodell oder an den Daten** Die ursprüngliche Zuweisung bleibt erhalten und `geraet_installation` bildet den realen Nutzungsverlauf ab.
