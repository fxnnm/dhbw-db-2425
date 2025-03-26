--------------------------------------------------------
--- Szenario: Transaktionen
-- Verzögerte Sichtbarkeit / Transaktionale Sichtkonsistenz bei REPEATABLE READ
-- Zwei Sessions arbeiten auf unterschiedlichen Versionen der Daten arbeiten – Änderungen werden erst nach dem COMMIT sichtbar
--------------------------------------------------------

/*

MySQL Shell:
https://dev.mysql.com/downloads/shell/

\connect root@localhost
\sql
\system dir
\system cls
\q (beenden)

\sql
\system dir

source "C:\Users\kke\SynologyDrive\Lernen\DHBW Stuttgart\Informatik\Datenbanken\2024_25\PythonProjects\dhbw-db-2425\script.sql"

show databases;
show engines;
SHOW VARIABLES LIKE 'innodb_flush_log_at_trx_commit';

use dhbw25;
show tables:
describe dhbw25.kurs;

DROP DATABASE IF EXISTS transaktionen;
CREATE DATABASE IF NOT EXISTS transaktionen;
use transaktionen;

select connection_id();
select @@transaction_isolation;

\use Kessler_Test_Kessler
\sql
\py --> \system echo Hallo DHBW!
\js
\s
\quit
CTRL+D ---> Session schließen

*/

DROP TABLE IF EXISTS ttable1;
-------------------------------------------------
-- CREATE TABLE ttable (
CREATE TABLE ttable1 (id int NOT NULL, data int DEFAULT NULL, PRIMARY KEY (id));
-------------------------------------------------
-- INSERT INTO ttable VALUES
INSERT INTO ttable1 VALUES(1,100),(2,100),(3,250),(4,NULL),(5,200),(6,300),(7,1000),(8,500),(9,NULL),(10,700);

-------------------------------------------------
delete from ttable1;
-- drop table ttable1;
INSERT INTO ttable1 VALUES (1,100),(2,100),(3,250),(4,NULL),(5,200),(6,300),(7,1000),(8,500),(9,NULL),(10,700);
-------------------------------------------------

select * from ttable1;

-- Transaktionssteuerung mit Savepoints in MySQL

START transaction;
SAVEPOINT ttable1savepoint1;
INSERT INTO ttable1 (id, data) values (11, 130);
SAVEPOINT ttable1savepoint2;
DELETE FROM ttable1 where id > 5;
rollback to ttable1savepoint2;
update ttable1 set data = 1250 where id = 3;
rollback to table1savepoint1;
INSERT INTO ttable1 (id, data) values (12, 132);
rollback; -- Komplette Transaktion wird zurückgerollt
-- SELECT @@autocommit; bin ich innerhalb von Transaktionen? 0: Transaktion ist aktiv, evtl. mit Savepoints
INSERT INTO ttable1 (id, data) values (13, 132);
commit; -- speichert alles innerhalb der Transaktion
-------------------------------------------------


-- Eine verzögerte Sicht bei REPEATABLE READ (MVCC-Snapshot) – kein einen klassischer Phantom Read.
-- Bei dem Beispiel mit dem Isolation Level REPEATABLE READ wird in MySQL (mit InnoDB Storage-Engine) automatisch MVCC (Multiversion Concurrency Control) verwendet – ohne dass man es aktivieren musst.
-- Jede Transaktion arbeitet mit ihrer eigenen „eingefrorenen Sicht“ auf die Daten über MVCC.

---- 2 Sessions zur DB eröffnen:
\connect root@localhost

---Isolation 'Level Repeatable Read' -------------->
--- Verbindung 1 + 2:
set session transaction isolation level repeatable read;
start transaction;

--- Verbindung 1:
delete from ttable1 where id > 8;
select sum(data) from ttable1; ---> 2.450

--- Verbindung 2:
select sum(data) from ttable1; ---> 3.150
update ttable1 set data=data+200 where id=5;
select sum(data) from ttable1; ---> 3.350

--- Verbindung 1:
commit;
select sum(data) from ttable1; ---> 2.450

--- Verbindung 2:
select sum(data) from ttable1; ---> 3350
commit;
select sum(data) from ttable1; ---> 2650;

--- Verbindung 1:
select sum(data) from ttable1; ---> 2.650
-------------------------------------------------<<



DROP TABLE IF EXISTS ttable1;
-------------------------------------------------
-- CREATE TABLE ttable (
CREATE TABLE ttable1 (id int NOT NULL, data int DEFAULT NULL, PRIMARY KEY (id));
-------------------------------------------------
-- INSERT INTO ttable VALUES
INSERT INTO ttable1 VALUES(1,100),(2,100),(3,250),(4,NULL),(5,200),(6,300),(7,1000),(8,500),(9,NULL),(10,700);

-- Verbindung 1:
-- --- Isolation Level setzen
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;
START TRANSACTION;

-- Erste Abfrage → kein Problem
SELECT SUM(data) FROM ttable1;  -- Ergebnis: 3.150

-- Jetzt wird etwas gelöscht
DELETE FROM ttable1 WHERE id > 8;  -- löscht IDs 9 und 10

-- Transaktion noch NICHT committet
-- Session offen halten

-- dann:
 COMMIT;


-- Verbindung 2
-- Isolation Level setzen
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;
START TRANSACTION;

-- Diese Abfrage wird jetzt BLOCKIERT!
SELECT SUM(data) FROM ttable1;

--nach Commit in 1:
-- Ergebnis: 2.450 (wie in 1.)




-------------------------------------------------
