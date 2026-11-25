/* =============================================================================
   Consultas candidatas a CERTIFICAR en Claude Data · Conservas Ardora
   Cómo certificar: abre la consulta de un gráfico > edítala > activa
   «Certificar consulta» > añade las instrucciones (una por línea) > «Probar» >
   «Publicar».
============================================================================= */
USE WAREHOUSE CLAUDE_DATA_WH;

-- C1 · Ingresos netos por región y trimestre
--   Instrucciones para Claude:
--     Ingresos = SUM(IMPORTE_NETO_EUR) solo con ESTADO = 'Completado'.
--     La región del pedido es la del cliente.
--     Para comparar un trimestre en curso, usa el mismo número de días del trimestre anterior.
SELECT r.REGION,
       DATE_TRUNC('quarter', p.FECHA_PEDIDO) AS TRIMESTRE_INICIO,
       SUM(p.IMPORTE_NETO_EUR)               AS INGRESOS_NETOS_EUR
FROM DEMO_CLAUDE_DATA.VENTAS.PEDIDOS p
JOIN DEMO_CLAUDE_DATA.VENTAS.CLIENTES c ON c.CLIENTE_ID = p.CLIENTE_ID
JOIN DEMO_CLAUDE_DATA.VENTAS.REGIONES r ON r.REGION_ID = c.REGION_ID
WHERE p.ESTADO = 'Completado'
GROUP BY 1, 2
ORDER BY 2, 1;

-- C2 · Ingresos frente a objetivo por región y trimestre
SELECT r.REGION, o.TRIMESTRE, o.OBJETIVO_INGRESOS_EUR,
       COALESCE(SUM(p.IMPORTE_NETO_EUR), 0) AS INGRESOS_NETOS_EUR,
       ROUND(100 * INGRESOS_NETOS_EUR / o.OBJETIVO_INGRESOS_EUR, 1) AS CUMPLIMIENTO_PCT
FROM DEMO_CLAUDE_DATA.VENTAS.OBJETIVOS o
JOIN DEMO_CLAUDE_DATA.VENTAS.REGIONES r ON r.REGION_ID = o.REGION_ID
LEFT JOIN DEMO_CLAUDE_DATA.VENTAS.CLIENTES c ON c.REGION_ID = o.REGION_ID
LEFT JOIN DEMO_CLAUDE_DATA.VENTAS.PEDIDOS p
       ON p.CLIENTE_ID = c.CLIENTE_ID
      AND p.ESTADO = 'Completado'
      AND DATE_TRUNC('quarter', p.FECHA_PEDIDO) = o.TRIMESTRE_INICIO
GROUP BY r.REGION, o.TRIMESTRE, o.TRIMESTRE_INICIO, o.OBJETIVO_INGRESOS_EUR
ORDER BY o.TRIMESTRE_INICIO, r.REGION;

-- C3 · Margen bruto por categoría y mes
SELECT pr.CATEGORIA,
       DATE_TRUNC('month', p.FECHA_PEDIDO)        AS MES,
       SUM(p.IMPORTE_NETO_EUR)                    AS INGRESOS_NETOS_EUR,
       SUM(p.IMPORTE_NETO_EUR - p.COSTE_EUR)      AS MARGEN_EUR,
       ROUND(100 * MARGEN_EUR / NULLIF(INGRESOS_NETOS_EUR, 0), 1) AS MARGEN_PCT
FROM DEMO_CLAUDE_DATA.VENTAS.PEDIDOS p
JOIN DEMO_CLAUDE_DATA.VENTAS.PRODUCTOS pr ON pr.PRODUCTO_ID = p.PRODUCTO_ID
WHERE p.ESTADO = 'Completado'
GROUP BY 1, 2
ORDER BY 2, 1;
