# Data Modeling Strategies — Part 1: Lakehouse Foundation

> **Module:** Data Modeling Strategies  
> **Source:** Databricks Learning Festival 2026 — Pathway 8: Data Warehousing Practitioner  
> **Scope of these notes:** Intro + Lakehouse Architecture Recap (foundation slides before Inmon/Kimball/Data Vault)

---

## Objectives

By the end of this module you should be able to:

- Understand **Bill Inmon's top-down (3NF)** approach  
- Map **Inmon's EDW concepts** to Databricks medallion layers  
- Summarise **Kimball's bottom-up, star schema-driven** approach (facts/dimensions)  
- Illustrate how **star schemas integrate with the Lakehouse**  
- Understand **Data Vault 2.0's** Hubs, Links, and Satellites for agile schema evolution  
- Compare **Data Vault to Inmon/Kimball**

---

## Content Map

```
Inmon's Corporate        Kimball's Dimensional      Data Vault 2.0
Information Factory  →   Modeling              →
─────────────────────    ──────────────────────    ──────────────────────
Overview of Inmon        Fact vs. Dimension;        Hubs (business keys),
methodology;             Conformed dimensions,      Links (relationships),
Strengths (governance,   SCD types; Kimball vs.     Satellites (attributes);
single source of truth)  medallion alignment;       TPC-H mapping example;
vs. limitations          Surrogate keys &           Strengths (historization,
                         dimension creation;        incremental loads)
                         Fact table referencing     vs. complexity
                         dimension keys
```

---

## Lakehouse Architecture Recap

> *This module builds on top of Lakehouse principles — all modeling decisions are shaped by the Lakehouse framework.*

| Principle | What it means for data modeling |
|---|---|
| Modeling decisions depend on governance, processing & storage layers | Medallion Architecture (Bronze → Silver → Gold) dictates **where** and **how** data is transformed |
| Unity Catalog enforces governance & interoperability | Schema consistency, lineage tracking, and access control impact how we model data across domains |
| Bridging AI and BI | Data models must serve **both** structured analytics (BI) and feature engineering (AI/ML) workloads |

---

## Core Principles & Medallion Architecture

### The Lakehouse Combines Data Lakes & Warehouses

- Eliminates silos by supporting both **structured and unstructured** data in a single platform.

### Medallion Architecture (Bronze → Silver → Gold)

| Layer | Role | Key characteristics |
|---|---|---|
| **Bronze** | Raw ingestion | No processing; data kept to fix mistakes; historical record-keeping |
| **Silver** | Curated / Cleansed | Cleaned, conformed & enriched; directly queryable; PII masking/redaction |
| **Gold** | Final / Optimised | Denormalised, read-optimised; project/use-case specific; supports BI, ML & analytics |

> **Flow:** Bronze → *(Spark stream)* → Silver → Gold  
> Gold can branch into: time series resampled & interpolated / feature reduction / feature enhanced

### Schema Enforcement & Governance

- Supports open formats like **Delta Lake** while enforcing schema consistency.

### Built for Performance & Scale

- Combines **ACID transactions**, indexing, and caching for high-performance querying.

---

## Modern Data and AI Platform — Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│  ETL & DS tools              │  BI Tools                    │
├─────────────────────────────────────────────────────────────┤
│                     Orchestration                           │
├────────────────────┬──────────────────────┬─────────────────┤
│  Ingest & Transform│ Advanced Analytics,  │  Data Warehouse │
│                    │ ML & AI              │                 │
├────────────────────┴──────────────────────┴─────────────────┤
│                       AI Engine                             │
├─────────────────────────────────────────────────────────────┤
│                  Data & AI Governance                       │
├─────────────────────────────────────────────────────────────┤
│                     Cloud Storage                           │
└─────────────────────────────────────────────────────────────┘
```

Personas served: **Data Engineer · ML Engineer · Data Scientist · Business Analyst · Business Partners**

---

## Unity Catalog for Governance & Modeling

> *Unity Catalog is the governance backbone that makes consistent data modeling possible across the Lakehouse.*

| Capability | Detail |
|---|---|
| **Centralized Governance** | Manages schemas, tables, and permissions across all workspaces and clouds |
| **Schema Enforcement & Data Lineage** | Tracks data movement, transformations, and dependencies for model reproducibility |
| **Fine-Grained Access Control** | Column- and row-level permissions — data is secure yet accessible |
| **Cross-Domain Interoperability** | Consistent definitions across teams; avoids **schema drift** |
| **Multi-Cloud & Open Formats** | Governed access to Delta Lake, Parquet, and other formats |

### Before vs. After Unity Catalog

**Before:** Each workspace had its own isolated User/group management, Metastore, Access controls, and Compute resources.

**After (With Unity Catalog):** A single Unity Catalog layer (User/group management + Metastore + Access controls) is shared across all workspaces; each workspace retains its own Compute resources.

### Unity Catalog Object Hierarchy

```
Databricks Account
  └── (Unity) Metastore
        └── Catalog
              └── Schema
                    ├── Table
                    ├── View
                    ├── Volume
                    ├── Function
                    └── Model
