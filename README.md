# MEXICO INFLATION ANALYSIS SYSTEM

---

## The Big Picture

The **Mexico Inflation Analysis System** is a streamlined data engineering pipeline built to track, transform, and visualize official economic indicators. By connecting directly to the Bank of Mexico (Banxico) API, the system automates the entire journey of financial data—from raw internet metrics to high-performance database storage.

This project focuses on **three main pillars**:
* **Extraction & Cleaning:** Pulling raw data from official sources and formatting it correctly.
* **Relational Storage (SQL):** Structuring the data into an organized MySQL database for operational safety.
* **NoSQL Migration (MongoDB):** Cloning pre-calculated reports into MongoDB for ultra-fast performance and analysis.

---

## How the Pipeline Works

### 1. Data Ingestion & Transformation
The system automatically connects to the Banxico API to retrieve twelve critical macroeconomic series from **2022 to 2024**. The pipeline instantly cleans this raw data, checks for consistency, and prepares it for database insertion.

### 2. The SQL Powerhouse (MySQL)
Once cleaned, the data is injected into a MySQL database. To prevent messy data or duplicates, the system uses secure internal database procedures. Instead of just creating boring technical tables, MySQL generates **"Citizen Views"**—special configurations that translate complex financial data into simple, real-world metrics.

### 3. The NoSQL Speed Booster (MongoDB)
To make sure reading the data doesn't slow down the system, these pre-calculated financial stories are automatically **migrated and cloned** into MongoDB. This separation ensures that the main data remains safe in SQL while the analytical dashboard reads directly from MongoDB at lightning speed.

---

## What This System Delivers

Instead of confusing spreadsheets, the system translates raw numbers into **six clear financial insights**:

* **The Inflation Thermometer:** Calculates total accumulated inflation and gives a clear risk diagnosis (Low, Alert, or Red).
* **Real Purchasing Power:** Shows exactly how much the value of money has changed in the real world over time.
* **Smart Savings Guide:** Analyzes market trends to tell you if it is currently a good month to invest in treasury certificates (CETES).
* **Currency Tracker:** Monitors the exact performance and fluctuations of the Mexican Peso against the US Dollar.
* **The Seasonal Expense Map:** Identifies which month of the year is historically the most expensive for consumers.
* **Volatility Alerts:** Breaks down whether price spikes are structural issues or just temporary jumps in volatile goods like food and fuel.

---

## Execution & Folder Structure

### Step-by-Step Flow
1.  **Initialize:** Run the local configuration scripts to set up your tables and automated views.
2.  **Inject:** Execute the main pipeline script to download and store the economic data.
3.  **Clone:** Run the migration script to copy the processed summaries into MongoDB.
4.  **Launch:** Turn on the console interface to read from MongoDB and display the final financial reports directly on your screen.

### Inside the Project
The repository keeps things clean by separating the work into two distinct environments:
* **The Database Folder:** Holds the blueprints for your tables, automatic logging triggers, and citizen-friendly financial views.
* **The Python Folder:** Contains the central configuration files, data extraction tools, the migration pipeline, and the terminal user interface.

---

### Troubleshooting Made Simple

* **Access Denied / Connection Errors:** Double-check your local database credentials and make sure your MySQL service is actually turned on.
* **Missing Tables:** Ensure you ran the database initialization scripts *before* starting the Python programs.
* **Empty Results:** Verify your internet connection and ensure your free Banxico API token hasn't expired.
