USE dhbw25_views;
SET NAMES utf8mb4;

-- Vorhandene Tabellen löschen, falls vorhanden
DROP TABLE IF EXISTS pruefung;
DROP TABLE IF EXISTS kurs;
DROP TABLE IF EXISTS benutzer;
DROP TABLE If EXISTS dozent;
DROP TABLE IF EXISTS student;
DROP TABLE IF EXISTS studiengang;

-- Tabelle für Benutzer
CREATE TABLE benutzer (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(100) NOT NULL UNIQUE,
    vorname VARCHAR(100) NOT NULL,
    nachname VARCHAR(100) NOT NULL,
    rolle VARCHAR(100) NOT NULL
    -- rolle ENUM('admin1', 'dozent', 'student', 'dau') NOT NULL
);


-- Tabelle für Kurse
CREATE TABLE kurs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    titel VARCHAR(100),
    dozentid INT,
    FOREIGN KEY (dozentid) REFERENCES benutzer(id)
);

-- Tabelle für Prüfungen
CREATE TABLE pruefung (
    id INT PRIMARY KEY AUTO_INCREMENT,
    studentid INT,
    kursid INT,
    note DECIMAL(3,1),
    datum DATE,
    FOREIGN KEY (studentid) REFERENCES benutzer(id),
    FOREIGN KEY (kursid) REFERENCES kurs(id)
);

CREATE TABLE dozent (
    id INT PRIMARY KEY AUTO_INCREMENT,
    benutzerid INT NOT NULL,
    buero VARCHAR(100),
    telefon VARCHAR(50),
    forschungsgebiet VARCHAR(255),
    FOREIGN KEY (benutzerid) REFERENCES benutzer(id)
);

CREATE TABLE studiengang (
    id INT PRIMARY KEY AUTO_INCREMENT,
    titel VARCHAR(100) NOT NULL,
    leiter VARCHAR(100) NOT NULL
);

CREATE TABLE student (
    id INT PRIMARY KEY AUTO_INCREMENT,
    vorname VARCHAR(100) NOT NULL,
    nachname VARCHAR(100) NOT NULL,
    studiengangid INT,
    FOREIGN KEY (studiengangid) REFERENCES studiengang(id)
);

CREATE TABLE IF NOT EXISTS log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    studentid INT,
    kursid INT,
    note DECIMAL(3,1),
    inserted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
