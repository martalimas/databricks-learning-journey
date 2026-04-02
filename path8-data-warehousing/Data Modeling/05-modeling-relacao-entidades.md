# Lab — Modelação ER e Constraints no Databricks

> **Módulo:** Data Modeling Strategies  
> **Fonte:** Databricks Learning Festival 2026 — Pathway 8: Data Warehousing Practitioner  
> **Dataset:** TPC-H (`samples.tpch`) — tabelas `customer` e `orders`  
> **Schema de trabalho:** `silver`

---

## Objectivos

- Criar tabelas com constraints de Primary Key (PK) e Foreign Key (FK)
- Compreender como as constraints funcionam no Databricks (informativas vs. enforçadas)
- Inserir dados a partir do dataset TPC-H no schema `bronze`
- Demonstrar o comportamento de violações de constraints
- Reverter para um estado limpo
- Visualizar o diagrama ER no Catalog Explorer

---

## Conceito-Chave: Constraints no Databricks

> **Atenção — comportamento diferente do SQL Server/PostgreSQL!**

| Constraint | Enforçada? | Para que serve |
|---|---|---|
| `PRIMARY KEY` | ❌ Não (por defeito) | Documental — explica relações entre tabelas |
| `FOREIGN KEY` | ❌ Não (por defeito) | Documental — permite gerar ERDs no Catalog Explorer |
| `NOT NULL` | ✅ Sim | Enforçada activamente |
| `CHECK` | ✅ Sim | Enforçada activamente |

As constraints PK e FK são **informativas** — servem para o Databricks perceber as relações e gerar ERDs automaticamente no Catalog Explorer, mas **não impedem a inserção de dados inválidos**.

---

## Setup

### Passo 1 — Correr o script de setup do lab

```python
%run ./Includes/setup/lab_setup
```

O script faz automaticamente:
1. Deriva um identificador único a partir do email do utilizador
2. Cria um catalog com o nome do `user_id` do lab
3. Cria os schemas `bronze`, `silver` e `gold` dentro desse catalog
4. Copia as tabelas TPC-H do `samples.tpch` para o schema `bronze` (via CTAS)
5. Atribui permissões para que só este utilizador aceda aos schemas
6. Valida o setup — se alguma validação falhar, levanta uma excepção

> **Schemas criados em `samples`:** `accuweather`, `bakehouse`, `information_schema`, `nyctaxi`, `tpch`  
> **Tabelas TPC-H disponíveis em `bronze`:** `customer`, `lineitem`, `nation`, `orders`, `part`, `partsupp`, `region`, `supplier`

---

### Passo 2 — Definir o catalog e schema de trabalho

```python
# Obtém o utilizador actual e extrai o nome do catalog a partir do email
catalog_name = spark.sql("SELECT current_user()").collect()[0][0].split("@")[0]

# Define o schema de trabalho
schema_name = "silver"

# Activa o catalog e schema
spark.sql(f"USE CATALOG {catalog_name}")
spark.sql(f"USE {schema_name}")

# Confirma os valores activos
display(f"Catalog: {catalog_name}")
display(f"Schema: {schema_name}")
```

---

## Passo 3 — Criar tabelas com constraints

Vamos criar duas tabelas para demonstrar PK e FK:
- `lab_customer` — com PK em `c_custkey`
- `lab_orders` — com PK em `o_orderkey` e FK em `o_custkey` a referenciar `lab_customer`

### Criar `lab_customer`

```sql
%sql
-- Cria a tabela lab_customer com constraint de PRIMARY KEY em c_custkey
CREATE TABLE IF NOT EXISTS lab_customer
(
  c_custkey    INT,
  c_name       STRING,
  c_address    STRING,
  c_nationkey  INT,
  c_phone      STRING,
  c_acctbal    DECIMAL(12,2),
  c_mktsegment STRING,
  c_comment    STRING,
  CONSTRAINT pk_custkey PRIMARY KEY (c_custkey)
);
```

### Criar `lab_orders`

```sql
%sql
-- Cria a tabela lab_orders com PRIMARY KEY em o_orderkey
-- e FOREIGN KEY em o_custkey a referenciar lab_customer(c_custkey)
CREATE TABLE IF NOT EXISTS lab_orders
(
  o_orderkey     INT,
  o_custkey      INT,
  o_orderstatus  STRING,
  o_totalprice   DECIMAL(12,2),
  o_orderdate    DATE,
  o_orderpriority STRING,
  o_clerk        STRING,
  o_shippriority INT,
  o_comment      STRING,
  CONSTRAINT pk_orderkey PRIMARY KEY (o_orderkey),
  CONSTRAINT fk_custkey  FOREIGN KEY (o_custkey) REFERENCES lab_customer(c_custkey)
);
```

---

## Passo 4 — Inserir dados a partir das tabelas TPC-H do Bronze

