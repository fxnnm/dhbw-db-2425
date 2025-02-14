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
1. **Install dependencies:**  
   ```bash
   pip install -r requirements.txt
   ```
2. **Set environment variables:** (via `.env` file)
   ```env
   DB_NAME=my_database
   ACTIVE_MONGO_DB=development
   ```
3. **Run the application:**  
   ```bash
   flask run
   ```

---
### 📂 Project Structure
```
project/
├── app.py              # Main Flask Application
├── routes.py           # Route Handlers
├── templates/          # HTML Templates
└── static/             # CSS and JS Files
```

---
### 📈 Version
This README uses the version displayed from the project: **Version 0.2.14**.

### 💡 Contributors
- 🧑‍💻 Developer: Karsten Keßler
- 🏫 Organization: DHBW Stuttgart

### 📜 License
MIT License © 2024 Karsten Keßler, DHBW Stuttgart


