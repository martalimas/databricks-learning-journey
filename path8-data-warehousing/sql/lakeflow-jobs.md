# Lakeflow Jobs — Demo e Lab

**Módulo:** SQL Programming and Procedural Logic  
**Secção:** Procedural Logic in Databricks  
**Pathway:** 8 — Data Warehousing Practitioner  
**Formato:** Demo (40 min) + Lab

---

## Objectivos de Aprendizagem da Demo

No final desta demo serás capaz de:

- Aplicar parâmetros de job e dependências de tasks para construir workflows SQL orquestrados.
- Executar SQL tasks sequenciais e condicionais dentro de um Lakeflow Job.
- Demonstrar lógica de branching e caminhos de workflow condicionais em task pipelines.
- Realizar operações iterativas com automação **FOR-EACH** em Lakeflow Jobs.
- **Orquestrar uma sequência de queries SQL guardadas como tasks modulares num Lakeflow Job** *(objectivo principal do lab)*.

---

## Visão Geral do Exercício

**Título:** Lakeflow Job: Adaptar Lógica para Novas Condições

**Objectivo:** Construir um Lakeflow Job para segmentar, agregar e monitorizar encomendas com base na prioridade e intervalo de datas, usando branching e workflows condicionais, através da orquestração de uma sequência de queries SQL guardadas.

### Estrutura do Workflow (DAG)

```
[1_Filter_Orders_by_Priority_...]
        │
        ▼
[2_Count_Filtered_Orders]
        │
        ▼
[3_Filtered_Order_Count_Test]  <── If/Else: _count}} >= 750
        │                True ──► [4_Aggregate_Filtered_Orders]
        └──────────────  False ──► [5_Log_Low_Volume_Event]
```

### Passos do Exercício

1. Filtrar encomendas por prioridade e intervalo de datas numa SQL Task.
2. Adicionar uma SQL Task para contar as encomendas filtradas.
3. Usar um control flow If/Else para fazer branching com base em se a contagem de encomendas filtradas atinge o threshold definido.
4. Configurar uma SQL task de agregação para executar se houver encomendas suficientes, ou uma task de fallback para registar condições não cumpridas.
5. Executar e monitorizar manualmente a execução do job.

---

## Setup do Lab

### Configuração de Compute

> ⚠️ **Obrigatório:** Seleccionar **Classic Compute** antes de executar células. O Serverless está activo por defeito.

**Passos:**
1. Navegar para o menu dropdown no canto superior direito do notebook e seleccionar o cluster.
2. Se o cluster não aparecer: seleccionar **More** → **Attach to an existing compute resource** → escolher o cluster disponível.
3. Se o cluster estiver terminado: botão direito em **Compute** no painel esquerdo → **Open in new tab** → clicar no ícone de triângulo para reiniciar.

### Classroom Setup

Executar o script de setup fornecido antes de começar a demo:

```python
%run ../Includes/Classroom-Setup-3
```

Este script define automaticamente as variáveis de configuração e cria um ambiente de dados personalizado e seguro para cada utilizador, usando a hierarquia de três níveis do Unity Catalog.

---

## Step 1: Filtrar Encomendas por Prioridade e Intervalo de Datas

### Objectivo

Criar uma query SQL parametrizada que filtra a tabela `orders` por **prioridade** e um **intervalo de datas** especificado. Esta estrutura permite fácil automação com Lakeflow Jobs ou ferramentas de scheduling similares.

### Requisitos

- Usar a tabela `orders` como fonte.
- Seleccionar as colunas: `o_orderkey`, `o_custkey`, `o_orderstatus`, `o_totalprice`, `o_orderdate`, `o_orderpriority`.
- Aplicar filtros com os parâmetros SQL `:priority`, `:start_date` e `:end_date`:
  - `o_orderpriority = :priority`
  - `o_orderdate BETWEEN :start_date AND :end_date`
- Ordenar por `o_orderdate` ascendente.
- Os parâmetros serão fornecidos dinamicamente em runtime pelo Lakeflow Job.

### Query SQL (Demo__1_Filter_Orders_by_Priority_and_Date_Range)

