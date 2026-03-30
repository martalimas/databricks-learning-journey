# Introdução aos Lakeflow Jobs

**Módulo:** SQL Programming and Procedural Logic  
**Secção:** Procedural Logic in Databricks  
**Pathway:** 8 — Data Warehousing Practitioner  
**Formato:** Apenas lecture (10 min) — sem lab nesta secção

---

## Agenda

| Tópico | Duração | Lecture | Demo | Lab |
|---|---|---|---|---|
| Introdução aos Lakeflow Jobs | 10 min | ✓ | | |
| Lakeflow Jobs | 40 min | | ✓ | ✓ |
| Stored Procedure Migration Strategies | 10 min | ✓ | | |

---

## Objectivos de Aprendizagem

No final desta secção deves ser capaz de:

- Mapear as capacidades dos Lakeflow Jobs (pipelines reutilizáveis e parametrizadas) para a função das stored procedures.
- Avaliar as vantagens de usar Lakeflow Jobs em vez de stored procedures.
- Identificar os componentes de um Lakeflow Job no Databricks:
  - Identificar os tipos de task disponíveis.
  - Compreender como passar variáveis entre tasks.
  - Compreender as dependências e a ordem de execução.
  - Gerir recursos de cluster dentro de um workflow.
- Implementar lógica procedural usando tasks em Lakeflow Jobs.
- Orquestrar workflows para replicar a funcionalidade de stored procedures encadeadas.
- Automatizar a execução de jobs através de scheduling, event triggers e execução condicional.

---

## Porquê Lakeflow Jobs?

Os Lakeflow Jobs são a **ferramenta de automação de workflows** oferecida pelo Databricks.

### O Problema: Stored Procedures Ainda Não Estão Disponíveis

Nas plataformas SQL tradicionais, a lógica procedural vive dentro de **stored procedures** — blocos monolíticos que tratam do control flow, atribuição de variáveis e execução dinâmica.

Em Abril de 2025, as stored procedures SQL nativas do Databricks ainda estão em **Private Preview**. Isso significa que precisamos de uma alternativa modular e pronta para produção.

### A Solução: Lakeflow Jobs

Os Lakeflow Jobs fornecem **orquestração modular para lógica SQL no Databricks**. Em vez de embutir toda a lógica numa única stored procedure, cada passo lógico (filtrar, transformar, agregar) torna-se a sua própria **task**.

Características principais:

- Cada job organiza a lógica em **tasks reutilizáveis e executáveis de forma independente**.
- Suporta **control flow, lógica condicional, parâmetros e scheduling**.
- Pode **substituir funcionalmente** as stored procedures hoje — e irá englobá-las quando ficarem disponíveis de forma geral.
- Torna a lógica mais fácil de compreender, testar e adaptar ao longo do tempo.
- Oferece flexibilidade de scheduling e error handling que as stored procedures clássicas nem sempre fornecem.

> **Analogia com SQL Server:** Pensa num Lakeflow Job como um SQL Agent Job cujos steps contêm a lógica das tuas stored procedures — mas com dependências baseadas em DAG, branching condicional, parametrização e lineage integrado.

---

## Componentes de um Lakeflow Job

Um Lakeflow Job é composto por três blocos fundamentais:

| Componente | Função |
|---|---|
| **Tasks** | Unidades individuais de trabalho — executam scripts SQL, notebooks ou Spark Declarative Pipelines |
| **Dependencies** | Definem a sequência e a ordem de execução entre tasks (DAG) |
| **Clusters / Configuração** | Clusters podem ser partilhados entre tasks ou isolados por task; parâmetros podem ser fixos ou passados em runtime |

No nível mais alto está o próprio **Job** — um contentor para o workflow. Dentro dele, as **Tasks** fazem o trabalho real. As tasks são ligadas por **dependências**, formando um **Directed Acyclic Graph (DAG)** que governa a ordem de execução.

```
[SQL Task] ──► [If/Else Task] ──► [SQL Task]
                              └──► [SQL Task]
```

---

## Tipos de Task em Lakeflow Jobs

O Lakeflow suporta múltiplos tipos de task para diferentes necessidades de execução. O curso foca-se nas **SQL tasks** por serem o equivalente mais próximo da lógica de stored procedures.

