Inflation Tracker Mexico (INPC) – Database Project

Project Overview

This project focuses on the design and implementation of a relational database system in MySQL to store, organize, and analyze inflation data in Mexico using official information provided by Banco de México (Banxico) and INEGI APIs.

The system integrates Python-based automation to extract, process, and load data directly from official API services into the database. The objective is to create a reliable and scalable platform capable of analyzing inflation behavior across different periods, economic sectors, and geographic regions of Mexico.

⸻

Main Objectives

* Build a normalized MySQL database for inflation-related data.
* Integrate Banxico and INEGI APIs for automated data extraction.
* Develop ETL processes using Python.
* Store historical inflation records for analysis and reporting.
* Generate structured data that can support future dashboards, reports, and statistical analysis.

⸻

System Architecture

Database (MySQL)

The database is designed following relational database normalization principles to ensure data integrity, scalability, and efficient querying.

Core Tables

* Registro_Inflacion – Main table containing inflation records.
* Catalogo_Indicadores – Stores economic indicators and metadata.
* Periodos_Tiempo – Handles monthly and yearly time references.
* Rubros_Gasto – Stores expenditure categories such as food, transport, housing, etc.
* Bitacora_Extraccion – Tracks API extraction processes and update logs.

Data Integrity Features

* Primary and foreign keys
* Controlled data types
* Referential integrity constraints
* Structured relationships between entities

⸻

API Integration

The project uses official APIs from:

* Banco de México (Banxico)
* INEGI

Python scripts are responsible for:

1. Connecting to APIs
2. Retrieving JSON data
3. Validating and cleaning information
4. Transforming data into database-compatible formats
5. Automatically inserting records into MySQL

⸻

Technologies Used

* Database: MySQL
* Programming Language: Python
* APIs: Banxico API, INEGI API
* Version Control: Git & GitHub
* Project Management: Trello, WBS Methodology

⸻

Project Scope

The database is intended to support:

* Inflation trend analysis
* Geographic comparisons between regions and states
* Category-based inflation studies
* Historical data storage
* Automated update processes
* Future integration with dashboards and visualization tools

⸻

Expected Outcomes

The system aims to provide:

* Reliable inflation datasets
* Faster statistical queries
* Automated data updates
* Structured historical records
* Improved accessibility for economic analysis and academic research

⸻

Team Members

* Chan Lauro Joseph
* Felix Camacho Misael Alejandro
* Gaxiola Elizalde Uziel Hiram
* Merin Zepeda Esteban Gabriel

⸻

Repository Purpose

This repository contains:

* MySQL database scripts
* Table creation scripts
* Insert statements
* Audit log structures
* ETL integration scripts
* Documentation related to the project