```sql
-- SQL Task:
-- Filter Orders by Priority and Date Range
SELECT
    o_orderkey,
    o_custkey,
    o_orderstatus,
    o_totalprice,
    o_orderdate,
    o_orderpriority
FROM labuser10985142_1755068202_catalog.bronze.orders
WHERE
    o_orderpriority = :priority
    AND o_orderdate BETWEEN :start_date AND :end_date
ORDER BY
    o_orderdate ASC;
```

**Parâmetros de exemplo usados na demo:**
- Start Date: `1994-01-01`
- End Date: `1994-01-05`
- Priority: `1-URGENT`

### Configuração da Task no Job

| Campo | Valor |
|---|---|
| Task name | `Demo__1_Filter_Orders_by_Priority_and_Date_Range` |
| Type | SQL |
| SQL task | Query |
| SQL query | `Demo__1_Filter Orders by Priority and Date Range` |
| SQL warehouse | `shared_warehouse (2XS)` |
| Parâmetros | Start Date, End Date, Priority |

### Como Abrir a Query no SQL Editor

1. Abrir o **SQL Editor** a partir da barra lateral do Databricks.
2. Clicar no botão `+` e seleccionar **Open existing query**.
3. Na lista de queries, seleccionar `Demo__1_Filter Orders by Priority and Date Range`.

---

## Step 2: Contar as Encomendas Filtradas

### Objectivo

Criar uma query SQL parametrizada que **conta o número de encomendas filtradas** com base na prioridade e intervalo de datas seleccionados. Esta contagem irá conduzir a lógica condicional dentro do Lakeflow Job.

### Requisitos

- Usar a tabela `orders` como fonte.
- Aplicar os mesmos parâmetros SQL: `:priority`, `:start_date`, `:end_date`.
- Retornar a contagem de registos correspondentes.
- Criar um alias para a coluna de output: `filtered_order_count`.
- Os parâmetros serão fornecidos dinamicamente em runtime.

### Query SQL (Demo__2_Count_Filtered_Orders)

```sql
-- SQL Task:
-- Count Filtered Orders
SELECT
    COUNT(*) AS filtered_order_count
FROM orders
WHERE
    o_orderpriority = :priority
    AND o_orderdate BETWEEN :start_date AND :end_date;
```

> **Nota importante:** O alias `filtered_order_count` é crítico — é este nome que será referenciado pela task If/Else no passo seguinte através da sintaxe `{{tasks.Demo__2_Count_Filtered_Orders.output.first_row.filtered_order_count}}`.

---

## Step 3: If/Else Control Flow — Branching com Base em `filtered_order_count`

### Objectivo

Configurar um control flow if/else dinâmico com base no número de encomendas filtradas identificado no Step 2. O Lakeflow Job irá automaticamente fazer branching:
- Se a contagem for **≥ 750** → executar a task de agregação (Step 4).
- Se a contagem for **< 750** → executar a task de fallback logging (Step 5).

### Requisitos

1. Usar o valor de output `filtered_order_count` do Step 2 como variável de decisão.
2. Implementar uma condição If/Else:
   - **If** `filtered_order_count >= 750` → executar a task de agregação.
   - **Else** → executar a task de fallback logging.
3. A lógica de branching é aplicada dentro do workflow para que o próximo passo seja determinado dinamicamente em runtime.

> **Nota:** Não é necessário criar uma nova Query para esta task. A task If/Else usa o output da Query da task anterior (Step 2) como input.

### Configuração da Task no Job

| Campo | Valor |
|---|---|
| Task name | `Demo__3_Filtered_Order_Count_Test` |
| Type | `If/else condition` |
| Condition | `{{tasks.Demo__2_Count_Filtered_Orders.output.first_row.filtered_order_count}}` |
| Operador | `>=` |
| Valor | `750` |
| Depends on | `Demo__2_Count_Filtered_Orders` |
| Run if dependencies | `All succeeded` |

**Como aparece no DAG:**
```
[Demo__2_Count_Filtered_Or...] ──► [Demo__3_Filtered_Order_Co... <> _count}} >= 750]
                                              │
                                   True ──►  [4_Aggregate_Filtered_Orders]
                                   False ──► [5_Log_Low_Volume_Event]
```

---

## Step 4: Agregação se Houver Encomendas Suficientes (Ramo True)

