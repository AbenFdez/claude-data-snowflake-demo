/* =============================================================================
   DEMO CLAUDE DATA · Base de datos de ejemplo en Snowflake
   Empresa ficticia: CONSERVAS ARDORA, S.L.
     Conservera fundada en 1945 en A Illa de Arousa (Pontevedra), en la ría de Arousa.
     Elabora conservas de marisco y pescado de las Rías Baixas y las vende a
     tiendas gourmet, hostelería, distribuidores y cadenas de supermercados de
     toda España y del extranjero.
   -----------------------------------------------------------------------------
   Cómo usarlo
     1. En Snowsight: Projects > Worksheets > "+" > SQL Worksheet.
     2. Pega este script entero y ejecútalo con "Run All" (Ctrl/Cmd + Shift + Enter).
     3. Tarda menos de un minuto en un warehouse X-Small.

   Las fechas son RELATIVAS al día en que se ejecuta: 8 trimestres de datos que
   terminan AYER. Vuelve a ejecutarlo el día antes de grabar para que "este
   trimestre" y "este mes" tengan datos frescos. (Evita ejecutarlo el día 1 de un
   trimestre: el trimestre en curso quedaría vacío.)

   ⚠ CREATE OR REPLACE DATABASE borra y recrea DEMO_CLAUDE_DATA entera cada vez.

   Historia que esconden los datos (lo que Claude debería descubrir en la demo)
     · Casi todos los mercados crecen en el trimestre en curso (≈ +8-12 % frente
       al mismo periodo del trimestre anterior)...
     · ...salvo SUR, que cae (≈ -15 %): su mayor cliente, la cadena
       "Supermercados Hispalis" (Gran cuenta, Sevilla), dejó de comprar unas tres
       semanas antes del inicio del trimestre.
     · INTERNACIONAL es el que más crece (≈ +30 %), empujado por importadores
       (canal Distribuidor) en Portugal, Francia, Reino Unido y México.
     · Este mes se disparan las ALTAS de clientes por el canal FERIA.
     · En noviembre y diciembre suben los lotes y estuches de regalo de Navidad.
     · ~8 % de los pedidos están Devueltos o Cancelados: sumar IMPORTE_NETO_EUR sin
       filtrar ESTADO = 'Completado' infla los ingresos. Es el argumento perfecto
       para las consultas certificadas.
     · Galicia es el mercado principal (≈ 30 % de las ventas).
   Las consultas para certificar están en sql/02_consultas_certificadas.sql.
   Los porcentajes son aproximados: los datos son aleatorios en cada ejecución.
============================================================================= */


/* ---------------------------------------------------------------------------
   0. Entorno: warehouse pequeño que se apaga solo (ahorra créditos del trial)
--------------------------------------------------------------------------- */
USE ROLE ACCOUNTADMIN;

CREATE WAREHOUSE IF NOT EXISTS CLAUDE_DATA_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'Warehouse para la demo de Claude Data';

USE WAREHOUSE CLAUDE_DATA_WH;

CREATE OR REPLACE DATABASE DEMO_CLAUDE_DATA
  COMMENT = 'Datos ficticios de Conservas Ardora (A Illa de Arousa) para la demo de Claude Data';
CREATE SCHEMA DEMO_CLAUDE_DATA.VENTAS
  COMMENT = 'Ventas, clientes, productos y objetivos comerciales de Conservas Ardora';
USE SCHEMA DEMO_CLAUDE_DATA.VENTAS;

-- Ventana temporal: 8 trimestres que terminan ayer
SET fecha_fin        = DATEADD('day', -1, CURRENT_DATE());
SET inicio_trimestre = DATE_TRUNC('quarter', $fecha_fin);
SET inicio_mes       = DATE_TRUNC('month', $fecha_fin);
SET fecha_inicio     = DATEADD('quarter', -7, $inicio_trimestre);
SET ndias            = DATEDIFF('day', $fecha_inicio, $fecha_fin) + 1;
SET dias_mes         = DATEDIFF('day', $inicio_mes, $fecha_fin) + 1;


/* ---------------------------------------------------------------------------
   1. REGIONES (mercados comerciales)
--------------------------------------------------------------------------- */
CREATE OR REPLACE TABLE REGIONES (
  REGION_ID          NUMBER(10,0) NOT NULL PRIMARY KEY COMMENT 'Identificador de la región comercial',
  REGION             VARCHAR      NOT NULL COMMENT 'Nombre de la región comercial (mercado)',
  DIRECTOR_REGIONAL  VARCHAR      COMMENT 'Responsable comercial de la región (ficticio)',
  AMBITO             VARCHAR      COMMENT 'Comunidades autónomas o países que cubre la región'
) COMMENT = 'Regiones comerciales de Conservas Ardora. Galicia es el mercado local';

