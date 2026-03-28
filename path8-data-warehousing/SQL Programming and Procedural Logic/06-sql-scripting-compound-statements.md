# SQL Scripting in Databricks — Compound Statements

**Módulo:** SQL Programming and Procedural Logic  
**Secção:** SQL Scripting in Databricks  
**Fonte:** Databricks Learning Festival 2026 — Pathway 8: Data Warehousing Practitioner

---

## Contexto: SQL Scripting em Databricks

**SQL Scripting** em Databricks segue o standard **SQL/PSM** (Persistent Stored Modules) e foi disponibilizado em **Public Preview no Databricks Runtime 16.3+** (Março 2025).

Representa um passo significativo para profissionais com background em RDBMS — traz constructs procedurais familiares (control flow, variáveis, error handling) para dentro do SQL nativo do Databricks.

**O que oferece:**
- Agrupa múltiplos statements SQL num único script com `BEGIN...END`
- Adiciona constructs procedurais: variáveis, controlo de fluxo, error handling
- Disponível em Databricks Runtime 16.3+

---

## Compound Statements — `BEGIN...END`

Um **Compound Statement** é o bloco fundamental do SQL Scripting em Databricks. Agrupa múltiplos comandos SQL numa única unidade de execução.

**Características principais:**
- Agrupa múltiplos comandos SQL dentro de um único bloco de execução
- Encapsula constructs de scripting como variáveis, control flow e error handlers
- Funciona como um lightweight procedure body — ideal para lógica modular
- **Scope local**: variáveis e views declaradas dentro do bloco só existem dentro do bloco

> **Regra importante:** o Databricks **requer** um bloco `BEGIN...END` sempre que queres usar features de scripting como variáveis, control flow ou error handlers. Sem ele, esses constructs não funcionam.

---

## Anatomia de um Compound Statement

```sql
BEGIN
  -- Passo 1: criar uma temp view dentro do bloco
  CREATE OR REPLACE TEMP VIEW high_value_orders AS
  SELECT o_orderkey, o_totalprice
  FROM orders
  WHERE o_totalprice > 100000;

  -- Passo 2: operar imediatamente sobre o resultado
  SELECT COUNT(*) AS high_value_count
  FROM high_value_orders;
END;
```

### As três partes:

| Parte | O que faz |
|---|---|
| `BEGIN` | Abre o bloco de scripting |
| Statements dentro | Executam em sequência como uma unidade lógica |
| `END;` | Fecha formalmente o bloco — obrigatório |

---

## Porquê usar Compound Statements?

**Fora** de um bloco `BEGIN...END`, terias de executar cada statement manualmente, um de cada vez. **Dentro** do bloco, executam como uma unidade lógica — podes sequenciar lógica: primeiro definir, depois operar.

Este padrão — **primeiro criar, depois usar** — é o core do scripting. E é o que desbloqueia tudo o resto:

| Feature | Precisa de BEGIN...END? |
|---|---|
| Variáveis (`DECLARE`) | ✅ Sim |
| Control flow (`IF`, `CASE`) | ✅ Sim |
| Loops (`FOR`, `WHILE`) | ✅ Sim |
| Error handling (`EXCEPTION`) | ✅ Sim |
| Temp Views simples | ❌ Não (mas beneficiam de estar num bloco) |

> Pensa em `BEGIN...END` como o **contentor** que activa o modo scripting. Vais usá-lo em todos os exemplos desta secção.

---

## Compound Statements vs outras abordagens

| | Compound Statement | Notebook cells | CTE |
|---|---|---|---|
| **Múltiplos statements** | ✅ Num único bloco | ✅ Células separadas | ❌ Apenas queries |
| **Variáveis** | ✅ | ❌ | ❌ |
| **Control flow** | ✅ | ❌ | ❌ |
| **Scope local** | ✅ Variáveis morrem com o bloco | ❌ Persistem na sessão | N/A |
| **Runtime mínimo** | DBR 16.3+ | Qualquer | Qualquer |

---

## Key takeaways

- `BEGIN...END` é o **entry point** para SQL Scripting em Databricks — sem ele, nenhum construct procedural funciona
- Disponível desde **DBR 16.3** (Março 2025) — feature recente, ainda em Public Preview
- Segue o standard **SQL/PSM** — familiar para quem vem de Oracle, SQL Server, ou PostgreSQL
- Scope local significa que variáveis declaradas dentro do bloco **não vazam** para fora — comportamento mais seguro e previsível
- É a base sobre a qual se constroem variáveis, loops, conditionals e error handling nas secções seguintes


# SQL Scripting in Databricks — Demo: Compound Statements

> **Pathway 8 · SQL Programming and Procedural Logic**  
> Tópico: Compound Statements (demo notebook)

---

## O que este demo ensina

- Usar compound statements (`BEGIN...END`) para organizar workflows SQL com múltiplos passos
- Encadear temporary views dentro de um bloco composto
- Controlar a ordem de execução de operações relacionadas como uma unidade lógica única

---

## Contexto do ambiente (laboratório Databricks)

Este demo corre num notebook Databricks com:

| Requisito | Porquê |
|---|---|
| Runtime **16.4 LTS ou superior** | SQL Scripting é uma feature recente |
| **Classic Compute** (não Serverless) | SQL Scripting não suporta Serverless neste contexto |
| **Unity Catalog** habilitado | Para gerir catálogos e schemas com privilégios |
| Dataset **TPCH** (`samples.tpch`) | Tabelas de exemplo: `orders`, `customer`, `nation`, `region` |
| Privilégios `CREATE CATALOG`, `USE CATALOG`, `CREATE SCHEMA`, `USE SCHEMA`, `SELECT` | Para criar e aceder à estrutura de dados do utilizador |

