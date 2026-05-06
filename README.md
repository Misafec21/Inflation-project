Inflation Tracker Mexico (INPC) - Database Project

Project Overview

This project aims to design and implement a robust database system in MySQL to store, structure, and analyze the National Consumer Price Index (INPC) in Mexico. Rather than relying on manual data entry, the system utilizes a Python integration to extract raw data from official Banxico and INEGI APIs. This allows for a professional-grade analysis of how inflation impacts different regions and spending categories over time.

Key Features & Scope

Database Architecture (MySQL)
The core of the system is a normalized relational database designed for high-performance queries.
•	Core Entities: Includes Registro_Inflacion (central table), Catalogo_Indicadores, Periodos_Tiempo, and Rubros_Gasto.
•	Scalability: The model is projected to expand to 10–12 entities to include granular geographic data (Regions, States, Cities) and internal audit logs.
•	Data Integrity: Implements foreign keys and specific data types to prevent design errors during the extraction phase.
Automation Engine (Python)

A Python-based ETL (Extract, Transform, Load) script serves as the bridge between official sources and the database:

•	API Integration: Connects to the Banxico SieAPI to fetch JSON data.
•	Automated Processing: Cleans and validates data before insertion into MySQL to ensure consistency.
•	Extraction Logs: Automates the Bitacora_Extraccion table to maintain a traceable history of data updates.

Project Management

The development follows software engineering best practices to ensure timely delivery:
•	WBS (Work Breakdown Structure): A hierarchical breakdown of tasks from API analysis to final SQL implementation.
•	Trello Tracking: Utilization of a Kanban board to manage tasks among team members (Chan, Felix, Gaxiola, and Merin).

Tech Stack
•	Database: MySQL
•	Language: Python (for API extraction and data processing)
•	API Sources: Banco de México (Banxico), INEGI
•	Management: Trello, WBS Methodology

Objectives & Problem Solving
The primary goal is to address the social issue of inflation and its impact on purchasing power. By translating "raw numbers" into actionable insights, this project provides:
•	Sector Analysis: Identifying which sectors (Food, Transport, Housing) are driving inflation.
•	Geographic Comparison: Comparing price increases across different regions of Mexico.
•	Efficient Reporting: Optimized time-based tables for fast annual and monthly average calculations.

Team Members
•	Chan Lauro Joseph
•	Felix Camacho Misael Alejandro
•	Gaxiola Elizalde Uziel Hiram
•	Merin Zepeda Esteban Gabriel