INSERT INTO REGIONES VALUES
  (1, 'Galicia',       'Uxía Otero',      'A Coruña, Lugo, Ourense y Pontevedra'),
  (2, 'Centro',        'Javier Sanz',     'Madrid, Castilla y León, Castilla-La Mancha, Extremadura'),
  (3, 'Este',          'Jordi Puig',      'Cataluña, Comunidad Valenciana, Aragón, Baleares'),
  (4, 'Sur',           'Antonio Vega',    'Andalucía, Murcia, Canarias'),
  (5, 'Norte',         'Ane Etxeberria',  'Asturias, Cantabria, País Vasco, Navarra, La Rioja'),
  (6, 'Internacional', 'Brais Lema',      'Portugal, Francia, Reino Unido, México');


/* ---------------------------------------------------------------------------
   2. PRODUCTOS (precio por caja)
--------------------------------------------------------------------------- */
CREATE OR REPLACE TABLE PRODUCTOS (
  PRODUCTO_ID          NUMBER(10,0)  NOT NULL PRIMARY KEY COMMENT 'Identificador del producto',
  PRODUCTO             VARCHAR       NOT NULL COMMENT 'Nombre comercial del producto',
  CATEGORIA            VARCHAR       NOT NULL COMMENT 'Moluscos, Cefalópodos, Pescados, Packs y regalo o Formato hostelería',
  FORMATO_CAJA         VARCHAR       COMMENT 'Contenido de una caja (la unidad de venta)',
  PRECIO_CAJA_EUR      NUMBER(10,2)  NOT NULL COMMENT 'Precio de tarifa por caja, en euros, sin IVA',
  COSTE_CAJA_EUR       NUMBER(10,2)  NOT NULL COMMENT 'Coste de producción por caja, en euros'
) COMMENT = 'Catálogo de conservas de Conservas Ardora. Se vende por cajas';

INSERT INTO PRODUCTOS VALUES
  ( 1, 'Mejillones en escabeche',                  'Moluscos',            '24 latas de 115 g',   52.80,  31.00),
  ( 2, 'Berberechos al natural 35/45',             'Moluscos',            '24 latas de 120 g',  118.00,  72.00),
  ( 3, 'Zamburiñas en salsa de vieira',            'Moluscos',            '24 latas de 111 g',   64.00,  38.00),
  ( 4, 'Navajas al natural',                       'Moluscos',            '24 latas de 120 g',   96.00,  60.00),
  ( 5, 'Almejas al natural',                       'Moluscos',            '24 latas de 120 g',  132.00,  84.00),
  ( 6, 'Pulpo en aceite de oliva',                 'Cefalópodos',         '24 latas de 111 g',   98.00,  60.00),
  ( 7, 'Calamares en su tinta',                    'Cefalópodos',         '24 latas de 111 g',   46.00,  27.00),
  ( 8, 'Chipirones rellenos',                      'Cefalópodos',         '24 latas de 111 g',   58.00,  35.00),
  ( 9, 'Sardinillas en aceite de oliva',           'Pescados',            '24 latas de 90 g',    42.00,  24.00),
  (10, 'Xoubas en escabeche',                      'Pescados',            '24 latas de 90 g',    45.00,  26.00),
  (11, 'Bonito del norte en aceite de oliva',      'Pescados',            '24 latas de 112 g',   86.00,  55.00),
  (12, 'Ventresca de bonito',                      'Pescados',            '24 latas de 112 g',  148.00,  95.00),
  (13, 'Atún claro en aceite de oliva',            'Pescados',            '24 latas de 112 g',   39.00,  24.00),
  (14, 'Huevas de merluza',                        'Pescados',            '24 latas de 120 g',   54.00,  32.00),
  (15, 'Caballa en aceite de oliva',               'Pescados',            '24 latas de 120 g',   38.00,  22.00),
  (16, 'Pack degustación Rías Baixas',             'Packs y regalo',      '10 packs de 6 latas', 165.00,  95.00),
  (17, 'Estuche gourmet de regalo',                'Packs y regalo',      '6 estuches',          220.00, 130.00),
  (18, 'Lote de Navidad para empresas',            'Packs y regalo',      '4 lotes',             340.00, 205.00),
  (19, 'Mejillón en escabeche, formato hostelería','Formato hostelería',  '6 latas de 1 kg',     72.00,  44.00),
  (20, 'Pulpo en aceite, formato hostelería',      'Formato hostelería',  '6 latas de 1 kg',    165.00, 105.00),
  (21, 'Bonito del norte, formato hostelería',     'Formato hostelería',  '6 latas de 1,8 kg',  118.00,  76.00),
  (22, 'Berberecho, formato hostelería',           'Formato hostelería',  '6 latas de 1 kg',     96.00,  60.00),
  (23, 'Sardinilla, formato hostelería',           'Formato hostelería',  '6 latas de 1 kg',     58.00,  34.00),
  (24, 'Zamburiña, formato hostelería',            'Formato hostelería',  '6 latas de 1 kg',     84.00,  50.00);


