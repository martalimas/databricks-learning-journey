# ⚠️ Erros Recorrentes em Pipelines de Dados

## 🔴 Muito Comuns

### 1. Duplicados por re-execução
- **Causa:** INSERT simples sem idempotência
- **Solução:** MERGE INTO ou TRUNCATE + INSERT
- **Exemplo real:** Gold tables duplicadas se correr script 2x
```sql
-- ❌ Errado — duplica se correr 2x
INSERT INTO gold.tabela SELECT ...

-- ✅ Correcto — idempotente
MERGE INTO gold.tabela AS target
USING (...) AS source
ON target.id = source.id
WHEN MATCHED THEN UPDATE SET *
WHEN NOT MATCHED THEN INSERT *;
```

### 2. Schema mismatch
- **Causa:** ficheiro novo com coluna extra ou tipo diferente
- **Solução:** Auto Loader com schema evolution ou rescue data column

### 3. NULL propagation
- **Causa:** campo NULL numa operação matemática
- **Exemplo:** `price * quantity` → se price = NULL → resultado = NULL
- **Solução:** `COALESCE(price, 0)` ou filtrar NULLs antes
```sql
-- ❌ Errado
SUM(price * quantity)

-- ✅ Correcto
SUM(COALESCE(price, 0) * COALESCE(quantity, 0))
-- ou filtrar antes:
WHERE price IS NOT NULL AND quantity IS NOT NULL
```

### 4. Encoding de caracteres
- **Causa:** ficheiro UTF-8 mas sistema espera Latin-1
- **Exemplo:** "João" vira "Jo?o"
- **Solução:** definir encoding explicitamente na ingestão

### 5. Timezone mismatch
- **Causa:** timestamps de sistemas diferentes em timezones diferentes
- **Solução:** converter sempre para UTC no Bronze
```sql
-- Converter para UTC na ingestão
CONVERT_TIMEZONE('UTC', timestamp_column) AS timestamp_utc
```

---

## 🟡 Menos Comuns mas Documentados

### 6. Small files problem
- **Causa:** Auto Loader cria milhares de ficheiros Parquet pequenos → queries lentas
- **Solução:** `OPTIMIZE + ZORDER` periodicamente
```sql
OPTIMIZE tpcdi_learning.silver.fact_trades
ZORDER BY (trade_date, customer_id);
```

### 7. Data skew
- **Causa:** uma partição tem muito mais dados que as outras
- **Exemplo:** 80% dos clientes são de Portugal → um worker sobrecarregado
- **Solução:** SKEW HINT ou repartitioning

### 8. Late arriving data
- **Causa:** dados chegam fora de ordem
- **Exemplo:** trade de segunda chega na quarta → relatório de segunda já estava errado
- **Solução:** watermarking em streaming

### 9. Cascading failures
- **Causa:** erro no Bronze que só se manifesta no Gold
- **Solução:** data quality checks em cada camada (não só no final!)

---

## 🔴 Raros mas Graves

### 10. Silent data corruption
- **Causa:** transformação errada que não dá erro
- **Exemplo:** dividir por zero com NULLIF → NULL silencioso
- **Solução:** testes de qualidade + reconciliação com fonte

### 11. Delta Log corruption
- **Causa:** operação interrompida a meio
- **Solução:** RESTORE TABLE para versão anterior (time travel!)
```sql
-- Ver histórico de versões
DESCRIBE HISTORY tpcdi_learning.silver.fact_trades;

-- Restaurar versão anterior
RESTORE TABLE tpcdi_learning.silver.fact_trades TO VERSION AS OF 3;
```

---

## 🛡️ Como prevenir — Data Quality Checks

### Opção 1 — Table Constraints (informativo)
```sql
ALTER TABLE silver.fact_trades
ADD CONSTRAINT price_not_null CHECK (price IS NOT NULL);
```
> ⚠️ No Databricks é informativo, não enforced como no SQL Server!

### Opção 2 — Tabela de log de qualidade
```sql
CREATE TABLE IF NOT EXISTS silver.data_quality_log (
    check_name      STRING,
    tabela          STRING,
    total_registos  BIGINT,
    registos_falha  BIGINT,
    percentagem_ok  DECIMAL(5,2),
    status          STRING,  -- ✅ PASS ou ❌ FAIL
    executado_em    TIMESTAMP
);
```

### Opção 3 — Delta Live Tables Expectations (mais avançado)
```python
@dlt.table
@dlt.expect("price_not_null", "price IS NOT NULL")
@dlt.expect("valid_quantity", "quantity > 0")
@dlt.expect_or_drop("valid_customer", "customer_id IS NOT NULL")
def silver_trades():
    return spark.table("bronze.raw_trades")
```
> 📌 Precisa de Delta Live Tables — ver Path 1 / Módulo 3

---

## 📚 Documentação Oficial
- Databricks: https://docs.databricks.com
- Delta Lake: https://delta.io
- dbt: https://docs.getdbt.com
- Great Expectations: https://greatexpectations.io