### Tasks de Código
| Tipo | Descrição |
|---|---|
| Notebook | Executa células num notebook Databricks (SQL, Python, Scala, R) |
| Python script | Executa um ficheiro `.py` |
| Python wheel | Executa uma biblioteca Python empacotada |
| JAR | Executa um JAR Java/Scala |
| Spark submit | Submete um job Spark directamente |
| Clean Room notebook | Executa um notebook num ambiente Clean Room |

### Tasks SQL
| Tipo | Descrição |
|---|---|
| Legacy dashboard | Actualiza um dashboard legado |
| Query | Executa uma query SQL contra um SQL Warehouse |
| Alert | Dispara um alerta SQL |
| SQL File | Executa um ficheiro `.sql` contra um SQL Warehouse |

### Tasks de Ingestão e Transformação
| Tipo | Descrição |
|---|---|
| Pipeline | Executa um Lakeflow Spark Declarative Pipeline |
| dbt | Executa um projecto dbt |

### Tasks de Control Flow
| Tipo | Descrição |
|---|---|
| Run Job | Dispara outro Lakeflow Job |
| If/else condition | Branching condicional baseado no output de uma task anterior |
| For each | Executa a mesma task em paralelo para múltiplos valores de input |

### Foco do Curso: SQL Tasks

A **SQL Task** executa uma ou mais instruções SQL contra um SQL Warehouse. É o tipo de task central deste módulo e a melhor escolha para migrar lógica de stored procedures.

As **Notebook Tasks** são mais indicadas para jobs complexos com loops, UDFs ou ML. Os **Spark Declarative Pipelines** definem transformações e data quality checks de forma declarativa. Python wheels e JARs externos são avançados/experimentais e não são o foco aqui.

---

## Passar Variáveis Entre Tasks

Uma das funcionalidades mais poderosas dos Lakeflow Jobs é a capacidade de **passar valores dinamicamente entre tasks**, tornando os jobs conscientes dos dados em vez de terem valores fixos.

### Como Funciona

Usa a sintaxe de expressão para referenciar o output de uma task anterior:

```
{{tasks.<task_name>.output.first_row.<column_name>}}
```

**Exemplo:** A Task A extrai um intervalo de datas de uma tabela de controlo. A Task B referencia esse output sem fixar a data no código:

```
{{tasks.TASK_A.output.first_row.result}}
```

### Três Formas de Fornecer Input

| Método | Descrição | Ideal para |
|---|---|---|
| **Referência ao output de task** | `{{tasks.TASK_A.output.first_row.col}}` | Encadear tasks dinamicamente |
| **Parâmetros a nível de job** | Definidos no job e injectados em runtime | Orquestradores externos ou utilizadores a fornecerem valores |
| **SQL widgets** | Inputs de parâmetros interactivos dentro de notebooks | Desenvolvimento interactivo e parametrização dentro do notebook |

### O Que Isto Permite

- Filtros condicionais baseados em dados retornados por tasks anteriores.
- Queries dinâmicas dirigidas por valores em runtime.
- Pipelines de reporting específicos por região ou data — usando apenas SQL.

> **Princípio chave:** A passagem de parâmetros é o que transforma uma sequência estática de queries numa pipeline dinâmica e consciente dos dados.

---

## Definir Dependências e Ordem de Execução

As tasks executam na ordem definida pelo seu **grafo de dependências**.

### Directed Acyclic Graph (DAG)

Os Lakeflow Jobs executam com base num DAG. Este grafo define quais tasks têm de ser concluídas antes de outras poderem começar.

- Cada task pode depender de **uma ou mais tasks upstream**.
- Se uma task upstream falhar, as tasks downstream **não executam** (comportamento por defeito) — evitando o processamento de dados parciais ou inválidos.
- O DAG torna os jobs mais fáceis de visualizar, depurar e manter.

```
Filtrar ──► Agregar ──► Escrever ──► Notificar
```

Com branching:

```
[If/Else Task] ──► [TASK_X] ──► [TASK_Z]
               └──► [TASK_Y] ──┘
```

> **Analogia:** Se vens de um contexto de stored procedures, pensa em cada task como um **bloco procedural** e nas dependências como o "fluxo de execução" de um bloco para o seguinte — mas com o DAG a tornar esse fluxo explícito e visual.

---

## Control Flow

A lógica procedural não é apenas sobre sequenciamento — é também sobre **branching, iteração e resiliência**. Os Lakeflow Jobs fornecem estas capacidades através de **configuração a nível de task**, sem código imperativo.