/* ---------------------------------------------------------------------------
   3. CLIENTES (1.525)
      · 60 % clientes históricos (alta antes del periodo), 40 % nuevos.
      · Altas internacionales recientes: sobre todo vía Distribuidor (importadores).
      · Altas de este mes: pico del canal Feria + 25 altas extra.
--------------------------------------------------------------------------- */
CREATE OR REPLACE TABLE CLIENTES AS
WITH base AS (
  SELECT
    ROW_NUMBER() OVER (ORDER BY SEQ4()) AS id,
    UNIFORM(1, 100, RANDOM())           AS r_region,
    UNIFORM(1, 100, RANDOM())           AS r_seg,
    UNIFORM(1, 100, RANDOM())           AS r_canal,
    UNIFORM(1, 100, RANDOM())           AS r_nuevo,
    UNIFORM(0, 5, RANDOM())             AS r_ciudad,
    UNIFORM(0, 1000000, RANDOM())       AS r_fecha
  FROM TABLE(GENERATOR(ROWCOUNT => 1525))
),
atributos AS (
  SELECT
    id,
    r_canal,
    CASE WHEN r_region <= 30 THEN 1 WHEN r_region <= 52 THEN 2 WHEN r_region <= 68 THEN 3
         WHEN r_region <= 80 THEN 4 WHEN r_region <= 90 THEN 5 ELSE 6 END       AS region_id,
    CASE WHEN r_seg <= 40 THEN 'Tienda gourmet' WHEN r_seg <= 75 THEN 'Hostelería'
         WHEN r_seg <= 92 THEN 'Distribuidor' ELSE 'Gran cuenta' END             AS segmento,
    r_ciudad,
    CASE
      WHEN id > 1500     THEN DATEADD('day', MOD(r_fecha, $dias_mes), $inicio_mes)
      WHEN r_nuevo <= 60 THEN DATEADD('day', -1 - MOD(r_fecha, 1095), $fecha_inicio)
      ELSE                    DATEADD('day', MOD(r_fecha, $ndias), $fecha_inicio)
    END                                                                          AS fecha_alta
  FROM base
),
con_nombre AS (
  SELECT
    a.*,
    GET(CASE region_id
          WHEN 1 THEN ARRAY_CONSTRUCT('Vigo','A Coruña','Santiago de Compostela','Pontevedra','Ourense','Lugo')
          WHEN 2 THEN ARRAY_CONSTRUCT('Madrid','Valladolid','Toledo','Salamanca','Segovia','Cáceres')
          WHEN 3 THEN ARRAY_CONSTRUCT('Barcelona','Valencia','Zaragoza','Palma','Alicante','Girona')
          WHEN 4 THEN ARRAY_CONSTRUCT('Sevilla','Málaga','Granada','Cádiz','Murcia','Las Palmas de Gran Canaria')
          WHEN 5 THEN ARRAY_CONSTRUCT('Oviedo','Gijón','Santander','Bilbao','San Sebastián','Pamplona')
          ELSE        ARRAY_CONSTRUCT('Oporto','Lisboa','París','Burdeos','Londres','Ciudad de México')
        END, r_ciudad::INT)::VARCHAR                                                AS ciudad,
    (GET(CASE segmento
           WHEN 'Tienda gourmet' THEN ARRAY_CONSTRUCT('Delicatessen','Ultramarinos','Colmado','Despensa','Vinoteca',
                                                      'Tienda Gourmet','Charcutería','Mercado','Ultramar','Bodega')
           WHEN 'Hostelería'     THEN ARRAY_CONSTRUCT('Restaurante','Taberna','Mesón','Marisquería','Pulpería',
                                                      'Gastrobar','Hotel','Casa de Comidas','Bar','Asador')
           WHEN 'Distribuidor'   THEN ARRAY_CONSTRUCT('Distribuciones','Comercial','Alimentación','Cash',
                                                      'Suministros Hosteleros','Almacenes','Logística Alimentaria',
                                                      'Importaciones','Gourmet Selección','Provisiones')
           ELSE                       ARRAY_CONSTRUCT('Supermercados','Hipermercados','Grupo','Cadena','Mercados',
                                                      'Autoservicios','Superalimentación','Hipercentro','Economatos',
                                                      'Cooperativa')
         END, MOD(id, 10)::INT)::VARCHAR
     || ' ' ||
     GET(ARRAY_CONSTRUCT(
           'Atlántico','Arousa','Rías Baixas','O Grove','Cambados','Fisterra','Costa da Morte','Miño','Sil','Ulla',
           'Barbanza','Cíes','Ons','Sálvora','Ortigueira','As Mariñas','Bergantiños','O Morrazo','Lérez','Tambre',
           'Cantábrico','Mediterráneo','Retiro','Castellana','Triana','Albaicín','Ebro','Duero','Tajo','Guadalquivir',
           'Montjuïc','Turia','Alhambra','Giralda','Sierra','Vega','Ribera','Prado','Mirador','Horizonte',
           'Aurora','Faro','Puerto','Lonja','Muelle','Marea','Brisa','Ancla','Timón','Velero',
           'Gaviota','Caracola','Coral','Perla','Alameda','Plaza Mayor','La Esquina','El Rincón','San Juan','Santiago',
           'San Marcos','El Carmen','La Paz','Los Arcos','La Fuente','El Pilar','La Merced','Las Flores','El Olivo','La Encina',
           'Los Pinos','El Roble','La Ermita','El Molino','La Torre','El Castillo','La Estrella','El Sol','La Luna','El Mar'),
         MOD(FLOOR(id / 10), 80)::INT)::VARCHAR)                                    AS nombre_base
  FROM atributos a
)
SELECT
  id::NUMBER(10,0) AS CLIENTE_ID,
  IFF(ROW_NUMBER() OVER (PARTITION BY nombre_base ORDER BY id) > 1,
      nombre_base || ' (' || ciudad || ')', nombre_base)::VARCHAR                 AS NOMBRE_CLIENTE,
  region_id::NUMBER(10,0)                                                         AS REGION_ID,
  ciudad::VARCHAR                                                                 AS CIUDAD,
  (CASE WHEN region_id < 6 THEN 'España'
        WHEN ciudad IN ('Oporto','Lisboa') THEN 'Portugal'
        WHEN ciudad IN ('París','Burdeos') THEN 'Francia'
        WHEN ciudad = 'Londres' THEN 'Reino Unido'
        ELSE 'México' END)::VARCHAR                                               AS PAIS,
  segmento::VARCHAR                                                               AS SEGMENTO,
  (CASE
     WHEN id > 1500 THEN 'Feria'
     WHEN fecha_alta >= $inicio_mes THEN
       CASE WHEN r_canal <= 45 THEN 'Feria' WHEN r_canal <= 70 THEN 'Web'
            WHEN r_canal <= 90 THEN 'Comercial directo' ELSE 'Distribuidor' END
     WHEN region_id = 6 AND fecha_alta >= DATEADD('quarter', -1, $inicio_trimestre) THEN
       CASE WHEN r_canal <= 55 THEN 'Distribuidor' WHEN r_canal <= 75 THEN 'Web'
            WHEN r_canal <= 90 THEN 'Comercial directo' ELSE 'Feria' END
     ELSE
       CASE WHEN r_canal <= 35 THEN 'Web' WHEN r_canal <= 65 THEN 'Comercial directo'
            WHEN r_canal <= 85 THEN 'Distribuidor' ELSE 'Feria' END
   END)::VARCHAR                                                                  AS CANAL_ALTA,
  fecha_alta::DATE                                                                AS FECHA_ALTA
