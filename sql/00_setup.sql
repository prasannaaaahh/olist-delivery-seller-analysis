-- Business question: Create the empty database that the Olist analysis loads into.
-- Run once before notebook 01. Tables are created by notebooks/01_load_data.ipynb.

CREATE DATABASE IF NOT EXISTS olist CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;