/* =============================================================================
   Limpieza: borra todo lo que crea 01_crear_demo.sql
   ⚠ Irreversible. Ejecútalo solo cuando ya no necesites la demo.
============================================================================= */
USE ROLE ACCOUNTADMIN;

DROP DATABASE  IF EXISTS DEMO_CLAUDE_DATA;
DROP WAREHOUSE IF EXISTS CLAUDE_DATA_WH;
DROP ROLE      IF EXISTS CLAUDE_DATA_LECTOR;