FROM con_nombre;

-- La gran cadena de Sur que deja de comprar
UPDATE CLIENTES
   SET NOMBRE_CLIENTE = 'Supermercados Hispalis',
       REGION_ID      = 4,
       CIUDAD         = 'Sevilla',
       PAIS           = 'España',
       SEGMENTO       = 'Gran cuenta',
       CANAL_ALTA     = 'Comercial directo',
       FECHA_ALTA     = DATEADD('year', -3, $fecha_inicio)
 WHERE CLIENTE_ID = 1;

COMMENT ON TABLE CLIENTES IS 'Clientes de Conservas Ardora (nombres ficticios)';
COMMENT ON COLUMN CLIENTES.CLIENTE_ID     IS 'Identificador del cliente';
COMMENT ON COLUMN CLIENTES.NOMBRE_CLIENTE IS 'Nombre comercial del cliente (ficticio)';
COMMENT ON COLUMN CLIENTES.REGION_ID      IS 'Región comercial del cliente; enlaza con REGIONES.REGION_ID';
COMMENT ON COLUMN CLIENTES.CIUDAD         IS 'Ciudad del cliente';
COMMENT ON COLUMN CLIENTES.PAIS           IS 'País del cliente';
COMMENT ON COLUMN CLIENTES.SEGMENTO       IS 'Tipo de cliente: Tienda gourmet, Hostelería, Distribuidor o Gran cuenta (cadenas de supermercados)';
COMMENT ON COLUMN CLIENTES.CANAL_ALTA     IS 'Canal por el que se captó al cliente: Web, Comercial directo, Distribuidor o Feria';
COMMENT ON COLUMN CLIENTES.FECHA_ALTA     IS 'Fecha en la que el cliente se dio de alta. Usar para contar altas por periodo';


