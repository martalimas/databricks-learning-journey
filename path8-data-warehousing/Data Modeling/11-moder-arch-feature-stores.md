# Feature Stores — Modern Data Architecture Use Cases

> **Módulo:** Data Warehousing with Databricks — Path 8  
> **Tema:** Modern Data Architecture Use Cases — Feature Stores para ML/AI

---

## Índice

1. [Objectivos do Módulo](#1-objectivos-do-módulo)
2. [Modern Data Modeling para ML e AI](#2-modern-data-modeling-para-ml-e-ai)
3. [O que é um Feature Store](#3-o-que-é-um-feature-store)
4. [Arquitectura de um Feature Store](#4-arquitectura-de-um-feature-store)
5. [Feature Tables](#5-feature-tables)
6. [Tipos de Feature Tables](#6-tipos-de-feature-tables)
7. [Medallion para ML/AI — Modern Use Cases](#7-medallion-para-mlai--modern-use-cases)
8. [Comparação: DWH vs. ML/AI Use Cases](#8-comparação-dwh-vs-mlai-use-cases)

---

## 1. Objectivos do Módulo

Este módulo introduz os use cases modernos orientados a AI/ML, distinguindo-os dos use cases clássicos de DWH, e explora a integração com o Feature Store do Databricks.

- Introduzir use cases AI-driven: **featurization** e **real-time inference**
- Ilustrar o use case moderno (vs. DWH clássico)
- Explorar a abordagem medallion para featurization
- Highlight da integração com Feature Store
- Criar uma feature table e registá-la no Feature Store
- Recap das diferenças entre Inmon, Kimball, Data Vault e abordagem Modern
- Examinar os benefícios da **enhanced medallion architecture**

---

## 2. Modern Data Modeling para ML e AI

O data modeling para ML e AI engloba estruturas e práticas especializadas para suportar o desenvolvimento, deployment e manutenção de sistemas inteligentes.

### Componentes-chave

- **Feature Stores e Feature Tables** — repositório centralizado de features reutilizáveis
- **Data Pipelines** — orquestração do fluxo de dados desde a fonte até ao modelo
- **Model Management** — versionamento, tracking e deployment de modelos

### Importância

- Aumenta a eficiência e eficácia dos workflows de ML/AI.
- Garante **consistência, escalabilidade e reutilização** de features entre diferentes modelos e equipas.

---

## 3. O que é um Feature Store

Um **Feature Store** é um repositório centralizado que gere, armazena e serve features utilizadas em modelos de machine learning.

### Propósito

| Dimensão | Descrição |
|----------|-----------|
| **Consistency** | As features usadas durante o treino e o serving são **idênticas** — elimina o *training-serving skew* |
| **Reusability** | Permite reutilizar features existentes em múltiplos modelos sem re-engenharia |
| **Scalability** | Suporta computação e armazenamento de features em grande escala |

### Core Functions

- **Feature Storage:** armazenamento persistente de features computadas.
- **Feature Serving:** acesso em real-time ou batch para inferência de modelos.
- **Feature Governance:** metadata, lineage e controlos de acesso.

### Benefícios

- Reduz duplicação de esforços de feature engineering.
- Melhora a colaboração entre equipas de data engineering e data science.
- Acelera o deployment de modelos e aumenta a sua fiabilidade.

> **Problema que resolve:** sem Feature Store, a mesma feature é re-calculada de formas ligeiramente diferentes por equipas diferentes, causando inconsistências entre treino e produção.

---

## 4. Arquitectura de um Feature Store

### Componentes Core

| Componente | Função |
|------------|--------|
| **Repository** | Armazena e gere definições de features e metadata |
| **Storage Layer** | Sistemas de armazenamento físico (databases, data lakes) onde os dados residem |
| **Serving Layer** | APIs e serviços que disponibilizam features a modelos ML em real-time ou batch |
| **Registry** | Catálogo de features disponíveis — definições, fontes e estatísticas de utilização |
| **Transformation Layer** | Ferramentas e processos para feature engineering e transformações |

### Workflow

```
Feature Engineering  →  Feature Registration  →  Feature Storage
       ↓                                               ↓
  (Data scientists              (Com metadata)    (No repositório)
   transformam dados)
                                                       ↓
Monitoring & Management  ←  Feature Serving  ←  (Disponível)
(qualidade, uso, performance)   (training + inference)
```

---

## 5. Feature Tables

**Feature Tables** são tabelas estruturadas dentro de um feature store que organizam features relacionadas para use cases ML específicos ou domínios de negócio. Cada linha representa uma instância única de uma feature para uma entidade específica.

### Propósito

- **Logical Grouping:** agrupa features por área temática para gestão e acesso mais fáceis.
- **Performance Optimization:** organiza features de forma alinhada com os workflows ML.
- **Version Control:** gere versões de feature tables para tracking de alterações e reproducibilidade.
- **Access Control:** implementa permissões granulares de acesso.

### Estrutura (colunas típicas)

| Campo | Descrição |
|-------|-----------|
| **Feature Name** | Identificador de cada feature |
| **Data Type** | Tipo de dados (integer, float, string, …) |
| **Description** | Explicação detalhada do propósito e uso da feature |
| **Source** | Origem da feature (raw data, derived, …) |
| **Creation Timestamp** | Quando a feature foi criada ou actualizada pela última vez |

---

## 6. Tipos de Feature Tables

| Tipo | Características | Exemplos de uso |
|------|----------------|-----------------|
| **Static** | Features constantes ao longo do tempo; baixa frequência de update; tipicamente de master data | Atributos geográficos, categorias de produto |
| **Dynamic** | Actualizadas regularmente; alta frequência; derivadas de dados transaccionais ou streaming | Saldo actual, contagem de sessões recentes |
| **Aggregated** | Representam dados agregados; calculadas com funções de agregação (SUM, AVG) | Total de compras dos últimos 30 dias |
| **Temporal** | Capturam alterações e tendências temporais; incorporam pontos históricos; habilitam time-series | Evolução do score de crédito |
| **Composite** | Combinam múltiplos tipos de features de diferentes fontes ou categorias | Perfil completo do cliente para modelos complexos |

---

## 7. Medallion para ML/AI — Modern Use Cases

O medallion architecture para ML/AI difere do DWH clássico nas transformações aplicadas em cada camada:

| Camada | Nome ML/AI | O que acontece | Diferença vs. DWH |
|--------|-----------|----------------|-------------------|
| **bronze** | Landing | Dados brutos no formato original (temporário); landing zone permite Delta independentemente do formato de input | Igual |
| **bronze** | Ingestion | Dados convertidos para Delta (de Avro, CSV, Parquet, XML, JSON); verificação **leve** (schema); **sem business logic**; abordagem *schema on read* | DWH aplica mais transformações aqui |
| **silver** | Curation | Dados limpos (cleansed), filtrados e aumentados (augmented data) | DWH faz refinamento dimensional aqui |
| **gold** | Final | Agregados a nível de negócio; dados mascarados/reduzidos/anonimizados para uso em projectos; denormalizados para performance | DWH serve star schema; ML/AI serve feature tables |

### Diagrama de fluxo

```
Sources
   ↓
Landing (bronze) — Raw data (temp.)
   ↓
Ingestion (bronze) — Verified data (Delta, schema check, sem business logic)
   ↓
Curation (silver) — Cleansed data + Filtered data + Augmented data
   ↓
Final (gold) — Project data + Business-level aggregates
   ↓
Python / R / SQL / Scala  ←  ETL/ELT
```

### Características específicas do uso ML/AI

- **Verification leve no bronze:** no DWH verifica-se o data contract em profundidade; para ML/AI a verificação é mais leve, focada em schema e timeframe básicos.
- **Schema on read:** os dados de ML/AI são frequentemente processados com schema inferido na leitura, não na escrita.
- **Gold para ML:** em vez de star schemas, a camada gold serve feature tables — aggregates de negócio, dados anonimizados e desnormalizados para ingestão directa em modelos.

---

## 8. Comparação: DWH vs. ML/AI Use Cases

| Dimensão | DWH (Kimball/DV) | ML/AI (Feature Store) |
|----------|-----------------|----------------------|
| **Objectivo da gold** | Star schema para BI/reporting | Feature tables para treino e inferência |
| **Consumidores** | Analistas, BI tools | Data scientists, modelos ML |
| **Transformações silver** | Refinamento dimensional, SCD | Cleansing, filtering, augmentation |
| **Consistência crítica** | Entre relatórios | Entre treino e serving (training-serving skew) |
| **Histórico** | SCD Type 2, Data Vault Satellites | Temporal Feature Tables |
| **Acesso** | SQL queries, dashboards | APIs (real-time), batch jobs |
| **Governança** | Data catalog, lineage | Feature Registry, lineage, access controls |

### Recap das 4 abordagens de modeling

| Abordagem | Foco | Camada principal no Databricks |
|-----------|------|-------------------------------|
| **Inmon (EDW)** | Integração centralizada normalizada | silver (3NF) |
| **Kimball (Star Schema)** | Reporting dimensional | gold (DimX + FactX) |
| **Data Vault 2.0** | Auditabilidade + multi-source integration | silver (H/L/S) |
| **Modern (ML/AI)** | Feature engineering + real-time inference | gold (Feature Tables) |

> **Nota para o exame:** a abordagem Modern não substitui as anteriores — tipicamente **coexistem**. O DV pode alimentar o Feature Store; o Kimball serve o BI; as Feature Tables servem os modelos ML.
