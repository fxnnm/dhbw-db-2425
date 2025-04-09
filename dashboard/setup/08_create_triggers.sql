DELIMITER $$

CREATE TRIGGER pruefung_bi
BEFORE INSERT ON pruefung
FOR EACH ROW
BEGIN
    IF NEW.note < 1.0 OR NEW.note > 5.0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Note muss zwischen 1.0 und 5.0 liegen';
    END IF;
END $$

DELIMITER ;

-- Trigger: jede neue Prüfung wird in die Log-Tabelle kopiert
DELIMITER $$

CREATE TRIGGER pruefung_ai
AFTER INSERT ON pruefung
FOR EACH ROW
BEGIN
    INSERT INTO log (studentid, kursid, note)
    VALUES (NEW.studentid, NEW.kursid, NEW.note);
END $$

DELIMITER ;

