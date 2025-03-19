/*
\sql
\system dir
\connect root@localhost
\show databases;
 */
-- -----------------------------------------------
-- - Szenario: DDL (Data Definition Language)
-- -----------------------------------------------
-- Lösche bestehende Datenbank, Benutzer und Rollen für eine saubere Neuinstallation
-- -----------------------------------------------

-- Lösche die Datenbank, falls sie existiert
DROP DATABASE IF EXISTS dhbw25;

-- Lösche alle Benutzer
DROP USER IF EXISTS 'dhbw25_admin_user'@'localhost';
DROP USER IF EXISTS 'dhbw25_professor_user'@'localhost';
DROP USER IF EXISTS 'dhbw25_student_user'@'localhost';

-- Lösche alle Rollen
DROP ROLE IF EXISTS dhbw25_admin_role;
DROP ROLE IF EXISTS dhbw25_professor_role;
DROP ROLE IF EXISTS dhbw25_student_role;

-- Aktualisieren der Berechtigungen nach dem Löschen
FLUSH PRIVILEGES;

-- -----------------------------------------------
-- Erstellen der Datenbank
-- -----------------------------------------------

CREATE DATABASE IF NOT EXISTS dhbw25 CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
-- utf8mb4_bin gewährleistet volle Unicode-Unterstützung (z. B. Sonderzeichen, Emojis).
-- Dies macht zudem Textwerte groß- und kleinschreibungsensitiv.

-- Default Schema setzen
USE dhbw25;

SHOW tables;

-- -----------------------------------------------
-- Erstellen der Tabellen
-- -----------------------------------------------

