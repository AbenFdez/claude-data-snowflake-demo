/* =============================================================================
   Conectar Claude (Claude Data) a Snowflake · Conservas Ardora
   -----------------------------------------------------------------------------
   Ejecútalo DESPUÉS de 01_crear_demo.sql, con "Run All".

   Crea:
     1. Un servidor MCP de Snowflake con una herramienta SQL de SOLO LECTURA
        sobre DEMO_CLAUDE_DATA.VENTAS. Es lo que Claude usa para consultar.
     2. Una integración OAuth para que Claude inicie sesión en tu nombre.
     3. Tu rol por defecto pasa a ser CLAUDE_DATA_LECTOR: Claude entra con tu
        rol por defecto, y Snowflake bloquea ACCOUNTADMIN para OAuth.
        (En Snowsight puedes seguir cambiando a ACCOUNTADMIN cuando quieras.)

   Al final verás UNA fila con los 3 datos que pide el conector de Claude:
     URL_SERVIDOR_MCP, CLIENT_ID y CLIENT_SECRET.
   ⚠ El CLIENT_SECRET es una contraseña: pégalo solo en el formulario del
     conector de Claude. No lo pongas en chats, diapositivas ni en GitHub.
============================================================================= */

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE CLAUDE_DATA_WH;

-- 1. Servidor MCP con una herramienta SQL de solo lectura
CREATE OR REPLACE MCP SERVER DEMO_CLAUDE_DATA.VENTAS.CLAUDE_MCP
  FROM SPECIFICATION $$
tools:
  - title: "Consultas SQL de Conservas Ardora"
    name: "sql_exec_tool"
    type: "SYSTEM_EXECUTE_SQL"
    description: "Ejecuta consultas SQL de solo lectura sobre DEMO_CLAUDE_DATA.VENTAS: ventas, clientes, productos y objetivos de Conservas Ardora."
    config:
      read_only: true
      query_timeout: 120
      warehouse: "CLAUDE_DATA_WH"
$$;

-- Permisos del rol de lectura sobre el servidor MCP
GRANT USAGE ON MCP SERVER DEMO_CLAUDE_DATA.VENTAS.CLAUDE_MCP TO ROLE CLAUDE_DATA_LECTOR;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE CLAUDE_DATA_LECTOR;

-- 2. Integración OAuth para Claude
CREATE OR REPLACE SECURITY INTEGRATION CLAUDE_OAUTH
  TYPE = OAUTH
  OAUTH_CLIENT = CUSTOM
  ENABLED = TRUE
  OAUTH_CLIENT_TYPE = 'CONFIDENTIAL'
  OAUTH_REDIRECT_URI = 'https://claude.ai/api/mcp/auth_callback'
  OAUTH_ISSUE_REFRESH_TOKENS = TRUE
  OAUTH_USE_SECONDARY_ROLES = NONE
  ALLOWED_ROLES_LIST = ('CLAUDE_DATA_LECTOR')
  COMMENT = 'Acceso de Claude (Claude Data) a la demo de Conservas Ardora';

-- 3. Tu rol por defecto pasa a ser el de solo lectura
SET sql_rol = (SELECT 'ALTER USER "' || CURRENT_USER() || '" SET DEFAULT_ROLE = CLAUDE_DATA_LECTOR');
EXECUTE IMMEDIATE $sql_rol;

-- 4. Los 3 datos para el conector de Claude
WITH s AS (
  SELECT PARSE_JSON(SYSTEM$SHOW_OAUTH_CLIENT_SECRETS('CLAUDE_OAUTH')) AS j
)
SELECT
  'https://' || REPLACE(LOWER(CURRENT_ORGANIZATION_NAME() || '-' || CURRENT_ACCOUNT_NAME()), '_', '-')
    || '.snowflakecomputing.com/api/v2/databases/DEMO_CLAUDE_DATA/schemas/VENTAS/mcp-servers/CLAUDE_MCP' AS URL_SERVIDOR_MCP,
  j:OAUTH_CLIENT_ID::STRING     AS CLIENT_ID,
  j:OAUTH_CLIENT_SECRET::STRING AS CLIENT_SECRET
FROM s;
