### 🚦 Vorgehensplan für **Schritt 3 – Daten‑Import & ‑Bereinigung**

**Ausgangslage**

- Das relationale Schema ist bereits über `create_table.sql` in MySQL angelegt.  
- Rohdaten liegen im `data/`‑Ordner als einzelne CSV‑/JSON‑Dateien (z. B. `01_fahrzeug.csv`, `unfall.json`) vor citeturn4file0.  
- Laut `TODO.md` müssen **alle** Imports in Transaktionen laufen und es kann eine Datenbereinigung nötig sein citeturn4file2.  

---

#### 1 | Vorbereitung

1. **Quell­dateien inventarisieren**  
   - Liste aller CSV/JSON/XLSX‑Dateien anlegen (Dateiname, Inhalt, vermutete Zieltabelle).  
2. **Mapping‑Tabelle erstellen**  
   - Spalte‑zu‑Spalte‑Zuordnung zwischen Quell­datei und MySQL‑Tabelle inklusive Datentyp‑Umwandlungen (Datum → `DATE`, Dezimaltrennzeichen → `DECIMAL(…)`, Boolesche Werte u. s. w.).  
3. **Import‑Reihenfolge festlegen**  
   - Entitäten ohne FKs zuerst → danach abhängige Tabellen.  
   - Typische Reihenfolge im Telematik‑Modell:  
     `fahrzeug` → `fahrer` → `geraet` → `geraet_installation` → `fahrt` → `messwert` → `wartung` etc.  

## 📌 Mapping‑Tabelle (CSV ⇢ MySQL)

| Reihenfolge | CSV‑Datei | MySQL‑Tabelle |
|-----------|------------------------|----------------------|
| 1 | 01_fahrzeug.csv | fahrzeug |
| 2 | 02_fahrer.csv | fahrer |
| 3 | 03_fahrer_fahrzeug.csv | fahrer_fahrzeug |
| 4 | 04_geraet.csv | geraet |
| 5 | 05_fahrt.csv | fahrt |
| 6 | 06_fahrt_fahrer.csv | fahrt_fahrer |
| 7 | 07_fahrzeugparameter.csv | fahrzeugparameter |
| 8 | 08_beschleunigung.csv | beschleunigung |
| 9 | 09_diagnose.csv | diagnose |
| 10 | 10_wartung.csv | wartung |
| 11 | 11_geraet_installation.csv | geraet_installation |

*(Die Reihenfolge orientiert sich an der FK‑Abhängigkeit und eignet sich für den Import‑Workflow.)*

### 📥 Import‑Reihenfolge (CSV → MySQL)

1. **01_fahrzeug.csv** → `fahrzeug`  
2. **02_fahrer.csv** → `fahrer`  
3. **03_fahrer_fahrzeug.csv** → `fahrer_fahrzeug`  
4. **04_geraet.csv** → `geraet`  
5. **05_fahrt.csv** → `fahrt`  
6. **06_fahrt_fahrer.csv** → `fahrt_fahrer`  
7. **07_fahrzeugparameter.csv** → `fahrzeugparameter`  
8. **08_beschleunigung.csv** → `beschleunigung`  
9. **09_diagnose.csv** → `diagnose`  
10. **10_wartung.csv** → `wartung`  
11. **11_geraet_installation.csv** → `geraet_installation`


---

#### 2 | Staging & Bereinigung

| Schritt | Warum? | Wie? |
|---------|--------|------|
| **Staging‑Tabellen** | Rohdaten unverändert einspielen, spätere Re‑Imports möglich | 1‑zu‑1 Kopie der Zieltabelle ohne FKs/PKs (`*_stg`). |
| **Constraints deaktivieren** | Import beschleunigen | `SET FOREIGN_KEY_CHECKS=0;` |
| **Datenbereinigung** | Dubletten, Null‑Werte, Formate | SQL‑`UPDATE`/`DELETE`, z. B. vereinheitlichte Kennzeichen, Trim/Upper, range‑Checks für Messwerte |
| **Validierung** | Qualität sicherstellen | SQL‑Assertions/SELECT‑Checks, z. B. „keine Fahrten ohne Fahrer“ |