### Mecanismos de Control Flow

| Mecanismo | Como Funciona |
|---|---|
| **If/Else** | Executa uma task apenas se uma task anterior satisfizer critérios de sucesso ou retornar um valor específico |
| **For Each** | Itera sobre uma lista de inputs e executa a mesma task em paralelo (ex: relatórios para múltiplas regiões) |
| **Retry Policies** | Re-executa automaticamente uma task falhada com uma estratégia de backoff configurável — útil para APIs instáveis ou disponibilidade intermitente de ficheiros |
| **Error Handling / Alertas** | Dispara alertas ou lógica de fallback em caso de falha — ex: enviar email ou executar um passo compensatório |

```
[If/Else Task] ── True ──►
               ── False ──► [SQL Task] ──► [SQL Task] ── Falha ──► [Error Notification]
```

Isto replica a lógica condicional que esperarias numa stored procedure, mas de forma mais **modular e tolerante a falhas**.

---

## Scheduling e Triggering de Lakeflow Jobs

Depois de definido o workflow, o passo seguinte é decidir **quando e como deve executar**.

### Métodos de Trigger

| Método | Descrição |
|---|---|
| **Manual** | Executar a partir da UI do Databricks ou programaticamente via Databricks Jobs API |
| **Scheduled — Simples** | Intervalos regulares: hora a hora, diário ou semanal |
| **Scheduled — Avançado** | Usar expressões `cron` ou o visual schedule picker para timing preciso |
| **File-Based** | Trigger quando um ficheiro chega ao cloud storage (ex: S3, ADLS) — ideal para cenários de ingestão de dados |
| **API & Orquestradores Externos** | Integração com Apache Airflow ou Azure Data Factory |
| **Table Updates** | Trigger com base em alterações a uma tabela Delta |

### Referência da UI

O painel **Schedules & Triggers** na UI do Databricks permite:
- Definir o estado do trigger (Active / Paused).
- Escolher o tipo de trigger (Scheduled, File arrival, etc.).
- Alternar entre Simple (selector de intervalo) e Advanced (sintaxe cron).

> **Mapeamento por caso de uso:**
> - Pipeline batch nocturno → Scheduled (cron diário).
> - Reagir a novos dados que chegam → File-based trigger.
> - Orquestração externa já existe → Integração com Airflow/ADF.

---

## Data Lineage no Databricks

### O Que É Data Lineage?

O data lineage é a capacidade de **rastrear dados à medida que fluem da origem para o destino** — através das camadas de ingestão, transformação e consumo.

No Databricks, o lineage opera a múltiplos níveis:

- Captura **operações de leitura/escrita** ao nível de tabela, coluna e query.
- Permite visibilidade através das camadas de **ingestão, transformação e serving**.
- Crítico para **governação, auditoria e depuração**.

**Exemplo:** Um relatório de vendas na camada Gold é construído a partir de um dataset limpo na Silver, que por sua vez vem de um ficheiro bruto no Bronze. O lineage liga esses pontos automaticamente.

O lineage não é apenas uma conveniência de metadados — desempenha um papel crítico na **conformidade com o RGPD**, no rastreamento de erros em dashboards downstream e na redução de recomputações desnecessárias.

---

## Explorar Lineage a Partir de um Lakeflow Job

### Como É Gerado o Lineage

O lineage em Lakeflow Jobs é **derivado automaticamente das execuções de tasks** — não é necessário configurá-lo manualmente.

- Cada **execução de SQL task** contribui com metadados de lineage para o Unity Catalog.
- Sempre que uma task lê ou escreve numa tabela gerida pelo Unity Catalog, essa actividade é registada **até ao nível de coluna**.
- Aplica-se a SQL tasks, notebook tasks e qualquer Lakeflow Job que interaja com recursos do Unity Catalog.

> **Ponto chave:** O lineage está incorporado no motor de execução dos Lakeflow Jobs e é activado automaticamente, desde que uses recursos governados pelo catálogo.

### Que Metadados São Capturados

| Metadado | Descrição |
|---|---|
| Tabelas/views de origem | Quais objectos foram lidos |
| Tabelas/views de destino | Quais objectos foram escritos |
| Colunas acedidas | Quais colunas específicas foram utilizadas |

---

## Ver Lineage no Catalog Explorer

