-- REPORT: fahrten_fahrer
SELECT f.id AS fahrerID, f.vorname, f.nachname, COUNT(ff.fahrtid) AS anzahl_fahrten
FROM fahrer f
LEFT JOIN fahrt_fahrer ff ON f.id = ff.fahrerid
GROUP BY f.id, f.vorname, f.nachname
ORDER BY anzahl_fahrten DESC
-- ENDREPORT

-- REPORT: durchschnitt_geschwindigkeit
SELECT 
    ff.fahrerid,
    fa.vorname,
    fa.nachname,
    ROUND(AVG(fp.geschwindigkeit), 2) AS durchschnitt_geschwindigkeit,
    ROUND(AVG(fp.motortemperatur), 2) AS durchschnitt_motortemperatur
FROM fahrzeugparameter fp
JOIN fahrt f ON fp.fahrtid = f.id
JOIN fahrt_fahrer ff ON f.id = ff.fahrtid
JOIN fahrer fa ON ff.fahrerid = fa.id
WHERE fp.geschwindigkeit IS NOT NULL
AND fp.motortemperatur IS NOT NULL
AND f.startzeitpunkt IS NOT NULL
GROUP BY ff.fahrerid, fa.vorname, fa.nachname;
-- ENDREPORT

-- REPORT: aktive_fahrer
SELECT DISTINCT ff.fahrerid, fa.vorname, fa.nachname
FROM fahrt f
JOIN fahrer_fahrzeug ff ON f.fahrzeugid = ff.fahrzeugid
JOIN fahrer fa ON ff.fahrerid = fa.id
WHERE f.startzeitpunkt >= DATE_SUB(CURDATE(), INTERVAL 15 MONTH)
AND (
    (ff.gueltig_bis IS NULL AND f.startzeitpunkt >= ff.gueltig_ab)
    OR (f.startzeitpunkt BETWEEN ff.gueltig_ab AND ff.gueltig_bis)
);
-- ENDREPORT

-- REPORT: max_geschwindigkeit
SELECT 
    ff.fahrerid,
    fa.vorname,
    fa.nachname,
    MAX(fp.geschwindigkeit) AS max_geschwindigkeit
FROM fahrzeugparameter fp
JOIN fahrt f ON fp.fahrtid = f.id
JOIN fahrt_fahrer ff ON f.id = ff.fahrtid
JOIN fahrer fa ON ff.fahrerid = fa.id
WHERE fp.geschwindigkeit IS NOT NULL
GROUP BY ff.fahrerid, fa.vorname, fa.nachname;
-- ENDREPORT