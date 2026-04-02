# Glossário de Abreviaturas — Data Engineering & Databricks

> Referência rápida de siglas e abreviaturas mais comuns em Data Engineering, Databricks, SQL e infraestrutura cloud.

---

## SQL & DDL/DML

| Abreviatura | Significado | Notas |
|---|---|---|
| **CTA / CTAS** | Create Table As (Select) | Cria tabela a partir do resultado de uma query |
| **DDL** | Data Definition Language | CREATE, ALTER, DROP, TRUNCATE |
| **DML** | Data Manipulation Language | INSERT, UPDATE, DELETE, MERGE |
| **DQL** | Data Query Language | SELECT |
| **DCL** | Data Control Language | GRANT, REVOKE |
| **TCL** | Transaction Control Language | COMMIT, ROLLBACK, SAVEPOINT |
| **CTE** | Common Table Expression | Bloco `WITH nome AS (...)` |
| **SFW** | Select-From-Where | Estrutura base de uma query SQL |
| **CRUD** | Create, Read, Update, Delete | Operações base em qualquer sistema de dados |
| **UPSERT** | Update + Insert | Inserir se não existe, atualizar se existe |
| **PK / FK** | Primary Key / Foreign Key | Chaves de integridade relacional |
| **NF** | Normal Form | 1NF, 2NF, 3NF — graus de normalização de esquemas |

---

## Databricks & Lakehouse

| Abreviatura | Significado | Notas |
|---|---|---|
| **DBFS** | Databricks File System | Sistema de ficheiros nativo do Databricks |
| **DBSQL** | Databricks SQL | Componente de warehouse SQL do Databricks |
| **UC** | Unity Catalog | Solução de governance e metastore centralizada |
| **HMS** | Hive Metastore | Metastore legado (anterior ao Unity Catalog) |
| **DLT** | Delta Live Tables | Pipeline declarativo de streaming/batch |
| **DWH / DW** | Data Warehouse | Armazém de dados estruturado |
| **DL** | Data Lake | Armazém de dados raw/semi-estruturado |
| **LH** | Lakehouse | Arquitetura que combina Data Lake + Data Warehouse |
| **CE** | Community Edition | Versão gratuita do Databricks |
| **DBU** | Databricks Unit | Unidade de faturação de compute no Databricks |
| **SQL WH** | SQL Warehouse | Cluster otimizado para cargas SQL no Databricks |
| **ADB** | Azure Databricks | Databricks na cloud Microsoft Azure |

---

## Arquitetura & Pipelines

| Abreviatura | Significado | Notas |
|---|---|---|
| **ETL** | Extract, Transform, Load | Pipeline clássico — transforma antes de carregar |
| **ELT** | Extract, Load, Transform | Transformação feita após carga (padrão em Lakehouse) |
| **CDC** | Change Data Capture | Captura incremental de alterações na fonte de dados |
| **SCD** | Slowly Changing Dimension | Dimensões que mudam ao longo do tempo (Type 1, 2, 3…) |
| **SOR** | System of Record | Fonte autoritativa de um dado específico |
| **SOT** | Source of Truth | Única fonte verdadeira de um domínio de dados |
| **ODS** | Operational Data Store | Camada intermédia entre fonte operacional e DWH |
| **MDM** | Master Data Management | Gestão centralizada de dados mestres (clientes, produtos…) |
| **DAG** | Directed Acyclic Graph | Grafo de dependências de um pipeline ou job |
| **B/S/G** | Bronze / Silver / Gold | Camadas da arquitetura medallion |

---

## Formatos & Storage