### Como Aceder ao Lineage

1. Navegar para **Unity Catalog → Data → Tables**.
2. Seleccionar uma tabela e clicar no separador **Lineage**.
3. Explorar origens upstream e dependências downstream.
4. Filtrar por workspace, data, utilizador ou job run.

### O Que Podes Ver

- **Lineage upstream:** Quais jobs ou notebooks leram desta tabela.
- **Lineage downstream:** Que novos datasets esta tabela ajuda a produzir.
- **Navegação drill-down:** Clica em qualquer dataset no grafo para explorar o seu próprio lineage — move-te para trás e para a frente no fluxo de dados.

---

## Porquê o Lineage é Importante para Lógica Procedural

O lineage torna-se especialmente importante quando os Lakeflow Jobs crescem em complexidade — múltiplas queries parametrizadas, lógica de branching, condicionais e caminhos de retry.

Sem um mapa visual do fluxo de dados, torna-se difícil raciocinar sobre o impacto de uma única alteração.

| Benefício | O Que Significa na Prática |
|---|---|
| **Observable e explicável** | O workflow é um sistema transparente e rastreável — não uma caixa negra |
| **Dependências ocultas reveladas** | Vês exactamente quais inputs contribuíram para quais outputs |
| **Auditabilidade de conformidade** | Respondes com confiança a "De onde veio este número?" ou "Quem modificou este dataset?" para auditorias RGPD/HIPAA |
| **Optimização** | Identifica leituras/escritas redundantes ou desnecessárias |

---

## Boas Práticas de Lineage em Lakeflow Jobs

| Prática | Porquê |
|---|---|
| **Usar sempre tabelas geridas pelo Unity Catalog** | O lineage só rastreia dados em ambientes governados — escrever em caminhos de storage não geridos perde visibilidade |
| **Evitar caminhos de storage fixos no código** | O lineage opera ao nível do objecto lógico (tabelas, views, colunas) — não ao nível do ficheiro |
| **Modularizar tasks** | Cada task deve representar um único passo lógico; isto cria cadeias de lineage limpas onde cada transformação é isolada e fácil de rastrear |
| **Usar views ou CTAS/RTAS para transformações intermédias** | Os artefactos intermédios tornam os jobs mais fáceis de testar e melhoram a granularidade e a interpretabilidade dos grafos de lineage |

> Com estas práticas, o lineage torna-se um **superpoder integrado** para monitoring, conformidade e depuração.

---

## Resumo

| Conceito | Takeaway Principal |
|---|---|
| **Porquê Lakeflow Jobs** | As stored procedures nativas estão em Private Preview; os Lakeflow Jobs são a alternativa pronta para produção |
| **Componentes do job** | Job → Tasks + Dependencies + Configuração de cluster + Parâmetros |
| **Tipos de task** | SQL Tasks são o foco principal; Notebook e Pipeline tasks para cenários mais complexos |
| **Passagem de variáveis** | Usar `{{tasks.X.output.first_row.col}}` para encadear outputs; parâmetros de job e widgets para input externo |
| **DAG** | A ordem de execução é definida por dependências; falhas bloqueiam tasks downstream por defeito |
| **Control flow** | If/Else, For Each, Retry Policies e Error Handling — todos configurados ao nível da task |
| **Scheduling** | Triggers manuais, cron, file-based, API/externos ou actualizações de tabela |
| **Lineage** | Rastreamento automático ao nível de coluna para todas as tasks com Unity Catalog — sem configuração manual |
| **Boas práticas de lineage** | Usar sempre tabelas Unity Catalog; modularizar tasks; evitar caminhos fixos |
# Introduction to Lakeflow Jobs

**Module:** SQL Programming and Procedural Logic  
**Section:** Procedural Logic in Databricks  
**Pathway:** 8 — Data Warehousing Practitioner  
**Format:** Lecture only (10 min) — no lab in this section

---

## Agenda

| Topic | Time | Lecture | Demo | Lab |
|---|---|---|---|---|
| Introduction to Lakeflow Jobs | 10 min | ✓ | | |
| Lakeflow Jobs | 40 min | | ✓ | ✓ |
| Stored Procedure Migration Strategies | 10 min | ✓ | | |

---

## Learning Objectives

By the end of this section you will be able to:

