-- Skript für Daten-Import, Bereinigung sowie Integritäts- und Plausibilitätsprüfungen in MySQL

-- Temporarily disable foreign key checks for performance
SET FOREIGN_KEY_CHECKS = 0;
START TRANSACTION;

-- 1. Fahrzeug
LOAD DATA LOCAL INFILE 'data/01_fahrzeug.csv'
INTO TABLE fahrzeug_stg
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id, hersteller, modell, baujahr);
INSERT INTO fahrzeug (id, hersteller, modell, baujahr)
SELECT DISTINCT id, TRIM(hersteller), TRIM(modell), baujahr FROM fahrzeug_stg
ON DUPLICATE KEY UPDATE
hersteller = VALUES(hersteller),
modell = VALUES(modell),
baujahr = VALUES(baujahr);

-- 2. Fahrer
LOAD DATA LOCAL INFILE 'data/02_fahrer.csv'
INTO TABLE fahrer_stg
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id, vorname, nachname, geburtsdatum, kontakt_nr, email);
UPDATE fahrer_stg
SET geburtsdatum = STR_TO_DATE(geburtsdatum, '%Y-%m-%d')
WHERE geburtsdatum REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';
INSERT INTO fahrer (id, vorname, nachname, geburtsdatum, kontakt_nr, email)
SELECT DISTINCT id, TRIM(vorname), TRIM(nachname), geburtsdatum, TRIM(kontakt_nr), TRIM(email)
FROM fahrer_stg
WHERE geburtsdatum IS NOT NULL AND geburtsdatum REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';

-- 3. Fahrer-Fahrzeug Zuordnung
LOAD DATA LOCAL INFILE 'data/03_fahrer_fahrzeug.csv'
INTO TABLE fahrer_fahrzeug_stg
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(fahrerid, fahrzeugid, gueltig_ab, gueltig_bis);
UPDATE fahrer_fahrzeug_stg
SET gueltig_ab = STR_TO_DATE(gueltig_ab, '%Y-%m-%d'),
    gueltig_bis = CASE
        WHEN gueltig_bis IS NOT NULL AND gueltig_bis REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
        THEN STR_TO_DATE(gueltig_bis, '%Y-%m-%d')
        ELSE NULL
    END
WHERE gueltig_ab REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';
INSERT INTO fahrer_fahrzeug (fahrerid, fahrzeugid, gueltig_ab, gueltig_bis)
SELECT DISTINCT fahrerid, fahrzeugid, gueltig_ab, gueltig_bis FROM fahrer_fahrzeug_stg;

-- 4. Gerät
LOAD DATA LOCAL INFILE 'data/04_geraet.csv'
INTO TABLE geraet_stg
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id, fahrzeugid, geraet_typ, hersteller, modell);
INSERT INTO geraet (id, fahrzeugid, geraet_typ, hersteller, modell)
SELECT DISTINCT id, fahrzeugid, TRIM(geraet_typ), TRIM(hersteller), TRIM(modell) FROM geraet_stg;

-- 5. Fahrt
LOAD DATA LOCAL INFILE 'data/05_fahrt.csv'
INTO TABLE fahrt_stg
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id, fahrzeugid, geraetid, startzeitpunkt, endzeitpunkt, route);
UPDATE fahrt_stg
SET startzeitpunkt = STR_TO_DATE(startzeitpunkt, '%d.%m.%Y %H:%i'),
    endzeitpunkt = STR_TO_DATE(endzeitpunkt, '%d.%m.%Y %H:%i');
INSERT INTO fahrt (id, fahrzeugid, geraetid, startzeitpunkt, endzeitpunkt, route)
SELECT DISTINCT id, fahrzeugid, geraetid, startzeitpunkt, endzeitpunkt, TRIM(route)
FROM fahrt_stg
WHERE fahrzeugid IS NOT NULL;  -- Exclude rows with NULL 'fahrzeugid'

