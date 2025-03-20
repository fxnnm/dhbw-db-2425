--- Zusätzlich Daten in Tabelle beschleunigung, damit 1:n klar wird
INSERT INTO beschleunigung (fahrtid, zeitstempel, x_achse, y_achse, z_achse)
VALUES 
(95435, '2024-01-02 08:53:05', 2.18, -1.1, 2.97),
(95435, '2024-01-02 08:53:06', 3.15, 1.83, 4.69),
(95435, '2024-01-02 08:53:07', 2.98, -4.19, -4.87);

-- Löschen falscher Daten aus fahrt_fahrer
DELETE FROM fahrt_fahrer WHERE fahrtid IN (100001, 100003);

--- Zusätzlich Daten in Tabelle fahrt_fahrer, damit 1:n klar wird
INSERT INTO fahrt_fahrer (fahrtid, fahrerid) VALUES 
(30, 5),  -- Fahrt 30 hat jetzt zwei Fahrer (4 & 5)
(16, 11); -- Fahrt 16 hat jetzt zwei Fahrer (10 & 11)
