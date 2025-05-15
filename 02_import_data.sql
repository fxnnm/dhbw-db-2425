-- file: 03_import_data.sql
-- Skript für Daten-Import, Bereinigung sowie Integritäts- und Plausibilitätsprüfungen in MySQL

-- 1. Import-Log-Tabelle (pro Lauf Einträge zu Fehlern/Erfolgen)
CREATE TABLE IF NOT EXISTS import_log (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  run_timestamp    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  file_name        VARCHAR(255)  NOT NULL,
  row_number       INT           NULL,
  error_message    TEXT          NULL,
  status           ENUM('OK','ERROR') NOT NULL DEFAULT 'OK'
) ENGINE=InnoDB;

-- 2. Stored Procedure für den Import und Prüfungen
DELIMITER $$
DROP PROCEDURE IF EXISTS import_data$$
CREATE PROCEDURE import_data()
BEGIN
  DECLARE v_err TEXT;

  -- Fehler-Handler: Rollback, Log-Eintrag und Fehlermeldung weitergeben
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    GET DIAGNOSTICS CONDITION 1 v_err = MESSAGE_TEXT;
    ROLLBACK;
    INSERT INTO import_log(file_name, row_number, error_message, status)
      VALUES('unknown', NULL, v_err, 'ERROR');
    RESIGNAL;
  END;

  -- FK-Prüfungen temporär ausschalten für Performance
  SET FOREIGN_KEY_CHECKS = 0;
  START TRANSACTION;

  -- ****************************************************************
  -- Bulk-Import & Bereinigung für jede Tabelle
  -- ****************************************************************

  -- 1. Fahrzeug
  -- Lade Rohdaten unverändert in Staging
  LOAD DATA LOCAL INFILE 'data/01_fahrzeug.csv'
    INTO TABLE fahrzeug_stg
    FIELDS TERMINATED BY ';' ENCLOSED BY '"' IGNORE 1 ROWS
    (id, kennzeichen, hersteller, baujahr);
  -- Datenbereinigung: Kennzeichen einheitlich (Großbuchstaben, keine Leerzeichen)
  UPDATE fahrzeug_stg
    SET kennzeichen = UPPER(TRIM(kennzeichen));
  -- Übertragen in Zieltabelle mit Upsert
  INSERT INTO fahrzeug(id, kennzeichen, hersteller, baujahr)
    SELECT DISTINCT id, kennzeichen, hersteller, baujahr FROM fahrzeug_stg
    ON DUPLICATE KEY UPDATE
      kennzeichen = VALUES(kennzeichen),
      hersteller  = VALUES(hersteller),
      baujahr     = VALUES(baujahr);
  INSERT INTO import_log(file_name, status) VALUES('01_fahrzeug.csv','OK');

  -- 2. Fahrer (analog zu Fahrzeug)
  LOAD DATA LOCAL INFILE 'data/02_fahrer.csv'
    INTO TABLE fahrer_stg
    FIELDS TERMINATED BY ';' ENCLOSED BY '"' IGNORE 1 ROWS
    (id, vorname, nachname, geburtsdatum);
  UPDATE fahrer_stg
    SET vorname = TRIM(vorname),
        nachname = TRIM(nachname),
        geburtsdatum = STR_TO_DATE(geburtsdatum, '%Y-%m-%d');
  INSERT INTO fahrer(id, vorname, nachname, geburtsdatum)
    SELECT DISTINCT id, vorname, nachname, geburtsdatum FROM fahrer_stg
    ON DUPLICATE KEY UPDATE
      vorname      = VALUES(vorname),
      nachname     = VALUES(nachname),
      geburtsdatum = VALUES(geburtsdatum);
  INSERT INTO import_log(file_name, status) VALUES('02_fahrer.csv','OK');

  -- 3. Fahrer-Fahrzeug Zuordnung
  LOAD DATA LOCAL INFILE 'data/03_fahrer_fahrzeug.csv'
    INTO TABLE fahrer_fahrzeug_stg
    FIELDS TERMINATED BY ';' ENCLOSED BY '"' IGNORE 1 ROWS
    (fahrer_id, fahrzeug_id);
  INSERT INTO fahrer_fahrzeug(fahrer_id, fahrzeug_id)
    SELECT DISTINCT fahrer_id, fahrzeug_id FROM fahrer_fahrzeug_stg
    ON DUPLICATE KEY UPDATE fahrer_id = VALUES(fahrer_id);
  INSERT INTO import_log(file_name, status) VALUES('03_fahrer_fahrzeug.csv','OK');

  -- 4. Gerät
  LOAD DATA LOCAL INFILE 'data/04_geraet.csv'
    INTO TABLE geraet_stg
    FIELDS TERMINATED BY ';' ENCLOSED BY '"' IGNORE 1 ROWS
    (id, typ, firmware_version);
  INSERT INTO geraet(id, typ, firmware_version)
    SELECT DISTINCT id, typ, firmware_version FROM geraet_stg
    ON DUPLICATE KEY UPDATE
      typ              = VALUES(typ),
      firmware_version = VALUES(firmware_version);
  INSERT INTO import_log(file_name, status) VALUES('04_geraet.csv','OK');

  -- 5. Fahrt
  LOAD DATA LOCAL INFILE 'data/05_fahrt.csv'
    INTO TABLE fahrt_stg
    FIELDS TERMINATED BY ';' ENCLOSED BY '"' IGNORE 1 ROWS
    (id, fahrzeug_id, startzeit, endzeit, distanz);
  UPDATE fahrt_stg
    SET startzeit = STR_TO_DATE(startzeit, '%Y-%m-%d %H:%i:%s'),
        endzeit   = STR_TO_DATE(endzeit,   '%Y-%m-%d %H:%i:%s');
  INSERT INTO fahrt(id, fahrzeug_id, startzeit, endzeit, distanz)
    SELECT DISTINCT id, fahrzeug_id, startzeit, endzeit, distanz FROM fahrt_stg
    ON DUPLICATE KEY UPDATE
      startzeit = VALUES(startzeit),
      endzeit   = VALUES(endzeit),
      distanz   = VALUES(distanz);
  INSERT INTO import_log(file_name, status) VALUES('05_fahrt.csv','OK');

  -- 6. Fahrt-Fahrer Zuordnung
  LOAD DATA LOCAL INFILE 'data/06_fahrt_fahrer.csv'
    INTO TABLE fahrt_fahrer_stg
    FIELDS TERMINATED BY ';' ENCLOSED BY '"' IGNORE 1 ROWS
    (fahrt_id, fahrer_id);
  INSERT INTO fahrt_fahrer(fahrt_id, fahrer_id)
    SELECT DISTINCT fahrt_id, fahrer_id FROM fahrt_fahrer_stg
    ON DUPLICATE KEY UPDATE fahrt_id = VALUES(fahrt_id);
  INSERT INTO import_log(file_name, status) VALUES('06_fahrt_fahrer.csv','OK');

  -- 7. Fahrzeugparameter
  LOAD DATA LOCAL INFILE 'data/07_fahrzeugparameter.csv'
    INTO TABLE fahrzeugparameter_stg
    FIELDS TERMINATED BY ';' ENCLOSED BY '"' IGNORE 1 ROWS
    (fahrzeug_id, parameter_name, parameter_wert);
  INSERT INTO fahrzeugparameter(fahrzeug_id, parameter_name, parameter_wert)
    SELECT DISTINCT fahrzeug_id, parameter_name, parameter_wert FROM fahrzeugparameter_stg
    ON DUPLICATE KEY UPDATE parameter_wert = VALUES(parameter_wert);
  INSERT INTO import_log(file_name, status) VALUES('07_fahrzeugparameter.csv','OK');

  -- 8. Beschleunigung
  LOAD DATA LOCAL INFILE 'data/08_beschleunigung.csv'
    INTO TABLE beschleunigung_stg
    FIELDS TERMINATED BY ';' ENCLOSED BY '"' IGNORE 1 ROWS
    (id, fahrt_id, zeitstempel, wert);
  UPDATE beschleunigung_stg
    SET zeitstempel = STR_TO_DATE(zeitstempel, '%Y-%m-%d %H:%i:%s');
  INSERT INTO beschleunigung(id, fahrt_id, zeitstempel, wert)
    SELECT DISTINCT id, fahrt_id, zeitstempel, wert FROM beschleunigung_stg
    ON DUPLICATE KEY UPDATE wert = VALUES(wert);
  INSERT INTO import_log(file_name, status) VALUES('08_beschleunigung.csv','OK');

  -- 9. Diagnose
  LOAD DATA LOCAL INFILE 'data/09_diagnose.csv'
    INTO TABLE diagnose_stg
    FIELDS TERMINATED BY ';' ENCLOSED BY '"' IGNORE 1 ROWS
    (id, geraet_id, code, beschreibung);
  INSERT INTO diagnose(id, geraet_id, code, beschreibung)
    SELECT DISTINCT id, geraet_id, code, beschreibung FROM diagnose_stg
    ON DUPLICATE KEY UPDATE beschreibung = VALUES(beschreibung);
  INSERT INTO import_log(file_name, status) VALUES('09_diagnose.csv','OK');

  -- 10. Wartung
  LOAD DATA LOCAL INFILE 'data/10_wartung.csv'
    INTO TABLE wartung_stg
    FIELDS TERMINATED BY ';' ENCLOSED BY '"' IGNORE 1 ROWS
    (id, geraet_id, datum, typ);
  UPDATE wartung_stg
    SET datum = STR_TO_DATE(datum, '%Y-%m-%d');
  INSERT INTO wartung(id, geraet_id, datum, typ)
    SELECT DISTINCT id, geraet_id, datum, typ FROM wartung_stg
    ON DUPLICATE KEY UPDATE typ = VALUES(typ);
  INSERT INTO import_log(file_name, status) VALUES('10_wartung.csv','OK');

  -- 11. Gerät-Installation
  LOAD DATA LOCAL INFILE 'data/11_geraet_installation.csv'
    INTO TABLE geraet_installation_stg
    FIELDS TERMINATED BY ';' ENCLOSED BY '"' IGNORE 1 ROWS
    (id, geraet_id, fahrzeug_id, install_datum);
  UPDATE geraet_installation_stg
    SET install_datum = STR_TO_DATE(install_datum, '%Y-%m-%d');
  INSERT INTO geraet_installation(id, geraet_id, fahrzeug_id, install_datum)
    SELECT DISTINCT id, geraet_id, fahrzeug_id, install_datum FROM geraet_installation_stg
    ON DUPLICATE KEY UPDATE install_datum = VALUES(install_datum);
  INSERT INTO import_log(file_name, status) VALUES('11_geraet_installation.csv','OK');

  -- ****************************************************************
  -- 5. Integritäts- und Plausibilitätsprüfungen
  -- ****************************************************************

  -- 5.1. Zeilenanzahl prüfen: Staging vs. Ziel
  -- Beispiel für 'fahrzeug'
  SELECT COUNT(*) INTO @cnt_stg FROM fahrzeug_stg;
  SELECT COUNT(*) INTO @cnt_tgt FROM fahrzeug;
  IF @cnt_stg <> @cnt_tgt THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = CONCAT('Row count mismatch (fahrzeug): staging=', @cnt_stg, ', target=', @cnt_tgt);
  END IF;

  -- 5.2. Fremdschlüssel prüfen: keine Waisen
  -- Beispiel für fahrer_fahrzeug
  SELECT COUNT(*) INTO @orph_fg
    FROM fahrer_fahrzeug f
    LEFT JOIN fahrer r ON f.fahrer_id = r.id
    WHERE r.id IS NULL;
  IF @orph_fg > 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = CONCAT('Orphan FK in fahrer_fahrzeug: ', @orph_fg, ' rows');
  END IF;

  -- 5.3. Domänen-Prüfungen: Wertebereiche
  -- Beispiel für fahrt.distanz (0–10000 km)
  SELECT COUNT(*) INTO @inv_dist FROM fahrt WHERE distanz < 0 OR distanz > 10000;
  IF @inv_dist > 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = CONCAT('Invalid distanz in fahrt: ', @inv_dist, ' rows');
  END IF;

  -- 5.4. Optional: Weitere Prüfungen hier einfügen (Messwertbereiche, Datumslogik etc.)

  -- Commit und Constraints wieder aktivieren
  COMMIT;
  SET FOREIGN_KEY_CHECKS = 1;
END$$
DELIMITER ;

-- Aufruf der Import-Prozedur
CALL import_data();
