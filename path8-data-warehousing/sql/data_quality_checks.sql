-- ============================================================
-- data_quality_checks.sql
-- Testes de qualidade de dados na camada Silver
-- ============================================================

USE CATALOG tpcdi_learning;

-- Criar tabela de log de qualidade
CREATE TABLE IF NOT EXISTS silver.data_quality_log (
    check_name      STRING,
    tabela          STRING,
    total_registos  BIGINT,
    registos_falha  BIGINT,
    percentagem_ok  DECIMAL(5,2),
    status          STRING,
    executado_em    TIMESTAMP
);

-- Inserir resultados dos testes
INSERT INTO silver.data_quality_log

-- Teste 1: preços NULL
SELECT
    'price_not_null'            AS check_name,
    'silver.fact_trades'        AS tabela,
    COUNT(*)                    AS total_registos,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS registos_falha,
    ROUND(100.0 * SUM(CASE WHEN price IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS percentagem_ok,
    CASE WHEN SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) = 0
         THEN '✅ PASS' ELSE '❌ FAIL' END AS status,
    current_timestamp()         AS executado_em
FROM silver.fact_trades

UNION ALL

-- Teste 2: clientes duplicados
SELECT
    'no_duplicate_customers'    AS check_name,
    'silver.dim_customers'      AS tabela,
    COUNT(*)                    AS total_registos,
    COUNT(*) - COUNT(DISTINCT customer_id) AS registos_falha,
    ROUND(100.0 * COUNT(DISTINCT customer_id) / COUNT(*), 2) AS percentagem_ok,
    CASE WHEN COUNT(*) = COUNT(DISTINCT customer_id)
         THEN '✅ PASS' ELSE '❌ FAIL' END AS status,
    current_timestamp()         AS executado_em
FROM silver.dim_customers

UNION ALL

-- Teste 3: trades com clientes inválidos
SELECT
    'valid_customer_in_trades'  AS check_name,
    'silver.fact_trades'        AS tabela,
    COUNT(*)                    AS total_registos,
    SUM(CASE WHEN c.customer_id IS NULL THEN 1 ELSE 0 END) AS registos_falha,
    ROUND(100.0 * SUM(CASE WHEN c.customer_id IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS percentagem_ok,
    CASE WHEN SUM(CASE WHEN c.customer_id IS NULL THEN 1 ELSE 0 END) = 0
         THEN '✅ PASS' ELSE '❌ FAIL' END AS status,
    current_timestamp()         AS executado_em
FROM silver.fact_trades t
LEFT JOIN silver.dim_customers c ON t.customer_id = c.customer_id;

-- Ver resultados
SELECT * FROM silver.data_quality_log ORDER BY executado_em DESC;
