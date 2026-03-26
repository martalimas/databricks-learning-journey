-- ============================================================
-- setup_catalog.sql
-- Criação do catalog, schemas e tabelas do projecto TPCDI
-- ============================================================

-- Criar catalog
CREATE CATALOG IF NOT EXISTS tpcdi_learning;
USE CATALOG tpcdi_learning;

-- Criar schemas (Medallion Architecture)
CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;

-- Confirmar
SHOW SCHEMAS IN tpcdi_learning;

-- ============================================================
-- BRONZE — dados em bruto, tudo STRING
-- ============================================================

CREATE TABLE IF NOT EXISTS bronze.raw_customers (
    customer_id     STRING,
    name            STRING,
    email           STRING,
    phone           STRING,
    city            STRING,
    country         STRING,
    status          STRING,
    created_date    STRING,
    _source_file    STRING,
    _ingested_at    TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bronze.raw_trades (
    trade_id        STRING,
    customer_id     STRING,
    security_id     STRING,
    trade_date      STRING,
    quantity        STRING,
    price           STRING,
    trade_type      STRING,
    status          STRING,
    _source_file    STRING,
    _ingested_at    TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bronze.raw_securities (
    security_id     STRING,
    ticker          STRING,
    company_name    STRING,
    sector          STRING,
    exchange        STRING,
    _source_file    STRING,
    _ingested_at    TIMESTAMP
);

-- ============================================================
-- SILVER — dados limpos e tipados correctamente
-- ============================================================

CREATE TABLE IF NOT EXISTS silver.dim_customers (
    customer_id     BIGINT,
    name            STRING,
    email           STRING,
    phone           STRING,
    city            STRING,
    country         STRING,
    status          STRING,
    created_date    DATE,
    is_active       BOOLEAN,
    updated_at      TIMESTAMP
);

CREATE TABLE IF NOT EXISTS silver.dim_securities (
    security_id     BIGINT,
    ticker          STRING,
    company_name    STRING,
    sector          STRING,
    exchange        STRING,
    updated_at      TIMESTAMP
);

CREATE TABLE IF NOT EXISTS silver.fact_trades (
    trade_id        BIGINT,
    customer_id     BIGINT,
    security_id     BIGINT,
    trade_date      DATE,
    quantity        INTEGER,
    price           DECIMAL(16,2),
    trade_type      STRING,
    status          STRING,
    processed_at    TIMESTAMP
);

-- ============================================================
-- GOLD — dados agregados, prontos para análise
-- ============================================================

CREATE TABLE IF NOT EXISTS gold.trades_by_customer (
    customer_id         BIGINT,
    customer_name       STRING,
    country             STRING,
    total_trades        BIGINT,
    total_value         DECIMAL(16,2),
    avg_trade_value     DECIMAL(16,2),
    first_trade_date    DATE,
    last_trade_date     DATE,
    updated_at          TIMESTAMP
);

CREATE TABLE IF NOT EXISTS gold.trades_by_sector (
    sector              STRING,
    exchange            STRING,
    total_trades        BIGINT,
    total_value         DECIMAL(16,2),
    avg_price           DECIMAL(16,2),
    unique_customers    BIGINT,
    updated_at          TIMESTAMP
);

-- Confirmar tudo
SHOW TABLES IN tpcdi_learning.bronze;
SHOW TABLES IN tpcdi_learning.silver;
SHOW TABLES IN tpcdi_learning.gold;
