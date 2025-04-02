# ------------------------------------------------------------------------------
# Deadlock-Demo mit echten SQL-Transaktionen (MySQL) zur Lehrzwecken
#
# Erstellt für den Unterricht an der DHBW Stuttgart
# Dozent: Karsten Keßler
#
# Dieses Skript demonstriert den Ablauf eines Deadlocks zwischen vier Sitzungen
# (Transaktionen), die verschiedene Sperren (S-Lock, X-Lock) auf Ressourcen setzen.
#
# © 2025 DHBW Stuttgart – Verwendung nur zu Lehr-/Demozwecken
# ------------------------------------------------------------------------------

import mysql.connector
import threading
import time

DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': 'admin123',
    'database': 'dhbw25',
    'autocommit': False
}


def sitzung1():  # Transaktion 1
    conn = mysql.connector.connect(**DB_CONFIG)
    cursor = conn.cursor(buffered=True)
    cursor.execute("SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;")
    cursor.execute("START TRANSACTION;")

    time.sleep(0.0)
    print("[Zeit 1.0 | Sitzung 1 | Transaktion 1] FOR SHARE auf Ressource A (S-Lock gesetzt)")
    cursor.execute("SELECT * FROM ttable2 WHERE id = 'A' FOR SHARE;")

    time.sleep(1.0)
    print("[Zeit 2.0 | Sitzung 1 | Transaktion 1] FOR SHARE auf Ressource D (S-Lock gesetzt)")
    cursor.execute("SELECT * FROM ttable2 WHERE id = 'D' FOR SHARE;")

    time.sleep(2.0)
    print("[Zeit 4.0 | Sitzung 1 | Transaktion 1] FOR SHARE auf Ressource B (blockiert – Sitzung 2 hält X-Lock)")
    try:
        cursor.execute("SELECT * FROM ttable2 WHERE id = 'B' FOR SHARE;")
    except Exception as e:
        print("[Sitzung 1] Fehler: ", e)

    conn.rollback()
    conn.close()


def sitzung2():  # Transaktion 2
    conn = mysql.connector.connect(**DB_CONFIG)
    cursor = conn.cursor(buffered=True)
    cursor.execute("SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;")
    cursor.execute("START TRANSACTION;")

    time.sleep(2.0)
    print("[Zeit 3.0 | Sitzung 2 | Transaktion 2] FOR UPDATE auf Ressource B (X-Lock gesetzt)")
    cursor.execute("SELECT * FROM ttable2 WHERE id = 'B' FOR UPDATE;")

    time.sleep(4.0)
    print("[Zeit 7.0 | Sitzung 2 | Transaktion 2] FOR UPDATE auf Ressource C (blockiert – Sitzung 3 hält S-Lock)")
    try:
        cursor.execute("SELECT * FROM ttable2 WHERE id = 'C' FOR UPDATE;")
    except Exception as e:
        print("[Sitzung 2] Fehler: ", e)

    conn.rollback()
    conn.close()


def sitzung3():  # Transaktion 3
    conn = mysql.connector.connect(**DB_CONFIG)
    cursor = conn.cursor(buffered=True)
    cursor.execute("SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;")
    cursor.execute("START TRANSACTION;")

    time.sleep(4.0)
    print("[Zeit 5.0 | Sitzung 3 | Transaktion 3] FOR SHARE auf Ressource D (S-Lock gesetzt)")
    cursor.execute("SELECT * FROM ttable2 WHERE id = 'D' FOR SHARE;")

    time.sleep(1.0)
    print("[Zeit 6.0 | Sitzung 3 | Transaktion 3] FOR SHARE auf Ressource C (S-Lock gesetzt)")
    cursor.execute("SELECT * FROM ttable2 WHERE id = 'C' FOR SHARE;")

    time.sleep(2.0)
    print("[Zeit 9.0 | Sitzung 3 | Transaktion 3] FOR UPDATE auf Ressource A (blockiert – Sitzung 1 hält S-Lock → "
          "Deadlock!)")
    try:
        cursor.execute("SELECT * FROM ttable2 WHERE id = 'A' FOR UPDATE;")
    except Exception as e:
        print("[Sitzung 3] Fehler: ", e)

    conn.rollback()
    conn.close()


def sitzung4():  # Transaktion 4
    conn = mysql.connector.connect(**DB_CONFIG)
    cursor = conn.cursor(buffered=True)
    cursor.execute("SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;")
    cursor.execute("START TRANSACTION;")

    time.sleep(6.0)
    print("[Zeit 8.0 | Sitzung 4 | Transaktion 4] FOR UPDATE auf Ressource B (blockiert – Sitzung 2 hält X-Lock)")
    try:
        cursor.execute("SELECT * FROM ttable2 WHERE id = 'B' FOR UPDATE;")
    except Exception as e:
        print("[Sitzung 4] Fehler: ", e)

    conn.rollback()
    conn.close()


def setup_table():
    conn = mysql.connector.connect(**DB_CONFIG)
    cursor = conn.cursor()
    cursor.execute("DROP TABLE IF EXISTS ttable2;")
    cursor.execute("""
        CREATE TABLE ttable2 (
            id CHAR(1) PRIMARY KEY,
            wert INT
        );
    """)
    cursor.execute("""
        INSERT INTO ttable2 (id, wert) VALUES
        ('A', 100), ('B', 100), ('C', 100), ('D', 100);
    """)
    conn.commit()
    conn.close()
    print("[Setup] Tabelle ttable2 wurde erstellt und befüllt.")


if __name__ == "__main__":
    setup_table()

    threads = [
        threading.Thread(target=sitzung1),
        threading.Thread(target=sitzung2),
        threading.Thread(target=sitzung3),
        threading.Thread(target=sitzung4),
    ]

    for t in threads:
        t.start()

    for t in threads:
        t.join()

    print("App erfolgreich beendet.")
