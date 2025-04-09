USE dhbw25_views;
SET NAMES utf8mb4;
-- Benutzer anlegen (ohne direkte GRANTs)
DROP USER IF EXISTS 'admin1'@'localhost';
CREATE USER 'admin1'@'localhost' IDENTIFIED BY 'admin1pass';

DROP USER IF EXISTS 'dozent1'@'localhost';
CREATE USER 'dozent1'@'localhost' IDENTIFIED BY 'dozent1pass';

DROP USER IF EXISTS 'student1'@'localhost';
CREATE USER 'student1'@'localhost' IDENTIFIED BY 'student1pass';

DROP USER IF EXISTS 'dau1'@'localhost';
CREATE USER 'dau1'@'localhost' IDENTIFIED BY 'dau1pass';