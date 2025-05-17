-- UPDATE Trigger for table: fahrzeug
DROP TRIGGER IF EXISTS trg_fahrzeug_after_update;
$$
CREATE TRIGGER trg_fahrzeug_after_update
AFTER UPDATE ON fahrzeug
FOR EACH ROW
BEGIN
    INSERT INTO changelog (tabelle, aktion, benutzer, alte_werte, neue_werte)
    VALUES (
        'fahrzeug',
        'UPDATE',
        USER(),
        JSON_OBJECT('id', OLD.id, 'hersteller', OLD.hersteller, 'modell', OLD.modell, 'baujahr', OLD.baujahr),
        JSON_OBJECT('id', NEW.id, 'hersteller', NEW.hersteller, 'modell', NEW.modell, 'baujahr', NEW.baujahr)
    );
END;
$$

-- UPDATE Trigger for table: fahrer
DROP TRIGGER IF EXISTS trg_fahrer_after_update;
$$
CREATE TRIGGER trg_fahrer_after_update
AFTER UPDATE ON fahrer
FOR EACH ROW
BEGIN
    INSERT INTO changelog (tabelle, aktion, benutzer, alte_werte, neue_werte)
    VALUES (
        'fahrer',
        'UPDATE',
        USER(),
        JSON_OBJECT('id', OLD.id, 'vorname', OLD.vorname, 'nachname', OLD.nachname, 'geburtsdatum', OLD.geburtsdatum, 'kontakt_nr', OLD.kontakt_nr, 'email', OLD.email),
        JSON_OBJECT('id', NEW.id, 'vorname', NEW.vorname, 'nachname', NEW.nachname, 'geburtsdatum', NEW.geburtsdatum, 'kontakt_nr', NEW.kontakt_nr, 'email', NEW.email)
    );
END;
$$

-- UPDATE Trigger for table: fahrer_fahrzeug
DROP TRIGGER IF EXISTS trg_fahrer_fahrzeug_after_update;
$$
CREATE TRIGGER trg_fahrer_fahrzeug_after_update
AFTER UPDATE ON fahrer_fahrzeug
FOR EACH ROW
BEGIN
    INSERT INTO changelog (tabelle, aktion, benutzer, alte_werte, neue_werte)
    VALUES (
        'fahrer_fahrzeug',
        'UPDATE',
        USER(),
        JSON_OBJECT('fahrerid', OLD.fahrerid, 'fahrzeugid', OLD.fahrzeugid, 'gueltig_ab', OLD.gueltig_ab, 'gueltig_bis', OLD.gueltig_bis),
        JSON_OBJECT('fahrerid', NEW.fahrerid, 'fahrzeugid', NEW.fahrzeugid, 'gueltig_ab', NEW.gueltig_ab, 'gueltig_bis', NEW.gueltig_bis)
    );
END;
$$

-- UPDATE Trigger for table: geraet
DROP TRIGGER IF EXISTS trg_geraet_after_update;
$$
CREATE TRIGGER trg_geraet_after_update
AFTER UPDATE ON geraet
FOR EACH ROW
BEGIN
    INSERT INTO changelog (tabelle, aktion, benutzer, alte_werte, neue_werte)
    VALUES (
        'geraet',
        'UPDATE',
        USER(),
        JSON_OBJECT('id', OLD.id, 'fahrzeugid', OLD.fahrzeugid, 'geraet_typ', OLD.geraet_typ, 'hersteller', OLD.hersteller, 'modell', OLD.modell),
        JSON_OBJECT('id', NEW.id, 'fahrzeugid', NEW.fahrzeugid, 'geraet_typ', NEW.geraet_typ, 'hersteller', NEW.hersteller, 'modell', NEW.modell)
    );
END;
$$

-- UPDATE Trigger for table: fahrt
DROP TRIGGER IF EXISTS trg_fahrt_after_update;
$$
CREATE TRIGGER trg_fahrt_after_update
AFTER UPDATE ON fahrt
FOR EACH ROW
BEGIN
    INSERT INTO changelog (tabelle, aktion, benutzer, alte_werte, neue_werte)
    VALUES (
        'fahrt',
        'UPDATE',
        USER(),
        JSON_OBJECT('id', OLD.id, 'fahrzeugid', OLD.fahrzeugid, 'geraetid', OLD.geraetid, 'startzeitpunkt', OLD.startzeitpunkt, 'endzeitpunkt', OLD.endzeitpunkt, 'route', OLD.route),
        JSON_OBJECT('id', NEW.id, 'fahrzeugid', NEW.fahrzeugid, 'geraetid', NEW.geraetid, 'startzeitpunkt', NEW.startzeitpunkt, 'endzeitpunkt', NEW.endzeitpunkt, 'route', NEW.route)
    );
END;
$$

-- UPDATE Trigger for table: fahrt_fahrer
DROP TRIGGER IF EXISTS trg_fahrt_fahrer_after_update;
$$
CREATE TRIGGER trg_fahrt_fahrer_after_update
AFTER UPDATE ON fahrt_fahrer
FOR EACH ROW
BEGIN
    INSERT INTO changelog (tabelle, aktion, benutzer, alte_werte, neue_werte)
    VALUES (
        'fahrt_fahrer',
        'UPDATE',
        USER(),
        JSON_OBJECT('fahrtid', OLD.fahrtid, 'fahrerid', OLD.fahrerid),
        JSON_OBJECT('fahrtid', NEW.fahrtid, 'fahrerid', NEW.fahrerid)
    );