- Map Lakeflow Job capabilities (reusable, parameterized pipelines) to the function of stored procedures.
- Evaluate the advantages of using Lakeflow Jobs over stored procedures.
- Identify the components of a Lakeflow Job in Databricks.
  - Identify the available task types.
  - Understand how to pass variables between tasks.
  - Understand task dependencies and execution order.
  - Manage cluster resources within a workflow for optimal performance.
- Implement procedural logic using tasks in Lakeflow Jobs.
- Orchestrate workflows to replicate chained stored procedure functionality.
- Establish task dependencies and execution order.
- Implement parameter passing between tasks.
- Automate job execution through scheduling, event triggers, and conditional execution.

---

## Why Lakeflow Jobs?

Lakeflow Jobs is the **workflow automation tool** offered by Databricks. This lecture focuses on why it exists and how it maps to the world you already know — stored procedures.

### The Problem: Stored Procedures Are Not Yet Available

In traditional SQL platforms, procedural logic lives inside **stored procedures** — monolithic blocks that handle control flow, variable assignments, and dynamic execution.

As of April 2025, Databricks' native SQL stored procedures are still in **Private Preview**. That means we need an alternative that is both modular and production-ready.

### The Solution: Lakeflow Jobs

Lakeflow Jobs provide **modular orchestration for SQL logic in Databricks**. Instead of embedding all logic in a single SQL procedure, each logical step (filter, transform, aggregate) becomes its own **task**.

Key characteristics:

- Each job organises logic into **reusable, independently executable tasks**.
- Supports **control flow, conditional logic, parameters, and scheduling**.
- Can **functionally replace** stored procedures today — and will encompass them when native stored procedures become generally available.
- Makes logic easier to reason about, test, and adapt over time.
- Provides scheduling and error handling flexibility that classic stored procedures don't always offer.

> **Analogy for SQL Server background:** Think of a Lakeflow Job as a SQL Agent Job whose steps are your stored procedure logic — but with DAG-based dependencies, conditional branching, parameterisation, and built-in lineage tracking.

---

## Components of a Lakeflow Job

A Lakeflow Job is made up of three building blocks:

| Component | Role |
|---|---|
| **Tasks** | Individual units of work — execute SQL scripts, notebooks, or Spark Declarative Pipelines |
| **Dependencies** | Define sequencing and execution order between tasks (DAG) |
| **Clusters / Configuration** | Clusters can be shared across tasks or isolated per task; parameters can be hardcoded or passed at runtime |

At the top level is the **Job** itself — a container for the workflow. Inside it, **Tasks** do the actual work. Tasks are connected by **dependencies** forming a **Directed Acyclic Graph (DAG)** that governs execution order.

```
[SQL Task] ──► [If/Else Task] ──► [SQL Task]
                              └──► [SQL Task]
```

---

## Task Types in Lakeflow Jobs

Lakeflow supports multiple task types to fit different execution needs. The course focuses on **SQL tasks** as the closest equivalent to stored procedure logic.

### Code Tasks
| Type | Description |
|---|---|
| Notebook | Execute cells in a Databricks notebook (SQL, Python, Scala, R) |
| Python script | Run a `.py` file |
| Python wheel | Run a packaged Python library |
| JAR | Run a Java/Scala JAR |
| Spark submit | Submit a Spark job directly |
| Clean Room notebook | Run a notebook in a Clean Room environment |

### SQL Tasks
| Type | Description |
|---|---|
| Legacy dashboard | Run a legacy dashboard refresh |
| Query | Run a SQL query against a SQL Warehouse |
| Alert | Trigger a SQL alert |
| SQL File | Run a `.sql` file against a SQL Warehouse |

### Ingestion and Transformation Tasks
| Type | Description |
|---|---|
| Pipeline | Execute a Lakeflow Spark Declarative Pipeline |
| dbt | Run a dbt project |

### Control Flow Tasks
| Type | Description |
|---|---|
| Run Job | Trigger another Lakeflow Job |
| If/else condition | Conditional branching based on prior task output |
| For each | Run the same task in parallel for multiple input values |

### Focus for This Course: SQL Tasks

The **SQL Task** runs one or more SQL statements against a SQL Warehouse. It is the core task type of this module and the best choice when migrating logic from stored procedures.

**Notebook Tasks** are better for complex jobs involving loops, UDFs, or ML logic. **Spark Declarative Pipelines** define transformations and data quality checks declaratively. Python wheels and external JARs are advanced/experimental and are not the focus here.