-- 6. Fahrt-Fahrer Zuordnung
LOAD DATA LOCAL INFILE 'data/06_fahrt_fahrer.csv'
INTO TABLE fahrt_fahrer_stg
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(fahrtid, fahrerid);
INSERT INTO fahrt_fahrer (fahrtid, fahrerid)
SELECT DISTINCT fahrtid, fahrerid FROM fahrt_fahrer_stg;

-- 7. Fahrzeugparameter
LOAD DATA LOCAL INFILE 'data/07_fahrzeugparameter.csv'
INTO TABLE fahrzeugparameter_stg
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id, fahrtid, zeitstempel, geschwindigkeit, motortemperatur, luftmassenstrom, batterie);
UPDATE fahrzeugparameter_stg
SET zeitstempel = STR_TO_DATE(REPLACE(zeitstempel, '"', ''), '%Y-%m-%d %H:%i:%s');
INSERT INTO fahrzeugparameter (id, fahrtid, zeitstempel, geschwindigkeit, motortemperatur, luftmassenstrom, batterie)
SELECT DISTINCT id, fahrtid, zeitstempel, geschwindigkeit, motortemperatur, luftmassenstrom, batterie FROM fahrzeugparameter_stg;

-- 8. Beschleunigung
LOAD DATA LOCAL INFILE 'data/08_beschleunigung.csv'
INTO TABLE beschleunigung_stg
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id, fahrtid, zeitstempel, x_achse, y_achse, z_achse);
UPDATE beschleunigung_stg
SET zeitstempel = STR_TO_DATE(REPLACE(zeitstempel, '"', ''), '%Y-%m-%d %H:%i:%s');
INSERT INTO beschleunigung (id, fahrtid, zeitstempel, x_achse, y_achse, z_achse)
SELECT DISTINCT id, fahrtid, zeitstempel, x_achse, y_achse, z_achse FROM beschleunigung_stg;

-- 9. Diagnose
LOAD DATA LOCAL INFILE 'data/09_diagnose.csv'
INTO TABLE diagnose_stg
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id, fahrtid, zeitstempel, fehlercode, beschreibung);
UPDATE diagnose_stg
SET zeitstempel = STR_TO_DATE(REPLACE(zeitstempel, '"', ''), '%Y-%m-%d %H:%i:%s');
INSERT INTO diagnose (id, fahrtid, zeitstempel, fehlercode, beschreibung)
SELECT DISTINCT id, fahrtid, zeitstempel, TRIM(fehlercode), TRIM(beschreibung) FROM diagnose_stg;

-- 10. Wartung
LOAD DATA LOCAL INFILE 'data/10_wartung.csv'
INTO TABLE wartung_stg
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id, fahrzeugid, datum, beschreibung);
UPDATE wartung_stg
SET datum = STR_TO_DATE(DATE(REPLACE(datum, '"', '')), '%Y-%m-%d');
INSERT INTO wartung (id, fahrzeugid, datum, beschreibung)
SELECT DISTINCT id, fahrzeugid, datum, TRIM(beschreibung) FROM wartung_stg;

-- 11. Gerät-Installation
LOAD DATA LOCAL INFILE 'data/11_geraet_installation.csv'
INTO TABLE geraet_installation_stg
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(id, geraetid, fahrzeugid, einbau_datum, ausbau_datum);

UPDATE geraet_installation_stg
SET 
  einbau_datum = CASE 
                   WHEN LOWER(TRIM(einbau_datum)) IN ('null', '') THEN NULL
                   ELSE STR_TO_DATE(TRIM(einbau_datum), '%Y-%m-%d')
                 END,
  ausbau_datum = CASE 
                   WHEN LOWER(TRIM(ausbau_datum)) IN ('null', '') THEN NULL
                   ELSE STR_TO_DATE(TRIM(ausbau_datum), '%Y-%m-%d')
                 END;

INSERT INTO geraet_installation (id, geraetid, fahrzeugid, einbau_datum, ausbau_datum)
SELECT DISTINCT id, geraetid, fahrzeugid, einbau_datum, ausbau_datum
FROM geraet_installation_stg;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;
COMMIT;
