# DWH Modeling — Dimensional Modeling e ETL

> **Módulo:** Data Warehousing with Databricks — Path 8  
> **Fonte de dados:** TPC-H  
> **Objectivo:** Construir um star schema completo com uma dimensão SCD Type 2, percorrendo todo o ciclo Bronze → Silver → Gold.

---

## Índice

1. [Objectivos e Setup](#1-objectivos-e-setup)
2. [Part 1 — Definição das Tabelas](#2-part-1--definição-das-tabelas)
3. [Part 2 — Carga da Camada Silver](#3-part-2--carga-da-camada-silver)
4. [Part 3 — Carga Inicial da Camada Gold](#4-part-3--carga-inicial-da-camada-gold)
5. [Part 4 — Actualizações Incrementais (SCD Type 2 MERGE)](#5-part-4--actualizações-incrementais-scd-type-2-merge)
6. [Part 5 — Validação e Queries de Exemplo](#6-part-5--validação-e-queries-de-exemplo)
7. [Part 6 — Resumo e Próximos Passos](#7-part-6--resumo-e-próximos-passos)

---

## 1. Objectivos e Setup

### O que vamos construir

A partir dos dados TPC-H brutos (camada **bronze**), vamos construir um **star schema** na camada **gold**, passando por uma camada **silver** de refinamento. O resultado final será:

- Uma dimensão com **SCD Type 2** (`DimCustomer`) que preserva o histórico de alterações.
- Uma dimensão de datas (`DimDate`).
- Uma tabela de factos (`FactOrders`).

### Passos do notebook

| # | Passo | Descrição |
|---|-------|-----------|
| 1 | Definir estruturas | Criar tabelas silver e gold, incluindo surrogate keys com `GENERATED ALWAYS AS IDENTITY` |
| 2 | Carregar Silver | Mover dados de `bronze` para `silver`, com rename de colunas, TRIM e normalização de tipos |
| 3 | Criar SCD Type 2 | Construir a dimensão `DimCustomer` que preserva histórico para registos alterados |
| 4 | Carregar Gold | Carga inicial **e** incremental das tabelas de dimensão e de factos |
| 5 | Validar | Verificar contagens e explorar queries analíticas no star schema |

### Setup (pré-requisito)

Antes de executar o notebook é necessário ter corrido o script de lab setup, que cria:

1. Um catálogo dedicado com o nome do utilizador (extraído do email).
2. Os schemas `bronze`, `silver` e `gold` dentro desse catálogo.
3. As tabelas TPC-H copiadas de *Samples* para o schema `bronze`.

```python
# Obter o nome do catálogo a partir do email do utilizador
catalog_name = spark.sql("SELECT current_user()").collect()[0][0].split("@")[0]
spark.sql(f"USE CATALOG {catalog_name}")
```

---

## 2. Part 1 — Definição das Tabelas

### Conceito chave: `GENERATED ALWAYS AS IDENTITY`

Em Delta Lake (Databricks), as surrogate keys são geradas automaticamente com esta sintaxe:

```sql
dim_customer_key BIGINT GENERATED ALWAYS AS IDENTITY
```

- A coluna é preenchida automaticamente com valores inteiros incrementais.
- **Não se insere valor** nessa coluna — o Delta trata disso de forma transparente.
- Elimina a necessidade de sequences ou identity columns geridas manualmente como no SQL Server.

---

### 1.2 Tabelas Silver

A camada **silver** (também chamada *refined* ou *integration*) normaliza e padroniza os dados brutos sem ainda aplicar lógica de negócio dimensional.

#### `silver.refined_customer`

```sql
CREATE TABLE IF NOT EXISTS refined_customer (
    customer_id    INT,           -- PK do cliente (vem de c_custkey)
    name           STRING,        -- Nome do cliente
    address        STRING,        -- Morada
    nation_key     INT,           -- FK para a tabela de nações
    phone          STRING,        -- Telefone
    acct_bal       DECIMAL(12,2), -- Saldo da conta
    market_segment STRING,        -- Segmento de mercado
    comment        STRING         -- Comentários adicionais
);
```

#### `silver.refined_orders`

```sql
CREATE TABLE IF NOT EXISTS refined_orders (
    order_id       INT,           -- PK da encomenda (vem de o_orderkey)
    customer_id    INT,           -- FK para o cliente
    order_status   STRING,        -- Estado (e.g., pending, shipped)
    total_price    DECIMAL(12,2), -- Preço total
    order_date     DATE,          -- Data da encomenda
    order_priority STRING,        -- Prioridade
    clerk          STRING,        -- Funcionário responsável
    ship_priority  INT,           -- Prioridade de envio
    comment        STRING         -- Comentários adicionais
);
```

---

### 1.3 Tabelas Gold (Star Schema)

A camada **gold** implementa o star schema com surrogate keys e, no caso da `DimCustomer`, atributos SCD Type 2.

#### `gold.DimCustomer` — Dimensão com SCD Type 2

```sql
CREATE TABLE IF NOT EXISTS DimCustomer (
    dim_customer_key BIGINT GENERATED ALWAYS AS IDENTITY, -- Surrogate key (gerada automaticamente)
    customer_id      INT,           -- Chave natural (business key)
    name             STRING,
    address          STRING,
    nation_key       INT,
    phone            STRING,
    acct_bal         DECIMAL(12,2),
    market_segment   STRING,
    comment          STRING,
    -- Colunas SCD Type 2:
    start_date       DATE,          -- Início da validade do registo
    end_date         DATE,          -- Fim da validade (NULL = registo activo)
    is_current       BOOLEAN,       -- TRUE = versão actual
    CONSTRAINT pk_dim_customer PRIMARY KEY (dim_customer_key)
);
```

> **Nota SCD Type 2:** Para cada cliente pode existir **mais do que uma linha** em `DimCustomer`. A linha activa tem `is_current = TRUE` e `end_date = NULL`. As linhas históricas têm `is_current = FALSE` e `end_date` preenchido com a data em que foi substituída.

#### `gold.DimDate`

```sql
CREATE TABLE IF NOT EXISTS DimDate (
    dim_date_key BIGINT GENERATED ALWAYS AS IDENTITY, -- Surrogate key
    full_date    DATE,   -- Data completa
    day          INT,    -- Dia do mês
    month        INT,    -- Mês
    year         INT,    -- Ano
    CONSTRAINT pk_dim_date PRIMARY KEY (dim_date_key) RELY
);
```

#### `gold.FactOrders`

```sql
CREATE TABLE IF NOT EXISTS FactOrders (
    fact_orders_key  BIGINT GENERATED ALWAYS AS IDENTITY, -- Surrogate key
    order_id         INT,
    dim_customer_key BIGINT,           -- FK → DimCustomer
    dim_date_key     BIGINT,           -- FK → DimDate
    total_price      DECIMAL(12,2),
    order_status     STRING,
    order_priority   STRING,
    clerk            STRING,
    ship_priority    INT,
    comment          STRING,
    CONSTRAINT pk_fact_orders PRIMARY KEY (fact_orders_key),
    CONSTRAINT fk_customer FOREIGN KEY (dim_customer_key) REFERENCES DimCustomer(dim_customer_key),
    CONSTRAINT fk_date     FOREIGN KEY (dim_date_key)     REFERENCES DimDate(dim_date_key)
);
```

---

## 3. Part 2 — Carga da Camada Silver

Os dados são movidos de `bronze` para `silver` aplicando:
- **Rename** de colunas (convenção TPC-H `c_custkey` → `customer_id`).
- **TRIM** para remover espaços em strings.
- **CAST** para normalizar tipos de dados.

```python
silver_schema = "silver"
spark.sql(f"USE {silver_schema}")
```

### INSERT refined_customer ← bronze.customer

```sql
INSERT INTO refined_customer
SELECT
    c_custkey                       AS customer_id,
    TRIM(c_name)                    AS name,
    TRIM(c_address)                 AS address,
    c_nationkey                     AS nation_key,
    TRIM(c_phone)                   AS phone,
    CAST(c_acctbal AS DECIMAL(12,2)) AS acct_bal,
    c_mktsegment                    AS market_segment,
    TRIM(c_comment)                 AS comment
FROM bronze.customer;
```

### INSERT refined_orders ← bronze.orders

```sql
INSERT INTO refined_orders
SELECT
    o_orderkey                         AS order_id,
    o_custkey                          AS customer_id,
    TRIM(o_orderstatus)                AS order_status,
    CAST(o_totalprice AS DECIMAL(12,2)) AS total_price,
    o_orderdate                        AS order_date,
    TRIM(o_orderpriority)              AS order_priority,
    TRIM(o_clerk)                      AS clerk,
    o_shippriority                     AS ship_priority,
    TRIM(o_comment)                    AS comment
FROM bronze.orders;
```

### Validação Silver

```python
display(spark.sql("SELECT COUNT(*) AS refined_customer_count FROM refined_customer"))
display(spark.sql("SELECT COUNT(*) AS refined_orders_count FROM refined_orders"))
```

---

## 4. Part 3 — Carga Inicial da Camada Gold

Na carga inicial, todos os registos são tratados como **versão actual**.

```python
gold_schema = "gold"
spark.sql(f"USE {gold_schema}")
```

### 3.1 DimCustomer — Carga Inicial (SCD Type 2)

Todos os clientes entram com:
- `start_date = CURRENT_DATE()`
- `end_date = NULL`
- `is_current = TRUE`

```sql
INSERT INTO DimCustomer
(customer_id, name, address, nation_key, phone, acct_bal,
 market_segment, comment, start_date, end_date, is_current)
SELECT
    customer_id,
    name,
    address,
    nation_key,
    phone,
    acct_bal,
    market_segment,
    `comment`,
    CURRENT_DATE(),  -- start_date
    NULL,            -- end_date (NULL = activo)
    TRUE             -- is_current
FROM {silver_schema}.refined_customer;
```

### 3.2 DimDate

Recolhe as datas únicas presentes nas encomendas e decompõe-as nas partes componentes:

```sql
INSERT INTO DimDate (full_date, day, month, year)
SELECT DISTINCT
    order_date,
    DAY(order_date),
    MONTH(order_date),
    YEAR(order_date)
FROM {silver_schema}.refined_orders
WHERE order_date IS NOT NULL;
```

> **Nota:** Em produção, a `DimDate` é normalmente pré-populada com todos os dias de um intervalo de vários anos. Aqui usa-se apenas as datas existentes nas encomendas.

### 3.3 FactOrders

O INSERT na tabela de factos resolve as surrogate keys através de JOINs com as dimensões:

```sql
INSERT INTO FactOrders
(order_id, dim_customer_key, dim_date_key, total_price,
 order_status, order_priority, clerk, ship_priority, comment)
SELECT
    ro.order_id,
    dc.dim_customer_key,   -- FK resolvida via JOIN com DimCustomer
    dd.dim_date_key,       -- FK resolvida via JOIN com DimDate
    ro.total_price,
    ro.order_status,
    ro.order_priority,
    ro.clerk,
    ro.ship_priority,
    ro.comment
FROM {silver_schema}.refined_orders ro
JOIN DimCustomer dc
    ON  ro.customer_id = dc.customer_id
    AND dc.is_current = TRUE     -- ← garantir que usamos a versão actual do cliente
JOIN DimDate dd
    ON ro.order_date = dd.full_date;
```

### Validação Gold (carga inicial)

```python
display(spark.sql("SELECT 'DimCustomer' AS table_name, COUNT(*) AS record_count FROM DimCustomer"))
display(spark.sql("SELECT 'DimDate'     AS table_name, COUNT(*) AS record_count FROM DimDate"))
display(spark.sql("SELECT 'FactOrders'  AS table_name, COUNT(*) AS record_count FROM FactOrders"))
```

---

## 5. Part 4 — Actualizações Incrementais (SCD Type 2 MERGE)

### O problema

Na vida real, os dados de origem mudam ao longo do tempo (e.g., um cliente muda de morada). O SCD Type 2 exige:

1. **Fechar** o registo antigo em `DimCustomer`: `end_date = <data actual>`, `is_current = FALSE`.
2. **Inserir** um novo registo com os atributos actualizados: `start_date = <data actual>`, `end_date = NULL`, `is_current = TRUE`.

### A solução: um único MERGE

Um único `MERGE` consegue fazer estas duas operações em simultâneo através do conceito de **staged_changes**.

---

### 4.1 Criar dados de teste (TEMP VIEW)

Simula dois cenários típicos:

```sql
CREATE OR REPLACE TEMP VIEW incremental_customer_updates AS
-- Cenário 1: cliente existente (ID=101) com morada alterada
SELECT 101    AS customer_id, 'CHANGED Name'      AS name,
       'Updated Address 500' AS address, 77 AS nation_key,
       '555-NEW-8888' AS phone, CAST(999.99 AS DECIMAL(12,2)) AS acct_bal,
       'NEW_SEGMENT' AS market_segment, 'Existing row changed' AS comment
UNION ALL
-- Cenário 2: cliente completamente novo (ID=99999)
SELECT 99999  AS customer_id, 'Completely New'    AS name,
       '123 New Street' AS address, 99 AS nation_key,
       '999-999-1234' AS phone, CAST(500.00 AS DECIMAL(12,2)) AS acct_bal,
       'MARKET_NEW' AS market_segment, 'Newly added customer' AS comment;
```

---

### 4.2 MERGE SCD Type 2 — Lógica Completa

#### Estratégia de `staged_changes`

O CTE `staged_changes` duplica cada registo de entrada em dois:

| `row_type` | Propósito |
|------------|-----------|
| `'OLD'` | Encontrar o registo activo existente em `DimCustomer` e **fechá-lo** |
| `'NEW'` | Inserir a versão actualizada (ou o novo cliente) |

```sql
WITH staged_changes AS (
    -- Linha "OLD": vai fazer match com o registo activo e fechá-lo
    SELECT i.customer_id, i.name, i.address, i.nation_key,
           i.phone, i.acct_bal, i.market_segment, i.comment,
           'OLD' AS row_type
    FROM incremental_customer_updates i

    UNION ALL

    -- Linha "NEW": não vai fazer match → activa o caminho INSERT
    SELECT i.customer_id, i.name, i.address, i.nation_key,
           i.phone, i.acct_bal, i.market_segment, i.comment,
           'NEW' AS row_type
    FROM incremental_customer_updates i
)
MERGE INTO DimCustomer AS target
USING staged_changes   AS source
ON  target.customer_id = source.customer_id
AND target.is_current  = TRUE
AND source.row_type    = 'OLD'

-- Se encontrou o registo activo (linha OLD fez match): fecha o registo
WHEN MATCHED THEN
    UPDATE SET
        target.end_date   = CURRENT_DATE(),
        target.is_current = FALSE

-- Se não encontrou match (linha NEW nunca faz match): insere novo registo
WHEN NOT MATCHED THEN
    INSERT (customer_id, name, address, nation_key, phone, acct_bal,
            market_segment, comment, start_date, end_date, is_current)
    VALUES (source.customer_id, source.name, source.address, source.nation_key,
            source.phone, source.acct_bal, source.market_segment, source.comment,
            CURRENT_DATE(), NULL, TRUE);
```

#### Como funciona o truque `OLD`/`NEW`

```
incremental_customer_updates (1 linha por cliente)
         ↓  UNION ALL duplica
staged_changes (2 linhas por cliente: OLD + NEW)
         ↓  MERGE
DimCustomer:
  ├── linha OLD faz match (customer_id + is_current=TRUE) → UPDATE fecha registo
  └── linha NEW NÃO faz match (is_current já é FALSE após UPDATE) → INSERT novo
```

> **Chave do padrão:** A linha `NEW` nunca vai fazer match na condição `is_current = TRUE` porque, para clientes existentes, o UPDATE acabou de mudar `is_current` para `FALSE`. Para clientes novos, nunca existia registo activo. Em ambos os casos, cai no `WHEN NOT MATCHED → INSERT`.

---

### 4.3 Validar os Resultados

```python
# Cliente 101: deve ter 2 linhas — 1 antiga (is_current=FALSE) + 1 nova (is_current=TRUE)
display(spark.sql("""
    SELECT dim_customer_key, customer_id, name, address,
           is_current, start_date, end_date
    FROM DimCustomer
    WHERE customer_id = 101
    ORDER BY dim_customer_key
"""))

# Cliente 99999: novo cliente — deve ter 1 linha (is_current=TRUE)
display(spark.sql("""
    SELECT dim_customer_key, customer_id, name, address,
           is_current, start_date, end_date
    FROM DimCustomer
    WHERE customer_id = 99999
    ORDER BY dim_customer_key
"""))
```

**Resultado esperado para o cliente 101:**

| customer_id | name | address | is_current | start_date | end_date |
|-------------|------|---------|-----------|------------|----------|
| 101 | Customer#000000101 | sMMl2r... | **false** | 2025-02-01 | 2025-02-01 |
| 101 | CHANGED Name | Updated Address 500 | **true** | 2025-02-01 | null |

---

## 6. Part 5 — Validação e Queries de Exemplo

### 5.1 Contagem de Registos

```python
display(spark.sql("SELECT 'DimCustomer' AS table_name, COUNT(*) AS record_count FROM DimCustomer"))
display(spark.sql("SELECT 'DimDate'     AS table_name, COUNT(*) AS record_count FROM DimDate"))
display(spark.sql("SELECT 'FactOrders'  AS table_name, COUNT(*) AS record_count FROM FactOrders"))
```

### 5.2 Top Segmentos de Mercado por Volume de Vendas

```sql
SELECT
    dc.market_segment,
    SUM(f.total_price) AS total_spent
FROM FactOrders f
JOIN DimCustomer dc
    ON f.dim_customer_key = dc.dim_customer_key
GROUP BY dc.market_segment
ORDER BY total_spent DESC
LIMIT 10;
```

### 5.3 Contagem de Encomendas por Ano

```sql
SELECT
    dd.year,
    COUNT(*) AS orders_count
FROM FactOrders f
JOIN DimDate dd
    ON f.dim_date_key = dd.dim_date_key
GROUP BY dd.year
ORDER BY dd.year;
```

---

## 7. Part 6 — Resumo e Próximos Passos

### O que foi feito

| Área | Detalhe |
|------|---------|
| **Estruturas** | Tabelas silver (`refined_customer`, `refined_orders`) e gold (`DimCustomer`, `DimDate`, `FactOrders`) com `GENERATED ALWAYS AS IDENTITY` |
| **SCD Type 2** | `DimCustomer` com `start_date`, `end_date`, `is_current` |
| **Carga inicial** | Bronze → Silver (TRIM/CAST/rename) + Silver → Gold (surrogate key resolution) |
| **Incremental** | MERGE único com padrão `OLD`/`NEW` para fechar e inserir em simultâneo |
| **Validação** | Contagens de registos + queries analíticas no star schema |

### Próximos passos sugeridos

- Automatizar a detecção de alterações em `refined_customer` para manter `DimCustomer` sincronizada.
- Estender o SCD Type 2 a outras dimensões (e.g., `DimSupplier`, `DimPart`).
- Criar tabelas de factos adicionais (e.g., `FactLineItems`) para enriquecer o star schema.
- Explorar queries de BI avançadas tirando partido das optimizações de performance do Databricks.

---

> **Padrão a memorizar — MERGE SCD Type 2:**  
> `staged_changes = OLD (fecha) + NEW (insere)` → um único MERGE faz as duas operações atomicamente.