---

## Passing Variables Between Tasks

One of the most powerful features of Lakeflow Jobs is the ability to **pass values dynamically between tasks**, making jobs data-aware rather than hardcoded.

### How It Works

Use the expression syntax to reference output from a prior task:

```
{{tasks.<task_name>.output.first_row.<column_name>}}
```

**Example:** Task A extracts a date range from a control table. Task B references that output without hardcoding the date:

```
{{tasks.TASK_A.output.first_row.result}}
```

### Three Ways to Supply Input

| Method | Description | Best for |
|---|---|---|
| **Task output reference** | `{{tasks.TASK_A.output.first_row.col}}` | Chaining tasks dynamically |
| **Job-level parameters** | Defined at job level, injected at runtime | External orchestrators or users supplying values |
| **SQL widgets** | Interactive parameter inputs inside notebooks | Interactive development and notebook-level parameterisation |

### What This Enables

- Conditional filters based on data returned by previous tasks.
- Dynamic pivot queries driven by runtime values.
- Region-specific or date-specific reporting pipelines — using just SQL.

> **Key principle:** Parameter passing is what turns a static sequence of queries into a dynamic, data-aware pipeline.

---

## Defining Dependencies and Execution Order

Tasks run in the order defined by their **dependency graph**.

### Directed Acyclic Graph (DAG)

Lakeflow Jobs execute based on a DAG. This graph defines which tasks must complete before others can start.

- Each task can depend on **one or more upstream tasks**.
- If an upstream task fails, downstream tasks **do not run** (default behaviour) — preventing processing of partial or invalid data.
- The DAG makes jobs easier to visualise, debug, and maintain.

```
Filter ──► Aggregate ──► Write ──► Notify
```

With branching:

```
[If/Else Task] ──► [TASK_X] ──► [TASK_Z]
               └──► [TASK_Y] ──┘
```

> **Analogy:** If you come from a stored procedure background, think of each task as a **procedural block** and the dependencies as the "execution flow" from one block to the next — except the DAG makes that flow explicit and visual.

---

## Control Flow

Procedural logic isn't just about sequencing — it's also about **branching, iteration, and resilience**. Lakeflow Jobs provide these capabilities through **task-level configuration**, not imperative code.

### Control Flow Mechanisms

| Mechanism | How It Works |
|---|---|
| **If/Else** | Run a task only if a previous task meets success criteria or returns a specific value |
| **For Each** | Iterate over a list of inputs and run the same task in parallel (e.g., reports for multiple regions) |
| **Retry Policies** | Automatically re-run a failed task with a configurable backoff strategy — useful for flaky APIs or intermittent file availability |
| **Error Handling / Alerting** | Trigger alerts or fallback logic on failure — e.g., send an email notification or run a compensating step |

```
[If/Else Task] ── True ──►
               ── False ──► [SQL Task] ──► [SQL Task] ── Failure ──► [Error Notification]
```

This replicates the conditional logic you'd expect in a stored procedure, but in a more **modular and fault-tolerant** way.

---

## Scheduling and Triggering Lakeflow Jobs

Once a workflow is defined, the next step is deciding **when and how it runs**.

### Trigger Methods

| Method | Description |
|---|---|
| **Manual** | Run from the Databricks UI or programmatically via the Databricks Jobs API |
| **Scheduled — Simple** | Regular intervals: hourly, daily, or weekly |
| **Scheduled — Advanced** | Use `cron` expressions or the visual schedule picker for precise timing |
| **File-Based** | Trigger on file arrival in cloud storage (e.g., S3, ADLS) — ideal for data ingestion scenarios |
| **API & External Schedulers** | Integrate with Apache Airflow or Azure Data Factory |
| **Table Updates** | Trigger on changes to a Delta table |

### UI Reference

The **Schedules & Triggers** panel in the Databricks UI allows you to:
- Set trigger status (Active / Paused).
- Choose trigger type (Scheduled, File arrival, etc.).
- Switch between Simple (interval picker) and Advanced (cron syntax) schedule types.

> **Use case mapping:**
> - Nightly batch pipeline → Scheduled (daily cron).
> - React to new data landing → File-based trigger.
> - External orchestration already exists → Airflow/ADF integration.

---

## Data Lineage in Databricks

### What Is Data Lineage?

