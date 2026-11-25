<p align="center">
  <img src="assets/logo-conservas-ardora.jpg" alt="Logo de Conservas Ardora, A Illa de Arousa" width="320">
</p>

# Demo de Claude Data con Snowflake · Conservas Ardora

Material para enseñar **Claude Data** sobre una base de datos de ejemplo en **Snowflake**. Incluye scripts SQL que generan los datos, el modelo de datos, el guion de la demo y las consultas para certificar.

La empresa de los datos es **Conservas Ardora, S.L.**, una conservera ficticia fundada en 1945 en **A Illa de Arousa (Pontevedra)**, en plena ría de Arousa, que vende conservas de marisco y pescado de las Rías Baixas a tiendas gourmet, hostelería, distribuidores y cadenas de supermercados de España y del extranjero.

> Todos los datos, nombres de clientes y personas son ficticios y se generan al azar en cada ejecución.

---

## Qué es Claude Data

Claude Data (antes *Claude Dashboards*) convierte preguntas sobre los datos de una empresa en paneles, historias de datos y vídeos cortos narrados. Te conectas a un almacén de datos (Snowflake, BigQuery, Databricks, Redshift o ClickHouse) o a otra app, preguntas en lenguaje natural y Claude escribe y ejecuta el SQL. Cada gráfico muestra su consulta y cuándo se actualizó por última vez.

Documentación oficial:
- [Get started with Claude Data](https://support.claude.com/en/articles/17454700-get-started-with-claude-data)
- [Dashboards and Motion](https://claude.com/resources/articles/dashboards-and-motion)
- [Introducing Claude Whiteboards, Claude Sheets, and Claude Data](https://claude.com/resources/articles/sheets-whiteboards-data)

## Requisitos

| Necesitas | Detalle |
| --- | --- |
| Un plan de pago de Claude | Claude Data está en Pro, Max, Ultra, Team y Enterprise. En Enterprise lo activa un administrador. |
| Una cuenta de Snowflake | Con una [cuenta de prueba](https://signup.snowflake.com/) basta. El script usa un warehouse X-Small que se apaga a los 60 s. |
| Permisos de ACCOUNTADMIN en Snowflake | Solo para ejecutar el script de creación. Claude se conecta con un rol de solo lectura. |

## Estructura del repositorio

```
.
├── README.md
├── assets/
│   └── logo-conservas-ardora.jpg      # Logo de la conservera
├── sql/
│   ├── 01_crear_demo.sql              # Crea warehouse, base de datos, tablas, vista y rol de lectura
│   ├── 02_consultas_certificadas.sql  # Consultas para certificar en Claude Data
│   └── 99_limpieza.sql                # Borra todo lo creado
└── docs/
    ├── modelo-de-datos.md             # Tablas, columnas y relaciones
    └── guion-demo.md                  # Paso a paso de la demo, con los prompts
```

## Puesta en marcha

### 1. Crea los datos en Snowflake

1. En Snowsight, abre **Projects › Worksheets › + › SQL Worksheet**.
2. Pega [`sql/01_crear_demo.sql`](sql/01_crear_demo.sql) y pulsa **Run All**.
3. Comprueba los resultados del apartado 8 del script: volumen de las tablas, variación por región, altas por canal y la sobreestimación al no filtrar por estado.

Se crea lo siguiente:

| Objeto | Nombre |
| --- | --- |
| Warehouse | `CLAUDE_DATA_WH` (X-Small, se apaga a los 60 s) |
| Base de datos y esquema | `DEMO_CLAUDE_DATA.VENTAS` |
| Tablas | `REGIONES`, `PRODUCTOS`, `CLIENTES`, `PEDIDOS`, `OBJETIVOS` |
| Vista | `V_VENTAS_DETALLE` |
| Rol de solo lectura | `CLAUDE_DATA_LECTOR`, que se asigna al usuario que ejecuta el script |

> **Las fechas son relativas.** Se generan 8 trimestres que terminan **ayer**. Vuelve a ejecutar el script el día antes de grabar o presentar para que «este trimestre» y «este mes» tengan datos frescos. El script borra y recrea la base de datos cada vez. No lo ejecutes el día 1 de un trimestre, porque el trimestre en curso quedaría vacío.

### 2. Conecta Snowflake a Claude

Conecta tu cuenta de Snowflake desde Claude como almacén de datos. Usa estos valores:

| Campo | Valor |
| --- | --- |
| Rol | `CLAUDE_DATA_LECTOR` (no uses `ACCOUNTADMIN`) |
| Warehouse | `CLAUDE_DATA_WH` |
| Base de datos y esquema | `DEMO_CLAUDE_DATA` · `VENTAS` |

Claude trabaja con los permisos de la conexión. Con este rol solo puede leer la base de datos de la demo.

### 3. Haz la demo

Sigue [`docs/guion-demo.md`](docs/guion-demo.md).

### 4. Certifica las consultas clave

[`sql/02_consultas_certificadas.sql`](sql/02_consultas_certificadas.sql) trae tres consultas, cada una con instrucciones para Claude:

- **C1:** ingresos netos por región y trimestre.
- **C2:** ingresos frente a objetivo.
- **C3:** margen bruto por categoría y mes.

Para certificar una consulta, abre la de un gráfico, edítala, activa **Certificar consulta**, añade las instrucciones (una por línea) y pulsa **Probar** y después **Publicar**. Las consultas certificadas están en beta.

### 5. Limpieza

Cuando termines, ejecuta [`sql/99_limpieza.sql`](sql/99_limpieza.sql). Borra la base de datos, el warehouse y el rol, y no se puede deshacer.

## La historia que esconden los datos

Los datos están preparados para que Claude encuentre algo interesante:

| Hallazgo | Cómo aparece |
| --- | --- |
| Casi todos los mercados crecen en el trimestre en curso | ≈ +8-12 % frente al mismo periodo del trimestre anterior |
| **Sur cae** | ≈ -15 %: la cadena *Supermercados Hispalis* (Sevilla), su mayor cliente, dejó de comprar unas semanas antes de empezar el trimestre |
| **Internacional es el que más crece** | ≈ +30 %, empujado por importadores (canal *Distribuidor*) de Portugal, Francia, Reino Unido y México |
| Pico de **altas por el canal Feria** este mes | Ideal para la pregunta «¿cómo se comparan las altas de este mes por canal con las del mes pasado?» |
| Campaña de Navidad | Los lotes y estuches de regalo suben en noviembre y diciembre |
| ~8 % de pedidos devueltos o cancelados | Si se suma el importe sin filtrar `ESTADO = 'Completado'`, los ingresos salen inflados. Es el motivo para certificar consultas |
| Galicia es el mercado principal | ≈ 30 % de las ventas |

Los porcentajes son aproximados porque los datos cambian en cada ejecución.

## Licencia

[MIT](LICENSE)
