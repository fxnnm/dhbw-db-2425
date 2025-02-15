# MongoDB Command Guide – DHBW Stuttgart 🗄️

A structured guide for common MongoDB operations used in the DHBW Stuttgart project.

---

## 📦 **Database Operations**
```sh
use newDB                 # Switch to newDB (creates it if not exists)
db.tempCollection.insertOne({name: "Karsten Kessler", age: 76})  # Insert document
show dbs                  # Show all databases
use my_database           # Switch to my_database
show collections          # Show all collections
```

---

## 📊 **Basic Queries**
```sh
db.tweets.count()         # Count documents in tweets collection
db.tweets.find()          # Display all documents
db.dhbw.find({titel: "Lost me"})  # Find by title
db.dhbw.count()           # Count documents
```

---

## 🛠️ **Insert, Update, Delete**
```sh
db.dhbw.insert({typ:"dvd",titel:"Lost me",regie:"David Bowie"})  # Insert
db.dhbw.updateOne({titel: "Lost me"}, {$set: {regie: "David Bowie"}})  # Update
db.dhbw.deleteOne({titel: "Tiger"})  # Delete
```

---

## 🔒 **User Management**
```sh
use admin
db.createUser({user: "adminUser", pwd: passwordPrompt(), roles: ["userAdminAnyDatabase", "readWriteAnyDatabase"]})
```

---

## 📚 **Collections & Indexes**
```sh
db.createCollection("dhbw")
db.dhbw.createIndex({titel: 1})   # Create index
db.dhbw.getIndexes()              # List indexes
```

---

## 📋 **Aggregation Pipeline**
```sh
db.tweets.aggregate([
  { $group: { _id: "$user.friends_count", count: { $sum: 1 } } },
  { $sort: { count: -1 } }
])
```

---

## 🏫 **Data Insertion (Embedded & Referenced)**
```sh
db.Hochschule.insertMany([...])   # Insert Hochschulen
db.Vorlesung.insertMany([...])    # Insert Vorlesungen
db.Dozent.insertMany([...])       # Insert Dozenten
db.Student.insertMany([...])      # Insert Students
```

---

## 🔍 **Find & Aggregate Examples**
```sh
db.Student.find({}, {name: 1, email: 1})
db.Student.aggregate([...]).pretty()  # Aggregation example
```

---

## 🗑️ **Drop Collections**
```sh
db.Student.drop()
db.Vorlesung.drop()
db.Dozent.drop()
db.Hochschule.drop()
```

---

*This guide is designed to make working with MongoDB easier and more readable.*  
📘 Happy coding at **DHBW Stuttgart**!
