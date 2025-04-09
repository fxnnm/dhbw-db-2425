-- MySQL-Skript mit Fehlerbehandlung und Rollback
USE dhbw25_views;
SET NAMES utf8mb4;

DROP PROCEDURE IF EXISTS ImportDaten;

DELIMITER $$

-- Eine gespeicherte Prozedur für den gesamten Import mit Fehlerbehandlung
CREATE PROCEDURE ImportDaten()
import_proc: BEGIN  -- Label hinzugefügt
    -- Deklarieren der Variablen für die Fehlerbehandlung
    DECLARE exit_handler BOOLEAN DEFAULT FALSE;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SET exit_handler = TRUE;
        SELECT 'Ein SQL-Fehler ist aufgetreten!' AS Fehler;
        ROLLBACK;
    END;

    -- ====== BENUTZER IMPORT ======
    SELECT 'Starte Benutzer-Import...' AS Info;

    START TRANSACTION;

    -- Admins
    INSERT INTO benutzer (username, vorname, nachname, rolle) VALUES ('admin1', 'Alice', 'Admin', 'admin');
    INSERT INTO benutzer (username, vorname, nachname, rolle) VALUES ('admin2', 'Bob', 'Bombe', 'admin');

    -- Dozenten
    INSERT INTO benutzer (username, vorname, nachname, rolle) VALUES ('dozent1', 'Pascal', 'Primus', 'dozent');
    INSERT INTO benutzer (username, vorname, nachname, rolle) VALUES ('dozent2', 'Raspi', 'Rekursiv', 'dozent');
    INSERT INTO benutzer (username, vorname, nachname, rolle) VALUES ('dozent3', 'Clara', 'Compiler', 'dozent');

    -- Studenten
    INSERT INTO benutzer (username, vorname, nachname, rolle) VALUES ('student1', 'Anna', 'Algorithmus', 'student');
    INSERT INTO benutzer (username, vorname, nachname, rolle) VALUES ('student2', 'Ben', 'Binary', 'student');
    INSERT INTO benutzer (username, vorname, nachname, rolle) VALUES ('student3', 'Clara', 'Code', 'student');
    INSERT INTO benutzer (username, vorname, nachname, rolle) VALUES ('student4', 'David', 'Datenbank', 'student');
    INSERT INTO benutzer (username, vorname, nachname, rolle) VALUES ('student5', 'Eva', 'Exception', 'student');
    INSERT INTO benutzer (username, vorname, nachname, rolle) VALUES ('student6', 'Felix', 'Funktion', 'student');
    INSERT INTO benutzer (username, vorname, nachname, rolle) VALUES ('student7', 'Greta', 'Gui', 'student');
    INSERT INTO benutzer (username, vorname, nachname, rolle) VALUES ('student8', 'Hannes', 'Hardware', 'student');
    INSERT INTO benutzer (username, vorname, nachname, rolle) VALUES ('student9', 'Isabel', 'Interface', 'student');
    INSERT INTO benutzer (username, vorname, nachname, rolle) VALUES ('student10', 'Jonas', 'Json', 'student');

    -- DAUs
    INSERT INTO benutzer (username, vorname, nachname, rolle) VALUES ('dau1', 'Dieter', 'Ahnungslos', 'dau');
    INSERT INTO benutzer (username, vorname, nachname, rolle) VALUES ('dau2', 'Sabine', 'Sorglos', 'dau');

    -- Check if error occurred
    IF exit_handler THEN
        SELECT 'Fehler beim Benutzer-Import, Transaktion zurückgesetzt' AS Fehler;
        SET exit_handler = FALSE;
        LEAVE import_proc;  -- Korrigiert
    ELSE
        COMMIT;
        SELECT 'Benutzer-Import erfolgreich abgeschlossen' AS Status;
        SELECT COUNT(*) AS 'Anzahl importierter Benutzer' FROM benutzer;
    END IF;

    -- ====== DOZENTEN IMPORT ======
    SELECT 'Starte Dozenten-Import...' AS Info;

    START TRANSACTION;

    -- Dozent Einträge
    INSERT INTO dozent (benutzerid, buero, telefon, forschungsgebiet) VALUES
    (3, 'B.112', '0711-123456', 'Rekursive Algorithmen'),
    (4, 'B.113', '0711-123457', 'Embedded Systems'),
    (5, 'B.114', '0711-123458', 'Compilerbau');

    -- Check if error occurred
    IF exit_handler THEN
        SELECT 'Fehler beim Dozenten-Import, Transaktion zurückgesetzt' AS Fehler;
        SET exit_handler = FALSE;
        LEAVE import_proc;  -- Korrigiert
    ELSE
        COMMIT;
        SELECT 'Dozenten-Import erfolgreich abgeschlossen' AS Status;
        SELECT COUNT(*) AS 'Anzahl importierter Dozenten' FROM dozent;
    END IF;

    -- ====== KURSE IMPORT ======
    SELECT 'Starte Kurse-Import...' AS Info;

    START TRANSACTION;

    -- Kurse
    INSERT INTO kurs (titel, dozentid) VALUES ('Mathematik', 3);
    INSERT INTO kurs (titel, dozentid) VALUES ('Informatik', 4);
    INSERT INTO kurs (titel, dozentid) VALUES ('Physik', 5);

    -- Check if error occurred
    IF exit_handler THEN
        SELECT 'Fehler beim Kurse-Import, Transaktion zurückgesetzt' AS Fehler;
        SET exit_handler = FALSE;
        LEAVE import_proc;  -- Korrigiert
    ELSE
        COMMIT;
        SELECT 'Kurse-Import erfolgreich abgeschlossen' AS Status;
        SELECT COUNT(*) AS 'Anzahl importierter Kurse' FROM kurs;
    END IF;

    -- ====== PRÜFUNGEN IMPORT ======
    SELECT 'Starte Prüfungen-Import...' AS Info;

    START TRANSACTION;

    -- Prüfungen
    INSERT INTO pruefung (studentid, kursid, note, datum) VALUES (6, 1, 1.3, '2025-01-10');
    INSERT INTO pruefung (studentid, kursid, note, datum) VALUES (6, 2, 2.3, '2025-01-17');
    INSERT INTO pruefung (studentid, kursid, note, datum) VALUES (6, 3, 2.0, '2025-01-24');

    INSERT INTO pruefung (studentid, kursid, note, datum) VALUES (7, 1, 1.3, '2025-01-10');
    INSERT INTO pruefung (studentid, kursid, note, datum) VALUES (7, 2, 2.3, '2025-01-17');
    INSERT INTO pruefung (studentid, kursid, note, datum) VALUES (7, 3, 2.0, '2025-01-24');

    INSERT INTO pruefung (studentid, kursid, note, datum) VALUES (8, 1, 1.3, '2025-01-10');
    INSERT INTO pruefung (studentid, kursid, note, datum) VALUES (8, 2, 2.3, '2025-01-17');
    INSERT INTO pruefung (studentid, kursid, note, datum) VALUES (8, 3, 2.0, '2025-01-24');

    INSERT INTO pruefung (studentid, kursid, note, datum) VALUES (9, 1, 2.3, '2025-01-10');
    INSERT INTO pruefung (studentid, kursid, note, datum) VALUES (9, 2, 4.3, '2025-01-17');
    INSERT INTO pruefung (studentid, kursid, note, datum) VALUES (9, 3, 1.0, '2025-01-24');

    INSERT INTO pruefung (studentid, kursid, note, datum) VALUES (10, 1, 1.0, '2025-01-10');
    INSERT INTO pruefung (studentid, kursid, note, datum) VALUES (10, 2, 1.1, '2025-01-17');
    INSERT INTO pruefung (studentid, kursid, note, datum) VALUES (10, 3, 1.0, '2025-01-24');

    -- Check if error occurred
    IF exit_handler THEN
        SELECT 'Fehler beim Prüfungen-Import, Transaktion zurückgesetzt' AS Fehler;
        SET exit_handler = FALSE;
        LEAVE import_proc;  -- Korrigiert
    ELSE
        COMMIT;
        SELECT 'Prüfungen-Import erfolgreich abgeschlossen' AS Status;
        SELECT COUNT(*) AS 'Anzahl importierter Prüfungen' FROM pruefung;
    END IF;

    -- ====== STUDIENGÄNGE UND WEITERE STUDENTEN IMPORT ======
    SELECT 'Starte Studiengänge und weitere Studenten-Import...' AS Info;

    START TRANSACTION;

    -- Studiengänge
    INSERT INTO studiengang (titel, leiter) VALUES ('Mathematik', 'Prof. Gauss');
    INSERT INTO studiengang (titel, leiter) VALUES ('Informatik', 'Prof. Zuse');

    -- Weitere Studenten
    INSERT INTO student (vorname, nachname, studiengangid) VALUES ('August', 'Algebra', 1);
    INSERT INTO student (vorname, nachname, studiengangid) VALUES ('Theo', 'Turing', 2);

    -- Check if error occurred
    IF exit_handler THEN
        SELECT 'Fehler beim Studiengänge/Studenten-Import, Transaktion zurückgesetzt' AS Fehler;
        SET exit_handler = FALSE;
        LEAVE import_proc;  -- Korrigiert
    ELSE
        COMMIT;
        SELECT 'Studiengänge und weitere Studenten erfolgreich importiert' AS Status;
        SELECT COUNT(*) AS 'Anzahl importierter Studiengänge' FROM studiengang;
        SELECT COUNT(*) AS 'Anzahl importierter zusätzlicher Studenten' FROM student;
    END IF;

    -- ====== ABSCHLUSSBERICHT ======
    SELECT 'Gesamter Import erfolgreich abgeschlossen!' AS Gesamtergebnis;

END$$  -- Das Label wird automatisch geschlossen

DELIMITER ;

-- Um die Prozedur auszuführen:
-- CALL ImportDaten();

-- Nach dem Ausführen können wir die Prozedur wieder löschen wenn gewünscht:
-- DROP PROCEDURE IF EXISTS ImportDaten;