# Feature Store Lab no Databricks
**Módulo:** Modern Data Architecture Use Cases — Demonstration  
**Tema:** Modern Case Study: Feature Store  

---

## Objectivos do Lab

Este notebook percorre o processo de:

1. **Instalar bibliotecas** para o Databricks Feature Store
2. **Construir features** e guardá-las no Feature Store
3. **Treinar um modelo** usando essas features
4. **Realizar Batch Inference** com as mesmas features

---

## Requisitos de Cluster

- **Recomendado:** Databricks ML Runtime (ex: `13.3 LTS ML`) — já inclui as bibliotecas necessárias.
- **Alternativa:** Num cluster sem ML Runtime, instalar manualmente as bibliotecas (abordagem usada neste lab).

---

## 1. Instalar Bibliotecas

Instalamos a biblioteca **Databricks Feature Engineering** (também conhecida como Feature Store) para podermos criar definições de tabelas, carregar training sets e publicar features.

```python
%pip install databricks-feature-engineering
```

Após a instalação, reiniciamos o kernel Python para que a biblioteca fique disponível:

```python
dbutils.library.restartPython()
```

---

## 2. Configuração do Ambiente

Trabalhamos num catálogo e schema a que temos acesso. Os nomes devem ser ajustados ao nosso ambiente.

```python
from databricks.feature_store import FeatureStoreClient

fs = FeatureStoreClient()

# Derivar o nome do catálogo a partir do utilizador atual
catalog_name = spark.sql("SELECT current_user()").collect()[0][0].split("@")[0]
silver_schema = "silver"
gold_schema   = "gold"

spark.sql(f"USE CATALOG {catalog_name}")
spark.sql(f"USE {silver_schema}")

print("Catalog and schemas set for feature development.")
```

> **Nota:** `FeatureStoreClient()` é o ponto de entrada principal para interagir com o Feature Store.

---

## 3. Criar ou Atualizar Features

**Objetivo:** Construir features ao nível do cliente a partir das tabelas refinadas `refined_orders` e `refined_customer`.

Features a calcular:

| Feature | Descrição |
|---|---|
| `total_orders` | Número total de encomendas por cliente |
| `avg_order_value` | Preço médio por encomenda |
| `total_spending` | Valor total gasto pelo cliente |
| `market_segment` | Coluna categórica da dimensão cliente |

```python
from pyspark.sql.functions import col, count, avg, sum, current_timestamp

orders_df    = spark.sql("SELECT * FROM refined_orders")
customers_df = spark.sql("SELECT * FROM refined_customer")

base_features_df = (
    orders_df.groupBy("customer_id")
    .agg(
        count("*").alias("total_orders"),
        avg("total_price").alias("avg_order_value"),
        sum("total_price").alias("total_spending")
    )
    .join(
        customers_df.select("customer_id", "market_segment"),
        on="customer_id",
        how="inner"
    )
    .withColumn("feature_update_ts", current_timestamp())
)

display(base_features_df.limit(5))
```

### 3.1 Registar ou Fazer Merge-Update da Feature Table

Criamos a feature table `customer_features` no schema `gold`. Se já existir, fazemos merge com os novos dados.

```python
feature_table_name = f"{catalog_name}.{gold_schema}.customer_features"

try:
    fs.create_table(
        name=feature_table_name,
        primary_keys=["customer_id"],
        schema=base_features_df.schema,
        description="Customer-level features derived from refined tables."
    )
    print(f"Feature table '{feature_table_name}' created.")
except Exception as e:
    print(f"Feature table might already exist: {e}")

fs.write_table(
    name=feature_table_name,
    df=base_features_df,
    mode="merge"
)

print(f"Feature table '{feature_table_name}' updated with new features.")
```

> **Conceito chave — `mode="merge"`:** Atualiza registos existentes (por chave primária) e insere novos. Garante idempotência nas atualizações.

### 3.2 Agendar Atualizações

Este notebook (ou um subconjunto) pode ser agendado como um **Databricks Job** para refrescar as features periodicamente com dados novos. Isto garante que as features se mantêm atualizadas para as tarefas de ML downstream.

---

## 4. Treinar um Modelo com o Feature Store

Passos:
1. Criar um **label simples**: clientes que gastaram mais do que um determinado threshold são considerados *"high spender"*.
2. Recuperar as mesmas features via `FeatureLookup`.
3. Treinar um modelo básico de **Logistic Regression**.

### Criar o Label

```python
from pyspark.sql.functions import when

threshold = 20000.0

labeled_df = (
    base_features_df
    .withColumn("label", when(col("total_spending") > threshold, 1).otherwise(0))
    .select("customer_id", "total_orders", "avg_order_value",
            "total_spending", "market_segment", "label")
)

display(labeled_df.limit(5))
```

### 4.1 Construir o Training Set com FeatureLookups

