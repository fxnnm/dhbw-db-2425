@echo off
chcp 65001 >nul
REM Starte alle SQL-Skripte automatisch mit relativen Pfaden

REM Setze Pfade basierend auf dem Speicherort dieses Skripts
SET MYSQL_BIN="C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
SET SQL_PATH=""
SET MY_CNF=".my.cnf"
SET DBNAME=dhbw25_views

echo Starte SQL-Skripte...

%MYSQL_BIN% --defaults-file=%MY_CNF% < "%SQL_PATH%01_create_database.sql"
echo 01_create_database.sql gelaufen.

%MYSQL_BIN% --defaults-file=%MY_CNF% %DBNAME% < "%SQL_PATH%02_create_tables.sql"
echo 02_create_tables.sql gelaufen.

%MYSQL_BIN% --defaults-file=%MY_CNF% %DBNAME% < "%SQL_PATH%03_create_users.sql"
echo 03_create_users.sql gelaufen.

%MYSQL_BIN% --defaults-file=%MY_CNF% %DBNAME% < "%SQL_PATH%04_create_views.sql"
echo 04_create_views.sql gelaufen.

%MYSQL_BIN% --defaults-file=%MY_CNF% %DBNAME% < "%SQL_PATH%05_grant_roles.sql"
echo 05_grant_roles.sql gelaufen.

%MYSQL_BIN% --defaults-file=%MY_CNF% %DBNAME% < "%SQL_PATH%07_sp_import_data.sql"
echo 07_sp_import_data.sql gelaufen.

%MYSQL_BIN% --defaults-file=%MY_CNF% %DBNAME% -e "CALL ImportDaten();"
echo Import mit Fehlerbehandlung durchgeführt.

%MYSQL_BIN% --defaults-file=%MY_CNF% %DBNAME% < "%SQL_PATH%08_create_triggers.sql"
echo 08_create_triggers.sql gelaufen.

echo.
echo Alle SQL-Skripte erfolgreich beendet.
pause



