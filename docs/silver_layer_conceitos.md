# Silver Layer — Conceitos Fundamentais

> Ficha de consulta sobre design de funções de escrita, particionamento, cardinalidade, indexing e SCD Type 2 em Delta Lake.
> Contexto: projecto `market-pulse-pipeline` (Bronze → Silver → Gold).

---

## Índice

1. [Parâmetros de funções de write](#1-parâmetros-de-funções-de-write)
2. [Overwrite vs Append (princípio Medallion)](#2-overwrite-vs-append-princípio-medallion)
3. [Particionamento — para que serve](#3-particionamento--para-que-serve)
4. [Cardinalidade na decisão de partições](#4-cardinalidade-na-decisão-de-partições)
5. [Indexing vs Partitioning](#5-indexing-vs-partitioning)
6. [SCD Type 2 + MERGE](#6-scd-type-2--merge)
7. [Aplicação ao projecto](#7-aplicação-ao-projecto-market-pulse-pipeline)
8. [Frases-chave para entrevistas](#8-frases-chave-para-entrevistas)

---

## 1. Parâmetros de funções de write

**Pergunta:** as funções são sempre assim? ou podemos ter outros parâmetros?

**Resposta:** os parâmetros dependem do que a função precisa fazer.

### O essencial

| Parâmetro | Sempre necessário? | Para quê |
|---|---|---|
| `df` (DataFrame) | ✅ Sim | os dados a escrever |
| `path` | ✅ Sim | onde escrever |
| `mode` | ⚠️ Opcional | overwrite, append, etc. |
| `partition_by` | ⚠️ Opcional | colunas de partição |
| `mergeSchema`, `optimizeWrite` | ⚠️ Opcional | opções Delta |
| `table_name` | ⚠️ Opcional | logging do resultado |

### Versão mínima (3 args)

```python
def write_silver_table(df: DataFrame, path: str, table_name: str) -> None:
    df.write.format("delta").mode("overwrite").save(path)
    print(f"✅ {table_name} written to {path}")
```

**Trade-off:** simples, mas `mode` está hardcoded como `overwrite`.

### Versão flexível (5 args)

```python
def write_silver_table(
    df: DataFrame,
    path: str,
    table_name: str,
    mode: str = "overwrite",
    partition_by: list = None
) -> None:
    writer = df.write.format("delta").mode(mode)
    if partition_by:
        writer = writer.partitionBy(*partition_by)
    writer.save(path)
    print(f"✅ {table_name} written to {path} (mode={mode})")
```

**Trade-off:** suporta partições e modos diferentes; defaults mantêm compatibilidade.

### Como decidir?

- Vou escrever de formas diferentes? → adiciona `mode`
- Vou particionar? → adiciona `partition_by`
- Vou usar a função várias vezes? → mais parâmetros faz sentido
- É só este caso? → versão mínima chega

---

## 2. Overwrite vs Append (princípio Medallion)

### Por que `overwrite` na Silver?

```
Bronze Landing    →  source of truth (imutável)
Bronze Ingestion  →  snapshot do landing
Silver            →  derivado do Bronze Ingestion (sempre re-derivável)
```

A Silver é sempre **re-derivável** a partir do Bronze. Logo, se o pipeline correr 2x:

| Modo | Resultado |
|---|---|
| `append` | 10 linhas → 20 (duplicadas) ❌ |
| `overwrite` | apaga e reescreve, sempre 10 limpas ✅ |

### Quando seria diferente?

Em produção real com dados muito grandes usaria-se **MERGE** (upsert):

```sql
MERGE INTO silver.fact_prices target
USING source
ON target.symbol = source.symbol AND target.trade_date = source.trade_date
WHEN MATCHED THEN UPDATE
WHEN NOT MATCHED THEN INSERT
```

Só processa o que mudou — mais eficiente. (Stage 3 — Production Hardening.)

---

## 3. Particionamento — para que serve

### O que é

Particionar = dividir os dados em **pastas físicas** baseadas no valor de uma coluna.

```
Sem partições:
silver/fact_prices/
    part-00000.parquet  (todos os dados)
    part-00001.parquet

Com partições por trade_date:
silver/fact_prices/
    trade_date=2026-04-28/
        part-00000.parquet  ← só dia 28
    trade_date=2026-04-27/
        part-00000.parquet  ← só dia 27
```

### Para que serve — 3 razões

#### 3.1 Partition Pruning (a mais importante!)

Query: `SELECT * FROM fact_prices WHERE trade_date = '2026-04-28'`

- **Sem partições:** Spark lê TODOS os ficheiros, filtra em memória, devolve resultado → lento.
- **Com partições:** Spark vê o filtro, lê APENAS a pasta `trade_date=2026-04-28/`, skip 99% dos dados → rápido.

> O Spark "poda" partições irrelevantes — partition pruning.

#### 3.2 Paralelização

- Sem partições: Spark distribui aleatoriamente.
- Com partições: Spark sabe distribuir cada partição a um executor → processamento paralelo natural.

#### 3.3 Maintenance e gestão

- **Apagar dados antigos:** sem partições reescreve tudo; com partições apaga só a pasta `trade_date=2020-*/`.
- **Reprocessar 1 dia:** com partições carrega só essa partição.

### Custos

- ✅ Queries com filtro → muito mais rápidas
- ❌ Queries sem filtro → igual ou ligeiramente pior
- ❌ Tabelas pequenas → overhead inútil
- ❌ Particionar mal → **small files problem**

---

## 4. Cardinalidade na decisão de partições

**Cardinalidade** = número de valores únicos numa coluna.

| Coluna | Cardinalidade |
|---|---|
| `symbol` em `dim_stock` | 5 (baixa) |
| `symbol` em `fact_prices` | 5 (baixa) |
| `trade_date` em `fact_prices` | ~100 (média) |
| `ingest_timestamp` | ~milhares (alta) |

### Regra de ouro

> Particionar por colunas de **cardinalidade média-baixa** que são usadas em **filtros**.

| Cardinalidade | Para particionar? |
|---|---|
| Muito baixa (1–10) | ⚠️ Só se a tabela for enorme |
| Média (10–1000) | ✅ Ideal |
| Alta (>10000) | ❌ Cria muitos ficheiros pequenos = small files problem |

### O "small files problem"

Se cada partição tiver poucos KB em vez de poucos GB, o Spark perde performance — passa mais tempo a abrir/fechar ficheiros do que a processar dados.

> Particionar demais é tão mau como particionar de menos.

### Aplicação ao projecto

```
silver_fact_prices (~500 linhas):
  partition by symbol      →  5 partições de 100 linhas ⚠️ pequenas
  partition by trade_date  →  100 partições de 5 linhas ❌ péssimo
  → não particionar (tabela pequena)

gold_daily_metrics (milhões de linhas, daqui a anos):
  partition by trade_date  →  ~365 partições/ano de milhares de linhas ✅
  partition by symbol      →  poucas partições enormes ⚠️
  → particionar por trade_date faz sentido
```

---

## 5. Indexing vs Partitioning

Ambos servem o mesmo objectivo: **"não ler dados que não precisamos"**.

### Diferença fundamental

| | Index (BD relacional) | Partition (Data Lake) |
|---|---|---|
| Onde | Estrutura B-tree separada | Pastas físicas |
| Granularidade | Linha individual | Pasta inteira |
| Mantido por | BD actualiza automaticamente | Tu organizas no write |
| Custo escrita | Lento (actualiza index) | Igual |
| Custo leitura filtrada | Muito rápido | Rápido |
| Custo storage | Extra (o index) | Zero |

### Em Delta Lake — mecanismos adicionais

#### Z-Order

```python
df.write.format("delta").save(path)
spark.sql("OPTIMIZE silver.fact_prices ZORDER BY (symbol)")
```

Reordena os dados **dentro dos ficheiros** para que linhas com o mesmo `symbol` fiquem juntas. Acelera queries que filtram por `symbol`.

#### Data skipping

Delta guarda **min/max de cada coluna por ficheiro** automaticamente. Quando filtras, Delta sabe quais ficheiros podem conter o valor — skip dos outros.

### Hierarquia de "filtragem física"

```
Particionamento  →  skip de PASTAS inteiras       (mais grosso)
Z-Order          →  skip de FICHEIROS dentro      (médio)
Data skipping    →  skip de BLOCKS dentro         (mais fino)
Index B-tree     →  skip até linha individual     (mais granular)
```

Cada um é melhor para casos diferentes.

---

## 6. SCD Type 2 + MERGE

SCD Type 2 = guardar o **histórico de mudanças** numa dimensão. É o caso de uso clássico do MERGE num data warehouse moderno.

### Sem SCD vs com SCD2

```
dim_stock (sem SCD)
┌────────┬───────────────┬───────────┐
│ symbol │ last_refreshed│ time_zone │
├────────┼───────────────┼───────────┤
│ AAPL   │ 2026-04-28    │ US/Eastern│
└────────┴───────────────┴───────────┘
         ↑ se mudar, perde-se o anterior

dim_stock (com SCD2)
┌────────┬───────────────┬───────────┬────────────┬────────────┬───────────┐
│ symbol │ last_refreshed│ time_zone │ valid_from │ valid_to   │ is_current│
├────────┼───────────────┼───────────┼────────────┼────────────┼───────────┤
│ AAPL   │ 2026-04-27    │ US/Eastern│ 2026-04-27 │ 2026-04-28 │ false     │
│ AAPL   │ 2026-04-28    │ US/Eastern│ 2026-04-28 │ 9999-12-31 │ true      │
└────────┴───────────────┴───────────┴────────────┴────────────┴───────────┘
```

A linha velha **não desaparece** — fica fechada com `valid_to`. Linha nova abre.

### MERGE para SCD2

```sql
MERGE INTO silver.dim_stock target
USING staging_dim_stock source
ON target.symbol = source.symbol AND target.is_current = TRUE

-- Se mudou algum atributo: fechar a linha actual
WHEN MATCHED AND target.last_refreshed != source.last_refreshed THEN
    UPDATE SET
        target.valid_to = current_date(),
        target.is_current = FALSE

-- Se é novo symbol: inserir nova linha
WHEN NOT MATCHED THEN
    INSERT (symbol, last_refreshed, time_zone, valid_from, valid_to, is_current)
    VALUES (source.symbol, source.last_refreshed, source.time_zone,
            current_date(), '9999-12-31', TRUE)
```

> Depois é preciso um segundo INSERT para abrir a nova versão das linhas que se fecharam.

### Como tudo se relaciona

```
Particionamento  →  performance (não duplicar leituras)
Index/Z-Order    →  performance (skip de dados)
SCD2 + MERGE     →  histórico (preservar mudanças no tempo)
                    → também precisa de boa performance!
                       → daí MERGE em vez de overwrite
```

São camadas diferentes do mesmo objectivo: gerir dados eficientemente em escala.

---

## 7. Aplicação ao projecto market-pulse-pipeline

### Stage 1 — agora

| Tabela | Linhas | Particionar? | Modo | Notas |
|---|---|---|---|---|
| `silver_dim_stock` | 5 | ❌ Não | `overwrite` | tabela demasiado pequena |
| `silver_fact_prices` | ~500 | ❌ Não | `overwrite` | ainda pequena |
| `gold_daily_metrics` | milhares+ | ⚠️ Talvez | `overwrite` | rever quando crescer |

### Stage 3 — Production Hardening

- Migrar de `overwrite` para `MERGE` (upsert) na `fact_prices`.
- Adicionar `OPTIMIZE` + `ZORDER BY (symbol)` na `fact_prices`.

### Stage 5 — Advanced Patterns

- `dim_stock` com **SCD2 + MERGE** (histórico de mudanças).
- Demonstra capacidade de lidar com mudanças de atributos no tempo.

---

## 8. Frases-chave para entrevistas

> **Particionamento:** "Particiono por colunas de cardinalidade média que são frequentemente usadas em filtros — tipicamente a coluna de data. Evito particionar por colunas de alta cardinalidade para não cair no small files problem."

> **Para que serve particionar:** "Particionar serve para partition pruning — o Spark consegue saltar partições inteiras quando há filtros, reduzindo I/O drasticamente. Mas só vale a pena em tabelas grandes com queries que filtram pela coluna de partição."

> **Indexing vs partitioning:** "Em Delta Lake usamos partições para skip de pastas, Z-Order para reorganizar dentro de partições, e data skipping baseado em min/max statistics. Não temos indexes B-tree como em bases relacionais — o paradigma é diferente: optimizamos para reads sequenciais paralelos, não random access."

> **SCD2:** "SCD Type 2 implementa-se com MERGE em Delta Lake — uma única operação que actualiza linhas existentes (fechando o histórico) e insere novas. É um padrão essencial em data warehousing para dimensões que mudam ao longo do tempo, como informação de clientes ou produtos."

---

## Checklist mental antes de escrever uma tabela

- [ ] A tabela é grande o suficiente para justificar partição? (>1GB ou >100k linhas por partição)
- [ ] Há uma coluna de cardinalidade média usada frequentemente em filtros?
- [ ] É derivada (overwrite seguro) ou tem histórico próprio (precisa de MERGE)?
- [ ] É uma dimensão que muda no tempo? (candidata a SCD2)
- [ ] A função de write tem flexibilidade suficiente para futuros casos? (`mode`, `partition_by`)
