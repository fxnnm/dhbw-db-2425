-- ------------------------------------------------------------------------------
-- Trigger- und Prozeduren-Demo in MySQL (Referentielle Integrität & Validierung)
--
-- Erstellt für den Unterricht an der DHBW Stuttgart
-- Dozent: Karsten Keßler
--
-- Dieses SQL-Skript zeigt:
--   Validierung von Notenänderungen (keine Verschlechterung erlaubt)
--   Verhinderung des Löschens von Studenten mit vorhandenen Ergebnissen
--   Protokollierung von Notenverbesserungen
--   Einsatz von Triggern und Stored Procedures zur Datenkonsistenz
--
-- © 2025 DHBW Stuttgart – Verwendung ausschließlich zu Lehr-/Demozwecken
-- ------------------------------------------------------------------------------

-- Test DB anlegen
CREATE DATABASE IF NOT EXISTS dhbw25_trigger;

USE dhbw25_trigger;

-- -------------- Integrität: ON UPDATE CASCADE -----

drop table if exists bestellung;
drop table if exists kunde;

-- 1. Vater
CREATE TABLE kunde (
    kundenid INT PRIMARY KEY,
    name VARCHAR(100)
);

-- 2. Kind mit ON UPDATE CASCADE
CREATE TABLE bestellung (
    bestellnr INT PRIMARY KEY,
    kundenid INT,
    FOREIGN KEY (kundenid) REFERENCES kunde(kundenid)
    ON UPDATE CASCADE
);

-- Väter erzeugen
INSERT INTO kunde VALUES (1, 'Vater 1');
INSERT INTO kunde VALUES (2, 'Vater 2');

-- Kinder erzeugen
INSERT INTO bestellung VALUES (1, 1);  -- verweist auf Vater 1
INSERT INTO bestellung VALUES (2, 2);  -- verweist auf Vater 2

-- Vater ändern --> Kind wird auch geändert (Referenzielle Integrität bleibt erhalten)
UPDATE kunde SET kundenid = 5 WHERE kundenid = 1;
-- -------------------

-- -------------- Integrität: ON DELETE SET NULL -----
drop table if exists user10;
drop table if exists rolle10;

-- Parent Table
create table rolle10(
id varchar(3) primary key,
name varchar(10)
);

-- Child Table
create table user10(
id varchar(3),
name varchar(10),
foreign key(id) references rolle10(id)
on delete set null
);

insert into rolle10 values
('A', 'Admin'),
('L', 'Local'),
('G', 'Global'),
('D','DAU');

insert into user10 values
('A', 'Anette'),
('L', 'Ludwig'),
('L', 'Lisa'),
('G','Gerd'),
('D','Dieter'),
('D','Detlef'),
('D','Doris');

select * from rolle10;
select * from user10;

delete from user10 where id = 'L';  -- geht
delete from rolle10 where id = 'D'; -- SET NULL --> ID auf NULL

-- -------------- TRIGGER -----
-- DROP section remains unchanged
DROP PROCEDURE IF EXISTS check_studentenloeschung;
DROP PROCEDURE IF EXISTS check_note_verbesserung;
DROP FUNCTION IF EXISTS ist_note_verbessert;

DROP TABLE IF EXISTS Notenprotokoll;
DROP TABLE IF EXISTS Ergebnisse;
DROP TABLE IF EXISTS Studenten;

-- Tabllen anlegen
CREATE TABLE Studenten (
    MatrNr INT PRIMARY KEY,
    Name VARCHAR(100),
    Vorname VARCHAR(100)
);

CREATE TABLE Ergebnisse (
    ErgebnisID INT PRIMARY KEY AUTO_INCREMENT,
    MatrNr INT,
    Fach VARCHAR(100),
    Note DECIMAL(3,1),
    FOREIGN KEY (MatrNr) REFERENCES Studenten(MatrNr)
);

