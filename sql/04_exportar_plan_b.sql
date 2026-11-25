/* =============================================================================
   Plan B · Exportar los datos de Conservas Ardora a CSV
   -----------------------------------------------------------------------------
   Para hacer la demo SIN servidor MCP (por ejemplo, con una cuenta de prueba
   de Snowflake, que no permite usarlo): exporta los datos y adjúntalos en un
   chat de Claude para crear el panel de Claude Data.

   Ejecuta cada consulta por separado (cursor dentro de la consulta + botón ▶)
   y descarga su resultado en CSV con el botón ⬇ de la barra de resultados.
     1. ventas_detalle.csv → pedidos con cliente, región y producto (~55.000 filas)
     2. clientes.csv       → todos los clientes, para las altas por canal
============================================================================= */

USE WAREHOUSE CLAUDE_DATA_WH;

-- 1. ventas_detalle.csv
SELECT * FROM DEMO_CLAUDE_DATA.VENTAS.V_VENTAS_DETALLE ORDER BY FECHA_PEDIDO;

-- 2. clientes.csv
SELECT c.CLIENTE_ID, c.NOMBRE_CLIENTE, r.REGION, c.CIUDAD, c.PAIS, c.SEGMENTO, c.CANAL_ALTA, c.FECHA_ALTA
FROM DEMO_CLAUDE_DATA.VENTAS.CLIENTES c
JOIN DEMO_CLAUDE_DATA.VENTAS.REGIONES r ON r.REGION_ID = c.REGION_ID
ORDER BY c.CLIENTE_ID;