```

**Three-part naming convention:**
```sql
SELECT * FROM catalog1.schema1.table1;
```

---

## Data Intelligence & Feature Engineering

> *A well-modeled Lakehouse serves both BI and AI simultaneously.*

| Concept | Key point |
|---|---|
| **Lakehouse supports both BI & AI** | SQL analytics, BI dashboards, and AI-driven feature engineering coexist in a unified architecture |
| **Feature Engineering needs scalable pipelines** | AI workloads require real-time **and** batch processing for feature extraction & transformation |
| **Feature Stores** | Prevent "training-serving skew" by storing **reusable, versioned features** across ML pipelines |
| **Data Intelligence** | Combines predictive modeling with historical analytics for deeper insights |
| **Real-Time & Batch Inference** | ML models leverage streaming + historical data for accurate, real-time decisioning |

---

## Mosaic AI — End-to-End AI Capabilities

Databricks' AI layer is called **Mosaic AI** and is fully integrated into the Data Intelligence Platform.

### High-level capability blocks

| Block | What it does |
|---|---|
| **MLOps + LLMOps** | Move code, data, and models between development and production; manage models, features, experiments |
| **Prepare Data** | Discover & transform structured data into features; chunk & create embeddings from unstructured data |
| **Develop & Evaluate AI** | Train/test algorithms; fine-tune & prompt engineer models; create GenAI agents; evaluate experiments |
| **Serve Data & AI** | Low-latency model & feature serving; log model requests/responses; query embeddings in Vector DB |
| **AI Engine** | AI-driven discovery & search, AI Assistant, performance optimization & scaling |
| **Data & AI Governance** | Security & permissions; model lineage; data monitoring; AI monitoring (metrics, quality, drift) |

### Mosaic AI — Specific Tools (integrated into Lakehouse)

| Area | Mosaic AI tools |
|---|---|
| MLOps / LLMOps | MLflow, Asset Bundles (CI/CD) |
| Develop & Evaluate | AutoML, AI Playground, Model Training, Agent Framework, Agent Evaluation |
| Serve Apps | AI Gateway, Model Serving, AI Functions, Databricks Apps |
| Serve Data | Function Serving, Feature Serving, Vector Search |
| Governance | Model Registry in UC, Feature Store in UC, Tools Catalog in UC, Models in Marketplace |
| External integrations | HuggingFace, OpenAI, LangChain, … |

---

## Key Takeaways — How Lakehouse Architecture Shapes Data Modeling

| Takeaway | Why it matters |
|---|---|
| The Lakehouse integrates structured & unstructured data | Supports BI, ML, and real-time analytics in a single framework |
| Medallion Architecture provides a structured data flow | Bronze (raw) → Silver (cleansed) → Gold (optimised) defines **where** and **how** data models are applied |
| Unity Catalog enforces governance & consistency | Standardised schemas, access control, and lineage tracking enable trustworthy data modeling |
| Feature Stores bridge AI & business analytics | Ensures consistent, versioned feature definitions across training & inference workflows |
| A strong data modeling strategy builds on these principles | Data remains scalable, governed, and optimised for AI & analytics |

---

## What's Coming Next

The next sections of the module deep-dive into the three major data modeling strategies, each building on this Lakehouse foundation:

1. **Inmon's Corporate Information Factory** — top-down, 3NF, EDW → mapped to medallion layers  
2. **Kimball's Dimensional Modeling** — bottom-up, star schemas, facts & dimensions → integrated with Lakehouse  
3. **Data Vault 2.0** — Hubs / Links / Satellites, agile schema evolution → TPC-H mapping example  

---

*Notes generated from Databricks Learning Festival 2026 slides — repo: `github.com/martalimas/databricks-learning-journey`*
