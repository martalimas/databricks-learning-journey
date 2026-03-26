# databricks-learning-journey
Data Engineering learning journey with Databricks

# 🚀 Databricks Learning Journey

Repositório de aprendizagem de Data Engineering com foco no Databricks.

## 📚 Contexto

Estudo activo para certificação Databricks através do **Learning Festival 2026**.
Background em ETL e migração de dados — transição para Data Engineering moderno.

## 🗺️ Percurso

### Databricks Learning Festival (16 Mar – 3 Abr 2026)
- [ ] **Path 8 — Data Warehousing Practitioner** ← em curso
  - [x] Data Warehousing with Databricks
  - [ ] SQL Programming and Procedural Logic
  - [ ] Data Modelling Strategies

### A seguir
- [ ] **Path 1 — Associate Data Engineering**
- [ ] **Path 2 — Professional Data Engineering**

## 🏗️ Projecto Prático — TPCDI Pipeline

Pipeline completo construído no Databricks Community Edition
inspirado no benchmark TPC-DI:
```
Bronze (raw) → Silver (clean) → Gold (aggregated)
        ↑
Lakeflow Job (orquestrado)
```

**Stack:** Delta Lake · Serverless SQL · Unity Catalog · Lakeflow Jobs

📁 Ver código em [`path8-data-warehousing/notebooks/`](./path8-data-warehousing/notebooks/)

## 📖 Documentação

| Documento | Descrição |
|-----------|-----------|
| [Guia de Referência](./docs/guia-referencia.md) | Conceitos, paralelos, dúvidas e respostas |
| [Erros Comuns](./docs/erros-comuns.md) | Erros recorrentes em pipelines |
| [Glossário](./docs/glossario.md) | Termos chave com definições rápidas |

## 🔧 Tecnologias

![Databricks](https://img.shields.io/badge/Databricks-FF3621?style=flat&logo=databricks&logoColor=white)
![Apache Spark](https://img.shields.io/badge/Apache%20Spark-E25A1C?style=flat&logo=apachespark&logoColor=white)
![Delta Lake](https://img.shields.io/badge/Delta%20Lake-003366?style=flat)
![SQL](https://img.shields.io/badge/SQL-4479A1?style=flat&logo=postgresql&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)

## 📝 Notas

Este repositório cresce à medida que o percurso avança.
Cada pasta corresponde a um path de certificação diferente.
Os notebooks são exportados do Databricks Community Edition.

