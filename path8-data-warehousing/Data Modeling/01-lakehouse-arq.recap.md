# Data Modeling Strategies — Part 2: Why Model + DWH Foundations

> **Module:** Data Modeling Strategies  
> **Source:** Databricks Learning Festival 2026 — Pathway 8: Data Warehousing Practitioner  
> **Scope:** DWH Data Modeling rationale, methodology overview, logical modeling concepts, DWH build process

---

## Why Model? — DWH Data Modeling

A data warehouse is used by **business users** to evaluate and make business decisions.  
Data warehouse data needs to be modeled to:

- Correctly **represent the business**
- Ensure that insights and decisions based on the data warehouse are **impactful**

### How?

| Step | What it involves |
|---|---|
| Understand the business | Its actors, relationships, processes, requirements |
| Create a logical data model | Formal model of the organisation's business processes and needs |
| Ensure data quality | Accurate, consistent, and well-organised |
| Enable BI support | Analytics, reporting, and effective business intelligence |

**Modeling flow:**

```
Business Model          →   Logical Model         →   DWH Implementation    →   BI, Analytics
(processes, actors,         (formal business           (technology-specific)      & Reporting
 relationships,              model, technology-
 requirements)               agnostic)
```

---

## Data Modeling Methods — Three Schools of Thought

Historically, three dominant methodologies for data warehousing practitioners:

| Method | Author | Book | Year |
|---|---|---|---|
| **Top-down approach** | Bill Inmon | *Building the Data Warehouse* | 1992 |
| **Bottom-up approach** | Ralph Kimball | *The Data Warehouse Toolkit* | 1996 |
| **Data Vault 2.0** | Dan Linstedt | *Building a Scalable Data Warehouse with Data Vault 2.0* | 2015 |

---

## Data Warehousing — Purpose of Modeling

```
                        Business Requirements
                          (Information Need)
                                 │
              ┌──────────────────┼─────────────────────┐
              │   Data Warehouse Environment            │
              │                                         │
              │   ┌─────────────────────────────────┐  │
              │   │     Business Information Model  │  │
              │   └───────┬──────────────┬──────────┘  │
              │           │              │              │
              │   ┌───────▼──────┐  ┌───▼──────────┐  │
              │   │ DWH Logical  │  │ Data Marts   │  │
              │   │ Data Model   │  │ Logical DM   │  │
              │   │    (LDM)     │  │    (LDM)     │  │
              │   └───────┬──────┘  └──────┬───────┘  │
              │           │                │           │
Sources ──►  │   ┌───────▼──────┐  ┌──────▼───────┐  │  ──► Apps
(RDBMS,      │   │  Physical    │  │  Data Mart   │  │  ──► BI Tools
 Files/Logs, │   │  Staging Mdl │  │              │  │
 Biz Apps,   │   └──────────────┘  └──────────────┘  │
 Clouds)     └──────────────────────────────────────────┘
             Source    Ingest    Integration   Delivery
```

---

## Context for Concepts

> The Inmon approach provides a **methodology-agnostic conceptual foundation** for data modeling.

Key concepts originating with Inmon — such as the **logical model** — translate effectively into the terminologies of competing methodologies (ontologies and taxonomies used in Kimball and Data Vault).

This means: learn Inmon's vocabulary once, apply it everywhere.

---

## Logical Data Modeling — Key Terms

| Term | Definition |
|---|---|
| **Entity** | Person, place, thing, or concept about which you wish to record facts |
| **Attribute** | A non-decomposable, atomic piece of information describing an entity |
| **Non-Decomposable** | The smallest unit of information you will want to reference |
| **Business rules** | Specifications that preserve the integrity of the LDM by governing which values attributes may assume |

### Business Rules — Two Categories

- **Key business rules** — the identification of unique records
- **Domain business rules** — validation of attribute values

---

## Logical Data Modeling — Optimal Approach

A good logical data model should satisfy six qualities:

| # | Quality | Definition |
|---|---|---|
| 1 | **Structural validity** | Consistency with how the business defines and organises information |
| 2 | **Simplicity** | Ease of understanding |
| 3 | **No redundancy** | No extraneous information |
| 4 | **Shareability** | Not specific to one solution — usable by many |
| 5 | **Extensibility** | Ability to evolve with minimal effect on the existing base |
| 6 | **Integrity** | Consistency with the way the business uses and manages information values |

---

## Building a DWH — The Process

Models are **front-and-center** when building a data warehouse. Three model types:

| Model | Definition |
|---|---|
| **Business Information Model (BIM)** | Models actors, their relations, and how they interact — "how the business works" |
| **Logical Data Model (LDM)** | Model of the data associated with the BIM |
| **Physical Data Model (PDM)** | The implemented data model derived from the LDM |

Models **describe the business world** and its relationships — they depict business processes within the organisation, and generate the business context required to create meaningful information from data.

### Simplified DWH Process

```
ANALYZE                    DESIGN                        BUILD
──────────────────         ──────────────────────        ──────────────────────
Business requirements  ──► Data Staging Design      ──► Source Data in Staging

Business Information
Model
        │
        ▼
Logical Data Model     ──► Physical Data Modeling    ──► DWH Implementation

Data Mart Logical
Data Model             ──► Data Mart Physical
                            Data Modeling

Source Data Analysis

Source Mapping         ──► ETL Design               ──► ETL Development
                                                           ▲
                                                    (feeds back into
                                                     DWH Implementation)
```

### The Three Phases Explained

| Phase | Characteristics |
|---|---|
| **Analyze** | Technology-agnostic — pure business understanding |
| **Design** | Impacted by technology and understandability for consumers |
| **Build** | Uses the actual technology to implement the physical model and ETL processes |

---

## Data Warehousing in the Lakehouse

When migrating or implementing a DWH, the data architect is typically **not in a position to dictate** which legacy methodologies the business uses.

**The Databricks advantage:**

- The Lakehouse can easily support the **harmonious coexistence** of as many legacy DWH methodologies as the business requires (Inmon + Kimball + Data Vault can all live together)
- A well-architected Lakehouse **opens new opportunities** to apply data warehouse data to modern use cases (ML, real-time analytics, AI)

> Key insight: You don't have to pick one methodology and throw away the rest. The Lakehouse is flexible enough to host all of them simultaneously.

---

*Notes generated from Databricks Learning Festival 2026 slides — repo: `github.com/martalimas/databricks-learning-journey`*