/* ---------------------------------------------------------------------------
   4. PEDIDOS (≈ 55.000-65.000)
      Una línea por pedido. La región del pedido es la del cliente.
--------------------------------------------------------------------------- */
CREATE OR REPLACE TABLE PEDIDOS AS
WITH dias AS (
  SELECT fecha FROM (
    SELECT DATEADD('day', ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1, $fecha_inicio) AS fecha
    FROM TABLE(GENERATOR(ROWCOUNT => 800))
  )
  WHERE fecha <= $fecha_fin
),
candidatos AS (
  SELECT
    d.fecha,
    UNIFORM(2, 1525, RANDOM())                 AS cliente_id,
    ZIPF(1, 18, RANDOM())                      AS rango_producto,
    UNIFORM(0::FLOAT, 1::FLOAT, RANDOM())      AS r_acepta,
    UNIFORM(1, 100, RANDOM())                  AS r_canal,
    UNIFORM(1, 100, RANDOM())                  AS r_estado,
    UNIFORM(1, 100, RANDOM())                  AS r_hosteleria,
    UNIFORM(1, 100, RANDOM())                  AS r_navidad,
    UNIFORM(1, 6, RANDOM())                    AS cant_tienda,
    UNIFORM(2, 10, RANDOM())                   AS cant_hosteleria,
    UNIFORM(10, 60, RANDOM())                  AS cant_distribuidor,
    UNIFORM(30, 150, RANDOM())                 AS cant_gran_cuenta,
    UNIFORM(0, 5, RANDOM())                    AS desc_tienda,
    UNIFORM(0, 8, RANDOM())                    AS desc_hosteleria,
    UNIFORM(8, 15, RANDOM())                   AS desc_distribuidor,
    UNIFORM(12, 20, RANDOM())                  AS desc_gran_cuenta
  FROM dias d
  CROSS JOIN TABLE(GENERATOR(ROWCOUNT => 300))
),
pedidos_normales AS (
  SELECT
    ca.fecha,
    ca.cliente_id,
    CASE
      -- la hostelería compra sobre todo formatos grandes
      WHEN c.SEGMENTO = 'Hostelería' AND ca.r_hosteleria <= 55 THEN 19 + MOD(ca.r_hosteleria, 6)
      -- campaña de Navidad: lotes y estuches de regalo
      WHEN MONTH(ca.fecha) IN (11, 12) AND c.SEGMENTO <> 'Hostelería' AND ca.r_navidad <= 18
        THEN IFF(ca.r_navidad <= 10, 18, 17)
      -- resto: catálogo de lata pequeña por popularidad (mejillones, sardinillas y atún primero)
      ELSE GET(ARRAY_CONSTRUCT(1,9,13,7,6,11,2,15,10,3,16,8,14,4,12,5,17,18),
               (ca.rango_producto - 1)::INT)::INT
    END                                                                           AS producto_id,
    CASE c.SEGMENTO WHEN 'Tienda gourmet' THEN ca.cant_tienda
                    WHEN 'Hostelería'     THEN ca.cant_hosteleria
                    WHEN 'Distribuidor'   THEN ca.cant_distribuidor
                    ELSE ca.cant_gran_cuenta END                                  AS cantidad,
    CASE c.SEGMENTO WHEN 'Tienda gourmet' THEN ca.desc_tienda
                    WHEN 'Hostelería'     THEN ca.desc_hosteleria
                    WHEN 'Distribuidor'   THEN ca.desc_distribuidor
                    ELSE ca.desc_gran_cuenta END                                  AS descuento_pct,
    CASE
      WHEN c.REGION_ID = 6 AND ca.fecha >= $inicio_trimestre AND ca.r_canal <= 40 THEN 'Distribuidor'
      WHEN c.SEGMENTO = 'Tienda gourmet' THEN
        CASE WHEN ca.r_canal <= 50 THEN 'Web' WHEN ca.r_canal <= 80 THEN 'Comercial directo' ELSE 'Distribuidor' END
      WHEN c.SEGMENTO = 'Hostelería' THEN
        CASE WHEN ca.r_canal <= 20 THEN 'Web' WHEN ca.r_canal <= 60 THEN 'Comercial directo' ELSE 'Distribuidor' END
      WHEN c.SEGMENTO = 'Distribuidor' THEN
        CASE WHEN ca.r_canal <= 15 THEN 'Web' ELSE 'Comercial directo' END
      ELSE 'Comercial directo'
    END                                                                           AS canal_venta,
    ca.r_estado
  FROM candidatos ca
  JOIN CLIENTES c ON c.CLIENTE_ID = ca.cliente_id
  WHERE c.FECHA_ALTA <= ca.fecha
    AND ca.r_acepta < 0.42
        -- estacionalidad: Navidad fuerte, verano con turismo, enero flojo
        * DECODE(MONTH(ca.fecha), 1,0.80, 2,0.85, 3,0.95, 4,1.00, 5,0.95, 6,1.00,
                                  7,1.05, 8,0.95, 9,0.95, 10,1.00, 11,1.15, 12,1.30)
        -- fines de semana casi sin pedidos
        * IFF(DAYOFWEEKISO(ca.fecha) >= 6, 0.30, 1.00)
        -- historia: Internacional acelera, Sur se enfría
        * CASE
            WHEN c.REGION_ID = 6 AND ca.fecha >= $inicio_trimestre                         THEN 1.25
            WHEN c.REGION_ID = 6 AND ca.fecha >= DATEADD('quarter', -1, $inicio_trimestre) THEN 1.08
            WHEN c.REGION_ID = 4 AND ca.fecha >= $inicio_trimestre                         THEN 0.95
            ELSE 1.00
          END
),
pedidos_hispalis AS (
  -- Supermercados Hispalis: pedidos grandes hasta ~3 semanas antes del trimestre actual
  SELECT
    d.fecha,
    1                                                                AS cliente_id,
    GET(ARRAY_CONSTRUCT(1,9,11,13,6,16), UNIFORM(0, 5, RANDOM()))::INT AS producto_id,
    UNIFORM(100, 250, RANDOM())                                      AS cantidad,
    18                                                               AS descuento_pct,
    'Comercial directo'                                              AS canal_venta,
    UNIFORM(1, 100, RANDOM())                                        AS r_estado
  FROM dias d
  WHERE d.fecha < DATEADD('day', -20, $inicio_trimestre)
    AND DAYOFWEEKISO(d.fecha) <= 5
    AND UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) < 0.45
),
todos AS (
  SELECT fecha, cliente_id, producto_id, cantidad, descuento_pct, canal_venta, r_estado FROM pedidos_normales
  UNION ALL
  SELECT fecha, cliente_id, producto_id, cantidad, descuento_pct, canal_venta, r_estado FROM pedidos_hispalis
)
SELECT
  (100000 + ROW_NUMBER() OVER (ORDER BY t.fecha, t.cliente_id, t.producto_id))::NUMBER(10,0) AS PEDIDO_ID,
  t.fecha::DATE                                                                  AS FECHA_PEDIDO,
  t.cliente_id::NUMBER(10,0)                                                     AS CLIENTE_ID,
  t.producto_id::NUMBER(10,0)                                                    AS PRODUCTO_ID,
  t.canal_venta::VARCHAR                                                         AS CANAL_VENTA,
  t.cantidad::NUMBER(10,0)                                                       AS CAJAS,
  p.PRECIO_CAJA_EUR                                                              AS PRECIO_CAJA_EUR,
  t.descuento_pct::NUMBER(5,2)                                                   AS DESCUENTO_PCT,
  ROUND(t.cantidad * p.PRECIO_CAJA_EUR, 2)::NUMBER(14,2)                         AS IMPORTE_BRUTO_EUR,
  ROUND(t.cantidad * p.PRECIO_CAJA_EUR * (1 - t.descuento_pct / 100), 2)::NUMBER(14,2) AS IMPORTE_NETO_EUR,
  ROUND(t.cantidad * p.COSTE_CAJA_EUR, 2)::NUMBER(14,2)                          AS COSTE_EUR,
  (CASE WHEN t.r_estado <= 92 THEN 'Completado'
        WHEN t.r_estado <= 97 THEN 'Devuelto'
        ELSE 'Cancelado' END)::VARCHAR                                           AS ESTADO
