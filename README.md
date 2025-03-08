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

---
### 💻 How to Run

## Installation

1. Clone the repository:
   ```sh
   git clone https://github.com/karkessler/dhbw-db-2425.git
   cd dhbw-db-2425

2. Set and activate a virtual environment:
   ```sh
   python -m venv .venv
   source .venv/bin/activate  # On Windows use `.venv\Scripts\activate`

3. **Install dependencies:**  
   ```bash
   pip install -r requirements.txt
   ```
   
2. **Set environment variables:** (via `.env` file)
   ```env
   SECRET_KEY=3b9a21c8ef0b4a95a24bc52de4dc56f7

   MYSQL_HOST=127.0.0.1
   MYSQL_USER=root
   MYSQL_PASSWORD=admin123
   MYSQL_DB_NAME=telematik

   MONGO_HOST=localhost
   MONGO_PORT=27017
   MONGO_DB_NAME=telematik
   
   ```
3. **Run the application:**  
   ```bash
   flask run (or PyCharm, Visual Code, ...)
   ```

---
### 📂 Project Structure
```
├── app.py                # Main Flask Application
├── .env                  # Environment Variables
├── api
│   ├── routes
│   │   ├── route.py      # Route Handlers
├── core                  # Core functionalities
├── data                  # Data files (CSV, JSON)
│   ├── 01_fahrzeug.csv
│   ├── unfall.json
├── events                # Event Handling
├── infrastructure        # Backend and Helpers
│   ├── common
│   │   ├── db_helpers.py  # Database Helper Functions
│   ├── config
│   │   ├── config.py     # Configuration File
│   ├── database
│   │   ├── helpers
│   │   │   ├── helpers.py # Additional Database Helpers
│   ├── service           # Business Logic
│   ├── logging           # Logging Configuration
├── static                # CSS, JS, Images
├── tests                 # Unit and Integration Tests
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

### 📜 License
MIT License © 2024 Karsten Keßler, DHBW Stuttgart


