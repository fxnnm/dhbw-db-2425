# DHBW-DB-2425 – README.md

## 📚 Project Overview  
**DHBW-DB_2023_24_App**  
**Version:** 0.2.14  

---
### 📝 Description
This project is a **Database Management Web Application** for MySQL and MongoDB. It provides features such as table conversion, data import, and report generation.

### 🚀 Features:
- ⚙️ **Table Conversion:** Convert tables between different formats.
- 📥 **Data Import:** Upload and insert data into your database.
- 📊 **Report Generation:** View statistical reports.
- ✏️ **Table Editing:** Modify existing tables with ease.
- 🔄 **Reload Functionality:** Refresh data instantly.
- 🔍 **Pagination & Navigation:** Browse large datasets with page navigation and direct page jump.
- ✅ **Data Validation:** Stored procedures ensure data consistency and enforce business rules.
- 🧠 **Smart Trigger Logging:** Automatically logs all updates in a dedicated changelog table.
- 🌐 **MongoDB Integration:** Import and convert MySQL tables to MongoDB collections.
- 📦 **Server Statistics:** View live statistics from both MySQL and MongoDB (e.g., row count, last update).
- 🔧 **Schema Setup Automation:** Automatically creates schema and populates it on first run.
- 🔐 **Environment-Based Configuration:** Secure and configurable via .env file.
- 🚨 **Error Feedback:** User-friendly error messages and debug logging.
- 🛠️ **Update Tracking:** View history of changes through audit triggers.

---
### 💻 How to Run

## Installation

1. **Clone the repository:**
   ```sh
   git clone https://github.com/karkessler/dhbw-db-2425.git
   cd dhbw-db-2425

2. **Set and activate a virtual environment:**
   ```sh
   python -m venv .venv
   source .venv/bin/activate  # On Windows 

3. **Install dependencies:**  
   ```bash
   pip install -r requirements.txt
   ```
   
2. **Set environment variables:** (via `.env` file)
   ```env
   SECRET_KEY=...

   MYSQL_HOST=...
   MYSQL_USER=...
   MYSQL_PASSWORD=...
   MYSQL_DB_NAME=...

   MONGO_HOST=...
   MONGO_PORT=27017...
   MONGO_DB_NAME=telematik...
   
   ```

3. **Start Docker Container:**
   ```bash
   docker-compose up -d
   ```

4. **Run the application:**  
   ```bash
   python app.py
   ```
   !!! It is important to start the application via python and not flask !!!

5. **Open the Website:** (in the browser)
   ```Use the following address: http://127.0.0.1:5000
   ```

---
### 📂 Project Structure
```
├── app.py                # Main Flask Application
├── .env                  # Environment Variables
├── convert.py            # Converts selected MySQL tables into MongoDB collections, optionally with embedding
├── 01_create_table.sql   # Creates all MySQL tables and their constraints
├── 02_import_data.sql    # Imports and cleans data from CSV files into the database
├── 03_reports.sql        # Defines reusable SQL report queries (used dynamically in the app)
├── 04_trigger.sql        # Creates triggers that log UPDATE operations into the changelog
├── 05_sp.sql             # Contains stored procedures (e.g., for inserting new records with validation)
├── docker-compose.yml    # Defines and configures multi-container Docker services for MySQL and MongoDB
├── requirements.txt      # Lists all Python dependencies needed to run the application
├── api
│   ├── routes
│   │   ├── route.py      # Route Handlers
├── core                  # Core functionalities ----------------------------evtl. sql Dateien hierhin verschieben
├── data                  # Data files (CSV, JSON)
│   ├── 01_fahrzeug.csv
│   ├── 02_fahrer.csv
│   ├── 03_fahrer_fahrzeug.csv
│   ├── 04_geraet.csv
│   ├── 05_fahrt.csv
│   ├── 06_fahrt_fahrer.csv
│   ├── 07_fahrzeugparameter.csv
│   ├── 08_beschleunigung.csv
│   ├── 09_diagnose.csv
│   ├── 10_wartung.csv
│   ├── 11_geraet_installation.csv
│   ├── data_cleanup.sql
│   ├── fahrt.json
│   ├── unfall.json
├── infrastructure        # Backend and Helpers
│   ├── config
│   │   ├── config.py     # Configuration File
│   ├── database
│   │   ├── helpers
│   │   │   ├── helpers.py # Additional Database Helpers
├── static                # CSS, JS, Images
├── web                   # Frontend
│   ├── templates         # HTML Templates
│   │   ├── index.html
│   │   ├── layout.html
│   │   ├── add_data.html
│   │   ├── convert.html
│   │   ├── reports.html
│   │   ├── select_table.html
│   │   ├── view_table.html

```

---
### 📈 Version
This README uses the version displayed from the project: **Version 0.2.14**.

### 💡 Contributors
- 🧑‍💻 Developer: Karsten Keßler
- 🏫 Organization: DHBW Stuttgart
- 🎓 Students: Finn Manser, Mara Pliske, Marcel Janßen

### 📜 License
MIT License © 2024 Karsten Keßler, DHBW Stuttgart