| Abreviatura | Significado | Notas |
|---|---|---|
| **ORC** | Optimized Row Columnar | Formato colunar otimizado (ecossistema Hive/Hadoop) |
| **AVRO** | — (nome próprio) | Formato de serialização orientado a linhas, com schema embutido |
| **JSON** | JavaScript Object Notation | Formato semi-estruturado ubíquo |
| **CSV** | Comma-Separated Values | Formato flat tabular |
| **TSV** | Tab-Separated Values | Variante do CSV com separador tab |
| **ZSTD / SNAPPY / GZIP** | Algoritmos de compressão | Usados em ficheiros Parquet/Delta |
| **ACID** | Atomicity, Consistency, Isolation, Durability | Propriedades transacionais — suportadas pelo Delta Lake |
| **MoR** | Merge on Read | Estratégia de escrita Delta: aplica alterações na leitura |
| **CoW** | Copy on Write | Estratégia de escrita Delta: reescreve o ficheiro completo |

---

## Compute & Infraestrutura

| Abreviatura | Significado | Notas |
|---|---|---|
| **VM** | Virtual Machine | Máquina virtual |
| **JVM** | Java Virtual Machine | Runtime do Apache Spark |
| **GC** | Garbage Collection | Limpeza automática de memória na JVM |
| **CPU / GPU** | Central / Graphics Processing Unit | Tipos de unidade de processamento |
| **RAM** | Random Access Memory | Memória volátil |
| **IOPS** | Input/Output Operations Per Second | Métrica de performance de storage |
| **IAM** | Identity and Access Management | Gestão de identidades e permissões (cloud) |
| **RBAC** | Role-Based Access Control | Controlo de acesso baseado em papéis/funções |
| **VPC** | Virtual Private Cloud | Rede privada virtual na cloud |
| **CLI** | Command Line Interface | Interface de linha de comando |
| **API** | Application Programming Interface | Interface de programação entre sistemas |
| **REST** | Representational State Transfer | Estilo arquitetural de APIs HTTP |
| **SDK** | Software Development Kit | Kit de ferramentas de desenvolvimento |
| **JDBC / ODBC** | Java DB Connectivity / Open DB Connectivity | Protocolos de ligação a bases de dados |

---

## Apache Spark & Processamento

| Abreviatura | Significado | Notas |
|---|---|---|
| **RDD** | Resilient Distributed Dataset | Abstração base do Spark — legado, evitar em código novo |
| **DF** | DataFrame | Abstração tabular distribuída do Spark |
| **DS** | Dataset | DataFrame com tipagem forte (Scala/Java) |
| **UDF** | User Defined Function | Função customizada aplicada em colunas Spark |
| **UDAF** | User Defined Aggregate Function | UDF para operações de agregação |
| **AQE** | Adaptive Query Execution | Otimização dinâmica de queries em runtime |
| **CBO** | Cost-Based Optimizer | Otimizador de planos de execução baseado em estatísticas |
| **OOM** | Out of Memory | Erro de memória esgotada — comum em Spark mal configurado |
| **DPP** | Dynamic Partition Pruning | Eliminação dinâmica de partições irrelevantes em runtime |
| **Z-order** | Z-Order Clustering | Técnica de co-localização de dados Delta para acelerar leituras |

---

## Certificação, Carreira & Gestão

| Abreviatura | Significado | Notas |
|---|---|---|
| **DE** | Data Engineer | |
| **DA** | Data Analyst | |
| **DS** | Data Scientist | |
| **ML** | Machine Learning | |
| **MLOps** | ML Operations | Operacionalização e ciclo de vida de modelos ML |
| **DataOps** | Data Operations | DevOps aplicado a pipelines e produtos de dados |
| **BI** | Business Intelligence | |
| **KPI** | Key Performance Indicator | Indicador-chave de performance |
| **SLA** | Service Level Agreement | Acordo formal de nível de serviço |
| **SLO** | Service Level Objective | Objetivo mensurável de nível de serviço |
| **PoC** | Proof of Concept | Prova de conceito — valida viabilidade técnica |
| **MVP** | Minimum Viable Product | Produto mínimo viável |
| **SME** | Subject Matter Expert | Especialista num domínio específico |

---


