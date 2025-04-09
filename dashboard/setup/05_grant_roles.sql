USE dhbw25_views;
SET NAMES utf8mb4;
-- Rollen erstellen
DROP ROLE IF EXISTS studentrolle;
DROP ROLE IF EXISTS dozentrolle;
DROP ROLE IF EXISTS adminrolle;
DROP ROLE IF EXISTS daurolle;

CREATE ROLE IF NOT EXISTS studentrolle;
CREATE ROLE IF NOT EXISTS dozentrolle;
CREATE ROLE IF NOT EXISTS adminrolle;
CREATE ROLE IF NOT EXISTS daurolle;

-- Rechte den Rollen zuweisen
-- Studenten:
GRANT SELECT ON dhbw25_views.studentsicht TO studentrolle;
-- Dozenten:
GRANT SELECT ON dhbw25_views.dozentsicht TO dozentrolle;
GRANT SELECT ON dhbw25_views.dozentinfosicht TO dozentrolle;
GRANT SELECT ON dhbw25_views.topstudentsicht TO dozentrolle;
GRANT SELECT ON dhbw25_views.kursstatistiksicht TO dozentrolle;
GRANT SELECT ON dhbw25_views.bestestudentsicht TO dozentrolle;

-- Admin bekommt alles:
GRANT SELECT ON dhbw25_views.* TO adminrolle;
-- Der DAU nur sinnloses:
GRANT SELECT ON dhbw25_views.dauinfosicht TO daurolle;

-- Rollen Benutzern zuweisen
REVOKE studentrolle FROM 'student1'@'localhost';
-- REVOKE studentrolle FROM 'student2'@'localhost';
REVOKE dozentrolle FROM 'dozent1'@'localhost';
REVOKE adminrolle FROM 'admin1'@'localhost';
REVOKE daurolle FROM 'dau1'@'localhost';

GRANT studentrolle TO 'student1'@'localhost';
-- GRANT studentrolle TO 'student2'@'localhost';
GRANT dozentrolle TO 'dozent1'@'localhost';
GRANT adminrolle TO 'admin1'@'localhost';
GRANT daurolle TO 'dau1'@'localhost';

-- Standardrolle beim Login aktivieren
SET DEFAULT ROLE studentrolle TO 'student1'@'localhost';
-- SET DEFAULT ROLE studentrolle TO 'student2'@'localhost';
SET DEFAULT ROLE dozentrolle TO 'dozent1'@'localhost';
SET DEFAULT ROLE adminrolle TO 'admin1'@'localhost';
SET DEFAULT ROLE daurolle TO 'dau1'@'localhost';