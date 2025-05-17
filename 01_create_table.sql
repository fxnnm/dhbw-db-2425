-- Disable foreign key checks so tables can be dropped in any order
SET foreign_key_checks = 0;

-- Drop existing tables (in dependency order based on foreign keys)
DROP TABLE IF EXISTS geraet_installation;
DROP TABLE IF EXISTS diagnose;
DROP TABLE IF EXISTS beschleunigung;
DROP TABLE IF EXISTS fahrzeugparameter;
DROP TABLE IF EXISTS fahrt_fahrer;
DROP TABLE IF EXISTS fahrt;
DROP TABLE IF EXISTS wartung;
DROP TABLE IF EXISTS fahrer_fahrzeug;
DROP TABLE IF EXISTS geraet;
DROP TABLE IF EXISTS fahrer;
DROP TABLE IF EXISTS fahrzeug;
DROP TABLE IF EXISTS konvertierung_log;
DROP TABLE IF EXISTS changelog;

-- Drop staging tables
DROP TABLE IF EXISTS geraet_installation_stg;
DROP TABLE IF EXISTS diagnose_stg;
DROP TABLE IF EXISTS beschleunigung_stg;
DROP TABLE IF EXISTS fahrzeugparameter_stg;
DROP TABLE IF EXISTS fahrt_fahrer_stg;
DROP TABLE IF EXISTS fahrt_stg;
DROP TABLE IF EXISTS wartung_stg;
DROP TABLE IF EXISTS fahrer_fahrzeug_stg;
DROP TABLE IF EXISTS geraet_stg;
DROP TABLE IF EXISTS fahrer_stg;
DROP TABLE IF EXISTS fahrzeug_stg;
DROP TABLE IF EXISTS import_log;

-- Re-enable foreign key checks
SET foreign_key_checks = 1;

-- Create staging tables (no constraints for easier import)

-- Staging table 1: fahrzeug_stg
CREATE TABLE fahrzeug_stg (
    id INT,
    hersteller VARCHAR(100),
    modell VARCHAR(100),
    baujahr INT
) ENGINE=InnoDB;

-- Staging table 2: fahrer_stg
CREATE TABLE fahrer_stg (
    id INT,
    vorname VARCHAR(50),
    nachname VARCHAR(50),
    geburtsdatum VARCHAR(20), -- as string for conversion
    kontakt_nr VARCHAR(20),
    email VARCHAR(100)
) ENGINE=InnoDB;

-- Staging table 3: fahrer_fahrzeug_stg
CREATE TABLE fahrer_fahrzeug_stg (
    fahrerid INT,
    fahrzeugid INT,
    gueltig_ab VARCHAR(20), -- as string for conversion
    gueltig_bis VARCHAR(20) -- as string for conversion
) ENGINE=InnoDB;

-- Staging table 4: geraet_stg
CREATE TABLE geraet_stg (
    id INT,
    fahrzeugid INT,
    geraet_typ VARCHAR(50),
    hersteller VARCHAR(100),
    modell VARCHAR(100)
) ENGINE=InnoDB;

-- Staging table 5: fahrt_stg
CREATE TABLE fahrt_stg (
    id INT,
    fahrzeugid INT,
    geraetid INT,
    startzeitpunkt VARCHAR(30),
    endzeitpunkt VARCHAR(30),
    route TEXT
) ENGINE=InnoDB;

-- Staging table 6: fahrt_fahrer_stg
CREATE TABLE fahrt_fahrer_stg (
    fahrtid INT,
    fahrerid INT
) ENGINE=InnoDB;

-- Staging table 7: fahrzeugparameter_stg
CREATE TABLE fahrzeugparameter_stg (
    id INT,
    fahrtid INT,
    zeitstempel VARCHAR(30),
    geschwindigkeit FLOAT,
    motortemperatur FLOAT,
    luftmassenstrom FLOAT,
    batterie FLOAT
) ENGINE=InnoDB;

-- Staging table 8: beschleunigung_stg
CREATE TABLE beschleunigung_stg (
    id INT,
    fahrtid INT,
    zeitstempel VARCHAR(30),
    x_achse FLOAT,
    y_achse FLOAT,
    z_achse FLOAT
) ENGINE=InnoDB;

-- Staging table 9: diagnose_stg
CREATE TABLE diagnose_stg (
    id INT,
    fahrtid INT,
    zeitstempel VARCHAR(30),
    fehlercode VARCHAR(50),
    beschreibung TEXT
) ENGINE=InnoDB;

-- Staging table 10: wartung_stg
CREATE TABLE wartung_stg (
    id INT,
    fahrzeugid INT,
    datum VARCHAR(20),
    beschreibung TEXT
) ENGINE=InnoDB;

-- Staging table 11: geraet_installation_stg
CREATE TABLE geraet_installation_stg (
    id INT,
    geraetid INT,
    fahrzeugid INT,
    einbau_datum VARCHAR(20), -- as string for conversion
    ausbau_datum VARCHAR(20) -- as string for conversion
) ENGINE=InnoDB;

-- Import log table (to track import process)
CREATE TABLE import_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    run_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    file_name VARCHAR(255) NOT NULL,
    row_num INT NULL,
    error_message TEXT NULL,
    status ENUM('OK','ERROR') NOT NULL DEFAULT 'OK'
) ENGINE=InnoDB;

-- Create actual data tables

