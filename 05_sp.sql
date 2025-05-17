DELIMITER $$

DROP PROCEDURE IF EXISTS addFahrt$$

CREATE PROCEDURE addFahrt (
    IN p_fahrzeugid INT,
    IN p_geraetid INT,
    IN p_startzeitpunkt DATETIME,
    IN p_endzeitpunkt DATETIME,
    IN p_route VARCHAR(255)
)
BEGIN
    -- Validierung: Fahrzeug muss existieren
    IF NOT EXISTS (SELECT 1 FROM fahrzeug WHERE id = p_fahrzeugid) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Fahrzeug-ID existiert nicht';
    END IF;

    -- Validierung: Geraet muss existieren
    IF NOT EXISTS (SELECT 1 FROM geraet WHERE id = p_geraetid) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Geraet-ID existiert nicht';
    END IF;

    -- Fahrt anlegen
    INSERT INTO fahrt (fahrzeugid, geraetid, startzeitpunkt, endzeitpunkt, route)
    VALUES (p_fahrzeugid, p_geraetid, p_startzeitpunkt, p_endzeitpunkt, p_route);
END$$

DELIMITER ;