END;
$$

-- UPDATE Trigger for table: fahrzeugparameter
DROP TRIGGER IF EXISTS trg_fahrzeugparameter_after_update;
$$
CREATE TRIGGER trg_fahrzeugparameter_after_update
AFTER UPDATE ON fahrzeugparameter
FOR EACH ROW
BEGIN
    INSERT INTO changelog (tabelle, aktion, benutzer, alte_werte, neue_werte)
    VALUES (
        'fahrzeugparameter',
        'UPDATE',
        USER(),
        JSON_OBJECT('id', OLD.id, 'fahrtid', OLD.fahrtid, 'zeitstempel', OLD.zeitstempel, 'geschwindigkeit', OLD.geschwindigkeit, 'motortemperatur', OLD.motortemperatur, 'luftmassenstrom', OLD.luftmassenstrom, 'batterie', OLD.batterie),
        JSON_OBJECT('id', NEW.id, 'fahrtid', NEW.fahrtid, 'zeitstempel', NEW.zeitstempel, 'geschwindigkeit', NEW.geschwindigkeit, 'motortemperatur', NEW.motortemperatur, 'luftmassenstrom', NEW.luftmassenstrom, 'batterie', NEW.batterie)
    );
END;
$$

-- UPDATE Trigger for table: beschleunigung
DROP TRIGGER IF EXISTS trg_beschleunigung_after_update;
$$
CREATE TRIGGER trg_beschleunigung_after_update
AFTER UPDATE ON beschleunigung
FOR EACH ROW
BEGIN
    INSERT INTO changelog (tabelle, aktion, benutzer, alte_werte, neue_werte)
    VALUES (
        'beschleunigung',
        'UPDATE',
        USER(),
        JSON_OBJECT('id', OLD.id, 'fahrtid', OLD.fahrtid, 'zeitstempel', OLD.zeitstempel, 'x_achse', OLD.x_achse, 'y_achse', OLD.y_achse, 'z_achse', OLD.z_achse),
        JSON_OBJECT('id', NEW.id, 'fahrtid', NEW.fahrtid, 'zeitstempel', NEW.zeitstempel, 'x_achse', NEW.x_achse, 'y_achse', NEW.y_achse, 'z_achse', NEW.z_achse)
    );
END;
$$

-- UPDATE Trigger for table: diagnose
DROP TRIGGER IF EXISTS trg_diagnose_after_update;
$$
CREATE TRIGGER trg_diagnose_after_update
AFTER UPDATE ON diagnose
FOR EACH ROW
BEGIN
    INSERT INTO changelog (tabelle, aktion, benutzer, alte_werte, neue_werte)
    VALUES (
        'diagnose',
        'UPDATE',
        USER(),
        JSON_OBJECT('id', OLD.id, 'fahrtid', OLD.fahrtid, 'zeitstempel', OLD.zeitstempel, 'fehlercode', OLD.fehlercode, 'beschreibung', OLD.beschreibung),
        JSON_OBJECT('id', NEW.id, 'fahrtid', NEW.fahrtid, 'zeitstempel', NEW.zeitstempel, 'fehlercode', NEW.fehlercode, 'beschreibung', NEW.beschreibung)
    );
END;
$$

-- UPDATE Trigger for table: wartung
DROP TRIGGER IF EXISTS trg_wartung_after_update;
$$
CREATE TRIGGER trg_wartung_after_update
AFTER UPDATE ON wartung
FOR EACH ROW
BEGIN
    INSERT INTO changelog (tabelle, aktion, benutzer, alte_werte, neue_werte)
    VALUES (
        'wartung',
        'UPDATE',
        USER(),
        JSON_OBJECT('id', OLD.id, 'fahrzeugid', OLD.fahrzeugid, 'datum', OLD.datum, 'beschreibung', OLD.beschreibung),
        JSON_OBJECT('id', NEW.id, 'fahrzeugid', NEW.fahrzeugid, 'datum', NEW.datum, 'beschreibung', NEW.beschreibung)
    );
END;
$$

-- UPDATE Trigger for table: geraet_installation
DROP TRIGGER IF EXISTS trg_geraet_installation_after_update;
$$
CREATE TRIGGER trg_geraet_installation_after_update
AFTER UPDATE ON geraet_installation
FOR EACH ROW
BEGIN
    INSERT INTO changelog (tabelle, aktion, benutzer, alte_werte, neue_werte)
    VALUES (
        'geraet_installation',
        'UPDATE',
        USER(),
        JSON_OBJECT('id', OLD.id, 'geraetid', OLD.geraetid, 'fahrzeugid', OLD.fahrzeugid, 'einbau_datum', OLD.einbau_datum, 'ausbau_datum', OLD.ausbau_datum),
        JSON_OBJECT('id', NEW.id, 'geraetid', NEW.geraetid, 'fahrzeugid', NEW.fahrzeugid, 'einbau_datum', NEW.einbau_datum, 'ausbau_datum', NEW.ausbau_datum)
    );
END;
$$