-- Table 1: fahrzeug (01_fahrzeug.csv)
CREATE TABLE fahrzeug (
    id INT AUTO_INCREMENT PRIMARY KEY,
    hersteller VARCHAR(100) NOT NULL,
    modell VARCHAR(100) NOT NULL,
    baujahr INT NOT NULL
) ENGINE=InnoDB;

-- Table 2: fahrer (02_fahrer.csv)
CREATE TABLE fahrer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vorname VARCHAR(50) NOT NULL,
    nachname VARCHAR(50) NOT NULL,
    geburtsdatum DATE,
    kontakt_nr VARCHAR(20),
    email VARCHAR(100)
) ENGINE=InnoDB;

-- Table 3: fahrer_fahrzeug (03_fahrer_fahrzeug.csv)
CREATE TABLE fahrer_fahrzeug (
    fahrerid INT NOT NULL,
    fahrzeugid INT NOT NULL,
    gueltig_ab DATE NOT NULL,
    gueltig_bis DATE,
    PRIMARY KEY (fahrerid, fahrzeugid, gueltig_ab),
    CONSTRAINT fk_ff_fahrer FOREIGN KEY (fahrerid) REFERENCES fahrer(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ff_fahrzeug FOREIGN KEY (fahrzeugid) REFERENCES fahrzeug(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Table 4: geraet (04_geraet.csv)
CREATE TABLE geraet (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fahrzeugid INT NOT NULL,
    geraet_typ VARCHAR(50) NOT NULL,
    hersteller VARCHAR(100),
    modell VARCHAR(100),
    CONSTRAINT fk_geraet_fahrzeug FOREIGN KEY (fahrzeugid) REFERENCES fahrzeug(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Table 5: fahrt (05_fahrt.csv)
CREATE TABLE fahrt (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fahrzeugid INT NOT NULL,
    geraetid INT NOT NULL,
    startzeitpunkt DATETIME NOT NULL,
    endzeitpunkt DATETIME,
    route TEXT,
    CONSTRAINT fk_fahrt_fahrzeug FOREIGN KEY (fahrzeugid) REFERENCES fahrzeug(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_fahrt_geraet FOREIGN KEY (geraetid) REFERENCES geraet(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Table 6: fahrt_fahrer (06_fahrt_fahrer.csv)
CREATE TABLE fahrt_fahrer (
    fahrtid INT NOT NULL,
    fahrerid INT NOT NULL,
    PRIMARY KEY (fahrtid, fahrerid),
    CONSTRAINT fk_ffahrt_fahrt FOREIGN KEY (fahrtid) REFERENCES fahrt(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ffahrt_fahrer FOREIGN KEY (fahrerid) REFERENCES fahrer(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Table 7: fahrzeugparameter (07_fahrzeugparameter.csv)
CREATE TABLE fahrzeugparameter (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fahrtid INT NOT NULL,
    zeitstempel DATETIME NOT NULL,
    geschwindigkeit FLOAT,
    motortemperatur FLOAT,
    luftmassenstrom FLOAT,
    batterie FLOAT,
    CONSTRAINT fk_fahrzeugparameter_fahrt FOREIGN KEY (fahrtid) REFERENCES fahrt(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Table 8: beschleunigung (08_beschleunigung.csv)
CREATE TABLE beschleunigung (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fahrtid INT NOT NULL,
    zeitstempel DATETIME NOT NULL,
    x_achse FLOAT,
    y_achse FLOAT,
    z_achse FLOAT,
    CONSTRAINT fk_beschleunigung_fahrt FOREIGN KEY (fahrtid) REFERENCES fahrt(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Table 9: diagnose (09_diagnose.csv)
CREATE TABLE diagnose (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fahrtid INT NOT NULL,
    zeitstempel DATETIME NOT NULL,
    fehlercode VARCHAR(50),
    beschreibung TEXT,
    CONSTRAINT fk_diagnose_fahrt FOREIGN KEY (fahrtid) REFERENCES fahrt(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Table 10: wartung (10_wartung.csv)
CREATE TABLE wartung (
    id INT AUTO_INCREMENT PRIMARY KEY,
    fahrzeugid INT NOT NULL,
    datum DATE NOT NULL,
    beschreibung TEXT,
    CONSTRAINT fk_wartung_fahrzeug FOREIGN KEY (fahrzeugid) REFERENCES fahrzeug(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Table 11: geraet_installation (11_geraet_installation.csv)
CREATE TABLE geraet_installation (
    id INT AUTO_INCREMENT PRIMARY KEY,
    geraetid INT NOT NULL,
    fahrzeugid INT NOT NULL,
    einbau_datum DATE NOT NULL,
    ausbau_datum DATE,
    CONSTRAINT fk_gi_geraet FOREIGN KEY (geraetid) REFERENCES geraet(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_gi_fahrzeug FOREIGN KEY (fahrzeugid) REFERENCES fahrzeug(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Table 12: konvertierung_log (used by convert.py)
CREATE TABLE konvertierung_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tabelle VARCHAR(255),
    anzahl INT,
    zeitstempel TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Table 13: changelog (for tracking updates to other tables)
CREATE TABLE changelog (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tabelle VARCHAR(255) NOT NULL,
    aktion VARCHAR(10) NOT NULL, -- INSERT, UPDATE, DELETE
    zeitstempel TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    benutzer VARCHAR(255),
    alte_werte TEXT,
    neue_werte TEXT
) ENGINE=InnoDB;