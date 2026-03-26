# 📚 Guia de Referência — Data Engineering no Databricks
### Sessão de estudo — 25 de Março 2026
### Path 8: Data Warehousing Practitioner

---

## 📑 Índice

1. [Conceitos Base](#1-conceitos-base)
2. [Unity Catalog — Hierarquia e Dot Notation](#2-unity-catalog--hierarquia-e-dot-notation)
3. [Clusters e SQL Warehouse Types](#3-clusters-e-sql-warehouse-types)
4. [Formatos de Ficheiro](#4-formatos-de-ficheiro)
5. [Arquitectura Medallion](#5-arquitectura-medallion)
6. [Técnicas de Ingestão](#6-técnicas-de-ingestão)
7. [Transformações e Qualidade de Dados](#7-transformações-e-qualidade-de-dados)
8. [Modelo Dimensional — Fact, Dimension, Reference Tables](#8-modelo-dimensional--fact-dimension-reference-tables)
9. [Surrogate Keys (SK)](#9-surrogate-keys-sk)
10. [Grants e Privileges](#10-grants-e-privileges)
11. [Lakeflow Jobs — Orquestração](#11-lakeflow-jobs--orquestração)
12. [Erros Recorrentes em Pipelines](#12-erros-recorrentes-em-pipelines)
13. [Equivalentes nas Diferentes Clouds](#13-equivalentes-nas-diferentes-clouds)
14. [Paralelos com Experiência Anterior](#14-paralelos-com-experiência-anterior)
15. [Hands-on: Pipeline Construído Hoje](#15-hands-on-pipeline-construído-hoje)
16. [Dúvidas e Respostas da Sessão](#16-dúvidas-e-respostas-da-sessão)

---

## 1. Conceitos Base

### Data Warehouse
Base de dados optimizada para análise e relatórios. Dados chegam já limpos, transformados e estruturados. Rápido para queries analíticas.

### Data Lake
Repositório de dados em bruto — estruturados, semi-estruturados e não-estruturados. Barato de armazenar (S3, Azure Blob, GCS). Pode tornar-se um "data swamp" sem governança.

### Lakehouse
Junção do melhor dos dois mundos:
```
Data Lake (armazenamento barato) + Data Warehouse (performance, ACID) = Lakehouse
```
O Delta Lake / Apache Iceberg tornam isto possível.

### Unity Catalog
Camada de catálogo e governança do Databricks. Organiza numa hierarquia de 3 níveis. Controla acesso, regista linhagem, audita operações.

### Unified Governance
Uma única camada de controlo para todos os dados, independentemente de onde estão ou quem os usa. Antes: permissões definidas em 5 sítios diferentes. Agora: defines uma vez, aplica em todo o lado.

### Data Silos
Cada departamento guarda dados no seu próprio sistema, isolado dos outros. Resultado: impossível cruzar dados entre departamentos.

### Fragmented Systems
Ferramentas diferentes para cada parte do pipeline (ingestão, transformação, análise, ML) que não foram desenhadas para trabalhar juntas.

### Serverless
Não significa que não há servidores — significa que não os geres tu.
```
Tradicional: Tu provisiones → Tu pagas mesmo parado → Tu geres
Serverless:  Databricks gere → Pagas só o que usas → Arranca em segundos
```

### Metastore
Catálogo central que guarda informação SOBRE os dados (metadados) — não os dados em si. É o "Google Maps" dos teus dados.

### TPC-DI Benchmark
Transaction Processing Performance Council — Data Integration. Teste padronizado para medir performance de sistemas ETL. O Databricks usa-o para provar a performance do SQL Serverless + Photon Engine.

---

## 2. Unity Catalog — Hierarquia e Dot Notation

### Hierarquia completa
```
Metastore
├── External Storage Access
├── Catalog
│   └── Schema (Database)
│       ├── Table
│       ├── View
│       ├── Volume
│       ├── Function
│       └── Model
├── Query Federation
└── Delta Sharing
```

### Relação com Workspaces
```
Databricks Account
├── Unity Metastore 1  ←── Workspace A
├── Unity Metastore 2  ←── Workspace B
                       └── Workspace C
```

### Dot Notation
```sql
-- Endereço completo (equivalente a SQL Server: database.dbo.tabela)
SELECT * FROM catalog.schema.tabela;

-- Com USE (equivalente ao import do Python — define o contexto)
USE CATALOG vendas;
USE SCHEMA comercial;
SELECT * FROM clientes;  -- o sistema completa: vendas.comercial.clientes
```

**Analogia:** `USE` é como um `import` em Python — diz ao sistema onde procurar primeiro.

---

## 3. Clusters e SQL Warehouse Types

### O que é um Cluster
Conjunto de máquinas que trabalham juntas como se fossem uma só.
```
Driver Node (o "chefe") → divide trabalho
Worker 1, Worker 2, Worker 3 → executam em paralelo
```

### SQL Warehouse Types

| | SQL Classic | SQL Pro | SQL Serverless |
|---|---|---|---|
| Classificação | "Good" | "Better" | "Best" |
| Compute Management | Self-managed | Self-managed | Gerido pelo Databricks |
| Performance | Photon Engine | Predictive I/O + Python UDFs | High-concurrency + caching |
| Melhor para | Exploratory SQL | ETL/ELT + DSML | BI + ETL + zero gestão |
| Cluster Sizes | Fixo | Fixo + dinâmico | 100% dinâmico |

### Custos — o paradoxo do Serverless
```
Classic: preço/hora mais barato MAS paga-se mesmo parado
Serverless: preço/hora mais caro MAS paga-se só o que se usa
→ Para uso esporádico: Serverless pode sair mais barato!
```

### Conceitos de Performance
- **Photon Engine** → motor C++ que acelera queries SQL
- **Predictive I/O** → carrega dados antecipadamente (como buffer de vídeo)
- **Python UDFs** → funções Python reutilizáveis em SQL
- **Query Federation** → queries a dados fora do Databricks sem copiar
- **Materialized Views** → resultado guardado fisicamente, actualiza automaticamente
- **High-concurrency** → muitos utilizadores simultâneos sem degradação

---

## 4. Formatos de Ficheiro

| Formato | Orientação | Analytics | Streaming | Schema | Uso típico |
|---------|-----------|-----------|-----------|--------|------------|
| CSV | Linha | ❌ | ❌ | ❌ | Troca de dados simples |
| JSON | Linha | ❌ | ❌ | Parcial | APIs |
| Parquet | Coluna | ✅ | ❌ | ✅ | Data lakes / analytics |
| Avro | Linha | ❌ | ✅ | ✅ | Streaming / Kafka |
| Delta | Coluna | ✅ | ✅ | ✅ | Lakehouse |

### Parquet vs CSV — porquê a diferença
```
CSV: query SELECT SUM(valor) → lê TODAS as colunas de TODAS as linhas
Parquet: vai directamente à coluna "valor" → ignora o resto → muito mais rápido
```

### Avro
Optimizado para streaming e transporte. O Kafka usa Avro para enviar mensagens. É como um caminhão de transporte (move dados rápido) vs Parquet que é o armazém organizado (consulta rápida).

### OLAP Cubes (conceito legado)
Pré-calculavam resultados para serem rápidos. Problema: rígidos, demorava horas a construir. As Materialized Views + Parquet + Photon tornaram-nos obsoletos.

---

## 5. Arquitectura Medallion

### As 3 camadas (Multi Hop)
```
Bronze (🥉) → Silver (🥈) → Gold (🥇)
dados raw      dados limpos    dados agregados
tudo STRING    tipos correctos  prontos para análise
```

### Ligação ao trabalho anterior
```
SD_MIG_00_*   →  Bronze (dados raw)
SD_MIG_*      →  Silver (dados limpos e tipados)
Destino final →  Gold (prontos para uso)
```

### Stack tecnológica por baixo
```
Lakeflow Pipeline (as tuas regras)
Spark + Photon (executa)
Delta Lake (guarda)
Cloud Storage S3/ADLS/GCS (infraestrutura física)
```

---

## 6. Técnicas de Ingestão

### 4 métodos principais

| Método | Automático | Sem código | Incremental | Streaming | Schema inference |
|--------|-----------|------------|-------------|-----------|-----------------|
| CREATE TABLE / CTAS | ❌ | ❌ | ❌ | ❌ | ❌ |
| Upload UI | ❌ | ✅ | ❌ | ❌ | ✅ |
| COPY INTO | ❌ | ❌ | ✅ | ❌ | ✅ |
| Auto Loader | ✅ | ❌ | ✅ | ✅ | ✅ |

### COPY INTO — conceito chave
**Idempotente** = podes correr o mesmo comando várias vezes sem duplicar dados. O Databricks guarda quais ficheiros já foram carregados.

### Auto Loader
- Monitoriza pasta no cloud storage
- Processa ficheiros novos automaticamente
- **Rescue data column**: dados que não encaixam no schema vão para `_rescued_data` em vez de serem perdidos

### Streaming Tables
```sql
-- Fonte: ficheiros
CREATE STREAMING TABLE web_clicks AS
SELECT * FROM STREAM read_files('s3://bucket')

-- Fonte: Kafka (mensagens em tempo real)
CREATE STREAMING TABLE server_logs AS
SELECT from_json(...) FROM STREAM read_kafka(...)
```

### CDC (Change Data Capture)
Captura só o que mudou em vez de extrair tudo:
```
Sem CDC: exportas 10 milhões de registos todos os dias
Com CDC: hoje mudaram 500 linhas → exportas só 500
```
Comando: `APPLY CHANGES INTO` (versão automática do MERGE INTO)

### Kafka — o que são "mensagens"
```json
{
  "evento": "venda",
  "timestamp": "2024-03-15T14:32:01",
  "cliente_id": 42,
  "valor": 999.00
}
```
Cada evento que acontece num sistema é uma mensagem publicada num tópico Kafka. O Databricks consome essas mensagens em tempo real.

### Batch vs Streaming vs Micro-batch
```
Batch:        Uma vez por dia          → relatório mensal
Micro-batch:  A cada 5 minutos         → dashboard frequente
Streaming:    Milissegundos            → detecção de fraude
```

### Lakeflow Connect — Before vs After
```
ANTES: fonte → infra de extracção → Spark Streaming → notebook custom → Databricks
DEPOIS: fonte → Lakeflow Connect → Databricks
```

---

## 7. Transformações e Qualidade de Dados

### Padrões de limpeza Bronze → Silver
```sql
-- Limpar string vazia → NULL e tipar
CASE WHEN TRIM(campo) = '' THEN NULL
     ELSE CAST(TRIM(campo) AS tipo)
END

-- Eliminar duplicados (o mais recente ganha)
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY id
    ORDER BY _ingested_at DESC
) = 1

-- Tratar sinal negativo no fim (formato asiático: 1500- = -1500)
CASE WHEN RIGHT(TRIM(price), 1) = '-'
     THEN CAST('-' || REPLACE(TRIM(price),'-','') AS DECIMAL(16,2))
     ELSE CAST(TRIM(price) AS DECIMAL(16,2))
END
```

### Materialized Views
```sql
-- View normal: recalcula TUDO cada vez que é consultada
CREATE VIEW sales_report AS SELECT city, SUM(price) FROM sales GROUP BY city;

-- Materialized View: guarda resultado, actualiza só quando dados mudam
CREATE MATERIALIZED VIEW sales_report AS SELECT city, SUM(price) FROM sales GROUP BY city;
```
Casos de uso: BI dashboards, Easy ELT, Streaming, Data Sharing.

### O que faz o Data Engineer?
```
Plataforma faz:              Tu fazes:
─────────────                ────────
Gerir clusters               Desenhar a arquitectura
Detectar ficheiros           Definir regras de negócio
Actualizar views             Construir pipelines
Escalar recursos             Garantir qualidade de dados
                             Optimizar performance
                             Governança e segurança
```

---

## 8. Modelo Dimensional — Fact, Dimension, Reference Tables

### Fact Tables
Registam eventos/transacções. Têm números, métricas, factos. Crescem constantemente.
```
FactTrade: trade_id | customer_id | security_id | date_id | quantidade | valor
```
Não têm nomes — só IDs e números. Para saber quem é o customer_id 42, vais à DimCustomer.

### Dimension Tables
Guardam contexto das entidades. Respondem ao "quem, quando, onde, o quê".
```
DimCustomer: customer_id | nome | email | cidade | segmento
DimDate:     date_id | data | ano | mes | trimestre | dia_semana
```

### Reference Tables
Listas pequenas de valores fixos. Raramente mudam.
```
TradeType:  type_id | codigo | descricao
StatusType: status_id | codigo | descricao
TaxRate:    country | year | taxa
```

### Como se ligam
```sql
SELECT c.nome, SUM(f.valor) AS total
FROM FactTrade f
JOIN DimCustomer c ON f.customer_id = c.customer_id
JOIN DimDate d ON f.date_id = d.date_id
WHERE d.ano = 2024 AND d.mes = 3
GROUP BY c.nome;
```

### DI Operational Tables + Audit
Equivalente às tabelas de staging e de controlo do trabalho anterior.
- **DImessages** → log de mensagens do pipeline
- **Audit** → quem fez o quê, quando, com que resultado

---

## 9. Surrogate Keys (SK)

### O que são
Chaves artificiais geradas pelo sistema — sem significado de negócio.

### Natural Key vs Surrogate Key
| | Natural Key | Surrogate Key |
|---|---|---|
| Origem | Dados reais (NIF, email) | Gerada artificialmente |
| Muda? | Pode mudar | Nunca muda |
| Tamanho | Pode ser longa | Sempre simples (integer) |
| Significado | Tem significado de negócio | Não tem significado |

### Porquê usar SK?
1. Natural keys podem mudar (NIF corrigido, email alterado)
2. Performance: JOIN em INTEGER muito mais rápido que STRING
3. SCD Type 2: mesmo NIF, duas SK diferentes para guardar histórico
4. Fontes múltiplas: Sistema A e B podem ter cliente ID=100 sem conflito

### Como gerar no Databricks
```sql
-- Opção 1: IDENTITY (recomendada)
CREATE TABLE dim_customers (
    sk_customer BIGINT GENERATED ALWAYS AS IDENTITY,
    customer_id STRING, ...
);

-- Opção 2: dense_rank() — usámos no trabalho anterior!
SELECT dense_rank() OVER (ORDER BY customer_id) AS sk_customer, ...

-- Opção 3: md5() hash — determinística
SELECT md5(CAST(customer_id AS STRING)) AS sk_customer, ...
```

### Ligação ao trabalho anterior
O `dense_rank()` no script do PlafondCalendar era exactamente surrogate keys!
```sql
dense_rank() over(order by UnifiedSocialCCNo, BPNumber, Brand, GroupType)
```

---

## 10. Grants e Privileges

### Sintaxe base
```sql
GRANT  privilégio ON objecto TO utilizador/grupo
REVOKE privilégio ON objecto FROM utilizador/grupo
```

### Privilégios mais comuns
| Privilégio | O que permite |
|---|---|
| `USE CATALOG` | Entrar no catalog |
| `USE SCHEMA` | Entrar no schema |
| `SELECT` | Ler dados |
| `INSERT` | Inserir dados |
| `MODIFY` | INSERT + UPDATE + DELETE |
| `CREATE TABLE` | Criar tabelas |
| `ALL PRIVILEGES` | Tudo |

### Exemplo prático — separação por camadas
```sql
-- Bronze: só data engineers
GRANT USE SCHEMA, SELECT ON SCHEMA tpcdi_learning.bronze TO `data_engineers`;

-- Silver: engenheiros + cientistas
GRANT USE SCHEMA, SELECT ON SCHEMA tpcdi_learning.silver TO `data_scientists`;

-- Gold: todos os analistas
GRANT USE SCHEMA, SELECT ON SCHEMA tpcdi_learning.gold TO `analysts`;
```

### Diferença para SQL Server
| SQL Server | Databricks Unity Catalog |
|---|---|
| Roles (db_datareader) | Grupos no Unity Catalog |
| Gerido por DBA | Gerido pelo Data Engineer |
| Só cobre dados | Cobre tabelas, volumes, modelos, notebooks |

### Nota importante
No Community Edition és o owner → tens ALL PRIVILEGES automaticamente → SHOW GRANTS retorna 0 linhas (é correcto!).

---

## 11. Lakeflow Jobs — Orquestração

### Tipos de Tasks
| Task | Para quê |
|------|----------|
| Databricks Notebooks | ✅ Usámos hoje! |
| Python Scripts | Ficheiros .py |
| SQL Files/Queries | Queries directas |
| DBSQL Dashboards | Actualizar dashboards |
| Spark Declarative Pipeline | DLT com qualidade incorporada |
| dbt | Transformações SQL organizadas |
| Java JAR / Spark Submit | Jobs clássicos |

### Control Flows
| Flow | Como funciona | Exemplo |
|------|--------------|---------|
| Sequential | Uma atrás da outra ✅ | Bronze → Silver → Gold |
| Parallel | Ao mesmo tempo | 3 tabelas Bronze em simultâneo |
| Conditionals | If/else | SE Bronze OK → corre Silver |
| Loops | For each | Para cada ficheiro → processa |
| Jobs as Task | Job chama outro Job | Pipeline modular |

### Triggers
| Trigger | Quando corre |
|---------|-------------|
| Manual ✅ | Clicas Run now |
| Scheduled (Cron) | "todos os dias às 6h" |
| API Trigger | Chamada externa |
| File Arrival | Quando chega ficheiro novo |
| Table Update | Quando tabela é actualizada |
| Continuous (Streaming) | Sempre à escuta — Kafka, Event Hubs |

### Depends on — opções importantes
- `All succeeded` → só corre se TODAS as anteriores tiverem sucesso ✅ (usámos)
- `At least one succeeded` → corre se pelo menos uma tiver sucesso
- `All done` → corre sempre, mesmo que anteriores falhem

### Lakeflow Jobs vs Airflow
| | Airflow | Lakeflow Jobs |
|---|---|---|
| DAGs | Código Python | GUI + código opcional |
| Infraestrutura | Geres tu | Gerido pelo Databricks |
| CI/CD | Nativo | A ser desenvolvido |
| Integração Databricks | Externa | Nativa |

### Quando usar Lakeflow Jobs
- ETL/Spark/ML simples mas poderoso
- Já usas notebooks com `%run`
- Queres reduzir overhead do Airflow
- Queres que não-engenheiros criem workflows
- Queres independência de cloud provider

### Jobs & Pipelines — 3 opções no Community Edition
| | Job | ETL Pipeline | Ingestion Pipeline |
|---|---|---|---|
| Flexibilidade | Total | Média | Específico |
| Código | Sim | Opcional | Não |
| Para quê | Orquestração geral | Transformações DLT | Ingestão de fontes |
| Equivalente a | Airflow | dbt + DLT | Lakeflow Connect |

---

## 12. Erros Recorrentes em Pipelines

### 🔴 Muito Comuns

**1. Duplicados por re-execução**
- Causa: INSERT simples sem idempotência
- Solução: MERGE INTO ou TRUNCATE + INSERT
- Exemplo real: Gold tables duplicadas se correr script 2x ← aconteceu hoje!

**2. Schema mismatch**
- Causa: ficheiro novo com coluna extra ou tipo diferente
- Solução: Auto Loader com schema evolution ou rescue data

**3. NULL propagation**
- Causa: campo NULL numa operação matemática
- Exemplo: `price * quantity` → se price = NULL → resultado = NULL
- Solução: `COALESCE(price, 0)` ou filtrar NULLs antes

**4. Encoding de caracteres**
- Causa: ficheiro UTF-8 mas sistema espera Latin-1
- Exemplo: "João" vira "Jo?o"
- Solução: definir encoding explicitamente na ingestão

**5. Timezone mismatch**
- Causa: timestamps de sistemas diferentes em timezones diferentes
- Solução: converter sempre para UTC no Bronze

### 🟡 Menos Comuns mas Documentados

**6. Small files problem**
- Causa: Auto Loader cria milhares de ficheiros Parquet pequenos
- Solução: `OPTIMIZE + ZORDER` periodicamente

**7. Data skew**
- Causa: uma partição tem muito mais dados que as outras
- Solução: SKEW HINT ou repartitioning

**8. Late arriving data**
- Causa: dados chegam fora de ordem
- Solução: watermarking em streaming

**9. Cascading failures**
- Causa: erro no Bronze que só se manifesta no Gold
- Solução: data quality checks em cada camada

### 🔴 Raros mas Graves

**10. Silent data corruption**
- Causa: transformação errada que não dá erro
- Solução: testes de qualidade + reconciliação com fonte

**11. Delta Log corruption**
- Causa: operação interrompida a meio
- Solução: `RESTORE TABLE` para versão anterior (time travel!)

### Documentação oficial
- Databricks: docs.databricks.com
- Delta Lake: delta.io
- dbt: docs.getdbt.com
- Great Expectations: greatexpectations.io

---

## 13. Equivalentes nas Diferentes Clouds

### Databricks não é exclusivo de uma cloud!
Corre em cima de AWS, Azure ou GCP — é independente.

| Função | Databricks | Azure | AWS | Google Cloud |
|---|---|---|---|---|
| Lakehouse/Analytics | Databricks | Microsoft Fabric | Redshift + S3 | BigQuery |
| Data Lake | Delta Lake | ADLS Gen2 | S3 + Lake Formation | GCS |
| Spark gerido | Databricks Runtime | HDInsight | EMR | Dataproc |
| ML Platform | MLflow | Azure ML | SageMaker | Vertex AI |
| Orquestração | Lakeflow Jobs | Azure Data Factory | AWS Glue | Cloud Composer |
| Catálogo | Unity Catalog | Microsoft Purview | AWS Glue Catalog | Dataplex |

### Portabilidade de skills
```
O que aprendes          Portabilidade
──────────────          ─────────────
SQL                     100% — universal
Spark / PySpark          90% — open source
Conceitos arquitectura   90% — universais
Delta Lake               80% — open source
MLflow                   80% — open source
Ferramentas específicas  40% — nomes diferentes
```

**Conclusão:** Aprender Databricks = aprender data engineering. A transição para outra cloud é aprender os nomes das ferramentas equivalentes, não reaprender tudo.

---

## 14. Paralelos com Experiência Anterior

### Scripts do trabalho anterior → Equivalente Databricks

| O que fazias | Equivalente Databricks |
|---|---|
| Tabelas `SD_MIG_00_*` (staging raw) | Bronze layer |
| Tabelas `SD_MIG_*` (dados limpos) | Silver layer |
| Tabelas destino finais | Gold layer |
| Script CheckTypes (validação de tipos) | Delta Live Tables Expectations |
| `SD_MIG_CheckTypes_Log` (log de erros) | Data Quality Log / Quarantine table |
| Loop duplo com `sp_executesql` | Great Expectations / dbt tests |
| `SD_Mig_CustomLog` (logging) | Event Log do Delta Live Tables |
| `#ColumnsToIgnore` | Schema evolution settings |
| `TRY/CATCH` com rethrow | Error handling em Lakeflow Jobs |
| `SD_Mig_MapCode2Code` | Reference Table de migração |

### Padrão que usavas no trabalho
```sql
-- Padrão de limpeza que fazias manualmente:
CASE WHEN len(RTRIM(LTRIM(campo))) = 0 THEN NULL
     ELSE CAST(RTRIM(LTRIM(campo)) AS nvarchar(255))
END

-- Equivalente moderno no Databricks:
NULLIF(TRIM(campo), '') → NULL se vazio
```

### Sinal negativo no fim (formato chinês)
```sql
-- 1500- significa -1500 em sistemas contabilísticos chineses
-- Tratamento que o teu senior implementou:
CASE WHEN right(ltrim(rtrim(campo)), 1) = '-'
     THEN cast('-' + replace(ltrim(rtrim(campo)), '-', '') as decimal)
     ELSE cast(ltrim(rtrim(campo)) as decimal)
END
```

### SQL Server vs Databricks
| SQL Server | Databricks |
|---|---|
| Database.dbo.Tabela | Catalog.Schema.Tabela |
| Primary Key enforced | Informativa (não enforced) |
| Foreign Key enforced | Não existe |
| Validação pela BD | Validação no pipeline (teu trabalho!) |

### A progressão completa
```
Scripts T-SQL manuais     → sabes o que pode correr mal
(trabalho anterior)          sabes porquê as ferramentas existem

Databricks agora          → fazes o mesmo 10x mais rápido
                             com menos código

Bootcamp Zach Wilson      → ligas os dois mundos
(depois do festival)         código + plataforma

Resultado                 → engenheira completa! 💪
```

---

## 15. Hands-on: Pipeline Construído Hoje

### Estrutura criada
```
tpcdi_learning (catalog)
├── bronze
│   ├── raw_customers    ← dados em bruto, tudo STRING, com erros
│   ├── raw_trades       ← inclui "210.50-", preço vazio, cliente inválido
│   └── raw_securities
├── silver
│   ├── dim_customers    ← 5 linhas (duplicado eliminado!)
│   ├── dim_securities   ← 4 linhas
│   └── fact_trades      ← 5 linhas (preço vazio e cliente 9 excluídos!)
└── gold
    ├── trades_by_customer  ← agregado por cliente
    └── trades_by_sector    ← agregado por sector
```

### Notebooks criados (em JOB_workflow_ingestion/)
- `Bronze_Ingestion` → TRUNCATE + INSERT (simula ficheiro a chegar)
- `Silver_Transform` → MERGE/INSERT com limpeza completa
- `Gold_Aggregate` → MERGE INTO (idempotente)

### Job criado: TPCDI_Pipeline
```
Bronze_Ingestion
      │ (depends on: all succeeded)
      ▼
Silver_Transform
      │ (depends on: all succeeded)
      ▼
Gold_Aggregate
```

### Problemas inseridos propositadamente no Bronze
```
raw_customers → cliente 1 duplicado (dois ficheiros CSV)
raw_trades    → T004: price = "210.50-" (sinal negativo asiático)
                T006: price = "" (preço vazio)
                T007: customer_id = 9 (não existe na dim_customers)
```

### Como foram tratados na Silver
```sql
-- Duplicados: ROW_NUMBER() QUALIFY
QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY _ingested_at DESC) = 1

-- Sinal negativo no fim:
CASE WHEN RIGHT(TRIM(price), 1) = '-'
THEN CAST('-' || REPLACE(TRIM(price),'-','') AS DECIMAL(16,2))

-- Preço vazio → excluído:
WHERE TRIM(price) != ''

-- Cliente inválido → excluído:
AND CAST(customer_id AS BIGINT) IN (SELECT customer_id FROM silver.dim_customers)
```

---

## 16. Dúvidas e Respostas da Sessão

### ❓ "Serverless é muito mais caro?"
Não é linear. Para uso contínuo (8h/dia) o Classic é mais barato. Para uso esporádico, o Serverless pode ser mais barato porque não pagas quando está parado.

### ❓ "O USE é como um import?"
Exactamente! `USE CATALOG` e `USE SCHEMA` dizem ao sistema onde procurar, assim como `import` em Python define onde procurar módulos. Podes omitir e usar o path completo `catalog.schema.tabela`.

### ❓ "Aprendendo Databricks, a transição para outra cloud é fácil?"
Sim — como Java facilita aprender C#. SQL é universal, Spark é open source, os conceitos de arquitectura são portáteis. Só os nomes das ferramentas específicas mudam.

### ❓ "Não há primary keys no Databricks?"
Existem mas são informativas, não enforced. O Databricks é optimizado para biliões de linhas distribuídas — verificar unicidade em tempo real seria impossível. A responsabilidade passa para o pipeline (o teu trabalho!).

### ❓ "O que faz um data engineer se a plataforma automatiza tudo?"
A plataforma executa — tu decides o quê e porquê: desenhas a arquitectura, defines regras de negócio, constróis pipelines, garantes qualidade, optimizas performance, governança e segurança.

### ❓ "Batch não morreu com o streaming?"
Não — coexistem. Batch para relatórios mensais, faturação, salários. Streaming para fraude, alertas, clicks em tempo real. Micro-batch é o meio-termo (a cada 5 minutos).

### ❓ "O que se usa para RAG — dados em bruto?"
Não! RAG usa dados da camada **Gold** — limpos, estruturados, de qualidade. Dados em bruto com erros dariam respostas incorrectas à IA.

### ❓ "Parquet tem a ver com os cubos OLAP?"
Sim — os cubos OLAP pré-calculavam resultados para serem rápidos (anos 90-2000). O Parquet + Databricks + Photon tornaram-nos obsoletos — queries analíticas rápidas sem pré-calcular nada.

### ❓ "SHOW GRANTS retornou 0 linhas — está correcto?"
Sim! És o owner do catalog → tens ALL PRIVILEGES automaticamente → não precisas de grants explícitos → SHOW GRANTS não mostra nada porque os grants são para outros utilizadores.

### ❓ "O Job está a demorar muito para poucos dados"
É o cold start do Serverless — alocar VMs + instalar runtime + iniciar Spark ≈ 30-60 segundos. O teu código corre em 2-3 segundos. Em produção com dados reais este overhead é insignificante.

---

## 📌 Conceitos Chave — Glossário Rápido

| Termo | Definição rápida |
|---|---|
| **Idempotente** | Podes correr N vezes com o mesmo resultado — não duplica |
| **CDC** | Captura só o que mudou em vez de extrair tudo |
| **Serverless** | Não geres infra — pagas só o que usas |
| **Materialized View** | Resultado guardado fisicamente, actualiza automaticamente |
| **SCD Type 2** | Guarda histórico criando nova linha com datas de validade |
| **Surrogate Key** | ID artificial sem significado de negócio que nunca muda |
| **Data Skew** | Uma partição tem muito mais dados que as outras |
| **Cold Start** | Tempo de arranque de um cluster serverless |
| **Schema Evolution** | Capacidade de adaptar-se a mudanças no schema dos dados |
| **Rescue Data** | Coluna especial que guarda dados que não encaixam no schema |
| **DAG** | Directed Acyclic Graph — diagrama de dependências entre tasks |
| **Photon Engine** | Motor C++ do Databricks que acelera queries SQL |
| **Delta Sharing** | Partilhar dados com outras organizações sem copiá-los |
| **Query Federation** | Fazer queries a dados fora do Databricks sem importar |
| **Watermarking** | Técnica para lidar com mensagens que chegam fora de ordem |

---

*Documento gerado na sessão de 25 de Março de 2026*
*Próxima sessão: Monitoring, Visualization, Genie, Power BI Integration + prática no Databricks Community Edition*
