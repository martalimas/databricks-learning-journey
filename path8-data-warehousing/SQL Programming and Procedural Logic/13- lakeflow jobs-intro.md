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