### Objectivo

Implementar uma SQL task de agregação que activa **apenas se houver encomendas filtradas suficientes** (i.e., se `filtered_order_count >= 750`). Esta task executa uma query de agregação agrupada na tabela `orders` — contando o número de encomendas por prioridade.

### Requisitos

- Usar a tabela `orders` como fonte.
- Aplicar a mesma lógica de filtros com os parâmetros `:priority`, `:start_date`, `:end_date`.
- Agrupar os resultados por `o_orderpriority`.
- O output deve fornecer uma contagem de encomendas por valor de prioridade.

### Query SQL (Demo__4_Aggregation_Filtered_Orders)

```sql
-- SQL Task:
-- Aggregate Orders by Priority
SELECT
    o_orderpriority,
    COUNT(*) AS order_count
FROM labuser10985142_1755068202_catalog.bronze.orders
WHERE
    o_orderpriority = :priority
    AND o_orderdate BETWEEN :start_date AND :end_date
GROUP BY
    o_orderpriority
ORDER BY
    o_orderpriority;
```

**Resultado de exemplo:**

| o_orderpriority | order_count |
|---|---|
| 1-URGENT | 3081 |

### Configuração da Task no Job

| Campo | Valor |
|---|---|
| Task name | `Demo__4_Aggregation_Filtered_Orders` |
| Type | SQL |
| SQL task | Query |
| SQL query | `Demo__4_Aggregation Filtered Orders` |
| SQL warehouse | `shared_warehouse (2XS)` |
| Depends on | `Demo__3_Filtered_Order_Count_Test (true)` |
| Run if dependencies | `All succeeded` |
| Parâmetros | Start Date, End Date |

---

## Step 5: Fallback Logging se Não Houver Encomendas Suficientes (Ramo False)

### Objectivo

Implementar uma SQL task de fallback que é activada **apenas quando a contagem de encomendas filtradas é inferior a 750**. Garante que o Lakeflow Job é tolerante a falhas ao lidar graciosamente com casos em que o volume de dados esperado não é atingido — em vez de falhar silenciosamente, o workflow regista este evento de baixo volume para auditoria e revisão futura.

### Requisitos

1. A task de fallback insere um registo numa tabela de auditoria ligeira (`default.job_audit_log`).
2. Cada registo de audit log deve capturar:
   - O timestamp actual.
   - O nome do job (ex: `'Lakeflow Jobs Lab'`).
   - Uma mensagem significativa (ex: `'Low volume detected for selected criteria'`).

### Configuração da Task no Job

| Campo | Valor |
|---|---|
| Task name | `Demo__5_Log_Low_Volume_Event` |
| Type | SQL |
| SQL task | Query |
| SQL query | `Demo__5_Log Low Volume Event` |
| SQL warehouse | `shared_warehouse (2XS)` |
| Depends on | `Demo__3_Filtered_Order_Count_Test (false)` |

---

## Queries Disponíveis no Lab

O ambiente do lab inclui 5 queries SQL pré-criadas:

| Query | Descrição |
|---|---|
| `Demo__0_Create and Register the Job Audit Log Table` | Cria a tabela de auditoria para o fallback log |
| `Demo__1_Filter Orders by Priority and Date Range` | Task 1 — filtro parametrizado |
| `Demo__2_Count_Filtered_Orders` | Task 2 — contagem para decisão if/else |
| `Demo__4_Aggregation Filtered Orders` | Task 4 — agregação (ramo True) |
| `Demo__5_Log Low Volume Event` | Task 5 — fallback log (ramo False) |

---

## Tipos de Task Disponíveis na UI (Referência Visual)

Ao adicionar uma task no job, o dropdown **Type** mostra:

**Code:** Notebook, Python script, Python wheel, JAR, Spark Submit, Clean Room notebook  
**SQL:** Legacy dashboard, SQL query, SQL alert, SQL file  
**Ingestion and transformation:** Pipeline, New ingestion pipeline, dbt  
**Control flow:** Run Job, If/else condition, For each  
**Other:** Dashboard, Power BI

---

## Criar o Job na UI do Databricks

### Passo a Passo