Usamos `FeatureLookup` para recuperar colunas da feature table e juntá-las com o nosso dataset com labels.

```python
from databricks.feature_store import FeatureLookup

feature_lookup = FeatureLookup(
    table_name=feature_table_name,
    feature_names=[
        "total_orders",
        "avg_order_value",
        "total_spending",
        "market_segment",
    ],
    lookup_key="customer_id",
)

# Remover as colunas do labeled_df que vão ser fornecidas pelo lookup
labeled_df_clean = labeled_df.drop(
    "total_orders", "avg_order_value", "total_spending", "market_segment"
)

training_set = fs.create_training_set(
    df=labeled_df_clean,
    feature_lookups=[feature_lookup],
    label="label",
    exclude_columns=["feature_update_ts"]
)

training_df = training_set.load_df()
display(training_df.limit(5))
```

> **Porquê usar `FeatureLookup`?**  
> Garante que o training e a inferência usam **exatamente as mesmas features**, eliminando *training-serving skew*.

### 4.2 Treinar um Modelo Simples de Logistic Regression

Convertemos a coluna categórica `market_segment` para formato numérico, vetorizamos todas as features e treinamos um classificador binário.

```python
from pyspark.ml.classification import LogisticRegression
from pyspark.ml.feature import StringIndexer, OneHotEncoder, VectorAssembler
from pyspark.ml import Pipeline

# Tratar a coluna categórica
indexer  = StringIndexer(inputCol="market_segment", outputCol="market_segment_idx", handleInvalid="keep")
encoder  = OneHotEncoder(inputCols=["market_segment_idx"], outputCols=["market_segment_vec"])

# Vetorizar todas as features numéricas
assembler = VectorAssembler(
    inputCols=["total_orders", "avg_order_value", "total_spending", "market_segment_vec"],
    outputCol="features"
)

lr = LogisticRegression(featuresCol="features", labelCol="label", maxIter=10)

pipeline = Pipeline(stages=[indexer, encoder, assembler, lr])
model    = pipeline.fit(training_df)

print("Model training complete.")
```

### 4.3 (Opcional) Registar Modelo no MLflow

Para rastrear versões, métricas e facilitar o deploy, podemos registar o modelo no MLflow. Os detalhes são omitidos neste lab por brevidade.

---

## 5. Batch Inference com o Feature Store

**Cenário:** Temos IDs de clientes novos ou existentes e queremos prever quais podem ser high spenders.

Passos:
1. Criar um DataFrame com IDs de clientes.
2. Recuperar as features via `FeatureLookup`.
3. Gerar previsões com o pipeline treinado.

### Criar DataFrame de Clientes de Exemplo

```python
from pyspark.sql.functions import lit

sample_customers = (
    training_df.select("customer_id")
    .limit(5)
    .withColumn("batch_inference_example", lit(True))
)

display(sample_customers)
```

### 5.1 Recuperar Features e Pontuar

Fazemos merge dos clientes preparados com a feature table para obter um DataFrame final que pode ser passado ao modelo.

```python
inference_lookup = FeatureLookup(
    table_name=feature_table_name,
    feature_names=[
        "total_orders",
        "avg_order_value",
        "total_spending",
        "market_segment"
    ],
    lookup_key="customer_id"
)

inference_set = fs.create_training_set(
    df=sample_customers,
    feature_lookups=[inference_lookup],
    label=None          # Sem label em inferência
)

inference_df  = inference_set.load_df()
predictions   = model.transform(inference_df)

display(predictions.select("customer_id", "prediction", "probability"))
```

> **Nota:** Usar `label=None` em `create_training_set` indica que estamos em modo de inferência (sem ground truth).

---

## 6. Resumo e Próximos Passos

| Conceito | Descrição |
|---|---|
| **Periodic Feature Updates** | Manter as features atuais via Jobs agendados |
| **Single Source of Truth** | O Feature Store garante consistência entre training e inferência |
| **Batch ou Real-Time Inference** | Podem usar as mesmas definições de features |

Este lab completa um walkthrough end-to-end de como **construir**, **manter** e **servir features** no Databricks, **treinar um modelo** e **inferir previsões** em novos dados.

---

## Glossário Rápido

| Termo | Significado |
|---|---|
| `FeatureStoreClient` | Cliente Python para interagir com o Feature Store |
| `fs.create_table()` | Regista uma nova feature table (com schema e primary keys) |
| `fs.write_table(mode="merge")` | Atualiza a feature table fazendo upsert pelos primary keys |
| `FeatureLookup` | Define quais features recuperar da feature table, e por que chave |
| `fs.create_training_set()` | Junta o DataFrame de labels com as features via lookup |
| `training_set.load_df()` | Materializa o training set como um Spark DataFrame |
| *Training-serving skew* | Diferença entre as features usadas no treino vs. na produção — o Feature Store elimina este problema |