```sql
%sql
-- Popula lab_customer a partir dos dados TPC-H no bronze
INSERT INTO lab_customer
SELECT
  c_custkey,
  c_name,
  c_address,
  c_nationkey,
  c_phone,
  c_acctbal,
  c_mktsegment,
  c_comment
FROM bronze.customer;
```

```sql
%sql
-- Popula lab_orders a partir dos dados TPC-H no bronze
INSERT INTO lab_orders
SELECT
  o_orderkey,
  o_custkey,
  o_orderstatus,
  o_totalprice,
  o_orderdate,
  o_orderpriority,
  o_clerk,
  o_shippriority,
  o_comment
FROM bronze.orders;
```

---

## Passo 5 — Demonstrar violações de constraints

> Como as constraints PK e FK **não são enforçadas** por defeito no Databricks, os inserts abaixo **não vão levantar erro** — mas ilustram o comportamento.

### Violação de Foreign Key

Inserir uma encomenda com um `o_custkey` que não existe em `lab_customer`:

```sql
%sql
-- Tenta inserir uma encomenda com um customer inexistente
-- No Databricks: NÃO levanta erro (FK não enforçada)
INSERT INTO lab_orders
VALUES (
  9999999,           -- o_orderkey
  9999999,           -- o_custkey (não existe em lab_customer!)
  'F',
  1000.00,
  current_date(),
  '3-LOW',
  'Clerk#000000001',
  0,
  'Testing invalid customer key'
);
```

### Violação de Primary Key

Inserir um cliente com um `c_custkey` que já existe em `lab_customer`:

```sql
%sql
-- Tenta inserir um cliente com c_custkey duplicado
-- No Databricks: NÃO levanta erro (PK não enforçada)
-- Assumindo que c_custkey = 1 já existe na tabela
INSERT INTO lab_customer
VALUES (
  1,
  'Duplicate Customer',
  'Duplicate Address',
  9999,
  '999-999-9999',
  9999.99,
  'DUPLICATE_SEGMENT',
  'Inserting a duplicate primary key for demonstration'
);
```

> **Conclusão:** em SQL Server ou PostgreSQL, ambos os inserts falhariam com erro. No Databricks, passam silenciosamente — a responsabilidade de garantir integridade referencial cabe ao pipeline ETL.

---

## Passo 6 — Reverter para um estado limpo

Para remover as linhas problemáticas, podemos usar `DELETE` directo ou **Delta Time Travel**:

```sql
%sql
-- Remove a violação de foreign key
DELETE FROM lab_orders
WHERE o_orderkey = 9999999;
```

```sql
%sql
-- Remove o registo duplicado de primary key
DELETE FROM lab_customer
WHERE c_custkey = 1
  AND c_name = 'Duplicate Customer';
```

> **Alternativa com Delta Time Travel:**
> ```sql
> -- Restaura a tabela para a versão anterior à inserção indevida
> RESTORE TABLE lab_orders TO VERSION AS OF 1;
> ```

---

## Passo 7 — Visualizar o Diagrama ER no Databricks

O Databricks gera automaticamente ERDs com base nas constraints PK/FK definidas.

**Como aceder:**
1. No menu lateral esquerdo, ir a **Catalog**
2. Seleccionar o teu catalog (baseado no teu `user_id` de lab)
3. Seleccionar o schema `silver`
4. Localizar a tabela `lab_orders` (que tem a FK para `lab_customer`)
5. Clicar em **View Relationships**

Deverás ver `lab_orders` com uma foreign key a referenciar `lab_customer`.

> **Insight:** mesmo sem enforçamento, as constraints são suficientes para o Databricks construir o diagrama ER — o que é muito útil para documentação e comunicação do modelo de dados.

---

## Passo 8 — Teardown (limpar apenas as tabelas do lab)

```sql
%sql
-- Remove apenas as tabelas criadas neste lab
-- As tabelas TPC-H no bronze ficam intactas
DROP TABLE IF EXISTS lab_orders;
DROP TABLE IF EXISTS lab_customer;
```

---

## Resumo dos Conceitos do Lab

| Conceito | Comportamento no Databricks |
|---|---|
| `PRIMARY KEY` | Declarativa — não enforçada; usada para ERDs e optimização de queries |
| `FOREIGN KEY` | Declarativa — não enforçada; permite visualização de relações no Catalog Explorer |
| `NOT NULL` | Enforçada — rejeita inserções com valores nulos |
| `CHECK` | Enforçada — rejeita inserções que violem a condição |
| Violação de FK | Insert passa sem erro — integridade garantida pelo pipeline ETL |
| Violação de PK | Insert passa sem erro — duplicados possíveis sem controlo explícito |
| Reverter dados | `DELETE` directo ou `RESTORE TABLE TO VERSION AS OF N` (Delta Time Travel) |
| Ver ERD | Catalog Explorer → tabela → **View Relationships** |

---

*Notas geradas a partir dos slides do Databricks Learning Festival 2026 — repo: `github.com/martalimas/databricks-learning-journey`*
