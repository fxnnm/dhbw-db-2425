-- Benutzer sicher neu anlegen

-- DROP USER IF EXISTS 'adminuser'@'localhost';
-- CREATE USER 'adminuser'@'localhost' IDENTIFIED BY 'adminpass';

-- DROP USER IF EXISTS 'dozent1'@'localhost';
-- CREATE USER 'dozent1'@'localhost' IDENTIFIED BY 'dozentpass';

-- DROP USER IF EXISTS 'student1'@'localhost';
-- CREATE USER 'student1'@'localhost' IDENTIFIED BY 'studentpass';

-- DROP USER IF EXISTS 'dau1'@'localhost';
-- CREATE USER 'dau1'@'localhost' IDENTIFIED BY 'daupass';

-- Rechte für Admin: volle Sicht
GRANT SELECT ON dhbw25_views.adminsicht TO 'admin1'@'localhost';

-- Rechte für Dozent: nur dozentensicht
GRANT SELECT ON dhbw25_views.dozentensicht TO 'dozent1'@'localhost';

-- Rechte für Student: nur studentensicht
GRANT SELECT ON dhbw25_views.studentensicht TO 'student1'@'localhost';

-- DAU: kein GRANT – kein Zugriff