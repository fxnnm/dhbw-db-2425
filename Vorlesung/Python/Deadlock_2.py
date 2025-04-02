# ------------------------------------------------------------------------------
# Wait-Die-Simulation in Python zur Demonstration von Deadlock-Vermeidung
#
# Erstellt für Lehrzwecke an der DHBW Stuttgart
# Dozent: Karsten Keßler
#
# Dieses Skript demonstriert die Wait-Die-Strategie mit versetzten Transaktionen
# zur Deadlock-Vermeidung in parallelen Systemen.
# Jede Sitzung hier ist ein Thread, der das Verhalten einer Transaktion nachahmt
# mit eigenen Sperrversuchen, Wartezeiten und Abbrüchen nach dem Wait-Die-Prinzip.“
#
# © 2025 DHBW Stuttgart – Verwendung nur zu Lehr-/Demozwecken
# ------------------------------------------------------------------------------

import threading
import time

resource_locks = {"A": None, "B": None, "C": None}
resource_lock = threading.Lock()
global_start_time = time.time()


class Transaction(threading.Thread):
    def __init__(self, tid, resources_to_lock, delay=0):
        super().__init__()
        self.tid = tid
        self.resources_to_lock = resources_to_lock
        self.delay = delay
        self.timestamp = None

    def run(self):
        time.sleep(self.delay)
        self.timestamp = time.time() - global_start_time
        print(f"[Zeit {self._zeit()} | Transaktion T{self.tid}] gestartet (Timestamp: {self.timestamp:.3f})")

        for res in self.resources_to_lock:
            locked = False
            wait_start = time.time()
            max_wait = 3

            while not locked:
                with resource_lock:
                    holder = resource_locks[res]
                    if holder is None:
                        resource_locks[res] = self
                        print(
                            f"[Zeit {self._zeit()} | Transaktion T{self.tid}] FOR UPDATE auf Ressource {res} (Lock gesetzt)")
                        time.sleep(1.0)  # kleine Pause nach gesetztem Lock
                        locked = True
                    else:
                        if self.timestamp < holder.timestamp:
                            print(
                                f"[Zeit {self._zeit()} | Transaktion T{self.tid}] wartet auf Ressource {res}, gehalten von T{holder.tid} (älter)")
                        else:
                            print(
                                f"[Zeit {self._zeit()} | Transaktion T{self.tid}] ist jünger als T{holder.tid} → ABGEBROCHEN (Wait-Die greift)")
                            return

                if time.time() - wait_start > max_wait:
                    print(
                        f"[Zeit {self._zeit()} | Transaktion T{self.tid}] hat zu lange gewartet auf Ressource {res} → gibt auf.")
                    return

                time.sleep(1.5)

        print(f"[Zeit {self._zeit()} | Transaktion T{self.tid}] hat alle Ressourcen gesperrt: {self.resources_to_lock}")
        time.sleep(1.5)
        with resource_lock:
            for res in self.resources_to_lock:
                resource_locks[res] = None
                print(f"[Zeit {self._zeit()} | Transaktion T{self.tid}] gibt Ressource {res} frei")
        print(f"[Zeit {self._zeit()} | Transaktion T{self.tid}] beendet")

    def _zeit(self):
        return f"{(time.time() - global_start_time):.3f}"


# Transaktionen definieren
transactions = [
    Transaction(1, ["A", "B"], delay=0),
    Transaction(2, ["B", "C"], delay=1),
    Transaction(3, ["C", "A"], delay=2),
]

for t in transactions:
    t.start()

for t in transactions:
    t.join()

print("App erfolgreich beendet.")
