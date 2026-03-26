-- ============================================================
-- Gold_Aggregate.sql
-- Agregação Silver → Gold
-- Usa MERGE INTO para ser idempotente (não duplica se correr 2x)
-- ============================================================

-- Célula 1: Configuração
USE CATALOG tpcdi_learning;

-- Célula 2: Limpar Gold
TRUNCATE TABLE gold.trades_by_customer;
TRUNCATE TABLE gold.trades_by_sector;

-- Célula 3: Silver → Gold: Por cliente
MERGE INTO gold.trades_by_customer AS target
USING (
    SELECT
        c.customer_id,
        c.name                          AS customer_name,
        c.country,
        COUNT(t.trade_id)               AS total_trades,
        SUM(t.price * t.quantity)       AS total_value,
        AVG(t.price * t.quantity)       AS avg_trade_value,
        MIN(t.trade_date)               AS first_trade_date,
        MAX(t.trade_date)               AS last_trade_date,
        current_timestamp()             AS updated_at
    FROM silver.dim_customers c
    JOIN silver.fact_trades t ON c.customer_id = t.customer_id
    WHERE t.price IS NOT NULL
    GROUP BY c.customer_id, c.name, c.country
) AS source
ON target.customer_id = source.customer_id
WHEN MATCHED THEN UPDATE SET *
WHEN NOT MATCHED THEN INSERT *;

-- Célula 4: Silver → Gold: Por sector
MERGE INTO gold.trades_by_sector AS target
USING (
    SELECT
        s.sector,
        s.exchange,
        COUNT(t.trade_id)               AS total_trades,
        SUM(t.price * t.quantity)       AS total_value,
        AVG(t.price)                    AS avg_price,
        COUNT(DISTINCT t.customer_id)   AS unique_customers,
        current_timestamp()             AS updated_at
    FROM silver.dim_securities s
    JOIN silver.fact_trades t ON s.security_id = t.security_id
    WHERE t.price IS NOT NULL
    GROUP BY s.sector, s.exchange
) AS source
ON target.sector = source.sector
AND target.exchange = source.exchange
WHEN MATCHED THEN UPDATE SET *
WHEN NOT MATCHED THEN INSERT *;

-- Célula 5: Confirmar Gold
SELECT 'trades_by_customer' AS tabela, COUNT(*) AS total FROM gold.trades_by_customer
UNION ALL
SELECT 'trades_by_sector',             COUNT(*) FROM gold.trades_by_sector;

-- Célula 6: Ver resultados finais
SELECT * FROM gold.trades_by_customer ORDER BY total_value DESC;
SELECT * FROM gold.trades_by_sector ORDER BY total_value DESC;
