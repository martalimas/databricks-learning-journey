# Data Vault 2.0 — Demonstração Prática (Databricks)

> **Módulo:** Data Warehousing with Databricks — Path 8  
> **Tipo:** Notebook de demonstração  
> **Fonte de dados:** TPC-H (bronze) → silver (refined) → silver (Raw Vault) → gold (Business Views)

---

## Índice

1. [Objectivos e Conceitos-Chave](#1-objectivos-e-conceitos-chave)
2. [Setup do Ambiente](#2-setup-do-ambiente)
3. [Criar as Tabelas DV 2.0](#3-criar-as-tabelas-dv-20)
4. [ETL Process — Carregar o Data Vault](#4-etl-process--carregar-o-data-vault)
5. [Business Views (Camada Gold)](#5-business-views-camada-gold)
6. [Sample Queries](#6-sample-queries)
7. [Verification Steps](#7-verification-steps)
8. [Cleanup](#8-cleanup)
9. [Conclusão e Padrões a Memorizar](#9-conclusão-e-padrões-a-memorizar)

---

## 1. Objectivos e Conceitos-Chave

### O que este lab constrói

Um modelo Data Vault 2.0 completo em Databricks a partir dos dados TPC-H, com:
- **Hubs** para as entidades de negócio core (Customer, Order)
- **Links** para representar relações entre entidades
- **Satellites** para armazenar atributos descritivos e tracking histórico
- Uma **business layer** (gold) sobre o vault para suportar queries de end-users

### Conceitos-chave do DV 2.0

| Componente | Definição |
|-----------|-----------|
| **Hub** | Lista única de business keys com metadata associada |
| **Link** | Conecta Hubs para representar relações |
| **Satellite** | Armazena atributos descritivos de um Hub ou Link, permitindo tracking histórico |

> **Diferencial do DV 2.0:** uso de **hash keys** (MD5) como chaves primárias — em vez de surrogate keys inteiras — para performance e escalabilidade. Permitem geração determinística e paralela sem dependências de sequência.

---

## 2. Setup do Ambiente

```python
# Extrair o nome do catálogo a partir do email do utilizador
catalog_name = spark.sql("SELECT current_user()").collect()[0][0].split("@")[0]

silver_schema = "silver"

spark.sql(f"USE CATALOG {catalog_name}")
spark.sql(f"USE {silver_schema}")
```

---

## 3. Criar as Tabelas DV 2.0

### Convenções de nomenclatura

| Tipo | Prefixo | Exemplo |
|------|---------|---------|
| Hub | `H_` | `H_Customer`, `H_Order` |
| Link | `L_` | `L_Customer_Order` |
| Satellite | `S_` | `S_Customer`, `S_Order` |
| Business View | `BV_` | `BV_Customer_Order` |

---

### 3.1 Hubs

Os Hubs são **imutáveis** — só se fazem INSERTs, nunca UPDATEs.  
A hash key é gerada via MD5 da business key e serve de PK.

#### `H_Customer`

```sql
CREATE TABLE IF NOT EXISTS H_Customer (
    customer_hk    STRING    NOT NULL COMMENT 'MD5(customer_id)',  -- Hash key (PK)
    customer_id    INT       NOT NULL,                             -- Business Key
    load_timestamp TIMESTAMP NOT NULL,                             -- Data de ingestão
    record_source  STRING,                                         -- Origem do registo
    CONSTRAINT pk_h_customer PRIMARY KEY (customer_hk)
);
```

#### `H_Order`

```sql
CREATE TABLE IF NOT EXISTS H_Order (
    order_hk       STRING    NOT NULL COMMENT 'MD5(order_id)',
    order_id       INT       NOT NULL,
    load_timestamp TIMESTAMP NOT NULL,
    record_source  STRING,
    CONSTRAINT pk_h_order PRIMARY KEY (order_hk)
);
```

> **Nota:** A PK é a **hash key** (STRING), não um BIGINT auto-gerado como no Kimball. Isso permite geração paralela e distribuída sem coordenação central.

---

### 3.2 Links

Os Links também são **imutáveis**. A hash key do Link é gerada via MD5 da concatenação das hash keys dos Hubs relacionados.

#### `L_Customer_Order`

```sql
CREATE TABLE IF NOT EXISTS L_Customer_Order (
    customer_order_hk STRING    NOT NULL COMMENT 'MD5(customer_hk||order_hk)',  -- Hash key composta
    customer_hk       STRING    NOT NULL,   -- FK → H_Customer
    order_hk          STRING    NOT NULL,   -- FK → H_Order
    load_timestamp    TIMESTAMP NOT NULL,
    record_source     STRING,
    CONSTRAINT pk_l_customer_order PRIMARY KEY (customer_order_hk)
);
```

> **Padrão da hash key do Link:** `MD5(hub1_hk || '||' || hub2_hk)` — concatenação com separador antes do hash.

---

### 3.3 Satellites

Os Satellites têm PK **composta**: `(hash_key_do_hub, load_timestamp)`.  
Incluem um campo `hash_diff` = MD5 de todas as colunas descritivas — usado para detectar alterações de forma eficiente.

#### `S_Customer`

```sql
CREATE TABLE IF NOT EXISTS S_Customer (
    customer_hk    STRING         NOT NULL,                                   -- FK → H_Customer
    hash_diff      STRING         NOT NULL COMMENT 'MD5 of all descriptive columns',  -- Detector de alterações
    name           STRING,
    address        STRING,
    nation_key     INT,
    phone          STRING,
    acct_bal       DECIMAL(12, 2),
    market_segment STRING,
    comment        STRING,
    load_timestamp TIMESTAMP      NOT NULL,
    record_source  STRING,
    CONSTRAINT pk_s_customer PRIMARY KEY (customer_hk, load_timestamp)  -- PK composta!
);
```

#### `S_Order` (estrutura análoga)

```sql
-- Colunas descritivas: order_status, total_price, order_date,
--                      order_priority, clerk, ship_priority, comment
-- PK: (order_hk, load_timestamp)
```

---

## 4. ETL Process — Carregar o Data Vault

O processo ETL segue sempre esta ordem:
```
1. Carregar Hubs  (entidades independentes)
2. Carregar Satellites dos Hubs
3. Carregar Links  (dependem dos Hubs já carregados)
```

---

### 4.1 Helper Functions (PySpark)

Todas as hash keys são geradas via `md5()` da biblioteca `pyspark.sql.functions`.

```python
from pyspark.sql.functions import md5, concat_ws, col, current_timestamp, lit

# Hash key do Hub Customer: MD5 da business key
def generate_customer_hash_keys(df):
    return df.withColumn(
        "customer_hk",
        md5(col("customer_id").cast("string"))
    )

# Hash key do Hub Order
def generate_order_hash_keys(df):
    return df.withColumn(
        "order_hk",
        md5(col("order_id").cast("string"))
    )

# Hash key do Link: MD5 da concatenação das hash keys dos dois Hubs
def generate_customer_order_hash_key(df):
    return df.withColumn(
        "customer_order_hk",
        md5(concat_ws("||", col("customer_hk"), col("order_hk")))
    )

# hash_diff do Satellite: MD5 de todas as colunas descritivas concatenadas
def generate_hash_diff(df, columns):
    return df.withColumn(
        "hash_diff",
        md5(concat_ws("||", *[col(c) for c in columns]))
    )
```

> **Porquê `concat_ws("||", ...)`?** O separador `||` evita colisões de hash quando os valores das colunas contêm strings que se poderiam "colar" de formas diferentes e produzir o mesmo MD5.

---

### 4.2 Carregar as Tabelas Refinadas (Silver)

Antes de alimentar o Data Vault, os dados passam por uma etapa de refinamento (rename + cast) em tabelas silver intermédias.

```python
from pyspark.sql.functions import col, to_date, current_timestamp

def etl_refined_customer():
    bronze_customer = spark.table("bronze.customer")
    refined_customer = bronze_customer.select(
        col("c_custkey").cast("int").alias("customer_id"),
        col("c_name").alias("name"),
        col("c_address").alias("address"),
        col("c_nationkey").cast("int").alias("nation_key"),
        col("c_phone").alias("phone"),
        col("c_acctbal").cast("decimal(12,2)").alias("acct_bal"),
        col("c_mktsegment").alias("market_segment"),
        col("c_comment").alias("comment")
    )
    refined_customer.write.mode("overwrite").saveAsTable("silver.refined_customer")

def etl_refined_orders():
    bronze_orders = spark.table("bronze.orders")
    refined_orders = bronze_orders.select(
        col("o_orderkey").cast("int").alias("order_id"),
        col("o_custkey").cast("int").alias("customer_id"),
        col("o_orderstatus").alias("order_status"),
        col("o_totalprice").cast("decimal(12,2)").alias("total_price"),
        to_date(col("o_orderdate"), "yyyy-MM-dd").alias("order_date"),
        col("o_orderpriority").alias("order_priority"),
        col("o_clerk").alias("clerk"),
        col("o_shippriority").cast("int").alias("ship_priority"),
        col("o_comment").alias("comment")
    )
    refined_orders.write.mode("overwrite").saveAsTable("silver.refined_orders")
```

---

### 4.3 Carregar o Hub Customer

```python
from pyspark.sql.functions import current_timestamp, lit

silver_customer_df = spark.sql("SELECT * FROM silver.refined_customer")

customer_hub_data = (
    generate_customer_hash_keys(silver_customer_df)
    .withColumn("load_timestamp", current_timestamp())
    .withColumn("record_source", lit("TPC-H"))
)

customer_hub_data.createOrReplaceTempView("customer_hub_stage")

spark.sql("""
MERGE INTO H_Customer AS target
USING customer_hub_stage AS source
ON target.customer_hk = source.customer_hk
WHEN NOT MATCHED THEN
    INSERT (customer_hk, customer_id, load_timestamp, record_source)
    VALUES (source.customer_hk, source.customer_id, source.load_timestamp, source.record_source)
""")
```

> **MERGE Hub = apenas INSERT.** Hubs são imutáveis — se a hash key já existe, não fazemos nada (`WHEN NOT MATCHED` only). Nunca há `WHEN MATCHED UPDATE` num Hub.

---

### 4.4 Carregar o Satellite Customer

O Satellite usa o `hash_diff` para detectar se os atributos mudaram. Se a combinação `(customer_hk, load_timestamp)` já existe, não insere.

```python
customer_sat_columns = ["name", "address", "nation_key", "phone", "acct_bal", "market_segment", "comment"]

customer_sat_data = generate_hash_diff(customer_hub_data, customer_sat_columns)
customer_sat_data.createOrReplaceTempView("customer_sat_stage")

spark.sql(f"""
MERGE INTO S_Customer AS target
USING customer_sat_stage AS source
ON target.customer_hk = source.customer_hk
AND target.load_timestamp = source.load_timestamp
WHEN NOT MATCHED THEN
    INSERT (customer_hk, hash_diff, {', '.join(customer_sat_columns)}, load_timestamp, record_source)
    VALUES (source.customer_hk, source.hash_diff, {', '.join([f'source.{col}' for col in customer_sat_columns])}, source.load_timestamp, source.record_source)
""")
```

> **MERGE Satellite = também apenas INSERT.** Os Satellites são append-only: cada versão nova é uma linha nova. O `hash_diff` permite detectar em queries se um registo mudou sem comparar coluna a coluna.

---

### 4.5 Carregar Hub e Satellite de Order

Mesmo padrão do Customer — Hub primeiro, depois Satellite.

```python
silver_orders_df = spark.sql("SELECT * FROM silver.refined_orders")

order_hub_data = (
    generate_order_hash_keys(silver_orders_df)
    .withColumn("load_timestamp", current_timestamp())
    .withColumn("record_source", lit("TPC-H"))
)
order_hub_data.createOrReplaceTempView("order_hub_stage")

# MERGE INTO H_Order (mesmo padrão do H_Customer)
spark.sql("""
MERGE INTO H_Order AS target
USING order_hub_stage AS source
ON target.order_hk = source.order_hk
WHEN NOT MATCHED THEN
    INSERT (order_hk, order_id, load_timestamp, record_source)
    VALUES (source.order_hk, source.order_id, source.load_timestamp, source.record_source)
""")

# Satellite de Order
order_sat_columns = ["order_status", "total_price", "order_date", "order_priority",
                     "clerk", "ship_priority", "comment"]
order_sat_data = generate_hash_diff(order_hub_data, order_sat_columns)
order_sat_data.createOrReplaceTempView("order_sat_stage")

spark.sql(f"""
MERGE INTO S_Order AS target
USING order_sat_stage AS source
ON target.order_hk = source.order_hk
AND target.load_timestamp = source.load_timestamp
WHEN NOT MATCHED THEN
    INSERT (order_hk, hash_diff, {', '.join(order_sat_columns)}, load_timestamp, record_source)
    VALUES (source.order_hk, source.hash_diff, {', '.join([f'source.{col}' for col in order_sat_columns])}, source.load_timestamp, source.record_source)
""")
```

---

### 4.6 Carregar o Link Customer-Order

**Ponto crítico:** o Link não gera as hash keys a partir dos dados de origem — usa as hash keys **já existentes nos Hubs**, resolvidas via JOIN.

```python
from pyspark.sql.functions import concat_ws

link_data = (
    silver_orders_df.alias("orders")
    # Resolver customer_hk via JOIN com H_Customer
    .join(spark.table("H_Customer").alias("hc"),
          on=[col("orders.customer_id") == col("hc.customer_id")],
          how="inner")
    # Resolver order_hk via JOIN com H_Order
    .join(spark.table("H_Order").alias("ho"),
          on=[col("orders.order_id") == col("ho.order_id")],
          how="inner")
    # Seleccionar apenas as hash keys já estabelecidas
    .select(
        col("hc.customer_hk").alias("customer_hk"),
        col("ho.order_hk").alias("order_hk")
    )
    # Criar a hash key combinada do Link
    .withColumn("customer_order_hk",
                md5(concat_ws("||", col("customer_hk"), col("order_hk"))))
    .withColumn("load_timestamp", current_timestamp())
    .withColumn("record_source", lit("TPC-H"))
)

link_data.createOrReplaceTempView("link_stage")

spark.sql("""
MERGE INTO L_Customer_Order AS target
USING link_stage AS source
ON target.customer_order_hk = source.customer_order_hk
WHEN NOT MATCHED THEN
    INSERT (customer_order_hk, customer_hk, order_hk, load_timestamp, record_source)
    VALUES (source.customer_order_hk, source.customer_hk, source.order_hk,
            source.load_timestamp, source.record_source)
""")
```

> **Regra importante:** O Link nunca recalcula as hash keys — vai **buscar aos Hubs** as keys já calculadas e persistidas. Isto garante consistência referencial.

---

## 5. Business Views (Camada Gold)

As Business Views vivem na camada **gold** e fazem o JOIN de todos os componentes do vault para expor uma interface simples aos utilizadores finais. Podem ser materializadas como tabelas se necessário.

```sql
CREATE OR REPLACE VIEW gold.BV_Customer_Order AS
SELECT
    hc.customer_id,
    sc.name           AS customer_name,
    sc.address        AS customer_address,
    ho.order_id,
    so.order_date,
    so.total_price,
    so.order_status
FROM H_Customer hc
JOIN S_Customer sc
    ON hc.customer_hk = sc.customer_hk          -- Hub → Satellite
JOIN L_Customer_Order lco
    ON hc.customer_hk = lco.customer_hk          -- Hub → Link
JOIN H_Order ho
    ON lco.order_hk = ho.order_hk                -- Link → Hub
JOIN S_Order so
    ON ho.order_hk = so.order_hk;               -- Hub → Satellite
```

> **Padrão de JOIN no DV:** `Hub → Satellite` (atributos) e `Hub → Link → Hub` (relações). As Business Views abstrai esta complexidade para os consumidores.

---

## 6. Sample Queries

### Query completa à Business View

```sql
SELECT * FROM gold.BV_Customer_Order;
```

### Total de vendas por cliente

```sql
SELECT
    customer_name,
    SUM(total_price) AS total_sales
FROM gold.BV_Customer_Order
GROUP BY customer_name
ORDER BY total_sales DESC;
```

---

## 7. Verification Steps

### Contagem de registos em todos os componentes

```sql
SELECT 'H_Customer'       AS table_name, COUNT(*) AS record_count FROM H_Customer
UNION ALL
SELECT 'H_Order',          COUNT(*) FROM H_Order
UNION ALL
SELECT 'L_Customer_Order', COUNT(*) FROM L_Customer_Order
UNION ALL
SELECT 'S_Customer',       COUNT(*) FROM S_Customer
UNION ALL
SELECT 'S_Order',          COUNT(*) FROM S_Order;
```

### Verificar integridade referencial do Link

Confirma que cada encomenda está associada a exactamente um cliente:

```sql
SELECT
    COUNT(*) AS total_orders,
    SUM(CASE WHEN customer_count = 1  THEN 1 ELSE 0 END) AS orders_with_one_customer,
    SUM(CASE WHEN customer_count != 1 THEN 1 ELSE 0 END) AS orders_with_multiple_customers
FROM (
    SELECT order_hk, COUNT(DISTINCT customer_hk) AS customer_count
    FROM L_Customer_Order
    GROUP BY order_hk
);
```

---

## 8. Cleanup

A ordem de DROP é **inversa** à ordem de criação: Satellites → Links → Hubs → Views.  
*(A `silver.refined_customer` não é apagada — será necessária no lab de Feature Store.)*

```sql
-- 1. Drop Satellites primeiro (dependem dos Hubs)
DROP TABLE IF EXISTS S_Customer;
DROP TABLE IF EXISTS S_Order;

-- 2. Drop o Link
DROP TABLE IF EXISTS L_Customer_Order;

-- 3. Drop os Hubs
DROP TABLE IF EXISTS H_Customer;
DROP TABLE IF EXISTS H_Order;

-- 4. Drop Business Views (gold)
DROP VIEW IF EXISTS gold.BV_Customer_Order;
```

---

## 9. Conclusão e Padrões a Memorizar

### O que foi construído

Um modelo Data Vault 2.0 funcional em Databricks que demonstra o ciclo completo:

```
Bronze (TPC-H) → Silver refined → Silver Raw Vault (H/L/S) → Gold Business Views
```

### Padrões críticos do DV 2.0

| Padrão | Regra |
|--------|-------|
| **Hash Keys** | `MD5(business_key)` para Hubs; `MD5(hk1 \|\| hk2)` para Links |
| **hash_diff** | `MD5(concat de todas as colunas descritivas)` — detector de alterações no Satellite |
| **PK Hub** | `hash_key` (STRING) — imutável, append-only |
| **PK Link** | `hash_key_combinada` (STRING) — imutável, append-only |
| **PK Satellite** | `(hash_key_do_hub, load_timestamp)` — composta! |
| **MERGE Hub/Link** | `WHEN NOT MATCHED` apenas — nunca há UPDATE |
| **MERGE Satellite** | `WHEN NOT MATCHED` apenas — append-only, cada versão é nova linha |
| **Link loading** | JOIN com Hubs já carregados para resolver as hash keys — nunca recalcular |
| **Business View** | `Hub → Satellite` (atributos) + `Hub → Link → Hub` (relações) |

### DV 2.0 vs. Kimball — diferenças práticas

| Aspecto | DV 2.0 (este lab) | Kimball (lab anterior) |
|---------|------------------|----------------------|
| Chave de dimensão | MD5 STRING | BIGINT GENERATED ALWAYS AS IDENTITY |
| Histórico | Satellite append-only | SCD Type 2 com is_current/end_date |
| Relações | Links separados | FKs directas na fact table |
| Camada de consumo | Business Views (gold) | Star schema directamente consultável |
| Imutabilidade | Total (Hubs e Links nunca mudam) | Não garantida |