CREATE TABLE Notenprotokoll (
    ProtokollID INT PRIMARY KEY AUTO_INCREMENT,
    ErgebnisID INT,
    AlteNote DECIMAL(3,1),
    NeueNote DECIMAL(3,1),
    Zeitpunkt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ErgebnisID) REFERENCES Ergebnisse(ErgebnisID)
);

--  1. Prozedur: check_note_verbesserung
DELIMITER //
CREATE PROCEDURE check_note_verbesserung(IN alt DECIMAL(3,1), IN neu DECIMAL(3,1))
BEGIN
    IF neu > alt THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Note darf sich nicht verschlechtern!';
    END IF;
END //
DELIMITER ;

DELIMITER //
-- 2. Den aufbauenden Trigger anlegen
CREATE TRIGGER verhindere_notenverschlechterung_bu
BEFORE UPDATE ON Ergebnisse
FOR EACH ROW
BEGIN
    CALL check_note_verbesserung(OLD.Note, NEW.Note);
END;
//

-- 3. Prozedur: check_studentenloeschung
DROP PROCEDURE IF EXISTS check_studentenloeschung;

DELIMITER //

CREATE PROCEDURE check_studentenloeschung(IN in_matrnr INT)
BEGIN
    DECLARE cnt INT DEFAULT 0;

    SELECT COUNT(*) INTO cnt
    FROM Ergebnisse
    WHERE MatrNr = in_matrnr;

    -- Zum Debuggen (kann danach entfernt werden)
    -- SELECT CONCAT('DEBUG: COUNT = ', cnt) AS DebugOutput;

    IF cnt > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Student hat noch Ergebnis(se) und darf nicht gelöscht werden!';
    END IF;
END;
//

DELIMITER ;

-- 4. Den aufbauenden Trigger anlegen
DELIMITER //
CREATE TRIGGER blockiere_studentenloeschung_bd
BEFORE DELETE ON Studenten
FOR EACH ROW
BEGIN
    CALL check_studentenloeschung(OLD.MatrNr);
END;
//

-- Funktion: gibt TRUE zurück, wenn neue Note besser ist
DELIMITER //
CREATE FUNCTION ist_note_verbessert(alt DECIMAL(3,1), neu DECIMAL(3,1))
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    RETURN neu < alt;
END;
//
DELIMITER ;

DELIMITER //
-- AFTER UPDATE Trigger für Logging
CREATE TRIGGER logge_notenverbesserung_au
AFTER UPDATE ON Ergebnisse
FOR EACH ROW
BEGIN
    IF ist_note_verbessert(OLD.Note, NEW.Note) THEN
        INSERT INTO Notenprotokoll (ErgebnisID, AlteNote, NeueNote)
        VALUES (OLD.ErgebnisID, OLD.Note, NEW.Note);
    END IF;
END;
//

DELIMITER ;

-- Testdaten einfügen
INSERT INTO Studenten (MatrNr, Name, Vorname) VALUES
(1001, 'Müller', 'Hans'),
(1002, 'Schmidt', 'Lisa'),
(1003, 'Weber', 'Max');

-- Nach dem Einfügen der Studenten überprüfen
SELECT * FROM Studenten;
-- Erwartetes Ergebnis: 3 Studenteneinträge sollten angezeigt werden

INSERT INTO Ergebnisse (MatrNr, Fach, Note) VALUES
(1001, 'Datenbanken', 2.0),
(1001, 'Programmierung', 3.0),
(1002, 'Datenbanken', 1.7),
(1003, 'Algorithmen', 2.3);

-- Nach dem Einfügen der Ergebnisse überprüfen
SELECT * FROM Ergebnisse;
-- Erwartetes Ergebnis: 4 Ergebniseinträge sollten angezeigt werden

-- Test 1: Notenverbesserung (sollte funktionieren)
UPDATE Ergebnisse SET Note = 1.3 WHERE MatrNr = 1001 AND Fach = 'Datenbanken';
-- Überprüfen, ob die Note aktualisiert wurde
SELECT * FROM Ergebnisse WHERE MatrNr = 1001 AND Fach = 'Datenbanken';
-- Erwartetes Ergebnis: Note sollte 1.3 sein

