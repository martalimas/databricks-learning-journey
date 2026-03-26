-- ============================================================
-- Silver_Transform.sql
-- Transformação Bronze → Silver
-- Limpa, tipa correctamente e elimina problemas de qualidade
-- ============================================================

-- Célula 1: Configuração
USE CATALOG tpcdi_learning;

-- Célula 2: Limpar Silver para reprocessar
TRUNCATE TABLE silver.dim_customers;
TRUNCATE TABLE silver.dim_securities;
TRUNCATE TABLE silver.fact_trades;

-- Célula 3: Bronze → Silver: Clientes
-- Limpa, tipa e elimina duplicados (o mais recente ganha)
INSERT INTO silver.dim_customers
SELECT
    CAST(customer_id AS BIGINT)                 AS customer_id,
    INITCAP(TRIM(name))                         AS name,
    LOWER(TRIM(email))                          AS email,
    TRIM(phone)                                 AS phone,
    INITCAP(TRIM(city))                         AS city,
    UPPER(TRIM(country))                        AS country,
    TRIM(status)                                AS status,
    TO_DATE(created_date, 'yyyyMMdd')           AS created_date,
    CASE WHEN TRIM(status) = 'ACTIVE'
         THEN TRUE ELSE FALSE END               AS is_active,
    current_timestamp()                         AS updated_at
FROM bronze.raw_customers
WHERE customer_id IS NOT NULL
  AND TRIM(customer_id) != ''
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY customer_id
    ORDER BY _ingested_at DESC
) = 1;  -- elimina duplicados, fica só o mais recente!

-- Célula 4: Bronze → Silver: Securities
INSERT INTO silver.dim_securities
SELECT
    CAST(REPLACE(security_id, 'S', '') AS BIGINT) AS security_id,
    UPPER(TRIM(ticker))                           AS ticker,
    TRIM(company_name)                            AS company_name,
    TRIM(sector)                                  AS sector,
    TRIM(exchange)                                AS exchange,
    current_timestamp()                           AS updated_at
FROM bronze.raw_securities
WHERE security_id IS NOT NULL;

-- Célula 5: Bronze → Silver: Trades
-- Trata sinal negativo no fim (formato asiático)
-- Exclui preços vazios (T006)
-- Exclui clientes que não existem na dim_customers (T007)
INSERT INTO silver.fact_trades
SELECT
    CAST(REPLACE(trade_id, 'T', '') AS BIGINT)      AS trade_id,
    CAST(customer_id AS BIGINT)                     AS customer_id,
    CAST(REPLACE(security_id, 'S', '') AS BIGINT)   AS security_id,
    TO_DATE(trade_date, 'yyyyMMdd')                 AS trade_date,
    CAST(quantity AS INTEGER)                       AS quantity,
    CASE
        WHEN TRIM(price) = '' THEN NULL
        WHEN RIGHT(TRIM(price), 1) = '-'
        THEN CAST('-' || REPLACE(TRIM(price),'-','') AS DECIMAL(16,2))
        ELSE CAST(TRIM(price) AS DECIMAL(16,2))
    END                                             AS price,
    TRIM(trade_type)                                AS trade_type,
    TRIM(status)                                    AS status,
    current_timestamp()                             AS processed_at
FROM bronze.raw_trades
WHERE TRIM(price) != ''
  AND CAST(customer_id AS BIGINT)
      IN (SELECT customer_id FROM silver.dim_customers);

-- Célula 6: Confirmar Silver
SELECT 'dim_customers'  AS tabela, COUNT(*) AS total FROM silver.dim_customers
UNION ALL
SELECT 'dim_securities',            COUNT(*) FROM silver.dim_securities
UNION ALL
SELECT 'fact_trades',               COUNT(*) FROM silver.fact_trades;
