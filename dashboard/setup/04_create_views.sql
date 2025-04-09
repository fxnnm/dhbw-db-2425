use dhbw25_views;
SET NAMES utf8mb4;

-- Vorhandene Sichten löschen, falls vorhanden
DROP VIEW IF EXISTS adminsicht;
DROP VIEW IF EXISTS dozentsicht;
DROP VIEW IF EXISTS studentsicht;
DROP VIEW IF EXISTS topstudentsicht;
DROP VIEW IF EXISTS dozentinfosicht;
DROP VIEW IF EXISTS kursstatistiksicht;
DROP VIEW IF EXISTS bestestudentsicht;
DROP VIEW IF EXISTS dauinfosicht;
DROP VIEW IF EXISTS benutzerohnerollesicht;
DROP VIEW IF EXISTS gutenotensicht;
DROP VIEW IF EXISTS studenteninfosicht;
DROp VIEW IF EXISTS kursdurchschnittsicht;

-- 1. Adminsicht – sieht alles
CREATE OR REPLACE VIEW adminsicht AS
SELECT
    p.id AS pruefung_id,
    p.note,
    p.datum,

    s.id AS student_id,
    s.username AS student_username,
    s.vorname AS student_vorname,
    s.nachname AS student_nachname,
    s.rolle AS student_rolle,

    k.id AS kurs_id,
    k.titel AS kurs_titel,

    d.id AS dozent_id,
    d.username AS dozent_username,
    d.vorname AS dozent_vorname,
    d.nachname AS dozent_nachname,
    d.rolle AS dozent_rolle,

    dz.buero AS dozent_buero,
    dz.telefon AS dozent_telefon,
    dz.forschungsgebiet AS dozent_forschungsgebiet

FROM pruefung p
JOIN benutzer s ON p.studentid = s.id
JOIN kurs k ON p.kursid = k.id
JOIN benutzer d ON k.dozentid = d.id
LEFT JOIN dozent dz ON dz.benutzerid = d.id;

-- 2. Dozentensicht – sieht nur eigene Kurse
CREATE VIEW dozentsicht AS
SELECT
    d.vorname AS dozent_vorname,
    d.nachname AS dozent_nachname,
    s.vorname AS student_vorname,
    s.nachname AS student_nachname,
    k.titel AS kurs,
    p.note,
    p.datum
FROM pruefung p
JOIN benutzer s ON p.studentid = s.id
JOIN kurs k ON p.kursid = k.id
JOIN benutzer d ON k.dozentid = d.id;

-- 3. Studentensicht – sieht nur eigene Noten
CREATE OR REPLACE VIEW studentsicht AS
SELECT
    s.vorname AS student_vorname,
    s.nachname AS student_nachname,
    k.titel AS kurs,
    p.note,
    p.datum
FROM pruefung p
JOIN benutzer s ON p.studentid = s.id
JOIN kurs k ON p.kursid = k.id;

-- 4. Topstudentsicht (verschachtelte View)
CREATE VIEW topstudentsicht AS
SELECT * FROM studentsicht
WHERE note <= 1.5;

-- 5. Dozentinfosicht
CREATE VIEW dozentinfosicht AS
SELECT
    b.username,
    b.vorname,
    b.nachname,
    d.buero,
    d.telefon,
    d.forschungsgebiet
FROM dozent d
JOIN benutzer b ON d.benutzerid = b.id;

-- 6. Kursstatistik
CREATE VIEW kursstatistiksicht AS
SELECT
    k.titel AS kurs,
    d.vorname AS dozent_vorname,
    d.nachname AS dozent_nachname,
    COUNT(p.id) AS anzahl_teilnehmer,
    ROUND(AVG(p.note), 2) AS durchschnittsnote
FROM pruefung p
JOIN kurs k ON p.kursid = k.id
JOIN benutzer d ON k.dozentid = d.id
GROUP BY k.id, k.titel, d.vorname, d.nachname;

-- 7. Beste Studenten
CREATE VIEW bestestudentsicht AS
SELECT
    s.vorname AS student_vorname,
    s.nachname AS student_nachname,
    k.titel AS kurs,
    p.note,
    p.datum
FROM pruefung p
JOIN benutzer s ON p.studentid = s.id
JOIN kurs k ON p.kursid = k.id
WHERE p.note <= 1.5
ORDER BY p.note ASC;

-- 8. DAU-Info
CREATE VIEW dauinfosicht AS
SELECT
    'Hallo DAU!' AS nachricht,
    NOW() AS zeitpunkt,
    'Zugriff ist stark eingeschraenkt.' AS hinweis;

-- A. Erstelle eine Sicht, die die Rolle ausblendet (9)
CREATE VIEW benutzerohnerollesicht AS
SELECT username, vorname, nachname
FROM benutzer;

-- B. Erstelle eine Sicht, die nur Prüfungen mit sehr guten Noten erlaubt (10)
CREATE VIEW gutenotensicht AS
SELECT studentid, kursid, note
FROM pruefung
WHERE note <= 2.0
WITH CHECK OPTION;

-- C. (11)
CREATE VIEW studenteninfosicht AS
SELECT s.vorname, s.nachname, sg.titel AS studiengang, sg.leiter
FROM student s
JOIN studiengang sg ON s.studiengangid = sg.id;

-- D. (12)
CREATE VIEW kursdurchschnittsicht AS
SELECT kursid, AVG(note) AS durchschnitt
FROM pruefung
GROUP BY kursid;
