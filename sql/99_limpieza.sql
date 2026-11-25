/* =============================================================================
   Limpieza: borra todo lo que crean 01_crear_demo.sql y 03_conectar_claude.sql
   ⚠ Irreversible. Ejecútalo solo cuando ya no necesites la demo.
   Después, quita también el conector «Snowflake Conservas Ardora» en
   Claude › Ajustes › Conectores.
============================================================================= */
USE ROLE ACCOUNTADMIN;

-- Tu rol por defecto vuelve a ser ACCOUNTADMIN
SET sql_rol = (SELECT 'ALTER USER "' || CURRENT_USER() || '" SET DEFAULT_ROLE = ACCOUNTADMIN');
EXECUTE IMMEDIATE $sql_rol;

DROP SECURITY INTEGRATION IF EXISTS CLAUDE_OAUTH;
DROP DATABASE  IF EXISTS DEMO_CLAUDE_DATA;   -- incluye el servidor MCP CLAUDE_MCP
DROP WAREHOUSE IF EXISTS CLAUDE_DATA_WH;
DROP ROLE      IF EXISTS CLAUDE_DATA_LECTOR;