Data lineage is the ability to **track data as it flows from source to destination** — across ingestion, transformation, and consumption layers.

In Databricks, lineage operates at multiple levels:

- Captures **read/write operations** at the table, column, and query levels.
- Enables visibility across **ingestion, transformation, and serving layers**.
- Critical for **governance, auditing, and debugging**.

**Example:** A sales report in the Gold layer is built from a cleaned dataset in Silver, which comes from a raw file in Bronze. Lineage connects those dots automatically.

Lineage is not just a metadata convenience — it plays a critical role in **GDPR compliance**, tracing errors in downstream dashboards, and reducing unnecessary recomputations.

---

## Explore Lineage From a Lakeflow Job

### How Lineage Is Generated

Lineage in Lakeflow Jobs is **derived automatically from task executions** — you do not have to configure it manually.

- Every **SQL task execution** contributes lineage metadata to Unity Catalog.
- Whenever a task reads from or writes to a Unity Catalog-managed table, that activity is logged **down to the column level**.
- This applies to SQL tasks, notebook tasks, and any Lakeflow Job that interacts with Unity Catalog assets.

> **Key point:** Lineage is built into the Lakeflow Job execution engine and is triggered automatically as long as you are using catalog-governed resources.

### What Metadata Is Captured

| Metadata | Description |
|---|---|
| Source tables/views | Which objects were read |
| Destination tables/views | Which objects were written |
| Columns accessed | Which specific columns were used |

---

## View Lineage in Catalog Explorer

### How to Access Lineage

1. Navigate to **Unity Catalog → Data → Tables**.
2. Select a table and click the **Lineage** tab.
3. Explore upstream sources and downstream dependencies.
4. Filter by workspace, date, user, or job run.

### What You Can See

- **Upstream lineage:** Which jobs or notebooks read from this table.
- **Downstream lineage:** What new datasets this table helps produce.
- **Drill-down navigation:** Click any dataset in the graph to explore its own lineage — move backward and forward in the data flow.

---

## Why Lineage Matters for Procedural Logic

Lineage becomes especially important when Lakeflow Jobs grow complex — multiple parameterised queries, branching logic, conditionals, and retry paths.

Without a visual map of data flow, it becomes difficult to reason about the end-to-end impact of a single change.

| Benefit | What It Means in Practice |
|---|---|
| **Observable and explainable** | Your workflow is a transparent, traceable system — not a black box |
| **Hidden dependencies revealed** | See exactly which inputs contributed to which outputs |
| **Compliance auditability** | Confidently answer "Where did this number come from?" or "Who modified this dataset?" for GDPR/HIPAA audits |
| **Optimization** | Identify redundant or unnecessary reads/writes |

---

## Lineage Best Practices in Lakeflow Jobs

| Practice | Why |
|---|---|
| **Always use Unity Catalog-managed tables** | Lineage can only track data in governed environments — writing to unmanaged storage paths loses visibility |
| **Avoid hardcoded storage paths** | Lineage operates at the logical object level (tables, views, columns) — not at the file level |
| **Modularise tasks** | Each task should represent a single logical step; this creates clean lineage chains where each transformation is isolated and easy to track |
| **Use views or CTAS/RTAS for intermediate transformations** | Intermediate artifacts make jobs easier to test and improve lineage granularity and interpretability |

> With these practices in place, lineage becomes a **built-in superpower** for monitoring, compliance, and debugging.

---

## Summary

| Concept | Key Takeaway |
|---|---|
| **Why Lakeflow Jobs** | Native stored procedures are in Private Preview; Lakeflow Jobs are the production-ready alternative |
| **Job components** | Job → Tasks + Dependencies + Cluster config + Parameters |
| **Task types** | SQL Tasks are the primary focus; Notebook and Pipeline tasks for more complex scenarios |
| **Variable passing** | Use `{{tasks.X.output.first_row.col}}` to chain task outputs; job parameters and widgets for external input |
| **DAG** | Execution order is defined by dependencies; failures block downstream tasks by default |
| **Control flow** | If/Else, For Each, Retry Policies, and Error Handling — all configured at task level |
| **Scheduling** | Manual, cron, file-based, API/external, or table-update triggers |
| **Lineage** | Automatic, column-level tracking for all Unity Catalog-managed tasks — no manual configuration needed |
| **Lineage best practice** | Always use Unity Catalog tables; modularise tasks; avoid hardcoded paths |