### Estrutura criada pelo setup script

O script de setup (`%run ../Includes/Classroom-Setup-1`) cria automaticamente:

```
[Catalog: <user_catalog_name>]
├── [Schema: bronze]   ← tabelas TPCH copiadas aqui (customer, orders, nation, etc.)
├── [Schema: silver]   ← vazio; destinado a dados refinados/curados
└── [Schema: gold]     ← vazio; destinado a agregações e reporting
```

O objeto `DA` (Databricks Academy) expõe variáveis de sessão como:
- `DA.username`
- `DA.catalog_name`
- `DA.user_catalog_name`  ← o catálogo único deste utilizador
- `DA.schema_name`
- `DA.paths.working_dir`

---

## Exercício: Filtering and Joining Low-Value Orders with Customer Regions

**Objetivo:** Num único bloco composto, filtrar encomendas de baixo valor e cruzá-las com a região geográfica do cliente.

### Lógica em 3 passos

**Passo 1 — Filtrar encomendas de baixo valor**

Criar uma temporary view `low_value_orders` com apenas as encomendas cujo `o_totalprice` é inferior a 10 000.

```sql
-- Step 1: Filter low-value orders
CREATE OR REPLACE TEMP VIEW low_value_orders AS
SELECT o_orderkey, o_custkey, o_totalprice
FROM <user_catalog_name>.bronze.orders
WHERE o_totalprice < 10000;
```

**Passo 2 — Associar clientes à sua região**

Criar uma temporary view `customer_region` que junta a tabela `customer` com a tabela `nation`, para obter o nome da nação e a chave de região de cada cliente.

```sql
-- Step 2: Join with customer and nation to get region
CREATE OR REPLACE TEMP VIEW customer_region AS
SELECT
    c.c_custkey,
    c.c_name      AS customer_name,
    n.n_name      AS nation_name,
    n.n_regionkey AS regionkey
FROM <user_catalog_name>.bronze.customer c
JOIN <user_catalog_name>.bronze.nation n
    ON c.c_nationkey = n.n_nationkey;
```

**Passo 3 — Cruzar resultados**

Juntar as duas views para produzir um resumo: por cada encomenda de baixo valor, mostrar o ID da encomenda, o preço total e a região do cliente.

```sql
-- Step 3: Final join to summarize order data
SELECT o.o_orderkey, o.o_totalprice, cr.regionkey
FROM low_value_orders o
JOIN customer_region cr ON o.o_custkey = cr.c_custkey;
```

---

## O bloco completo — BEGIN...END

Os 3 passos são envolvidos num único compound statement. Isto garante que são executados como uma unidade lógica coesa:

```sql
-- Use BEGIN...END to group all steps as one logical unit
-- (Replace <user_catalog_name> with your actual catalog name)
BEGIN

    ----- Step 1: Filter low-value orders
    CREATE OR REPLACE TEMP VIEW low_value_orders AS
    SELECT o_orderkey, o_custkey, o_totalprice
    FROM <user_catalog_name>.bronze.orders
    WHERE o_totalprice < 10000;

    ----- Step 2: Join with customer and nation to get region
    CREATE OR REPLACE TEMP VIEW customer_region AS
    SELECT
        c.c_custkey,
        c.c_name      AS customer_name,
        n.n_name      AS nation_name,
        n.n_regionkey AS regionkey
    FROM <user_catalog_name>.bronze.customer c
    JOIN <user_catalog_name>.bronze.nation n
        ON c.c_nationkey = n.n_nationkey;

    ----- Step 3: Final join to summarize order data
    SELECT o.o_orderkey, o.o_totalprice, cr.regionkey
    FROM low_value_orders o
    JOIN customer_region cr ON o.o_custkey = cr.c_custkey;

END;
```

> **Nota:** No SQL Editor do Databricks, o `%sql` magic não é necessário — cola directamente o bloco acima e substitui `<user_catalog_name>` pelo nome real do catálogo.

---

## Cleanup — remover o que foi criado

As temporary views existem apenas durante a sessão, mas podem ser removidas explicitamente:

```sql
-- Remover a view de encomendas de baixo valor
DROP VIEW IF EXISTS low_value_orders;

-- Remover a view de clientes com região
DROP VIEW IF EXISTS customer_region;

-- Remover o catálogo inteiro do utilizador (apaga schemas e tabelas em cascata)
DROP CATALOG IF EXISTS <user_catalog_name> CASCADE;
```

---

## Conclusão

Este demo ilustra como o `BEGIN...END` permite:

1. **Agrupar operações relacionadas** — os 3 passos são uma unidade, não 3 queries soltas
2. **Controlar a ordem de execução** — o Databricks executa sequencialmente dentro do bloco
3. **Reutilizar resultados intermédios** — as temp views criadas num passo estão disponíveis nos passos seguintes do mesmo bloco
4. **Manter legibilidade** — o script fica estruturado e fácil de manter

> O próximo tópico — **Variables in SQL Scripts** — vai introduzir variáveis declaradas dentro destes blocos, tornando os scripts ainda mais dinâmicos e reutilizáveis.