FROM todos t
JOIN PRODUCTOS p ON p.PRODUCTO_ID = t.producto_id;

COMMENT ON TABLE PEDIDOS IS 'Pedidos de clientes (una línea por pedido). La región del pedido es la del cliente (CLIENTES.REGION_ID). Los ingresos se calculan solo con ESTADO = ''Completado''.';
COMMENT ON COLUMN PEDIDOS.PEDIDO_ID         IS 'Identificador del pedido';
COMMENT ON COLUMN PEDIDOS.FECHA_PEDIDO      IS 'Fecha en la que se realizó el pedido';
COMMENT ON COLUMN PEDIDOS.CLIENTE_ID        IS 'Cliente que realiza el pedido; enlaza con CLIENTES.CLIENTE_ID';
COMMENT ON COLUMN PEDIDOS.PRODUCTO_ID       IS 'Producto pedido; enlaza con PRODUCTOS.PRODUCTO_ID';
COMMENT ON COLUMN PEDIDOS.CANAL_VENTA       IS 'Canal por el que entró el pedido: Web, Comercial directo o Distribuidor';
COMMENT ON COLUMN PEDIDOS.CAJAS             IS 'Número de cajas pedidas';
COMMENT ON COLUMN PEDIDOS.PRECIO_CAJA_EUR   IS 'Precio de tarifa por caja en euros, sin IVA';
COMMENT ON COLUMN PEDIDOS.DESCUENTO_PCT     IS 'Descuento aplicado, en porcentaje (0-100)';
COMMENT ON COLUMN PEDIDOS.IMPORTE_BRUTO_EUR IS 'Cajas x precio de tarifa, antes de descuento, sin IVA';
COMMENT ON COLUMN PEDIDOS.IMPORTE_NETO_EUR  IS 'Importe tras descuento, sin IVA. Ingresos = SUM(IMPORTE_NETO_EUR) con ESTADO = ''Completado''';
COMMENT ON COLUMN PEDIDOS.COSTE_EUR         IS 'Coste de producción de lo vendido, en euros. Margen = IMPORTE_NETO_EUR - COSTE_EUR';
COMMENT ON COLUMN PEDIDOS.ESTADO            IS 'Completado, Devuelto o Cancelado. Devueltos y cancelados no cuentan como ingresos';


