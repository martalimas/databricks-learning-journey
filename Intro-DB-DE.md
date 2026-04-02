# Get Started with Databricks for Data Engineering

> **Curso:** Using Databricks for Data Engineering  
> **Fonte:** Databricks Learning Festival 2026 — Pathway 8  
> **Notas em:** Português 🇵🇹

---

## Índice

1. [Introdução ao Data Engineering](#1-introdução-ao-data-engineering)
2. [Arquitetura de Alto Nível](#2-arquitetura-de-alto-nível)
3. [Desafios Comuns](#3-desafios-comuns)
4. [A Plataforma Databricks — Visão Geral](#4-a-plataforma-databricks--visão-geral)
5. [Lakeflow — Visão Geral](#5-lakeflow--visão-geral)
6. [Lakeflow Connect — Conectores](#6-lakeflow-connect--conectores)
7. [Delta Lake — Visão Geral](#7-delta-lake--visão-geral)
8. [Delta Lake — Funcionalidades Chave](#8-delta-lake--funcionalidades-chave)
9. [Demo: Criar e Trabalhar com uma Delta Table](#9-demo-criar-e-trabalhar-com-uma-delta-table)
10. [Lakeflow Connect — Técnicas de Ingestão](#10-lakeflow-connect--técnicas-de-ingestão)
11. [Demo: Ingerir Dados no Delta Lake](#11-demo-ingerir-dados-no-delta-lake)
12. [Data Transformation — Arquitetura Medallion](#12-data-transformation--arquitetura-medallion)
13. [ETL com Lakeflow Spark Declarative Pipelines](#13-etl-com-lakeflow-spark-declarative-pipelines)
14. [Unified Orchestration com Lakeflow Jobs](#14-unified-orchestration-com-lakeflow-jobs)
15. [Recap dos Objetivos de Aprendizagem](#15-recap-dos-objetivos-de-aprendizagem)
16. [Próximos Passos](#16-próximos-passos)

---

## 1. Introdução ao Data Engineering

### Responsabilidades Chave

| Responsabilidade | Descrição | Detalhes |
|---|---|---|
| **Transformar dados brutos em dados limpos e fiáveis** | Processo de ETL | Extração de diversas fontes; limpeza de erros e inconsistências; transformação para formato estruturado e utilizável |
| **Garantir qualidade e integridade dos dados** | Data Quality | Desenvolver processos para monitorizar precisão, consistência e fiabilidade; manter dados confiáveis |
| **Desenhar, construir e manter pipelines de dados** | Pipeline Engineering | Caminhos pelos quais os dados fluem de várias fontes para sistemas de armazenamento e ferramentas analíticas; criar, otimizar e automatizar estas pipelines |

---

## 2. Arquitetura de Alto Nível

A arquitetura de Data Engineering evolui progressivamente com camadas adicionais:

```
Data Sources ──► Ingestion ──► [ Data Processing ] ──► Data Warehousing & BI
                               [ Data Storage    ] ──► Data Science & ML
                                                  ──► Data Sharing
                          ──── Orchestration ────
          ───────── Data Governance, Access and Security ──────────
```

**Componentes:**

- **Data Sources** — Bases de dados, ficheiros, cloud storage, IoT/sensores
- **Ingestion** — Processo de trazer dados das fontes para o sistema
- **Data Processing** — Transformação e processamento dos dados ingeridos
- **Data Storage** — Armazenamento persistente (Data Lake, Lakehouse)
- **Consumidores finais:**
  - Data Warehousing e Business Intelligence
  - Data Science e Machine Learning
  - Data Sharing
- **Orchestration** — Coordenação e agendamento dos processos
- **Data Governance, Access and Security** — Camada transversal de governança

---

## 3. Desafios Comuns

As organizações tipicamente utilizam **uma variedade de technology stacks** para gerir o processo de Data Engineering, o que introduz **vários desafios**:

### Métodos de Ingestão Complexos
- Ingestão em streaming
- Tracking manual de ficheiros para ingestão
- Gestão de tarefas de ingestão propensas a erros

### Suporte a Princípios Chave de Data Engineering
- Desenvolvimento ágil, CI/CD e controlo de versões
- Ambientes de desenvolvimento e produção isolados

### Ferramentas de Orquestração de Terceiros
- Aumenta o overhead operacional e a complexidade do sistema
- Requer competências avançadas e expertise específica
- Inconsistências entre plataformas

> 💡 **Conclusão:** A proliferação de ferramentas heterogéneas cria fricção, custo e risco. A Databricks propõe uma plataforma unificada para resolver estes problemas.

---

## 4. A Plataforma Databricks — Visão Geral

**"Simplify Data Engineering Using the Databricks Data Intelligence Platform"**

```
┌─────────────────────────────────────────────────────────────────────┐
│  🔮 UNITY CATALOG — Data Governance, Access and Security           │
├──────────────┬──────────────────────────────────┬───────────────────┤
│ Data Sources │    LAKEFLOW SPARK DECLARATIVE     │  DBSQL            │
│              │         PIPELINES                 │  Data Warehousing │
│  [DB] [file] │                                   │  & BI             │
│  [cloud][IoT]│  LAKEFLOW CONNECT    Data         ├───────────────────┤
│              │  ┌─────────────┐   Processing     │  MOSAIC AI        │
│              │  │ Ingestion   │  Apache Spark     │  Data Science     │
│              │  │ CREATE TABLE│  + Photon        │  & ML             │
│              │  │ COPY INTO   ├──────────────    ├───────────────────┤
│              │  │ AUTO LOADER │  DELTA LAKE       │  DELTA SHARING    │
│              │  └─────────────┘  Cloud Data Lake  │  Data Sharing     │
│              │                   aws  Azure  GCP  │                   │
├──────────────┴──────────────────────────────────┴───────────────────┤
│  📋 LAKEFLOW JOBS — Orchestration                                   │
└─────────────────────────────────────────────────────────────────────┘
```

**Mapeamento de componentes Databricks → Arquitetura tradicional:**

| Componente Databricks | Papel na Arquitetura |
|---|---|
| **Lakeflow Connect** | Ingestão (CREATE TABLE, COPY INTO, AUTO LOADER) |
| **Lakeflow Spark Declarative Pipelines** | Processamento e transformação de dados |
| **Delta Lake** | Armazenamento (Cloud Data Lake) |
| **DBSQL** | Data Warehousing e Business Intelligence |
| **Mosaic AI** | Data Science e Machine Learning |
| **Delta Sharing** | Partilha de dados |
| **Lakeflow Jobs** | Orquestração |
| **Unity Catalog** | Governança, acesso e segurança |

---

## 5. Lakeflow — Visão Geral

**Lakeflow** é o conjunto de produtos Databricks para **dataflow fiável e automatizado** a partir de sistemas de registo (*systems-of-record*).

### Posicionamento no ecossistema Databricks

```
┌────────────────────────────────────────────────────────┐
│                   Unity Catalog                        │
│              (Knowledge of your data)                  │
│     Your data stored in an open, broadly accessible   │
│                  lakehouse format                      │
├──────────┬──────────────┬──────────────┬───────────────┤
│Lakeflow  │ Databricks   │   AI/BI      │  Mosaic AI    │
│Ingest,   │ SQL Data     │ Business     │ Artificial    │
│ETL,      │ Warehousing  │ Intelligence │ Intelligence  │
│Streaming │              │              │               │
└──────────┴──────────────┴──────────────┴───────────────┘
```

### Os 3 Pilares do Lakeflow

| Produto | Nome Anterior | Função |
|---|---|---|
| **Lakeflow Connect** | — | Ligar fontes de dados ao lakehouse |
| **Lakeflow Spark Declarative Pipelines** | DLT (Delta Live Tables) | Pipelines ETL declarativas e fiáveis |
| **Lakeflow Jobs** | Workflows | Orquestração unificada de analytics e AI |

**Fontes suportadas pelo Lakeflow Connect:**
Azure Data Lake Storage, Google Cloud Storage, AWS S3, Oracle Database, PostgreSQL, MySQL, SQL Server, Salesforce, Workday, Google Analytics, ServiceNow, Google Ads, Oracle NetSuite, SharePoint, Dynamics 365

---

## 6. Lakeflow Connect — Conectores

### Upload de Ficheiros
- Upload de ficheiros locais para o Databricks
- Upload para um Volume
- Criar uma tabela a partir de um ficheiro local

### Standard Connectors
Ingestão de dados no lakehouse a partir de várias fontes e métodos:

**Fontes Suportadas:**
- Cloud Object Storage
- Kafka
- Outras fontes

**Métodos de Ingestão:**
- Batch
- Incremental Batch
- Streaming

### Managed Connectors
Ingestão a partir de:
- **Software as a Service (SaaS)** — Salesforce, Google Analytics, Oracle NetSuite, Dynamics 365, Workday, SharePoint, Google Ads, ServiceNow, Meta, e muitos mais
- **Bases de dados** — Oracle, PostgreSQL, MySQL, SQL Server, MongoDB, IBM DB2, Amazon DynamoDB, e muitos mais

**Leituras e escritas incrementais** para tornar a ingestão mais rápida, escalável e cost-efficient.

**Características dos Managed Connectors:**
- Design sem código (*no code*), baixa manutenção
- Pipelines seguras e saudáveis
- Alta escala e alto desempenho

---

## 7. Delta Lake — Visão Geral

### O que é o Delta Lake?

O **Delta Lake** é um protocolo open-source para leitura e escrita de ficheiros em cloud storage.

```
Data Sources ──► Ingestion ──► Lakehouse
                               ┌─────────────────────────┐
                               │  Data Processing        │
                               ├─────────────────────────┤
                               │  Parquet (formato base) │
                               │  Iceberg                │
                               │  ▶ DELTA LAKE ◀         │
                               ├─────────────────────────┤
                               │  Cloud Data Lake        │
                               │  aws  Azure  GCP        │
                               └─────────────────────────┘
```

### Estrutura Física de uma Delta Table

```
DeltaTableName/
├── ficheiro1.parquet      ← dados
├── ficheiro2.parquet      ← dados
├── ficheiro3.parquet      ← dados
├── ficheiro4.parquet      ← dados
└── _delta_log/            ← transaction log
    ├── 0000.json
    ├── 0001.json
    └── 0002.json
```

- **Dados** armazenados como **ficheiros Parquet**
- **Metadados** armazenados como **transaction logs** na pasta `_delta_log/`

### Delta Lake é o Formato Padrão no Databricks

> ⚠️ **Delta Lake é o formato default para todas as tabelas criadas no Databricks.**

```sql
-- SQL: USING DELTA é opcional (é o default)
CREATE TABLE orders
-- USING DELTA  ← desnecessário, mas válido
AS SELECT ...
```

```python
# Python: .format("delta") é opcional (é o default)
df.write
  # .format("delta")  ← desnecessário, mas válido
  .saveAsTable("mytable")
```

---

## 8. Delta Lake — Funcionalidades Chave

### 1. ACID Transactions

O Delta Lake fornece garantias transacionais ACID ao nível da tabela para dados armazenados em **cloud object storage**.

| Propriedade | Significado |
|---|---|
| **A**tomicity | A transação completa integralmente ou não executa |
| **C**onsistency | Os dados seguem as regras ou são revertidos (*rolled back*) |
| **I**solation | Uma transação completa antes de outra começar |
| **D**urability | Os dados são guardados de forma persistente após conclusão |

### 2. DML Operations

O Delta Lake suporta operações de **Data Manipulation Language**:

```sql
-- Adicionar novas linhas
INSERT INTO mytable VALUES (...)

-- Atualizar valores existentes
UPDATE mytable SET coluna = valor WHERE condição

-- Eliminar linhas
DELETE FROM mytable WHERE condição

-- Selecionar registos de uma tabela fonte e executar múltiplas
-- operações DML numa tabela destino
MERGE INTO mytable AS target
USING source_table AS source
ON target.id = source.id
WHEN MATCHED THEN UPDATE SET ...
WHEN NOT MATCHED THEN INSERT ...
```

### 3. Time Travel

Cada operação de escrita numa Delta table cria automaticamente uma **nova versão**, registada no transaction log.

**Capacidades do Time Travel:**
- Consultar dados históricos (*query historical data*)
- Garantir isolamento de snapshots
- Restaurar versões anteriores

#### Sintaxe — Por Timestamp
```sql
SELECT * FROM my_table
TIMESTAMP AS OF ('2025-06-09')
```

#### Sintaxe — Por Versão
```sql
SELECT * FROM my_table
VERSION AS OF 1
```

#### Ver Histórico de Alterações da Tabela

**Método 1 — DESCRIBE HISTORY:**
```sql
DESCRIBE HISTORY my_table;
-- Colunas: version, timestamp, userId, userName, operation
```

**Método 2 — Table UI:**
Ir à secção **History** da tabela no Catalog Explorer (Unity Catalog).

### 4. Schema Evolution e Schema Enforcement

| Feature | Comportamento |
|---|---|
| **Schema Evolution** | Ajusta automaticamente o schema da Delta table quando os dados mudam |
| **Schema Enforcement** | Garante que qualquer dado escrito na Delta table corresponde ao schema definido |

### 5. Outras Funcionalidades (Many More!)

- **Unified Batch and Streaming** — Uma única API para batch e streaming
- **Performance** — Otimizações de leitura/escrita
- **Scalable Metadata** — Metadados escaláveis para tabelas muito grandes
- **Optimization** — Compactação automática de ficheiros Parquet
- **Delta Lake é Open Source!** 🔓

---

## 9. Demo: Criar e Trabalhar com uma Delta Table

> **Pré-requisito:** Selecionar **Classic Compute** (não Serverless — está ativo por default)

### A. Explorar o Catálogo

#### O Modelo de Objetos do Unity Catalog

```
Metastore
├── Storage credential
├── External location
├── Share / Recipient / Provider / Connection
└── Catalog
    └── Schema (= Database)
        ├── Table
        ├── View
        ├── Volume
        ├── Model
        └── Function
```

> **Namespace de 3 níveis:** `catalog.schema.objeto` (tabela, view, volume, model, função)

#### 1. Visualizar o Catálogo e Schema

```
1. Clicar no ícone Catalog na barra de navegação esquerda
2. Expandir o catálogo dbacademy
3. Localizar o schema único (labuser...)
4. Expandir o schema → contém apenas um Volume chamado myfiles
5. Expandir o volume → contém um ficheiro employees.csv
```

#### 2. Configurar Catálogo e Schema Padrão

```sql
%sql
USE CATALOG dbacademy;
USE SCHEMA IDENTIFIER(DA.schema_name);
-- IDENTIFIER: interpreta uma string constante como nome de objeto
-- Pode interpretar: Relation, Function, Column, Field, Schema, Catalog

SELECT current_catalog(), current_schema();
```

> **Nota:** `IDENTIFIER` é necessário quando o nome do schema está numa variável SQL. Alternativamente, pode-se usar o nome diretamente sem a cláusula IDENTIFIER.

#### 3. Descrever o Schema

```sql
%sql
DESCRIBE SCHEMA EXTENDED IDENTIFIER(DA.schema_name);
```

#### 4. Mostrar Tabelas

```sql
%sql
SHOW TABLES;
-- Resultado esperado: sem tabelas (schema vazio inicialmente)
```

#### 5. Mostrar Volumes

```sql
%sql
SHOW VOLUMES;
-- Resultado: volume myfiles
```

> **O que são Volumes?** Objetos do Unity Catalog que representam um volume lógico de armazenamento numa localização de cloud object storage. Fornecem capacidades de acesso, armazenamento, governança e organização de ficheiros. Enquanto as **tabelas** gerem datasets tabulares, os **volumes** gerem datasets não-tabulares (qualquer formato: estruturado, semi-estruturado, não-estruturado).

#### 6. Listar Ficheiros num Volume

```python
spark.sql(f"LIST '/Volumes/dbacademy/{DA.schema_name}/myfiles'").display()
```

> **Formato do caminho de um Volume:** `/Volumes/catalog_name/schema_name/volume_name/`

### B. Criar uma Delta Table a partir de um CSV

#### Ler o ficheiro como texto (para inspeção)

```sql
%sql
SELECT * FROM text.`/Volumes/dbacademy/{DA.schema_name}/myfiles/`
-- A 1ª linha são os nomes das colunas, separadas por vírgulas
```

```python
spark.sql(f"""
  SELECT * 
  FROM text.`/Volumes/dbacademy/{DA.schema_name}/myfiles/`
""").display()
```

#### Ler CSV com a Table-Valued Function `read_files()`

```sql
%sql
SELECT *
FROM read_files(
  '/Volumes/dbacademy/' || DA.schema_name || '/myfiles/',
  format => 'csv',
  header => true,
  inferSchema => true
)
-- Nota: uma coluna "_rescued_data" é fornecida por default
-- para dados que não correspondam ao schema inferido
```

> **Resultado esperado:** 4 funcionários com nomes de colunas válidos.

#### Criar Delta Table com CTAS (CREATE TABLE AS SELECT)

```sql
%sql
-- Remover tabela se já existir (para demo)
DROP TABLE IF EXISTS current_employees;

-- Criar Delta table a partir do ficheiro CSV
CREATE TABLE current_employees AS
SELECT
  ID,
  FirstName,
  Country,
  Role
FROM read_files(
  '/Volumes/dbacademy/' || DA.schema_name || '/myfiles/',
  format => 'csv',
  header => true,
  inferSchema => true
);

-- O CREATE TABLE cria uma Delta table por default
```

> **Verificar no Catalog:** dbacademy > schema > Tables > `current_employees` ✅

#### [Opcional] Criar Delta Table com Python/PySpark

```python
# Ler o CSV para um Spark DataFrame
sdf = (
    spark
    .read
    .format("csv")
    .option('header', 'true')
    .option('inferSchema', 'true')
    .load(f'/Volumes/dbacademy/{DA.schema_name}/myfiles/')
)

# Criar Delta table a partir do DataFrame
(
    sdf
    .write
    .mode("overwrite")
    .format("delta")
    .saveAsTable(f"dbacademy.{DA.schema_name}.current_employees_py")
)
```

```python
# Ler a Delta table com Python
spark.read.table(f"dbacademy.{DA.schema_name}.current_employees_py").display()

# Listar tabelas com Python
spark.catalog.listTables(f"dbacademy.{DA.schema_name}")
# Resultado: current_employees e current_employees_py
```

```sql
%sql
-- Consultar a tabela
SELECT * FROM current_employees;
-- Resultado: 4 linhas de dados
```

### C. Inspecionar a Delta Table

#### DESCRIBE DETAIL

```sql
%sql
DESCRIBE DETAIL current_employees;
```

**Observar:**
- Coluna `format` = **delta** (confirma que é uma Delta table)
- Coluna `location` = caminho cloud da tabela: `s3://<bucket-name>/<metastore-id>/tables/<table-id>`

#### DESCRIBE EXTENDED

```sql
%sql
DESCRIBE EXTENDED current_employees;
```

**Observar:**
- Parte superior: metadados das colunas
- Coluna `col_name` com valor `Type` → `data_type` = **Managed**

> **Tabela Managed:** O Databricks gere o ciclo de vida e o layout dos ficheiros. É o método de criação de tabelas por default.

#### DESCRIBE HISTORY (versão inicial)

```sql
%sql
DESCRIBE HISTORY current_employees;
```

**Colunas relevantes:**
- `version` — número da versão da tabela
- `timestamp` — quando a operação ocorreu
- `operation` — que operação foi executada
- `operationsMetrics` — número de ficheiros, linhas de output, bytes de output

> **Estado inicial:** version = 0 (tabela recém-criada)

### D. INSERT, UPDATE e DELETE na Delta Table

#### Estado atual da tabela

```sql
%sql
SELECT * FROM current_employees;
-- 4 colunas, 4 linhas
-- IDs: 1111, 2222, 3333, 4444
-- Role do ID 1111: Manager
```

#### Executar operações DML

```sql
%sql
-- 1. Inserir dois novos funcionários
INSERT INTO current_employees
VALUES
  (5555, 'Alex',   'USA',   'Instructor'),
  (6666, 'Sanjay', 'India', 'Instructor');

-- 2. Atualizar o Role do funcionário ID 1111
UPDATE current_employees
  SET Role = 'Senior Manager'
  WHERE ID = 1111;

-- 3. Eliminar o registo do funcionário com ID 3333
DELETE FROM current_employees
  WHERE ID = 3333;
```

```sql
%sql
-- Verificar resultado
SELECT * FROM current_employees ORDER BY ID;
```

#### Verificar versões criadas

```sql
%sql
DESCRIBE HISTORY current_employees;
```

**Versões geradas:**

| Version | Operação |
|---|---|
| 0 | CREATE OR REPLACE TABLE (tabela original) |
| 1 | WRITE (INSERT dos 2 novos funcionários) |
| 2 | UPDATE (Role do ID 1111 → Senior Manager) |
| 3 | DELETE (remoção do ID 3333) |
| 4 | OPTIMIZE (otimização preditiva automática — feature opcional do Delta Lake no Databricks) |

> **Nota:** A ordem das operações OPTIMIZE pode variar.

### E. Time Travel — Ler Versões Anteriores

O histórico pode ser usado para: auditoria, rollback ou query a um ponto específico no tempo.

```sql
%sql
-- Versão atual (a mais recente por default)
SELECT * FROM current_employees ORDER BY ID;
```

```sql
%sql
-- Time Travel por timestamp
SELECT * FROM current_employees
TIMESTAMP AS OF ('2025-05-15T20:12:17.000+00:00');
```

```sql
%sql
-- Time Travel por versão (versão original com 4 funcionários)
SELECT * FROM current_employees VERSION AS OF 0;
```

---

## 10. Lakeflow Connect — Técnicas de Ingestão

### Visão Geral das Técnicas

```
Data Sources ──► Ingestion ──────────────────► Delta Lake (Lakehouse)
                  ┌────────────────┐
                  │  CREATE TABLE  │
                  │  COPY INTO     │
                  │  AUTO LOADER   │
                  └────────────────┘
```

### 1. CREATE TABLE (CTAS)

```sql
CREATE TABLE mydeltatable
-- USING DELTA  ← opcional, é o default
AS
<query>
```

- **CREATE TABLE AS SELECT (CTAS)** cria uma tabela selecionando dados de uma tabela existente ou fonte de dados
- O formato default é **Delta**

### 2. UPLOAD UI

- Interface **point-and-click** para upload de ficheiros e criação de tabelas
- Suporta: **CSV, TSV, JSON, Avro, Parquet, ficheiros de texto**
- Permite também upload direto para um **Unity Catalog Volume**

### 3. COPY INTO

```sql
COPY INTO mydeltatable
FROM 'your-path'
FILE_FORMAT = 'format'
FILE_OPTIONS = ('format-options')
```

**Características:**
- Carrega ficheiros de uma localização de ficheiros para uma Delta table
- Suporta **vários formatos de ficheiro** e localizações de cloud storage
- Consegue lidar automaticamente com **alterações de schema**
- Operação **idempotente** — ficheiros já carregados da fonte são ignorados (não duplica dados)

### 4. AUTO LOADER

> ⚠️ **Fora do scope deste curso**

**O que faz:**
- Processa **incrementalmente (streaming)** novos ficheiros de dados à medida que chegam ao cloud storage
- Infere schemas automaticamente e acomoda schema changes
- Inclui uma coluna **rescue data** para dados que não correspondam ao schema

**Benefícios:**
- **Sem gestão de estado de ficheiros** — processa novos ficheiros automaticamente
- **Escalável** — usa cloud services e RocksDB; funciona com milhões de ficheiros num diretório
- **Fácil de usar** — configura automaticamente notification e message queue services; modelo "set and forget"

**Comparação antes/depois:**

| Antes | Depois (Auto Loader) |
|---|---|
| Notification Service + Message Queue + Spark batch + Airflow file sensor | Auto Loader → Spark → Delta |
| Setup complexo, múltiplos componentes | Pipe direto do cloud storage para Delta Lake |

---

## 11. Demo: Ingerir Dados no Delta Lake

> **Pré-requisito:** Selecionar **Classic Compute** (não Serverless)

### A. Configurar e Explorar o Ambiente

#### 1A. Com SQL

```sql
%sql
-- Definir catálogo e schema padrão
USE CATALOG dbacademy;
USE SCHEMA IDENTIFIER(DA.schema_name);

-- Mostrar tabelas disponíveis
SHOW TABLES;
-- Resultado esperado: sem tabelas
```

#### 1B. Com PySpark

```python
# Definir catálogo e schema padrão (requer Spark 3.4.0 ou superior)
spark.catalog.setCurrentCatalog(DA.catalog_name)
spark.catalog.setCurrentDatabase(DA.schema_name)

# Mostrar tabelas disponíveis
spark.catalog.listTables(DA.schema_name)
```

### Demo COPY INTO — Versões criadas

Após executar o demo de COPY INTO com dois ficheiros (employees.csv e employees2.csv):

```sql
%sql
DESCRIBE HISTORY current_employees_copyinto;
```

**Versões:**

| Version | Operação |
|---|---|
| 0 | CREATE TABLE (tabela vazia criada pelo CREATE TABLE) |
| 1 | COPY INTO com **employees.csv** (primeiro carregamento) |
| 2 | COPY INTO com **employees2.csv** (segundo carregamento — COPY INTO é idempotente: só carrega ficheiros novos) |

---

## 12. Data Transformation — Arquitetura Medallion

### O que é a Arquitetura Medallion (Multi-Hop)?

```
              Ingest          Data Processing & Transformation           Consumers
              ──────    ──────────────────────────────────────────    ──────────────
  Batch ──►           │         ← Data Quality Levels →            │  BI & Reporting
                      │                                              │
  Streaming ──►       │  Bronze ──────► Silver ──────► Gold         │  ML & AI
                      │  (raw)         (clean)        (aggregated)  │
                      │                                              │  Streaming
                      │     Incrementally Improve Data Quality       │  Analytics
                      └──────────────────── Delta Lake ─────────────┘
```

### As 3 Camadas

#### 🟤 Bronze — Raw Data Layer

- **Dumping ground** para dados brutos dos sistemas fonte externos
- Dados tal como **originalmente existiam** (raw, sem transformações)
- **Retenção longa** (anos) — fonte de verdade histórica
- Pode remover **PII (Personally Identifiable Information)** se necessário
- Operação típica: **INSERT**

#### ⚪ Silver — Cleaned & Enriched Layer

- **Filtrar, limpar, fazer join e enriquecer** os dados Bronze
- **Definir estrutura** e aplicar ou evoluir o schema
- **Single source of truth** para análises
- Operações típicas: **DELETE, MERGE**

#### 🟡 Gold — Business-Level Layer

- Dados **limpos e prontos para consumo**
- Pode conter **agregados ao nível de negócio** dos dados Silver
- **Entregue downstream** a utilizadores e aplicações (BI, ML, Streaming Analytics)
- Operações típicas: **OVERWRITE, AGGREGATE**

### Delta Lake ACID Support na Arquitetura Medallion

> O suporte ACID do Delta Lake **permite INSERT, DELETE, UPDATE e MERGE** ao longo de todo o processo de transformação de dados.

### Flexibilidade Multi-Fonte

A arquitetura Medallion aceita múltiplas fontes em simultâneo:
- Data stream source → Bronze → Silver → Gold
- Batch source → Bronze → Silver → Gold
- Data Lake (CSV, JSON, TXT) → Bronze → Silver → Gold
- Os dados de Gold podem alimentar múltiplos consumidores (BI, ML, Streaming)

---

## 13. ETL com Lakeflow Spark Declarative Pipelines

### Posição na Plataforma Databricks

No diagrama geral da plataforma, **Lakeflow Spark Declarative Pipelines** situa-se na camada de **Data Processing** (entre a ingestão e os consumidores finais).

### O que são Spark Declarative Pipelines?

**Lakeflow Spark Declarative Pipelines** (anteriormente chamado DLT — Delta Live Tables) é o **primeiro framework ETL que usa uma abordagem declarativa simples** para construir pipelines de dados fiáveis.

> Gere automaticamente a **infraestrutura à escala**, para que analistas e engenheiros gastem menos tempo em ferramentas e mais tempo a obter valor dos dados.

### Os 4 Pilares

| Pilar | Descrição |
|---|---|
| **Accelerate ETL development** | Declarar ingestão e transformações com SQL ou Python; deixar as Spark Declarative Pipelines tratar do resto |
| **Automatically manage your infrastructure** | Scaling e recovery automatizados melhoram fiabilidade e reduzem manutenção |
| **Have confidence in your data** | Qualidade de dados integrada na pipeline |
| **Simplify batch and streaming** | As pipelines adaptam-se a workloads near real-time e batch, otimizando performance e custo |

### Connecting to Data Sources

As Lakeflow Spark Declarative Pipelines integram com o **Lakeflow Connect** para aceder a:

```
Lakeflow Connect Sources
├── Cloud Storage (S3, ADLS, GCS)
├── Message Queues (Kafka, Pub/Sub, Kinesis, etc.)
├── Databases (SQL Server, PostgreSQL, etc.)
└── Software as a Service (Workday, Salesforce, etc.)
         │
         ▼
  Lakeflow Spark Declarative Pipelines
  ┌────────────────────────────────────┐
  │  Bronze ──► Silver ──► Gold        │
  │           (Databricks)             │
  └────────────────────────────────────┘
```

### Funcionalidade — Pipeline Bronze→Silver→Gold

```
BRONZE                  SILVER                    GOLD
──────────────    ──────────────────────    ──────────────────
[tabela raw 1]    [tabela enriched]         [tabela gold 1]
[tabela raw 2]  ──►         ▼          ──►  [tabela gold 2]
                    [tabela filtered]
                Clean ──►  Enrich
                         ──► Filter
                         ──► Aggregate
```

- **Simplified authoring** — declarativo em SQL ou Python
- **Intelligent optimizations** — incrementalização automática
- **Batch and streaming** — pipeline unificada

---

## 14. Unified Orchestration com Lakeflow Jobs

### Posição na Plataforma Databricks

**Lakeflow Jobs** é a camada de **Orchestration** na base do diagrama da plataforma Databricks.

### O que é o Lakeflow Jobs?

- Serviço de orquestração de tarefas de propósito geral, totalmente gerido, baseado na cloud, para **toda a plataforma**
- Para **data engineers, data scientists e analistas** construirem pipelines de dados, analytics e AI fiáveis
- Interface **point-and-click** fácil de usar
- As **Lakeflow Spark Declarative Pipelines podem ser uma task** num Lakeflow Job

### Building Blocks de um Lakeflow Job

**Um Job é uma unidade de orquestração no Databricks.**

#### Tasks (o que pode ser executado)

| Task Type | Descrição |
|---|---|
| Databricks Notebooks | Notebooks Python/SQL/Scala/R |
| Python Scripts | Ficheiros .py |
| Python Wheels | Pacotes Python |
| SQL Files/Queries | Ficheiros SQL |
| DBSQL Dashboards | Dashboards Databricks SQL |
| Lakeflow Declarative Pipeline | Pipelines ETL declarativas |
| dbt | Modelos dbt |
| Java JAR file | JARs Java/Scala |
| Spark Submit | Jobs Spark genéricos |

#### Control Flows (como as tasks se relacionam)

| Control Flow | Comportamento |
|---|---|
| **Sequential** | Tasks executam uma após outra |
| **Parallel** | Tasks executam em simultâneo |
| **Conditionals (Run If)** | Execução condicional baseada em resultado anterior |
| **Run Job (Modular)** | Chamar outro Job como subtarefa |
| **For-Each Loop** | Iterar sobre uma coleção |

#### Triggers (quando o Job é iniciado)

| Trigger | Descrição |
|---|---|
| Manual Trigger | Execução manual |
| Scheduled (Cron) | Agendamento por expressão Cron |
| API Trigger | Ativado via API REST |
| File Arrival Triggers | Quando novos ficheiros chegam |
| Table Triggers | Quando uma tabela é atualizada |
| Continuous (Streaming) | Execução contínua/streaming |

### Monitorização em Tempo Real

- **UI de monitorização simples e intuitiva** com métricas em tempo real e analytics detalhadas para cada run de workflow
- **Drill down** para perceber quais tasks estão a falhar e porquê
- **Troubleshoot** antes de os clientes serem impactados

### Timeline View com Query Insights

- **Visualizar o critical path** para troubleshooting e otimizações
- **Live query profile** para performance insights com query history
- **Searchable query profile**

---

## 15. Recap dos Objetivos de Aprendizagem

Ao concluir este curso, o aluno é capaz de:

1. Listar as **quatro linhas de produto** chave disponíveis na Databricks
2. Descrever como cada linha de produto serve o respetivo público
3. Navegar na **Databricks Workspace UI** para localizar funcionalidades e features chave
4. Descrever as **responsabilidades primárias e competências core** de um data engineer
5. Explicar as etapas de uma **arquitetura tradicional de Data Engineering**, desde ingestão até processamento, armazenamento e consumo
6. Definir os **componentes core do Lakeflow** e descrever como beneficia os praticantes de Data Engineering
7. Descrever a **Arquitetura Medallion** para transformação de dados no Databricks
8. Descrever como as **Lakeflow Spark Declarative Pipelines** e os **Lakeflow Jobs** facilitam a orquestração unificada no Databricks

---

## 16. Próximos Passos

### Data Engineering with Databricks

Continuar a aprendizagem através de ofertas **self-paced** ou **instructor-led** que cobrem:
- Databricks Data Science & Engineering Workspace
- Databricks SQL
- Lakeflow Spark Declarative Pipelines
- Databricks Repos
- Databricks Task Orchestration
- Unity Catalog

### Data Engineer Associate Certification

**Validar competências de dados e AI no Databricks** através de credencial Databricks.

**Distribuição do exame:**

| Tópico | Peso |
|---|---|
| Data Intelligence Platform | 24% |
| ELT With Spark SQL and Python | 29% |
| Incremental Data Processing | 22% |
| Production Pipelines | 16% |
| Data Governance | 9% |

---

## Referência Rápida — Comandos SQL Essenciais

```sql
-- Navegação e contexto
USE CATALOG nome_catalogo;
USE SCHEMA IDENTIFIER(variavel_schema);
SELECT current_catalog(), current_schema();

-- Exploração
SHOW TABLES;
SHOW VOLUMES;
LIST '/Volumes/catalog/schema/volume/';

-- Inspecionar tabelas
DESCRIBE DETAIL nome_tabela;
DESCRIBE EXTENDED nome_tabela;
DESCRIBE HISTORY nome_tabela;
DESCRIBE SCHEMA EXTENDED IDENTIFIER(schema);

-- Criar tabelas
CREATE TABLE nome AS SELECT ...;               -- CTAS (Delta por default)
DROP TABLE IF EXISTS nome;

-- Ingestão
COPY INTO nome_tabela
  FROM 'caminho'
  FILE_FORMAT = 'csv'
  FILE_OPTIONS = ('header' = 'true');

-- DML
INSERT INTO tabela VALUES (...);
UPDATE tabela SET col = val WHERE cond;
DELETE FROM tabela WHERE cond;
MERGE INTO target USING source ON ...;

-- Time Travel
SELECT * FROM tabela TIMESTAMP AS OF ('data');
SELECT * FROM tabela VERSION AS OF numero;

-- Ler ficheiros
SELECT * FROM text.`/Volumes/catalog/schema/volume/`;
SELECT * FROM read_files('path', format => 'csv', header => true, inferSchema => true);
```

## Referência Rápida — PySpark Essencial

```python
# Configurar catálogo e schema
spark.catalog.setCurrentCatalog(DA.catalog_name)
spark.catalog.setCurrentDatabase(DA.schema_name)
spark.catalog.listTables(DA.schema_name)

# Ler CSV
sdf = (spark.read
         .format("csv")
         .option('header', 'true')
         .option('inferSchema', 'true')
         .load(f'/Volumes/dbacademy/{DA.schema_name}/myfiles/'))

# Escrever Delta table
(sdf.write
    .mode("overwrite")
    .format("delta")
    .saveAsTable(f"dbacademy.{DA.schema_name}.nome_tabela"))

# Ler Delta table
spark.read.table(f"dbacademy.{DA.schema_name}.nome_tabela").display()

# Listar ficheiros num volume
spark.sql(f"LIST '/Volumes/dbacademy/{DA.schema_name}/myfiles'").display()
```