---

#### 3 | Import‑Skript‐Skeleton (MySQL)

```sql
-- file: 03_import_data.sql
START TRANSACTION;

-- 1. Fahrzeug
LOAD DATA LOCAL INFILE 'data/01_fahrzeug.csv'
INTO TABLE fahrzeug_stg
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
IGNORE 1 ROWS
(id, kennzeichen, hersteller, baujahr);

-- Bereinigung Beispiel
UPDATE fahrzeug_stg
SET  kennzeichen = UPPER(TRIM(kennzeichen));

-- Übertrag in Zieltabelle
INSERT INTO fahrzeug(id, kennzeichen, hersteller, baujahr)
SELECT DISTINCT id, kennzeichen, hersteller, baujahr
FROM fahrzeug_stg
ON DUPLICATE KEY UPDATE
  kennzeichen = VALUES(kennzeichen),
  hersteller  = VALUES(hersteller),
  baujahr     = VALUES(baujahr);

-- 2. Weitere Tabellen analoge Blöcke …
-- …

COMMIT;
```

**Fehlerbehandlung**  
- Innerhalb jedes Blocks `DECLARE EXIT HANDLER FOR SQLEXCEPTION` → `ROLLBACK;`.  
- Skript abbrechen, Protokoll in eigener `import_log`‑Tabelle speichern (Datei, Zeile, Fehler).

---

#### 4 | Werkzeuge & Best Practices

| Tool | Zweck |
|------|-------|
| `LOAD DATA INFILE` oder `mysqlsh \importTable` | Schnellster Bulk‑Import für CSV |
| `jq` / `mysqlsh util.importJSON` | JSON → Tabelle |
| Transaktionsgröße | Bei Millionen Zeilen ggf. **Batching** (`COMMIT` nach 50 k) |
| Index‑Handling | Sekundär­indizes erst **nach** dem Import anlegen |
| Zeit‑Stempel | Spalten `created_at`, `import_batch_id` für Nachvollziehbarkeit |

---

#### 5 | Integritäts‑ und Plausi‑Checks

- **Row‑Counts**: Staging‑Zeilen = Ziel‑Zeilen (erwartete Items)  
- **FK‑Beziehungen**: `SELECT … LEFT JOIN … WHERE child.fk IS NULL` → 0 Ergebnisse.  
- **Domänenprüfungen**: z. B. Geschwindigkeit 0–300 km/h, Temperatur –40 – +150 °C.  

---

#### 6 | Dokumentation

1. **README Abschnitt „Import“**:  
   - benötigte MySQL‑Option (`local_infile=1`)  
   - Aufrufbeispiel: `mysql < 03_import_data.sql`  
2. **Mapping‑Tabelle & Bereinigungsregeln** als Markdown (`docs/import_mapping.md`).  
3. **Import‑Log**: Jeder Lauf erzeugt Eintrag in `import_log` (Datei, Zeilen, Dauer, Erfolg).

---

#### 7 | Nächste Schritte nach erfolgreichem Import

- Trigger & Stored Procedures (Changelog‑Trigger, „Neue Fahrt“-SP).  
- Mongo‑Konvertierung (Teil 2).  
- Reports 1‑3 als vorbereitete Views oder gespeicherte Statements.

---

**Kurz gesagt**:  
1. **Staging‑Tabellen nutzen**, 2. **Rohdaten laden**, 3. **in einer einzigen Transaktion bereinigen & überführen**, 4. **validieren** – alles sauber skriptgesteuert und versioniert. Damit ist der Datenimport reproduzierbar, fehlertolerant und erfüllt die Anforderungen aus der `TODO.md`.