/* ---------------------------------------------------------------------------
   5. OBJETIVOS por región y trimestre
      Objetivo = ingresos del mismo trimestre del año anterior + 10 %
      (los 4 primeros trimestres, sin histórico, ≈ lo realizado).
--------------------------------------------------------------------------- */
CREATE OR REPLACE TABLE OBJETIVOS AS
WITH trimestres AS (
  SELECT DATEADD('quarter', ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1, $fecha_inicio) AS trimestre
  FROM TABLE(GENERATOR(ROWCOUNT => 8))
),
ingresos AS (
  SELECT c.REGION_ID, DATE_TRUNC('quarter', p.FECHA_PEDIDO) AS trimestre, SUM(p.IMPORTE_NETO_EUR) AS ingresos
  FROM PEDIDOS p
  JOIN CLIENTES c ON c.CLIENTE_ID = p.CLIENTE_ID
  WHERE p.ESTADO = 'Completado'
  GROUP BY 1, 2
),
rejilla AS (
  SELECT r.REGION_ID, t.trimestre, i.ingresos,
         LAG(i.ingresos, 4) OVER (PARTITION BY r.REGION_ID ORDER BY t.trimestre) AS ingresos_hace_un_anio
  FROM REGIONES r
  CROSS JOIN trimestres t
  LEFT JOIN ingresos i ON i.REGION_ID = r.REGION_ID AND i.trimestre = t.trimestre
)
SELECT
  REGION_ID::NUMBER(10,0)                                  AS REGION_ID,
  trimestre::DATE                                          AS TRIMESTRE_INICIO,
  (YEAR(trimestre) || '-T' || QUARTER(trimestre))::VARCHAR AS TRIMESTRE,
  ROUND(COALESCE(ingresos_hace_un_anio * 1.10,
                 ingresos * UNIFORM(0.95::FLOAT, 1.08::FLOAT, RANDOM())), -3)::NUMBER(14,0) AS OBJETIVO_INGRESOS_EUR
FROM rejilla;

COMMENT ON TABLE OBJETIVOS IS 'Objetivo de ingresos netos por región y trimestre natural (trimestre completo)';
COMMENT ON COLUMN OBJETIVOS.REGION_ID             IS 'Región; enlaza con REGIONES.REGION_ID';
COMMENT ON COLUMN OBJETIVOS.TRIMESTRE_INICIO      IS 'Primer día del trimestre natural';
COMMENT ON COLUMN OBJETIVOS.TRIMESTRE             IS 'Etiqueta del trimestre, p. ej. 2026-T4';
COMMENT ON COLUMN OBJETIVOS.OBJETIVO_INGRESOS_EUR IS 'Objetivo de ingresos netos del trimestre completo, en euros';


/* ---------------------------------------------------------------------------
   6. Vista desnormalizada (facilita las preguntas en lenguaje natural)
--------------------------------------------------------------------------- */
CREATE OR REPLACE VIEW V_VENTAS_DETALLE
  COMMENT = 'Pedidos con cliente, región y producto. Ingresos = SUM(IMPORTE_NETO_EUR) con ESTADO = ''Completado'''
AS
SELECT
  p.PEDIDO_ID, p.FECHA_PEDIDO,
  DATE_TRUNC('month', p.FECHA_PEDIDO)   AS MES,
  DATE_TRUNC('quarter', p.FECHA_PEDIDO) AS TRIMESTRE_INICIO,
  r.REGION, c.PAIS, c.CIUDAD, c.NOMBRE_CLIENTE, c.SEGMENTO, c.CANAL_ALTA,
  pr.PRODUCTO, pr.CATEGORIA,
  p.CANAL_VENTA, p.CAJAS, p.PRECIO_CAJA_EUR, p.DESCUENTO_PCT,
  p.IMPORTE_BRUTO_EUR, p.IMPORTE_NETO_EUR, p.COSTE_EUR,
  p.IMPORTE_NETO_EUR - p.COSTE_EUR      AS MARGEN_EUR,
  p.ESTADO
