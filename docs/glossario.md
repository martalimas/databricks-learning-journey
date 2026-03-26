# 📖 Glossário — Data Engineering no Databricks

| Termo | Definição rápida |
|---|---|
| **Idempotente** | Podes correr N vezes com o mesmo resultado — não duplica |
| **CDC** | Change Data Capture — captura só o que mudou em vez de extrair tudo |
| **Serverless** | Não geres infra — pagas só o que usas |
| **Materialized View** | Resultado guardado fisicamente, actualiza automaticamente |
| **SCD Type 2** | Slowly Changing Dimension — guarda histórico criando nova linha com datas de validade |
| **Surrogate Key** | ID artificial sem significado de negócio que nunca muda |
| **Natural Key** | Chave que vem dos dados reais (NIF, email) — pode mudar |
| **Data Skew** | Uma partição tem muito mais dados que as outras |
| **Cold Start** | Tempo de arranque de um cluster serverless |
| **Schema Evolution** | Capacidade de adaptar-se a mudanças no schema dos dados |
| **Rescue Data** | Coluna especial que guarda dados que não encaixam no schema |
| **DAG** | Directed Acyclic Graph — diagrama de dependências entre tasks |
| **Photon Engine** | Motor C++ do Databricks que acelera queries SQL |
| **Delta Sharing** | Partilhar dados com outras organizações sem copiá-los |
| **Query Federation** | Fazer queries a dados fora do Databricks sem importar |
| **Watermarking** | Técnica para lidar com mensagens que chegam fora de ordem |
| **Data Lake** | Repositório de dados em bruto — structured, semi e não estruturado |
| **Data Warehouse** | BD optimizada para análise — dados limpos e estruturados |
| **Lakehouse** | Data Lake + Data Warehouse — o melhor dos dois mundos |
| **Metastore** | Catálogo central que guarda metadados — o "Google Maps" dos teus dados |
| **Unity Catalog** | Camada de governança do Databricks — quem acede a quê |
| **Medallion Architecture** | Bronze (raw) → Silver (clean) → Gold (aggregated) |
| **ELT** | Extract → Load → Transform (carrega primeiro, transforma depois) |
| **ETL** | Extract → Transform → Load (transforma antes de carregar) |
| **Micro-batch** | Processamento a cada X minutos — meio-termo entre batch e streaming |
| **Data Silo** | Dados isolados por departamento sem partilha entre sistemas |
| **Idempotent** | Ver Idempotente |
| **UPSERT** | UPDATE + INSERT — actualiza se existe, insere se não existe |
| **MERGE INTO** | Comando SQL que implementa UPSERT no Databricks |
| **Time Travel** | Capacidade do Delta Lake de consultar versões anteriores de uma tabela |
| **ACID** | Atomicity, Consistency, Isolation, Durability — propriedades de transacções fiáveis |
| **Parquet** | Formato colunar optimizado para analytics |
| **Avro** | Formato orientado a linha optimizado para streaming/Kafka |
| **Kafka** | Sistema de mensagens distribuído — publica e consome eventos em tempo real |
| **Tópico Kafka** | Categoria de mensagens (ex: "vendas", "clicks") |
| **Lakeflow Jobs** | Orquestrador nativo do Databricks — equivalente ao Airflow |
| **Lakeflow Connect** | Conector nativo do Databricks para fontes externas |
| **Spark Declarative Pipeline** | Pipeline DLT com qualidade de dados incorporada |
| **dbt** | Data Build Tool — transformações SQL com testes automáticos |
| **RAG** | Retrieval Augmented Generation — IA que usa os teus dados para responder |
| **Genie** | Funcionalidade Databricks — responde a perguntas sobre dados em linguagem natural |
