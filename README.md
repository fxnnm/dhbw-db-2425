## Abschnitt: Daten-Import

Dieser Abschnitt beschreibt, wie der Bulk-Import der Rohdaten in MySQL durchgeführt wird.

### Voraussetzungen

- **MySQL-Option**: Aktivieren von `local_infile` in der Client-Verbindung:
  ```bash
  mysql --local_infile=1 -u <user> -p <database>
  ```
- **Staging-Tabellen**: Für jede Zieltabelle existiert eine entsprechende Staging-Tabelle (`<tabelle>_stg`), ohne Primary/Foreign Keys. Beispiel:
  ```sql
  CREATE TABLE IF NOT EXISTS fahrzeug_stg LIKE fahrzeug;
  ALTER TABLE fahrzeug_stg DROP PRIMARY KEY;
  ```
- **Mapping & Bereinigungsregeln**: Details zur Spaltenzuordnung und Datenbereinigung in `docs/import_mapping.md`.

### Import-Skript aufrufen

1. Wechsel in das Projektverzeichnis, das das Skript enthält:
   ```bash
   cd path/to/project
   ```
2. Führe das Import-Skript aus:
   ```bash
   mysql --local_infile=1 -u <user> -p <database> < 03_import_data.sql
   ```
3. Die Prozedur `import_data()` lädt alle CSV-Dateien aus dem `data/`-Verzeichnis, bereinigt sie, überträgt die Daten in die Zieltabellen und führt abschließend Integritäts- und Plausibilitätsprüfungen aus.

### Logging & Fehlerbehandlung

- **Import-Log**: Jeder Schritt schreibt ein Ergebnis (`OK`/`ERROR`) in die Tabelle `import_log`.
- Bei einem SQL-Fehler wird die gesamte Transaktion zurückgesetzt und der Fehler in `import_log` protokolliert.

---

### Nächste Schritte

- **Stored Procedures**: Nach erfolgreichem Import können Trigger oder weitere Prozeduren (z. B. Changelog-Trigger) aktiviert werden.
- **Daten-Qualität**: Zusätzliche Plausibilitätsprüfungen (z. B. Sensorwerte, Datumslogik) in `03_import_data.sql` ergänzen.