FROM PEDIDOS p
JOIN CLIENTES  c  ON c.CLIENTE_ID   = p.CLIENTE_ID
JOIN REGIONES  r  ON r.REGION_ID    = c.REGION_ID
JOIN PRODUCTOS pr ON pr.PRODUCTO_ID = p.PRODUCTO_ID;


/* ---------------------------------------------------------------------------
   7. Rol de solo lectura para conectar Claude
      No conectes Claude con ACCOUNTADMIN: usa este rol.
--------------------------------------------------------------------------- */
CREATE ROLE IF NOT EXISTS CLAUDE_DATA_LECTOR COMMENT = 'Lectura de DEMO_CLAUDE_DATA para Claude Data';
GRANT ROLE CLAUDE_DATA_LECTOR TO ROLE SYSADMIN;

GRANT USAGE ON WAREHOUSE CLAUDE_DATA_WH                      TO ROLE CLAUDE_DATA_LECTOR;
GRANT USAGE ON DATABASE  DEMO_CLAUDE_DATA                    TO ROLE CLAUDE_DATA_LECTOR;
GRANT USAGE ON SCHEMA    DEMO_CLAUDE_DATA.VENTAS             TO ROLE CLAUDE_DATA_LECTOR;
GRANT SELECT ON ALL TABLES IN SCHEMA DEMO_CLAUDE_DATA.VENTAS TO ROLE CLAUDE_DATA_LECTOR;
GRANT SELECT ON ALL VIEWS  IN SCHEMA DEMO_CLAUDE_DATA.VENTAS TO ROLE CLAUDE_DATA_LECTOR;

-- Te asigna el rol a ti (el usuario que ejecuta el script)
SET mi_usuario = CURRENT_USER();
GRANT ROLE CLAUDE_DATA_LECTOR TO USER IDENTIFIER($mi_usuario);


/* ---------------------------------------------------------------------------
   8. Comprobaciones rápidas (mira los resultados antes de grabar)
--------------------------------------------------------------------------- */

-- 8.1 Volumen por tabla
SELECT 'REGIONES' AS tabla, COUNT(*) AS filas FROM REGIONES
UNION ALL SELECT 'PRODUCTOS', COUNT(*) FROM PRODUCTOS
UNION ALL SELECT 'CLIENTES',  COUNT(*) FROM CLIENTES
UNION ALL SELECT 'PEDIDOS',   COUNT(*) FROM PEDIDOS
UNION ALL SELECT 'OBJETIVOS', COUNT(*) FROM OBJETIVOS;

-- 8.2 El hallazgo principal: trimestre en curso vs mismo periodo del trimestre anterior
WITH params AS (
  SELECT DATE_TRUNC('quarter', MAX(FECHA_PEDIDO)) AS ini_act, MAX(FECHA_PEDIDO) AS fin_act FROM PEDIDOS
)
SELECT
  v.REGION,
  ROUND(SUM(IFF(v.FECHA_PEDIDO BETWEEN pr.ini_act AND pr.fin_act, v.IMPORTE_NETO_EUR, 0))) AS ingresos_trimestre_actual,
  ROUND(SUM(IFF(v.FECHA_PEDIDO BETWEEN DATEADD('quarter', -1, pr.ini_act)
                                   AND DATEADD('quarter', -1, pr.fin_act), v.IMPORTE_NETO_EUR, 0))) AS ingresos_mismo_periodo_anterior,
  ROUND(100 * (ingresos_trimestre_actual / NULLIF(ingresos_mismo_periodo_anterior, 0) - 1), 1) AS variacion_pct
FROM V_VENTAS_DETALLE v
CROSS JOIN params pr
WHERE v.ESTADO = 'Completado'
GROUP BY v.REGION
ORDER BY variacion_pct DESC;

-- 8.3 Altas de clientes por canal: este mes vs el mes anterior (a la misma fecha)
SELECT
  CANAL_ALTA,
  COUNT_IF(FECHA_ALTA BETWEEN $inicio_mes AND $fecha_fin) AS altas_este_mes,
  COUNT_IF(FECHA_ALTA BETWEEN DATEADD('month', -1, $inicio_mes)
                          AND DATEADD('month', -1, $fecha_fin)) AS altas_mes_anterior
FROM CLIENTES
GROUP BY CANAL_ALTA
ORDER BY altas_este_mes DESC;

-- 8.4 Por qué hace falta certificar: ingresos "ingenuos" vs ingresos correctos
SELECT
  ROUND(SUM(IMPORTE_NETO_EUR))                                AS suma_sin_filtrar_estado,
  ROUND(SUM(IFF(ESTADO = 'Completado', IMPORTE_NETO_EUR, 0))) AS ingresos_correctos,
  ROUND(100 * (1 - ingresos_correctos / suma_sin_filtrar_estado), 1) AS sobreestimacion_pct
FROM PEDIDOS
WHERE FECHA_PEDIDO >= $inicio_trimestre;