CREATE TABLE student (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    NAME VARCHAR(50) NOT NULL,
    MATRIKELNUMMER VARCHAR(10) UNIQUE NOT NULL,
    EMAIL VARCHAR(100) UNIQUE,
    ALTER_JAHRE INT CHECK (ALTER_JAHRE >= 18),
    EINSCHREIBEDATUM TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DESCRIBE dhbw25.student;


-- ALTER TABLE student ADD CONSTRAINT chk_age CHECK (ALTER_JAHRE >= 18);
-- ALTER TABLE student DROP CONSTRAINT chk_age;

CREATE TABLE kurs (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    NAME VARCHAR(50) NOT NULL
);

CREATE TABLE student_kurs (
    STUDENT_ID INT,
    KURS_ID INT,
    PRIMARY KEY (STUDENT_ID, KURS_ID),
    FOREIGN KEY (STUDENT_ID) REFERENCES student(ID) ON DELETE CASCADE,
    FOREIGN KEY (KURS_ID) REFERENCES kurs(ID) ON DELETE CASCADE
);


-- -----------------------------------------------
-- Einfügen von Testdaten
-- -----------------------------------------------

-- Füge Studenten hinzu
-- -----------------------------------------------
-- Insert Sample Data into Student Table
-- -----------------------------------------------

INSERT INTO student (NAME, MATRIKELNUMMER, EMAIL, ALTER_JAHRE, EINSCHREIBEDATUM) VALUES
('Alice Müller', '20231001', 'alice.mueller@example.com', 20, '2023-09-01'),
('Bob Schmidt', '20231002', 'bob.schmidt@example.com', 22, '2023-09-02'),
('Charlie Meier', '20231003', 'charlie.meier@example.com', 19, '2023-09-03'),
('David Klein', '20231004', 'david.klein@example.com', 21, '2023-09-04'),
('Emma Fischer', '20231005', 'emma.fischer@example.com', 23, '2023-09-05');

INSERT INTO student (NAME, MATRIKELNUMMER, EMAIL, ALTER_JAHRE, EINSCHREIBEDATUM) VALUES
('Judith Jung', '20231007', 'alice.mueller@example.com', 20, '2023-09-01');

INSERT INTO student (NAME, MATRIKELNUMMER, EMAIL, ALTER_JAHRE, EINSCHREIBEDATUM) VALUES
('Judith Jung', '20231007', 'judith.jung@example.com', 17, '2023-09-01');

INSERT INTO student (NAME, MATRIKELNUMMER, EMAIL, ALTER_JAHRE, EINSCHREIBEDATUM) VALUES
('Judith Jung', '20231007', 'judith.jung@example.com', 19, '2023-09-01');

-- Füge Kurse hinzu
INSERT INTO kurs (NAME) VALUES
('Datenbanken'),
('Programmierung'),
('Maschinelles Lernen');

-- Verknüpfe Studenten mit Kursen
INSERT INTO student_kurs (STUDENT_ID, KURS_ID) VALUES
(1, 1),
(1, 2),
(2, 2),
(2, 3),
(3, 1),
(3, 3);

-- -----------------------------------------------
-- Löschen von Testdaten
-- -----------------------------------------------
DELETE from student_kurs;


-- -----------------------------------------------
-- Benutzer und Rollenverwaltung
-- -----------------------------------------------

-- Erstelle Rollen
CREATE ROLE IF NOT EXISTS dhbw25_admin_role;
CREATE ROLE IF NOT EXISTS dhbw25_professor_role;
CREATE ROLE IF NOT EXISTS dhbw25_student_role;

-- Erstelle Benutzer
CREATE USER IF NOT EXISTS 'dhbw25_admin_user'@'localhost' IDENTIFIED BY 'secure_password';
CREATE USER IF NOT EXISTS 'dhbw25_professor_user'@'localhost' IDENTIFIED BY 'secure_password';
CREATE USER IF NOT EXISTS 'dhbw25_student_user'@'localhost' IDENTIFIED BY 'secure_password';

-- Weise Rollen den Benutzern zu
GRANT dhbw25_admin_role TO 'dhbw25_admin_user'@'localhost';
GRANT dhbw25_professor_role TO 'dhbw25_professor_user'@'localhost';
GRANT dhbw25_student_role TO 'dhbw25_student_user'@'localhost';

-- -----------------------------------------------
-- Rechte für Rollen festlegen
-- -----------------------------------------------

-- Administratorrolle: Volle Kontrolle über die Datenbank
GRANT ALL PRIVILEGES ON dhbw25.* TO dhbw25_admin_role;

-- Professorrolle: Kann Kurse verwalten, aber z.B. keine Studenten löschen
GRANT SELECT, INSERT, UPDATE, DELETE ON dhbw25.kurs TO dhbw25_professor_role;
GRANT SELECT ON dhbw25.student TO dhbw25_professor_role;
GRANT SELECT, INSERT, DELETE ON dhbw25.student_kurs TO dhbw25_professor_role;

-- Studentenrolle: Kann Kurse ansehen
GRANT SELECT ON dhbw25.kurs TO dhbw25_student_role;
GRANT SELECT ON dhbw25.student_kurs TO dhbw25_student_role;

-- Aktualisieren der Berechtigungen nach Änderungen
FLUSH PRIVILEGES;

-- -----------------------------------------------
-- Test: Zeige alle Benutzer und Rollen
-- -----------------------------------------------
SELECT user, host FROM mysql.user;
SELECT DISTINCT user FROM mysql.user WHERE user LIKE '%_role';
SHOW GRANTS FOR 'dhbw25_admin_user'@'localhost';
SHOW GRANTS FOR 'dhbw25_professor_user'@'localhost';
SHOW GRANTS FOR 'dhbw25_student_user'@'localhost';

SHOW GRANTS FOR 'dhbw25_admin_role';
SHOW GRANTS FOR 'dhbw25_professor_role';
SHOW GRANTS FOR 'dhbw25_student_role';

-- -----------------------------------------------
-- Löschen der Datenbank, Benutzer und Rollen am Ende des Scripts
-- -----------------------------------------------

-- Lösche die gesamte Datenbank
DROP DATABASE IF EXISTS dhbw25;

-- Lösche alle Benutzer
DROP USER IF EXISTS 'dhbw25_admin_user'@'localhost';
DROP USER IF EXISTS 'dhbw25_professor_user'@'localhost';
DROP USER IF EXISTS 'dhbw25_student_user'@'localhost';

-- Lösche alle Rollen
DROP ROLE IF EXISTS dhbw25_admin_role;
DROP ROLE IF EXISTS dhbw25_professor_role;
DROP ROLE IF EXISTS dhbw25_student_role;

-- Aktualisieren der Berechtigungen nach dem Löschen
FLUSH PRIVILEGES;