-- Überprüfen, ob Notenprotokoll erstellt wurde
SELECT * FROM Notenprotokoll;
-- Erwartetes Ergebnis: Ein Eintrag mit AlteNote=2.0, NeueNote=1.3

-- Test 2: Notenverschlechterung (sollte fehlschlagen)
UPDATE Ergebnisse SET Note = 4.0 WHERE MatrNr = 1001 AND Fach = 'Datenbanken';
-- Erwartetes Ergebnis: Fehlermeldung "Note darf sich nicht verschlechtern!"

-- Überprüfen, ob die Note unverändert ist
SELECT * FROM Ergebnisse WHERE MatrNr = 1001 AND Fach = 'Datenbanken';
-- Erwartetes Ergebnis: Note sollte immer noch 1.3 sein

-- Test 3: Unveränderte Note
UPDATE Ergebnisse SET Note = 1.3 WHERE MatrNr = 1001 AND Fach = 'Datenbanken';
-- Überprüfen, ob Notenprotokoll unverändert ist
SELECT * FROM Notenprotokoll;
-- Erwartetes Ergebnis: Keine neuen Einträge im Protokoll

-- Test 4: Student mit Ergebnissen löschen (sollte fehlschlagen)
DELETE FROM Studenten WHERE MatrNr = 1001;
-- Erwartetes Ergebnis: Fehlermeldung "Student hat noch Ergebnis(se) und darf nicht gelöscht werden!"

-- Überprüfen, ob der Student noch vorhanden ist
SELECT * FROM Studenten WHERE MatrNr = 1001;
-- Erwartetes Ergebnis: Student sollte noch vorhanden sein

-- Test 5: Ergebnisse eines Studenten löschen
DELETE FROM Ergebnisse WHERE MatrNr = 1003;
-- Überprüfen, ob die Ergebnisse gelöscht wurden
SELECT * FROM Ergebnisse WHERE MatrNr = 1003;
-- Erwartetes Ergebnis: Keine Ergebnisse für MatrNr 1003

-- Test 6: Student ohne Ergebnisse löschen (sollte funktionieren)
DELETE FROM Studenten WHERE MatrNr = 1003;
-- Überprüfen, ob der Student gelöscht wurde
SELECT * FROM Studenten WHERE MatrNr = 1003;
-- Erwartetes Ergebnis: Kein Student mit MatrNr 1003
-- CALL check_studentenloeschung(1003);

-- Test 7: Mehrere Notenverbesserungen
UPDATE Ergebnisse SET Note = 1.0 WHERE MatrNr = 1002 AND Fach = 'Datenbanken';
UPDATE Ergebnisse SET Note = 2.0 WHERE MatrNr = 1001 AND Fach = 'Programmierung';

-- Überprüfen der aktualisierten Noten joinen
SELECT * FROM Ergebnisse WHERE (MatrNr = 1002 AND Fach = 'Datenbanken') OR (MatrNr = 1001 AND Fach = 'Programmierung');
-- Erwartetes Ergebnis: Noten sollten auf 1.0 bzw. 2.0 aktualisiert sein

-- Überprüfen des Notenprotokolls für die letzten beiden Aktualisierungen
SELECT * FROM Notenprotokoll ORDER BY Zeitpunkt; -- DESC LIMIT 2;
-- Erwartetes Ergebnis: Zwei neue Einträge im Protokoll

-- Abschließende Gesamtübersicht
SELECT s.MatrNr, s.Name, s.Vorname, e.Fach, e.Note
FROM Studenten s
JOIN Ergebnisse e ON s.MatrNr = e.MatrNr
ORDER BY s.MatrNr, e.Fach;

SELECT * FROM Notenprotokoll ORDER BY Zeitpunkt;

-- SELECT COUNT(*) FROM Ergebnisse WHERE MatrNr = 1003;
-- SELECT * FROM Ergebnisse WHERE MatrNr = 1003;
