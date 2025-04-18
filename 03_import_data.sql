/* 0.1  Import‑Log anlegen (falls noch nicht vorhanden) */
CREATE TABLE IF NOT EXISTS import_log (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    datei       VARCHAR(64),
    zeilen      INT,
    start_ts    DATETIME,
    ende_ts     DATETIME,
    status      ENUM('OK','FEHLER') NOT NULL,
    meldung     TEXT
);

------------------ Staging Tabellen ------------------

/* Fahrzeug */
DROP TABLE IF EXISTS fahrzeug_stg;
CREATE TABLE fahrzeug_stg LIKE fahrzeug;
ALTER TABLE fahrzeug_stg
    DROP PRIMARY KEY,                     -- FK‑frei
    AUTO_INCREMENT = 1;                   -- falls PK autoincrement

/* Fahrer */
DROP TABLE IF EXISTS fahrer_stg;
CREATE TABLE fahrer_stg LIKE fahrer;
ALTER TABLE fahrer_stg
    DROP PRIMARY KEY,                     -- FK‑frei
    AUTO_INCREMENT = 1;                   -- falls PK autoincrement

/* Fahrer_Fahrzeug */
DROP TABLE IF EXISTS fahrer_fahrzeug_stg;
CREATE TABLE fahrer_fahrzeug_stg LIKE fahrer_fahrzeug;
ALTER TABLE fahrer_fahrzeug_stg
    DROP PRIMARY KEY;                     -- FK‑frei

/* Geraet */
DROP TABLE IF EXISTS geraet_stg;
CREATE TABLE geraet_stg LIKE geraet;
ALTER TABLE geraet_stg
    DROP PRIMARY KEY,                     -- FK‑frei
    AUTO_INCREMENT = 1;                   -- falls PK autoincrement

/* Fahrt */
DROP TABLE IF EXISTS fahrt_stg;
CREATE TABLE fahrt_stg LIKE fahrt;
ALTER TABLE fahrt_stg
    DROP PRIMARY KEY,                     -- FK‑frei
    AUTO_INCREMENT = 1;                   -- falls PK autoincrement

/* Fahrzeugparameter */
DROP TABLE IF EXISTS fahrzeugparameter_stg;
CREATE TABLE fahrzeugparameter_stg LIKE fahrzeugparameter;
ALTER TABLE fahrzeugparameter_stg
    DROP PRIMARY KEY,                     -- FK‑frei
    AUTO_INCREMENT = 1;                   -- falls PK autoincrement

/* Beschleunigung */
DROP TABLE IF EXISTS beschleunigung_stg;
CREATE TABLE beschleunigung_stg LIKE beschleunigung;
ALTER TABLE beschleunigung_stg
    DROP PRIMARY KEY,                     -- FK‑frei
    AUTO_INCREMENT = 1;                   -- falls PK autoincrement

/* Diagnose */
DROP TABLE IF EXISTS diagnose_stg;
CREATE TABLE diagnose_stg LIKE diagnose;
ALTER TABLE diagnose_stg
    DROP PRIMARY KEY,                     -- FK‑frei
    AUTO_INCREMENT = 1;                   -- falls PK autoincrement

/* Wartung */
DROP TABLE IF EXISTS wartung_stg;
CREATE TABLE wartung_stg LIKE wartung;
ALTER TABLE wartung_stg
    DROP PRIMARY KEY,                     -- FK‑frei
    AUTO_INCREMENT = 1;                   -- falls PK autoincrement

/* Geraet_Installation */
DROP TABLE IF EXISTS geraet_installation_stg;
CREATE TABLE geraet_installation_stg LIKE geraet_installation;
ALTER TABLE geraet_installation_stg
    DROP PRIMARY KEY,                     -- FK‑frei
    AUTO_INCREMENT = 1;                   -- falls PK autoincrement
