-- 03_reports.sql
-- Report 1: Durchschnittliche Geschwindigkeit und Motortemperatur pro Fahrer im März 2024
SELECT 
    f.fahrerid,
    fa.vorname,
    fa.nachname,
    AVG(fp.geschwindigkeit) AS durchschnitt_geschwindigkeit,
    AVG(fp.motortemperatur) AS durchschnitt_motortemperatur
FROM fahrzeugparameter fp
JOIN fahrt fht ON fp.fahrtid = fht.id
JOIN fahrt_fahrer f ON fht.id = f.fahrtid
JOIN fahrer fa ON f.fahrerid = fa.id
WHERE MONTH(fht.startzeitpunkt) = 3 AND YEAR(fht.startzeitpunkt) = 2024
GROUP BY f.fahrerid;

-- Report 2: Fahrer mit Fahrten in den letzten 15 Monaten
SELECT DISTINCT f.fahrerid, fa.vorname, fa.nachname
FROM fahrt fht
JOIN fahrt_fahrer f ON fht.id = f.fahrtid
JOIN fahrer fa ON f.fahrerid = fa.id
WHERE fht.startzeitpunkt >= CURDATE() - INTERVAL 15 MONTH;

-- Report 3: Höchste jemals gemessene Geschwindigkeit je Fahrer
SELECT 
    f.fahrerid,
    fa.vorname,
    fa.nachname,
    MAX(fp.geschwindigkeit) AS max_geschwindigkeit
FROM fahrzeugparameter fp
JOIN fahrt fht ON fp.fahrtid = fht.id
JOIN fahrt_fahrer f ON fht.id = f.fahrtid
JOIN fahrer fa ON f.fahrerid = fa.id
GROUP BY f.fahrerid;