1. Na barra lateral, ir a **Jobs & Pipelines**.
2. Clicar em **Create** → seleccionar **Job**.
3. O job é criado com uma "Unnamed task" por defeito.
4. Configurar cada task conforme os steps acima.
5. Para adicionar tasks subsequentes, clicar em **+ Add task** no canvas do DAG.

### Campos Principais de Configuração de uma Task SQL

| Campo | Descrição |
|---|---|
| Task name | Identificador único da task no job |
| Type | Tipo de task (ex: SQL) |
| SQL task | Sub-tipo (ex: Query) |
| SQL query | Query guardada no SQL Editor a executar |
| SQL warehouse | Warehouse onde a query corre |
| Depends on | Task(s) upstream de que depende |
| Run if dependencies | Condição: All succeeded, At least one succeeded, etc. |
| Parameters | Pares chave-valor injectados em runtime |

---

## Executar e Monitorizar o Job

### Executar Manualmente

No ecrã do job, clicar em **Run now** para iniciar uma execução manual.

### Vista de Runs

O separador **Runs** mostra:
- Gráfico de duração total por run ao longo do tempo.
- Lista de runs com: Start time, Run ID, Launched, Duration, Status, Error code, Run parameters.

**Informação de Job Details (painel lateral):**
- Job ID
- Creator
- Run as
- Tags / Description
- Lineage (No lineage information for this job — apenas disponível com Unity Catalog e SQL tasks activas)
- Performance optimized
- Schedules & Triggers
- Compute: warehouse associado (ex: `shared_warehouse, 2X-Small, 1 cluster`)
- Job parameters

### Vista de Execução (Graph)

O separador **Graph** de um run mostra o DAG com o estado de cada task:

```
[Demo__1_Filter_Orders_by... ✓ Succeeded 11s]
        │
        ▼
[Demo__2_Count_Filtered... ✓ Succeeded 11s]
        │
        ▼
[Demo__3_Filtered_Order_Co... ✓ Succeeded] <── True activo
        │
   True ──► [Demo__4_Aggregation_Fil... ✓ Succeeded 11s]
   False ──► [Demo__5_Log_Low_Volum... ○ Excluded]
```

> Quando a condição é `True` (count >= 750), a Task 4 executa e a Task 5 fica com estado **Excluded** — não falhou, foi excluída condicionalmente.

### Detalhe de uma Task Run

Ao clicar numa task run específica, podes ver:
- Job ID e Run ID
- Task run ID
- Status (ex: Succeeded)
- Timestamps de início e fim
- Duração
- SQL Query executada
- Compute utilizado
- Lineage da task

---

## Testar o Ramo False (Alterar o Threshold)

Para verificar o comportamento do ramo False, edita a condição da task If/Else para um valor mais alto (ex: `>= 500` alterado para `>= 5000` ou directamente para `>= 500` com um dataset pequeno).

**Exemplo da demo:** o threshold foi alterado de `750` para `500` na condição, mantendo os mesmos dados — o ramo False é então activado e a Task 5 (Log Low Volume Event) executa.

---

## Limpeza (Clean Up)

No final do lab, executar as células de limpeza para remover os artefactos criados:

```python
# Remover todas as SQL Query files criadas no directório home/user
delete_demo_dbsql_queries()
```

```sql
-- Apagar o catálogo único criado para este utilizador (com CASCADE)
-- Isto remove também todos os schemas/tabelas dentro do catálogo
DROP CATALOG IF EXISTS ${DA.user_catalog_name} CASCADE
```

---

## Resumo do Lab

| Step | Task | Tipo | Condição de Execução |
|---|---|---|---|
| 1 | Filter Orders by Priority and Date Range | SQL Query | Sempre (primeira task) |
| 2 | Count Filtered Orders | SQL Query | Após Step 1 com sucesso |
| 3 | Filtered Order Count Test | If/Else | Após Step 2 com sucesso |
| 4 | Aggregation Filtered Orders | SQL Query | Se Step 3 = **True** (count >= 750) |
| 5 | Log Low Volume Event | SQL Query | Se Step 3 = **False** (count < 750) |

**Padrão aprendido:** Filter → Count → Branch → Aggregate *ou* Log  
Este padrão replica o comportamento de uma stored procedure com lógica condicional — mas de forma modular, rastreável e tolerante a falhas.
